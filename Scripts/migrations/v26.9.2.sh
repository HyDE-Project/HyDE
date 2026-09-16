#!/usr/bin/env sh

# The "swaync" dot (Scripts/dots/swaync.toml) bundled both the swaync package
# and its config files. #2084 (26602069) split those apart: config now ships
# through "swaync_config" (Scripts/dots/swaync-config.toml, in extra.toml),
# and the daemon install became opt-in. "swaync" was dropped from every
# group at the same time and has since been deleted from the repo, but a
# machine that had it deployed before that refactor still carries its
# manifest at $XDG_DATA_HOME/deez/dots/swaync.toml, recording it as the
# owner of ~/.config/swaync. The "waybar" dot separately claimed
# menus/swaync.xml as part of syncing its whole menus/ directory, on every
# machine, fresh or not. deez-dots refuses to let a second dot touch a path
# another dot already owns, so swaync_config's deploy failed with "File
# conflict" on both (#2103).
#
# waybar.toml now excludes menus/swaync.xml via ignored_paths, but that
# alone does not fix already-installed machines: deez-dots reuses a dot's
# cached bundle whenever the dot's own *source* files haven't changed since
# it was built, and ignored_paths is metadata on the dot definition, not a
# source file, so it never invalidates that cache. Without also clearing
# waybar's stale manifest and cached bundle here, waybar keeps reusing the
# old bundle that still claims menus/swaync.xml, and swaync_config keeps
# failing on every restore, forever.
#
# Only manifests (deez-dots' record of who owns a path) and cached build
# artifacts are removed. Deployed config files on disk are never touched --
# waybar's and swaync_config's own next deploy relays those fresh anyway.

data_home="${XDG_DATA_HOME:-${HOME}/.local/share}"
cache_home="${XDG_CACHE_HOME:-${HOME}/.cache}"
build_dir="${cache_home}/deez/dots/build"

status=0

for manifest in "${data_home}/deez/dots/swaync.toml" "${data_home}/deez/dots/waybar.toml" "${data_home}/deez/dots/swaync_config.toml"; do
    [ -e "${manifest}" ] || continue
    if rm -f "${manifest}"; then
        echo "Cleared the stale '$(basename "${manifest}" .toml)' dot record (#2103)"
    else
        echo "  failed to remove ${manifest}" >&2
        status=1
    fi
done

if [ -d "${build_dir}" ]; then
    for bundle in "${build_dir}"/swaync-*.tar.gz "${build_dir}"/waybar-*.tar.gz "${build_dir}"/swaync_config-*.tar.gz; do
        [ -e "${bundle}" ] || continue
        if rm -f "${bundle}"; then
            echo "Cleared the stale cached bundle $(basename "${bundle}")"
        else
            echo "  failed to remove ${bundle}" >&2
            status=1
        fi
    done
fi

exit "${status}"
