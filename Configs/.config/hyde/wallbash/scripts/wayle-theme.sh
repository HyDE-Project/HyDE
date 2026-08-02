#!/usr/bin/env bash
# wayle-theme.sh - Bridge Hyde wallbash colors to wayle palette
# Called by wayle.dcol wallbash hook on wallpaper/theme change
# Receives dcol_* environment variables from wallbash (hex without #)

command -v wayle >/dev/null 2>&1 || exit 0
pgrep -x wayle >/dev/null 2>&1 || exit 0
[[ -z "$dcol_pry1" ]] && exit 0

# Map wallbash dcol colors to wayle palette slots
# dcol values are raw hex (no # prefix)
wayle config set styling.palette.bg "#${dcol_pry1}" 2>/dev/null
wayle config set styling.palette.surface "#${dcol_pry2}" 2>/dev/null
wayle config set styling.palette.elevated "#${dcol_pry3}" 2>/dev/null
wayle config set styling.palette.fg "#${dcol_txt1}" 2>/dev/null
wayle config set styling.palette.fg-muted "#${dcol_3xa6}" 2>/dev/null
wayle config set styling.palette.primary "#${dcol_1xa7}" 2>/dev/null
wayle config set styling.palette.red "#${dcol_1xa8}" 2>/dev/null
wayle config set styling.palette.yellow "#${dcol_1xa6}" 2>/dev/null
wayle config set styling.palette.green "#${dcol_2xa7}" 2>/dev/null
wayle config set styling.palette.blue "#${dcol_3xa7}" 2>/dev/null
