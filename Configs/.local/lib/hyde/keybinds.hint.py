#! /usr/bin/env python3
import subprocess
import json
import argparse
from collections import defaultdict


def get_hyprctl_binds():
    try:
        result = subprocess.run(
            ["hyprctl", "binds", "-j"], capture_output=True, text=True, check=True
        )
        binds = json.loads(result.stdout)
        return binds
    except subprocess.CalledProcessError as e:
        print(f"Error executing hyprctl: {e}")
        return None
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON: {e}")
        return None


def parse_description(description):
    if description.startswith("[") and "] " in description:
        headers, main_description = description.split("] ", 1)
        headers = headers.strip("[").split("|")
    else:
        headers = ["", "", "", ""]
        main_description = description

    return {
        "header1": headers[0].replace("\\]", "]") if headers else "",
        "header2": headers[1].replace("\\]", "]") if len(headers) > 1 else "",
        "header3": headers[2].replace("\\]", "]") if len(headers) > 2 else "",
        "header4": headers[3].replace("\\]", "]") if len(headers) > 3 else "",
        "description": main_description,
    }


def map_dispatcher(dispatcher):
    dispatcher_map = {
        "exec": "execute",
        # Add more mappings as needed
    }
    return dispatcher_map.get(dispatcher, dispatcher)


def map_codeDisplay(keycode, key):
    if keycode == 0:
        return key
    code_map = {
        61: "slash",
        87: "KP_1",
        88: "KP_2",
        89: "KP_3",
        83: "KP_4",
        84: "KP_5",
        85: "KP_6",
        79: "KP_7",
        80: "KP_8",
        81: "KP_9",
        90: "KP_0",
    }
    return code_map.get(keycode, key)


def map_modDisplay(modmask):
    modkey_map = {
        64: "SUPER",
        32: "HYPER",
        16: "META",
        8: "ALT",
        4: "CTRL",
        2: "CAPSLOCK",
        1: "SHIFT",
    }
    modsym = []
    for key, name in sorted(modkey_map.items(), reverse=True):
        if modmask >= key:
            modmask -= key
            modsym.append(name)
    return " ".join(modsym) if modsym else "None"


def map_keyDisplay(key):
    """Map keysym to a more descriptive term."""
    # Implement key mapping if needed
    return key


def find_duplicated_binds(binds):
    bind_map = defaultdict(list)
    for bind in binds:
        key = (bind["mod_display"], bind["key_display"])
        bind_map[key].append(bind)

    duplicated_binds = {k: v for k, v in bind_map.items() if len(v) > 1}
    return duplicated_binds


def tabulate_binds(binds):
    """Tabulate binds data for printing."""
    headers = ["ModSym", "KeySym", "Dispatcher", "Arg", "Description"]

    # Calculate column widths
    col_widths = [len(header) for header in headers]
    for bind in binds:
        col_widths[0] = max(col_widths[0], len(bind["modsym"]))
        col_widths[1] = max(col_widths[1], len(bind["keysym"]))
        col_widths[2] = max(col_widths[2], len(bind["dispatcher"]))
        col_widths[3] = max(col_widths[3], len(bind["arg"]))
        col_widths[4] = max(col_widths[4], len(bind["description"]))

    # Create a horizontal separator
    separator = "+" + "+".join("-" * (width + 2) for width in col_widths) + "+"

    # Create the header row
    header_row = (
        "|"
        + "|".join(
            f" {header.ljust(width)} " for header, width in zip(headers, col_widths)
        )
        + "|"
    )

    # Create the table rows
    rows = [separator, header_row, separator]
    for bind in binds:
        row = (
            "|"
            + "|".join(
                f" {str(bind[key]).ljust(width)} "
                for key, width in zip(
                    ["modsym", "keysym", "dispatcher", "arg", "description"], col_widths
                )
            )
            + "|"
        )
        rows.append(row)
    rows.append(separator)

    return "\n".join(rows)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Hyprland keybinds hint script")
    parser.add_argument(
        "--show-unbind", action="store_true", help="Show duplicated keybinds"
    )
    args = parser.parse_args()

    binds_data = get_hyprctl_binds()
    if binds_data:
        for bind in binds_data:
            if bind.get("has_description", False):
                parsed_description = parse_description(bind["description"])
                bind.update(parsed_description)
            else:
                bind["description"] = (
                    f"{map_dispatcher(bind['dispatcher'])} {bind['arg']}"
                )
                bind.update(
                    {"header1": "", "header2": "", "header3": "", "header4": ""}
                )
            bind["key"] = map_codeDisplay(bind["keycode"], bind["key"])
            bind["key_display"] = map_keyDisplay(bind["key"])
            bind["mod_display"] = map_modDisplay(bind["modmask"])

        if args.show_unbind:
            duplicated_binds = find_duplicated_binds(binds_data)
            for (mod_display, key_display), binds in duplicated_binds.items():
                print(f"unbind = {mod_display} , {key_display}")
        else:
            print(json.dumps(binds_data, indent=4))
            # print(tabulate_binds(binds_data))
