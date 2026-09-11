#!/usr/bin/env bash
# `hyde-shell app` launches a service/scope via `exec`, so a process started
# through it (every hc.start.* entry in variables.lua uses this path) has to
# inherit whatever HyDE's generated config exports. This case used to skip
# globalcontrol.sh entirely -- and with it export_hyde_config(), which
# sources ~/.local/state/hyde/config (config.toml's generated env vars, e.g.
# BATTERY_NOTIFY_DOCK) -- and only reached it on hyde-shell's other,
# non-"app" code path (#1951).

. "$(dirname -- "$0")/lib/common.sh"

hyde_shell="$REPO_ROOT/Configs/.local/bin/hyde-shell"
[ -f "$hyde_shell" ] || {
    fail "hyde-shell not found at $hyde_shell"
    finish
}

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

home_dir="$work_dir/home"
mkdir -p "$home_dir/.local/state/hyde" "$home_dir/.config"
printf 'export BATTERY_NOTIFY_DOCK=true\n' >"$home_dir/.local/state/hyde/config"

# app.sh hands off to app2unit when a systemd user session exists, or to a
# plain `exec` of the trailing command otherwise -- this fake stands in for
# both identically, so the test doesn't depend on whether this machine
# happens to have one running.
fake_bin="$work_dir/fake_bin"
mkdir -p "$fake_bin"
cat >"$fake_bin/app2unit" <<'EOF'
#!/bin/sh
while [ "$#" -gt 0 ] && [ "$1" != "--" ]; do shift; done
[ "$#" -gt 0 ] && shift
exec "$@"
EOF
chmod +x "$fake_bin/app2unit"

bin_dir=$(dirname "$hyde_shell")

##
# Runs `hyde-shell app -- "$@"` against the sandboxed HOME, with the fake
# app2unit and the real hyde-shell/its sibling scripts on PATH.
##
run_app() {
    env -i \
        HOME="$home_dir" \
        XDG_CONFIG_HOME="$home_dir/.config" \
        XDG_DATA_HOME="$home_dir/.local/share" \
        XDG_CACHE_HOME="$home_dir/.cache" \
        XDG_STATE_HOME="$home_dir/.local/state" \
        XDG_RUNTIME_DIR="$home_dir/run" \
        PATH="$fake_bin:$bin_dir:/usr/bin:/bin" \
        bash "$hyde_shell" app -- "$@"
}

output=$(run_app sh -c 'echo "BATTERY_NOTIFY_DOCK=$BATTERY_NOTIFY_DOCK"' 2>"$work_dir/stderr")

case $output in
*'BATTERY_NOTIFY_DOCK=true'*) ;;
*)
    fail "hyde-shell app did not forward BATTERY_NOTIFY_DOCK from ~/.local/state/hyde/config to the launched process: got '$output' (stderr: $(cat "$work_dir/stderr"))"
    ;;
esac

# Out-of-spec: no generated config file at all (a fresh install, or a user
# who never set anything in config.toml) must not turn into a hard failure --
# export_hyde_config() is documented to treat an absent file as success, and
# that has to keep holding on this newly-added call site too.
rm -f "$home_dir/.local/state/hyde/config"
missing_output=$(run_app sh -c 'echo "status=ok BATTERY_NOTIFY_DOCK=$BATTERY_NOTIFY_DOCK"' 2>"$work_dir/stderr")
case $missing_output in
*'status=ok'*) ;;
*)
    fail "hyde-shell app failed outright with no generated config file present: got '$missing_output' (stderr: $(cat "$work_dir/stderr"))"
    ;;
esac
case $missing_output in
*'BATTERY_NOTIFY_DOCK=true'*)
    fail "a variable from a nonexistent config file was still set: $missing_output"
    ;;
esac

finish
