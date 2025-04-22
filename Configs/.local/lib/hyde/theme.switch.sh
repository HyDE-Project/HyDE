#!/usr/bin/env bash
# shellcheck disable=SC2154

#// set variables

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"
[ -z "${HYDE_THEME}" ] && echo "ERROR: unable to detect theme" && exit 1
get_themes
confDir="${XDG_CONFIG_HOME:-$(xdg-user-dir CONFIG)}"
#// define functions

Theme_Change() {
  local x_switch=$1

  # shellcheck disable=SC2154
  for i in "${!thmList[@]}"; do
    if [ "${thmList[i]}" == "${HYDE_THEME}" ]; then
      if [ "${x_switch}" == 'n' ]; then
        setIndex=$(((i + 1) % ${#thmList[@]}))
      elif [ "${x_switch}" == 'p' ]; then
        setIndex=$((i - 1))
      fi
      themeSet="${thmList[setIndex]}"
      break
    fi
  done
}

sanitize_hypr_theme() {
  input_file="${1}"
  output_file="${2}"
  buffer_file="$(mktemp)"

  sed '1d' "${input_file}" >"${buffer_file}"
  # Define an array of patterns to remove
  # Supports regex patterns
  dirty_regex=(
    "^ *exec"
    "^ *decoration[^:]*: *drop_shadow"
    "^ *drop_shadow"
    "^ *decoration[^:]*: *shadow *="
    "^ *decoration[^:]*: *col.shadow* *="
    "^ *shadow_"
    "^ *col.shadow*"
  )

  dirty_regex+=("${HYPR_CONFIG_SANITIZE[@]}")

  # Loop through each pattern and remove matching lines
  for pattern in "${dirty_regex[@]}"; do
    grep -E "${pattern}" "${buffer_file}" | while read -r line; do
      sed -i "\|${line}|d" "${buffer_file}"
      print_log -sec "theme" -warn "sanitize" "${line}"
    done
  done
  cat "${buffer_file}" >"${output_file}"
  rm -f "${buffer_file}"

}

#// evaluate options
quiet=false
while getopts "qnps:" option; do
  case $option in

  n) # set next theme
    Theme_Change n
    export xtrans="grow"
    ;;

  p) # set previous theme
    Theme_Change p
    export xtrans="outer"
    ;;

  s) # set selected theme
    themeSet="$OPTARG" ;;
  q)
    quiet=true
    ;;
  *) # invalid option
    echo "... invalid option ..."
    echo "$(basename "${0}") -[option]"
    echo "n : set next theme"
    echo "p : set previous theme"
    echo "s : set input theme"
    exit 1
    ;;
  esac
done

#// update control file

# shellcheck disable=SC2076
[[ ! " ${thmList[*]} " =~ " ${themeSet} " ]] && themeSet="${HYDE_THEME}"

set_conf "HYDE_THEME" "${themeSet}"
print_log -sec "theme" -stat "apply" "${themeSet}"

export reload_flag=1
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"

#// hypr
# shellcheck disable=SC2154
# Updates the compositor theme data in advance
[[ -n $HYPRLAND_INSTANCE_SIGNATURE ]] && hyprctl keyword misc:disable_autoreload 1 -q
sanitize_hypr_theme "${HYDE_THEME_DIR}/hypr.theme" "${XDG_CONFIG_HOME}/hypr/themes/theme.conf"

# shellcheck disable=SC2154
if [ "${enableWallDcol}" -eq 0 ]; then
  GTK_THEME="$(get_hyprConf "GTK_THEME")"
else
  GTK_THEME="Wallbash-Gtk"
fi
GTK_ICON="$(get_hyprConf "ICON_THEME")"
CURSOR_THEME="$(get_hyprConf "CURSOR_THEME")"
font_name="$(get_hyprConf "FONT")"
font_size="$(get_hyprConf "FONT_SIZE")"
monospace_font_name="$(get_hyprConf "MONOSPACE_FONT")"

# Early load the icon theme so that it is available for the rest of the script
if ! dconf write /org/gnome/desktop/interface/icon-theme "'${GTK_ICON}'"; then
  print_log -sec "theme" -warn "dconf" "failed to set icon theme"
fi

# legacy and directory resolution
if [ -d /run/current-system/sw/share/themes ]; then
  export themesDir=/run/current-system/sw/share/themes
fi

if [ ! -d "${themesDir}/${GTK_THEME}" ] && [ -d "$HOME/.themes/${GTK_THEME}" ]; then
  cp -rns "$HOME/.themes/${GTK_THEME}" "${themesDir}/${GTK_THEME}"
fi

#// qt5ct

toml_write "${confDir}/qt5ct/qt5ct.conf" "Appearance" "icon_theme" "${GTK_ICON}"
toml_write "${confDir}/qt5ct/qt5ct.conf" "Fonts" "general" "\"${font_name},10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,\""
toml_write "${confDir}/qt5ct/qt5ct.conf" "Fonts" "fixed" "\"${monospace_font_name},9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,\""
# toml_write "${confDir}/qt5ct/qt5ct.conf" "Appearance" "color_scheme_path" "${confDir}/qt5ct/colors/colors.conf"
# toml_write "${confDir}/qt5ct/qt5ct.conf" "Appearance" "custom_palette" "true"

# // qt6ct

toml_write "${confDir}/qt6ct/qt6ct.conf" "Appearance" "icon_theme" "${GTK_ICON}"
toml_write "${confDir}/qt6ct/qt6ct.conf" "Fonts" "general" "\"${font_name},10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,\""
toml_write "${confDir}/qt6ct/qt6ct.conf" "Fonts" "fixed" "\"${monospace_font_name},9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,\""
# toml_write "${confDir}/qt6ct/qt6ct.conf" "Appearance" "color_scheme_path" "${confDir}/qt6ct/colors/colors.conf"
# toml_write "${confDir}/qt6ct/qt6ct.conf" "Appearance" "custom_palette" "true"

# // kde plasma

toml_write "${confDir}/kdeglobals" "Icons" "Theme" "${GTK_ICON}"
toml_write "${confDir}/kdeglobals" "General" "TerminalApplication" "${TERMINAL}"
toml_write "${confDir}/kdeglobals" "UiSettings" "ColorScheme" "colors"

# For KDE stuff

toml_write "${confDir}/kdeglobals" "KDE" "widgetStyle" "kvantum"
# toml_write "${confDir}/kdeglobals" "Colors:View" "BackgroundNormal" "#00000000" #! This is set on wallbash

# // The default cursor theme // fallback

toml_write "${XDG_DATA_HOME}/icons/default/index.theme" "Icon Theme" "Inherits" "${CURSOR_THEME}"
toml_write "${HOME}/.icons/default/index.theme" "Icon Theme" "Inherits" "${CURSOR_THEME}"

# // gtk2

sed -i -e "/^gtk-theme-name=/c\gtk-theme-name=\"${GTK_THEME}\"" \
  -e "/^include /c\include \"$HOME/.gtkrc-2.0.mime\"" \
  -e "/^gtk-cursor-theme-name=/c\gtk-cursor-theme-name=\"${CURSOR_THEME}\"" \
  -e "/^gtk-icon-theme-name=/c\gtk-icon-theme-name=\"${GTK_ICON}\"" "$HOME/.gtkrc-2.0"

#// gtk3

toml_write "${confDir}/gtk-3.0/settings.ini" "Settings" "gtk-theme-name" "${GTK_THEME}"
toml_write "${confDir}/gtk-3.0/settings.ini" "Settings" "gtk-icon-theme-name" "${GTK_ICON}"
toml_write "${confDir}/gtk-3.0/settings.ini" "Settings" "gtk-cursor-theme-name" "${CURSOR_THEME}"
toml_write "${confDir}/gtk-3.0/settings.ini" "Settings" "gtk-font-name" "${font_name} ${font_size}"

#// gtk4
if [ -d "${themesDir}/${GTK_THEME}/gtk-4.0" ]; then
  gtk4Theme="${GTK_THEME}"
else
  gtk4Theme="Wallbash-Gtk"
  print_log -sec "theme" -stat "use" "'Wallbash-Gtk' as gtk4 theme"
fi
rm -rf "${confDir}/gtk-4.0"
ln -s "${themesDir}/${gtk4Theme}/gtk-4.0" "${confDir}/gtk-4.0"

#// flatpak GTK

if pkg_installed flatpak; then
  flatpak \
    --user override \
    --filesystem="${themesDir}":ro \
    --filesystem="$HOME/.themes":ro \
    --filesystem="$HOME/.icons":ro \
    --filesystem="$HOME/.local/share/icons":ro \
    --env=GTK_THEME="${gtk4Theme}" \
    --env=ICON_THEME="${GTK_ICON}"

  flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo &

fi
# // xsettingsd

sed -i -e "/^Net\/ThemeName /c\Net\/ThemeName \"${GTK_THEME}\"" \
  -e "/^Net\/IconThemeName /c\Net\/IconThemeName \"${GTK_ICON}\"" \
  -e "/^Gtk\/CURSOR_THEMEName /c\Gtk\/CURSOR_THEMEName \"${CURSOR_THEME}\"" \
  "$confDir/xsettingsd/xsettingsd.conf"

# // Legacy themes using ~/.themes also fixed GTK4 not following xdg

if [ ! -L "$HOME/.themes/${GTK_THEME}" ] && [ -d "${themesDir}/${GTK_THEME}" ]; then
  print_log -sec "theme" -warn "linking" "${GTK_THEME} to ~/.themes to fix GTK4 not following xdg"
  mkdir -p "$HOME/.themes"
  rm -rf "$HOME/.themes/${GTK_THEME}"
  ln -snf "${themesDir}/${GTK_THEME}" "$HOME/.themes/"
fi

#// wallpaper
export -f pkg_installed
export scrDir

[[ -d "$HYDE_CACHE_HOME/wallpapers/" ]] && find "$HYDE_CACHE_HOME/wallpapers" -name "*.png" -exec sh -c '
    for file; do
        base=$(basename "$file" .png)
        if pkg_installed ${base}; then
            "${scrDir}/wallpaper.sh" --link --backend "${base}"
        fi
    done
' sh {} + &

if [ "$quiet" = true ]; then
  "${scrDir}/wallpaper.sh" -s "$(readlink "${HYDE_THEME_DIR}/wall.set")" --global >/dev/null 2>&1
else
  "${scrDir}/wallpaper.sh" -s "$(readlink "${HYDE_THEME_DIR}/wall.set")" --global
fi
