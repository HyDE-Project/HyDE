#!/usr/bin/env bash
#  Author : JaxTsai
# Syncs swaync with the active HyDE theme's hypr.theme:
#   - notification popup gap from the screen edge  <- general:gaps_out (theme.css)
#   - control center margin from the screen edge   <- general:gaps_out (config.json)
#   - corner rounding                               <- decoration:rounding (theme.css)
# Values are pulled once per theme reload via hyq. The theme.css values are
# stamped over the tagged placeholders below (do not hand-edit those values,
# they are overwritten every time this runs). The config.json margins are
# managed the same way: control-center-margin-* is overwritten every reload,
# everything else in config.json is left untouched.
[[ $HYDE_SHELL_INIT -ne 1 ]] && eval "$(hyde-shell init)"

theme_css="${confDir}/swaync/theme.css"
config_json="${confDir}/swaync/config.json"

hypr_theme="${HYDE_THEME_DIR:-$XDG_CONFIG_HOME/hyde/themes/$HYDE_THEME}/hypr.theme"

hyq_query() {
    local query="$1"
    [ -f "$hypr_theme" ] || return 1
    command -v hyq &>/dev/null || return 1
    hyq -s --query "$query" "$hypr_theme" 2>/dev/null | tail -n1
}

# gaps_out -> padding (hyde:gaps_out) + control-center-margin-*
gaps_out="$(hyq_query "general:gaps_out")"
[[ $gaps_out =~ ^([0-9]+,){0,3}[0-9]+$ ]] || gaps_out=8

if [ -f "$theme_css" ]; then
    gaps_css="$(awk -F',' '{for(i=1;i<=NF;i++) printf "%s%dpx", (i>1?" ":""), $i}' <<<"$gaps_out")"
    sed -i -E "s#padding: [0-9]+px( [0-9]+px){0,3};([[:space:]]*/\* hyde:gaps_out \*/)#padding: ${gaps_css};\2#" "$theme_css"
fi

if [ -f "$config_json" ] && command -v jq &>/dev/null; then
    # gaps_out follows CSS padding order: top[,right,bottom,left]
    IFS=',' read -ra _gaps <<<"$gaps_out"
    if [ ${#_gaps[@]} -eq 1 ]; then
        gap_top=${_gaps[0]} gap_right=${_gaps[0]} gap_bottom=${_gaps[0]} gap_left=${_gaps[0]}
    else
        gap_top=${_gaps[0]} gap_right=${_gaps[1]} gap_bottom=${_gaps[2]} gap_left=${_gaps[3]}
    fi
    config_tmp="$(mktemp)"
    if jq --argjson t "$gap_top" --argjson r "$gap_right" --argjson b "$gap_bottom" --argjson l "$gap_left" \
        '."control-center-margin-top"=$t | ."control-center-margin-right"=$r | ."control-center-margin-bottom"=$b | ."control-center-margin-left"=$l' \
        "$config_json" >"$config_tmp"; then
        mv "$config_tmp" "$config_json"
    else
        rm -f "$config_tmp"
    fi
fi

# decoration:rounding -> border-radius (hyde:rounding)
if [ -f "$theme_css" ]; then
    rounding="$(hyq_query "decoration:rounding")"
    [[ $rounding =~ ^[0-9]+$ ]] || rounding=12
    sed -i -E "s#border-radius: [0-9]+px;([[:space:]]*/\* hyde:rounding \*/)#border-radius: ${rounding}px;\1#" "$theme_css"
fi

swaync-client -R && swaync-client -rs
