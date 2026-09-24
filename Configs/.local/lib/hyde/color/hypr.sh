#!/usr/bin/env bash
[[ $HYDE_SHELL_INIT -ne 1 ]] && eval "$(hyde-shell init)"
if [[ ${WALLBASH_STARTUP:-0} -eq 1 ]]; then
    exit 0
fi

confDir="${confDir:-$XDG_CONFIG_HOME}"
cacheDir="${cacheDir:-$XDG_CACHE_HOME/hyde}"
HYDE_THEME="${HYDE_THEME:-}"
HYDE_THEME_DIR="${HYDE_THEME_DIR:-$confDir/hyde/themes/$HYDE_THEME}"
enableWallDcol="${enableWallDcol:-0}"
# Loads the interface variables of a hyprlang file into __NAME variables.
# hyq's `--export env` output is not shell-safe: it does not escape `$(...)`,
# backticks or quotes in a value, so evaluating it runs whatever a downloaded
# theme's hypr.theme or a config.toml value contains (CWE-78). Each value is
# queried on its own and assigned as data instead. Empty results are skipped,
# so a variable the file does not define keeps what an earlier source set.
load_hypr_vars() {
    local file=$1 name value
    for name in GTK_THEME COLOR_SCHEME ICON_THEME CURSOR_THEME CURSOR_SIZE \
        FONT FONT_SIZE DOCUMENT_FONT DOCUMENT_FONT_SIZE MONOSPACE_FONT \
        MONOSPACE_FONT_SIZE CODE_THEME; do
        # Sizes are queried as strings too: an `[int]` hint makes hyq fail on
        # a `$VAR = 24` variable, which would drop a size override silently.
        value=$(hyq "$file" -Q "\$${name}[string]" 2>/dev/null)
        # The sizes end up unquoted in the Lua ui state below, so anything but
        # a plain integer would be written into the file as code.
        [[ ${name} == *_SIZE && ! ${value} =~ ^[0-9]*$ ]] && continue
        [[ -n ${value} ]] && printf -v "__$name" '%s' "${value}"
    done
}
__GTK_THEME= __COLOR_SCHEME= __ICON_THEME= __CURSOR_THEME= __CURSOR_SIZE=
__FONT= __FONT_SIZE= __DOCUMENT_FONT= __DOCUMENT_FONT_SIZE=
__MONOSPACE_FONT= __MONOSPACE_FONT_SIZE= __CODE_THEME=
load_hypr_vars "$HYDE_THEME_DIR/hypr.theme"

# The user's [hyprland] overrides from config.toml (converted into the state
# hyprland.conf) win over the theme, exactly as in theme.switch.sh. Without
# this the Lua ui state written below kept the theme's own GTK theme and
# color/dconf.lua wrote it back into gsettings on every wallbash run, so
# GTK3 apps (Firefox, blueman) ignored the override, see HyDE#2132.
hypr_state_file="${XDG_STATE_HOME:-$HOME/.local/state}/hyde/hyprland.conf"
[[ -f ${hypr_state_file} ]] && load_hypr_vars "$hypr_state_file"

# This is for older themes that do not define the above variables
[[ -z ${__GTK_THEME} ]] && __GTK_THEME=$(get_hyprConf "GTK_THEME")
[[ -z ${__COLOR_SCHEME} ]] && __COLOR_SCHEME=$(get_hyprConf "COLOR_SCHEME")
[[ -z ${__ICON_THEME} ]] && __ICON_THEME=$(get_hyprConf "ICON_THEME")
[[ -z ${__CURSOR_THEME} ]] && __CURSOR_THEME=$(get_hyprConf "CURSOR_THEME")
[[ -z ${__CURSOR_SIZE} ]] && __CURSOR_SIZE=$(get_hyprConf "CURSOR_SIZE[int]")
[[ -z ${__FONT} ]] && __FONT=$(get_hyprConf "FONT")
[[ -z ${__FONT_SIZE} ]] && __FONT_SIZE=$(get_hyprConf "FONT_SIZE[int]")
[[ -z ${__DOCUMENT_FONT} ]] && __DOCUMENT_FONT=$(get_hyprConf "DOCUMENT_FONT")
[[ -z ${__DOCUMENT_FONT_SIZE} ]] && __DOCUMENT_FONT_SIZE=$(get_hyprConf "DOCUMENT_FONT_SIZE[int]")
[[ -z ${__MONOSPACE_FONT} ]] && __MONOSPACE_FONT=$(get_hyprConf "MONOSPACE_FONT")
[[ -z ${__MONOSPACE_FONT_SIZE} ]] && __MONOSPACE_FONT_SIZE=$(get_hyprConf "MONOSPACE_FONT_SIZE[int]")
[[ -z ${__CODE_THEME} ]] && __CODE_THEME=$(get_hyprConf "CODE_THEME")

# get_hyprConf above falls back to the raw file text, so a size can still be
# anything here, and the ui state writes sizes unquoted: drop non-integers.
for _size in __CURSOR_SIZE __FONT_SIZE __DOCUMENT_FONT_SIZE __MONOSPACE_FONT_SIZE; do
    [[ ${!_size} =~ ^[0-9]*$ ]] || printf -v "$_size" ''
done

# Faster: assigns escaped result to a variable instead of using subshell
lua_quote_to() {
    local _val="${2:-}"
    _val="${_val//\\/\\\\}"
    _val="${_val//\"/\\\"}"
    _val="${_val//$'\n'/\\n}"
    _val="${_val//$'\r'/\\r}"

    printf -v "$1" '%s' "$_val"
}

handle_on_lua() {
    ui_state="${XDG_STATE_HOME}/hyde/lua_state/ui.lua"
    wallbash_mode="theme"
    if [[ ${enableWallDcol:-0} -eq 1 ]]; then
        wallbash_mode="auto"
    elif [[ ${enableWallDcol:-0} -eq 2 ]]; then
        wallbash_mode="dark"
    elif [[ ${enableWallDcol:-0} -eq 3 ]]; then
        wallbash_mode="light"
    fi

    local _hyde_theme _gtk_theme _icon_theme _color_scheme
    local _cursor_theme _font _document_font _monospace_font
    local _notification_font _bar_font _menu_font
    local _code_theme _sddm_theme _wallbash_mode

    lua_quote_to _hyde_theme "${HYDE_THEME}"
    lua_quote_to _gtk_theme "${__GTK_THEME}"
    lua_quote_to _icon_theme "${__ICON_THEME}"
    lua_quote_to _color_scheme "${__COLOR_SCHEME}"
    lua_quote_to _cursor_theme "${__CURSOR_THEME}"
    lua_quote_to _font "${__FONT}"
    lua_quote_to _document_font "${__DOCUMENT_FONT}"
    lua_quote_to _monospace_font "${__MONOSPACE_FONT}"
    lua_quote_to _notification_font "${__NOTIFICATION_FONT:-${__FONT}}"
    lua_quote_to _bar_font "${__BAR_FONT:-${__FONT}}"
    lua_quote_to _menu_font "${__MENU_FONT:-${__FONT}}"
    lua_quote_to _code_theme "${__CODE_THEME}"
    lua_quote_to _sddm_theme "${__SDDM_THEME}"
    lua_quote_to _wallbash_mode "${wallbash_mode}"

    # ? UI config state
    cat <<ON_WALLBASH >"${ui_state}" && print_log -sec "theme" -stat "Updating HyDE Lua UI state for wallbash mode"
-- Auto-generated by HyDE // Read-only
local ui_state = {
    ui = {
        hyde_theme = "$_hyde_theme",
        -- gtk
        gtk_theme = "$_gtk_theme",
        icon_theme = "$_icon_theme",
        color_scheme = "$_color_scheme",

        -- Cursor
        cursor_theme = "$_cursor_theme",
        cursor_size = ${__CURSOR_SIZE:-nil},

        -- Fonts
        font = "$_font",
        font_size = ${__FONT_SIZE:-nil},
        document_font = "$_document_font",
        document_font_size = ${__DOCUMENT_FONT_SIZE:-nil},
        monospace_font = "$_monospace_font",
        monospace_font_size = ${__MONOSPACE_FONT_SIZE:-nil},
        notification_font = "$_notification_font",
        bar_font = "$_bar_font",
        menu_font = "$_menu_font",

        -- Extra Themes
        code_theme = "$_code_theme",
        sddm_theme = "$_sddm_theme",
    },
    wallbash = {
        mode = "$_wallbash_mode",
    },
}

return ui_state

ON_WALLBASH
}

handle_on_lua

GTK_THEME="${__GTK_THEME:-$GTK_THEME}"
COLOR_SCHEME="${__COLOR_SCHEME:-$COLOR_SCHEME}"
ICON_THEME="${__ICON_THEME:-$ICON_THEME}"
CURSOR_THEME="${__CURSOR_THEME:-$CURSOR_THEME}"
CURSOR_SIZE="${__CURSOR_SIZE:-$CURSOR_SIZE}"
FONT="${__FONT:-$FONT}"
FONT_SIZE="${__FONT_SIZE:-$FONT_SIZE}"
DOCUMENT_FONT="${__DOCUMENT_FONT:-$DOCUMENT_FONT}"
DOCUMENT_FONT_SIZE="${__DOCUMENT_FONT_SIZE:-$DOCUMENT_FONT_SIZE}"
MONOSPACE_FONT="${__MONOSPACE_FONT:-$MONOSPACE_FONT}"
MONOSPACE_FONT_SIZE="${__MONOSPACE_FONT_SIZE:-$MONOSPACE_FONT_SIZE}"

export GTK_THEME COLOR_SCHEME ICON_THEME CURSOR_THEME CURSOR_SIZE \
    FONT FONT_SIZE DOCUMENT_FONT DOCUMENT_FONT_SIZE MONOSPACE_FONT \
    MONOSPACE_FONT_SIZE
