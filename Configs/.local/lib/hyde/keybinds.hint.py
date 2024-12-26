#! /usr/bin/env python3
import subprocess
import json
import argparse
import os
from collections import defaultdict
import time


# filepath: /home/khing/.local/lib/hyde/keybinds.hint.py


def get_hyprctl_binds():
    while True:
        try:
            result = subprocess.run(
                ["hyprctl", "binds", "-j"], capture_output=True, text=True, check=True
            )
            while result.returncode != 0:
                print("Waiting for hyprctl command to succeed...")
                time.sleep(1)
                result = subprocess.run(
                    ["hyprctl", "binds", "-j"],
                    capture_output=True,
                    text=True,
                    check=True,
                )
            binds = json.loads(result.stdout)
            return binds
        except subprocess.CalledProcessError as e:
            print(f"Error executing hyprctl: {e}")
            return None
        except json.JSONDecodeError:
            time.sleep(1)


def parse_description(description):
    if description.startswith("[") and "] " in description:
        headers, main_description = description.split("] ", 1)
        headers = headers.strip("[").split("|")
    else:
        headers = ["Misc", "", "", ""]
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
    mod_display = []
    for key, name in sorted(modkey_map.items(), reverse=True):
        if modmask >= key:
            modmask -= key
            mod_display.append(name)
    return " ".join(mod_display) if mod_display else "None"


def map_keyDisplay(key):
    """Map key_display to a more descriptive term."""
    key_map = {
        "edge:r:d": "Touch right edge downwards",
        "edge:r:l": "Touch right edge left",
        "edge:r:r": "Touch right edge right",
    }
    return key_map.get(key, key)


def find_duplicated_binds(binds):
    bind_map = defaultdict(list)
    for bind in binds:
        key = (bind["mod_display"], bind["key_display"])
        bind_map[key].append(bind)

    duplicated_binds = {k: v for k, v in bind_map.items() if len(v) > 1}
    return duplicated_binds


def tabulate_binds(binds):
    """Tabulate binds data for printing."""
    headers = ["mod_display", "key_display", "Dispatcher", "Arg", "Description"]

    # Calculate column widths
    col_widths = [len(header) for header in headers]
    for bind in binds:
        col_widths[0] = max(col_widths[0], len(bind["mod_display"]))
        col_widths[1] = max(col_widths[1], len(bind["key_display"]))
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
                    ["mod_display", "key_display", "dispatcher", "arg", "description"],
                    col_widths,
                )
            )
            + "|"
        )
        rows.append(row)
    rows.append(separator)

    return "\n".join(rows)


def generate_md(binds):
    """Generate markdown table for binds data."""
    headers = ["Keys", "Action"]

    # Create the header row
    header_row = "| " + " | ".join(headers) + " |"
    separator_row = "| :--- | :--- |"

    # Group binds by headers
    header_groups = defaultdict(
        lambda: defaultdict(lambda: defaultdict(lambda: defaultdict(list)))
    )
    for bind in binds:
        header1 = bind.get("header1", "Default")
        header2 = bind.get("header2", "")
        header3 = bind.get("header3", "")
        header4 = bind.get("header4", "")
        header_groups[header1][header2][header3][header4].append(bind)

    # Create the table rows
    rows = []
    for header1, group1 in header_groups.items():
        rows.append(f"## {header1}")
        for header2, group2 in group1.items():
            if header2:
                rows.append(f"### {header2}")
            for header3, group3 in group2.items():
                if header3:
                    rows.append(f"#### {header3}")
                for header4, binds in group3.items():
                    if header4:
                        rows.append(f"##### {header4}")
                    rows.append(header_row)
                    rows.append(separator_row)
                    for bind in binds:
                        keys = bind["mod_display"].split() + [bind["key_display"]]
                        formatted_keys = (
                            "<kbd>" + "</kbd> + <kbd>".join(keys) + "</kbd>"
                        )
                        action = bind["description"]
                        row = f"| {formatted_keys} | {action} |"
                        rows.append(row)
                    rows.append("")

    return "\n".join(rows)


def generate_dmenu(binds):
    """Generate dmenu string for binds data."""
    dmenu_str = ""
    for bind in binds:
        mod_display = bind["mod_display"]
        if mod_display is None or mod_display == "None":
            mod_display = ""
        key_display = bind["key_display"]
        if key_display is None or key_display == "None":
            key_display = ""
        keys = [mod_display] if mod_display else []
        if key_display:
            keys.append(key_display)
        formatted_keys = " + ".join(keys).strip(" + ")
        action = bind["description"]
        header1 = bind.get("header1", "")
        header2 = bind.get("header2", "")
        header3 = bind.get("header3", "")
        header4 = bind.get("header4", "")
        dmenu_str += f"{formatted_keys} ::: {action} ::: {header1} ::: {header2} ::: {header3} ::: {header4}\n"
    return dmenu_str


def generate_rofi(binds):
    """Generate rofi string for binds data with headers."""
    rofi_str = ""
    groups = {}

    delimiter = os.getenv("ROFI_KEYBIND_HINT_DELIMITER", ">")
    for bind in binds:
        catch_all = bind.get("catch_all", False)
        if catch_all:  # hide the catch all keybind from the rofi menu
            continue

        displayed_keys = bind["displayed_keys"]
        description = bind["description"]
        dispatcher = bind["dispatcher"]
        arg = bind["arg"]
        header1 = bind.get("header1", "")
        header2 = bind.get("header2", "")
        header3 = bind.get("header3", "")
        header4 = bind.get("header4", "")
        header5 = bind.get("header5", "")
        submap = bind.get("submap", "")
        repeated = "repeat" if bind.get("repeat", False) else ""
        keycode = bind["keycode"]
        meta_data = f"{dispatcher} {arg} {repeated} {keycode} {header1} {header2} {header3} {header4} {header5} {submap} {displayed_keys}"

        displayed_rofi_keys = f"{displayed_keys:<20} {delimiter:<5} {description}"

        # Create nested dictionary structure
        if header1 not in groups:
            groups[header1] = {}
        if header2 not in groups[header1]:
            groups[header1][header2] = {}
        if header3 not in groups[header1][header2]:
            groups[header1][header2][header3] = {}
        if header4 not in groups[header1][header2][header3]:
            groups[header1][header2][header3][header4] = {}
        if header5 not in groups[header1][header2][header3][header4]:
            groups[header1][header2][header3][header4][header5] = []

        groups[header1][header2][header3][header4][header5].append(
            f"{displayed_rofi_keys} ::: {dispatcher} ::: {arg} ::: {repeated} ::: {meta_data}"
        )

        def format_group(headers, level=0, parent_meta_data=""):
            nonlocal rofi_str
            if level == 0:
                prefix = ""
            elif level == 1:
                prefix = ""
            else:
                prefix = " " * (level - 1) + ""

            suffix = f"[{parent_meta_data}]" if parent_meta_data else ""

            for header, subgroups in headers.items():
                current_meta_data = f"{header}{suffix}".strip(" <")
                if header:
                    rofi_str += (
                        f"{prefix} {header}  {suffix:>20} ::: ::: {current_meta_data}\n"
                    )
                if isinstance(subgroups, dict):
                    format_group(subgroups, level + 1, current_meta_data)
                else:
                    for binding in subgroups:
                        rofi_str += f"{binding} ::: ::: {current_meta_data}\n"
                    rofi_str += f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ::: ::: {current_meta_data}\n"

    format_group(groups)
    return rofi_str


def expand_meta_data(binds_data):
    submap_keys = {}

    # First pass: collect submap keys
    for bind in binds_data:
        if bind.get("has_description", False):
            parsed_description = parse_description(bind["description"])
            bind.update(parsed_description)
        else:
            bind["description"] = f"{map_dispatcher(bind['dispatcher'])} {bind['arg']}"
            bind.update(
                {"header1": "Misc", "header2": "", "header3": "", "header4": ""}
            )
        bind["key"] = map_codeDisplay(bind["keycode"], bind["key"])
        bind["key_display"] = map_keyDisplay(bind["key"])
        bind["mod_display"] = map_modDisplay(bind["modmask"])

        # Handle submaps
        if bind["dispatcher"] == "submap":
            submap_name = bind["arg"]
            submap_keys[submap_name] = {
                "mod_display": bind["mod_display"],
                "key_display": bind["key_display"],
            }

    # Second pass: update binds with submap keys
    for bind in binds_data:
        submap = bind.get("submap", "")
        mod_display = bind["mod_display"]
        if mod_display is None or mod_display == "None":
            mod_display = ""
        key_display = bind["key_display"]
        if key_display is None or key_display == "None":
            key_display = ""
        keys = [mod_display] if mod_display else []
        if key_display:
            keys.append(key_display)
        formatted_keys = " + ".join(keys).strip(" + ")

        if submap in submap_keys:
            submap_mod_display = submap_keys[submap]["mod_display"]
            submap_key_display = submap_keys[submap]["key_display"]
            bind["submap_mod"] = submap_mod_display
            bind["submap_key"] = submap_key_display
            bind["displayed_keys"] = (
                f"[{submap_mod_display} + {submap_key_display}] + {formatted_keys}".strip(
                    " + "
                )
            )
            bind["description"] = f"[{submap}] {bind['description']}"
        else:
            bind["submap_mod"] = ""
            bind["submap_key"] = ""
            bind["displayed_keys"] = formatted_keys


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Hyprland keybinds hint script")
    parser.add_argument(
        "--show-unbind", action="store_true", help="Show duplicated keybinds"
    )
    parser.add_argument(
        "--format",
        choices=["json", "md", "dmenu", "rofi"],
        default="json",
        help="Output format",
    )
    args = parser.parse_args()
    binds_data = get_hyprctl_binds()
    if binds_data:
        expand_meta_data(binds_data)
        if args.show_unbind:
            duplicated_binds = find_duplicated_binds(binds_data)
            for (mod_display, key_display), binds in duplicated_binds.items():
                print(f"unbind = {mod_display} , {key_display}")
        elif args.format == "json":
            print(json.dumps(binds_data, indent=4))
        elif args.format == "md":
            print(generate_md(binds_data))
        elif args.format == "dmenu":
            print(generate_dmenu(binds_data))
        elif args.format == "rofi":
            print(generate_rofi(binds_data))
