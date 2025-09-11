#!/usr/bin/env bash

# shellcheck disable=SC2154
# shellcheck disable=SC1091

[[ "${HYDE_SHELL_INIT}" -ne 1 ]] && eval "$(hyde-shell init)"

# Stores default values for the theme to avoid breakages.
source "${SHARE_DIR}/hyde/env-theme"

dconf_populate() {
    # Build the dconf content
    cat <<EOF
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
exec='$(command -v "${TERMINAL}")'

[org/gnome/desktop/wm/preferences]
button-layout='$BUTTON_LAYOUT'
EOF
}

# HYDE_THEME="$(hyq "${HYPRLAND_CONFIG}" --source --query 'hyde:theme')"
COLOR_SCHEME="prefer-${dcol_mode}"
GTK_THEME="Wallbash-Gtk"

# Populate variables from hyprland config if exists
if [[ -r "${HYPRLAND_CONFIG}" ]] &&
    command -v "hyq" &>/dev/null; then

    eval "$(
        hyq "${HYPRLAND_CONFIG}" --source --export env \
            -Q 'hyde:gtk-theme' \
            -Q 'hyde:color-scheme' \
            -Q 'hyde:icon-theme' \
            -Q 'hyde:cursor-theme' \
            -Q 'hyde:cursor-size' \
            -Q 'hyde:terminal' \
            -Q 'hyde:font' \
            -Q 'hyde:font-size' \
            -Q 'hyde:document-font' \
            -Q 'hyde:document-font-size' \
            -Q 'hyde:monospace-font' \
            -Q 'hyde:monospace-font-size' \
            -Q 'hyde:button-layout' \
            -Q 'hyde:font-antialiasing' \
            -Q 'hyde:font-hinting'

    )"
    GTK_THEME=${_hyde_gtk_theme:-$GTK_THEME}
    COLOR_SCHEME=${_hyde_color_scheme:-$COLOR_SCHEME}
    ICON_THEME=${_hyde_icon_theme:-$ICON_THEME}
    CURSOR_THEME=${_hyde_cursor_theme:-$CURSOR_THEME}
    CURSOR_SIZE=${_hyde_cursor_size:-$CURSOR_SIZE}
    TERMINAL=${_hyde_terminal:-$TERMINAL}
    FONT=${_hyde_font:-$FONT}
    FONT_SIZE=${_hyde_font_size:-$FONT_SIZE}
    DOCUMENT_FONT=${_hyde_document_font:-$DOCUMENT_FONT}
    DOCUMENT_FONT_SIZE=${_hyde_document_font_size:-$DOCUMENT_FONT_SIZE}
    MONOSPACE_FONT=${_hyde_monospace_font:-$MONOSPACE_FONT}
    MONOSPACE_FONT_SIZE=${_hyde_monospace_font_size:-$MONOSPACE_FONT_SIZE}
    BUTTON_LAYOUT=${_hyde_button_layout:-$BUTTON_LAYOUT}
    FONT_ANTIALIASING=${_hyde_font_antialiasing:-$FONT_ANTIALIASING}
    FONT_HINTING=${_hyde_font_hinting:-$FONT_HINTING}
fi

# Check if we need inverted colors
if [[ "${revert_colors:-0}" -eq 1 ]] ||
    [[ "${enableWallDcol:-0}" -eq 2 && "${dcol_mode:-}" == "light" ]] ||
    [[ "${enableWallDcol:-0}" -eq 3 && "${dcol_mode:-}" == "dark" ]]; then
    if [[ "${dcol_mode}" == "dark" ]]; then
        COLOR_SCHEME="prefer-light"
    else
        COLOR_SCHEME="prefer-dark"
    fi
fi

DCONF_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/hyde/dconf"

# Finalize the env variables

{ dconf load -f / <"${DCONF_FILE}" && print_log -sec "dconf" -stat "preserve" "${DCONF_FILE}"; } || print_log -sec "dconf" -warn "failed to preserve" "${DCONF_FILE}"
{ dconf_populate >"${DCONF_FILE}" && print_log -sec "dconf" -stat "populated" "${DCONF_FILE}"; } || print_log -sec "dconf" -warn "failed to populate" "${DCONF_FILE}"
{ dconf reset -f / <"${DCONF_FILE}" && print_log -sec "dconf" -stat "reset" "${DCONF_FILE}"; } || print_log -sec "dconf" -warn "failed to reset" "${DCONF_FILE}"
{ dconf load -f / <"${DCONF_FILE}" && print_log -sec "dconf" -stat "loaded" "${DCONF_FILE}"; } || print_log -sec "dconf" -warn "failed to load" "${DCONF_FILE}"

[[ -n "${HYPRLAND_INSTANCE_SIGNATURE}" ]] && hyprctl setcursor "${CURSOR_THEME}" "${CURSOR_SIZE}"

print_log -sec "dconf" -stat "Loaded dconf settings"
print_log -y "#-----------------------------------------------#"
dconf_populate
print_log -y "#-----------------------------------------------#"

# Finalize the env variables
export GTK_THEME ICON_THEME COLOR_SCHEME CURSOR_THEME CURSOR_SIZE TERMINAL \
    FONT FONT_SIZE DOCUMENT_FONT DOCUMENT_FONT_SIZE MONOSPACE_FONT MONOSPACE_FONT_SIZE \
    BAR_FONT MENU_FONT NOTIFICATION_FONT BUTTON_LAYOUT
