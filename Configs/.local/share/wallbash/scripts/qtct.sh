#!/usr/bin/env bash

wallbash_cache=${XDG_CACHE_HOME:-$HOME/.cache}/hyde/wallbash/qtct.conf
declare -A color_scheme_target_paths=(
    ["qt5ct_legacy"]="${XDG_CONFIG_HOME:-$HOME/.config}/qt5ct/colors.conf"
    ["qt6ct_legacy"]="${XDG_CONFIG_HOME:-$HOME/.config}/qt6ct/colors.conf"
    ["qt5ct"]="${XDG_CONFIG_HOME:-$HOME/.config}/qt5ct/colors/wallbash.conf"
    ["qt6ct"]="${XDG_CONFIG_HOME:-$HOME/.config}/qt6ct/colors/wallbash.conf"

)

[[ -f "$wallbash_cache" ]] || { echo "Wallbash cache file not found at $wallbash_cache"; exit 1; }

for scheme in "${!color_scheme_target_paths[@]}"; do
    target_path="${color_scheme_target_paths[$scheme]}"
    [[ -f "${target_path}" ]] &&  cp "$wallbash_cache" "$target_path"
done

