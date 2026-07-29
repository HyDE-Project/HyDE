#!/usr/bin/env sh
# Shared helpers for the test cases.

TESTS_DIR=${TESTS_DIR:-$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)}
export TESTS_DIR

# The tree under test. Defaults to the checkout the suite lives in, and can
# be pointed at another one to check it with this suite.
REPO_ROOT=${REPO_ROOT:-$(CDPATH='' cd -- "$TESTS_DIR/.." && pwd)}
export REPO_ROOT

_failures=0

fail() {
    _failures=$((_failures + 1))
    printf '    fail: %s\n' "$1"
}

skip() {
    printf '    skip: %s\n' "$1"
}

finish() {
    if [ "$_failures" -ne 0 ]; then
        printf '    %d failure(s)\n' "$_failures"
        exit 1
    fi
    exit 0
}
