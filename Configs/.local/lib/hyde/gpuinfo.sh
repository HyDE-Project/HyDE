#!/usr/bin/env bash
scrDir=$(dirname "$(realpath "$0")")
gpuinfo_file="/tmp/hyde-$UID-gpuinfo"
AQ_DRM_DEVICES="${AQ_DRM_DEVICES:-WLR_DRM_DEVICES}"
tired=false
if [[ " $* " =~ " --tired " ]]; then
    if ! grep -q "tired" "$gpuinfo_file"; then
        echo "tired=true" >>"$gpuinfo_file"
        echo "set tired flag"
    else
        echo "already set tired flag"
    fi
    echo "Nvidia GPU will not be queried if it is in suspend mode"
    echo "run --reset to reset the flag"
    exit 0
fi
if [[ " $* " =~ " --emoji " ]]; then
    if ! grep -q "GPUINFO_EMOJI" "$gpuinfo_file"; then
        echo "export GPUINFO_EMOJI=1" >>"$gpuinfo_file"
        echo "set emoji flag"
    else
        echo "already set emoji flag"
    fi
    echo "run --reset to reset the flag"
    exit 0
fi
if [[ ! " $* " =~ " --startup " ]]; then
    gpuinfo_file="$gpuinfo_file$2"
fi
detect() {
    card=$(echo "$AQ_DRM_DEVICES" | cut -d':' -f1 | cut -d'/' -f4)
    slot_number=$(ls -l /dev/dri/by-path/ | grep "$card" | awk -F'pci-0000:|-card' '{print $2}')
    vendor_id=$(lspci -nn -s "$slot_number")
    declare -A vendors=(["10de"]="nvidia" ["8086"]="intel" ["1002"]="amd")
    for vendor in "${!vendors[@]}"; do
        if [[ $vendor_id == *"$vendor"* ]]; then
            initGPU="${vendors[$vendor]}"
            break
        fi
    done
    if [[ -n $initGPU ]]; then
        $0 --use "$initGPU" --startup
    fi
}
query() {
    GPUINFO_NVIDIA_ENABLE=0 GPUINFO_AMD_ENABLE=0 GPUINFO_INTEL_ENABLE=0
    touch "$gpuinfo_file"
    if lsmod | grep -q 'nouveau'; then
        echo 'GPUINFO_NVIDIA_GPU="Linux"' >>"$gpuinfo_file"
        echo "GPUINFO_NVIDIA_ENABLE=1 # Using nouveau an open-source nvidia driver" >>"$gpuinfo_file"
    elif command -v nvidia-smi &>/dev/null; then
        GPUINFO_NVIDIA_GPU=$(nvidia-smi --query-gpu=gpu_name --format=csv,noheader,nounits | head -n 1)
        if [[ -n $GPUINFO_NVIDIA_GPU ]]; then
            if [[ $GPUINFO_NVIDIA_GPU == *"NVIDIA-SMI has failed"* ]]; then
                echo "GPUINFO_NVIDIA_ENABLE=0 # NVIDIA-SMI has failed" >>"$gpuinfo_file"
            else
                NVIDIA_ADDR=$(lspci | grep -Ei "VGA|3D" | grep -i "${GPUINFO_NVIDIA_GPU/NVIDIA /}" | cut -d' ' -f1)
                {
                    echo "NVIDIA_ADDR=\"$NVIDIA_ADDR\""
                    echo "GPUINFO_NVIDIA_GPU=\"${GPUINFO_NVIDIA_GPU/NVIDIA /}\""
                    echo "GPUINFO_NVIDIA_ENABLE=1"
                } >>"$gpuinfo_file"
            fi
        fi
    fi
    if lspci -nn | grep -E "(VGA|3D)" | grep -iq "1002"; then
        GPUINFO_AMD_GPU="$(lspci -nn | grep -Ei "VGA|3D" | grep -m 1 "1002" | awk -F'Advanced Micro Devices, Inc. ' '{gsub(/ *\[[^\]]*\]/,""); gsub(/ *\([^)]*\)/,""); print $2}')"
        AMD_ADDR=$(lspci | grep -Ei "VGA|3D" | grep -i "$GPUINFO_AMD_GPU" | cut -d' ' -f1)
        {
            echo "AMD_ADDR=\"$AMD_ADDR\""
            echo "GPUINFO_AMD_ENABLE=1"
            echo "GPUINFO_AMD_GPU=\"$GPUINFO_AMD_GPU\""
        } >>"$gpuinfo_file"
    fi
    if lspci -nn | grep -E "(VGA|3D)" | grep -iq "8086"; then
        GPUINFO_INTEL_GPU="$(lspci -nn | grep -Ei "VGA|3D" | grep -m 1 "8086" | awk -F'Intel Corporation ' '{gsub(/ *\[[^\]]*\]/,""); gsub(/ *\([^)]*\)/,""); print $2}')"
        INTEL_ADDR=$(lspci | grep -Ei "VGA|3D" | grep -i "$GPUINFO_INTEL_GPU" | cut -d' ' -f1)
        {
            echo "INTEL_ADDR=\"$INTEL_ADDR\""
            echo "GPUINFO_INTEL_ENABLE=1"
            echo "GPUINFO_INTEL_GPU=\"$GPUINFO_INTEL_GPU\""
        } >>"$gpuinfo_file"
    fi
    if ! grep -q "GPUINFO_PRIORITY=" "$gpuinfo_file" && [[ -n $AQ_DRM_DEVICES ]]; then
        trap detect EXIT
    fi
}
toggle() {
    if [[ -n $1 ]]; then
        NEXT_PRIORITY="GPUINFO_${1^^}_ENABLE"
        if ! grep -q "$NEXT_PRIORITY=1" "$gpuinfo_file"; then
            echo Error: "$NEXT_PRIORITY" not found in "$gpuinfo_file"
        fi
    else
        if ! grep -q "GPUINFO_AVAILABLE=" "$gpuinfo_file"; then
            GPUINFO_AVAILABLE=$(grep "_ENABLE=1" "$gpuinfo_file" | cut -d '=' -f 1 | tr '\n' ' ' | tr -d '#')
            echo "" >>"$gpuinfo_file"
            echo "GPUINFO_AVAILABLE=\"${GPUINFO_AVAILABLE[*]}\"" >>"$gpuinfo_file"
        fi
        if ! grep -q "GPUINFO_PRIORITY=" "$gpuinfo_file"; then
            GPUINFO_AVAILABLE=$(grep "GPUINFO_AVAILABLE=" "$gpuinfo_file" | cut -d'=' -f 2)
            initGPU=$(echo "$GPUINFO_AVAILABLE" | cut -d ' ' -f 1)
            echo "GPUINFO_PRIORITY=$initGPU" >>"$gpuinfo_file"
        fi
        mapfile -t anchor < <(grep "_ENABLE=1" "$gpuinfo_file" | cut -d '=' -f 1)
        GPUINFO_PRIORITY=$(grep "GPUINFO_PRIORITY=" "$gpuinfo_file" | cut -d'=' -f 2)
        for index in "${!anchor[@]}"; do
            if [[ ${anchor[$index]} == "$GPUINFO_PRIORITY" ]]; then
                current_index=$index
            fi
        done
        next_index=$(((current_index + 1) % ${#anchor[@]}))
        NEXT_PRIORITY=${anchor[$next_index]#\#}
    fi
    sed -i 's/^\(GPUINFO_NVIDIA_ENABLE=1\|GPUINFO_AMD_ENABLE=1\|GPUINFO_INTEL_ENABLE=1\)/#\1/' "$gpuinfo_file"
    sed -i "s/^#$NEXT_PRIORITY/$NEXT_PRIORITY/" "$gpuinfo_file"
    sed -i "s/GPUINFO_PRIORITY=$GPUINFO_PRIORITY/GPUINFO_PRIORITY=$NEXT_PRIORITY/" "$gpuinfo_file"
}
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

generate_json() {
    if [[ $GPUINFO_EMOJI -ne 1 ]]; then
        temp_lv="85:, 65:, 45:☁, ❄"
    else
        temp_lv="85:🌋, 65:🔥, 45:☁️, ❄️"
    fi
    util_lv="90:, 60:󰓅, 30:󰾅, 󰾆"
    icons="$(map_floor "$util_lv" "$utilization")$(map_floor "$temp_lv" "$temperature")"
    speedo=${icons:0:1}
    thermo=${icons:1:1}
    emoji=${icons:2}
    # Compute classes and percentage (5°C buckets for temp, 10% for util)
    local temp_val=${temperature%%.*}
    ((temp_val < 0)) && temp_val=0
    ((temp_val > 999)) && temp_val=999
    local temp_bucket=$(((temp_val / 5) * 5))
    ((temp_bucket > 100)) && temp_bucket=100
    local temp_class="temp-$temp_bucket"

    local util_val=${utilization%.*}
    ((${util_val:-0} < 0)) && util_val=0
    ((${util_val:-0} > 100)) && util_val=100
    local util_bucket=$(((util_val / 10) * 10))
    local util_class="util-$util_bucket"

    local temp_pct=$temp_val
    ((temp_pct > 100)) && temp_pct=100

    local json="{\"text\":\"$thermo $temperature°C\", \"tooltip\":\"$emoji $primary_gpu\n$thermo Temperature: $temperature°C"
    declare -A tooltip_parts
    if [[ -n $utilization ]]; then tooltip_parts["\n$speedo Utilization: "]="$utilization%"; fi
    if [[ -n $current_clock_speed ]] && [[ -n $max_clock_speed ]]; then tooltip_parts["\n Clock Speed: "]="$current_clock_speed/$max_clock_speed MHz"; fi
    if [[ -n $core_clock ]]; then tooltip_parts["\n Clock Speed: "]="$core_clock MHz"; fi
    if [[ -n $power_usage ]]; then
        if [[ -n $power_limit ]]; then
            tooltip_parts["\n󱪉 Power Usage: "]="$power_usage/$power_limit W"
        else
            tooltip_parts["\n󱪉 Power Usage: "]="$power_usage W"
        fi
    fi
    if [[ -n $power_discharge ]] && [[ $power_discharge != "0" ]]; then tooltip_parts["\n Power Discharge: "]="$power_discharge W"; fi
    if [[ -n $fan_speed ]]; then tooltip_parts["\n Fan Speed: "]="$fan_speed RPM"; fi
    for key in "${!tooltip_parts[@]}"; do
        local value="${tooltip_parts[$key]}"
        if [[ -n $value && $value =~ [a-zA-Z0-9] ]]; then
            json+="$key$value"
        fi
    done
    json="$json\", \"class\":[\"$temp_class\",\"$util_class\"], \"percentage\":$temp_pct, \"alt\":\"$temp_bucket\"}"
    echo "$json"
}
general_query() {
    filter=''
    sensors_data=$(sensors 2>/dev/null)
    temperature=$(echo "$sensors_data" | $filter grep -m 1 -E "(edge|Package id.*|another keyword)" | awk -F ':' '{print int($2)}')
    fan_speed=$(echo "$sensors_data" | $filter grep -m 1 -E "fan[1-9]" | awk -F ':' '{print int($2)}')
    for file in /sys/class/power_supply/BAT*/power_now; do
        [[ -f $file ]] && power_discharge=$(awk '{print $1*10^-6 ""}' "$file") && break
    done
    [[ -z $power_discharge ]] && for file in /sys/class/power_supply/BAT*/current_now; do
        [[ -e $file ]] && power_discharge=$(awk -v current="$(cat "$file")" -v voltage="$(cat "${file/current_now/voltage_now}")" 'BEGIN {print (current * voltage) / 10^12 ""}') && break
    done
    get_utilization() {
        statFile=$(head -1 /proc/stat)
        if [[ -z $GPUINFO_PREV_STAT ]]; then
            GPUINFO_PREV_STAT=$(awk '{print $2+$3+$4+$6+$7+$8 }' <<<"$statFile")
            echo "GPUINFO_PREV_STAT=\"$GPUINFO_PREV_STAT\"" >>"$gpuinfo_file"
        fi
        if [[ -z $GPUINFO_PREV_IDLE ]]; then
            GPUINFO_PREV_IDLE=$(awk '{print $5 }' <<<"$statFile")
            echo "GPUINFO_PREV_IDLE=\"$GPUINFO_PREV_IDLE\"" >>"$gpuinfo_file"
        fi
        currStat=$(awk '{print $2+$3+$4+$6+$7+$8 }' <<<"$statFile")
        currIdle=$(awk '{print $5 }' <<<"$statFile")
        diffStat=$((currStat - GPUINFO_PREV_STAT))
        diffIdle=$((currIdle - GPUINFO_PREV_IDLE))
        GPUINFO_PREV_STAT=$currStat
        GPUINFO_PREV_IDLE=$currIdle
        sed -i -e "/^GPUINFO_PREV_STAT=/c\GPUINFO_PREV_STAT=\"$currStat\"" -e "/^GPUINFO_PREV_IDLE=/c\GPUINFO_PREV_IDLE=\"$currIdle\"" "$gpuinfo_file" || {
            echo "GPUINFO_PREV_STAT=\"$currStat\"" >>"$cpuinfo_file"
            echo "GPUINFO_PREV_IDLE=\"$currIdle\"" >>"$cpuinfo_file"
        }
        awk -v stat="$diffStat" -v idle="$diffIdle" 'BEGIN {printf "%.1f", (stat/(stat+idle))*100}'
    }
    utilization=$(get_utilization)
    current_clock_speed=$(awk '{sum += $1; n++} END {if (n > 0) print sum / n / 1000 ""}' /sys/devices/system/cpu/cpufreq/policy*/scaling_cur_freq)
    max_clock_speed=$(awk '{print $1/1000}' /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)
}
intel_GPU() {
    primary_gpu="Intel $GPUINFO_INTEL_GPU"
    general_query
}
nvidia_GPU() {
    primary_gpu="NVIDIA $GPUINFO_NVIDIA_GPU"
    if [[ $GPUINFO_NVIDIA_GPU == "Linux" ]]; then
        general_query
        return
    fi
    if $tired; then
        is_suspend="$(cat /sys/bus/pci/devices/0000:"$NVIDIA_ADDR"/power/runtime_status)"
        if [[ $is_suspend == *"suspend"* ]]; then
            printf '{"text":"󰤂", "tooltip":"%s ⏾ Suspended mode"}' "$primary_gpu"
            exit
        fi
    fi
    gpu_info=$(nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,clocks.current.graphics,clocks.max.graphics,power.draw,power.limit --format=csv,noheader,nounits)
    IFS=',' read -ra gpu_data <<<"$gpu_info"
    temperature="${gpu_data[0]// /}"
    utilization="${gpu_data[1]// /}"
    current_clock_speed="${gpu_data[2]// /}"
    max_clock_speed="${gpu_data[3]// /}"
    power_usage="${gpu_data[4]// /}"
    power_limit="${gpu_data[5]// /}"
}
amd_GPU() {
    primary_gpu="AMD $GPUINFO_AMD_GPU"
    amd_output=$(python3 $scrDir/amdgpu.py)
    if [[ $amd_output != *"No AMD GPUs detected."* ]] && [[ $amd_output != *"Unknown query failure"* ]]; then
        temperature=$(echo "$amd_output" | jq -r '.["GPU Temperature"]' | sed 's/°C//')
        utilization=$(echo "$amd_output" | jq -r '.["GPU Load"]' | sed 's/%//')
        core_clock=$(echo "$amd_output" | jq -r '.["GPU Core Clock"]' | sed 's/ GHz//;s/ MHz//')
        power_usage=$(echo "$amd_output" | jq -r '.["GPU Power Usage"]' | sed 's/ Watts//')
    else
        general_query
    fi
}
if [[ ! -f $gpuinfo_file ]]; then
    query
    echo -e "Initialized Variable:\n$(cat "$gpuinfo_file")\n\nReboot or '$0 --reset' to RESET Variables"
fi
source "$gpuinfo_file"
case "$1" in
"--toggle" | "-t")
    toggle
    echo -e "Sensor: $NEXT_PRIORITY GPU" | sed 's/_ENABLE//g'
    exit
    ;;
"--use" | "-u")
    toggle "$2"
    ;;
"--reset" | "-rf")
    rm -fr "$gpuinfo_file"*
    query
    echo -e "Initialized Variable:\n$(cat "$gpuinfo_file" || true)\n\nReboot or '$0 --reset' to RESET Variables"
    exit
    ;;
"--stat")
    case "$2" in
    "amd")
        if
            [[ $GPUINFO_AMD_ENABLE -eq 1 ]]
        then
            echo "GPUINFO_AMD_ENABLE: $GPUINFO_AMD_ENABLE"
            exit 0
        fi
        ;;
    "intel")
        if
            [[ $GPUINFO_INTEL_ENABLE -eq 1 ]]
        then
            echo "GPUINFO_INTEL_ENABLE: $GPUINFO_INTEL_ENABLE"
            exit 0
        fi
        ;;
    "nvidia")
        if
            [[ $GPUINFO_NVIDIA_ENABLE -eq 1 ]]
        then
            echo "GPUINFO_NVIDIA_ENABLE: $GPUINFO_NVIDIA_ENABLE"
            exit 0
        fi
        ;;
    *)
        echo "Error: Invalid argument for --stat. Use amd, intel, or nvidia."
        exit 1
        ;;
    esac
    echo "GPU not enabled."
    exit 1
    ;;
*"-"*)
    GPUINFO_AVAILABLE=${GPUINFO_AVAILABLE//GPUINFO_/}
    cat <<EOF
  Available GPU: ${GPUINFO_AVAILABLE//_ENABLE/}
[options]
--toggle         * Toggle available GPU
--use [GPU]      * Only call the specified GPU (Useful for adding specific GPU on waybar)
--reset          *  Remove & restart all query

[flags]
--tired            * Adding this option will not query nvidia-smi if gpu is in suspend mode
--startup          * Useful if you want a certain GPU to be set at startup
--emoji            * Use Emoji instead of Glyphs

* If $USER declared env = AQ_DRM_DEVICES on hyprland then use this as the primary GPU
EOF
    exit
    ;;
esac
GPUINFO_NVIDIA_ENABLE=${GPUINFO_NVIDIA_ENABLE:-0} GPUINFO_INTEL_ENABLE=${GPUINFO_INTEL_ENABLE:-0} GPUINFO_AMD_ENABLE=${GPUINFO_AMD_ENABLE:-0}
if [[ $GPUINFO_NVIDIA_ENABLE -eq 1 ]]; then
    nvidia_GPU
elif [[ $GPUINFO_AMD_ENABLE -eq 1 ]]; then
    amd_GPU
elif [[ $GPUINFO_INTEL_ENABLE -eq 1 ]]; then
    intel_GPU
else
    primary_gpu="Not found"
    general_query
fi
generate_json
