#!/usr/bin/env bash

# Check release
if [ ! -f /etc/arch-release ] ; then
    exit 0
fi

# source variables
scrDir=$(dirname "$(realpath "$0")")
source "$scrDir/globalcontrol.sh"
get_aurhlpr
export -f pkg_installed
fpk_exup="pkg_installed flatpak && flatpak update"
# Create the folder to store the JSON file
[ ! -f "$HYDE_RUNTIME_DIR/update_info.json" ] && mkdir -p "$HYDE_RUNTIME_DIR"
json_file="$HYDE_RUNTIME_DIR/update_info.json"

# Trigger upgrade
if [ "$1" == "up" ] ; then
    if [ -f "$json_file" ]; then
        # refreshes the module so after you update it will reset to zero
        trap 'pkill -RTMIN+20 waybar' EXIT
        # Read and parse JSON in one step
        eval "$(jq -r '@sh "official_updates=\(.official_updates) aur_updates=\(.aur_updates) flatpak_updates=\(.flatpak_updates)"' "$json_file")"  
        command="
        fastfetch
        printf '[%s] %5s\n' 'Official' '$official_updates'
        printf '[%s] %10s\n' 'AUR' '$aur_updates'
        printf '[%s] %6s\n' 'Flatpak' '$flatpak_updates'
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
ofc=$(pacman -Qu | wc -l)

# Check for flatpak updates
if pkg_installed flatpak ; then
    fpk=$(flatpak remote-ls --updates | wc -l)
    fpk_disp="\n󰏓 Flatpak $fpk"
else
    fpk=0
    fpk_disp=""
fi

# Calculate total available updates
upd=$(( ofc + aur + fpk ))
# Prepare the upgrade info as JSON format
upgrade_info=$(cat <<EOF
{
    "official_updates": "$ofc",
    "aur_updates": "$aur",
    "flatpak_updates": "$fpk",
    "total_updates": "$upd"
}
EOF
)

# Save the upgrade info as JSON file
echo "$upgrade_info" > "$json_file"
# Show tooltip
if [ $upd -eq 0 ] ; then
    upd="" #Remove Icon completely
    # upd="󰮯"   #If zero Display Icon only
    echo "{\"text\":\"$upd\", \"tooltip\":\" Packages are up to date\"}"
else
    echo "{\"text\":\"󰮯 $upd\", \"tooltip\":\"󱓽 Official $ofc\n󱓾 AUR $aur$fpk_disp\"}"
fi
