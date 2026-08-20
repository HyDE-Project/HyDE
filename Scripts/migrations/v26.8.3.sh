#!/usr/bin/env sh

# The theme switch used to sanitize "hypr.theme" into "themes/theme.conf" and
# the colour pass used to write "themes/wallbash.conf". Both are generated for
# Hyprland alone, and Hyprland now reads the Lua state instead, so neither file
# is written any more. What is left behind is not inert: whatever sources them
# keeps applying the last theme that was ever generated, silently overriding
# the Lua state with stale borders, gaps and fonts.
#
# The colour include, "themes/colors.conf", is untouched. It is still generated
# on every colour pass because hyprlock sources it and has no Lua configuration.
#
# Nothing is deleted. The files are moved into a backup directory, and the lines
# that source them are commented out in the user's own hyprlang files rather
# than removed, so a user who wants them back has both the file and the include.

config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
data_home="${XDG_DATA_HOME:-${HOME}/.local/share}"
state_home="${XDG_STATE_HOME:-${HOME}/.local/state}"
backup_dir="${state_home}/hyde/migration/v26.8.3"

entry_point=""

old_ifs="${IFS}"
IFS=:
for data_dir in ${data_home} ${XDG_DATA_DIRS:-/usr/local/share:/usr/share}; do
    [ -n "${data_dir}" ] || continue
    if [ -r "${data_dir}/hypr/hyde.lua" ]; then
        entry_point="${data_dir}/hypr/hyde.lua"
        break
    fi
done
IFS="${old_ifs}"

if [ -z "${entry_point}" ]; then
    echo "  no readable hypr/hyde.lua under the data directories, leaving the generated theme files in place"
    exit 0
fi

retired="theme.conf wallbash.conf"

sourced_by="
hypr/userprefs.conf
hypr/hyprland.conf
"

for rel in ${sourced_by}; do
    file="${config_home}/${rel}"

    [ -e "${file}" ] || [ -L "${file}" ] || continue

    if [ ! -r "${file}" ] || [ ! -w "${file}" ]; then
        echo "  ${file} cannot be rewritten, leaving the retired theme files in place" >&2
        exit 1
    fi
done

moved=0
failed=0

for name in ${retired}; do
    src="${config_home}/hypr/themes/${name}"
    dst="${backup_dir}/${name}"

    [ -e "${src}" ] || [ -L "${src}" ] || continue

    # A rerun after the file was restored would otherwise destroy the copy kept
    # by the first run, so an occupied destination is reported and left alone.
    if [ -e "${dst}" ] || [ -L "${dst}" ]; then
        echo "  skipped ${name}, a backup already exists at ${dst}" >&2
        failed=$((failed + 1))
        continue
    fi

    if ! mkdir -p "${backup_dir}"; then
        echo "  failed to create ${backup_dir}" >&2
        failed=$((failed + 1))
        continue
    fi

    if mv "${src}" "${dst}"; then
        echo "  moved themes/${name}"
        moved=$((moved + 1))
    else
        echo "  failed to move themes/${name}" >&2
        failed=$((failed + 1))
    fi
done

commented=0

for rel in ${sourced_by}; do
    file="${config_home}/${rel}"

    [ -f "${file}" ] || continue

    grep -qE '^[[:space:]]*source[[:space:]]*=.*themes/(theme|wallbash)\.conf' "${file}"
    grep_status=$?

    case "${grep_status}" in
    0) ;;
    1) continue ;;
    *)
        echo "  failed to read ${rel}" >&2
        failed=$((failed + 1))
        continue
        ;;
    esac

    if sed -i -E 's@^([[:space:]]*source[[:space:]]*=.*themes/(theme|wallbash)\.conf.*)$@# retired by HyDE, the file it sources is no longer generated\n#\1@' "${file}"; then
        echo "  commented the retired include out of ${rel}"
        commented=$((commented + 1))
    else
        echo "  failed to rewrite ${rel}" >&2
        failed=$((failed + 1))
    fi
done

if [ "${moved}" -gt 0 ]; then
    echo "Moved ${moved} retired theme file(s) to ${backup_dir}"
    echo "They hold the last theme that was generated for the hyprlang configuration."
fi

if [ "${commented}" -gt 0 ]; then
    echo "Commented ${commented} include(s) that pointed at them"
fi

if [ "${failed}" -gt 0 ]; then
    echo "Left ${failed} retired theme file(s) in place" >&2
    exit 1
fi

exit 0
