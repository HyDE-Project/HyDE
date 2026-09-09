#!/usr/bin/env bash
# `hyde-shell wallbash <name>` looks up the script by appending ".sh" to
# whatever name it's given -- but its own usage/help fallback lists scripts
# by their real filename (e.g. "spotify.sh"), inviting a user to pass that
# exact name back in. Doing so looked for "spotify.sh.sh", found nothing,
# and silently fell through to the same usage text instead of running the
# script (#1801).

. "$(dirname -- "$0")/lib/common.sh"

hyde_shell="$REPO_ROOT/Configs/.local/bin/hyde-shell"
[ -f "$hyde_shell" ] || {
    fail "hyde-shell not found at $hyde_shell"
    finish
}

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

home_dir="$work_dir/home"
scripts_dir="$home_dir/.local/share/wallbash/scripts"
mkdir -p "$home_dir/.config" "$scripts_dir" "$home_dir/.local/state" "$home_dir/.cache"

cat >"$scripts_dir/spotify.sh" <<'EOF'
#!/usr/bin/env bash
echo "ran with args: $*"
EOF
chmod +x "$scripts_dir/spotify.sh"

##
# Runs `hyde-shell wallbash "$@"` against the sandboxed HOME/XDG dirs.
##
run_wallbash() {
    env -i \
        HOME="$home_dir" \
        XDG_CONFIG_HOME="$home_dir/.config" \
        XDG_DATA_HOME="$home_dir/.local/share" \
        XDG_CACHE_HOME="$home_dir/.cache" \
        XDG_STATE_HOME="$home_dir/.local/state" \
        XDG_RUNTIME_DIR="$home_dir/run" \
        PATH="/usr/bin:/bin" \
        bash "$hyde_shell" wallbash "$@" 2>"$work_dir/stderr"
}

# The reported shape: the name copied verbatim from the help listing, ".sh"
# and all.
output=$(run_wallbash spotify.sh foo)
case $output in
*'ran with args: foo'*) ;;
*)
    fail "wallbash spotify.sh (with the extension, as the help text lists it) did not run the script: got '$output' (stderr: $(cat "$work_dir/stderr"))"
    ;;
esac

# The name without the extension must keep working exactly as before --
# regression guard for the case this always handled correctly.
output=$(run_wallbash spotify bar)
case $output in
*'ran with args: bar'*) ;;
*)
    fail "wallbash spotify (no extension) did not run the script: got '$output' (stderr: $(cat "$work_dir/stderr"))"
    ;;
esac

# Out-of-spec: a name that isn't a script at all, with or without ".sh",
# must still fall through to the usage/help text -- not be silently
# swallowed, and not crash.
for missing in "nonexistent" "nonexistent.sh"; do
    output=$(run_wallbash "$missing")
    case $output in
    *'Usage: wallbash'*) ;;
    *)
        fail "wallbash $missing (which does not exist) did not show the usage text: got '$output' (stderr: $(cat "$work_dir/stderr"))"
        ;;
    esac
done

# Boundary: a script literally named "x.sh.sh" (unusual, but the glob
# doesn't forbid it) must still be reachable by its exact real name -- the
# fix must strip at most one trailing ".sh", not repeatedly.
cat >"$scripts_dir/oddname.sh.sh" <<'EOF'
#!/usr/bin/env bash
echo "odd script ran"
EOF
chmod +x "$scripts_dir/oddname.sh.sh"
output=$(run_wallbash oddname.sh.sh)
case $output in
*'odd script ran'*) ;;
*)
    fail "wallbash oddname.sh.sh (its exact real filename) did not run: got '$output' (stderr: $(cat "$work_dir/stderr"))"
    ;;
esac

finish
