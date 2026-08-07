#!/usr/bin/env sh
# The dependency steps have to resolve the group they include.

. "$(dirname -- "$0")/lib/common.sh"

if ! command -v python3 >/dev/null 2>&1; then
    skip "python3 is not installed"
    finish
fi

python3 "$TESTS_DIR/python/check_install_config.py" ||
    fail "the configs install.sh generates do not load their group"

finish
