#!/usr/bin/env python3
"""
Merged catalog for gamelauncher: combine Steam and Lutris entries into one JSON/rofi stream.

Outputs:
  --json : prints array of {backend, id, name, display_name, header, install_dir}
  --rofi-string : prints rofi-ready lines: display_name\0icon\u001f<header>\x1e<backend>:<id>

The script probes for Lutris (flatpak or native) and calls the existing
`gamelauncher/steam.py --json` to get Steam entries.
"""

import json
import subprocess
import os
from collections import defaultdict


def fetch_entries(command):
    try:
        result = subprocess.run(command, stdout=subprocess.PIPE, text=True, check=True)
        return json.loads(result.stdout)
    except Exception as e:
        print(f"Error fetching entries with {command}: {e}")
        return []


def merge_entries(steam_entries, lutris_entries):
    merged = []
    name_map = defaultdict(list)

    for entry in steam_entries:
        entry["backend"] = "steam"
        name_map[entry["name"].lower()].append(entry)
    for entry in lutris_entries:
        entry["backend"] = "lutris"
        name_map[entry["name"].lower()].append(entry)

    for name, entries in name_map.items():
        for entry in entries:
            if len(entries) > 1:
                entry["display_name"] = (
                    f"{entry['name']} <sub><span size='medium' foreground='gray'>{entry['backend']}</span></sub>"
                )
            else:
                entry["display_name"] = entry["name"]
            merged.append(entry)

    return merged


def main():
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true", help="Output merged JSON")
    parser.add_argument("--rofi-string", action="store_true", help="Output merged rofi strings")
    args = parser.parse_args()

    script_dir = os.path.dirname(os.path.abspath(__file__))
    steam_entries = fetch_entries(["python", os.path.join(script_dir, "steam.py"), "--json"])
    lutris_entries = fetch_entries(["python", os.path.join(script_dir, "lutris.py"), "--json"])

    merged = merge_entries(steam_entries, lutris_entries)

    if args.json:
        print(json.dumps(merged, indent=4))
        return

    if args.rofi_string:
        for entry in merged:
            rofi_string = f"{entry['display_name']}\t{entry['run_command']}"
            if entry.get("cover"):
                rofi_string += f"\t\x00icon\x1f{entry['cover']}"
            elif entry.get("icon"):
                rofi_string += f"\t\x00icon\x1f{entry['icon']}"
            elif entry.get("header"):
                rofi_string += f"\t\x00icon\x1f{entry['header']}"
            print(rofi_string)


if __name__ == "__main__":
    main()
