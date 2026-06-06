#!/usr/bin/env bash

if ! declare -F _t >/dev/null; then
    # shellcheck source=/dev/null
    if [[ -n "${LIB_DIR:-}" && -r "$LIB_DIR/hyde/i18n.sh" ]]; then
        source "$LIB_DIR/hyde/i18n.sh"
    else
        _t() {
            local key="${1:-}"
            local default="${2:-$key}"
            if (( $# >= 2 )); then
                shift 2
            else
                shift "$#"
            fi
            if (( $# > 0 )); then
                printf "$default" "$@"
            else
                printf '%s' "$default"
            fi
        }
        _tn() {
            _t "$@"
            printf '\n'
        }
    fi
fi

show_help() {
    _tn "wallpaper.help.usage" "Usage: %s --[options|flags] [parameters]" "$(basename "$0")"
    _tn "wallpaper.help.options_title" "options:"
    printf '    %-27s %s\n' "-j, --json" "$(_t "wallpaper.help.json" "List wallpapers in JSON format to STDOUT")"
    printf '    %-27s %s\n' "-S, --select" "$(_t "wallpaper.help.select" "Select wallpaper using rofi")"
    printf '    %-27s %s\n' "-n, --next" "$(_t "wallpaper.help.next" "Set next wallpaper")"
    printf '    %-27s %s\n' "-p, --previous" "$(_t "wallpaper.help.previous" "Set previous wallpaper")"
    printf '    %-27s %s\n' "-r, --random" "$(_t "wallpaper.help.random" "Set random wallpaper")"
    printf '    %-27s %s\n' "-s, --set <file>" "$(_t "wallpaper.help.set" "Set specified wallpaper")"
    printf '    %-27s %s\n' "    --start" "$(_t "wallpaper.help.start" "Start/apply current wallpaper to backend")"
    printf '    %-27s %s\n' "-g, --get" "$(_t "wallpaper.help.get" "Get current wallpaper of specified backend")"
    printf '    %-27s %s\n' "-o, --output <file>" "$(_t "wallpaper.help.output" "Copy current wallpaper to specified file")"
    printf '    %-27s %s\n' "    --multi-select" "$(_t "wallpaper.help.multi_select" "Enable multi-selection in select mode (works for --output only)")"
    printf '    %-27s %s\n' "    --link" "$(_t "wallpaper.help.link" "Resolve the linked wallpaper according to the theme")"
    printf '    %-27s %s\n' "-t  --filetypes <types>" "$(_t "wallpaper.help.filetypes" "Specify file types to override (colon-separated ':')")"
    printf '    %-27s %s\n' "    --cache <mode> [arg]" "$(_t "wallpaper.help.cache" "Build wallpaper cache")"
    printf '    %-27s %s\n' "" "$(_t "wallpaper.help.cache_modes" "modes: current, wall <file>, theme <name>, full")"
    printf '    %-27s %s\n' "-h, --help" "$(_t "wallpaper.help.help" "Display this help message")"
    printf '\n'
    _tn "wallpaper.help.flags_title" "flags:"
    printf '    %-27s %s\n' "-b, --backend <backend>" "$(_t "wallpaper.help.backend" "Set wallpaper backend to use (awww, hyprpaper, etc.)")"
    printf '    %-27s %s\n' "-G, --global" "$(_t "wallpaper.help.global" "Set wallpaper as global")"
    printf '\n\n'
    _tn "wallpaper.help.notes_title" "notes:"
    printf '       %s\n' "$(_t "wallpaper.help.note_backend_1" "--backend <backend> is also used to cache wallpapers/background images, e.g. hyprlock")"
    printf '           %s\n' "$(_t "wallpaper.help.note_backend_2" "when '--backend hyprlock' is used, the wallpaper will be cached in")"
    printf '           ~/.cache/hyde/wallpapers/hyprlock.png\n'
    printf '\n'
    printf '       %s\n' "$(_t "wallpaper.help.note_global_1" "--global flag is used to set the wallpaper as global, this means all")"
    printf '         %s\n' "$(_t "wallpaper.help.note_global_2" "thumbnails will be updated to reflect the new wallpaper")"
    printf '\n'
    printf '       %s\n' "$(_t "wallpaper.help.note_output_1" "--output <path> is used to copy the current wallpaper to the specified path")"
    printf '            %s\n' "$(_t "wallpaper.help.note_output_2" "We can use this to have a copy of the wallpaper to '/var/tmp' where sddm or")"
    printf '            %s\n' "$(_t "wallpaper.help.note_output_3" "any systemwide application can access it")"
    exit 0
}
