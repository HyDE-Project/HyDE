#!/bin/bash

# This script generates a Chrome theme based on the Wallbash wallpaper
# Thanks to https://github.com/metafates/ChromiumPywal for the inspiration

# shellcheck disable=SC2154
# shellcheck disable=SC1091
if ! source "${cacheDir}/wallbash/shell-colors"; then
  print_log -sec "chrome" -err "Failed to load" " 'shell-colors' file"
  exit 1
fi

THEME_NAME="Wallbash"
THEME_DIR="${cacheDir}/wallbash/$THEME_NAME-chrome-theme"

if [ -e "$THEME_DIR" ]; then
  rm -fr "$THEME_DIR"
fi
# Converts hex colors into rgb joined with comma
# #fff -> 255, 255, 255
hexToRgb() {
  # Remove '#' character from hex color #fff -> fff
  plain=${1#*#}
  printf "%d, %d, %d" "0x${plain:0:2}" "0x${plain:2:2}" "0x${plain:4:2}"
}
prepare() {
  if [ -d "$THEME_DIR" ]; then
    rm -rf "$THEME_DIR"
  fi

  mkdir "$THEME_DIR"
  mkdir "$THEME_DIR/images"

  # Copy wallpaper so it can be used in theme
  background_image="images/theme_ntp_background_norepeat.png"
  # shellcheck disable=SC2154
  cp "${cacheDir}/wall.set" "$THEME_DIR/$background_image"

}

# shellcheck disable=SC2154
background=$(hexToRgb "${wallbash_pry1}")
# shellcheck disable=SC2154
foreground=$(hexToRgb "${wallbash_txt1}")
# shellcheck disable=SC2154
accent=$(hexToRgb "${wallbash_1xa1}")
# shellcheck disable=SC2154
secondary=$(hexToRgb "${wallbash_pry2}")

# Generates the manifest.json file
#  TODO Make this them better
generate() {
  # Theme template
  cat >"$THEME_DIR/manifest.json" <<EOF
    {
      "manifest_version": 3,
      "version": "1.0",
      "name": "$THEME_NAME Theme",
      "theme": {
        "images": {
          "theme_ntp_background" : "$background_image"
        },
        "colors": {
          "frame": [$background],
          "frame_inactive": [$background],
          "toolbar": [$accent],
          "ntp_text": [$foreground],
          "ntp_link": [$accent],
          "ntp_section": [$secondary],
          "button_background": [$foreground],
          "toolbar_button_icon": [$foreground],
          "toolbar_text": [$foreground],
          "omnibox_background": [$background],
          "omnibox_text": [$foreground]
        },
        "properties": {
          "ntp_background_alignment": "bottom"
        }
      }
    }
EOF
}

prepare
generate
print_log -sec "wallbash" -stat "generated" "'Wallbash Chrome Theme' at '$THEME_DIR'"
