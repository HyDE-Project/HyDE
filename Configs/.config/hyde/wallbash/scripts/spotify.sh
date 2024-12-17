#!/usr/bin/env bash

# regen conf
if (pkg_installed spotify && pkg_installed spicetify-cli) || [ -n "$SPOTIFY_PATH" ]; then
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
        spotify_path="${shareDir}/spotify-launcher/install/usr/bin/spotify" # default for spotify-launcher
    elif [ -d /opt/spotify ]; then
        spotify_path='/opt/spotify' # default for AUR
        if [ ! -w "${spotify_path}" ] || [ ! -w "${spotify_path}/Apps" ]; then
            # For spotify in /opt/spotify \\ AUR
            notify-send -a "HyDE Alert" "Permission needed for Wallbash Spotify theme"
            pkexec chmod a+wr ${spotify_path}
            pkexec chmod a+wr -R ${spotify_path}/Apps
        fi
    fi
    if [ "$(spicetify config | awk '{if ($1=="color_scheme") print $2}')" != "Wallbash" ] || [[ "${*}" == *"--reset"* ]]; then
        spicetify &>/dev/null
        mkdir -p ~/.config/spotify
        touch ~/.config/spotify/prefs
        spotifyConf=$(spicetify -c)
        spotify_flags='--ozone-platform=wayland'
        sed -i -e "/^prefs_path/ s+=.*$+= $HOME/.config/spotify/prefs+g" \
            -e "/^spotify_path/ s+=.*$+= $spotify_path+g" \
            -e "/^spotify_launch_flags/ s+=.*$+= $spotify_flags+g" "$spotifyConf"
        curl -L -o "${cacheDir}/landing/Spotify_Sleek.tar.gz" "https://github.com/prasanthrangan/hyprdots/raw/main/Source/arcs/Spotify_Sleek.tar.gz"
        tar -xzf "${cacheDir}/landing/Spotify_Sleek.tar.gz" -C ~/.config/spicetify/Themes/
        spicetify backup apply
        spicetify config current_theme Sleek
        spicetify config color_scheme Wallbash
        spicetify apply
    fi

    if pgrep -x spotify >/dev/null; then
        pkill -x spicetify
        spicetify -q watch -s &
    fi

fi
