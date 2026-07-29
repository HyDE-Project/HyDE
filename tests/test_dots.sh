#!/usr/bin/env sh
# The installer's dot metafiles have to be well formed.

. "$(dirname -- "$0")/lib/common.sh"

if ! command -v python3 >/dev/null 2>&1; then
    skip "python3 is not installed"
    finish
fi

python3 "$TESTS_DIR/python/check_dots.py" || fail "check_dots reported defects"

finish
