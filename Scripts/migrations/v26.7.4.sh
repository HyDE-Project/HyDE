#!/usr/bin/env sh

# The Lua release replaced a set of shell helpers with Lua and Python
# equivalents. Deployment overwrites files but does not delete the ones that
# disappeared upstream, and hyde-shell used to resolve ".sh" before ".lua", so
# the leftovers kept answering in place of the scripts that replaced them.
#
# Nothing is deleted here. Anything found is moved aside so it can be restored
# if a local change is still needed.

lib_dir="${HOME}/.local/lib/hyde"
backup_dir="${XDG_STATE_HOME:-${HOME}/.local/state}/hyde/migration/v26.7.4"

superseded="
animations.sh
app2unit.sh
batterynotify.sh
color/dconf.sh
dontkillsteam.sh
hypr.altab.lua
hypr.unbind.sh
open.sh
parse.config.py
parse.json.py
shaders.sh
swwwallbash.sh
swwwallcache.sh
swwwallpaper.sh
swwwallselect.sh
sysmonlaunch.sh
system.update.sh
systemupdate.sh
testrunner.sh
themeselect.sh
themeswitch.sh
wbarconfgen.sh
wbarstylegen.sh
window.pin.sh
workflows.sh
"

[ -d "${lib_dir}" ] || exit 0

moved=0
failed=0
for rel in ${superseded}; do
    src="${lib_dir}/${rel}"
    [ -f "${src}" ] || continue

    dst="${backup_dir}/${rel}"

    # A rerun after the file was restored would otherwise destroy the copy kept
    # by the first run, so an occupied destination is reported and left alone.
    if [ -e "${dst}" ] || [ -L "${dst}" ]; then
        echo "  skipped ${rel}, a backup already exists at ${dst}" >&2
        failed=$((failed + 1))
        continue
    fi

    if ! mkdir -p "$(dirname "${dst}")"; then
        echo "  failed to create the backup directory for ${rel}" >&2
        failed=$((failed + 1))
        continue
    fi

    if mv "${src}" "${dst}"; then
        echo "  moved ${rel}"
        moved=$((moved + 1))
    else
        echo "  failed to move ${rel}" >&2
        failed=$((failed + 1))
    fi
done

if [ "${moved}" -gt 0 ]; then
    echo "Moved ${moved} superseded script(s) to ${backup_dir}"
fi

if [ "${failed}" -gt 0 ]; then
    echo "Left ${failed} superseded script(s) in place; they still shadow their replacements" >&2
    exit 1
fi
