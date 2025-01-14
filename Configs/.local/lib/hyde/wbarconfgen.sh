#!/usr/bin/env bash

# read control file and initialize variables

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"
# shellcheck disable=SC2154
waybar_dir="${confDir}/waybar"
modules_dir="$waybar_dir/modules"
conf_file="$waybar_dir/config.jsonc"
conf_ctl="$waybar_dir/config.ctl"
export scrDir

readarray -t read_ctl <"${conf_ctl}"
num_files="${#read_ctl[@]}"
switch=0

# update control file to set next/prev mode

if [ "${num_files}" -gt 1 ]; then
    for ((i = 0; i < "${num_files}"; i++)); do
        flag=$(cut -d '|' -f 1 <<<"${read_ctl[i]}")
        if [ "${flag}" -eq 1 ] && [ "$1" == "n" ]; then
            nextIndex=$(((i + 1) % "${num_files}"))
            switch=1
            break

        elif [ "${flag}" -eq 1 ] && [ "$1" == "p" ]; then
            nextIndex=$((i - 1))
            switch=1
            break
        fi
    done
fi

if [ $switch -eq 1 ]; then
    update_ctl="${read_ctl[nextIndex]}"
    reload_flag=1
    sed -i "s/^1/0/g" "$conf_ctl"
    awk -F '|' -v cmp="$update_ctl" '{OFS=FS} {if($0==cmp) $1=1; print$0}' "${conf_ctl}" >"${waybar_dir}/tmp" && mv "${waybar_dir}/tmp" "${conf_ctl}"
fi

# overwrite config from header module

# shellcheck disable=SC2155
export set_sysname=$(hostnamectl hostname)
# shellcheck disable=SC2155
export w_position=$(grep '^1|' "${conf_ctl}" | cut -d '|' -f 3)

# setting explicit waybar output

if [ ${#WAYBAR_OUTPUT[@]} -gt 0 ]; then
    w_output=$(printf '"%s", ' "${WAYBAR_OUTPUT[@]}")
    w_output=${w_output%, } # Remove the trailing comma and space
    print_log -sec "waybar" -stat "monitor output" "$w_output"

fi
export w_output="${w_output:-\"*\"}"

# setting waybar position

case ${w_position} in
left)
    export hv_pos="width"
    export r_deg=90
    ;;
right)
    export hv_pos="width"
    export r_deg=270
    ;;
*)
    export hv_pos="height"
    export r_deg=0
    ;;
esac

w_height=$(grep '^1|' "${conf_ctl}" | cut -d '|' -f 2)
if [ -z "${w_height}" ]; then
    # y_monres=$(cat /sys/class/drm/*/modes | head -1 | cut -d 'x' -f 2)
    y_monres=$(hyprctl -j monitors | jq '.[] | select(.focused == true) | (.height / .scale)')
    w_height=$((y_monres * 2 / 100))
fi
export w_height

export i_size=$((w_height * 6 / 10))
if [ $i_size -lt 12 ]; then
    export i_size="12"
fi

i_theme="$(get_hyprConf ICON_THEME)"
export i_theme

export i_task=$((w_height * 6 / 10))
if [ $i_task -lt 16 ]; then
    export i_task="16"
fi
export i_priv=$((w_height * 6 / 13))
if [ $i_priv -lt 12 ]; then
    export i_priv="12"
fi

envsubst <"${modules_dir}/header.jsonc" >"${conf_file}"

# module generator function

gen_mod() {
    local pos=$1
    local col=$2
    local mod=""

    list_mods() {
        mod="$(grep '^1|' "${conf_ctl}" | cut -d '|' -f "${col}")"

        if [[ $1 == "clean" ]]; then
            # Process each word and remove the part after '##' indicating a tag
            mod=$(echo "$mod" | awk '{for(i=1;i<=NF;i++){sub(/##.*/,"",$i); printf "%s ", $i}}')
            mod="${mod% }" # Remove trailing space
        fi

        mod="${mod//(/"custom/l_end"}"
        mod="${mod//)/"custom/r_end"}"
        mod="${mod//[/"custom/sl_end"}"
        mod="${mod//]/"custom/sr_end"}"
        mod="${mod//\{/"custom/rl_end"}"
        mod="${mod//\}/"custom/rr_end"}"
        mod="${mod// /"\",\""}"
        echo -e "${mod}"
    }

    write_mod="$write_mod $(list_mods)" # This is used to copy the modules to the config later

    echo -e "\t\"modules-${pos}\": [\"custom/padd\",\"$(list_mods clean)\",\"custom/padd\"]," >>"${conf_file}"

}

# write positions for modules

echo -e "\n\n// positions generated based on config.ctl //\n" >>"${conf_file}"
gen_mod left 4
gen_mod center 5
gen_mod right 6

# copy modules/*.jsonc to the config

echo -e "\n\n// sourced from modules based on config.ctl //\n" >>"${conf_file}"
echo "$write_mod" | sed 's/","/\n/g ; s/ /\n/g' | awk -F '/' '{print $NF}' | awk -F '#' '{print}' | awk '!x[$0]++' | while read -r mod_cpy; do
    if [ -f "${modules_dir}/${mod_cpy}.jsonc" ]; then
        envsubst <"${modules_dir}/${mod_cpy}.jsonc" >>"${conf_file}"
    fi
done

cat "${modules_dir}/footer.jsonc" >>"${conf_file}"

# generate style

"$scrDir/wbarstylegen.sh"

# restart waybar

if [ "$reload_flag" == "1" ]; then
    killall waybar
    waybar --config "${waybar_dir}/config.jsonc" --style "${waybar_dir}/style.css" >/dev/null 2>&1 &
fi
