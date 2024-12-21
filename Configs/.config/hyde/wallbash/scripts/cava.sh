#!/usr/bin/env bash

# shellcheck source=/home/khing/.local/bin/hyde-shell
# shellcheck disable=SC1091
if ! source "$(which hyde-shell)"; then
    echo "[wallbash] code :: Error: hyde-shell not found."
    echo "[wallbash] code :: Is HyDE installed?"
    exit 1
fi

confDir="${confDir:-$XDG_CONFIG_HOME}"
cacheDir="${cacheDir:-$XDG_CACHE_HOME/hyde}"
cvaDir="${confDir}/cava"
CAVA_CONF="${cvaDir}/config"
CAVA_DCOL="${cacheDir}/wallbash/cava"
KEY_LINE='### Auto generated wallbash colors ###'

if pkg_installed cava; then
    if [[ ! -d "${cvaDir}" ]]; then
        print_log -sec "wallbash" -warn "Not initialized" "cava config directory not found. Try running cava first."
    else

        sed -i "/${KEY_LINE}/,\$d" "${CAVA_CONF}"
        if grep -q "${KEY_LINE}" "${CAVA_CONF}"; then
            sed -i "/${KEY_LINE}/r ${CAVA_DCOL}" "${CAVA_CONF}"
        else
            echo "${KEY_LINE}" >>"${CAVA_CONF}"
            sed -i "/${KEY_LINE}/r ${CAVA_DCOL}" "${CAVA_CONF}"
        fi

        pkill -USR2 cava
    fi
fi
