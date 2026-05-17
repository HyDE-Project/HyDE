#!/usr/bin/env bash
[[ $HALLWAYDE_SHELL_INIT -ne 1 ]] && eval "$(hallwayde-shell init)"
source "$SHARE_DIR/hallwayde/env-theme"
dconf_populate() {
    cat << EOF
[org/gnome/desktop/interface]
icon-theme='$ICON_THEME'
gtk-theme='$GTK_THEME'
color-scheme='$COLOR_SCHEME'
cursor-theme='$CURSOR_THEME'
cursor-size=$CURSOR_SIZE
font-name='$FONT $FONT_SIZE'
document-font-name='$DOCUMENT_FONT $DOCUMENT_FONT_SIZE'
monospace-font-name='$MONOSPACE_FONT $MONOSPACE_FONT_SIZE'
font-antialiasing='$FONT_ANTIALIASING'
font-hinting='$FONT_HINTING'

[org/gnome/desktop/default-applications/terminal]
exec='$(command -v "$TERMINAL")'

[org/gnome/desktop/wm/preferences]
button-layout='$BUTTON_LAYOUT'
EOF
}
COLOR_SCHEME="prefer-$dcol_mode"
GTK_THEME="Wallbash-Gtk"
if [[ -r $HYPRLAND_CONFIG ]] && command -v "hyq" &> /dev/null; then
    eval "$(hyq "$HYPRLAND_CONFIG" --source --export env \
        -Q 'hallwayde:gtk-theme' \
        -Q 'hallwayde:color-scheme' \
        -Q 'hallwayde:icon-theme' \
        -Q 'hallwayde:cursor-theme' \
        -Q 'hallwayde:cursor-size' \
        -Q 'hallwayde:terminal' \
        -Q 'hallwayde:font' \
        -Q 'hallwayde:font-size' \
        -Q 'hallwayde:document-font' \
        -Q 'hallwayde:document-font-size' \
        -Q 'hallwayde:monospace-font' \
        -Q 'hallwayde:monospace-font-size' \
        -Q 'hallwayde:button-layout' \
        -Q 'hallwayde:font-antialiasing' \
        -Q 'hallwayde:font-hinting')"
    GTK_THEME=${_hallwayde_gtk_theme:-$GTK_THEME}
    COLOR_SCHEME=${_hallwayde_color_scheme:-$COLOR_SCHEME}
    ICON_THEME=${_hallwayde_icon_theme:-$ICON_THEME}
    CURSOR_THEME=${_hallwayde_cursor_theme:-$CURSOR_THEME}
    CURSOR_SIZE=${_hallwayde_cursor_size:-$CURSOR_SIZE}
    TERMINAL=${_hallwayde_terminal:-$TERMINAL}
    FONT=${_hallwayde_font:-$FONT}
    FONT_SIZE=${_hallwayde_font_size:-$FONT_SIZE}
    DOCUMENT_FONT=${_hallwayde_document_font:-$DOCUMENT_FONT}
    DOCUMENT_FONT_SIZE=${_hallwayde_document_font_size:-$DOCUMENT_FONT_SIZE}
    MONOSPACE_FONT=${_hallwayde_monospace_font:-$MONOSPACE_FONT}
    MONOSPACE_FONT_SIZE=${_hallwayde_monospace_font_size:-$MONOSPACE_FONT_SIZE}
    BUTTON_LAYOUT=${_hallwayde_button_layout:-$BUTTON_LAYOUT}
    FONT_ANTIALIASING=${_hallwayde_font_antialiasing:-$FONT_ANTIALIASING}
    FONT_HINTING=${_hallwayde_font_hinting:-$FONT_HINTING}
fi
if [[ ${revert_colors:-0} -eq 1 ]] || [[ ${enableWallDcol:-0} -eq 2 && ${dcol_mode:-} == "light" ]] || [[ ${enableWallDcol:-0} -eq 3 && ${dcol_mode:-} == "dark" ]]; then
    if [[ $dcol_mode == "dark" ]]; then
        COLOR_SCHEME="prefer-light"
    else
        COLOR_SCHEME="prefer-dark"
    fi
fi
DCONF_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/hallwayde/dconf"
{
    dconf load -f / < "$DCONF_FILE" && print_log -sec "dconf" -stat "preserve" "$DCONF_FILE"
} || print_log -sec "dconf" -warn "failed to preserve" "$DCONF_FILE"
{
    dconf_populate > "$DCONF_FILE" && print_log -sec "dconf" -stat "populated" "$DCONF_FILE"
} || print_log -sec "dconf" -warn "failed to populate" "$DCONF_FILE"
{
    dconf reset -f / < "$DCONF_FILE" && print_log -sec "dconf" -stat "reset" "$DCONF_FILE"
} || print_log -sec "dconf" -warn "failed to reset" "$DCONF_FILE"
{
    dconf load -f / < "$DCONF_FILE" && print_log -sec "dconf" -stat "loaded" "$DCONF_FILE"
} || print_log -sec "dconf" -warn "failed to load" "$DCONF_FILE"
[[ -n $HYPRLAND_INSTANCE_SIGNATURE ]] && hyprctl setcursor "$CURSOR_THEME" "$CURSOR_SIZE"
print_log -sec "dconf" -stat "Loaded dconf settings"
print_log -y "#-----------------------------------------------#"
dconf_populate
print_log -y "#-----------------------------------------------#"
export GTK_THEME ICON_THEME COLOR_SCHEME CURSOR_THEME CURSOR_SIZE TERMINAL FONT FONT_SIZE DOCUMENT_FONT DOCUMENT_FONT_SIZE MONOSPACE_FONT MONOSPACE_FONT_SIZE BAR_FONT MENU_FONT NOTIFICATION_FONT BUTTON_LAYOUT
