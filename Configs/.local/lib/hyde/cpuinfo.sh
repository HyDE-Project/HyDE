#!/bin/bash
map_floor() {
    IFS=', ' read -r -a pairs <<<"$1"
    if [[ ${pairs[-1]} != *":"* ]]; then
        def_val="${pairs[-1]}"
        unset 'pairs[${#pairs[@]}-1]'
    fi
    for pair in "${pairs[@]}"; do
        IFS=':' read -r key value <<<"$pair"
        num="${2%%.*}"
        if [[ $num =~ ^-?[0-9]+$ && $key =~ ^-?[0-9]+$ ]]; then
            if ((num > key)); then
                echo "$value"
                return
            fi
        elif [[ -n $num && -n $key && $num > $key ]]; then
            echo "$value"
            return
        fi
    done
    [ -n "$def_val" ] && echo $def_val || echo " "
}
init_query() {
    cpu_info_file="/tmp/hyde-$UID-processors"
    [[ -f $cpu_info_file ]] && source "$cpu_info_file"
    if [[ -z $CPUINFO_MODEL ]]; then
        CPUINFO_MODEL=$(lscpu | awk -F': ' '/Model name/ {gsub(/^ *| *$| CPU.*/,"",$2); print $2}')
        echo "CPUINFO_MODEL=\"$CPUINFO_MODEL\"" >>"$cpu_info_file"
    fi
    if [[ -z $CPUINFO_MAX_FREQ ]]; then
        CPUINFO_MAX_FREQ=$(lscpu | awk '/CPU max MHz/ { sub(/\..*/,"",$4); print $4}')
        echo "CPUINFO_MAX_FREQ=\"$CPUINFO_MAX_FREQ\"" >>"$cpu_info_file"
    fi
    statFile=$(head -1 /proc/stat)
    if [[ -z $CPUINFO_PREV_STAT ]]; then
        CPUINFO_PREV_STAT=$(awk '{print $2+$3+$4+$6+$7+$8 }' <<<"$statFile")
        echo "CPUINFO_PREV_STAT=\"$CPUINFO_PREV_STAT\"" >>"$cpu_info_file"
    fi
    if [[ -z $CPUINFO_PREV_IDLE ]]; then
        CPUINFO_PREV_IDLE=$(awk '{print $5 }' <<<"$statFile")
        echo "CPUINFO_PREV_IDLE=\"$CPUINFO_PREV_IDLE\"" >>"$cpu_info_file"
    fi
}
get_temp_color() {
    local temp=$1
    declare -A temp_colors=(
        [90]="#8b0000"
        [85]="#ad1f2f"
        [80]="#d22f2f"
        [75]="#ff471a"
        [70]="#ff6347"
        [65]="#ff8c00"
        [60]="#ffa500"
        [45]=""
        [40]="#add8e6"
        [35]="#87ceeb"
        [30]="#4682b4"
        [25]="#4169e1"
        [20]="#0000ff"
        [0]="#00008b")
    for threshold in $(echo "${!temp_colors[@]}" | tr ' ' '\n' | sort -nr); do
        if ((temp >= threshold)); then
            color=${temp_colors[$threshold]}
            if [[ -n $color ]]; then
                echo "<span color='$color'><b>$temp°C</b></span>"
            else
                echo "$temp°C"
            fi
            return
        fi
    done
}
get_utilization() {
    local statFile currStat currIdle diffStat diffIdle utilization
    statFile=$(head -1 /proc/stat)
    currStat=$(awk '{print $2+$3+$4+$6+$7+$8 }' <<<"$statFile")
    currIdle=$(awk '{print $5 }' <<<"$statFile")
    diffStat=$((currStat - CPUINFO_PREV_STAT))
    diffIdle=$((currIdle - CPUINFO_PREV_IDLE))
    CPUINFO_PREV_STAT=$currStat
    CPUINFO_PREV_IDLE=$currIdle
    sed -i -e "/^CPUINFO_PREV_STAT=/c\CPUINFO_PREV_STAT=\"$currStat\"" -e "/^CPUINFO_PREV_IDLE=/c\CPUINFO_PREV_IDLE=\"$currIdle\"" "$cpuinfo_file" || {
        echo "CPUINFO_PREV_STAT=\"$currStat\"" >>"$cpuinfo_file"
        echo "CPUINFO_PREV_IDLE=\"$currIdle\"" >>"$cpuinfo_file"
    }
    awk -v stat="$diffStat" -v idle="$diffIdle" 'BEGIN {printf "%.1f", (stat/(stat+idle))*100}'
}
cpuinfo_file="/tmp/hyde-$UID-processors"
source "$cpuinfo_file"
init_query
if [[ $CPUINFO_EMOJI -ne 1 ]]; then
    temp_lv="85:, 65:, 45:☁, ❄"
else
    temp_lv="85:🌋, 65:🔥, 45:☁️, ❄️"
fi
util_lv="90:, 60:󰓅, 30:󰾅, 󰾆"
sensors_json=$(sensors -j 2>/dev/null)
cpu_temps="$(jq -r '[
.["coretemp-isa-0000"], 
.["k10temp-pci-00c3"]
] | 
map(select(. != null)) | 
map(to_entries) | 
add | 
map(select(.value | 
objects) | 
"\(.key): \((.value | 
to_entries[] | 
select(.key | 
test("temp[0-9]+_input")) | 
.value | floor))°C") | 
join("\\n\t")' <<<"$sensors_json")"
if [ -n "$CPUINFO_TEMPERATURE_ID" ]; then
    temperature=$(grep -oP "(?<=$CPUINFO_TEMPERATURE_ID: )\d+" <<<"$cpu_temps")
fi
if [[ -z $temperature ]]; then
    cpu_temp_line="${cpu_temps%%$'°C'*}"
    temperature="${cpu_temp_line#*: }"
fi
utilization=$(get_utilization)
frequency=$(perl -ne 'BEGIN { $sum = 0; $count = 0 } if (/cpu MHz\s+:\s+([\d.]+)/) { $sum += $1; $count++ } END { if ($count > 0) { printf "%.2f\n", $sum / $count } else { print "NaN\n" } }' /proc/cpuinfo)
icons="$(map_floor "$util_lv" "$utilization")$(map_floor "$temp_lv" "$temperature")"
speedo="${icons:0:1}"
thermo="${icons:1:1}"
emoji="${icons:2}"
tooltip_str="$emoji $CPUINFO_MODEL\n"
[[ -n $thermo ]] && tooltip_str+="$thermo Temperature: \n\t$cpu_temps \n"
[[ -n $speedo ]] && tooltip_str+="$speedo Utilization: $utilization%\n"
tooltip_str+=" Clock Speed: $frequency/$CPUINFO_MAX_FREQ MHz"
cat <<JSON
{"text":"$thermo $(get_temp_color "$temperature")", "tooltip":"$tooltip_str"}
JSON
