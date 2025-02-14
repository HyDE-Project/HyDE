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
        "name": "Files",
        "command": "dolphin &"
    },
    {
        "name": "Themes",
        "command": "pkill -x rofi || ~/.local/share/bin/themeselect.sh"
    },
]