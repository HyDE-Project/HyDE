#!/usr/bin/env bash
#|---/ /+------------------+---/ /|#
#|--/ /-| Global functions |--/ /-|#
#|-/ /--| Prasanth Rangan  |-/ /--|#
#|/ /---+------------------+/ /---|#

set -e

scrDir="$(dirname "$(realpath "$0")")"
cloneDir="$(dirname "${scrDir}")" # fallback, we will use CLONE_DIR now
cloneDir="${CLONE_DIR:-${cloneDir}}"
confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
cacheDir="${XDG_CACHE_HOME:-$HOME/.cache}/hyde"
aurList=("yay" "paru" "pikaur" "trizen" "aura" "pakku" "pacaur" "aurman" "pacseek" "aurutils")
shlList=("zsh" "fish")
pacmanCmd=${cloneDir}/Configs/.local/lib/hyde/pm.sh

export cloneDir
export confDir
export cacheDir
export aurList
export shlList

pkg_installed() {
    local PkgIn=$1

    if pacman -Q "${PkgIn}" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

chk_list() {
    vrType="$1"
    local inList=("${@:2}")
    for pkg in "${inList[@]}"; do
        if pkg_installed "${pkg}"; then
            printf -v "${vrType}" "%s" "${pkg}"
            # shellcheck disable=SC2163 # dynamic variable
            export "${vrType}" # export the variable // reference of the variable
            return 0
        fi
    done
    # print_log -sec "install" -warn "no package found in the list..." "${inList[@]}"
    return 1
}

aur_health_check() {
    local helper="$1"
    if command -v "${helper}" &>/dev/null; then
        if "${helper}" --version &>/dev/null; then
            return 0
        fi
    fi
    return 1
}

chk_shell() {
    local candidate="${1:-}"
    local shell
    [ -n "${candidate}" ] || return 1
    for shell in "${shlList[@]}"; do
        [ "${shell}" = "${candidate}" ] && return 0
    done
    return 1
}

login_shell() {
    local entry
    entry="$(getent passwd "${USER}")" || return 1
    [ -n "${entry##*:}" ] || return 1
    basename "${entry##*:}"
}

shell_listed() {
    local wanted listed
    local shells="${2:-/etc/shells}"
    # The same shell is listed under /bin or /usr/bin, so both sides resolve.
    wanted="$(realpath -e "${1}" 2>/dev/null)" || return 1
    [ -f "${shells}" ] || return 0
    # The guard keeps a last line that carries no trailing newline.
    while IFS= read -r listed || [ -n "${listed}" ]; do
        listed="${listed%%#*}"
        listed="${listed//[[:space:]]/}"
        [ -n "${listed}" ] || continue
        [ "$(realpath -e "${listed}" 2>/dev/null)" = "${wanted}" ] && return 0
    done < "${shells}"
    return 1
}

resolve_shell() {
    local current
    chk_shell "${myShell:-}" && return 0
    # The shell already logged in with outranks the order of the list.
    current="$(login_shell || true)"
    if chk_shell "${current}"; then
        myShell="${current}"
        export myShell
        return 0
    fi
    chk_list "myShell" "${shlList[@]}"
}

pkg_available() {
    local PkgIn=$1

    if ${pacmanCmd} query "${PkgIn}" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

aur_available() {
    local PkgIn=$1

    # shellcheck disable=SC2154
    if ${pacmanCmd} info "${PkgIn}" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

nvidia_detect() {
    readarray -t dGPU < <(lspci -k | grep -E "(VGA|3D)" | awk -F ': ' '{print $NF}')
    if [ "${1}" == "--verbose" ]; then
        for indx in "${!dGPU[@]}"; do
            echo -e "\033[0;32m[gpu$indx]\033[0m detected :: ${dGPU[indx]}"
        done
        return 0
    fi
    if [ "${1}" == "--drivers" ]; then
        while read -r -d ' ' nvcode; do
            awk -F '|' -v nvc="${nvcode}" 'substr(nvc,1,length($3)) == $3 {split(FILENAME,driver,"/"); print driver[length(driver)],"\nnvidia-utils"}' "${scrDir}"/nvidia-db/nvidia*dkms
        done <<<"${dGPU[@]}"
        return 0
    fi
    if grep -iq nvidia <<<"${dGPU[@]}"; then
        return 0
    else
        return 1
    fi
}

prompt_timer() {
    set +e
    unset PROMPT_INPUT
    local timsec=$1
    local msg=$2
    while [[ ${timsec} -ge 0 ]]; do
        echo -ne "\r :: ${msg} (${timsec}s) : "
        read -rt 1 -n 1 PROMPT_INPUT && break
        ((timsec--))
    done
    export PROMPT_INPUT
    echo ""
    set -e
}
print_log() {
    local executable="${0##*/}"
    local logFile="${cacheDir}/logs/${HYDE_LOG}/${executable}.log"
    mkdir -p "$(dirname "${logFile}")"
    local section=${log_section:-}
    {
        [ -n "${section}" ] && echo -ne "\e[32m[$section] \e[0m"
        while (("$#")); do
            case "$1" in
            -r | +r)
                echo -ne "\e[31m$2\e[0m"
                shift 2
                ;; # Red
            -g | +g)
                echo -ne "\e[32m$2\e[0m"
                shift 2
                ;; # Green
            -y | +y)
                echo -ne "\e[33m$2\e[0m"
                shift 2
                ;; # Yellow
            -b | +b)
                echo -ne "\e[34m$2\e[0m"
                shift 2
                ;; # Blue
            -m | +m)
                echo -ne "\e[35m$2\e[0m"
                shift 2
                ;; # Magenta
            -c | +c)
                echo -ne "\e[36m$2\e[0m"
                shift 2
                ;; # Cyan
            -wt | +w)
                echo -ne "\e[37m$2\e[0m"
                shift 2
                ;; # White
            -n | +n)
                echo -ne "\e[96m$2\e[0m"
                shift 2
                ;; # Neon
            -stat)
                echo -ne "\e[30;46m $2 \e[0m :: "
                shift 2
                ;; # status
            -crit)
                echo -ne "\e[97;41m $2 \e[0m :: "
                shift 2
                ;; # critical
            -warn)
                echo -ne "WARNING :: \e[30;43m $2 \e[0m :: "
                shift 2
                ;; # warning
            +)
                echo -ne "\e[38;5;$2m$3\e[0m"
                shift 3
                ;; # Set color manually
            -sec)
                echo -ne "\e[32m[$2] \e[0m"
                shift 2
                ;; # section use for logs
            -err)
                echo -ne "ERROR :: \e[4;31m$2 \e[0m"
                shift 2
                ;; #error
            *)
                echo -ne "$1"
                shift
                ;;
            esac
        done
        echo ""
    } | if [ -n "${HYDE_LOG}" ]; then
        tee >(sed 's/\x1b\[[0-9;]*m//g' >>"${logFile}")
    else
        cat
    fi
}

# Creates the Python environment and syncs it against this checkout's lock.
#
# The dot deployment, the dependency checks and hyde-shell all run out of that
# environment, and the revisions they run are the ones this checkout pins. A
# run that skips this works with whatever was installed the last time it did
# not, so a corrected pin never reaches the machine that needs it. It lives
# here rather than in a script of its own so the pre-install path and the
# installer cannot drift apart.
setup_python_env() {
    local pyutils="${cloneDir}/Configs/.local/lib/hyde/pyutils/python_env.py"
    local python_env_dir="${HOME}/.local/state/hyde/python_env"

    if [ "${flg_DryRun:-0}" -eq 1 ]; then
        print_log -y "[PYTHON] " -b "dry-run :: " "Would setup Python environment"
        return 0
    fi

    if ! python3 "${pyutils}" create; then
        print_log -err "[PYTHON] " -crit "ERROR" "Failed to create the Python environment; the error above says why"
        print_log -err "[PYTHON] " -crit "HINT" "A missing python3 or base-devel is the usual cause"
        return 1
    fi

    if ! "${python_env_dir}/bin/python" "${pyutils}" sync; then
        print_log -err "[PYTHON] " -crit "ERROR" "Failed to install dependencies"
        return 1
    fi

    print_log -g "[PYTHON] " -b "complete :: " "Environment setup complete"
}

# Runs each migration in "$1" missing from the record in "$2", in version order,
# and records the ones that exit zero. Migrations must therefore be safe to run
# on a machine that has no record yet, which replays all of them once.
run_pending_migrations() {
    local migrationDir="$1"
    local stateFile="$2"
    local migrationFile
    local applied=0
    local pending=0

    [ -d "${migrationDir}" ] || return 0
    find "${migrationDir}" -maxdepth 1 -type f | grep -q . || return 0

    mkdir -p "$(dirname "${stateFile}")"
    [ -f "${stateFile}" ] || : >"${stateFile}"

    while read -r migrationFile; do
        [ -n "${migrationFile}" ] || continue
        grep -qxF "${migrationFile}" "${stateFile}" && continue
        pending=$((pending + 1))
        echo "Found migration file: ${migrationFile}"
        # stdin is closed for the migration: inheriting the loop's stdin let one
        # that reads input swallow the names of every migration after it.
        if sh "${migrationDir}/${migrationFile}" </dev/null; then
            printf '%s\n' "${migrationFile}" >>"${stateFile}"
            applied=$((applied + 1))
        else
            print_log -warn "Migration" "Failed to execute ${migrationFile}"
        fi
    done < <(find "${migrationDir}" -maxdepth 1 -type f -printf '%f\n' | sort -V)

    [ "${pending}" -gt 0 ] || echo "No outstanding migrations in ${migrationDir}."
    return 0
}

# Moves Hyprland's own generated example config out of the way so the deploy
# that follows can put HyDE's hyprland.lua template there instead (#2132).
#
# Hyprland writes that example when it starts and finds no config at all, e.g.
# after an install that failed before the dots were deployed. hyprland.lua is
# deployed with the preserve action, so HyDE then never replaces it, and the
# v26.8.1 migration only prepends the loader to it. The result loads HyDE and
# then the whole example on top as the user's override layer: Hyprland's
# default border colors and animations over every theme, and a second
# XF86AudioMute bind with different flags, so one press toggles mute twice.
#
# This runs on every restore rather than as a migration: a migration is
# recorded as applied on the first install, before a failed deploy can leave
# the window in which Hyprland generates the file.
#
# Only a byte-for-byte untouched example is moved: Hyprland's header followed
# by the example the installed Hyprland ships, optionally behind the exact
# v26.8.1 loader. Any edit, including one inside the header or the loader,
# keeps the file in place, as does an example from another Hyprland release;
# those only get a warning (review on #2134). Comparing against the installed
# example rather than stored hashes needs no update per Hyprland release. Even
# a verified example is moved, not deleted.
#
# A symlink is left alone: it belongs to a dotfile manager, and replacing it
# would take the machine off the managed copy.

# Hyprland's AUTOGENERATED_PREFIX_LUA (src/config/lua/DefaultConfig.hpp),
# written in front of the example; its leading newline is part of the file.
HYPR_AUTOGEN_PREFIX='
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- AUTOGENERATED HYPRLAND CONFIG.                        --
-- EDIT THIS CONFIG ACCORDING TO THE WIKI INSTRUCTIONS.  --
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

hl.config({ autogenerated = true }) -- remove this line to remove the warning

'
# What Scripts/migrations/v26.8.1.sh prepends, blank line included; the tests
# check the two copies stay identical.
HYDE_LUA_LOADER='-- Hyprland loads this file when it is started without a config, and it prefers
-- it over hyprland.conf. HyDE loads it too, last, as the override layer below.
-- The block keeps the two apart: hyde.lua sets `hyde` on its first line, so it
-- runs only when this file is the entry point and HyDE has not been loaded.
-- Removing it leaves a session with a cursor and nothing else.
if not hyde then
	local share = os.getenv("XDG_DATA_HOME") or (os.getenv("HOME") .. "/.local/share")
	local entry = share .. "/hypr/hyde.lua"
	local handle = io.open(entry, "r")
	if not handle then
		error("HyDE is not installed at " .. entry .. ". Run install.sh -r, or point Hyprland at your own config.")
	end
	handle:close()
	dofile(entry)
end

'

# The example the installed Hyprland embeds, which packages also install as
# <prefix>/share/hypr/hyprland.lua; the prefix is taken from the binary so
# /usr/local and Nix store builds are found too.
hypr_example_config() {
    local bin example
    bin=$(readlink -f "$(command -v Hyprland 2>/dev/null)" 2>/dev/null) || bin=""
    for example in ${bin:+"${bin%/bin/*}/share/hypr/hyprland.lua"} /usr/share/hypr/hyprland.lua; do
        [ -f "${example}" ] && [ -s "${example}" ] && [ -r "${example}" ] && {
            echo "${example}"
            return 0
        }
    done
    return 1
}

retire_autogenerated_hypr_config() {
    local target="${1:-${XDG_CONFIG_HOME:-${HOME}/.config}/hypr/hyprland.lua}"
    local backupRoot="${2:-${XDG_STATE_HOME:-${HOME}/.local/state}/hyde/backup/hyprland-autogenerated}"
    local example="${3:-}"
    local backupDir loader matched=0

    # Recorded for restore_retired_hypr_config; cleared first so a run that
    # retires nothing never hands back an older run's file.
    retiredHyprConfig=""

    [ -f "${target}" ] && [ ! -L "${target}" ] || return 0
    # Most files are the user's own config; only one carrying Hyprland's header
    # line is worth comparing, or warning about.
    grep -qx -- '-- AUTOGENERATED HYPRLAND CONFIG\. *--' "${target}" 2>/dev/null || return 0

    [ -n "${example}" ] || example=$(hypr_example_config) || example=""
    if [ -f "${example}" ] && [ -s "${example}" ]; then
        # Streamed into cmp rather than built in a variable: command
        # substitution would drop trailing newlines and hide an edit there.
        for loader in "" "${HYDE_LUA_LOADER}"; do
            if { printf '%s%s' "${loader}" "${HYPR_AUTOGEN_PREFIX}" && cat -- "${example}"; } |
                cmp -s -- "${target}" -; then
                matched=1
                break
            fi
        done
    fi

    if [ "${matched}" -ne 1 ]; then
        print_log -warn "Hyprland" "${target} carries Hyprland's generated-config header but could not be verified as an untouched example (edited, from another Hyprland release, or no example found at <prefix>/share/hypr/hyprland.lua); left in place. Review it: anything it sets overrides HyDE's theme and keybinds"
        return 0
    fi

    if [ "${flg_DryRun:-0}" -eq 1 ]; then
        print_log -y "[HYPRLAND] " -b "dry-run :: " "Would move Hyprland's generated example config ${target} aside"
        return 0
    fi

    # A fresh directory per run, so a second run never overwrites the first
    # backup even within the same second.
    if ! mkdir -p "${backupRoot}" 2>/dev/null ||
        ! backupDir=$(mktemp -d "${backupRoot}/$(date +%Y%m%d-%H%M%S).XXXX" 2>/dev/null) ||
        ! mv "${target}" "${backupDir}/hyprland.lua"; then
        print_log -warn "Hyprland" "Could not move Hyprland's generated example config ${target} aside; it still overrides HyDE's theme and keybinds"
        return 1
    fi

    retiredHyprConfig="${backupDir}/hyprland.lua"
    print_log -g "[HYPRLAND] " -b "replaced :: " "Hyprland's generated example config, which overrode HyDE; your copy is at ${retiredHyprConfig}"
    return 0
}

# Puts the file retire_autogenerated_hypr_config moved aside back when the
# deploy left nothing in its place. Hyprland's example with HyDE's loader in
# front still gives a working session; no hyprland.lua at all gives the
# pre-Lua leftovers or yet another generated example. The backup is copied,
# not moved, so it stays where the log line said it would be.
restore_retired_hypr_config() {
    local target="${1:-${XDG_CONFIG_HOME:-${HOME}/.config}/hypr/hyprland.lua}"

    [ -n "${retiredHyprConfig:-}" ] && [ -f "${retiredHyprConfig}" ] || return 0
    [ -e "${target}" ] || [ -L "${target}" ] && return 0

    if ! cp -p "${retiredHyprConfig}" "${target}"; then
        print_log -warn "Hyprland" "The deploy left no ${target}, and putting ${retiredHyprConfig} back failed"
        return 1
    fi
    print_log -y "[HYPRLAND] " -b "restored :: " "The deploy did not replace ${target}; put the previous file back"
    return 0
}
