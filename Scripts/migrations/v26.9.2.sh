#!/usr/bin/env sh

# The "swaync" dot (Scripts/dots/swaync.toml) bundled both the swaync package
# and its config files. #2084 (26602069) split those apart: config now ships
# through "swaync_config" (Scripts/dots/swaync-config.toml, in extra.toml),
# and the daemon install became opt-in. "swaync" was dropped from every
# group at the same time and has since been deleted from the repo, but a
# machine that had it deployed before that refactor still carries its
# manifest at $XDG_DATA_HOME/deez/dots/swaync.toml, recording it as the
# owner of ~/.config/swaync. deez-dots refuses to let a second dot touch a
# path another dot already owns, so every such machine's swaync_config
# deploy fails with "File conflict: .../.config/swaync/... (owned by
# swaync)" (#2103), forever, since nothing will ever deploy "swaync" again
# to update or clear that record itself.
#
# Only the manifest is deleted, i.e. deez-dots' record of who owns the path.
# swaync_config's own "sync" deploy relays the current config files right
# afterward, so nothing here removes or backs up the files on disk.

data_home="${XDG_DATA_HOME:-${HOME}/.local/share}"
manifest="${data_home}/deez/dots/swaync.toml"

[ -e "${manifest}" ] || exit 0

if rm -f "${manifest}"; then
    echo "Cleared the stale 'swaync' dot record (superseded by swaync_config, #2103)"
    exit 0
fi

echo "  failed to remove ${manifest}" >&2
exit 1
