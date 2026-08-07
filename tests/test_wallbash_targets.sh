#!/usr/bin/env sh
# Wallbash only renders into a directory that is already there.

. "$(dirname -- "$0")/lib/common.sh"

if ! command -v python3 >/dev/null 2>&1; then
    skip "python3 is not installed"
    finish
fi

python3 "$TESTS_DIR/python/check_wallbash_targets.py" ||
    fail "a wallbash target has no dot deploying its directory"

finish
