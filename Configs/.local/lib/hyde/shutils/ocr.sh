#!/usr/bin/env bash

[[ ${HYDE_SHELL_INIT} -ne 1 ]] && eval "$(hyde-shell init)"

# shellcheck disable=SC1091
[[ -f "${LIB_DIR}/hyde/shutils/l10n.sh" ]] && source "${LIB_DIR}/hyde/shutils/l10n.sh"

ocr_extract() {
    image_path="$1"
    tesseract_default_language=("eng")
    tesseract_languages=("${SCREENSHOT_OCR_TESSERACT_LANGUAGES[@]:-${tesseract_default_language[@]}}")
    tesseract_languages+=("osd")
    tesseract_package_prefix="tesseract-data-"
    tesseract_packages=("${tesseract_languages[@]/#/$tesseract_package_prefix}")
    tesseract_packages+=("tesseract")

    echo $tesseract_languages $SCREENSHOT_OCR_TESSERACT_LANGUAGES

    for pkg in "${tesseract_packages[@]}"; do
        if ! pkg_installed "$pkg"; then
            notify-send -a "HyDE Alert" "$(echo -e "${_T[OCR: required package is not installed]:-OCR: required package is not installed}\n $pkg")" -e -i "dialog-error"
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
    notify-send -a "HyDE Alert" "$(echo -e "${_T[OCR:]:-OCR:} ${#tesseract_output} ${_T[symbols recognized]:-symbols recognized}\n\n${_T[Languages used]:-Languages used} ${tesseract_languages[*]/#/'\n '}")" -i "$image_path" -e -r 9

}
