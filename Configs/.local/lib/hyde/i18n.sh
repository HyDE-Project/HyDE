#!/usr/bin/env bash

_hyde_i18n_normalize_locale() {
    local lang="${1:-${HYDE_LANG:-${I18N_LANGUAGE:-${LC_MESSAGES:-${LANG:-en}}}}}"

    lang="${lang%%.*}"
    lang="${lang%%@*}"

    case "$lang" in
        zh | zh_CN | zh_SG)
            printf '%s\n' "zh_CN"
            ;;
        zh_TW | zh_HK | zh_MO)
            printf '%s\n' "zh_TW"
            ;;
        "" | C | POSIX)
            printf '%s\n' "en"
            ;;
        *)
            printf '%s\n' "$lang"
            ;;
    esac
}

_hyde_i18n_base_dir() {
    if [[ -n "${SHARE_DIR:-}" ]]; then
        printf '%s\n' "${SHARE_DIR%/}/hyde/i18n"
        return
    fi

    printf '%s\n' "${XDG_DATA_HOME:-$HOME/.local/share}/hyde/i18n"
}

_hyde_i18n_file() {
    local locale base
    locale="$(_hyde_i18n_normalize_locale)"
    base="$(_hyde_i18n_base_dir)"

    if [[ -r "$base/$locale.json" ]]; then
        printf '%s\n' "$base/$locale.json"
        return
    fi

    printf '%s\n' "$base/en.json"
}

_hyde_i18n_lookup() {
    local file="$1"
    local key="$2"

    command -v jq >/dev/null 2>&1 || return 1
    [[ -r "$file" ]] || return 1

    jq -r --arg key "$key" '.[$key] // empty' "$file" 2>/dev/null
}

_t() {
    local key="${1:-}"
    local default="${2:-$key}"
    if (( $# >= 2 )); then
        shift 2
    else
        shift "$#"
    fi

    local base file fallback msg
    base="$(_hyde_i18n_base_dir)"
    file="$(_hyde_i18n_file)"
    fallback="$base/en.json"

    msg="$(_hyde_i18n_lookup "$file" "$key" || true)"
    if [[ -z "$msg" && "$file" != "$fallback" ]]; then
        msg="$(_hyde_i18n_lookup "$fallback" "$key" || true)"
    fi
    [[ -n "$msg" ]] || msg="$default"

    if (( $# > 0 )); then
        # shellcheck disable=SC2059
        printf "$msg" "$@"
    else
        printf '%s' "$msg"
    fi
}

_tn() {
    _t "$@"
    printf '\n'
}
