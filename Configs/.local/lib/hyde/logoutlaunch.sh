#!/usr/bin/env bash
if pgrep -x "wlogout" > /dev/null; then
    pkill -x "wlogout"
    exit 0
fi
scrDir=$(dirname "$(realpath "$0")")
source "$scrDir/globalcontrol.sh"
[ -n "$1" ] && wlogoutStyle="$1"
wlogoutStyle=${wlogoutStyle:-${WLOGOUT_STYLE:-1}}
confDir="${confDir:-$HOME/.config}"
wLayout="$confDir/wlogout/layout_$wlogoutStyle"
wlTmplt="$confDir/wlogout/style_$wlogoutStyle.css"
echo "wlogoutStyle: $wlogoutStyle"
echo "wLayout: $wLayout"
echo "wlTmplt: $wlTmplt"
if [ ! -f "$wLayout" ] || [ ! -f "$wlTmplt" ]; then
    echo "ERROR: Config $wlogoutStyle not found..."
    wlogoutStyle=1
    wLayout="$confDir/wlogout/layout_$wlogoutStyle"
    wlTmplt="$confDir/wlogout/style_$wlogoutStyle.css"
fi
if [ ! -f "$wLayout" ] || [ ! -f "$wlTmplt" ]; then
    echo "ERROR: no wlogout config under $confDir/wlogout, not launching..."
    exit 1
fi
mon_data=$(hyprctl -j monitors)
x_mon=$(jq '.[] | select(.focused==true) | .width' <<< "$mon_data")
y_mon=$(jq '.[] | select(.focused==true) | .height' <<< "$mon_data")
hypr_scale=$(get_monitor_scale "$(jq '.[] | select(.focused==true) | .scale' <<< "$mon_data")")
hypr_scale=${hypr_scale:-100}
case "$wlogoutStyle" in
    1)
        wlColms=6
        export mgn=$((y_mon * 28 / hypr_scale))
        export hvr=$((y_mon * 23 / hypr_scale))
        ;;
    2)
        wlColms=2
        export x_mgn=$((x_mon * 35 / hypr_scale))
        export y_mgn=$((y_mon * 25 / hypr_scale))
        export x_hvr=$((x_mon * 32 / hypr_scale))
        export y_hvr=$((y_mon * 20 / hypr_scale))
        ;;
esac
export fntSize=$((y_mon * 2 / 100))
cacheDir="$HYDE_CACHE_HOME"
dcol_mode="${dcol_mode:-dark}"
[ -f "$cacheDir/wall.dcol" ] && source "$cacheDir/wall.dcol"
enableWallDcol="${enableWallDcol:-1}"
if [ "$enableWallDcol" -eq 0 ]; then
    HYDE_THEME_DIR="${HYDE_THEME_DIR:-$confDir/hyde/themes/$HYDE_THEME}"
    dcol_mode=$(get_hyprConf "COLOR_SCHEME")
    dcol_mode=${dcol_mode#prefer-}
    [ -f "$HYDE_THEME_DIR/theme.dcol" ] && source "$HYDE_THEME_DIR/theme.dcol"
fi
{
    [ "$dcol_mode" == "dark" ] && export BtnCol="white"
} || export BtnCol="black"
hypr_border="${hypr_border:-10}"
export active_rad=$((hypr_border * 5))
export button_rad=$((hypr_border * 8))
wlStyle="$(envsubst < "$wlTmplt")"
wlogout -b "$wlColms" -c 0 -r 0 -m 0 --layout "$wLayout" --css <(echo "$wlStyle") --protocol layer-shell
