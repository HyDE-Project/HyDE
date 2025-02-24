#!/usr/bin/env bash

scrDir=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1091
source "$scrDir/globalcontrol.sh"
dock=${BATTERY_NOTIFY_DOCK:-false}

# TODO  Icon used
# xfce4-battery-critical-symbolic
# battery-XXX-charging
# battery-level-XXX-symbolic
# battery-full-charging-symbolic

config_info() {
    cat <<EOF

Modify '$XDG_CONFIG_HOME/hyde/config.toml'  to set options.

      STATUS      THRESHOLD    INTERVAL
      Full        $battery_full_threshold          $notify Minutes
      Critical    $battery_critical_threshold           $timer Seconds then '$execute_critical'
      Low         $battery_low_threshold           $interval Percent    then '$execute_low'
      Unplug      $unplug_charger_threshold          $interval Percent   then '$execute_unplug'

      Command on Charging: $execute_charging
      Command on Discharging: $execute_discharging
      Dock Mode: $dock (Will not notify on status change) 


EOF
}

is_laptop() { # Check if the system is a laptop
    if grep -q "Battery" /sys/class/power_supply/BAT*/type; then
        return 0 # It's a laptop
    else
        echo "No battery detected. If you think this is an error please post a report to the repo"
        exit 0 # It's not a laptop
    fi
}
is_laptop
fn_verbose() {
    if $verbose; then
        cat <<VERBOSE
=============================================
        Battery Status: $battery_status
        Battery Percentage: $battery_percentage
=============================================
VERBOSE
    fi
}

fn_percentage() {
    if [[ "$battery_percentage" -ge "$unplug_charger_threshold" ]] && [[ "$battery_status" != "Discharging" ]] && [[ "$battery_status" != "Full" ]] && (((battery_percentage - last_notified_percentage) >= interval)); then
        steps=$(printf "%03d" $(((battery_percentage + 5) / 10 * 10)))
        if $verbose; then echo "Prompt:UNPLUG: $unplug_charger_threshold $battery_status $battery_percentage $steps"; fi
        notify-send -a "HyDE Power" -t 5000 -r 5 -u "CRITICAL" -i "battery-${steps:-100}-charging" "Battery Charged" "Battery is at $battery_percentage%. You can unplug the charger"
        last_notified_percentage=$battery_percentage
    elif [[ "$battery_percentage" -le "$battery_critical_threshold" ]]; then
        count=$((timer > mnt ? timer : mnt)) # reset count
        while [ $count -gt 0 ] && [[ $battery_status == "Discharging"* ]]; do
            for battery in /sys/class/power_supply/BAT*; do battery_status=$(<"$battery/status"); done
            if [[ $battery_status != "Discharging" ]]; then break; fi
            notify-send -a "HyDE Power" -t 5000 -r 5 -u "CRITICAL" -i "xfce4-battery-critical" "Battery Critically Low" "$battery_percentage% is critically low. Device will execute $execute_critical in $((count / 60)):$((count % 60)) ."
            count=$((count - 1))
            sleep 1
        done
        [ $count -eq 0 ] && fn_action
    elif [[ "$battery_percentage" -le "$battery_low_threshold" ]] && [[ "$battery_status" == "Discharging" ]] && (((last_notified_percentage - battery_percentage) >= interval)); then
        steps=$(printf "%1d" $(((battery_percentage + 5) / 10 * 10)))
        if $verbose; then echo "Prompt:LOW: $battery_low_threshold $battery_status $battery_percentage"; fi
        notify-send -a "HyDE Power" -t 5000 -r 5 -u "CRITICAL" -i "battery-level-${steps:-10}-symbolic" "Battery Low" "Battery is at $battery_percentage%. Connect the charger."
        last_notified_percentage=$battery_percentage
    fi
}

fn_action() {                            #handles the $execute_critical command #? This is special as it will try to execute always
    count=$((timer > mnt ? timer : mnt)) # reset count
    nohup "$execute_critical" &>/dev/null &
}

fn_status() {
    if [[ $battery_percentage -ge $battery_full_threshold ]] && [[ "$battery_status" != *"Discharging"* ]]; then
        echo "Full and $battery_status"
        battery_status="Full"
    fi
    case "$battery_status" in # Handle the power supply status
    "Discharging")
        if $verbose; then echo "Case:$battery_status Level: $battery_percentage"; fi
        if [[ "$prev_status" != "Discharging" ]] || [[ "$prev_status" == "Full" ]]; then
            prev_status=$battery_status
            urgency=$([[ $battery_percentage -le "$battery_low_threshold" ]] && echo "CRITICAL" || echo "NORMAL")
            steps=$(printf "%1d" $(((battery_percentage + 5) / 10 * 10)))
            notify-send -a "HyDE Power" -t 5000 -r 5 -u "${urgency:-normal}" -i "battery-level-${steps:-10}-symbolic" "Charger Plug Out" "Battery is at $battery_percentage%."
            $execute_discharging
        fi
        fn_percentage
        ;;
    "Not"* | "Charging")
        if $verbose; then echo "Case:$battery_status Level: $battery_percentage"; fi
        if [[ "$prev_status" == "Discharging" ]] || [[ "$prev_status" == "Not"* ]]; then
            prev_status=$battery_status
            count=$((timer > mnt ? timer : mnt)) # reset count
            urgency=$([[ "$battery_percentage" -ge $unplug_charger_threshold ]] && echo "CRITICAL" || echo "NORMAL")
            steps=$(printf "%03d" $(((battery_percentage + 5) / 10 * 10)))
            notify-send -a "HyDE Power" -t 5000 -r 5 -u "${urgency:-normal}" -i "battery-${steps:-100}-charging" "Charger Plug In" "Battery is at $battery_percentage%."
            $execute_charging
        fi
        fn_percentage
        ;;
    "Full")
        if $verbose; then echo "Case:$battery_status Level: $battery_percentage"; fi
        if [[ $battery_status != "Discharging" ]]; then
            now=$(date +%s)
            if [[ "$prev_status" == *"harging"* ]] || ((now - lt >= $((notify * 60)))); then
                notify-send -a "HyDE Power" -t 5000 -r 5 -u "CRITICAL" -i "battery-full-charging-symbolic" "Battery Full" "Please unplug your Charger"
                prev_status=$battery_status lt=$now
                $execute_charging
            fi
        fi
        ;;
    *)
        if [[ ! -f "/tmp/hyde.battery.notify.status.fallback.$battery_status-$$" ]]; then
            echo "Status: '==>> \"${battery_status}\" <<==' Script on Fallback mode,Unknown power supply status.Please copy this line and raise an issue to the Github Repo.Also run 'ls /tmp/hyde.battery.notify' to see the list of lock files.*"
            touch "/tmp/hyde.battery.notify.status.fallback.$battery_status-$$"
        fi
        fn_percentage
        ;;
    esac
}

get_battery_info() { #TODO Might change this if we can get an effective way to parse dbus. I will do it some time...
    total_percentage=0 battery_count=0
    for battery in /sys/class/power_supply/BAT*; do
        battery_status=$(<"$battery/status") battery_percentage=$(<"$battery/capacity")
        total_percentage=$((total_percentage + battery_percentage))
        battery_count=$((battery_count + 1))
    done
    battery_percentage=$((total_percentage / battery_count)) #? For Multiple Battery
}

fn_status_change() { # Handle when status changes
    get_battery_info
    # Add these two lines at the beginning of the function
    local executed_low=false
    local executed_unplug=false

    if [ "$battery_status" != "$last_battery_status" ] || [ "$battery_percentage" != "$last_battery_percentage" ]; then
        last_battery_status=$battery_status
        last_battery_percentage=$battery_percentage # Check if battery status or percentage has changed
        fn_verbose
        fn_percentage

        if [[ "$battery_percentage" -le "$battery_low_threshold" ]] && ! $executed_low; then
            $execute_low
            executed_low=true executed_unplug=false
        fi
        if [[ "$battery_percentage" -ge "$unplug_charger_threshold" ]] && ! $executed_unplug; then
            $execute_unplug
            executed_unplug=true executed_low=false
        fi
        if ! $dock; then fn_status; fi
    fi
}

# resume_processes() { for pid in $pids ; do  if [ "$pid" -ne "$current_pid" ] ; then kill -CONT $pid ; notify-send -a "Battery Notify" -t 2000 -r 9889 -u "CRITICAL" "Debugging ENDED, Resuming Regular Process" ; fi ; done }

main() {                                       # Main function
    rm -fr "$HYDE_RUNTIME_DIR/battery.notify"* # Cleaning the lock file
    battery_full_threshold=${BATTERY_NOTIFY_THRESHOLD_FULL:-100}
    battery_critical_threshold=${BATTERY_NOTIFY_THRESHOLD_CRITICAL:-5}
    unplug_charger_threshold=${BATTERY_NOTIFY_THRESHOLD_UNPLUG:-80}
    battery_low_threshold=${BATTERY_NOTIFY_THRESHOLD_LOW:-20}
    timer=${BATTERY_NOTIFY_TIMER:-120}
    notify=${BATTERY_NOTIFY_NOTIFY:-1140}
    interval=${BATTERY_NOTIFY_INTERVAL:-5}
    execute_critical=${BATTERY_NOTIFY_EXECUTE_CRITICAL:-"systemctl suspend"}
    execute_low=${BATTERY_NOTIFY_EXECUTE_LOW:-}
    execute_unplug=${BATTERY_NOTIFY_EXECUTE_UNPLUG:-}
    execute_charging=${BATTERY_NOTIFY_EXECUTE_CHARGING:-}
    execute_discharging=${BATTERY_NOTIFY_EXECUTE_DISCHARGING:-}

    config_info
    if $verbose; then
        for line in "Verbose Mode is ON..." "" "" "" ""; do echo "${line}"; done
    #TODO Might still need this in the future but for now we don't have any battery notify issues
    # current_pid=$$
    # pids=$(pgrep -f "/usr/bin/env bash ${scrDir}/battery.notify.sh" )
    # for pid in $pids ; do if [ "$pid" -ne $current_pid ] ;then kill -STOP "$pid" ;notify-send -a "Battery Notify" -t 2000 -r 9889 -u "CRITICAL" "Debugging STARTED, Pausing Regular Process" ;fi ; done  ; trap resume_processes SIGINT ;
    fi
    get_battery_info # initiate the function
    last_notified_percentage=$battery_percentage
    prev_status=$battery_status
    dbus-monitor --system "type='signal',interface='org.freedesktop.DBus.Properties',path='$(upower -e | grep battery)'" 2>/dev/null | while read -r battery_status_change; do fn_status_change; done
}

verbose=false
case "$1" in
-i | --info)
    config_info
    exit 0
    ;;
-v | --verbose)
    verbose=true
    ;;
-*)
    cat <<HELP
Usage: $0 [options]

[-i|--info]                    Display configuration information
[-v|--verbose]                 Debugging mode
[-h|--help]                 This Message
HELP
    exit 0
    ;;
esac

mnc=2 mxc=50 mnl=10 mxl=80 mnu=40 mxu=100 mnt=60 mxt=1000 mnf=50 mxf=100 mnn=1 mxn=1140 mni=1 mxi=10 #Defaults Ranges

check_range() {
    local var=$1 min=$2 max=$3 error_message=$4
    if [[ $var =~ ^[0-9]+$ ]] && ((var >= min && var <= max)); then
        shift 2
    else
        echo -e "$1 WARNING: $error_message must be $min - $max." >&2
    fi
}

check_range "$battery_full_threshold" $mnf $mxf "Full Threshold"
check_range "$battery_critical_threshold" $mnc $mxc "Critical Threshold"
check_range "$battery_low_threshold" $mnl $mxl "Low Threshold"
check_range "$unplug_charger_threshold" $mnu $mxu "Unplug Threshold"
check_range "$timer" $mnt $mxt "Timer"
check_range "$notify" $mnn $mxn "Notify"
check_range "$interval" $mni $mxi "Interval"

main
