#!/usr/bin/env bash
[[ $HYDE_SHELL_INIT -ne 1 ]] && eval "$(hyde-shell init)"
[ -z "$HYDE_THEME" ] && echo "ERROR: unable to detect theme" && exit 1
get_themes
confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
Theme_Change() {
    local x_switch=$1
    for i in "${!thmList[@]}"; do
        if [ "${thmList[i]}" == "$HYDE_THEME" ]; then
            if [ "$x_switch" == 'n' ]; then
                setIndex=$(((i + 1) % ${#thmList[@]}))
            elif [ "$x_switch" == 'p' ]; then
                setIndex=$((i - 1))
            fi
            themeSet="${thmList[setIndex]}"
            break
        fi
    done
}
show_theme_status() {
    cat << EOF
Current theme: $HYDE_THEME
Gtk theme: $GTK_THEME
Icon theme: $ICON_THEME
Cursor theme: $CURSOR_THEME
Cursor size: $CURSOR_SIZE
Terminal: $TERMINAL
Font: $FONT
Font style: $FONT_STYLE
Font size: $FONT_SIZE
Document font: $DOCUMENT_FONT
Document font size: $DOCUMENT_FONT_SIZE
Monospace font: $MONOSPACE_FONT
Monospace font size: $MONOSPACE_FONT_SIZE
Bar font: $BAR_FONT
Menu font: $MENU_FONT
Notification font: $NOTIFICATION_FONT

EOF
}
load_hypr_variables() {
    local hypr_file="$1"
    eval "$(hyq "$hypr_file" \
        --export env \
        -Q '$GTK_THEME[string]' \
        -Q '$ICON_THEME[string]' \
        -Q '$CURSOR_THEME[string]' \
        -Q '$CURSOR_SIZE' \
        -Q '$FONT[string]' \
        -Q '$FONT_SIZE' \
        -Q '$FONT_STYLE[string]' \
        -Q '$DOCUMENT_FONT[string]' \
        -Q '$DOCUMENT_FONT_SIZE' \
        -Q '$MONOSPACE_FONT[string]' \
        -Q '$MONOSPACE_FONT_SIZE')"
    GTK_THEME=${__GTK_THEME:-$GTK_THEME}
    ICON_THEME=${__ICON_THEME:-$ICON_THEME}
    CURSOR_THEME=${__CURSOR_THEME:-$CURSOR_THEME}
    CURSOR_SIZE=${__CURSOR_SIZE:-$CURSOR_SIZE}
    TERMINAL=${__TERMINAL:-$TERMINAL}
    FONT=${__FONT:-$FONT}
    FONT_STYLE=${__FONT_STYLE:-''}
    FONT_SIZE=${__FONT_SIZE:-$FONT_SIZE}
    DOCUMENT_FONT=${__DOCUMENT_FONT:-$DOCUMENT_FONT}
    DOCUMENT_FONT_SIZE=${__DOCUMENT_FONT_SIZE:-$DOCUMENT_FONT_SIZE}
    MONOSPACE_FONT=${__MONOSPACE_FONT:-$MONOSPACE_FONT}
    MONOSPACE_FONT_SIZE=${__MONOSPACE_FONT_SIZE:-$MONOSPACE_FONT_SIZE}
    BAR_FONT=${__BAR_FONT:-$BAR_FONT}
    MENU_FONT=${__MENU_FONT:-$MENU_FONT}
    NOTIFICATION_FONT=${__NOTIFICATION_FONT:-$NOTIFICATION_FONT}
}
sanitize_hypr_theme() {
    input_file="$1"
    output_file="$2"
    buffer_file="$(mktemp)"
    sed '1d' "$input_file" > "$buffer_file"
    dirty_regex=(
        "^ *exec"
        "^ *decoration[^:]*: *drop_shadow"
        "^ *drop_shadow"
        "^ *decoration[^:]*: *shadow *="
        "^ *decoration[^:]*: *col.shadow* *="
        "^ *shadow_"
        "^ *col.shadow*")
    dirty_regex+=("${HYPR_CONFIG_SANITIZE[@]}")
    for pattern in "${dirty_regex[@]}"; do
        grep -E "$pattern" "$buffer_file" | while read -r line; do
            sed -i "\|$line|d" "$buffer_file"
            print_log -sec "theme" -warn "sanitize" "$line"
        done
    done
    cat "$buffer_file" > "$output_file"
    rm -f "$buffer_file"
}
quiet=false
while getopts "qnps:" option; do
    case $option in
        n)
            Theme_Change n
            export xtrans="grow"
            ;;
        p)
            Theme_Change p
            export xtrans="outer"
            ;;
        s) themeSet="$OPTARG" ;;
        q)
            quiet=true
            ;;
        *)
            echo "... invalid option ..."
            echo "$(basename "$0") -[option]"
            echo "n : set next theme"
            echo "p : set previous theme"
            echo "s : set input theme"
            exit 1
            ;;
    esac
done
[[ ! " ${thmList[*]} " =~ " $themeSet " ]] && themeSet="$HYDE_THEME"
set_conf "HYDE_THEME" "$themeSet"
print_log -sec "theme" -stat "apply" "$themeSet"
export reload_flag=1
source "$LIB_DIR/hyde/globalcontrol.sh"
source "$SHARE_DIR/hyde/env-theme"
if [[ -r $HYPRLAND_CONFIG ]]; then
    [[ -n $HYPRLAND_INSTANCE_SIGNATURE ]] && hyprctl keyword misc:disable_autoreload 1 -q
    [[ -r "$HYDE_THEME_DIR/hypr.theme" ]] && sanitize_hypr_theme "$HYDE_THEME_DIR/hypr.theme" "$XDG_CONFIG_HOME/hypr/themes/theme.conf"
    load_hypr_variables "$HYDE_THEME_DIR/hypr.theme"
    load_hypr_variables "${XDG_STATE_DIR:-$HOME/.local/state}/hyde/hyprland.conf"
fi
show_theme_status
if ! dconf write /org/gnome/desktop/interface/icon-theme "'$ICON_THEME'"; then
    print_log -sec "theme" -warn "dconf" "failed to set icon theme"
fi
if [ -d /run/current-system/sw/share/themes ]; then
    export themesDir=/run/current-system/sw/share/themes
fi
if [ ! -d "$themesDir/$GTK_THEME" ] && [ -d "$HOME/.themes/$GTK_THEME" ]; then
    cp -rns "$HOME/.themes/$GTK_THEME" "$themesDir/$GTK_THEME"
fi
QT5_FONT="${QT5_FONT:-$FONT}"
QT5_FONT_SIZE="${QT5_FONT_SIZE:-$FONT_SIZE}"
QT5_MONOSPACE_FONT="${QT5_MONOSPACE_FONT:-$MONOSPACE_FONT}"
QT5_MONOSPACE_FONT_SIZE="${QT5_MONOSPACE_FONT_SIZE:-${MONOSPACE_FONT_SIZE:-9}}"
toml_write "$confDir/qt5ct/qt5ct.conf" "Appearance" "icon_theme" "$ICON_THEME"
toml_write "$confDir/qt5ct/qt5ct.conf" "Fonts" "general" "\"$QT5_FONT,$QT5_FONT_SIZE,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,$FONT_STYLE\""
toml_write "$confDir/qt5ct/qt5ct.conf" "Fonts" "fixed" "\"$QT5_MONOSPACE_FONT,$QT5_MONOSPACE_FONT_SIZE,-1,5,400,0,0,0,0,0,0,0,0,0,0,1\""
QT6_FONT="${QT6_FONT:-$FONT}"
QT6_FONT_SIZE="${QT6_FONT_SIZE:-$FONT_SIZE}"
QT6_MONOSPACE_FONT="${QT6_MONOSPACE_FONT:-$MONOSPACE_FONT}"
QT6_MONOSPACE_FONT_SIZE="${QT6_MONOSPACE_FONT_SIZE:-${MONOSPACE_FONT_SIZE:-9}}"
toml_write "$confDir/qt6ct/qt6ct.conf" "Appearance" "icon_theme" "$ICON_THEME"
toml_write "$confDir/qt6ct/qt6ct.conf" "Fonts" "general" "\"$QT6_FONT,$QT6_FONT_SIZE,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,$FONT_STYLE\""
toml_write "$confDir/qt6ct/qt6ct.conf" "Fonts" "fixed" "\"$QT6_MONOSPACE_FONT,${QT6_MONOSPACE_FONT_SIZE:-9},-1,5,400,0,0,0,0,0,0,0,0,0,0,1\""
toml_write "$confDir/kdeglobals" "Icons" "Theme" "$ICON_THEME"
toml_write "$confDir/kdeglobals" "General" "TerminalApplication" "$TERMINAL"
toml_write "$confDir/kdeglobals" "UiSettings" "ColorScheme" "colors"
toml_write "$confDir/kdeglobals" "KDE" "widgetStyle" "kvantum"
toml_write "$XDG_DATA_HOME/icons/default/index.theme" "Icon Theme" "Inherits" "$CURSOR_THEME"
toml_write "$HOME/.icons/default/index.theme" "Icon Theme" "Inherits" "$CURSOR_THEME"
sed -i -e "/^gtk-theme-name=/c\gtk-theme-name=\"$GTK_THEME\"" \
    -e "/^include /c\include \"$HOME/.gtkrc-2.0.mime\"" \
    -e "/^gtk-cursor-theme-name=/c\gtk-cursor-theme-name=\"$CURSOR_THEME\"" \
    -e "/^gtk-icon-theme-name=/c\gtk-icon-theme-name=\"$ICON_THEME\"" "$HOME/.gtkrc-2.0"
GTK3_FONT="${GTK3_FONT:-$FONT}"
GTK3_FONT_SIZE="${GTK3_FONT_SIZE:-$FONT_SIZE}"
toml_write "$confDir/gtk-3.0/settings.ini" "Settings" "gtk-theme-name" "$GTK_THEME"
toml_write "$confDir/gtk-3.0/settings.ini" "Settings" "gtk-icon-theme-name" "$ICON_THEME"
toml_write "$confDir/gtk-3.0/settings.ini" "Settings" "gtk-cursor-theme-name" "$CURSOR_THEME"
toml_write "$confDir/gtk-3.0/settings.ini" "Settings" "gtk-cursor-theme-size" "$CURSOR_SIZE"
toml_write "$confDir/gtk-3.0/settings.ini" "Settings" "gtk-font-name" "$GTK3_FONT $GTK3_FONT_SIZE"
if [ -d "$themesDir/$GTK_THEME/gtk-4.0" ]; then
    gtk4Theme="$GTK_THEME"
else
    gtk4Theme="Wallbash-Gtk"
    print_log -sec "theme" -stat "use" "'Wallbash-Gtk' as gtk4 theme"
fi
rm -rf "$confDir/gtk-4.0"
if [ -d "$themesDir/$gtk4Theme/gtk-4.0" ]; then
    ln -s "$themesDir/$gtk4Theme/gtk-4.0" "$confDir/gtk-4.0"
else
    print_log -sec "theme" -warn "gtk4" "theme directory '$themesDir/$gtk4Theme/gtk-4.0' does not exist"
fi
if pkg_installed flatpak; then
    flatpak \
        --user override \
        --filesystem="$themesDir" \
        --filesystem="$HOME/.themes" \
        --filesystem="$HOME/.icons" \
        --filesystem="$HOME/.local/share/icons" \
        --env=GTK_THEME="$gtk4Theme" \
        --env=ICON_THEME="$ICON_THEME"
    flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo &
fi
sed -i -e "/^Net\/ThemeName /c\Net\/ThemeName \"$GTK_THEME\"" \
    -e "/^Net\/IconThemeName /c\Net\/IconThemeName \"$ICON_THEME\"" \
    -e "/^Gtk\/CursorThemeName /c\Gtk\/CursorThemeName \"$CURSOR_THEME\"" \
    -e "/^Gtk\/CursorThemeSize /c\Gtk\/CursorThemeSize $CURSOR_SIZE" \
    "$confDir/xsettingsd/xsettingsd.conf"
if [ ! -L "$HOME/.themes/$GTK_THEME" ] && [ -d "$themesDir/$GTK_THEME" ]; then
    print_log -sec "theme" -warn "linking" "$GTK_THEME to ~/.themes to fix GTK4 not following xdg"
    mkdir -p "$HOME/.themes"
    rm -rf "$HOME/.themes/$GTK_THEME"
    ln -snf "$themesDir/$GTK_THEME" "$HOME/.themes/"
fi
if [ -f "$HOME/.Xresources" ]; then
    sed -i -e "/^Xcursor\.theme:/c\Xcursor.theme: $CURSOR_THEME" \
        -e "/^Xcursor\.size:/c\Xcursor.size: $CURSOR_SIZE" "$HOME/.Xresources"
    grep -q "^Xcursor\.theme:" "$HOME/.Xresources" || echo "Xcursor.theme: $CURSOR_THEME" >> "$HOME/.Xresources"
    grep -q "^Xcursor\.size:" "$HOME/.Xresources" || echo "Xcursor.size: 30" >> "$HOME/.Xresources"
else
    cat > "$HOME/.Xresources" << EOF
Xcursor.theme: $CURSOR_THEME
Xcursor.size: $CURSOR_SIZE
EOF
fi
if [ -f "$HOME/.Xdefaults" ]; then
    sed -i -e "/^Xcursor\.theme:/c\Xcursor.theme: $CURSOR_THEME" \
        -e "/^Xcursor\.size:/c\Xcursor.size: $CURSOR_SIZE" "$HOME/.Xdefaults"
    grep -q "^Xcursor\.theme:" "$HOME/.Xdefaults" || echo "Xcursor.theme: $CURSOR_THEME" >> "$HOME/.Xdefaults"
    grep -q "^Xcursor\.size:" "$HOME/.Xdefaults" || echo "Xcursor.size: 30" >> "$HOME/.Xdefaults"
fi
if [ -f "$confDir/gtk-4.0/settings.ini" ]; then
    rm "$confDir/gtk-4.0/settings.ini"
fi
export -f pkg_installed
[[ -d "$HYDE_CACHE_HOME/wallpapers/" ]] && find -H "$HYDE_CACHE_HOME/wallpapers" -name "*.png" -exec sh -c '
    for file; do
        base=$(basename "$file" .png)
        if pkg_installed ${base}; then
            "${LIB_DIR}/hyde/wallpaper.sh" --link --backend "${base}"
        fi
    done
' sh {} + &
if [ "$quiet" = true ]; then
    "$LIB_DIR/hyde/wallpaper.sh" -s "$(readlink "$HYDE_THEME_DIR/wall.set")" --global > /dev/null 2>&1
else
    "$LIB_DIR/hyde/wallpaper.sh" -s "$(readlink "$HYDE_THEME_DIR/wall.set")" --global
fi
