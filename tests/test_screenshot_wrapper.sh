#!/usr/bin/env bash
# Satty needs a compatible GTK renderer when launched from Hyprland's
# environment, but explicit user choices must still win.

# shellcheck source=tests/lib/common.sh
. "$(dirname -- "$0")/lib/common.sh"

wrapper="$REPO_ROOT/Configs/.local/lib/hyde/screenshot.sh"
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT HUP INT TERM

mkdir -p "$fixture/bin" "$fixture/lib/hyde/screenshot" "$fixture/runtime" "$fixture/pictures"

cat >"$fixture/bin/hyde-shell" <<EOF
#!/usr/bin/env sh
if [ "\$1" = "init" ]; then
    cat <<'INIT'
HYDE_SHELL_INIT=1
LIB_DIR="$fixture/lib"
XDG_RUNTIME_DIR="$fixture/runtime"
XDG_PICTURES_DIR="$fixture/pictures"
SCREENSHOT_ANNOTATION_ENABLED=true
SCREENSHOT_ANNOTATION_TOOL=satty
SCREENSHOT_POST_COMMAND=()
SCREENSHOT_PRE_COMMAND=()
SCREENSHOT_OCR_TESSERACT_LANGUAGES=("eng")
SCREENSHOT_ANNOTATION_ARGS=()
pkg_installed() { command -v "\$1" >/dev/null 2>&1; }
print_log() { :; }
send_notifs() { :; }
INIT
fi
EOF

cat >"$fixture/lib/hyde/screenshot/grimblast" <<'EOF'
#!/usr/bin/env sh
for target_file in "$@"; do :; done
: >"$target_file"
EOF

cat >"$fixture/bin/satty" <<'EOF'
#!/usr/bin/env sh
printf 'GSK_RENDERER=%s\n' "${GSK_RENDERER-<unset>}"
EOF

chmod +x "$fixture/bin/hyde-shell" "$fixture/bin/satty" "$fixture/lib/hyde/screenshot/grimblast"

default_output=$(PATH="$fixture/bin:$PATH" "$wrapper" s --no-notify 2>&1)
default_status=$?

if [ "$default_status" -ne 0 ]; then
    fail "screenshot wrapper with default renderer exited with $default_status"
fi

printf '%s\n' "$default_output" | grep -qx 'GSK_RENDERER=gl' ||
    fail "Satty did not receive the compatible GL renderer default"

override_output=$(GSK_RENDERER=cairo PATH="$fixture/bin:$PATH" "$wrapper" s --no-notify 2>&1)
override_status=$?

if [ "$override_status" -ne 0 ]; then
    fail "screenshot wrapper with explicit renderer exited with $override_status"
fi

printf '%s\n' "$override_output" | grep -qx 'GSK_RENDERER=cairo' ||
    fail "screenshot wrapper did not preserve the explicit renderer"

finish
