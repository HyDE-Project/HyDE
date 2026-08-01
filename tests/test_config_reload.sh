#!/usr/bin/env sh
# Hyprland runs the whole Lua configuration under a single 1500 ms budget, and
# its watchdog is installed with LUA_MASKCOUNT: it counts VM instructions, so it
# cannot interrupt a blocked C call. A subprocess started while the
# configuration loads therefore spends the budget where nothing can attribute
# it, and the timeout surfaces in whichever module runs next — a parser, a bind
# table, anything with a tight Lua loop, none of which are the cause.
#
# Nothing the session loads at reload time may fork. The scan covers the whole
# shipped hypr tree, entry point included, since that is what Hyprland executes.

# shellcheck source=tests/lib/common.sh
. "$(dirname -- "$0")/lib/common.sh"

config_dir="$REPO_ROOT/Configs/.local/share/hypr"
[ -d "$config_dir" ] || {
    fail "the shipped Hyprland directory is missing"
    finish
}

list=$(mktemp)
trap 'rm -f "$list"' EXIT
find "$config_dir" -name '*.lua' -type f | sort > "$list"

# The TOML parser is the one library outside that tree the configuration pulls
# in — hyde/config.lua requires it, and it requires nothing further. The rest of
# luautils is shared with command line tools, where a subprocess is legitimate.
toml="$REPO_ROOT/Configs/.local/lib/hyde/luautils/toml.lua"
[ -f "$toml" ] && printf '%s\n' "$toml" >> "$list"

count=0
while IFS= read -r file; do
    count=$((count + 1))

    hits=$(grep -nE 'io\.popen|os\.execute' "$file")
    status=$?

    # grep answers 1 for a file with no match and 2 or more for a failure to
    # read one, which must not pass as "nothing found".
    if [ "$status" -gt 1 ]; then
        fail "${file#"$REPO_ROOT"/} could not be scanned"
        continue
    fi

    [ -z "$hits" ] && continue

    printf '%s\n' "$hits" | while IFS= read -r hit; do
        printf '    %s:%s\n' "${file#"$REPO_ROOT"/}" "$hit"
    done
    fail "${file#"$REPO_ROOT"/} blocks the configuration on a subprocess"
done < "$list"

# A guard that scans nothing passes for the wrong reason, and would keep doing
# so if the tree moved out from under it.
[ "$count" -gt 0 ] ||
    fail "no Lua file was scanned, the configuration tree is not where this expects it"

printf '    %d file(s) checked\n' "$count"

finish
