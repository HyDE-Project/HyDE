#!/usr/bin/env bash

# Function to set permissions for Spotify path
set_permissions() {
    local path=$1
    chmod a+wr "$path"
    chmod a+wr -R "$path/Apps"
}

# Function to notify and set permissions using pkexec
notify_and_set_permissions() {
    local path=$1
    notify-send -a "HyDE Alert" "Permission needed for Wallbash Spotify theme"
    pkexec chmod a+wr "$path"
    pkexec chmod a+wr -R "$path/Apps"
}

# Function to configure Spicetify
configure_spicetify() {
    local spotify_path=$1
    local cache_dir=$2
    local spotify_flags='--ozone-platform=wayland'
    local spotify_conf
    
    spicetify &>/dev/null
    mkdir -p ~/.config/spotify
    touch ~/.config/spotify/prefs
    spotify_conf=$(spicetify -c)
    
    sed -i -e "/^prefs_path/ s+=.*$+= $HOME/.config/spotify/prefs+g" \
    -e "/^spotify_path/ s+=.*$+= $spotify_path+g" \
    -e "/^spotify_launch_flags/ s+=.*$+= $spotify_flags+g" "$spotify_conf"
    
    spicetify_themes_dir="$HOME/.config/spicetify/Themes"
    if [ ! -d "${spicetify_themes_dir}/Sleek" ]; then
        curl -L -o "${cache_dir}/landing/Spotify_Sleek.tar.gz" "https://github.com/HyDE-Project/HyDE/raw/master/Source/arcs/Spotify_Sleek.tar.gz"
        tar -xzf "${cache_dir}/landing/Spotify_Sleek.tar.gz" -C "$spicetify_themes_dir"
    fi
    spicetify backup apply
    spicetify config current_theme Sleek
    spicetify config color_scheme Wallbash
    spicetify config sidebar_config 0
    spicetify restore backup
    spicetify backup apply
}

# Main script
cacheDir="${cacheDir:-$XDG_CACHE_HOME/hyde}"
shareDir=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -n "${SPOTIFY_PATH}" ]; then
    spotify_path="${SPOTIFY_PATH}"
    cat <<EOF
[warning]   using custom spotify path
            ensure to have proper permissions for ${SPOTIFY_PATH}
            run:
            chmod a+wr ${SPOTIFY_PATH}
            chmod a+wr -R ${SPOTIFY_PATH}/Apps

            note: run with 'sudo' if only needed.
EOF
    
    elif [ -d "${XDG_DATA_HOME}/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify" ]; then
    spotify_path="${XDG_DATA_HOME}/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify"
    print_log -sec "Spotify" " User Flatpak"
    elif [ -d /var/lib/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify ]; then
    spotify_path='/var/lib/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify'
    print_log -sec "Spotify" " System Flatpak"
    elif [ -f "${shareDir}/spotify-launcher/install/usr/bin/spotify" ]; then
    spotify_path="${shareDir}/spotify-launcher/install/usr/share/spotify"
    print_log -sec "Spotify" " Spotify-launcher"
    elif [ -d /opt/spotify ]; then
    spotify_path='/opt/spotify'
    print_log -sec "Spotify" " System Package Manager"
fi

if [ ! -w "${spotify_path}" ] || [ ! -w "${spotify_path}/Apps" ]; then
    notify_and_set_permissions "${spotify_path}"
fi

if (pkg_installed spotify && pkg_installed spicetify-cli) || [ -e "${spotify_path}" ]; then
    print_log -sec "Spotify" -stat "path" " ${spotify_path}"
    if [ "$(spicetify config | awk '{if ($1=="color_scheme") print $2}')" != "Wallbash" ] || [[ "${*}" == *"--reset"* ]]; then
        configure_spicetify "$spotify_path" "$cacheDir"
    fi
    
    if pgrep -x spotify >/dev/null; then
        pkill -x spicetify
        spicetify -q watch -s &
        disown
    fi
fi
