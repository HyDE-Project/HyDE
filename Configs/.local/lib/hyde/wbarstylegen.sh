#!/usr/bin/env bash

# detect hypr theme and initialize variables

scrDir=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"
# shellcheck disable=SC2154
waybar_dir="${confDir}/waybar"
modules_dir="$waybar_dir/modules"
conf_ctl="$waybar_dir/config.ctl"
in_file="$waybar_dir/modules/style.css"
out_file="$waybar_dir/style.css"
src_file="${confDir}/hypr/themes/theme.conf"

# calculate height from control file or monitor res

b_height=${WAYBAR_SCALE:-$(grep '^1|' "$conf_ctl" | cut -d '|' -f 2)}

if [ -z "$b_height" ] || [ "$b_height" == "0" ]; then
    y_monres=$(cat /sys/class/drm/*/modes | head -1 | cut -d 'x' -f 2)
    y_monres=$(hyprctl -j monitors | jq '.[] | select(.focused == true) | (.height / .scale)')
    b_height=$((y_monres * 3 / 100))
fi

# calculate values based on height

export b_radius=$((b_height * 70 / 100)) # block rad 70% of height (type1)
export c_radius=$((b_height * 25 / 100)) # block rad 25% of height {type2}
export t_radius=$((b_height * 25 / 100)) # tooltip rad 25% of height
export e_margin=$((b_height * 30 / 100)) # block margin 30% of height
export e_paddin=$((b_height * 10 / 100)) # block padding 10% of height
export g_margin=$((b_height * 14 / 100)) # module margin 14% of height
export g_paddin=$((b_height * 15 / 100)) # module padding 15% of height
export w_radius=$((b_height * 30 / 100)) # workspace rad 30% of height
export w_margin=$((b_height * 10 / 100)) # workspace margin 10% of height
export w_paddin=$((b_height * 10 / 100)) # workspace padding 10% of height
export w_padact=$((b_height * 40 / 100)) # workspace active padding 40% of height
export s_fontpx=$((b_height * 34 / 100)) # font size 34% of height

if [ "$b_height" -lt 30 ]; then
    export e_paddin=0
fi
if [ $s_fontpx -lt 10 ]; then
    export s_fontpx=10
fi

# adjust values for vert/horz

w_position="$(grep '^1|' "$conf_ctl" | cut -d '|' -f 3)"
export w_position
case ${w_position} in
top | bottom)
    export x1g_margin=${g_margin}
    export x2g_margin=0
    export x3g_margin=${g_margin}
    export x4g_margin=0
    export x1rb_radius=0
    export x2rb_radius=${b_radius}
    export x3rb_radius=${b_radius}
    export x4rb_radius=0
    export x1lb_radius=${b_radius}
    export x2lb_radius=0
    export x3lb_radius=0
    export x4lb_radius=${b_radius}
    export x1rc_radius=0
    export x2rc_radius=${c_radius}
    export x3rc_radius=${c_radius}
    export x4rc_radius=0
    export x1lc_radius=${c_radius}
    export x2lc_radius=0
    export x3lc_radius=0
    export x4lc_radius=${c_radius}
    export x1="top"
    export x2="bottom"
    export x3="left"
    export x4="right"
    ;;
left | right)
    export x1g_margin=0
    export x2g_margin=${g_margin}
    export x3g_margin=0
    export x4g_margin=${g_margin}
    export x1rb_radius=0
    export x2rb_radius=0
    export x3rb_radius=${b_radius}
    export x4rb_radius=${b_radius}
    export x1lb_radius=${b_radius}
    export x2lb_radius=${b_radius}
    export x3lb_radius=0
    export x4lb_radius=0
    export x1rc_radius=0
    export x2rc_radius=${c_radius}
    export x3rc_radius=${c_radius}
    export x4rc_radius=0
    export x1lc_radius=${c_radius}
    export x2lc_radius=0
    export x3lc_radius=0
    export x4lc_radius=${c_radius}
    export x1="left"
    export x2="right"
    export x3="top"
    export x4="bottom"
    ;;
esac

font_name=${WAYBAR_FONT:-$(get_hyprConf "WAYBAR_FONT")}
export font_name=${font_name:-"JetBrainsMono Nerd Font"}

# list modules and generate theme style
export modules_ls
# modules_ls=$(grep -m 1 '".*.": {'  --exclude="$modules_dir/footer.jsonc" "${modules_dir}"/*.jsonc | cut -d '"' -f 2 | awk -F '/' '{ if($1=="custom") print "#custom-"$NF"," ; else print "#"$NF","}')
modules_ls=$(grep -m 1 '".*.": {' --exclude="$modules_dir/footer.jsonc" "${modules_dir}"/*.jsonc | cut -d '"' -f 2 | awk -F '/' '{print ($1=="custom" ? "#custom-"$NF : "#"$NF)","}')
envsubst <"$in_file" >"$out_file"

# override rounded corners
hypr_border=$(awk -F '=' '{if($1~" rounding ") print $2}' "$src_file" | sed 's/ //g')
hypr_border=${hypr_border:-$WAYBAR_BORDER_RADIUS}
if [ "$hypr_border" == "0" ] || [ -z "$hypr_border" ]; then
    sed -i "/border-radius: /c\    border-radius: 0px;" "$out_file"
fi
