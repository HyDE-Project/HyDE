#!/usr/bin/env bash
# A restore has to refresh the Python environment before it deploys anything.
#
# The dot deployment, the dependency checks and hyde-shell all run out of that
# environment, and the revisions they run are the ones this checkout's lock
# pins. A restore that skips the step deploys with whatever was installed the
# last time it did not, so a corrected pin never reaches the machine. What it
# must not do instead is pull in the rest of the pre-install script, which
# rewrites the bootloader and pacman configuration.

. "$(dirname -- "$0")/lib/common.sh"

if [ ! -f "$REPO_ROOT/Scripts/install_env.sh" ]; then
    fail "Scripts/install_env.sh does not exist"
    finish
fi

[ -x "$REPO_ROOT/Scripts/install_env.sh" ] ||
    fail "Scripts/install_env.sh is not executable"

# The environment step has to stand alone: the pre-install script may call it,
# never the other way round.
grep -q 'install_pre\.sh' "$REPO_ROOT/Scripts/install_env.sh" &&
    fail "Scripts/install_env.sh calls back into the pre-install script"

grep -qE '^[[:space:]]*"\$\{scrDir\}/install_env\.sh"' "$REPO_ROOT/Scripts/install_pre.sh" ||
    fail "Scripts/install_pre.sh no longer runs the environment step"

# Nothing of the environment setup may be left behind in the pre-install
# script, or a change to one of them would stop matching the other unnoticed.
grep -q 'python_env\.py' "$REPO_ROOT/Scripts/install_pre.sh" &&
    fail "Scripts/install_pre.sh still sets up the Python environment itself"

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

cp -a "$REPO_ROOT/Scripts" "$work_dir/Scripts"
mkdir -p "$work_dir/home" "$work_dir/state"

# Every script the installer hands off to is replaced by a stub that records
# the fact, so a case can only fail on the dispatch under test and nothing
# reaches the system running the suite.
ran_log="$work_dir/ran.log"
for stub in install_env install_pre install_aur install_pst restore_thm restore_svc; do
    printf '#!/usr/bin/env sh\nprintf "%%s\\n" "%s" >>"%s"\n' "$stub" "$ran_log" \
        >"$work_dir/Scripts/$stub.sh"
    chmod +x "$work_dir/Scripts/$stub.sh"
done
rm -f "$work_dir/Scripts/migrations"/*.sh

run_installer() {
    : >"$ran_log"
    (
        HOME="$work_dir/home" XDG_STATE_HOME="$work_dir/state" \
            "$work_dir/Scripts/install.sh" "$@" </dev/null
    ) >"$work_dir/out.log" 2>&1
}

ran() { grep -qxF "$1" "$ran_log" 2>/dev/null; }

# A restore on its own: the environment step runs, the bootloader and pacman
# changes do not.
run_installer -r -t
ran install_env || fail "a restore did not refresh the Python environment"
ran install_pre && fail "a restore ran the pre-install script"

# An install on its own reaches deez for the dependency check, so it needs the
# environment just as much.
run_installer -i -t
ran install_env || fail "an install did not refresh the Python environment"
ran install_pre && fail "an install on its own ran the pre-install script"

# The pre-install operation still reaches the environment through
# install_pre.sh, so the message a failed restore prints keeps working.
run_installer -p -t
ran install_pre || fail "the pre-install operation no longer runs install_pre.sh"

# A combined run keeps the pre-install script, unchanged from before.
run_installer -i -r -t
ran install_pre || fail "a combined install and restore no longer runs install_pre.sh"

# What the extracted script itself does: create the environment, then sync it
# against this checkout's lock, and stop at the first of the two that fails.
env_tree="$work_dir/env_tree"
mkdir -p "$env_tree/Configs/.local/lib/hyde/pyutils" "$env_tree/home/.local/state/hyde/python_env/bin"
cp -a "$REPO_ROOT/Scripts" "$env_tree/Scripts"

env_log="$env_tree/env.log"
python_stub="$env_tree/Configs/.local/lib/hyde/pyutils/python_env.py"
ln -sf "$(command -v python3)" "$env_tree/home/.local/state/hyde/python_env/bin/python"

write_python_stub() {
    printf 'import sys\nwith open(%s, "a") as handle:\n    handle.write(sys.argv[1] + "\\n")\nsys.exit(%s if sys.argv[1] == "create" else 0)\n' \
        "\"$env_log\"" "$1" >"$python_stub"
}

run_env_step() {
    : >"$env_log"
    (
        HOME="$env_tree/home" "$env_tree/Scripts/install_env.sh" </dev/null
    ) >"$env_tree/out.log" 2>&1
}

write_python_stub 0
run_env_step
env_status=$?

[ "$env_status" -eq 0 ] ||
    fail "the environment step failed on a checkout where both calls succeed"

env_calls=$(tr '\n' ' ' <"$env_log")
[ "$env_calls" = "create sync " ] ||
    fail "the environment step ran '$env_calls', expected 'create sync '"

# A failed create has to stop the run: syncing into an environment that was
# never built reports success over a machine that has nothing installed.
write_python_stub 1
run_env_step
env_status=$?

[ "$env_status" -ne 0 ] ||
    fail "the environment step reported success after the environment failed to build"

grep -qxF 'sync' "$env_log" &&
    fail "the environment step synced dependencies after the environment failed to build"

# Dry run reports and touches nothing.
: >"$env_log"
(
    HOME="$env_tree/home" flg_DryRun=1 "$env_tree/Scripts/install_env.sh" </dev/null
) >"$env_tree/out.log" 2>&1 ||
    fail "the environment step failed under dry-run"

[ -s "$env_log" ] &&
    fail "the environment step ran the setup under dry-run"

finish
