#!/usr/bin/env bash
# Session menu via rofi (GTK, no wlogout/AUR).
# Same interface as before: `logoutlaunch.sh [style]` toggles the menu.
# The optional style arg is accepted for compatibility and ignored.

if pgrep -f "rofi.*-p Session" >/dev/null; then
    pkill -f "rofi.*-p Session"
    exit 0
fi

rofi_theme="$HOME/.config/rofi/theme.rasi"
[ -r "$rofi_theme" ] || rofi_theme=""
theme_args=()
[ -n "$rofi_theme" ] && theme_args=(-theme "$rofi_theme")

opt=$(printf 'Lock\nLog out\nSuspend\nHibernate\nReboot\nShut down' \
    | rofi -dmenu -p "Session" "${theme_args[@]}") || exit 0

case "$opt" in
    Lock)
        if command -v hyde-shell >/dev/null 2>&1; then
            hyde-shell lock-session
        else
            hyprlock
        fi
        ;;
    "Log out")
        if command -v uwsm >/dev/null 2>&1 && uwsm check is-active; then
            uwsm stop
        else
            hyprctl dispatch exit
        fi
        ;;
    Suspend) systemctl suspend ;;
    Hibernate) systemctl hibernate ;;
    Reboot) systemctl reboot ;;
    "Shut down") systemctl poweroff ;;
esac
