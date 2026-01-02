#!/bin/bash
# shellcheck disable=SC1090
cpuinfo_file="${XDG_RUNTIME_DIR:-/tmp}/hyde-$UID-processors"

map_floor() {
    IFS=', ' read -r -a pairs <<<"$1"
    if [[ ${pairs[-1]} != *":"* ]]; then
        def_val="${pairs[-1]}"
        unset 'pairs[-1]'
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
