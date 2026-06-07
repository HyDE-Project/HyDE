#!/usr/bin/env bash
# Source this file in scripts that need lightweight gettext-style localization.

_hyde_l10n_normalize_locale() {
    local lang="${1:-${HYDE_LANG:-${I18N_LANGUAGE:-${LC_MESSAGES:-${LANG:-en}}}}}"
    lang="${lang%%:*}"
    lang="${lang%%.*}"
    lang="${lang%%@*}"
    lang="${lang//-/_}"

    case "${lang,,}" in
        "" | c | posix)
            printf '%s\n' "en"
            ;;
        zh | zh_cn | zh_sg)
            printf '%s\n' "zh_CN"
            ;;
        *)
            printf '%s\n' "$lang"
            ;;
    esac
}

_hyde_l10n_locale_dir() {
    if [[ -n "${SHARE_DIR:-}" ]]; then
        printf '%s\n' "${SHARE_DIR%/}/hyde/locale"
        return
    fi

    printf '%s\n' "${XDG_DATA_HOME:-$HOME/.local/share}/hyde/locale"
}

_hyde_l10n_source_map() {
    local map_file="$1"
    [[ -r "$map_file" ]] || return 0
    # shellcheck source=/dev/null
    source "$map_file"
}

DESKTOP_LANG="$(_hyde_l10n_normalize_locale)"
export DESKTOP_LANG

declare -gA _T 2>/dev/null || declare -A _T 2>/dev/null || :
_hyde_l10n_source_map "$(_hyde_l10n_locale_dir)/${DESKTOP_LANG}.sh"
_hyde_l10n_source_map "${XDG_CONFIG_HOME:-$HOME/.config}/hyde/locale/${DESKTOP_LANG}.sh"

hyde_gettext() {
    local msg="${1:-}"
    if [[ -n "$msg" && -n "${_T[$msg]+_}" ]]; then
        printf '%s' "${_T[$msg]}"
        return
    fi
    printf '%s' "$msg"
}

# method overrides for localization

# Locale-aware notification handler
send_notifs() {
    local args=()
    for arg in "$@"; do
        # If it's not a flag (starts with -), try to translate it
        if [[ ! "$arg" =~ ^- ]]; then
            args+=("$(hyde_gettext "$arg")")
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
            local msg
            msg="$(hyde_gettext "$2")"
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
            local msg
            msg="$(hyde_gettext "$3")"
            echo -ne "\e[38;5;$2m$msg\e[0m" >&2
            shift 3
            ;;
        *)
            # Standard text
            echo -ne "$(hyde_gettext "$1")" >&2
            shift
            ;;
        esac
    done
    echo "" >&2
}

export -f hyde_gettext send_notifs print_log_L
