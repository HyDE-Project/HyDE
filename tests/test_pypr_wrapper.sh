#!/usr/bin/env bash
# The Pyprland wrapper must preserve command arguments when socket helper
# programs are unavailable and it falls back to the Pyprland CLI.

# shellcheck source=tests/lib/common.sh
. "$(dirname -- "$0")/lib/common.sh"

hyde_shell="$REPO_ROOT/Configs/.local/bin/hyde-shell"
fixture=$(mktemp -d)
server_pid=

cleanup() {
    if [[ -n "$server_pid" ]]; then
        kill "$server_pid" 2>/dev/null || true
        wait "$server_pid" 2>/dev/null || true
    fi
    rm -rf "$fixture"
}
trap cleanup EXIT HUP INT TERM

mkdir -p \
    "$fixture/bin" \
    "$fixture/config/pypr" \
    "$fixture/runtime/hypr/test-instance" \
    "$fixture/state/hyde/python_env/bin"
: >"$fixture/config/pypr/config.toml"
: >"$fixture/state/hyde/python_env/bin/activate"

for helper in nc socat ncat; do
    cat >"$fixture/bin/$helper" <<'EOF'
#!/usr/bin/env sh
exit 1
EOF
done

cat >"$fixture/bin/pgrep" <<'EOF'
#!/usr/bin/env sh
exit 0
EOF

cat >"$fixture/bin/pypr" <<'EOF'
#!/usr/bin/env sh
printf '<%s>\n' "$@"
EOF
chmod +x "$fixture/bin/"*

socket_path="$fixture/runtime/hypr/test-instance/.pyprland.sock"
python3 - "$socket_path" <<'PY' &
import socket
import sys
import time

server = socket.socket(socket.AF_UNIX)
server.bind(sys.argv[1])
time.sleep(30)
PY
server_pid=$!

for _ in {1..100}; do
    [[ -S "$socket_path" ]] && break
    sleep 0.01
done

if [[ ! -S "$socket_path" ]]; then
    fail "test Pyprland socket was not created"
    finish
fi

output=$(
    PATH="$fixture/bin:/usr/bin:/bin" \
        XDG_CONFIG_HOME="$fixture/config" \
        XDG_RUNTIME_DIR="$fixture/runtime" \
        XDG_STATE_HOME="$fixture/state" \
        HYPRLAND_INSTANCE_SIGNATURE=test-instance \
        "$hyde_shell" pypr toggle console 2>"$fixture/hyde-shell.stderr"
)
status=$?

if [[ "$status" -ne 0 ]]; then
    fail "Pyprland CLI fallback exited with $status: $(<"$fixture/hyde-shell.stderr")"
fi

if [[ "$output" != $'<toggle>\n<console>' ]]; then
    fail "Pyprland CLI fallback did not preserve command arguments: $output"
fi

finish
