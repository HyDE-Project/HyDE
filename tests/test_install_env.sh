#!/usr/bin/env bash
# The Python environment has to be refreshed before anything reaches deez.
#
# The dot deployment and both dependency checks run out of that environment,
# and the revisions they run are the ones this checkout's lock pins. A run that
# skips the step works with whatever was installed the last time it did not, so
# a corrected pin never reaches the machine. Ordering is the whole point: the
# dependency checks reach deez well before the deployment does.

. "$(dirname -- "$0")/lib/common.sh"

grep -q '^setup_python_env()' "$REPO_ROOT/Scripts/global_fn.sh" ||
    fail "global_fn.sh does not define the Python environment step"

grep -qE '^[[:space:]]*setup_python_env' "$REPO_ROOT/Scripts/install_pre.sh" ||
    fail "install_pre.sh no longer runs the Python environment step"

grep -q 'python_env\.py' "$REPO_ROOT/Scripts/install_pre.sh" &&
    fail "install_pre.sh sets up the environment itself instead of using the shared step"

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

clone_dir="$work_dir/clone"
home_dir="$work_dir/home"
mkdir -p "$clone_dir" "$home_dir/.local/lib/hyde/wallpaper" "$home_dir/.local/state/hyde/python_env/bin"
cp -a "$REPO_ROOT/Scripts" "$clone_dir/Scripts"

# Every hand-off is a stub that records the fact, so a case can only fail on
# the flow under test and nothing reaches the machine running the suite.
ran_log="$work_dir/ran.log"
for stub in install_pre install_aur install_pst restore_thm restore_svc; do
    printf '#!/usr/bin/env sh\nprintf "%%s\\n" "%s" >>"%s"\n' "$stub" "$ran_log" \
        >"$clone_dir/Scripts/$stub.sh"
    chmod +x "$clone_dir/Scripts/$stub.sh"
done
rm -f "$clone_dir/Scripts/migrations"/*.sh

mkdir -p "$clone_dir/Configs/.local/lib/hyde/pyutils"
printf 'import sys\nsys.exit(0)\n' >"$clone_dir/Configs/.local/lib/hyde/pyutils/lua_env.py"

# The environment step and deez both record what they were asked to do, in the
# same log, so their order is part of what the case checks.
write_python_stub() {
    cat >"$clone_dir/Configs/.local/lib/hyde/pyutils/python_env.py" <<PY
import sys

with open("$ran_log", "a") as handle:
    handle.write("python_env " + sys.argv[1] + "\n")

sys.exit(${1:-0} if sys.argv[1] == "create" else 0)
PY
}
write_python_stub 0

ln -sf "$(command -v python3)" "$home_dir/.local/state/hyde/python_env/bin/python"
printf '#!/usr/bin/env sh\nprintf "deez %%s\\n" "$1" >>"%s"\n' "$ran_log" \
    >"$home_dir/.local/state/hyde/python_env/bin/deez"
chmod +x "$home_dir/.local/state/hyde/python_env/bin/deez"

for helper in "wallpaper/cache.sh" "theme.switch.sh" "waybar.py"; do
    printf '#!/usr/bin/env sh\nexit 0\n' >"$home_dir/.local/lib/hyde/$helper"
    chmod +x "$home_dir/.local/lib/hyde/$helper"
done

run_installer() {
    : >"$ran_log"
    rm -rf "$work_dir/state"
    (
        env -u HYPRLAND_INSTANCE_SIGNATURE \
            HOME="$home_dir" \
            XDG_STATE_HOME="$work_dir/state" \
            XDG_CACHE_HOME="$work_dir/cache" \
            CLONE_DIR="$clone_dir" \
            "$clone_dir/Scripts/install.sh" "$@" <<<"n"
    ) >"$work_dir/out.log" 2>&1
}

ran() { grep -qxF "$1" "$ran_log" 2>/dev/null; }
line_of() { grep -nxF "$1" "$ran_log" 2>/dev/null | head -n 1 | cut -d: -f1; }

# A restore on its own refreshes the environment, and does it before the first
# thing that runs out of it.
run_installer -r
ran "python_env create" || fail "a restore did not create the Python environment"
ran "python_env sync" || fail "a restore did not sync the Python environment"
ran install_pre && fail "a restore ran the pre-install script"

first_deez=$(line_of "deez deps")
sync_at=$(line_of "python_env sync")
if [ -z "$first_deez" ] || [ -z "$sync_at" ]; then
    fail "a restore did not reach both steps, the ordering could not be checked"
elif [ "$sync_at" -gt "$first_deez" ]; then
    fail "the environment was synced after deez had already run"
fi

# An install on its own reaches deez for the dependency check, so it needs the
# environment just as much.
run_installer -i
ran "python_env sync" || fail "an install did not refresh the Python environment"
ran install_pre && fail "an install on its own ran the pre-install script"

# The pre-install operation and a combined run keep going through
# install_pre.sh, unchanged from before.
run_installer -p
ran install_pre || fail "the pre-install operation no longer runs install_pre.sh"

run_installer -i -r
ran install_pre || fail "a combined install and restore no longer runs install_pre.sh"

# A failed create has to stop the run: syncing into an environment that was
# never built would report success over a machine that has nothing installed.
write_python_stub 1
run_installer -r
status=$?
write_python_stub 0

[ "$status" -ne 0 ] || fail "the run reported success after the environment failed to build"
ran "python_env sync" && fail "the environment was synced after it failed to build"
ran "deez deps" && fail "deez ran after the environment failed to build"

# Dry run reports and touches nothing.
run_installer -r -t
ran "python_env create" && fail "the environment was built under dry-run"

finish
