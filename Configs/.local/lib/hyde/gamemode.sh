#!/usr/bin/env bash
# Toggle the 'gaming' workflow, returning to the previously active
# workflow when toggled off.
#
# State is persisted through the workflows mechanism (workflows.conf is
# sourced by hyprland.conf) plus staterc, so it survives any
# 'hyprctl reload' — unlike the previous implementation that injected
# gaming.conf as a volatile runtime keyword, which every reload
# (wallpaper change, theme switch, ...) silently wiped while its lock
# file kept claiming gamemode was still on.
[[ $HYDE_SHELL_INIT -ne 1 ]] && eval "$(hyde-shell init)"

confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
staterc="${XDG_STATE_HOME:-$HOME/.local/state}/hyde/staterc"
# shellcheck disable=SC1090
[ -f "$staterc" ] && source "$staterc"

if [ "${HYPR_WORKFLOW:-default}" = "gaming" ]; then
    restore="${GAMEMODE_RETURN_WORKFLOW:-default}"
    # Fall back to default if the saved workflow was removed/renamed,
    # or if stale state points back at gaming itself
    if [ "$restore" = "gaming" ] || [ ! -f "$confDir/hypr/workflows/${restore}.conf" ]; then
        restore="default"
    fi
    "$LIB_DIR/hyde/workflows.sh" --set "$restore"
else
    set_conf "GAMEMODE_RETURN_WORKFLOW" "${HYPR_WORKFLOW:-default}"
    "$LIB_DIR/hyde/workflows.sh" --set gaming
fi
# Apply immediately instead of relying on autoreload, which may be
# temporarily disabled by other scripts (e.g. color.set.sh)
hyprctl reload config-only -q
# Clean up the lock file left behind by the old implementation
rm -f "${XDG_RUNTIME_DIR}/hyde/gamemode.lck"
