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

    curl -L -o "${cache_dir}/landing/Spotify_Sleek.tar.gz" "https://github.com/prasanthrangan/hyprdots/raw/main/Source/arcs/Spotify_Sleek.tar.gz"
    tar -xzf "${cache_dir}/landing/Spotify_Sleek.tar.gz" -C ~/.config/spicetify/Themes/
    spicetify backup apply
    spicetify config current_theme Sleek
    spicetify config color_scheme Wallbash
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
    elif [ -f "${shareDir}/spotify-launcher/install/usr/bin/spotify" ]; then
        spotify_path="${shareDir}/spotify-launcher/install/usr/bin/spotify"
    elif [ -d /opt/spotify ]; then
        spotify_path='/opt/spotify'
        if [ ! -w "${spotify_path}" ] || [ ! -w "${spotify_path}/Apps" ]; then
            notify_and_set_permissions "${spotify_path}"
        fi
    fi

if (pkg_installed spotify && pkg_installed spicetify-cli) || [ -n "$spotify_path" ]; then


    if [ "$(spicetify config | awk '{if ($1=="color_scheme") print $2}')" != "Wallbash" ] || [[ "${*}" == *"--reset"* ]]; then
        configure_spicetify "$spotify_path" "$cacheDir"
    fi

    if pgrep -x spotify >/dev/null; then
        pkill -x spicetify
        spicetify -q watch -s &
    fi
fi
