#!/usr/bin/env sh
# The app wrapper must isolate app2unit from unrelated DEBUG values.

. "$(dirname -- "$0")/lib/common.sh"

wrapper="$REPO_ROOT/Configs/.local/lib/hyde/app.sh"

if [ ! -d /run/systemd/system ]; then
    skip "systemd is not available"
    finish
fi

fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT HUP INT TERM

cat >"$fixture/app2unit" <<'EOF'
#!/usr/bin/env sh
printf 'APP2UNIT_DEBUG=%s\n' "${APP2UNIT_DEBUG-<unset>}"
printf 'XTE_DEBUG=%s\n' "${XTE_DEBUG-<unset>}"
EOF
chmod +x "$fixture/app2unit"

output=$(
    unset APP2UNIT_DEBUG XTE_DEBUG
    export DEBUG=release
    PATH="$fixture:$PATH" "$wrapper" 2>&1
)
status=$?

if [ "$status" -ne 0 ]; then
    fail "app wrapper exited with $status"
fi

printf '%s\n' "$output" | grep -qx 'APP2UNIT_DEBUG=0' ||
    fail "app wrapper did not default APP2UNIT_DEBUG to 0"
printf '%s\n' "$output" | grep -qx 'XTE_DEBUG=0' ||
    fail "app wrapper did not default XTE_DEBUG to 0"

finish
