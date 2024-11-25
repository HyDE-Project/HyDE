#!/usr/bin/env sh

#// set variables

export scrDir="$(dirname "$(realpath "$0")")"
source "${scrDir}/globalcontrol.sh"
wallbashImg="${cacheDir}/wall.set"


#// validate input

if [ -z "${wallbashImg}" ] || [ ! -f "${wallbashImg}" ] ; then
    echo "Error: Input wallpaper not found!"
    exit 1
fi
wallbashOut="${dcolDir}/$(set_hash "${wallbashImg}").dcol"

if [ ! -f "${wallbashOut}" ] ; then
    "${scrDir}/swwwallcache.sh" -w "${wallbashImg}" &> /dev/null
fi

set -a
source "${wallbashOut}"
if [ -f "${hydeThemeDir}/theme.dcol" ] && [ "${enableWallDcol}" -eq 0 ]  ; then
    source "${hydeThemeDir}/theme.dcol"
    echo "[theme] Overriding dominant colors from \"${hydeTheme}\""
    echo "[note] Remove \"${hydeThemeDir}/theme.dcol\" to use wallpaper dominant colors"
fi

ovrWD="${2}"
case $ovrWD in
    r)
     override="$(find "${dcolDir}" -type f -name "*.dcol" | shuf -n 1)"
    echo "[Override] ${override}"
    source "${override}"
     ;;
    *)
    if [ -f "${ovrWD}" ]; then
    echo "[Source] ${ovrWD}"
    source "${ovrWD}"
    fi
    ;;
esac

[ "${dcol_mode}" == "light" ] && dcol_invt="dark" || dcol_invt="light"

[ "${dcol_mode}" == "dark" ] && dcol_invt="light" || dcol_invt="dark"
set +a


#// deploy wallbash colors

fn_wallbash () {
    local tplt="${1}"
    [ -f "${hydeConfDir}/hyde.conf" ] && source "${hydeConfDir}/hyde.conf"
    # Skips the the template declared in ./hyde.conf
    #[[ " ${skip_wallbash[@]} " =~ " ${tplt} " ]] && echo "[skip: template] ${tplt}" && return 0
    eval target="$(head -1 "${tplt}" | awk -F '|' '{print $1}')"
    [ ! -d "$(dirname "${target}")" ] && echo "[skip: no dir] \"${target}\"" && return 0
    appexe="$(head -1 "${tplt}" | awk -F '|' '{print $2}')"
    sed '1d' "${tplt}" > "${target}"

    if [[ "${enableWallDcol}" -eq 2 && "${dcol_mode}" == "light" ]] || [[ "${enableWallDcol}" -eq 3 && "${dcol_mode}" == "dark" ]] ; then
        sed -i 's/<wallbash_mode>/'"${dcol_invt}"'/g
                s/<wallbash_pry1>/'"${dcol_pry4}"'/g
                s/<wallbash_txt1>/'"${dcol_txt4}"'/g
                s/<wallbash_1xa1>/'"${dcol_4xa9}"'/g
                s/<wallbash_1xa2>/'"${dcol_4xa8}"'/g
                s/<wallbash_1xa3>/'"${dcol_4xa7}"'/g
                s/<wallbash_1xa4>/'"${dcol_4xa6}"'/g
                s/<wallbash_1xa5>/'"${dcol_4xa5}"'/g
                s/<wallbash_1xa6>/'"${dcol_4xa4}"'/g
                s/<wallbash_1xa7>/'"${dcol_4xa3}"'/g
                s/<wallbash_1xa8>/'"${dcol_4xa2}"'/g
                s/<wallbash_1xa9>/'"${dcol_4xa1}"'/g
                s/<wallbash_pry2>/'"${dcol_pry3}"'/g
                s/<wallbash_txt2>/'"${dcol_txt3}"'/g
                s/<wallbash_2xa1>/'"${dcol_3xa9}"'/g
                s/<wallbash_2xa2>/'"${dcol_3xa8}"'/g
                s/<wallbash_2xa3>/'"${dcol_3xa7}"'/g
                s/<wallbash_2xa4>/'"${dcol_3xa6}"'/g
                s/<wallbash_2xa5>/'"${dcol_3xa5}"'/g
                s/<wallbash_2xa6>/'"${dcol_3xa4}"'/g
                s/<wallbash_2xa7>/'"${dcol_3xa3}"'/g
                s/<wallbash_2xa8>/'"${dcol_3xa2}"'/g
                s/<wallbash_2xa9>/'"${dcol_3xa1}"'/g
                s/<wallbash_pry3>/'"${dcol_pry2}"'/g
                s/<wallbash_txt3>/'"${dcol_txt2}"'/g
                s/<wallbash_3xa1>/'"${dcol_2xa9}"'/g
                s/<wallbash_3xa2>/'"${dcol_2xa8}"'/g
                s/<wallbash_3xa3>/'"${dcol_2xa7}"'/g
                s/<wallbash_3xa4>/'"${dcol_2xa6}"'/g
                s/<wallbash_3xa5>/'"${dcol_2xa5}"'/g
                s/<wallbash_3xa6>/'"${dcol_2xa4}"'/g
                s/<wallbash_3xa7>/'"${dcol_2xa3}"'/g
                s/<wallbash_3xa8>/'"${dcol_2xa2}"'/g
                s/<wallbash_3xa9>/'"${dcol_2xa1}"'/g
                s/<wallbash_pry4>/'"${dcol_pry1}"'/g
                s/<wallbash_txt4>/'"${dcol_txt1}"'/g
                s/<wallbash_4xa1>/'"${dcol_1xa9}"'/g
                s/<wallbash_4xa2>/'"${dcol_1xa8}"'/g
                s/<wallbash_4xa3>/'"${dcol_1xa7}"'/g
                s/<wallbash_4xa4>/'"${dcol_1xa6}"'/g
                s/<wallbash_4xa5>/'"${dcol_1xa5}"'/g
                s/<wallbash_4xa6>/'"${dcol_1xa4}"'/g
                s/<wallbash_4xa7>/'"${dcol_1xa3}"'/g
                s/<wallbash_4xa8>/'"${dcol_1xa2}"'/g
                s/<wallbash_4xa9>/'"${dcol_1xa1}"'/g
                s/<wallbash_pry1_rgba(\([^)]*\))>/'"${dcol_pry4_rgba}"'/g
                s/<wallbash_txt1_rgba(\([^)]*\))>/'"${dcol_txt4_rgba}"'/g
                s/<wallbash_1xa1_rgba(\([^)]*\))>/'"${dcol_4xa9_rgba}"'/g
                s/<wallbash_1xa2_rgba(\([^)]*\))>/'"${dcol_4xa8_rgba}"'/g
                s/<wallbash_1xa3_rgba(\([^)]*\))>/'"${dcol_4xa7_rgba}"'/g
                s/<wallbash_1xa4_rgba(\([^)]*\))>/'"${dcol_4xa6_rgba}"'/g
                s/<wallbash_1xa5_rgba(\([^)]*\))>/'"${dcol_4xa5_rgba}"'/g
                s/<wallbash_1xa6_rgba(\([^)]*\))>/'"${dcol_4xa4_rgba}"'/g
                s/<wallbash_1xa7_rgba(\([^)]*\))>/'"${dcol_4xa3_rgba}"'/g
                s/<wallbash_1xa8_rgba(\([^)]*\))>/'"${dcol_4xa2_rgba}"'/g
                s/<wallbash_1xa9_rgba(\([^)]*\))>/'"${dcol_4xa1_rgba}"'/g
                s/<wallbash_pry2_rgba(\([^)]*\))>/'"${dcol_pry3_rgba}"'/g
                s/<wallbash_txt2_rgba(\([^)]*\))>/'"${dcol_txt3_rgba}"'/g
                s/<wallbash_2xa1_rgba(\([^)]*\))>/'"${dcol_3xa9_rgba}"'/g
                s/<wallbash_2xa2_rgba(\([^)]*\))>/'"${dcol_3xa8_rgba}"'/g
                s/<wallbash_2xa3_rgba(\([^)]*\))>/'"${dcol_3xa7_rgba}"'/g
                s/<wallbash_2xa4_rgba(\([^)]*\))>/'"${dcol_3xa6_rgba}"'/g
                s/<wallbash_2xa5_rgba(\([^)]*\))>/'"${dcol_3xa5_rgba}"'/g
                s/<wallbash_2xa6_rgba(\([^)]*\))>/'"${dcol_3xa4_rgba}"'/g
                s/<wallbash_2xa7_rgba(\([^)]*\))>/'"${dcol_3xa3_rgba}"'/g
                s/<wallbash_2xa8_rgba(\([^)]*\))>/'"${dcol_3xa2_rgba}"'/g
                s/<wallbash_2xa9_rgba(\([^)]*\))>/'"${dcol_3xa1_rgba}"'/g
                s/<wallbash_pry3_rgba(\([^)]*\))>/'"${dcol_pry2_rgba}"'/g
                s/<wallbash_txt3_rgba(\([^)]*\))>/'"${dcol_txt2_rgba}"'/g
                s/<wallbash_3xa1_rgba(\([^)]*\))>/'"${dcol_2xa9_rgba}"'/g
                s/<wallbash_3xa2_rgba(\([^)]*\))>/'"${dcol_2xa8_rgba}"'/g
                s/<wallbash_3xa3_rgba(\([^)]*\))>/'"${dcol_2xa7_rgba}"'/g
                s/<wallbash_3xa4_rgba(\([^)]*\))>/'"${dcol_2xa6_rgba}"'/g
                s/<wallbash_3xa5_rgba(\([^)]*\))>/'"${dcol_2xa5_rgba}"'/g
                s/<wallbash_3xa6_rgba(\([^)]*\))>/'"${dcol_2xa4_rgba}"'/g
                s/<wallbash_3xa7_rgba(\([^)]*\))>/'"${dcol_2xa3_rgba}"'/g
                s/<wallbash_3xa8_rgba(\([^)]*\))>/'"${dcol_2xa2_rgba}"'/g
                s/<wallbash_3xa9_rgba(\([^)]*\))>/'"${dcol_2xa1_rgba}"'/g
                s/<wallbash_pry4_rgba(\([^)]*\))>/'"${dcol_pry1_rgba}"'/g
                s/<wallbash_txt4_rgba(\([^)]*\))>/'"${dcol_txt1_rgba}"'/g
                s/<wallbash_4xa1_rgba(\([^)]*\))>/'"${dcol_1xa9_rgba}"'/g
                s/<wallbash_4xa2_rgba(\([^)]*\))>/'"${dcol_1xa8_rgba}"'/g
                s/<wallbash_4xa3_rgba(\([^)]*\))>/'"${dcol_1xa7_rgba}"'/g
                s/<wallbash_4xa4_rgba(\([^)]*\))>/'"${dcol_1xa6_rgba}"'/g
                s/<wallbash_4xa5_rgba(\([^)]*\))>/'"${dcol_1xa5_rgba}"'/g
                s/<wallbash_4xa6_rgba(\([^)]*\))>/'"${dcol_1xa4_rgba}"'/g
                s/<wallbash_4xa7_rgba(\([^)]*\))>/'"${dcol_1xa3_rgba}"'/g
                s/<wallbash_4xa8_rgba(\([^)]*\))>/'"${dcol_1xa2_rgba}"'/g
                s/<wallbash_4xa9_rgba(\([^)]*\))>/'"${dcol_1xa1_rgba}"'/g' "${target}"
    else
        sed -i 's/<wallbash_mode>/'"${dcol_mode}"'/g
                s/<wallbash_pry1>/'"${dcol_pry1}"'/g
                s/<wallbash_txt1>/'"${dcol_txt1}"'/g
                s/<wallbash_1xa1>/'"${dcol_1xa1}"'/g
                s/<wallbash_1xa2>/'"${dcol_1xa2}"'/g
                s/<wallbash_1xa3>/'"${dcol_1xa3}"'/g
                s/<wallbash_1xa4>/'"${dcol_1xa4}"'/g
                s/<wallbash_1xa5>/'"${dcol_1xa5}"'/g
                s/<wallbash_1xa6>/'"${dcol_1xa6}"'/g
                s/<wallbash_1xa7>/'"${dcol_1xa7}"'/g
                s/<wallbash_1xa8>/'"${dcol_1xa8}"'/g
                s/<wallbash_1xa9>/'"${dcol_1xa9}"'/g
                s/<wallbash_pry2>/'"${dcol_pry2}"'/g
                s/<wallbash_txt2>/'"${dcol_txt2}"'/g
                s/<wallbash_2xa1>/'"${dcol_2xa1}"'/g
                s/<wallbash_2xa2>/'"${dcol_2xa2}"'/g
                s/<wallbash_2xa3>/'"${dcol_2xa3}"'/g
                s/<wallbash_2xa4>/'"${dcol_2xa4}"'/g
                s/<wallbash_2xa5>/'"${dcol_2xa5}"'/g
                s/<wallbash_2xa6>/'"${dcol_2xa6}"'/g
                s/<wallbash_2xa7>/'"${dcol_2xa7}"'/g
                s/<wallbash_2xa8>/'"${dcol_2xa8}"'/g
                s/<wallbash_2xa9>/'"${dcol_2xa9}"'/g
                s/<wallbash_pry3>/'"${dcol_pry3}"'/g
                s/<wallbash_txt3>/'"${dcol_txt3}"'/g
                s/<wallbash_3xa1>/'"${dcol_3xa1}"'/g
                s/<wallbash_3xa2>/'"${dcol_3xa2}"'/g
                s/<wallbash_3xa3>/'"${dcol_3xa3}"'/g
                s/<wallbash_3xa4>/'"${dcol_3xa4}"'/g
                s/<wallbash_3xa5>/'"${dcol_3xa5}"'/g
                s/<wallbash_3xa6>/'"${dcol_3xa6}"'/g
                s/<wallbash_3xa7>/'"${dcol_3xa7}"'/g
                s/<wallbash_3xa8>/'"${dcol_3xa8}"'/g
                s/<wallbash_3xa9>/'"${dcol_3xa9}"'/g
                s/<wallbash_pry4>/'"${dcol_pry4}"'/g
                s/<wallbash_txt4>/'"${dcol_txt4}"'/g
                s/<wallbash_4xa1>/'"${dcol_4xa1}"'/g
                s/<wallbash_4xa2>/'"${dcol_4xa2}"'/g
                s/<wallbash_4xa3>/'"${dcol_4xa3}"'/g
                s/<wallbash_4xa4>/'"${dcol_4xa4}"'/g
                s/<wallbash_4xa5>/'"${dcol_4xa5}"'/g
                s/<wallbash_4xa6>/'"${dcol_4xa6}"'/g
                s/<wallbash_4xa7>/'"${dcol_4xa7}"'/g
                s/<wallbash_4xa8>/'"${dcol_4xa8}"'/g
                s/<wallbash_4xa9>/'"${dcol_4xa9}"'/g
                s/<wallbash_pry1_rgba(\([^)]*\))>/'"${dcol_pry1_rgba}"'/g
                s/<wallbash_txt1_rgba(\([^)]*\))>/'"${dcol_txt1_rgba}"'/g
                s/<wallbash_1xa1_rgba(\([^)]*\))>/'"${dcol_1xa1_rgba}"'/g
                s/<wallbash_1xa2_rgba(\([^)]*\))>/'"${dcol_1xa2_rgba}"'/g
                s/<wallbash_1xa3_rgba(\([^)]*\))>/'"${dcol_1xa3_rgba}"'/g
                s/<wallbash_1xa4_rgba(\([^)]*\))>/'"${dcol_1xa4_rgba}"'/g
                s/<wallbash_1xa5_rgba(\([^)]*\))>/'"${dcol_1xa5_rgba}"'/g
                s/<wallbash_1xa6_rgba(\([^)]*\))>/'"${dcol_1xa6_rgba}"'/g
                s/<wallbash_1xa7_rgba(\([^)]*\))>/'"${dcol_1xa7_rgba}"'/g
                s/<wallbash_1xa8_rgba(\([^)]*\))>/'"${dcol_1xa8_rgba}"'/g
                s/<wallbash_1xa9_rgba(\([^)]*\))>/'"${dcol_1xa9_rgba}"'/g
                s/<wallbash_pry2_rgba(\([^)]*\))>/'"${dcol_pry2_rgba}"'/g
                s/<wallbash_txt2_rgba(\([^)]*\))>/'"${dcol_txt2_rgba}"'/g
                s/<wallbash_2xa1_rgba(\([^)]*\))>/'"${dcol_2xa1_rgba}"'/g
                s/<wallbash_2xa2_rgba(\([^)]*\))>/'"${dcol_2xa2_rgba}"'/g
                s/<wallbash_2xa3_rgba(\([^)]*\))>/'"${dcol_2xa3_rgba}"'/g
                s/<wallbash_2xa4_rgba(\([^)]*\))>/'"${dcol_2xa4_rgba}"'/g
                s/<wallbash_2xa5_rgba(\([^)]*\))>/'"${dcol_2xa5_rgba}"'/g
                s/<wallbash_2xa6_rgba(\([^)]*\))>/'"${dcol_2xa6_rgba}"'/g
                s/<wallbash_2xa7_rgba(\([^)]*\))>/'"${dcol_2xa7_rgba}"'/g
                s/<wallbash_2xa8_rgba(\([^)]*\))>/'"${dcol_2xa8_rgba}"'/g
                s/<wallbash_2xa9_rgba(\([^)]*\))>/'"${dcol_2xa9_rgba}"'/g
                s/<wallbash_pry3_rgba(\([^)]*\))>/'"${dcol_pry3_rgba}"'/g
                s/<wallbash_txt3_rgba(\([^)]*\))>/'"${dcol_txt3_rgba}"'/g
                s/<wallbash_3xa1_rgba(\([^)]*\))>/'"${dcol_3xa1_rgba}"'/g
                s/<wallbash_3xa2_rgba(\([^)]*\))>/'"${dcol_3xa2_rgba}"'/g
                s/<wallbash_3xa3_rgba(\([^)]*\))>/'"${dcol_3xa3_rgba}"'/g
                s/<wallbash_3xa4_rgba(\([^)]*\))>/'"${dcol_3xa4_rgba}"'/g
                s/<wallbash_3xa5_rgba(\([^)]*\))>/'"${dcol_3xa5_rgba}"'/g
                s/<wallbash_3xa6_rgba(\([^)]*\))>/'"${dcol_3xa6_rgba}"'/g
                s/<wallbash_3xa7_rgba(\([^)]*\))>/'"${dcol_3xa7_rgba}"'/g
                s/<wallbash_3xa8_rgba(\([^)]*\))>/'"${dcol_3xa8_rgba}"'/g
                s/<wallbash_3xa9_rgba(\([^)]*\))>/'"${dcol_3xa9_rgba}"'/g
                s/<wallbash_pry4_rgba(\([^)]*\))>/'"${dcol_pry4_rgba}"'/g
                s/<wallbash_txt4_rgba(\([^)]*\))>/'"${dcol_txt4_rgba}"'/g
                s/<wallbash_4xa1_rgba(\([^)]*\))>/'"${dcol_4xa1_rgba}"'/g
                s/<wallbash_4xa2_rgba(\([^)]*\))>/'"${dcol_4xa2_rgba}"'/g
                s/<wallbash_4xa3_rgba(\([^)]*\))>/'"${dcol_4xa3_rgba}"'/g
                s/<wallbash_4xa4_rgba(\([^)]*\))>/'"${dcol_4xa4_rgba}"'/g
                s/<wallbash_4xa5_rgba(\([^)]*\))>/'"${dcol_4xa5_rgba}"'/g
                s/<wallbash_4xa6_rgba(\([^)]*\))>/'"${dcol_4xa6_rgba}"'/g
                s/<wallbash_4xa7_rgba(\([^)]*\))>/'"${dcol_4xa7_rgba}"'/g
                s/<wallbash_4xa8_rgba(\([^)]*\))>/'"${dcol_4xa8_rgba}"'/g
                s/<wallbash_4xa9_rgba(\([^)]*\))>/'"${dcol_4xa9_rgba}"'/g' "${target}"
    fi

    [ -z "${appexe}" ] || bash -c "${appexe}"
}

export -f fn_wallbash

fn_wallbash "$(realpath "${1}")"
