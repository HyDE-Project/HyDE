#!/usr/bin/env sh
# End-to-end: hint-hyprland.py run as a real process against a stubbed
# `hyprctl binds -j` and a real cache file, not just its functions imported
# directly (that's tests/test_keybind_hint_resolve.sh). Also the direct
# evidence for the one thing kRHYME7 asked about on #1996 (memory/cost
# during a normal run): no `lua` binary is ever on PATH here, so
# hint-hyprland.py re-parsing or re-executing the Lua config at hint-time,
# instead of only reading the cache hyde/binds.lua already wrote, would fail
# this test outright rather than merely being slow.

. "$(dirname -- "$0")/lib/common.sh"

if ! command -v python3 >/dev/null 2>&1; then
    skip "python3 is not installed"
    finish
fi

script="$REPO_ROOT/Configs/.local/lib/hyde/keybinds/hint-hyprland.py"
[ -f "$script" ] || {
    fail "hint-hyprland.py not found at $script"
    finish
}

work_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$work_dir"' EXIT

bin_dir="$work_dir/bin"
mkdir -p "$bin_dir" "$work_dir/cache/hyde"

# A resolvable __lua bind (SUPER + T), an unresolvable one (SUPER + Q, not in
# the cache below), and a plain non-__lua bind, in the exact shape
# `hyprctl binds -j` actually reports.
cat >"$bin_dir/hyprctl" <<'STUB'
#!/usr/bin/env sh
if [ "$1" = "binds" ]; then
    cat <<'JSON'
[
  {
    "modmask": 64, "submap": "", "key": "T", "keycode": 0, "catch_all": false,
    "description": "", "has_description": false, "locked": false, "mouse": false,
    "release": false, "repeat": false, "long_press": false, "arg": "5", "dispatcher": "__lua"
  },
  {
    "modmask": 64, "submap": "", "key": "Q", "keycode": 0, "catch_all": false,
    "description": "", "has_description": false, "locked": false, "mouse": false,
    "release": false, "repeat": false, "long_press": false, "arg": "9", "dispatcher": "__lua"
  },
  {
    "modmask": 64, "submap": "", "key": "B", "keycode": 0, "catch_all": false,
    "description": "", "has_description": false, "locked": false, "mouse": false,
    "release": false, "repeat": false, "long_press": false, "arg": "firefox", "dispatcher": "exec"
  }
]
JSON
    exit 0
fi
echo "unexpected hyprctl invocation: $*" >&2
exit 1
STUB
chmod +x "$bin_dir/hyprctl"

# Shadows any real `lua` on PATH with one that fails loudly instead of
# silently succeeding -- if hint-hyprland.py ever shells out to it, this
# turns that into a hard, specific test failure instead of just being slow.
cat >"$bin_dir/lua" <<'STUB'
#!/usr/bin/env sh
echo "hint-hyprland.py invoked lua at hint-time -- it must only read hyde/binds.lua's cache file" >&2
exit 1
STUB
chmod +x "$bin_dir/lua"

cat >"$work_dir/cache/hyde/lua_bind_commands.json" <<'JSON'
{"SUPER + T": "kitty"}
JSON

run() {
    XDG_CACHE_HOME="$work_dir/cache" PATH="$bin_dir:$PATH" python3 "$script" "$@"
}

rofi_out=$(run --format rofi 2>"$work_dir/stderr") || {
    fail "hint-hyprland.py --format rofi exited non-zero: $(cat "$work_dir/stderr")"
    finish
}

case $rofi_out in
*'hl.dsp.exec_cmd("kitty")'*) ;;
*) fail "the resolvable SUPER + T bind was not rewritten in rofi output" ;;
esac

resolved_line=$(printf '%s\n' "$rofi_out" | grep 'exec_cmd("kitty")')
case $resolved_line in
*' ::: 9 :::'*) fail "the resolved bind's arg still carries the old opaque ref" ;;
esac

unresolved_line=$(printf '%s\n' "$rofi_out" | grep ':::.*__lua.*::: 9 :::')
[ -n "$unresolved_line" ] ||
    fail "the unresolvable SUPER + Q bind (not in the cache) lost its __lua dispatcher"

case $rofi_out in
*'::: exec ::: firefox :::'*) ;;
*) fail "the plain exec bind was altered even though it isn't __lua" ;;
esac

# JSON output is the same expand_meta_data() pass, not a separate code path
# -- confirm the rewrite shows up there too, not just in the rofi formatter.
json_out=$(run --format json 2>/dev/null) || fail "hint-hyprland.py --format json exited non-zero"
printf '%s\n' "$json_out" | python3 -c '
import json, sys
binds = json.load(sys.stdin)
by_key = {(b["modmask"], b["key"]): b for b in binds}
t = by_key[(64, "T")]
q = by_key[(64, "Q")]
b = by_key[(64, "B")]
assert t["dispatcher"] == "hl.dsp.exec_cmd(\"kitty\")", t
assert t["arg"] == "", t
assert q["dispatcher"] == "__lua" and q["arg"] == "9", q
assert b["dispatcher"] == "exec" and b["arg"] == "firefox", b
' || fail "the JSON output did not show the same resolution as rofi output"

finish
