#!/usr/bin/env bash
# Source this file in any script that needs localization support. It sets up the _T associative array with translations based on the user's locale.

# Extract the system locale and set HYDE_LOCALE to the first two characters (language code)
_raw_sys_lang="${LC_ALL:-${LANG:-en}}"
export HYDE_LOCALE="${HYDE_LOCALE:-${_raw_sys_lang:0:2}}"
export HYDE_LOCALE="${HYDE_LOCALE,,}"
#? Handles edge cases where locale is set to "C" or "POSIX" which are not actual languages
[[ "$HYDE_LOCALE" == "c" || "$HYDE_LOCALE" == "po" ]] && export HYDE_LOCALE="en"

# Initialize the _T associative array for translations
declare -A _T 2>/dev/null || : # Localization support
[[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/hyde/locale/${HYDE_LOCALE}.sh" ]] && source "${XDG_DATA_HOME:-$HOME/.local/share}/hyde/locale/${HYDE_LOCALE}.sh"
[[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/hyde/locale/${HYDE_LOCALE}.sh" ]] && source "${XDG_CONFIG_HOME:-$HOME/.config}/hyde/locale/${HYDE_LOCALE}.sh"

# method overrides for localization

# Locale-aware notification handler
send_notifs() {
    local args=()
    for arg in "$@"; do
        # If it's not a flag (starts with -), try to translate it
        if [[ ! "$arg" =~ ^- ]]; then
            args+=("${_T[$arg]:-$arg}")
        else
            args+=("$arg")
        fi
    done
    notify-send "${args[@]}" &
}

# Locale-aware logging handler
print_log_L() {
    while (("$#")); do
        case "$1" in
        -r | +r | -g | +g | -y | +y | -b | +b | -m | +m | -c | +c | -wt | +w | -n | +n | -stat | -crit | -warn | -sec | -err)
            # $2 is the message. Translate it or use original.
            local msg="${_T[$2]:-$2}"
            case "$1" in
            -r | +r) echo -ne "\e[31m$msg\e[0m" >&2 ;;
            -g | +g) echo -ne "\e[32m$msg\e[0m" >&2 ;;
            -y | +y) echo -ne "\e[33m$msg\e[0m" >&2 ;;
            -b | +b) echo -ne "\e[34m$msg\e[0m" >&2 ;;
            -m | +m) echo -ne "\e[35m$msg\e[0m" >&2 ;;
            -c | +c) echo -ne "\e[36m$msg\e[0m" >&2 ;;
            -wt | +w) echo -ne "\e[37m$msg\e[0m" >&2 ;;
            -n | +n) echo -ne "\e[96m$msg\e[0m" >&2 ;;
            -stat) echo -ne "\e[4;30;46m $msg \e[0m :: " >&2 ;;
            -crit) echo -ne "\e[30;41m $msg \e[0m :: " >&2 ;;
            -warn) echo -ne "WARNING :: \e[30;43m $msg \e[0m :: " >&2 ;;
            -sec) echo -ne "\e[32m[$msg] \e[0m" >&2 ;;
            -err) echo -ne "ERROR :: \e[4;31m$msg \e[0m" >&2 ;;
            esac
            shift 2
            ;;
        +)
            # Custom color: $3 is the message
            local msg="${_T[$3]:-$3}"
            echo -ne "\e[38;5;$2m$msg\e[0m" >&2
            shift 3
            ;;
        *)
            # Standard text
            echo -ne "${_T[$1]:-$1}" >&2
            shift
            ;;
        esac
    done
    echo "" >&2
}

export -f send_notifs print_log_L
