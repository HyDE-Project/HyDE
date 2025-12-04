#!/usr/bin/env bash

[[ ${HYDE_SHELL_INIT} -ne 1   ]] && eval "$(hyde-shell init)"

qr_extract() {

    image_path="$1"

    if ! pkg_installed "zbar"; then
        notify-send -a "QR Scan" "zbar package is not installed" -e -i "dialog-error"
        return 1
    fi

    qr_output=$(
            zbarimg \
                --quiet \
                --oneshot \
                --raw \
                "${image_path}" \
                2> /dev/null
    )

    printf "%s" "$qr_output" | wl-copy
    notify-send -a "QR Scan" "QR: successfully recognized" -i "$image_path" -e -r 9
}
