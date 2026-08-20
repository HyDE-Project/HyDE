#!/usr/bin/env sh

# "$XDG_CONFIG_HOME/hyde/wallbash" ships as an editable example tree, and
# wallbash searches it before "$XDG_DATA_HOME/wallbash" (see `WALLBASH_DIRS`
# in globalcontrol.sh). "theme/swaync.dcol" and "scripts/swaync.sh" exist in
# both trees, so the example copy in the config dir permanently shadows the
# one HyDE actually maintains: every fix or feature shipped to the data-dir
# copy is silently ignored, and swaync always themes from whatever the config
# copy last happened to contain.
#
# Nothing is deleted. Both files are moved into a backup directory, so a user
# who deliberately customized their config copy still has it on disk.

config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
state_home="${XDG_STATE_HOME:-${HOME}/.local/state}"
backup_dir="${state_home}/hyde/migration/v26.8.4"

retired="theme/swaync.dcol scripts/swaync.sh"

moved=0
failed=0

for rel in ${retired}; do
    src="${config_home}/hyde/wallbash/${rel}"
    dst="${backup_dir}/${rel}"

    [ -e "${src}" ] || [ -L "${src}" ] || continue

    # A rerun after the file was restored would otherwise destroy the copy
    # kept by the first run, so an occupied destination is reported and left
    # alone.
    if [ -e "${dst}" ] || [ -L "${dst}" ]; then
        echo "  skipped ${rel}, a backup already exists at ${dst}" >&2
        failed=$((failed + 1))
        continue
    fi

    if ! mkdir -p "$(dirname "${dst}")"; then
        echo "  failed to create $(dirname "${dst}")" >&2
        failed=$((failed + 1))
        continue
    fi

    if mv "${src}" "${dst}"; then
        echo "  moved hyde/wallbash/${rel}"
        moved=$((moved + 1))
    else
        echo "  failed to move hyde/wallbash/${rel}" >&2
        failed=$((failed + 1))
    fi
done

if [ "${moved}" -gt 0 ]; then
    echo "Moved ${moved} shadowing swaync wallbash file(s) to ${backup_dir}"
    echo "swaync now themes from the copy in \$XDG_DATA_HOME/wallbash again."
fi

if [ "${failed}" -gt 0 ]; then
    echo "Left ${failed} shadowing swaync wallbash file(s) in place" >&2
    exit 1
fi

exit 0
