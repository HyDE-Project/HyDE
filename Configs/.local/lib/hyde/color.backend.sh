#!/usr/bin/env bash
if ! source "$(which hyde-shell)"; then
    echo "[$0] :: Error: hyde-shell not found."
    echo "[$0] :: Is HyDE installed?"
    exit 1
fi

# shellcheck disable=SC1091
source "${LIB_DIR}/hyde/shutils/argparse.sh"

VALID_BACKENDS=("imagemagick" "matugen")

fn_get() {
    [ -f "$HYDE_STATE_HOME/staterc" ] && source "$HYDE_STATE_HOME/staterc"
    local current="${DCOL_BACKEND:-imagemagick}"
    echo "$current"
}

fn_set() {
    local backend="$1"
    if [[ -z "$backend" ]]; then
        echo "Error: no backend specified"
        echo "Available backends: ${VALID_BACKENDS[*]}"
        exit 1
    fi

    # Validate
    local valid=false
    for b in "${VALID_BACKENDS[@]}"; do
        if [[ "$backend" == "$b" ]]; then
            valid=true
            break
        fi
    done

    if [[ "$valid" == false ]]; then
        echo "Error: invalid backend '$backend'"
        echo "Available backends: ${VALID_BACKENDS[*]}"
        exit 1
    fi

    # Check matugen is installed if selecting it
    if [[ "$backend" == "matugen" ]] && ! command -v matugen &>/dev/null; then
        echo "Error: matugen not found. Install with: paru -S matugen-bin"
        exit 1
    fi

    set_conf "DCOL_BACKEND" "$backend"
    echo "Color backend set to: $backend"
    notify-send -i "preferences-desktop-color" "HyDE Color Backend" "Switched to $backend"
}

fn_select() {
    [ -f "$HYDE_STATE_HOME/staterc" ] && source "$HYDE_STATE_HOME/staterc"
    local current="${DCOL_BACKEND:-imagemagick}"

    font_scale="$ROFI_SCALE"
    [[ $font_scale =~ ^[0-9]+$ ]] || font_scale=10
    font_name=${ROFI_FONT:-$(get_hyprConf "MENU_FONT")}
    font_name=${font_name:-$(get_hyprConf "FONT")}
    font_override="* {font: \"${font_name:-"JetBrainsMono Nerd Font"} $font_scale\";}"
    hypr_border=${hypr_border:-"$(hyprctl -j getoption decoration:rounding | jq '.int')"}
    wind_border=$((hypr_border * 3 / 2))
    elem_border=$((hypr_border == 0 ? 5 : hypr_border))
    hypr_width=${hypr_width:-"$(hyprctl -j getoption general:border_size | jq '.int')"}
    r_override="window{border:${hypr_width}px;border-radius:${wind_border}px;} wallbox{border-radius:${elem_border}px;} element{border-radius:${elem_border}px;}"

    local options
    options=$(printf '%s\n' "${VALID_BACKENDS[@]}")

    local selected
    selected=$(echo "$options" | rofi -dmenu -i -select "$current" \
        -p "Color backend" \
        -theme-str 'entry { placeholder: "Select color backend..."; }' \
        -theme-str "$font_override" \
        -theme-str "$r_override" \
        -theme-str "$(get_rofi_pos)" \
        -theme "clipboard")

    if [[ -z "$selected" ]]; then
        exit 0
    fi

    fn_set "$selected"
}

# Initialize argparse
argparse_init "$@"

argparse_program "hyde-shell color.backend"
argparse_header "HyDE Color Backend Selector"

argparse "--get,-g" "" "Print the current color backend"
argparse "--set,-s" "BACKEND" "Set the color backend (imagemagick or matugen)" "parameter"
argparse "--select,-S" "" "Select backend interactively via rofi"

argparse_finalize

case $ARGPARSE_ACTION in
    get) fn_get ;;
    set) fn_set "$BACKEND" ;;
    select) fn_select ;;
    *) argparse_help ;;
esac
