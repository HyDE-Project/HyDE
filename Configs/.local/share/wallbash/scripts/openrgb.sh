#!/usr/bin/env bash

if ! source "$(which hyde-shell)"; then
    echo "[wallbash] code :: Error: hyde-shell not found."
    echo "[wallbash] code :: Is HyDE installed?"
    exit 1
fi

if pkg_installed openrgb; then
    cacheDir="${cacheDir:-${XDG_CACHE_HOME:-$HOME/.cache}/hyde}"
    OPENRGB_PROFILE="${cacheDir}/wallbash/openrgb"
    mkdir -p "${OPENRGB_PROFILE%/*}"

    openrgb --color "${dcol_pry2}"
    openrgb --save-profile "${OPENRGB_PROFILE}"
fi
