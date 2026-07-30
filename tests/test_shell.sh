#!/usr/bin/env sh
# Every shipped shell script has to parse, shellcheck has to find no
# error-severity problem in it, and a script that declares sh has to stay
# within what sh provides.
#
# Parsing is done with bash for every file, since hyde-shell runs every .sh
# with bash regardless of the shebang. Whether an sh shebang is honest is a
# separate question, answered below by the dialect shellcheck infers from it:
# a file that promises sh and then uses arrays or `local` breaks the moment it
# is run directly on a system where /bin/sh is dash.

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

# SC3xxx is the dialect family: a construct the shebang's shell does not have.
# It is reported below error severity, so it needs its own pass.
posix_count=0
for file in $scripts; do
    case $(head -n 1 "$file") in
        '#!'*[!a-z]sh | '#!'*[!a-z]sh' '*) ;;
        *) continue ;;
    esac

    posix_count=$((posix_count + 1))

    findings=$(shellcheck --format=gcc "$file" 2>/dev/null | grep 'SC3[0-9][0-9][0-9]')
    [ -n "$findings" ] || continue

    printf '%s\n' "$findings" | while IFS= read -r line; do
        printf '    %s\n' "$line"
    done
    fail "${file#"$REPO_ROOT"/} declares sh but uses constructs sh does not have"
done

printf '    %d file(s) checked against the sh dialect\n' "$posix_count"

finish
