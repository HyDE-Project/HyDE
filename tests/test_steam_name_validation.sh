#!/usr/bin/env sh
# Steam display names become the first field in tab-delimited launcher rows.

. "$(dirname -- "$0")/lib/common.sh"

if ! command -v python3 >/dev/null 2>&1; then
    skip "python3 is not installed"
    finish
fi

python3 "$TESTS_DIR/python/check_steam_name_validation.py" ||
    fail "check_steam_name_validation reported defects"

finish
