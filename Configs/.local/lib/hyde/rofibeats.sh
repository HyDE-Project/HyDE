#!/usr/bin/env bash

#// Set variables
MUSIC_DIR="$HOME/Music/"
SHARE_DIR="${SHARE_DIR:-$HOME/.config/hyde}"
ICON_DIR="${SHARE_DIR}/icons/Wallbash-Icon"
ROFI_THEME_DIR="${SHARE_DIR}/hyde/rofi/themes"
ROFI_THEME="${ROFI_THEME_DIR}/style_10.rasi"
ROFI_MENU_THEME="${ROFI_THEME_DIR}/style_10.rasi"
DEFAULT_ICON="${ICON_DIR}/hyde.png"

#// Load Configurations
# Rofi scaling and font settings
font_scale="${ROFI_BEATS_SCALE:-10}"  # Default scale fallback
font_name="${ROFI_BEATS_FONT:-$(get_hyprConf "MENU_FONT")}"
font_name="${font_name:-$(get_hyprConf "FONT")}"
font_override="* {font: \"${font_name} ${font_scale}\";}"

# Styling for Rofi
hypr_width=${hypr_width:-"$(hyprctl -j getoption general:border_size | jq '.int')"}
hypr_border=${hypr_border:-"$(hyprctl -j getoption decoration:rounding | jq '.int')"}
wind_border=$((hypr_border * 3 / 2))
elem_border=$((hypr_border == 0 ? 5 : hypr_border))
r_override="window{border:${hypr_width}px;border-radius:${wind_border}px;} element{border-radius:${elem_border}px;}"

# Set rofi position
rofi_position=$(get_hyprConf "ROFI_POSITION")

#// Online Stations - Edit as required
declare -A ONLINE_MUSIC=(
  ["FM - Easy Rock 96.3 📻🎶"]="https://radio-stations-philippines.com/easy-rock"
  ["FM - Easy Rock - Baguio 91.9 📻🎶"]="https://radio-stations-philippines.com/easy-rock-baguio" 
  ["FM - Love Radio 90.7 📻🎶"]="https://radio-stations-philippines.com/love"
  ["FM - WRock - CEBU 96.3 📻🎶"]="https://onlineradio.ph/126-96-3-wrock.html"
  ["FM - Fresh Philippines 📻🎶"]="https://onlineradio.ph/553-fresh-fm.html"
  ["Radio - Lofi Girl 🎧🎶"]="https://play.streamafrica.net/lofiradio"
  ["Radio - Chillhop 🎧🎶"]="http://stream.zeno.fm/fyn8eh3h5f8uv"
  ["Radio - Ibiza Global 🎧🎶"]="https://filtermusic.net/ibiza-global"
  ["Radio - Metal Music 🎧🎶"]="https://tunein.com/radio/mETaLmuSicRaDio-s119867/"
  ["YT - Wish 107.5 YT Pinoy HipHop 📻🎶"]="https://youtube.com/playlist?list=PLkrzfEDjeYJnmgMYwCKid4XIFqUKBVWEs&si=vahW_noh4UDJ5d37"
  ["YT - Youtube Top 100 Songs Global 📹🎶"]="https://youtube.com/playlist?list=PL4fGSI1pDJn6puJdseH2Rt9sMvt9E2M4i&si=5jsyfqcoUXBCSLeu"
  ["YT - Wish 107.5 YT Wishclusives 📹🎶"]="https://youtube.com/playlist?list=PLkrzfEDjeYJn5B22H9HOWP3Kxxs-DkPSM&si=d_Ld2OKhGvpH48WO"
  ["YT - Relaxing Piano Music 🎹🎶"]="https://youtu.be/6H7hXzjFoVU?si=nZTPREC9lnK1JJUG"
  ["YT - Youtube Remix 📹🎶"]="https://youtube.com/playlist?list=PLeqTkIUlrZXlSNn3tcXAa-zbo95j0iN-0"
  ["YT - Korean Drama OST 📹🎶"]="https://youtube.com/playlist?list=PLUge_o9AIFp4HuA-A3e3ZqENh63LuRRlQ"
  ["YT - lofi hip hop radio beats 📹🎶"]="https://www.youtube.com/live/jfKfPfyJRdk?si=PnJIA9ErQIAw6-qd"
  ["YT - Relaxing Piano Jazz Music 🎹🎶"]="https://youtu.be/85UEqRat6E4?si=jXQL1Yp2VP_G6NSn"
)

#// Populate local_music array with files from music directory and subdirectories
populate_local_music() {
  local_music=()
  filenames=()
  while IFS= read -r file; do
    local_music+=("$file")
    filenames+=("$(basename "$file")")
  done < <(find -L "$MUSIC_DIR" -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" -o -iname "*.ogg" -o -iname "*.mp4" \))
}

#// Function for displaying notifications
notification() {
  notify-send -u normal -i "$DEFAULT_ICON" "Now Playing:" "$@"
}

#// Main function for playing local music
play_local_music() {
  populate_local_music

  # Prompt the user to select a song
  choice=$(printf "%s\n" "${filenames[@]}" | rofi -i -dmenu -config "$ROFI_THEME" -theme-str "${r_override} ${font_override}")

  if [[ -z "$choice" ]]; then
    exit 1
  fi

  # Find the corresponding file path based on user's choice and set that to play the song then continue on the list
  for (( i=0; i<"${#filenames[@]}"; ++i )); do
    if [[ "${filenames[$i]}" = "$choice" ]]; then
      notification "$choice"
      mpv --playlist-start="$i" --loop-playlist --vid=no "${local_music[@]}"
      break
    fi
  done
}

#// Main function for shuffling local music
shuffle_local_music() {
  notification "Shuffle Play local music"

  # Play music in $MUSIC_DIR on shuffle
  mpv --shuffle --loop-playlist --vid=no "$MUSIC_DIR"
}

#// Main function for playing online music
play_online_music() {
  choice=$(printf "%s\n" "${!ONLINE_MUSIC[@]}" | sort | rofi -i -dmenu -config "$ROFI_THEME" -theme-str "${r_override} ${font_override}")

  if [[ -z "$choice" ]]; then
    exit 1
  fi

  link="${ONLINE_MUSIC[$choice]}"

  notification "$choice"
  
  # Play the selected online music using mpv
  mpv --shuffle --vid=no "$link"
}

#// Function to stop music and kill mpv processes
stop_music() {
  mpv_pids=$(pgrep -x mpv)

  if [[ -n "$mpv_pids" ]]; then
    # Get the PID of the mpv process used by mpvpaper (using the unique argument added)
    mpvpaper_pid=$(ps aux | grep -- 'unique-wallpaper-process' | grep -v 'grep' | awk '{print $2}')

    for pid in $mpv_pids; do
      if ! echo "$mpvpaper_pid" | grep -q "$pid"; then
        kill -9 $pid || true 
      fi
    done
    notify-send -u low -i "$DEFAULT_ICON" "Music stopped" || true
  fi
}

#// Main Execution

# Check if music is already playing
if pgrep -x "mpv" > /dev/null; then
  stop_music
else
  user_choice=$(printf "Play from Online Stations\nPlay from Music directory\nShuffle Play from Music directory" | rofi -dmenu -config "$ROFI_MENU_THEME" -theme-str "${r_override} ${font_override}")

  case "$user_choice" in
    "Play from Music directory")
      play_local_music
      ;;
    "Play from Online Stations")
      play_online_music
      ;;
    "Shuffle Play from Music directory")
      shuffle_local_music
      ;;
    *)
      ;;
  esac
fi
