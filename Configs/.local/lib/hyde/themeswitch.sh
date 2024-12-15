#!/usr/bin/env bash
# shellcheck disable=SC2154

#// set variables

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"
[ -z "${HYDE_THEME}" ] && echo "ERROR: unable to detect theme" && exit 1
get_themes

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

#// evaluate options

while getopts "nps:" option; do
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
[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] && hyprctl keyword misc:disable_autoreload 1 -q
# shellcheck disable=SC2154
sed '1d' "${HYDE_THEME_DIR}/hypr.theme" >"${confDir}/hypr/themes/theme.conf" # Useless and already handled by swwwallbash.sh but kept for robustness
# shellcheck disable=SC2154
if [ "${enableWallDcol}" -eq 0 ]; then
    gtkTheme="$(get_hyprConf "GTK_THEME")"
else
    gtkTheme="Wallbash-Gtk"
fi
gtkIcon="$(get_hyprConf "ICON_THEME")"
cursorTheme="$(get_hyprConf "CURSOR_THEME")"

# legacy and directory resolution
if [ -d /run/current-system/sw/share/themes ]; then
    export themesDir=/run/current-system/sw/share/themes
fi

if [ ! -d "${themesDir}/${gtkTheme}" ] && [ -d "$HOME/.themes/${gtkTheme}" ]; then
    cp -rns "$HOME/.themes/${gtkTheme}" "${themesDir}/${gtkTheme}"
fi

#// qtct

if ! kwriteconfig6 --file "${confDir}/qt5ct/qt5ct.conf" --group "Appearance" --key "icon_theme" "${gtkIcon}" 2>/dev/null; then
    sed -i "/^icon_theme=/c\icon_theme=${gtkIcon}" "${confDir}/qt5ct/qt5ct.conf"
fi
if ! kwriteconfig6 --file "${confDir}/qt6ct/qt6ct.conf" --group "Appearance" --key "icon_theme" "${gtkIcon}" 2>/dev/null; then
    sed -i "/^icon_theme=/c\icon_theme=${gtkIcon}" "${confDir}/qt6ct/qt6ct.conf"
fi
# // kde plasma
if ! kwriteconfig6 --file "${confDir}/kdeglobals" --group "Icons" --key "Theme" "${gtkIcon}" 2>/dev/null; then
    sed -i "/^Theme=/c\Theme=${gtkIcon}" "${confDir}/kdeglobals"
fi

# Ensure [UiSettings] ColorScheme exists in kdeglobals // dolphin fix
if ! kwriteconfig6 --file "${confDir}/kdeglobals" --group "UiSettings" --key "ColorScheme" "${gtkTheme}" 2>/dev/null; then
    if ! grep -q "^\[UiSettings\]" "${confDir}/kdeglobals"; then
        echo -e "\n[UiSettings]\nColorScheme=${gtkTheme}" >>"${confDir}/kdeglobals"
    elif ! grep -q "^ColorScheme=" "${confDir}/kdeglobals"; then
        sed -i "/^\[UiSettings\]/a ColorScheme=${gtkTheme}" "${confDir}/kdeglobals"
    fi
fi

# For KDE stuff
kwriteconfig6 --file "${confDir}/kdeglobals" --group "KDE" --key "windgetStyke" "kvantum" 2>/dev/null
kwriteconfig6 --file "${confDir}/kdeglobals" --group "Colors:View" --key "BackgroundNormal" "#00000000" 2>/dev/null

# // gtk2

sed -i -e "/^gtk-theme-name=/c\gtk-theme-name=\"${gtkTheme}\"" \
    -e "/^include /c\include \"$HOME/.gtkrc-2.0.mime\"" \
    -e "/^gtk-cursor-theme-name=/c\gtk-cursor-theme-name=\"${cursorTheme}\"" \
    -e "/^gtk-icon-theme-name=/c\gtk-icon-theme-name=\"${gtkIcon}\"" "$HOME/.gtkrc-2.0"

#// gtk3

sed -i -e "/^gtk-theme-name=/c\gtk-theme-name=\"${gtkTheme}\"" \
    -e "/^gtk-icon-theme-name=/c\gtk-icon-theme-name=\"${gtkIcon}\"" "$confDir/gtk-3.0/settings.ini"

#// gtk4
if [ -d "${themesDir}/${gtkTheme}/gtk-4.0" ]; then
    gtk4Theme="${gtkTheme}"
else
    gtk4Theme="Wallbash-Gtk"
    print_log -sec "theme" -stat "use" "'Wallbash-Gtk' as gtk4 theme"
fi
rm -rf "${confDir}/gtk-4.0"
ln -s "${themesDir}/${gtk4Theme}/gtk-4.0" "${confDir}/gtk-4.0"

#// flatpak GTK

pkg_installed flatpak && flatpak \
    --user override \
    --filesystem="${themesDir}":ro \
    --filesystem="$HOME/.themes":ro \
    --filesystem="$HOME/.icons":ro \
    --filesystem=~/.local/share/icons:ro \
    --env=GTK_THEME="${gtk4Theme}" \
    --env=ICON_THEME="${gtkIcon}"

# // xsettingsd

sed -i -e "/^Net\/ThemeName /c\Net\/ThemeName \"${gtkTheme}\"" \
    -e "/^Net\/IconThemeName /c\Net\/IconThemeName \"${gtkIcon}\"" \
    -e "/^Gtk\/CursorThemeName /c\Gtk\/CursorThemeName \"${cursorTheme}\"" \
    "$confDir/xsettingsd/xsettingsd.conf"

# // Legacy themes using ~/.themes also fixed GTK4 not following xdg

if [ ! -d "$HOME/.themes" ]; then
    mkdir -p "$HOME/.themes"
fi

if [ ! -L "$HOME/.themes" ] && [ -d "${themesDir}/" ]; then
    ln -snf "${themesDir}/" "$HOME/.themes"
fi

#// wallpaper

"${scrDir}/swwwallpaper.sh" -s "$(readlink "${HYDE_THEME_DIR}/wall.set")"
