#!/usr/bin/env bash
# Make a bundled SDDM greeter theme show date and time in the system locale.
#
# Candy and Corners hardcode an English 12h time and date format in their
# theme.conf, so a 24h locale still gets "05:05 PM" on the login screen.
# Instead of editing the vendor files in place, HyDE keeps a patched copy per
# theme (blank formats, plus a QML fallback for Corners) and lays it over the
# extracted theme.
#
# Usage: sddm.locale.sh /usr/share/sddm/themes/Candy
#   HYDE_SDDM_OVERLAY  directory holding one overlay folder per theme name
#                      (default: ${XDG_DATA_HOME:-~/.local/share}/hyde/sddm)
#
# A theme without an overlay is left alone, so this is safe to call for any
# theme extracted from a color theme's Sddm_* archive.

themeDir="${1%/}"
overlayRoot="${HYDE_SDDM_OVERLAY:-${XDG_DATA_HOME:-$HOME/.local/share}/hyde/sddm}"

if [ -z "$themeDir" ] || [ ! -d "$themeDir" ]; then
    echo "sddm.locale.sh: not a theme directory: '${1}'" >&2
    exit 1
fi

themeName="$(basename "$themeDir")"
# The name comes from a tarball's top-level entry; never let it climb out of
# the overlay root.
case "$themeName" in
'' | . | .. | *[!A-Za-z0-9._-]*)
    echo "sddm.locale.sh: refusing theme name '${themeName}'" >&2
    exit 1
    ;;
esac

overlay="$overlayRoot/$themeName"
[ -d "$overlay" ] || exit 0

if [ -w "$themeDir" ]; then
    cp -rf "$overlay"/. "$themeDir"/
else
    sudo cp -rf "$overlay"/. "$themeDir"/
fi
