#!/usr/bin/env bash
# Source this file in any script that needs localization support. It sets up the _T associative array with translations based on the user's locale.

# Resolve the effective locale with app overrides first, then desktop/system defaults.
_raw_sys_lang="${HYDE_LANG:-${DESKTOP_LANG:-${LC_ALL:-${LC_MESSAGES:-${LANG:-en_US}}}}}"
_raw_sys_lang="${_raw_sys_lang%%.*}" # Remove encoding suffix (e.g., .UTF-8)
_raw_sys_lang="${_raw_sys_lang%%@*}" # Remove modifier suffix (e.g., @calendar)
_raw_sys_lang="${_raw_sys_lang//_/-}"
_raw_sys_lang="${_raw_sys_lang,,}"

# Keep the full tag for region-aware packs, but normalize the app language to the primary code.
case "$_raw_sys_lang" in
""|c|posix)
    export DESKTOP_LOCALE="en"
    export DESKTOP_LANG="en"
    ;;
*)
    export DESKTOP_LOCALE="$_raw_sys_lang"
    export DESKTOP_LANG="${_raw_sys_lang%%-*}"
    [[ -z "$DESKTOP_LANG" ]] && export DESKTOP_LANG="en"
    ;;
esac

# Initialize translation lookup table
declare -A _T 2>/dev/null || true

# Load translation dictionaries (full locale first, then primary language).
_loc_keys=("$DESKTOP_LOCALE")
[[ "$DESKTOP_LANG" != "$DESKTOP_LOCALE" ]] && _loc_keys+=("$DESKTOP_LANG")
for _loc_key in "${_loc_keys[@]}"; do
    for _loc_file in \
        "${XDG_DATA_HOME:-$HOME/.local/share}/hyde/locale/${_loc_key}.sh" \
        "${XDG_CONFIG_HOME:-$HOME/.config}/hyde/locale/${_loc_key}.sh"
    do
        [[ -r "$_loc_file" ]] && source "$_loc_file"
    done
done
unset _loc_file
unset _loc_key
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
print_T() {
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


export -f send_notifs print_T
