#!/usr/bin/env sh
# The app wrapper must isolate app2unit and xdg-terminal-exec from unrelated
# DEBUG values on both its systemd and direct-exec paths.

. "$(dirname -- "$0")/lib/common.sh"

wrapper="$REPO_ROOT/Configs/.local/lib/hyde/app.sh"

fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT HUP INT TERM

cat >"$fixture/app2unit" <<'EOF'
#!/usr/bin/env sh
printf 'APP2UNIT_DEBUG=%s\n' "${APP2UNIT_DEBUG-<unset>}"
printf 'XTE_DEBUG=%s\n' "${XTE_DEBUG-<unset>}"
while [ "$#" -gt 0 ] && [ "$1" != "--" ]; do
    shift
done
[ "$#" -gt 0 ] && shift
exec "$@"
EOF

cat >"$fixture/xdg-terminal-exec" <<'EOF'
#!/usr/bin/env sh
printf 'APP2UNIT_CONSUMER_DEBUG=%s\n' "${APP2UNIT_DEBUG-${DEBUG-0}}"
printf 'XTE_CONSUMER_DEBUG=%s\n' "${XTE_DEBUG-${DEBUG-0}}"
EOF
chmod +x "$fixture/app2unit" "$fixture/xdg-terminal-exec"

output=$(
    unset APP2UNIT_DEBUG XTE_DEBUG
    export DEBUG=release
    PATH="$fixture:$PATH" "$wrapper" -- xdg-terminal-exec 2>&1
)
status=$?

if [ "$status" -ne 0 ]; then
    fail "app wrapper exited with $status"
fi

printf '%s\n' "$output" | grep -qx 'APP2UNIT_CONSUMER_DEBUG=0' ||
    fail "app wrapper leaked DEBUG through APP2UNIT_DEBUG"
printf '%s\n' "$output" | grep -qx 'XTE_CONSUMER_DEBUG=0' ||
    fail "app wrapper leaked DEBUG into xdg-terminal-exec"

if [ -d /run/systemd/system ]; then
    printf '%s\n' "$output" | grep -qx 'APP2UNIT_DEBUG=0' ||
        fail "app wrapper did not default APP2UNIT_DEBUG to 0"
    printf '%s\n' "$output" | grep -qx 'XTE_DEBUG=0' ||
        fail "app wrapper did not default XTE_DEBUG to 0"
fi

export_line=$(grep -n '^export APP2UNIT_DEBUG XTE_DEBUG$' "$wrapper" | cut -d: -f1)
systemd_line=$(grep -n '^if \[ -d "/run/systemd/system" \]; then$' "$wrapper" | cut -d: -f1)

if [ -z "$export_line" ] || [ -z "$systemd_line" ] || [ "$export_line" -ge "$systemd_line" ]; then
    fail "scoped debug defaults are not exported before the execution-path branch"
fi

override_output=$(
    export DEBUG=release
    export APP2UNIT_DEBUG=1
    export XTE_DEBUG=yes
    PATH="$fixture:$PATH" "$wrapper" -- xdg-terminal-exec 2>&1
)
override_status=$?

if [ "$override_status" -ne 0 ]; then
    fail "app wrapper with explicit debug values exited with $override_status"
fi

printf '%s\n' "$override_output" | grep -qx 'APP2UNIT_CONSUMER_DEBUG=1' ||
    fail "app wrapper did not preserve APP2UNIT_DEBUG"
printf '%s\n' "$override_output" | grep -qx 'XTE_CONSUMER_DEBUG=yes' ||
    fail "app wrapper did not preserve XTE_DEBUG"

finish
