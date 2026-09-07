#!/usr/bin/env sh
# gamelauncher.sh must actually run a selected game, not just try to and
# silently fail. run_command (from steam.py/lutris.py/catalog.py) is a full
# shell command line, e.g. `xdg-open "lutris:rungame/some-slug"` -- quoted
# `exec "$cmd"` treats that whole string as a single program name and always
# fails, which is exactly what #2018 reports ("select a game, nothing
# happens"), introduced by b87c44b8 replacing the working `eval exec "$cmd"`.

. "$(dirname -- "$0")/lib/common.sh"

script="$REPO_ROOT/Configs/.local/lib/hyde/gamelauncher.sh"
[ -f "$script" ] || {
    fail "gamelauncher.sh not found at $script"
    finish
}

work_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$work_dir"' EXIT

bin_dir="$work_dir/bin"
python_dir="$work_dir/hyde/python_env/bin"
mkdir -p "$bin_dir" "$python_dir"

# Stands in for steam.py/lutris.py/catalog.py: gamelauncher.sh hardcodes the
# interpreter path via XDG_STATE_HOME rather than looking one up on PATH, so
# pointing XDG_STATE_HOME here is what actually substitutes it. Always
# emits one fixture line shaped like lutris.py's real run_command, but with
# a deliberate space *inside* the quoted argument -- naive word-splitting
# (as opposed to real shell-quote-aware parsing) would wrongly cut this into
# three argv pieces with stray literal quote characters, so this fails
# either the old bug (single mangled argv) or a half-fix (unquoted
# splitting) the same way, not just the one this repo happened to ship.
cat >"$python_dir/python" <<'STUB'
#!/usr/bin/env sh
printf 'Test Game\txdg-open "lutris:rungame/my slug"\n'
STUB
chmod +x "$python_dir/python"

# Stands in for the real interactive rofi: -dmenu mode reads candidate lines
# on stdin and prints the one line the user picked back out unchanged: this
# always "picks" the first one, deterministically.
cat >"$bin_dir/rofi" <<'STUB'
#!/usr/bin/env sh
sed -n '1p'
STUB
chmod +x "$bin_dir/rofi"

# The command gamelauncher.sh is ultimately supposed to run -- records
# exactly the argv it was invoked with, one argument per line, so the test
# can tell a correctly-split multi-word invocation from a mangled one.
cat >"$bin_dir/xdg-open" <<STUB
#!/usr/bin/env sh
for arg in "\$@"; do printf '%s\n' "\$arg"; done >"$work_dir/xdg-open.args"
STUB
chmod +x "$bin_dir/xdg-open"

run_gamelauncher() {
    HYDE_SHELL_INIT=1 \
        LIB_DIR="$REPO_ROOT/Configs/.local/lib" \
        XDG_STATE_HOME="$work_dir" \
        PATH="$bin_dir:$PATH" \
        bash "$script" --style catalog_dummy --backend lutris
}

# --style anything-non-numeric-and-not-steam_deck skips the steam_deck
# branch entirely (hyprctl/jq/magick, none of which this test stubs -- it
# isn't what's under test here).
run_gamelauncher >"$work_dir/out" 2>"$work_dir/err"
status=$?

[ "$status" -eq 0 ] || fail "gamelauncher.sh exited $status: $(cat "$work_dir/err")"

[ -f "$work_dir/xdg-open.args" ] ||
    fail "xdg-open was never invoked -- the selected game did not launch at all: $(cat "$work_dir/err")"

if [ -f "$work_dir/xdg-open.args" ]; then
    argv=$(cat "$work_dir/xdg-open.args")
    expected='lutris:rungame/my slug'
    [ "$argv" = "$expected" ] ||
        fail "xdg-open received $(wc -l <"$work_dir/xdg-open.args") argument(s) reading '$argv', expected exactly one: '$expected'"
fi

finish
