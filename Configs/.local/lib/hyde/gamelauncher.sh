#!/usr/bin/env bash

# set variables
MODE=${1}
scrDir=$(dirname "$(realpath "$0")")
source $scrDir/globalcontrol.sh
# ThemeSet="${confDir}/hypr/themes/theme.conf"

if [[ "$MODE" =~ ^[0-9]+$ ]]; then
  RofiConf="gamelauncher_${MODE}"
else
  RofiConf="${MODE:-$ROFI_GAMELAUNCHER_STYLE}"
fi
RofiConf=${RofiConf:-"gamelauncher_5"}

# set rofi override
elem_border=$((hypr_border * 2))
icon_border=$((elem_border - 3))
r_override="element{border-radius:${elem_border}px;} element-icon{border-radius:${icon_border}px;}"

[[ -z $MODE ]] && MODE=5
case $MODE in
5)
monitor_info=()
eval "$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) |
    "monitor_info=(\(.width) \(.height) \(.scale) \(.x) \(.y)) reserved_info=(\(.reserved | join(" ")))"')"

# Remove decimal point from scale and convert to integer (e.g., 1.25 -> 125)
monitor_scale="${monitor_info[2]//./}"
# Calculate display width adjusted for scale (95% of actual width)
monitor_width=$((monitor_info[0] * 95 / monitor_scale))
# Calculate display height adjusted for scale (95% of actual height)
monitor_height=$((monitor_info[1] * 95 / monitor_scale))

  BG=$HOME/.local/share/hyde/rofi/assets/steamdeck_holographic.png
  BGfx=$HOME/.cache/hyde/landing/steamdeck_holographic_${monitor_width}x${monitor_height}.png

  # Construct the command
  if [ ! -e "${BGfx}" ]; then
    magick "${BG}" -resize ${monitor_width}x${monitor_height} -background none -gravity center -extent ${monitor_width}x${monitor_height} "$BGfx"
  fi

  r_override="window {width: ${monitor_width}px; height: ${monitor_height}; background-image: url('${BGfx}',width);}  
                element {border-radius:${elem_border}px;} 
                element-icon {border-radius:${icon_border}px;}
                mainbox { padding: 25% 21% 25% 21%;}
                "
  # top right bottom left
  ;;

*) : ;;
esac

fn_steam() {

  notify-send -a "HyDE Alert" "Please wait... " -t 4000

  libraryThumbName="library_600x900.jpg"
  libraryHeaderName="header.jpg"
  # Get all manifests found within steam libs
  # SteamLib might contain more than one path
  ManifestList=$(grep '"path"' $SteamLib | awk -F '"' '{print $4}' | while read sp; do

  #Manifests for current path
  find "${sp}/steamapps" -type f -name "appmanifest_*.acf" 2>/dev/null 
  done)

  if [ -z "${ManifestList}" ]; then
    notify-send -a "HyDE Alert" "Cannot Fetch Steam Games!" && exit 1
  fi

  # read installed games
  GameList=$(echo "$ManifestList" | while read acf; do
    appid=$(grep '"appid"' $acf | cut -d '"' -f 4)
    gameName=$(grep '"name"' $acf | cut -d '"' -f 4)
    # Ignore Proton or Steam Runtimes
    if [[ ${gameName} != *"Proton"* && ${gameName} != *"Steam"* ]]; then
      game=$gameName
      echo "$game|$appid"
    else
      continue
    fi
  done | sort)

  # launch rofi menu
  RofiSel=$(
    echo "$GameList" | while read acf; do
      appid=$(echo "${acf}" | cut -d '|' -f 2)
      game=$(echo "${acf}" | cut -d '|' -f 1)
      # find the lib image
      libImage=$(find "${SteamThumb}/${appid}/" -type f -name "${libraryThumbName}" | head  -1)
      printf "%s\x00icon\x1f${libImage}\n" "${game}" >&2
      printf "%s\x00icon\x1f${libImage}\n" "${game}"
    done | rofi -dmenu \
      -theme-str "${r_override}" \
      -config $RofiConf
  )

  # launch game
  if [ -n "$RofiSel" ]; then 
    launchid=$(echo "$GameList" | grep "$RofiSel" | cut -d '|' -f 2)

    headerImage=$(find "${SteamThumb}/${launchid}/" -type f -name "*${libraryHeaderName}")
    ${steamlaunch} -applaunch "${launchid} [gamemoderun %command%]" &
    # dunstify "HyDE Alert" -a "Launching ${RofiSel}..." -i ${SteamThumb}/${launchid}_header.jpg -r 91190 -t 2200
    notify-send -a "HyDE Alert" -i "$headerImage" "Launching ${RofiSel}..."
  fi
}

fn_lutris() {
  [ ! -e "${icon_path}" ] && icon_path="${HOME}/.local/share/lutris/coverart"
  [ ! -e "${icon_path}" ] && icon_path="${HOME}/.cache/lutris/coverart"
  meta_data="/tmp/hyprdots-$(id -u)-lutrisgames.json"

  # Retrieve the list of games from Lutris in JSON format
  #TODO Only call this if new apps are installed...
  # [ ! -s "${meta_data}" ] &&
  notify-send -a "HyDE Alert" "Please wait... " -t 4000

  cat <<EOF
"Fetching Lutris Games..."

On error, please try to run the following command: '${run_lutris}" -j -l'

EOF

  eval "${run_lutris}" -j -l 2>/dev/null | jq --arg icons "$icon_path/" --arg prefix ".jpg" '.[] |= . + {"select": (.name + "\u0000icon\u001f" + $icons + .slug + $prefix)}' >"${meta_data}"

  [ ! -s "${meta_data}" ] && notify-send -a "HyDE Alert" "Cannot Fetch Lutris Games!" && exit 1
  CHOICE=$(
    jq -r '.[].select' "${meta_data}" | rofi -dmenu -p Lutris \
      -theme-str "${r_override}" \
      -config "${RofiConf}"
  )
  [ -z "$CHOICE" ] && exit 0
  SLUG=$(jq -r --arg choice "$CHOICE" '.[] | select(.name == $choice).slug' "${meta_data}")
  notify-send -a "HyDE Alert" -i "${icon_path}/${SLUG}.jpg" "Launching ${CHOICE}..."
  exec xdg-open "lutris:rungame/${SLUG}"
}

# Handle if flatpak or pkgmgr
run_lutris=""
echo "$*"
(flatpak list --columns=application | grep -q "net.lutris.Lutris") && run_lutris="flatpak run net.lutris.Lutris"
icon_path="${HOME}/.var/app/net.lutris.Lutris/data/lutris/coverart/"
[ -z "${run_lutris}" ] && (pkg_installed 'lutris') && run_lutris="lutris"

if [ -z "${run_lutris}" ] || echo "$*" | grep -q "steam"; then
  # set steam library
  if pkg_installed steam; then
    SteamLib="${XDG_DATA_HOME:-$HOME/.local/share}/Steam/config/libraryfolders.vdf"
    SteamThumb="${XDG_DATA_HOME:-$HOME/.local/share}/Steam/appcache/librarycache"
    steamlaunch="steam"
  else
    SteamLib="$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/config/libraryfolders.vdf"
    SteamThumb="$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/appcache/librarycache"
    steamlaunch="flatpak run com.valvesoftware.Steam"
  fi

  if [ ! -f $SteamLib ] || [ ! -d $SteamThumb ]; then
    notify-send -a "HyDE Alert" "Steam library not found!"
    exit 1
  fi
  fn_steam
else
  fn_lutris
fi
