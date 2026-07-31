#!/usr/bin/env sh
# Runs every test case in this directory and reports the result.
#
# Usage:
#   tests/run.sh            run every case
#   tests/run.sh binds      run the cases whose name contains "binds"
#
# A case is any executable tests/test_*.sh. It prints its own diagnostics and
# exits non-zero on failure.

set -u

TESTS_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
export TESTS_DIR
tests_dir=$TESTS_DIR
# Honour a pre-set REPO_ROOT so the suite can be pointed at another tree.
REPO_ROOT=${REPO_ROOT:-$(CDPATH='' cd -- "$tests_dir/.." && pwd)}
export REPO_ROOT

filter=${1:-}
total=0
failed=0

for case_path in "$tests_dir"/test_*.sh; do
    [ -f "$case_path" ] || continue

    case_name=$(basename "$case_path" .sh)
    if [ -n "$filter" ]; then
        case "$case_name" in
            *"$filter"*) ;;
            *) continue ;;
        esac
    fi

    total=$((total + 1))
    printf '%s\n' "$case_name"

    # An executable case runs under its own shebang; a plain file still runs,
    # so a forgotten chmod does not silently drop coverage.
    if [ -x "$case_path" ]; then
        "$case_path"
        status=$?
    else
        sh "$case_path"
        status=$?
    fi

    if [ "$status" -eq 0 ]; then
        printf '  ok\n'
    else
        printf '  FAILED\n'
        failed=$((failed + 1))
    fi
done

if [ "$total" -eq 0 ]; then
    printf 'no test cases matched\n' >&2
    exit 1
fi

printf '\n%d case(s), %d failed\n' "$total" "$failed"
[ "$failed" -eq 0 ]
