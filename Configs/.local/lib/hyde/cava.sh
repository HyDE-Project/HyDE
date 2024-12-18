#!/bin/env bash
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


stdout () {
temp_dir=${HYDE_RUNTIME_DIR:-/tmp}
local config_file="${temp_dir}/bar_cava_config"



usage() {
    cat <<HELP
Usage: $(basename "$0") [OPTIONS]
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

# // cava_stbmode - standby mode for stdout cava - default 0
# 0: clean - totally hides the module
# 1: blank - makes module expand as spaces
# 2: full - occupies the module with full bar
# 3: low - makes the module display the lowest set bar
# <string>: - displays a string
case ${cava_stbmode:-} in
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
stbAscii=$(printf '0%.0s' $(seq 1 "${bar_width}")) # predicts the amount of ancii characters to be used
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
    stdout "$@"
    ;;
*)  
    help_msg
    ;;
esac    