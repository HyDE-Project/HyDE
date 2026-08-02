#!/usr/bin/env sh
# Every shipped Lua file has to parse.

. "$(dirname -- "$0")/lib/common.sh"

if ! command -v luac >/dev/null 2>&1; then
    skip "luac is not installed"
    finish
fi

count=0
for file in $(find "$REPO_ROOT/Configs" -name '*.lua' -type f | sort); do
    count=$((count + 1))
    luac -p "$file" >/dev/null 2>&1 || fail "${file#"$REPO_ROOT"/} does not parse"
done

printf '    %d file(s) checked\n' "$count"
finish
