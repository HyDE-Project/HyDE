#!/bin/bash
<<<<<<< HEAD
# From https://github.com/prasanthrangan/hyprdots/pull/952
# All credits to https://github.com/mislah
# Modified: The HyDE Project
#  Benchmark 1: cpuinfo.sh
#   Time (mean ± σ):     159.4 ms ±  26.1 ms    [User: 38.6 ms, System: 62.2 ms]
#   Range (min … max):    99.8 ms … 182.7 ms    17 runs
=======
# shellcheck disable=SC1090
cpuinfo_file="${XDG_RUNTIME_DIR:-/tmp}/hyde-$UID-processors"
>>>>>>> master

map_floor() {
    IFS=', ' read -r -a pairs <<<"$1"
    if [[ ${pairs[-1]} != *":"* ]]; then
        def_val="${pairs[-1]}"
<<<<<<< HEAD
        unset 'pairs[${#pairs[@]}-1]'
=======
        unset 'pairs[-1]'
>>>>>>> master
    fi
    for pair in "${pairs[@]}"; do
        IFS=':' read -r key value <<<"$pair"
        num="${2%%.*}"
<<<<<<< HEAD
        # if awk -v num="$2" -v k="$key" 'BEGIN { exit !(num > k) }'; then #! causes 50ms+ delay
        if [[ "$num" =~ ^-?[0-9]+$ && "$key" =~ ^-?[0-9]+$ ]]; then # TODO Faster than awk but I might be dumb so checks might be lacking
=======
        if [[ $num =~ ^-?[0-9]+$ && $key =~ ^-?[0-9]+$ ]]; then
>>>>>>> master
            if ((num > key)); then
                echo "$value"
                return
            fi
<<<<<<< HEAD
        elif [[ -n "$num" && -n "$key" && "$num" > "$key" ]]; then
=======
        elif [[ -n $num && -n $key && $num > $key ]]; then
>>>>>>> master
            echo "$value"
            return
        fi
    done
<<<<<<< HEAD
    [ -n "$def_val" ] && echo $def_val || echo " "
}

init_query() {
    cpu_info_file="/tmp/hyde-${UID}-processors"

    # Source the file to load existing variables
    [[ -f "${cpu_info_file}" ]] && source "${cpu_info_file}"

    # Get static CPU information
    if [[ -z "$CPUINFO_MODEL" ]]; then
        CPUINFO_MODEL=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^ *//' | sed 's/ CPU.*//')
        echo "CPUINFO_MODEL=\"$CPUINFO_MODEL\"" >>"${cpu_info_file}"
    fi

    if [[ -z "$CPUINFO_MAX_FREQ" ]]; then
        CPUINFO_MAX_FREQ=$(lscpu | awk '/CPU max MHz/ { sub(/\..*/,"",$4); print $4}')
        echo "CPUINFO_MAX_FREQ=\"$CPUINFO_MAX_FREQ\"" >>"${cpu_info_file}"
    fi

    # Get initial CPU stat
    statFile=$(head -1 /proc/stat)
    if [[ -z "$CPUINFO_PREV_STAT" ]]; then
        CPUINFO_PREV_STAT=$(awk '{print $2+$3+$4+$6+$7+$8 }' <<<"$statFile")
        echo "CPUINFO_PREV_STAT=\"$CPUINFO_PREV_STAT\"" >>"${cpu_info_file}"
    fi
    if [[ -z "$CPUINFO_PREV_IDLE" ]]; then
        CPUINFO_PREV_IDLE=$(awk '{print $5 }' <<<"$statFile")
        echo "CPUINFO_PREV_IDLE=\"$CPUINFO_PREV_IDLE\"" >>"${cpu_info_file}"
    fi
}

# Function to determine color based on temperature
get_temp_color() {
    local temp=$1
    declare -A temp_colors=(
        [90]="#8b0000" # Dark Red for 90 and above
        [85]="#ad1f2f" # Red for 85 to 89
        [80]="#d22f2f" # Light Red for 80 to 84
        [75]="#ff471a" # Orange-Red for 75 to 79
        [70]="#ff6347" # Tomato for 70 to 74
        [65]="#ff8c00" # Dark Orange for 65 to 69
        [60]="#ffa500" # Orange for 60 to 64
        [45]="#5fb0b8" # Bleu vert
        [40]="#add8e6" # Light Blue for 40 to 44
        [35]="#87ceeb" # Sky Blue for 35 to 39
        [30]="#4682b4" # Steel Blue for 30 to 34
        [25]="#4169e1" # Royal Blue for 25 to 29
        [20]="#0000ff" # Blue for 20 to 24
        [0]="#00008b"  # Dark Blue for below 20
    )

    for threshold in $(echo "${!temp_colors[@]}" | tr ' ' '\n' | sort -nr); do
        if ((temp >= threshold)); then
            color=${temp_colors[$threshold]}
            if [[ -n $color ]]; then
                echo "<span color='$color'><b>${temp}°C</b></span>"
            else
                echo "${temp}°C"
            fi
            return
        fi
    done
}

get_use_color() {
    local utilization=$1
    local utilization_int=${utilization%.*}  # Convertir en entier en supprimant la partie décimale
    declare -A util_colors=(
        [90]="#ff5555"  # Rouge vif (Dracula Red)
        [85]="#ff6e67"  # Rouge orangé
        [80]="#ff9248"  # Orange intense
        [75]="#ffb86c"  # Orange clair (Dracula Orange)
        [70]="#f1fa8c"  # Jaune vert (Dracula Yellow)
        [65]="#50fa7b"  # Vert vif (Dracula Green)
        [60]="#8be9fd"  # Cyan (Dracula Cyan)
        [55]="#79dac8"  # Turquoise
        [50]="#66cdaa"  # Vert bleuté
        [45]="#5fb0b8"  # Bleu vert
        [40]="#5f87b8"  # Bleu
        [35]="#6272a4"  # Bleu mauve (Dracula Comment)
        [30]="#bd93f9"  # Violet (Dracula Purple)
        [25]="#a38ee0"  # Violet moyen
        [20]="#8c7ae6"  # Violet intense
        [0]="#44475a"   # Bleu gris foncé (Dracula Selection)
    )

    for threshold in $(echo "${!util_colors[@]}" | tr ' ' '\n' | sort -nr); do
        if (( utilization_int >= threshold )); then
            color=${util_colors[$threshold]}
            echo "<span color='$color'><b>${utilization}%</b></span>"
            return
        fi
    done
    # Fallback to default color if no threshold matches
    echo "<span color='#8be9fd'><b>${utilization}%</b></span>"
}

=======
    [ -n "$def_val" ] && echo "$def_val" || echo " "
}
init_query() {
    [[ -f $cpuinfo_file ]] && source "$cpuinfo_file"
    if [[ -z $CPUINFO_MODEL ]]; then
        CPUINFO_MODEL=$(lscpu | awk -F': ' '/Model name/ {gsub(/^ *| *$| CPU.*/,"",$2); print $2}')
        echo "CPUINFO_MODEL=\"$CPUINFO_MODEL\"" >>"$cpuinfo_file"
    fi
    if [[ -z $CPUINFO_MAX_FREQ ]]; then
        CPUINFO_MAX_FREQ=$(lscpu | awk '/CPU max MHz/ { sub(/\..*/,"",$4); print $4}')
        echo "CPUINFO_MAX_FREQ=\"$CPUINFO_MAX_FREQ\"" >>"$cpuinfo_file"
    fi
    statFile=$(head -1 /proc/stat)
    if [[ -z $CPUINFO_PREV_STAT ]]; then
        CPUINFO_PREV_STAT=$(awk '{print $2+$3+$4+$6+$7+$8 }' <<<"$statFile")
        echo "CPUINFO_PREV_STAT=\"$CPUINFO_PREV_STAT\"" >>"$cpuinfo_file"
    fi
    if [[ -z $CPUINFO_PREV_IDLE ]]; then
        CPUINFO_PREV_IDLE=$(awk '{print $5 }' <<<"$statFile")
        echo "CPUINFO_PREV_IDLE=\"$CPUINFO_PREV_IDLE\"" >>"$cpuinfo_file"
    fi
}

>>>>>>> master
get_utilization() {
    local statFile currStat currIdle diffStat diffIdle utilization
    statFile=$(head -1 /proc/stat)
    currStat=$(awk '{print $2+$3+$4+$6+$7+$8 }' <<<"$statFile")
    currIdle=$(awk '{print $5 }' <<<"$statFile")
    diffStat=$((currStat - CPUINFO_PREV_STAT))
    diffIdle=$((currIdle - CPUINFO_PREV_IDLE))
<<<<<<< HEAD

    # Store state and sleep
    CPUINFO_PREV_STAT=$currStat
    CPUINFO_PREV_IDLE=$currIdle

    # Save the current state to the file
=======
    CPUINFO_PREV_STAT=$currStat
    CPUINFO_PREV_IDLE=$currIdle
>>>>>>> master
    sed -i -e "/^CPUINFO_PREV_STAT=/c\CPUINFO_PREV_STAT=\"$currStat\"" -e "/^CPUINFO_PREV_IDLE=/c\CPUINFO_PREV_IDLE=\"$currIdle\"" "$cpuinfo_file" || {
        echo "CPUINFO_PREV_STAT=\"$currStat\"" >>"$cpuinfo_file"
        echo "CPUINFO_PREV_IDLE=\"$currIdle\"" >>"$cpuinfo_file"
    }
<<<<<<< HEAD

    awk -v stat="$diffStat" -v idle="$diffIdle" 'BEGIN {printf "%.1f", (stat/(stat+idle))*100}'
}

cpuinfo_file="/tmp/hyde-${UID}-processors"
# shellcheck disable=SC1090
source "${cpuinfo_file}"
init_query

# Define glyphs
if [[ $CPUINFO_EMOJI -ne 1 ]]; then
    temp_lv="85:, 65:, 45:☁, ❄"
else
    temp_lv="85:🌋, 65:🔥, 45:☁️, ❄️"
fi
util_lv="90:, 60:󰓅, 30:󰾅, 󰾆"

# Main loop

# Get dynamic CPU information
sensors_json=$(sensors -j 2>/dev/null)

# TODO: Add support for more sensor chips
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

if [ -n "${CPUINFO_TEMPERATURE_ID}" ]; then
    temperature=$(grep -oP "(?<=${CPUINFO_TEMPERATURE_ID}: )\d+" <<<"${cpu_temps}")
fi

if [[ -z "$temperature" ]]; then
    # Extract the first temperature from the JSON
    cpu_temp_line="${cpu_temps%%$'°C'*}" # Get the first line
    temperature="${cpu_temp_line#*: }"   # Remove everything before the colon and space
fi

utilization=$(get_utilization)
frequency=$(perl -ne 'BEGIN { $sum = 0; $count = 0 } if (/cpu MHz\s+:\s+([\d.]+)/) { $sum += $1; $count++ } END { if ($count > 0) { printf "%.2f\n", $sum / $count } else { print "NaN\n" } }' /proc/cpuinfo)

# Generate glyphs
icons="$(map_floor "$util_lv" "$utilization")$(map_floor "$temp_lv" "$temperature")"
speedo="${icons:0:1}"
thermo="${icons:1:1}"
emoji="${icons:2}"

# Get color based on utilization
utilization_color=$(get_use_color "$utilization")
temp_color=$(get_temp_color "$temperature")

# Prepare the tooltip string
tooltip_str="$emoji $CPUINFO_MODEL\n"
[[ -n "$thermo" ]] && tooltip_str+="$thermo Temperature: \n\t$cpu_temps \n"
[[ -n "$speedo" ]] && tooltip_str+="$speedo Utilization: $utilization_color\n"
tooltip_str+=" Clock Speed: $frequency/$CPUINFO_MAX_FREQ MHz"

# Print the output
cat <<JSON
{"text":"CPU: $speedo $utilization_color / $thermo $temp_color", "tooltip":"$tooltip_str"}
JSON


=======
    awk -v stat="$diffStat" -v idle="$diffIdle" 'BEGIN {printf "%.1f", (stat/(stat+idle))*100}'
}
[[ -f $cpuinfo_file ]] && source "$cpuinfo_file"
init_query
sensors_json=$(sensors -j 2>/dev/null)
cpu_temps="$(perl -e '
use strict;
use warnings;
my $parser;
BEGIN {
    eval { require Cpanel::JSON::XS; $parser = Cpanel::JSON::XS->new->utf8; 1 }
      or eval { require JSON::XS; $parser = JSON::XS->new->utf8; 1 }
      or do { require JSON::PP; $parser = JSON::PP->new->utf8; };
}
my $json = do { local $/; <> };
my $data = eval { $parser->decode($json) } || {};
my @chips = ("coretemp-isa-0000","k10temp-pci-00c3","zenpower-pci-00c3");
my @lines;
for my $chip (@chips) {
    next unless exists $data->{$chip} && ref $data->{$chip} eq "HASH";
    my $entries = $data->{$chip};
    for my $label (keys %$entries) {
        my $obj = $entries->{$label};
        next unless ref $obj eq "HASH";
        my $temp;
        for my $k (keys %$obj) {
            next unless $k =~ /^temp\d+_input$/;
            $temp = int($obj->{$k});
            last;
        }
        push @lines, "$label: ${temp}°C" if defined $temp;
    }
}
print join("\\n\\t", @lines);
' <<<"$sensors_json")"

if [ -n "$CPUINFO_TEMPERATURE_ID" ]; then
    temperature=$(perl -ne 'BEGIN{$id=shift} if (/^\Q$id\E:\s*([0-9]+)/){print $1; exit}' "$CPUINFO_TEMPERATURE_ID" <<<"$cpu_temps")
fi
if [[ -z $temperature ]]; then
    cpu_temp_line="${cpu_temps%%$'°C'*}"
    temperature="${cpu_temp_line#*: }"
fi
utilization=$(get_utilization)
frequency=$(perl -ne 'BEGIN { $sum = 0; $count = 0 } if (/cpu MHz\s+:\s+([\d.]+)/) { $sum += $1; $count++ } END { if ($count > 0) { printf "%.2f\n", $sum / $count } else { print "NaN\n" } }' /proc/cpuinfo)

# Numeric classes and percentage for Waybar formatting
temp_val=${temperature%%.*}
((temp_val < 0)) && temp_val=0
((temp_val > 999)) && temp_val=999
temp_bucket=$(((temp_val / 5) * 5))
((temp_bucket > 100)) && temp_bucket=100
temp_class="temp-$temp_bucket"

util_val=${utilization%.*}
((${util_val:-0} < 0)) && util_val=0
((${util_val:-0} > 100)) && util_val=100
util_bucket=$(((util_val / 10) * 10))
util_class="util-$util_bucket"

temp_pct=$temp_val
((temp_pct > 100)) && temp_pct=100
tooltip_str="$CPUINFO_MODEL\n"
tooltip_str+="Temperature: \n\t$cpu_temps \n"
tooltip_str+="Utilization: $utilization%\n"
tooltip_str+="Clock Speed: $frequency/$CPUINFO_MAX_FREQ MHz"
cat <<JSON
{"text":"$temperature°C", "tooltip":"$tooltip_str", "class":["$temp_class","$util_class"], "percentage":$temp_pct, "alt":"$temp_bucket"}
JSON
>>>>>>> master
