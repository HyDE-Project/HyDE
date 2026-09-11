#!/usr/bin/env sh
# lutris.py must not embed an unvalidated slug into run_command --
# gamelauncher.sh runs it through eval, so a slug containing a stray quote
# or shell metacharacter would be an injection vector (#2018).

. "$(dirname -- "$0")/lib/common.sh"

if ! command -v python3 >/dev/null 2>&1; then
    skip "python3 is not installed"
    finish
fi

python3 "$TESTS_DIR/python/check_lutris_slug_validation.py" ||
    fail "check_lutris_slug_validation reported defects"

finish
