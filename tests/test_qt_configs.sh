#!/usr/bin/env bash
# The Qt configurations carry no saved window state.
#
# The theme switch rewrites these files through kwriteconfig, which re-escapes
# a @ByteArray value on every pass: the geometry stanza grew and lost its
# leading bytes each time a theme was applied. It is per-machine window state,
# so the shipped configuration has no business holding it.

. "$(dirname -- "$0")/lib/common.sh"

checked=0
for name in qt5ct qt6ct; do
    conf="$REPO_ROOT/Configs/.config/$name/$name.conf"
    [ -f "$conf" ] || continue
    checked=$((checked + 1))

    grep -q '^\[SettingsWindow\]' "$conf" &&
        fail "$name.conf ships the settings window geometry, which the theme switch corrupts"
    grep -q '@ByteArray' "$conf" &&
        fail "$name.conf ships a @ByteArray value, which kwriteconfig re-escapes on every theme switch"

    # The keys the theme switch writes have to stay reachable.
    for section in Appearance Fonts; do
        grep -q "^\[$section\]" "$conf" ||
            fail "$name.conf lost the [$section] section the theme switch writes to"
    done
    grep -q '^icon_theme=' "$conf" ||
        fail "$name.conf no longer declares an icon theme"
done

[ "$checked" -ne 0 ] ||
    fail "neither Qt configuration is in this checkout"

# The theme switch has to leave the files as it found them, or the drift is
# back under another key.
if command -v kwriteconfig6 >/dev/null 2>&1 && [ "$checked" -ne 0 ]; then
    work=$(mktemp -d)
    trap 'rm -rf "$work"' EXIT
    for name in qt5ct qt6ct; do
        conf="$REPO_ROOT/Configs/.config/$name/$name.conf"
        [ -f "$conf" ] || continue
        cp "$conf" "$work/$name.conf"
        for round in 1 2 3; do
            kwriteconfig6 --file "$work/$name.conf" --group Appearance --key icon_theme "Theme$round"
        done
        kwriteconfig6 --file "$work/$name.conf" --group Appearance --key icon_theme \
            "$(grep '^icon_theme=' "$conf" | cut -d= -f2-)"
        diff -q "$conf" "$work/$name.conf" >/dev/null ||
            fail "$name.conf does not survive repeated theme switches unchanged: $(diff "$conf" "$work/$name.conf" | head -n 4 | tr '\n' ' ')"
    done
else
    skip "kwriteconfig6 is not installed, only the shipped files are checked"
fi

printf '    %d Qt configuration(s) checked\n' "$checked"

finish
