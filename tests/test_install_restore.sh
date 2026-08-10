#!/usr/bin/env bash
# A dot that fails to deploy must not cost the user the rest of the restore.
#
# The theme, the wallpaper cache, the migrations and the services are what put
# a partly deployed tree back into shape, so they are exactly the steps that
# have to keep running when a deployment reports failures. The run still has to
# end non-zero and say so, or a half-migrated install looks like a clean one.

. "$(dirname -- "$0")/lib/common.sh"

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

clone_dir="$work_dir/clone"
home_dir="$work_dir/home"
mkdir -p "$clone_dir" "$home_dir"
cp -a "$REPO_ROOT/Scripts" "$clone_dir/Scripts"

ran_log="$work_dir/ran.log"
deez_log="$work_dir/deez.log"

# Everything the restore hands off to is a stub that records the fact, so a
# case can only fail on the flow under test and nothing reaches the machine
# running the suite.
for stub in install_pre install_aur install_pst restore_thm restore_svc; do
    printf '#!/usr/bin/env sh\nprintf "%%s\\n" "%s" >>"%s"\n' "$stub" "$ran_log" \
        >"$clone_dir/Scripts/$stub.sh"
    chmod +x "$clone_dir/Scripts/$stub.sh"
done
rm -f "$clone_dir/Scripts/migrations"/*.sh
printf '#!/usr/bin/env sh\nprintf "%%s\\n" "migration" >>"%s"\n' "$ran_log" \
    >"$clone_dir/Scripts/migrations/v99.9.9.sh"
chmod +x "$clone_dir/Scripts/migrations/v99.9.9.sh"

mkdir -p "$clone_dir/Configs/.local/lib/hyde/pyutils"
printf 'import sys\nsys.exit(0)\n' >"$clone_dir/Configs/.local/lib/hyde/pyutils/lua_env.py"
# The restore refreshes the Python environment before it reaches deez, so the
# script it calls has to answer here too. Whether it does is checked by
# test_install_env; this case only needs it out of the way.
printf 'import sys\nsys.exit(0)\n' >"$clone_dir/Configs/.local/lib/hyde/pyutils/python_env.py"

mkdir -p "$home_dir/.local/state/hyde/python_env/bin" "$home_dir/.local/lib/hyde/wallpaper"
for helper in "wallpaper/cache.sh" "theme.switch.sh" "waybar.py"; do
    printf '#!/usr/bin/env sh\nprintf "%%s\\n" "%s" >>"%s"\n' "$(basename "$helper")" "$ran_log" \
        >"$home_dir/.local/lib/hyde/$helper"
    chmod +x "$home_dir/.local/lib/hyde/$helper"
done

deez_exe="$home_dir/.local/state/hyde/python_env/bin/deez"
# The environment step syncs through the interpreter in that environment.
ln -sf "$(command -v python3)" "$home_dir/.local/state/hyde/python_env/bin/python"

# The stub records every invocation and can be told to fail the core deploy,
# which is the call that used to end the run.
write_deez_stub() {
    {
        printf '#!/usr/bin/env sh\n'
        printf 'printf "%%s\\n" "$*" >>"%s"\n' "$deez_log"
        if [ "$1" = "fail-core" ]; then
            printf 'case "$*" in\n'
            printf '    *dots-groups/core.toml*dots*) exit 1 ;;\n'
            printf 'esac\n'
        fi
        printf 'exit 0\n'
    } >"$deez_exe"
    chmod +x "$deez_exe"
}

run_restore() {
    : >"$ran_log"
    : >"$deez_log"
    # A fresh state directory per run: the migration runner records what it
    # applied, so a shared one would make the second run look like it skipped
    # the step it was told to repeat.
    rm -rf "$work_dir/state"
    (
        # The run ends by asking about a reboot. Answering keeps the question
        # from reading EOF, which would end the script on its own.
        env -u HYPRLAND_INSTANCE_SIGNATURE \
            HOME="$home_dir" \
            XDG_STATE_HOME="$work_dir/state" \
            XDG_CACHE_HOME="$work_dir/cache" \
            CLONE_DIR="$clone_dir" \
            "$clone_dir/Scripts/install.sh" -r -s <<<"n"
    ) >"$work_dir/out.log" 2>&1
}

ran() { grep -qxF "$1" "$ran_log" 2>/dev/null; }

# A clean deployment: everything runs and the run succeeds.
write_deez_stub ok
run_restore
status=$?

[ "$status" -eq 0 ] || fail "a clean restore exited with $status: $(tail -n 5 "$work_dir/out.log")"
grep -q 'dots-groups/core.toml' "$deez_log" || fail "a clean restore never deployed the core dots"
ran restore_thm || fail "a clean restore did not apply the theme"
ran migration || fail "a clean restore did not run the migrations"
ran restore_svc || fail "a clean restore did not enable the services"
ran cache.sh || fail "a clean restore did not rebuild the wallpaper cache"

# The core deployment fails: the remaining steps still run, and the run ends
# non-zero saying what happened.
write_deez_stub fail-core
run_restore
status=$?

[ "$status" -ne 0 ] || fail "a restore whose core deployment failed reported success"
grep -q 'dots-groups/extra.toml' "$deez_log" ||
    fail "a failed core deployment stopped the extra dots from being deployed"
ran restore_thm || fail "a failed deployment stopped the theme from being applied"
ran migration || fail "a failed deployment stopped the migrations from running"
ran restore_svc || fail "a failed deployment stopped the services from being enabled"
ran cache.sh || fail "a failed deployment stopped the wallpaper cache from being rebuilt"
grep -q 'Some dots were not deployed' "$work_dir/out.log" ||
    fail "a failed deployment did not say so at the end of the run"
grep -q 'COMPLETED' "$work_dir/out.log" &&
    fail "a failed deployment still reported the run as completed"

finish
