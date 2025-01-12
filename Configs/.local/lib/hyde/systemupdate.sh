#!/usr/bin/env bash

if [ ! -f /etc/arch-release ] ; then
    exit 0
fi

scrDir=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1091
source "$scrDir/globalcontrol.sh"
get_aurhlpr

export -f pkg_installed

fpk_exup="pkg_installed flatpak && flatpak update"
snp_exup="pkg_installed snap && snap refresh"

# Temporary file to store update information
temp_file="$HYDE_RUNTIME_DIR/update_info"
# shellcheck source=/dev/null
[ -f "$temp_file" ] && source "$temp_file"

# Trigger upgrade if 'up' parameter is passed
if [ "$1" == "up" ] ; then
    if [ -f "$temp_file" ]; then

        trap 'pkill -RTMIN+20 waybar' EXIT
        
        # Read update info from the temporary file
        while IFS="=" read -r key value; do
            case "$key" in
                OFFICIAL_UPDATES) official=$value ;;
                AUR_UPDATES) aur=$value ;;
                FLATPAK_UPDATES) flatpak=$value ;;
                SNAP_UPDATES) snap=$value ;;
            esac
        done < "$temp_file"

        # Command to update the system and show update information
        command="
        fastfetch
        printf '[Official] %-10s\n[AUR]      %-10s\n[Flatpak]  %-10s\n[Snap]     %-10s\n' '$official' '$aur' '$flatpak' '$snap'
        ${aurhlpr} -Syu
        $fpk_exup
        $snp_exup
        read -n 1 -p 'Press any key to continue...'
        "
        kitty --title systemupdate sh -c "${command}"
    else
        echo "No upgrade info found. Please run the script without parameters first."
    fi
    exit 0
fi

aur=$(${aurhlpr} -Qua | wc -l)
ofc=$(CHECKUPDATES_DB=$(mktemp -u) checkupdates | wc -l)

# Check updates
if pkg_installed flatpak ; then
    fpk=$(flatpak remote-ls --updates | wc -l)
    fpk_disp="\n󰏓 Flatpak $fpk"
else
    fpk=0
    fpk_disp=""
fi

if pkg_installed snap ; then
    snp=$(snap refresh --list | wc -l)
    snp_disp="\n Snap $snp"
else
    snp=0
    snp_disp=""
fi

# Calculate total available updates
upd=$(( ofc + aur + fpk + snp ))

# Prepare the upgrade info
upgrade_info=$(cat <<EOF
OFFICIAL_UPDATES=$ofc
AUR_UPDATES=$aur
FLATPAK_UPDATES=$fpk
SNAP_UPDATES=$snp
EOF
)

# Save the upgrade info to the temporary file
echo "$upgrade_info" > "$temp_file"

# Show tooltip with update information
if [ $upd -eq 0 ] ; then
    upd="" # Remove Icon completely if no updates
    # upd="󰮯" # If zero, display Icon only
    echo "{\"text\":\"$upd\", \"tooltip\":\" Packages are up to date\"}"
else
    echo "{\"text\":\"󰮯 $upd\", \"tooltip\":\"󱓽 Official $ofc\n󱓾 AUR $aur$fpk_disp$snp_disp\"}"
fi
