#!/usr/bin/env bash
# Script to resolve fonts

font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
landing_dir="${XDG_CACHE_HOME:-$HOME/.cache}/hyde/landing/fonts"
mkdir -p "$font_dir" "$landing_dir"

download_and_extract() {
    local name="${1}"
    local url="${2}"
    local temp_dir="${landing_dir}/${name}"

    # Extract domain name using parameter expansion
    domain=${url#*://}   # Remove everything up to '://'
    domain=${domain%%/*} # Remove everything after the first '/'
    # Ping the extracted domain
    if ! ping -c 1 "$domain" &>/dev/null; then
        echo "[font] Ping to $domain failed"
        exit 1
    fi

    mkdir -p "${temp_dir}"
    if cd "${temp_dir}"; then
        curl -s -O -L "${url}" || return 1
    else
        return 1
    fi
    find "$temp_dir" -type f | while read -r file; do
        case "$file" in
        *.tar.gz)
            if command -v tar >/dev/null; then
                tar -xzf "$file" -C "${temp_dir}/${name}"
            else
                echo "[font] tar is not installed"
                return 1
            fi
            ;;
        *.zip)
            if command -v unzip >/dev/null; then
                unzip -q "$file" -d "${temp_dir}/${name}"
            else
                echo "[font] unzip is not installed"
                return 1
            fi
            ;;
        *.tar.xz)
            if command -v tar >/dev/null; then
                tar -xJf "$file" -C "${temp_dir}/${name}"
            else
                echo "tar is not installed"
                return 1
            fi
            ;;
        *.ttf | *.otf)
            mkdir -p "${font_dir}/hyde"
            mv "$file" "${font_dir}/hyde/$name.ttf"
            echo "[font] $name installed successfully. Please restart hyprlock to apply changes."
            notify-send -i "preferences-desktop-font" "HyDE font" "${name} Installed successfully"
            return 0
            ;;
        *)
            echo "[font] Unsupported file format: $file"
            rm -f "$temp_dir"
            return 1
            ;;
        esac

        if ! cp -rn "${temp_dir}/${name}" "$font_dir"; then
            echo "[font] Failed to extract $file"
            notify-send -i "preferences-desktop-font" "HyDE font" "Failed to extract $file"
            return 1
        fi
        notify-send -i "preferences-desktop-font" "HyDE font" "${name} Installed successfully"
    done

    rm -rf "$temp_dir"
    echo "[font] $name installed successfully. Please restart hyprlock to apply changes."
    return 0
}

resolve() {
    local layout_path="${1}"
    layout_path="$(printf "%s" "${layout_path}")"
    layout_path="$(realpath "${layout_path}")"
    if [[ ! -f "${layout_path}" ]]; then
        echo "[font] Layout file not found: ${layout_path}"
        return 1
    fi
    # shellcheck disable=SC2016
    grep -Eo '^\s*\$resolve\.font\s*=\s*[^|]+\s*\|\s*[^ ]+' "${layout_path}" | while IFS='=' read -r _ font; do
        name=$(echo "$font" | awk -F'|' '{print $1}' | xargs)
        url=$(echo "$font" | awk -F'|' '{print $2}' | xargs)
        if ! fc-list | grep -q "${name}"; then
            download_and_extract "$name" "$url"
            fc-cache -f "${font_dir}/${name}"
        fi
    done
}

"${@}"
