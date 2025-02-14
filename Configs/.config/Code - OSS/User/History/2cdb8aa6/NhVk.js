export const quickLaunchItems = [
    {
        "name": "GitHub",
        "command": "github-desktop &"
    },
    {
        "name": "Terminal",
        "command": "kitty &"
    },
    {
        "name": "Youtube + Github",
        "command": "xdg-open 'https://youtube.com/' && xdg-open 'https://github.com/' &"
    },
    {
        "name": "File Explorer",
        "command": "dolphin &"
    },
    {
        "name": "Change Theme",
        "command": "pkill -x rofi || ~/.local/share/bin/themeselect.sh"
    },
]