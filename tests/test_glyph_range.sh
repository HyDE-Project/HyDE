#!/usr/bin/env sh
# A shipped config may only name glyphs the deployed fonts carry.

. "$(dirname -- "$0")/lib/common.sh"

if ! command -v python3 > /dev/null 2>&1; then
    skip "python3 is not installed"
    finish
fi

python3 "$TESTS_DIR/python/check_glyph_range.py" ||
    fail "a config names a glyph Nerd Fonts v3 dropped"

finish
