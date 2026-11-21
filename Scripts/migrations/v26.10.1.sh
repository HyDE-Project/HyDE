#!/usr/bin/env sh

# Hyprdots kept its Waybar modules as bare fragments ('"cpu": { ... },' with
# '${r_deg}' placeholders) that its config generator pasted into one object.
# HyDE includes every "*json*" file in ~/.config/waybar/modules/ as a document
# of its own, and the installer never touches that directory, so the
# fragments survive an install on top of Hyprdots (#1992). Waybar's parser
# stops after the first complete value, reads such a file as the string
# "cpu", then looks up its "include" key and aborts with
# "Json::Value::resolveReference(key, end): requires objectValue": the bar
# never starts.
#
# A file is moved only when Waybar cannot load it: it is empty or holds only
# comments, its top-level value is neither an object nor an array, or it has
# a "${...}" placeholder outside a string, which no JSON parser accepts. All
# three abort Waybar, so nothing that loads today is touched, and HyDE's own
# modules in $XDG_DATA_HOME/waybar/modules/ take the place of a moved one.
# Nothing is deleted; each file goes to a backup directory.

config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
state_home="${XDG_STATE_HOME:-${HOME}/.local/state}"
modules_dir="${config_home}/waybar/modules"
backup_dir="${state_home}/hyde/migration/v26.10.1/waybar/modules"

[ -d "${modules_dir}" ] || exit 0

# Succeeds when Waybar would abort on the file. Strings cannot span lines in
# JSON, so only the comment state carries over from one line to the next.
# Like Waybar's parser, it skips a byte order mark and stops reading once the
# top-level value is closed. The C locale makes awk count bytes, so multibyte
# text cannot shift a position.
unloadable() {
    LC_ALL=C awk '
    NR == 1 && substr($0, 1, 3) == "\357\273\277" { $0 = substr($0, 4) }
    {
        n = length($0)
        i = 1
        in_string = 0
        while (i <= n) {
            c = substr($0, i, 1)
            if (in_comment) {
                if (c == "*" && substr($0, i + 1, 1) == "/") { in_comment = 0; i += 2 } else i++
                continue
            }
            if (in_string) {
                if (c == "\\") i++
                else if (c == "\"") in_string = 0
                i++
                continue
            }
            if (c == "/" && substr($0, i + 1, 1) == "/") break
            if (c == "/" && substr($0, i + 1, 1) == "*") { in_comment = 1; i += 2; continue }
            if (c == " " || c == "\t" || c == "\r") { i++; continue }
            if (first == "") first = c
            if (c == "\"") in_string = 1
            else if (c == "$" && substr($0, i + 1, 1) == "{") placeholder = 1
            else if (c == "{" || c == "[") depth++
            else if ((c == "}" || c == "]") && --depth <= 0) exit
            i++
        }
    }
    END { exit !(first == "" || (first != "{" && first != "[") || placeholder) }
    ' "$1"
}

status=0
moved=0

# The same glob as the "modules/*json*" include in config.jsonc.
for src in "${modules_dir}"/*json*; do
    [ -f "${src}" ] || continue

    unloadable "${src}" || continue

    name="$(basename "${src}")"
    dst="${backup_dir}/${name}"

    # A rerun after the file was restored would otherwise destroy the copy kept
    # by the first run, so an occupied destination is left alone. The same
    # file again is already backed up and goes; anything else is reported.
    if [ -f "${dst}" ] && cmp -s "${src}" "${dst}"; then
        if rm -f "${src}"; then
            echo "Removed waybar/modules/${name}, identical to its backup"
            moved=$((moved + 1))
        else
            echo "  failed to remove waybar/modules/${name}" >&2
            status=1
        fi
        continue
    fi
    if [ -e "${dst}" ] || [ -L "${dst}" ]; then
        echo "  skipped waybar/modules/${name}, a backup already exists at ${dst}" >&2
        status=1
        continue
    fi

    if ! mkdir -p "${backup_dir}"; then
        echo "  failed to create ${backup_dir}" >&2
        exit 1
    fi

    if mv "${src}" "${dst}"; then
        echo "Moved waybar/modules/${name}, which Waybar cannot load"
        moved=$((moved + 1))
    else
        echo "  failed to move waybar/modules/${name}" >&2
        status=1
    fi
done

if [ "${moved}" -gt 0 ]; then
    echo "They are kept in ${backup_dir}; Waybar uses HyDE's modules in their place (#1992)."
fi

exit "${status}"
