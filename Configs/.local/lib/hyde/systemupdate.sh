#!/usr/bin/env bash
if [ ! -f /etc/arch-release ]; then
    exit 0
fi
scrDir=$(dirname "$(realpath "$0")")
source "$scrDir/globalcontrol.sh"
get_aurhlpr
export -f pkg_installed
fpk_exup="pkg_installed flatpak && flatpak update"
temp_file="$XDG_RUNTIME_DIR/hyde/update_info"
[ -f "$temp_file" ] && source "$temp_file"
if [ "$1" == "up" ]; then
    if [ -f "$temp_file" ]; then
        trap 'pkill -RTMIN+20 waybar' EXIT
        while IFS="=" read -r key value; do
            case "$key" in
                OFFICIAL_UPDATES) official=$value ;;
                AUR_UPDATES) aur=$value ;;
                FLATPAK_UPDATES) flatpak=$value ;;
            esac
        done < "$temp_file"
        command="
        hyde-shell fastfetch
        printf '[Official] %-10s\n[AUR]      %-10s\n[Flatpak]  %-10s\n' '$official' '$aur' '$flatpak'
        "$aurhlpr" -Syu
        $fpk_exup
        read -n 1 -p 'Press any key to continue...'
        "
        kitty --title systemupdate sh -c "$command"
    else
        echo "No upgrade info found. Please run the script without parameters first."
    fi
    exit 0
fi
aur=$($aurhlpr -Qua | wc -l)
ofc=$(
    temp_db=$(mktemp -u "${XDG_RUNTIME_DIR:-"/tmp"}/checkupdates_db_XXXXXX")
    trap '[ -f "$temp_db" ] && rm "$temp_db" 2>/dev/null' EXIT INT TERM
    CHECKUPDATES_DB="$temp_db" checkupdates 2> /dev/null | wc -l
)
if pkg_installed flatpak; then
    fpk=$(flatpak remote-ls --updates | wc -l)
    fpk_disp="\n󰏓 Flatpak $fpk"
else
    fpk=0
    fpk_disp=""
fi
upd=$((ofc + aur + fpk))
upgrade_info=$(
    cat << EOF
OFFICIAL_UPDATES=$ofc
AUR_UPDATES=$aur
FLATPAK_UPDATES=$fpk
EOF
)
echo "$upgrade_info" > "$temp_file"
if [ $upd -eq 0 ]; then
    upd=""
    echo "{\"text\":\"$upd\", \"tooltip\":\" Packages are up to date\"}"
else
    echo "{\"text\":\"󰮯 $upd\", \"tooltip\":\"󱓽 Official $ofc\n󱓾 AUR $aur$fpk_disp\"}"
fi
