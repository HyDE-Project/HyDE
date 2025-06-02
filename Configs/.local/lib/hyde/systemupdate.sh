#!/usr/bin/env bash

# Check release
if [ ! -f /etc/arch-release ]; then
    exit 0
fi

# source variables
scrDir=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1091
source "$scrDir/globalcontrol.sh"
get_aurhlpr
export -f pkg_installed
fpk_exup="pkg_installed flatpak && flatpak update"
temp_file="$HYDE_RUNTIME_DIR/update_info"
# shellcheck source=/dev/null
[ -f "$temp_file" ] && source "$temp_file"

# Trigger upgrade
if [ "$1" == "up" ]; then
    if [ -f "$temp_file" ]; then
        # refreshes the module so after you update it will reset to zero
        trap 'pkill -RTMIN+20 waybar' EXIT
        # Read info from env file
        while IFS="=" read -r key value; do
            case "$key" in
            OFFICIAL_UPDATES) official=$value ;;
            AUR_UPDATES) aur=$value ;;
            FLATPAK_UPDATES) flatpak=$value ;;
            esac
        done <"$temp_file"

        command="
        fastfetch
        printf '[Official] %-10s\n[AUR]      %-10s\n[Flatpak]  %-10s\n' '$official' '$aur' '$flatpak'
        ${aurhlpr} -Syu
        $fpk_exup
        read -n 1 -p 'Press any key to continue...'
        "
        kitty --title systemupdate sh -c "${command}"
    else
        echo "No upgrade info found. Please run the script without parameters first."
    fi
    exit 0
fi

# Check for AUR updates
aur=$(${aurhlpr} -Qua | wc -l)
ofc=$(
    temp_db=$(mktemp -u /tmp/checkupdates_db_XXXXXX)
    trap '[ -f "$temp_db" ] && rm "$temp_db" 2>/dev/null' EXIT INT TERM
    CHECKUPDATES_DB="$temp_db" checkupdates 2>/dev/null | wc -l
)

# Check for flatpak updates
if pkg_installed flatpak; then
    fpk=$(flatpak remote-ls --updates | wc -l)
    fpk_disp="\n󰏓 Flatpak $fpk"
else
    fpk=0
    fpk_disp=""
fi

# Calculate total available updates
upd=$((ofc + aur + fpk))
# Prepare the upgrade info
upgrade_info=$(
    cat <<EOF
OFFICIAL_UPDATES=$ofc
AUR_UPDATES=$aur
FLATPAK_UPDATES=$fpk
EOF
)

# Save the upgrade info
echo "$upgrade_info" >"$temp_file"
# Show tooltip
if [ $upd -eq 0 ]; then
    upd="" #Remove Icon completely
    # upd="󰮯"   #If zero Display Icon only
    echo "{\"text\":\"$upd\", \"tooltip\":\" Packages are up to date\"}"
else
    echo "{\"text\":\"󰮯 $upd\", \"tooltip\":\"󱓽 Official $ofc\n󱓾 AUR $aur$fpk_disp\"}"
fi
