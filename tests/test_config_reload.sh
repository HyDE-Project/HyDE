#!/usr/bin/env sh
# Hyprland runs the whole Lua configuration under a single 1500 ms budget, and
# its watchdog is installed with LUA_MASKCOUNT: it counts VM instructions, so it
# cannot interrupt a blocked C call. A subprocess started while the
# configuration loads therefore spends the budget where nothing can attribute
# it, and the timeout surfaces in whichever module runs next — a parser, a bind
# table, anything with a tight Lua loop, none of which are the cause.
#
# Nothing the session loads at reload time may fork.

# shellcheck source=tests/lib/common.sh
. "$(dirname -- "$0")/lib/common.sh"

config_dir="$REPO_ROOT/Configs/.local/share/hypr/lua"
[ -d "$config_dir" ] || {
    fail "the shipped Hyprland Lua directory is missing"
    finish
}

count=0
for file in $(find "$config_dir" -name '*.lua' -type f | sort); do
    count=$((count + 1))

    hits=$(grep -nE 'io\.popen|os\.execute' "$file" || true)
    [ -z "$hits" ] && continue

    printf '%s\n' "$hits" | while IFS= read -r hit; do
        printf '    %s:%s\n' "${file#"$REPO_ROOT"/}" "$hit"
    done
    fail "${file#"$REPO_ROOT"/} blocks the configuration on a subprocess"
done

printf '    %d file(s) checked\n' "$count"

finish
