#!/usr/bin/env sh

# The Lua release deleted the hyprlang configuration from the repository, but
# deployment overwrites files and never removes the ones that disappeared
# upstream. The whole chain is therefore still on every upgraded machine, and
# it is not inert: Hyprland falls back to "$XDG_CONFIG_HOME/hypr/hyprland.conf"
# whenever no Lua config is found, and that file sources the rest. A session
# that lands on it runs the pre-Lua configuration — the battery notification
# still names a script that was moved aside, and the close-window binds still
# call one that no longer exists.
#
# Nothing is deleted here. Everything is moved into a backup directory, which
# for most of these files is the only copy of settings the user wrote.
#
# This runs only when the Lua entry point is in place. Moving hyprland.conf out
# of the way while nothing else can be found would leave Hyprland to generate a
# fresh default config, which is worse than the leftovers.

config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
data_home="${XDG_DATA_HOME:-${HOME}/.local/share}"
backup_dir="${XDG_STATE_HOME:-${HOME}/.local/state}/hyde/migration/v26.8.2"

entry_point="${data_home}/hypr/hyde.lua"
user_config="${config_home}/hypr/hyprland.lua"

# Readable, not merely present: the loader opens this file, and an unreadable
# one would fail there with the fallback configuration already moved away.
if [ ! -r "${entry_point}" ]; then
    echo "  ${entry_point} is missing or unreadable, leaving the hyprlang configuration in place"
    exit 0
fi

if [ ! -f "${user_config}" ] || ! grep -q '^if not hyde then$' "${user_config}"; then
    echo "  ${user_config} does not load HyDE yet, leaving the hyprlang configuration in place"
    exit 0
fi

# Paths are relative to the two roots below. The compositor configuration only:
# hyprlock, hypridle and hyprsunset are still hyprlang and still shipped.
config_leftovers="
animations.conf
hyprland.conf
keybindings.conf
monitors.conf
nvidia.conf
shaders.conf
userprefs.conf
windowrules.conf
workflows.conf
animations
workflows
"

data_leftovers="
hypr/defaults.conf
hypr/dynamic.conf
hypr/env.conf
hypr/finale.conf
hypr/hyprland.conf
hypr/migration.conf
hypr/startup.conf
hypr/variables.conf
hypr/windowrules.conf
hyde/hyprland.conf
hyde/keybindings.conf
hyde/templates/hypr
"

moved=0
failed=0

move_leftover() {
    src="$1"
    rel="$2"

    # A link that leads nowhere still occupies a retired path, and it is still
    # a copy of what the user had. Both tests, or a dangling one is skipped and
    # the path stays behind forever.
    [ -e "${src}" ] || [ -L "${src}" ] || return 0

    dst="${backup_dir}/${rel}"

    # A rerun after the file was restored would otherwise destroy the copy kept
    # by the first run, so an occupied destination is reported and left alone.
    if [ -e "${dst}" ] || [ -L "${dst}" ]; then
        echo "  skipped ${rel}, a backup already exists at ${dst}" >&2
        failed=$((failed + 1))
        return 0
    fi

    if ! mkdir -p "$(dirname "${dst}")"; then
        echo "  failed to create the backup directory for ${rel}" >&2
        failed=$((failed + 1))
        return 0
    fi

    if mv "${src}" "${dst}"; then
        echo "  moved ${rel}"
        moved=$((moved + 1))
    else
        echo "  failed to move ${rel}" >&2
        failed=$((failed + 1))
    fi
}

for rel in ${config_leftovers}; do
    move_leftover "${config_home}/hypr/${rel}" "config/hypr/${rel}"
done

for rel in ${data_leftovers}; do
    move_leftover "${data_home}/${rel}" "data/${rel}"
done

if [ "${moved}" -gt 0 ]; then
    echo "Moved ${moved} hyprlang leftover(s) to ${backup_dir}"
    echo "They are the only copy of what you had configured before the Lua release."
fi

if [ "${failed}" -gt 0 ]; then
    echo "Left ${failed} hyprlang leftover(s) in place" >&2
    exit 1
fi

exit 0
