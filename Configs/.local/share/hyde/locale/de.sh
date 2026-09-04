#!/usr/bin/env bash
# German (de) translations. Sourced by shutils/l10n.sh when DESKTOP_LANG=de.
# A missing key falls back to the original English string, so this file
# only needs entries for what's actually been migrated to print_log_L /
# send_notifs (or looked up directly against _T) so far -- see the files
# named in each section comment below. brightnesscontrol.sh was left out
# entirely: its one notification is a numeric bar plus a hardware device
# name, no translatable text at all.

# volumecontrol.sh
_T["muted"]="Stumm"
_T["unmuted"]="Ton an"
_T["Devices:"]="Geräte:"
_T["Choose an output device"]="Ausgabegerät wählen"
_T["Activated:"]="Aktiviert:"
_T["Error activating:"]="Fehler beim Aktivieren:"

# screenshot.sh
# ("saved in $save_dir" isn't listed: the path is interpolated into the
# string before send_notifs sees it, so no fixed _T key can ever match it.)
_T["Screenshot Error"]="Screenshot-Fehler"
_T["Failed to open annotation tool"]="Anmerkungstool konnte nicht geöffnet werden"
_T["Failed to take screenshot"]="Screenshot konnte nicht erstellt werden"
_T["OCR"]="OCR"
_T["Performing OCR on screenshot..."]="Führe OCR auf Screenshot aus …"
_T["OCR: extraction error"]="OCR: Fehler bei der Extraktion"
_T["OCR: screenshot error"]="OCR: Fehler beim Screenshot"
_T["QR Scan"]="QR-Scan"
_T["Performing QR scan on screenshot..."]="Führe QR-Scan auf Screenshot aus …"
_T["QR: extraction error"]="QR: Fehler bei der Extraktion"
_T["QR: screenshot error"]="QR: Fehler beim Screenshot"

# shutils/qr.sh
_T["zbar package is not installed"]="zbar-Paket ist nicht installiert"
_T["QR: successfully recognized"]="QR: erfolgreich erkannt"

# hyprsunset.sh
_T["Hyprsunset: ON"]="Hyprsunset: AN"
_T["Hyprsunset: OFF"]="Hyprsunset: AUS"
_T["Mode: Temperature"]="Modus: Temperatur"
_T["Mode: Gamma"]="Modus: Gamma"

# wallbashtoggle.sh -- same short labels in both the rofi mode-picker
# list (-m) and the notification afterwards, on purpose. "Automatisch"
# was tried for "auto" and rejected: too long, rofi truncated it with
# "...". "Auto" reads fine standalone in both places.
_T["theme"]="Theme"
_T["auto"]="Auto"
_T["dark"]="Dunkel"
_T["light"]="Hell"

# keyboardswitch.sh -- shows Hyprland's active_keymap XKB display name
# verbatim. Only the two layouts this repo/session actually exercised are
# covered; any other layout's English display name falls back untouched.
_T["German"]="Deutsch"
_T["English (US)"]="Englisch (US)"

# cliphist.sh
_T["Deleted"]="Gelöscht"
_T["Preview:"]="Vorschau:"
_T["No favorites."]="Keine Favoriten."
_T["Copied to clipboard."]="In Zwischenablage kopiert."
_T["Error: Selected favorite not found."]="Fehler: Ausgewählter Favorit nicht gefunden."
_T["Item is already in favorites."]="Eintrag ist bereits in den Favoriten."
_T["Added to favorites."]="Zu Favoriten hinzugefügt."
_T["No favorites to remove."]="Keine Favoriten zum Entfernen."
_T["Item removed from favorites."]="Eintrag aus Favoriten entfernt."
_T["All favorites have been deleted."]="Alle Favoriten wurden gelöscht."
_T["No favorites to delete."]="Keine Favoriten zum Löschen."
_T["Clipboard history cleared."]="Zwischenablage-Verlauf geleert."
_T["OCR Error"]="OCR-Fehler"
_T["No images in clipboard history..."]="Keine Bilder im Zwischenablage-Verlauf …"
_T["No image data in clipboard"]="Keine Bilddaten in der Zwischenablage"
_T["Scanning latest image from clipboard..."]="Scanne neuestes Bild aus der Zwischenablage …"

# font.sh
_T["Installed successfully"]="Erfolgreich installiert"
_T["Failed to extract:"]="Fehler beim Entpacken:"

# globalcontrol.sh (only its 2 real notify-send calls; the many print_log
# calls elsewhere in this file are debug/error-level internals, not
# end-user notifications, and were left alone on purpose)
_T["WARNING: No compatible wallpapers found in:"]="WARNUNG: Keine kompatiblen Wallpaper gefunden in:"
_T["File type not supported for this wallpaper backend."]="Dateityp wird von diesem Wallpaper-Backend nicht unterstützt."

# hyprlock.sh
_T["No .conf files found in:"]="Keine .conf-Dateien gefunden in:"
_T["Error"]="Fehler"
_T["Hyprlock config regenerated"]="Hyprlock-Konfiguration neu erstellt"
_T["Layout:"]="Layout:"
_T["Hyprlock layout:"]="Hyprlock-Layout:"
_T["Please swipe, press a key or click to exit."]="Wische, drücke eine Taste oder klicke zum Beenden."

# screenrecord.sh
_T["No screen recorder found. Try installing wl-screenrec or wf-recorder."]="Kein Bildschirmrekorder gefunden. Installiere wl-screenrec oder wf-recorder."
_T["Recording saved at"]="Aufnahme gespeichert unter"
_T["Recording stopped"]="Aufnahme gestoppt"

# wallpaper.sh
_T["set for"]="gesetzt für"
_T["Wallpaper not found"]="Wallpaper nicht gefunden"

# wallpaper.waydeeper.sh
_T["ERROR: failed to extract thumbnail from video"]="FEHLER: Thumbnail konnte nicht aus Video extrahiert werden"
_T["ERROR: waydeeper is not installed"]="FEHLER: waydeeper ist nicht installiert"
_T["ERROR: failed to download waydeeper"]="FEHLER: waydeeper-Download fehlgeschlagen für"
_T["model"]="Modell"

# theme.select.sh ("Style" itself is left untranslated on purpose, same
# as "theme" -- no _T entry needed, the fallback already reproduces it)
_T["applied..."]="angewendet …"

# rofiselect.sh
_T["is explicitly set, remove it in ~/.config/hyde/config.toml for changes to take effect."]="ist explizit gesetzt, entferne es in ~/.config/hyde/config.toml, damit Änderungen wirksam werden."

# shutils/ocr.sh
_T["OCR: required package is not installed"]="OCR: benötigtes Paket ist nicht installiert"
_T["OCR:"]="OCR:"
_T["symbols recognized"]="Zeichen erkannt"
_T["Languages used"]="Verwendete Sprachen"

# wallpaper.kon.sh
_T["Hash matched in"]="Hash gefunden in"
_T["Wallpaper set in"]="Wallpaper gesetzt in"

# hyde-launch.sh
_T["Deprecation Notice"]="Hinweis: Veraltet"
_T["hyde-launch.sh is deprecated. Please use hyde-shell open instead."]="hyde-launch.sh ist veraltet. Bitte stattdessen hyde-shell open verwenden."

# keybinds_hint.sh
_T["Keybind Hint"]="Tastenkürzel-Übersicht"
_T["Initialization failed."]="Initialisierung fehlgeschlagen."

# wallpaper/cache.sh
_T["Extracting thumbnail from video wallpaper..."]="Extrahiere Thumbnail aus Video-Wallpaper …"

# wallpaper.swww.sh
_T["DEPRECATION NOTICE: swww backend is deprecated, please switch to awww or other supported backends. See 'hyde-shell wallpaper --help' for more info."]="HINWEIS: Das swww-Backend ist veraltet, bitte zu awww oder einem anderen unterstützten Backend wechseln. Siehe 'hyde-shell wallpaper --help' für mehr Informationen."
