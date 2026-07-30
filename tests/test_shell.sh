#!/usr/bin/env sh
# Every shipped shell script has to parse, and shellcheck has to find no
# error-severity problem in it.
#
# Parsing is done with bash rather than the interpreter each script declares.
# Several scripts carry an sh shebang while using arrays and `local`, and
# hyde-shell runs every .sh with bash regardless, so checking them as POSIX sh
# would report a mismatch this suite is not the place to resolve.

. "$(dirname -- "$0")/lib/common.sh"

scripts=$(find "$REPO_ROOT/Configs" "$REPO_ROOT/Scripts" "$REPO_ROOT/tests" -name '*.sh' -type f | sort)

count=0
for file in $scripts; do
    count=$((count + 1))

    bash -n "$file" 2>/dev/null || fail "${file#"$REPO_ROOT"/} does not parse"
done

printf '    %d file(s) parsed\n' "$count"

if ! command -v shellcheck >/dev/null 2>&1; then
    skip "shellcheck is not installed"
    finish
fi

report=$(printf '%s\n' "$scripts" | xargs shellcheck --severity=error --format=gcc)
status=$?

if [ -n "$report" ]; then
    printf '%s\n' "$report" | while IFS= read -r line; do
        printf '    %s\n' "$line"
    done
    fail "shellcheck reported error-severity findings"
elif [ "$status" -ne 0 ]; then
    fail "shellcheck exited with $status without reporting anything"
fi

finish
