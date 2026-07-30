#!/usr/bin/env sh
# The installer's dot metafiles have to be well formed.

. "$(dirname -- "$0")/lib/common.sh"

if ! command -v python3 >/dev/null 2>&1; then
    skip "python3 is not installed"
    finish
fi

python3 "$TESTS_DIR/python/check_dots.py" || fail "check_dots reported defects"

hyde_metafile="$REPO_ROOT/Scripts/dots/hyde.toml"
official_grimblast='source = "blob+https://raw.githubusercontent.com/hyprwm/contrib/refs/heads/main/grimblast/grimblast"'

grep -Fqx "$official_grimblast" "$hyde_metafile" ||
    fail "grimblast is not sourced from the fixed upstream main branch"

if grep -q 'feature-grimblast-toplevel-handle' "$hyde_metafile"; then
    fail "grimblast still uses the double-selection experimental branch"
fi

finish
