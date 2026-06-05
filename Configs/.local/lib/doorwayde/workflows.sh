#!/usr/bin/env bash
if ! source "$(which doorwayde-shell)"; then
    echo "[$0] :: Error: doorwayde-shell not found."
    echo "[$0] :: Is DOORwayDE installed?"
    exit 1
fi

# Source argparse.sh for argument parsing
source "${LIB_DIR}/doorwayde/shutils/argparse.sh"

confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
workflows_dir="$confDir/hypr/workflows"
if [ ! -d "$workflows_dir" ]; then
    notify-send -i "preferences-desktop-display" "Error" "Workflows directory does not exist at $workflows_dir"
    exit 1
fi

fn_select() {
    default_icon=$(get_hyprConf "WORKFLOW_ICON" "$workflows_dir/default.conf")
    default_icon=${default_icon:0:1}
    workflow_list="$default_icon\t default"
    while IFS= read -r workflow_path; do
        workflow_name=$(basename "$workflow_path" .conf | xargs)
        [ "$workflow_name" = "default" ] && continue
        workflow_icon=$(get_hyprConf "WORKFLOW_ICON" "$workflow_path")
        workflow_icon=${workflow_icon:0:1}
        workflow_list="$workflow_list\n$workflow_icon\t $workflow_name"
    done < <(find -L "$workflows_dir" -type f -name "*.conf" 2>/dev/null)
    font_scale="$ROFI_WORKFLOW_SCALE"
    [[ $font_scale =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}
    font_name=${ROFI_WORKFLOW_FONT:-$ROFI_FONT}
    font_name=${font_name:-$(get_hyprConf "MENU_FONT")}
    font_name=${font_name:-$(get_hyprConf "FONT")}
    font_override="* {font: \"${font_name:-\"JetBrainsMono Nerd Font\"} $font_scale\";}"
    hypr_border=${hypr_border:-"$(hyprctl -j getoption decoration:rounding | jq '.int')"}
    wind_border=$((hypr_border * 3 / 2))
    elem_border=$((hypr_border == 0 ? 5 : hypr_border))
    hypr_width=${hypr_width:-"$(hyprctl -j getoption general:border_size | jq '.int')"}
    r_override="window{border:${hypr_width}px;border-radius:${wind_border}px;} wallbox{border-radius:${elem_border}px;} element{border-radius:${elem_border}px;}"
    rofi_select="${HYPR_WORKFLOW/default/default}"
    selected_workflow=$(echo -e "$workflow_list" | rofi -dmenu -i -select "$rofi_select" \
        -p "Select workflow" \
        -theme-str 'entry { placeholder: "💼 Select workflow..."; }' \
        -theme-str "$font_override" \
        -theme-str "$r_override" \
        -theme-str "$(get_rofi_pos)" \
        -theme "clipboard")
    if [ -z "$selected_workflow" ]; then
        exit 0
    fi
    selected_workflow=$(awk -F'\t' '{print $2}' <<<"$selected_workflow" | xargs)
    set_conf "HYPR_WORKFLOW" "$selected_workflow"
    fn_update
}
get_info() {
    [ -f "$DOORWAYDE_STATE_HOME/config" ] && source "$DOORWAYDE_STATE_HOME/config"
    [ -f "$DOORWAYDE_STATE_HOME/staterc" ] && source "$DOORWAYDE_STATE_HOME/staterc"
    current_workflow=${HYPR_WORKFLOW:-"default"}
    current_icon=$(get_hyprConf "WORKFLOW_ICON" "$workflows_dir/$current_workflow.conf")
    current_icon=${current_icon:0:1}
    current_description=$(get_hyprConf "WORKFLOW_DESCRIPTION" "$workflows_dir/$current_workflow.conf")
    current_description=${current_description:-"No description available"}
    export current_icon current_workflow current_description
}
fn_update() {
    get_info
    cat <<EOF >"$confDir/hypr/workflows.lua"
-- DOORwayDE controlled content -- DO NOT EDIT
-- Edit or add workflows in ./workflows/ and run
-- 'doorwayde-shell workflows --select' to update this file.
-- See https://wiki.hypr.land/Configuring/Variables/

local workflow = "$current_workflow"
require("workflows/" .. workflow)
EOF
    printf "%s %s: %s\n" "$current_icon" "$current_workflow" "$current_description"
    notify-send -r 9 -i "preferences-desktop-display" "Workflow: $current_icon $current_workflow" "$current_description"
}
# Initialize argparse
argparse_init "$@"

# Set program name and header
argparse_program "doorwayde-shell workflows"
argparse_header "DOORwayDE Workflow Selector"

# Define arguments
argparse "--set" "WORKFLOW_NAME" "Set the given workflow" "parameter"
argparse "--select,-S" "" "Select a workflow from the available options"
argparse "--help,-h" "" "Show this help message"

# Finalize parsing
argparse_finalize

# Handle the parsed arguments
[[ -z $ARGPARSE_ACTION ]] && ARGPARSE_ACTION=help

case "$ARGPARSE_ACTION" in
select)
    fn_select
    ;;
set)
    if [ -z "$WORKFLOW_NAME" ]; then
        echo "Error: --set requires a workflow name"
        exit 1
    fi
    set_conf "HYPR_WORKFLOW" "$WORKFLOW_NAME"
    fn_update
    ;;
help) argparse_help ;;
*) argparse_help ;;
esac
