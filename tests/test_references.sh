#!/usr/bin/env sh
# Shipped configs must not reference files the Lua release removed.

. "$(dirname -- "$0")/lib/common.sh"

configs_dir="$REPO_ROOT/Configs"
checked=0

# Retired names and the replacement each caller should use instead. The legacy
# restore_cfg.* pair under Scripts/ is deliberately out of scope: it deploys the
# pre-Lua tree and is no longer wired into the installer.
check_retired() {
    retired=$1
    replacement=$2
    hits=$(grep -rIl -- "$retired" "$configs_dir" 2>/dev/null || true)
    checked=$((checked + 1))
    [ -z "$hits" ] && return 0
    for hit in $hits; do
        fail "$(printf '%s references retired %s (use %s)' "${hit#"$REPO_ROOT"/}" "$retired" "$replacement")"
    done
}

check_retired 'hyde-shell themeswitch' 'hyde-shell theme.switch'
check_retired 'themeswitch.sh' 'theme.switch.sh'
check_retired 'hyde/open.sh' 'hyde-shell open'
check_retired 'hypr/keybindings.conf' 'hypr/hyprland.lua'
check_retired 'hypr/userprefs.conf' 'hypr/hyprland.lua'
check_retired 'hypr/windowrules.conf' 'hypr/hyprland.lua'
check_retired 'hypr/nvidia.conf' 'hypr/hyprland.lua'

# The Lua entry point is deployed as hyde.lua under XDG_DATA_HOME; every shell
# integration has to agree on that name or a session starts with no config.
entry_point="$configs_dir/.local/share/hypr/hyde.lua"
[ -f "$entry_point" ] || fail "the Lua entry point Configs/.local/share/hypr/hyde.lua is missing"
checked=$((checked + 1))

for integration in \
    ".config/uwsm/env-hyprland.d/00-hyde.sh" \
    ".config/fish/conf.d/hyde.fish"; do
    path="$configs_dir/$integration"
    [ -f "$path" ] || continue
    checked=$((checked + 1))
    grep -q 'HYPRLAND_CONFIG' "$path" || continue
    grep -q 'hypr/hyde\.lua' "$path" ||
        fail "$integration sets HYPRLAND_CONFIG without pointing at hypr/hyde.lua"
    grep -E 'HYPRLAND_CONFIG.*hypr/hyprland\.(conf|lua)' "$path" >/dev/null &&
        fail "$integration still defaults HYPRLAND_CONFIG to a path no dot deploys"
done

printf '    %d reference rule(s) checked\n' "$checked"
finish
