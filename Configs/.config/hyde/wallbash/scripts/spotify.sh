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
    local spicetify_conf
    local spotify_conf
    local spotify_prefs

    if [[ "$spotify_path" =~ "flatpak" ]]; then
        spotify_conf="$HOME/.var/app/com.spotify.Client/config/spotify"
    else
        spotify_conf="$HOME/.config/spotify"
    fi
    spotify_prefs="${spotify_conf}/prefs"

    spicetify &>/dev/null
    mkdir -p "$spotify_conf"
    touch "$spotify_prefs"
    spicetify_conf=$(spicetify -c)

    sed -i -e "/^prefs_path/ s+=.*$+= $spotify_prefs+g" \
        -e "/^spotify_path/ s+=.*$+= $spotify_path+g" \
        -e "/^spotify_launch_flags/ s+=.*$+= $spotify_flags+g" "$spicetify_conf"

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
flatpak_install_path="flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify"

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
elif [ -d "/var/lib/${flatpak_install_path}" ]; then
    spotify_path="/var/lib/${flatpak_install_path}"
elif [ -d "${shareDir}/${flatpak_install_path}" ]; then
    spotify_path="${shareDir}/${flatpak_install_path}"
fi
if [ ! -w "${spotify_path}" ] || [ ! -w "${spotify_path}/Apps" ]; then
    notify_and_set_permissions "${spotify_path}"
fi

if ([ -n "$spotify_path" ] || pkg_installed spotify) && pkg_installed spicetify-cli; then

    if [ "$(spicetify config | awk '{if ($1=="color_scheme") print $2}')" != "Wallbash" ] || [[ "${*}" == *"--reset"* ]]; then
        configure_spicetify "$spotify_path" "$cacheDir"
    fi

    spicetify refresh

    if pgrep -x spotify >/dev/null; then
        pkill -x spicetify
        spicetify -q watch -s &
        if ! pgrep -x spotify >/dev/null; then
            spicetify auto
        fi
    fi
fi
