#!/usr/bin/env bash

[[ ${HYDE_SHELL_INIT} -ne 1   ]] && eval "$(hyde-shell init)"

ocr_extract() {

    image_path="$1"
    tesseract_default_language=("eng")
    tesseract_languages=("${SCREENSHOT_OCR_TESSERACT_LANGUAGES[@]:-${tesseract_default_language[@]}}")
    tesseract_languages+=("osd")
    tesseract_package_prefix="tesseract-data-"
    tesseract_packages=("${tesseract_languages[@]/#/$tesseract_package_prefix}")
    tesseract_packages+=("tesseract")

    for pkg in "${tesseract_packages[@]}"; do
        if ! pkg_installed "$pkg"; then
            notify-send -a "HyDE Alert" "$(echo -e "OCR: required package is not installed\n $pkg")" -e -i "dialog-error"
            return 1
        fi
    done

    tesseract_languages_prepared=$(
            IFS=+
            echo "${tesseract_languages[*]}"
    )

    tesseract_output=$(
            tesseract \
                --psm 6 \
                --oem 3 \
                -l "${tesseract_languages_prepared}" \
                "${image_path}" \
                stdout 2> /dev/null
    )

    printf "%s" "$tesseract_output" | wl-copy
    notify-send -a "HyDE Alert" "$(echo -e "OCR: ${#tesseract_output} symbols recognized\n\nLanguages used ${tesseract_languages[@]/#/'\n '}")" -i "$image_path" -e -r 9

}
