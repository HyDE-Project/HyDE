#!/usr/bin/env bash
# German (de) translations. Sourced by shutils/l10n.sh when DESKTOP_LANG=de.
# A missing key falls back to the original English string, so this file
# only needs entries for what's actually been migrated to print_log_L /
# send_notifs (or looked up directly against _T) so far -- see
# Configs/.local/lib/hyde/screenshot.sh and volumecontrol.sh.

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
