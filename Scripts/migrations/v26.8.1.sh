#!/usr/bin/env sh

# Hyprland resolves "$XDG_CONFIG_HOME/hypr/hyprland.lua" before hyprland.conf
# and ignores the latter once the former exists. HyDE deploys that path as the
# user's override layer, loaded last by hyde.lua, and its entry point lives in
# the data directory where Hyprland never looks. A session started without
# HYPRLAND_CONFIG therefore loads the override layer on its own: a valid,
# empty configuration, so no error, and a compositor with a cursor and nothing
# else.
#
# The file is deployed with the preserve action, so a corrected template only
# reaches new installs. This puts the loader at the top of the copy already on
# disk. Nothing else in the file is touched, and a file that already has the
# loader is left alone.

config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
target="${config_home}/hypr/hyprland.lua"
backup_dir="${XDG_STATE_HOME:-${HOME}/.local/state}/hyde/migration/v26.8.1"

# A dangling link is checked before absence: exiting zero on one would have the
# runner record this migration as applied, and repairing the link afterwards
# would leave the loader missing for good.
if [ -L "${target}" ]; then
    # A config kept under a dotfile manager is a symlink into that tree.
    # Replacing the link with a regular file would take the machine off the
    # managed copy, so the rewrite follows it and edits what it points at.
    resolved=$(readlink -f "${target}")
    if [ -z "${resolved}" ] || [ ! -f "${resolved}" ]; then
        echo "  ${target} is a symlink that leads nowhere, leaving it alone" >&2
        exit 1
    fi
    echo "  ${target} is a symlink, editing ${resolved}"
    target="${resolved}"
fi

[ -f "${target}" ] || exit 0

if grep -q '^if not hyde then$' "${target}"; then
    echo "  ${target} already loads HyDE, nothing to do"
    exit 0
fi

if ! mkdir -p "${backup_dir}"; then
    echo "  cannot create ${backup_dir}, leaving ${target} alone" >&2
    exit 1
fi

# The copy is taken before the rewrite: a failure past this point leaves the
# original recoverable rather than half written.
if ! cp -p "${target}" "${backup_dir}/hyprland.lua"; then
    echo "  cannot back up ${target}, leaving it alone" >&2
    exit 1
fi

rewritten="${target}.hyde-migration"

# Seeding the new file from the old one carries its mode across; the
# redirection below truncates the copy rather than creating a file under the
# current umask.
if ! cp -p "${target}" "${rewritten}"; then
    echo "  cannot stage the rewrite of ${target}, leaving it alone" >&2
    rm -f "${rewritten}"
    exit 1
fi

{
    cat <<'LOADER'
-- Hyprland loads this file when it is started without a config, and it prefers
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

LOADER
    cat "${target}"
} >"${rewritten}" || {
    echo "  cannot write ${rewritten}, leaving ${target} alone" >&2
    rm -f "${rewritten}"
    exit 1
}

if ! mv "${rewritten}" "${target}"; then
    echo "  cannot replace ${target}, the original is unchanged" >&2
    rm -f "${rewritten}"
    exit 1
fi

echo "  ${target} now loads HyDE when Hyprland picks it"
echo "  the copy from before this change is at ${backup_dir}/hyprland.lua"
exit 0
