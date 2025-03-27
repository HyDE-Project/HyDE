#!/usr/bin/env bash
#----- Optimized bars animation without much CPU usage increase --------
#----- Optimized bars animation without much CPU usage increase pt2 --------

# Default values
scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"

help_msg() {
    cat <<HELP
Usage: $(basename "$0") [command] [OPTIONS]
Commands:
    stdout - Generate a cava bar to STDOUT useful for waybar, hyprlock, etc.
    waybar - Generate a cava bar for waybar.
    hyprlock - Generate a cava bar for hyprlock.

    Note: Configurations are set in ~/.config/hyde/config.toml

Options:
    stdout:
            --bar <cava_bar>  Specify the characters to use for the bar animation (default: ▁▂▃▄▅▆▇█).
            --width <cava_width>   Specify the width of the bar.
            --range <cava_range>   Specify the range of the bar.
            --help                        Display this help message and exit.
            --restart                     Restart the cava.
            --stb <cava_stbmode>  Specify the standby mode for stdout cava (default: 0).
                                        0: clean  - totally hides the module
                                        1: blank  - makes module expand as spaces
                                        2: full   - occupies the module with full bar
                                        3: low    - makes the module display the lowest set bar
                                        *: string - displays a string
HELP
}

stdout() {
    local temp_dir=${HYDE_RUNTIME_DIR:-/tmp}
    local name="${cava_cmd:-"stdout"}"
    local config_file="${temp_dir}/cava.${name}"

    usage() {
        cat <<HELP
Usage: $(basename "$0") "${cava_cmd}" [OPTIONS]
Options:
  --bar <cava_bar>  Specify the characters to use for the bar animation (default: ▁▂▃▄▅▆▇█).
  --width <cava_width>   Specify the width of the bar.
  --range <cava_range>   Specify the range of the bar.
  --help                        Display this help message and exit.
  --restart                     Restart the cava.
  --stb <cava_stbmode>  Specify the standby mode for stdout cava (default: 0).
                                0: clean  - totally hides the module
                                1: blank  - makes module expand as spaces
                                2: full   - occupies the module with full bar
                                3: low    - makes the module display the lowest set bar
                                *: string - displays a string
HELP
        exit 1
    }

    # Parse command line arguments using getopt
    if ! ARGS=$(getopt -o "hr" -l "help,bar:,width:,range:,restart,stb:" -n "$0" -- "$@"); then
        usage
    fi

    eval set -- "$ARGS"
    while true; do
        case "$1" in
        --help | -h)
            usage
            ;;
        --bar)
            cava_bar="$2"
            shift 2
            ;;
        --width)
            cava_width="$2"
            shift 2
            ;;
        --range)
            cava_range="$2"
            shift 2
            ;;
        --restart) # restart by killing all cava
            pkill -f "cava -p ${config_file}"
            exit 0
            ;;
        --stb)
            cava_stbmode="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            usage
            ;;
        esac
    done

    bar="${cava_bar:-▁▂▃▄▅▆▇█}"

    max_instances=${max_instances:-$CAVA_STDOUT_MAX_INSTANCES}
    max_instances=${max_instances:-1}

    if [ "$(pgrep -c -f "cava -p ${config_file}")" -ge "${max_instances}" ]; then
        echo "Cava reached max instances, restarting cava"
        notify-send "Cava reached max instances, restarting cava... update the config file to increase the max instances"
        pkill -o -f "cava -p ${config_file}" # kill the oldest instance
    fi

    # // cava_stbmode - standby mode for stdout cava - default 0
    # 0: clean - totally hides the module
    # 1: blank - makes module expand as spaces
    # 2: full - occupies the module with full bar
    # 3: low - makes the module display the lowest set bar
    # <string>: - displays a string
    case ${cava_stbmode:-0} in
    0)
        stbBar=''
        ;; # Clean
    1)
        stbBar="‎ "
        ;; # Invisible char
    2)
        stbBar="${bar: -1}"
        ;; # Full bar
    3)
        stbBar="${bar:0:1}"
        ;; # Lowest bar
    *)
        asciiBar="${cava_stbmode:-${bar}}"
        ;;
    esac

    # Calculate the length of the bar outside the loop
    bar_length=${#bar}
    bar_width=${cava_width:-${bar_length}}
    bar_range=${cava_range:-$((bar_length - 1))}
    # Create dictionary to replace char with bar
    dict="s/;//g"
    stbAscii=$(printf '0%.0s' $(seq 1 "${bar_width}")) # predicts the amount of ascii characters to be used
    [ -n "${asciiBar}" ] || asciiBar="${stbAscii//0/${stbBar}}"

    dict="$dict;s/${stbAscii}/${asciiBar}/g"
    i=0
    while [ $i -lt "${bar_length}" ] || [ $i -lt "${bar_width}" ]; do
        if [ $i -lt "${bar_length}" ]; then
            dict="$dict;s/$i/${bar:$i:1}/g"
        fi
        ((i++))
    done

    # Create cava config
    cat >"$config_file" <<EOF
[general]
bars = ${bar_width}
sleep_timer = 1
[input]
method = pulse
source = auto
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = ${bar_range}
EOF

    cava -p "$config_file" | sed -u "${dict}"
}

case $1 in
stdout)
    shift
    cava_cmd="stdout"
    cava_bar="$CAVA_STDOUT_BAR" cava_width="$CAVA_STDOUT_WIDTH" cava_range="$CAVA_STDOUT_RANGE" cava_stbmode="$CAVA_STDOUT_STANDBY"
    stdout "$@"
    ;;
waybar)
    shift
    cava_cmd="waybar"
    cava_bar="$CAVA_WAYBAR_BAR" cava_width="$CAVA_WAYBAR_WIDTH" cava_range="$CAVA_WAYBAR_RANGE" cava_stbmode="$CAVA_WAYBAR_STANDBY"
    stdout "$@"
    ;;
hyprlock)
    shift
    cava_cmd="hyprlock"
    cava_bar="$CAVA_HYPRLOCK_BAR" cava_width="$CAVA_HYPRLOCK_WIDTH" cava_range="$CAVA_HYPRLOCK_RANGE" cava_stbmode="$CAVA_HYPRLOCK_STANDBY"
    stdout "$@"
    ;;
*)
    help_msg
    ;;
esac
