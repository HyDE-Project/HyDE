#!/usr/bin/env bash

# shellcheck source=$HOME/.local/bin/hyde-shell
# shellcheck disable=SC1091
if ! source "$(which hyde-shell)"; then
  echo "[$0] :: Error: hyde-shell not found."
  echo "[$0] :: Is HyDE installed?"
  exit 1
fi
# Set variables
confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
workflows_dir="$confDir/hypr/workflows"

# Ensure the workflows directory exists
if [ ! -d "$workflows_dir" ]; then
  notify-send -i "preferences-desktop-display" "Error" "Workflows directory does not exist at $workflows_dir"
  exit 1
fi

# Show help function
show_help() {
  cat <<HELP
Usage: $0 [OPTIONS]

Options:
    --select | -S       Select a workflow from the available options
    --set               Set the given workflow
    --waybar            Get workflow info for Waybar
    --help   | -h       Show this help message
    
HELP
}

if [ -z "${*}" ]; then
  echo "No arguments provided"
  show_help
fi

# Define long options
LONG_OPTS="select,set:,waybar,help"
SHORT_OPTS="Sh"
# Parse options
PARSED=$(getopt --options ${SHORT_OPTS} --longoptions "${LONG_OPTS}" --name "$0" -- "$@")
if [ $? -ne 0 ]; then
  exit 2
fi
eval set -- "${PARSED}"

# Default action if no arguments are provided
if [ -z "$1" ]; then
  echo "No arguments provided"
  show_help
  exit 1
fi

# Functions
fn_select() {
  # Get default workflow icon
  default_icon=$(get_hyprConf "WORKFLOW_ICON" "${workflows_dir}/default.conf")
  default_icon=${default_icon:0:1}

  # Find workflows and get icons in one pass
  workflow_list="${default_icon}\t default"
  while IFS= read -r workflow_path; do
    # Sanitize workflow name by removing any leading/trailing whitespace
    workflow_name=$(basename "$workflow_path" .conf | xargs)
    [ "$workflow_name" = "default" ] && continue
    workflow_icon=$(get_hyprConf "WORKFLOW_ICON" "$workflow_path")
    workflow_icon=${workflow_icon:0:1}
    workflow_list="${workflow_list}\n${workflow_icon}\t ${workflow_name}"
  done < <(find "$workflows_dir" -follow -type f -name "*.conf" 2>/dev/null)

  # Set rofi scaling
  font_scale="${ROFI_WORKFLOW_SCALE}"
  [[ "${font_scale}" =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}

  # Set font name
  font_name=${ROFI_WORKFLOW_FONT:-$ROFI_FONT}
  font_name=${font_name:-$(get_hyprConf "MENU_FONT")}
  font_name=${font_name:-$(get_hyprConf "FONT")}

  # Set rofi font override
  font_override="* {font: \"${font_name:-\"JetBrainsMono Nerd Font\"} ${font_scale}\";}"

  # Window and element styling
  hypr_border=${hypr_border:-"$(hyprctl -j getoption decoration:rounding | jq '.int')"}
  wind_border=$((hypr_border * 3 / 2))
  elem_border=$((hypr_border == 0 ? 5 : hypr_border))
  hypr_width=${hypr_width:-"$(hyprctl -j getoption general:border_size | jq '.int')"}
  r_override="window{border:${hypr_width}px;border-radius:${wind_border}px;} wallbox{border-radius:${elem_border}px;} element{border-radius:${elem_border}px;}"

  rofi_select="${HYPR_WORKFLOW/default/default}"

  # Display options using Rofi with custom scaling, positioning, and placeholder
  selected_workflow=$(echo -e "${workflow_list}" |
    rofi -dmenu -i -select "$rofi_select" \
      -p "Select workflow" \
      -theme-str "entry { placeholder: \"💼 Select workflow...\"; }" \
      -theme-str "${font_override}" \
      -theme-str "${r_override}" \
      -theme-str "$(get_rofi_pos)" \
      -theme "clipboard")

  # Exit if no selection was made
  if [ -z "$selected_workflow" ]; then
    exit 0
  fi

  # Extract the workflow name (remove the icon and tab)
  selected_workflow=$(awk -F'\t' '{print $2}' <<<"${selected_workflow}" | xargs)
  set_conf "HYPR_WORKFLOW" "$selected_workflow"
  fn_update
}

get_info() {

  [ -f "$HYDE_STATE_HOME/config" ] && source "$HYDE_STATE_HOME/config"
  [ -f "$HYDE_STATE_HOME/staterc" ] && source "$HYDE_STATE_HOME/staterc"
  current_workflow=${HYPR_WORKFLOW:-"default"}

  current_icon=$(get_hyprConf "WORKFLOW_ICON" "${workflows_dir}/${current_workflow}.conf")
  current_icon=${current_icon:0:1}
  current_description=$(get_hyprConf "WORKFLOW_DESCRIPTION" "${workflows_dir}/${current_workflow}.conf")
  current_description=${current_description:-"No description available"}
  export current_icon current_workflow current_description
}

fn_update() {
  get_info
  cat <<EOF >"${confDir}/hypr/workflows.conf"
#! █░█░█ █▀█ █▀█ █▄▀ █▀▀ █░░ █▀█ █░█░█ █▀
#! ▀▄▀▄▀ █▄█ █▀▄ █░█ █▀░ █▄▄ █▄█ ▀▄▀▄▀ ▄█


#*┌────────────────────────────────────────────────────────────────────────────┐
#*│ # HyDE Controlled content // DO NOT EDIT                                   │
#*│ # This file sets the current workflow for Hyprland                         │
#*│ # Edit or add workflows in the ./workflows/ directory                      │
#*│ # and run the 'workflows.sh --select' command to update this file          │
#*│                                                                            │
#*│ #  Workflows are a set of configurations that can be applied to Hyprland   │
#*│ #   that suits the actual workflow you are doing.                          │
#*│ # It can be gaming mode, work mode, or anything else you can think of.     │
#*│ # you can also exec a command within the workflow                          │
#*│                                                                            │
#*└────────────────────────────────────────────────────────────────────────────┘

\$WORKFLOW = ${current_workflow}
\$WORKFLOW_ICON = ${current_icon}
\$WORKFLOW_DESCRIPTION = ${current_description}
\$WORKFLOWS_PATH = ./workflows/${current_workflow}.conf
source = \$WORKFLOWS_PATH

EOF

  printf "%s %s: %s\n" "$current_icon" "$current_workflow" "$current_description"
  notify-send -r 9 -i "preferences-desktop-display" "Workflow: ${current_icon} $current_workflow" "${current_description}"

}

handle_waybar() {
  get_info
  text="$current_icon"
  tooltip="Mode: ${current_icon} ${current_workflow} \n${current_description}"
  class="custom-workflows"

  echo "{\"text\": \"${text}\", \"tooltip\": \"${tooltip}\", \"class\": \"${class}\"}"

}

# Process options
while true; do
  case "$1" in
  -S | --select)
    fn_select
    # refresh waybar module only if waybar is running
    if pgrep -x waybar >/dev/null; then
      pkill -RTMIN+7 waybar
    fi

    exit 0
    ;;
  --set)
    if [ -z "$2" ]; then
      echo "Error: --set requires a workflow name"
      exit 1
    fi
    set_conf "HYPR_WORKFLOW" "$2"
    fn_update
    # refresh waybar module only if waybar is running
    if pgrep -x waybar >/dev/null; then
      pkill -RTMIN+7 waybar
    fi

    exit 0
    ;;
  --help | -h)
    show_help
    exit 0
    ;;
  --waybar)
    handle_waybar
    exit 0
    ;;
  --)
    shift
    break
    ;;
  *)
    echo "Invalid option: $1"
    show_help
    exit 1
    ;;
  esac
done
