export const quickLaunchItems = [
    {
        "name": "Find",
        "command": "fish -c fy.sh"
    },
    {
        "name": "Code",
        "command": "code &"
    },
    {
        "name": "Nvim",
        "command": "kitty nvim ~/.config &"
    },
    {
        "name": "Ob",
        "command": "flatpak run md.obsidian.Obsidian"
    },
    {
        "name": "Themes",
        "command": "pkill -x rofi || ~/.local/share/bin/themeselect.sh"
    },
]