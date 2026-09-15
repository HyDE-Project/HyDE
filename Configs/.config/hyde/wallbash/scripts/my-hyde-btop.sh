#!/usr/bin/env bash
# Selects the theme written by wallbash/always/btop.dcol and changes nothing else.
set -Eeuo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/btop"
config="$config_dir/btop.conf"
theme="hyde-wallbash"

[[ -d "$config_dir" ]] || exit 0

if [[ -f "$config" ]] && grep -q '^[[:space:]]*color_theme[[:space:]]*=' "$config"; then
    sed -i "s|^[[:space:]]*color_theme[[:space:]]*=.*$|color_theme = \"$theme\"|" "$config"
else
    printf 'color_theme = "%s"\n' "$theme" >>"$config"
fi
