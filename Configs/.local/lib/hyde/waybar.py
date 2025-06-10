#!/usr/bin/env python3

import json
import os
import glob
import subprocess
import re
import argparse
import shutil
import time
import sys
import hashlib
import signal
import atexit

from pathlib import Path

import pyutils.wrapper.libnotify as notify
import pyutils.compositor as HYPRLAND
import pyutils.logger as logger

from pyutils.wrapper.rofi import rofi_dmenu
from pyutils.xdg_base_dirs import (
    xdg_config_home,
    xdg_data_home,
    xdg_state_home,
    xdg_cache_home,
    xdg_runtime_dir,
)

logger = logger.get_logger()

MODULE_DIRS = [
    os.path.join(str(xdg_config_home()), "waybar", "modules"),
    os.path.join(str(xdg_data_home()), "waybar", "modules"),
    os.path.join("usr", "local", "share", "waybar", "modules"),
    os.path.join("usr", "share", "waybar", "modules"),
]

LAYOUT_DIRS = [
    os.path.join(str(xdg_config_home()), "waybar", "layouts"),
    os.path.join(str(xdg_data_home()), "waybar", "layouts"),
    os.path.join("usr", "local", "share", "waybar", "layouts"),
    os.path.join("usr", "share", "waybar", "layouts"),
]

LAYOUT_IGNORE = ["test.jsonc", "dock#sample.jsonc"]

STYLE_DIRS = [
    os.path.join(str(xdg_config_home()), "waybar", "styles"),
    os.path.join(str(xdg_data_home()), "waybar", "styles"),
]

INCLUDES_DIRS = [
    os.path.join(str(xdg_config_home()), "waybar", "includes"),
    os.path.join(str(xdg_data_home()), "waybar", "includes"),
    os.path.join("usr", "local", "share", "waybar", "includes"),
    os.path.join("usr", "share", "waybar", "includes"),
]

CONFIG_JSONC = Path(os.path.join(str(xdg_config_home()), "waybar", "config.jsonc"))
STATE_FILE = Path(os.path.join(str(xdg_state_home()), "hyde", "staterc"))
HYDE_CONFIG = Path(os.path.join(str(xdg_state_home()), "hyde", "config"))


def source_env_file(filepath):
    """Source environment variables from a file."""
    if os.path.exists(filepath):
        with open(filepath) as file:
            for line in file:
                if line.strip() and not line.startswith("#"):
                    key, value = line.strip().split("=", 1)
                    os.environ[key] = value.strip("'")


def get_file_hash(filepath):
    """Calculate the SHA256 hash of a file."""
    sha256 = hashlib.sha256()
    with open(filepath, "rb") as file:
        while chunk := file.read(8192):
            sha256.update(chunk)
    return sha256.hexdigest()


def find_layout_files():
    """Recursively find all layout files in the specified directories."""
    layouts = []
    for layout_dir in LAYOUT_DIRS:
        for root, _, files in os.walk(layout_dir):
            for file in files:
                if file.endswith(".jsonc") and file not in LAYOUT_IGNORE:
                    layouts.append(os.path.join(root, file))
    return sorted(layouts)


def get_state_value(key, default=None):
    """Get a value from the state file."""
    if not STATE_FILE.exists():
        return default

    with open(STATE_FILE, "r") as file:
        for line in file:
            if line.startswith(f"{key}="):
                return line.split("=", 1)[1].strip()
    return default


def get_config_value(key, default=None):
    """Get a value from the config file or state file."""
    if HYDE_CONFIG.exists():
        with open(HYDE_CONFIG, "r") as file:
            for line in file:
                clean_line = line.strip()
                if clean_line.startswith("export "):
                    clean_line = clean_line[7:]  # Remove "export "
                if clean_line.startswith(f"{key}="):
                    return clean_line.split("=", 1)[1].strip()
    return default


def set_state_value(key, value):
    """Set or update a value in the state file, removing any duplicates."""
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)

    if not STATE_FILE.exists():
        with open(STATE_FILE, "w") as file:
            file.write(f"{key}={value}\n")
        return True

    existing_lines = []
    seen_keys = set()
    if os.path.exists(STATE_FILE):
        with open(STATE_FILE, "r") as file:
            for line in file:
                line = line.strip()
                if not line:
                    continue
                try:
                    current_key = line.split("=", 1)[0]
                    if current_key not in seen_keys and current_key != key:
                        existing_lines.append(line)
                        seen_keys.add(current_key)
                except Exception:
                    existing_lines.append(line)

    existing_lines.append(f"{key}={value}")

    with open(STATE_FILE, "w") as file:
        file.write("\n".join(existing_lines) + "\n")

    return True


def get_current_layout_from_config():
    """Get the current layout from state file or by comparing hash of layout files with current config.jsonc."""
    logger.debug("Getting current layout")

    layout_path = get_state_value("WAYBAR_LAYOUT_PATH")
    if layout_path and os.path.exists(layout_path):
        logger.debug(f"Found current layout in state file: {layout_path}")
        return layout_path

    layout_name = get_state_value("WAYBAR_LAYOUT_NAME")
    if layout_name:
        layouts = find_layout_files()
        for layout in layouts:
            if os.path.basename(layout).replace(".jsonc", "") == layout_name:
                logger.debug(f"Found current layout by name in state file: {layout}")
                return layout

    logger.debug("Fallback to legacy hash comparison method")
    logger.debug(f"Checking config: {CONFIG_JSONC}")
    if not CONFIG_JSONC.exists():
        logger.error("Config file not found")
        CONFIG_JSONC.parent.mkdir(parents=True, exist_ok=True)
        with open(CONFIG_JSONC, "w") as f:
            json.dump({}, f)

    config_hash = get_file_hash(CONFIG_JSONC)
    layouts = find_layout_files()
    layout = None

    for layout_file in layouts:
        if get_file_hash(layout_file) == config_hash:
            logger.debug(f"Found current layout by hash: {layout_file}")
            layout_name = os.path.basename(layout_file).replace(".jsonc", "")
            set_state_value("WAYBAR_LAYOUT_PATH", layout_file)
            set_state_value("WAYBAR_LAYOUT_NAME", layout_name)
            layout = layout_file
            return layout

    if not layout and layouts:
        logger.debug("No current layout found by hash comparison")
        current_layout_name = "unknown"
        backup_layout(current_layout_name)
        layout = layouts[0]

        layout_name = os.path.basename(layout).replace(".jsonc", "")
        set_state_value("WAYBAR_LAYOUT_PATH", layout)
        set_state_value("WAYBAR_LAYOUT_NAME", layout_name)

        shutil.copyfile(layout, CONFIG_JSONC)
        logger.debug(f"Updated config.jsonc with layout: {layout}")

    return layout


def ensure_state_file():
    """Ensure the state file has the necessary entries."""
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)

    logger.debug(f"Ensuring state file exists at: {STATE_FILE}")

    if not STATE_FILE.exists():
        logger.debug("State file does not exist, creating it")
        current_layout = get_current_layout_from_config()
        layout_name = (
            os.path.basename(current_layout).replace(".jsonc", "")
            if current_layout
            else ""
        )
        style_path = resolve_style_path(current_layout) if current_layout else ""

        with open(STATE_FILE, "w") as file:
            if current_layout:
                file.write(f"WAYBAR_LAYOUT_PATH={current_layout}\n")
                file.write(f"WAYBAR_LAYOUT_NAME={layout_name}\n")
                file.write(f"WAYBAR_STYLE_PATH={style_path}\n")
                logger.debug(f"Created state file with layout: {current_layout}")
            else:
                logger.warning("No layout found to write to state file")
        return

    with open(STATE_FILE, "r") as file:
        lines = file.readlines()

    layout_path_exists = any(line.startswith("WAYBAR_LAYOUT_PATH=") for line in lines)
    layout_name_exists = any(line.startswith("WAYBAR_LAYOUT_NAME=") for line in lines)
    style_path_exists = any(line.startswith("WAYBAR_STYLE_PATH=") for line in lines)

    if not layout_path_exists or not layout_name_exists or not style_path_exists:
        logger.debug("State file is missing entries, updating it")
        current_layout = (
            get_current_layout_from_config() if not layout_path_exists else None
        )
        if current_layout:
            layout_name = os.path.basename(current_layout).replace(".jsonc", "")
            style_path = resolve_style_path(current_layout)

            with open(STATE_FILE, "a") as file:
                if not layout_path_exists:
                    file.write(f"WAYBAR_LAYOUT_PATH={current_layout}\n")
                    logger.debug(f"Added WAYBAR_LAYOUT_PATH={current_layout}")
                if not layout_name_exists:
                    file.write(f"WAYBAR_LAYOUT_NAME={layout_name}\n")
                    logger.debug(f"Added WAYBAR_LAYOUT_NAME={layout_name}")
                if not style_path_exists:
                    file.write(f"WAYBAR_STYLE_PATH={style_path}\n")
                    logger.debug(f"Added WAYBAR_STYLE_PATH={style_path}")


def resolve_style_path(layout_path):
    """Resolve the style path based on the layout path."""
    name = os.path.basename(layout_path).replace(".jsonc", "")
    dir_name = os.path.basename(os.path.dirname(layout_path))

    for style_dir in STYLE_DIRS:
        style_path = glob.glob(os.path.join(style_dir, f"{name}*.css"))

        if style_path:
            logger.debug(f"Resolved style path: {style_path[0]}")
            return style_path[0]

        basename_without_hash = name.split("#")[0]
        style_path = glob.glob(os.path.join(style_dir, f"{basename_without_hash}*.css"))
        if style_path:
            logger.debug(f"Resolved style path with #: {style_path[0]}")
            return style_path[0]

        if dir_name:
            style_path = glob.glob(os.path.join(style_dir, f"{dir_name}*.css"))
            if style_path:
                logger.debug(
                    f"Resolved style path from directory name: {style_path[0]}"
                )
                return style_path[0]

    for style_dir in STYLE_DIRS:
        default_path = os.path.join(style_dir, "defaults.css")
        if os.path.exists(default_path):
            logger.debug(f"Using default style: {default_path}")
            return default_path

    logger.warning("No default style found in any style directory")
    return os.path.join(STYLE_DIRS[0], "defaults.css")


def set_layout(layout):
    """Set the layout and corresponding style."""
    layouts_data = list_layouts()
    layout_path = None
    layout_name = None
    style_path = None

    for pair in layouts_data["layouts"]:
        if layout == pair["layout"] or layout == pair["name"]:
            layout_path = pair["layout"]
            layout_name = pair["name"]
            style_path = pair["style"]
            break

    if not layout_path:
        logger.error(f"Layout {layout} not found")
        sys.exit(1)

    set_state_value("WAYBAR_LAYOUT_PATH", layout_path)
    set_state_value("WAYBAR_LAYOUT_NAME", layout_name)
    set_state_value("WAYBAR_STYLE_PATH", style_path)

    style_filepath = os.path.join(str(xdg_config_home()), "waybar", "style.css")
    shutil.copyfile(layout_path, CONFIG_JSONC)
    write_style_file(style_filepath, style_path)
    update_icon_size()
    update_border_radius()
    generate_includes()
    update_global_css()
    notify.send("Waybar", f"Layout changed to {layout}", replace_id=9)
    run_waybar_command("killall waybar; waybar & disown")


def handle_layout_navigation(option):
    """Handle --next, --prev, and --set options."""
    layouts_data = list_layouts()
    layout_list = [
        layout["layout"]
        for layout in layouts_data["layouts"]
        if not layout.get("is_backup_entry")
    ]
    current_layout = None

    with open(STATE_FILE, "r") as file:
        for line in file:
            if line.startswith("WAYBAR_LAYOUT_PATH="):
                current_layout = line.split("=")[1].strip()
                break

    if not current_layout:
        logger.error("Current layout not found in state file.")
        return

    if current_layout not in layout_list:
        logger.warning("Current layout file not found, re-caching layouts.")
        current_layout = get_current_layout_from_config()
        if not current_layout:
            logger.error("Failed to recache current layout.")
            return

    current_index = layout_list.index(current_layout)
    if option == "--next":
        next_index = (current_index + 1) % len(layout_list)
        set_layout(layout_list[next_index])
    elif option == "--prev":
        prev_index = (current_index - 1 + len(layout_list)) % len(layout_list)
        set_layout(layout_list[prev_index])
    elif option == "--set":
        if len(sys.argv) < 3:
            logger.error("Usage: --set <layout>")
            return
        layout = sys.argv[2]
        set_layout(layout)


def list_layouts():
    """List all layouts with their matching styles and backups."""
    layouts = find_layout_files()
    layout_style_pairs = []
    backup_layouts = []

    for layout in layouts:
        for layout_dir in LAYOUT_DIRS:
            if layout.startswith(layout_dir):
                relative_path = os.path.relpath(layout, start=layout_dir)
                if "/backup/" in layout or "\\backup\\" in layout:
                    name = relative_path.replace(".jsonc", "")
                    backup_layouts.append(
                        {
                            "layout": layout,
                            "name": name,
                        }
                    )
                    continue

                name = relative_path.replace(".jsonc", "")
                style_path = resolve_style_path(layout)
                layout_style_pairs.append(
                    {"layout": layout, "name": name, "style": style_path}
                )
                break

    result = {"layouts": layout_style_pairs, "backups": backup_layouts}

    if len(backup_layouts) > 0:
        layout_style_pairs.append(
            {
                "name": f"List all {len(backup_layouts)} Backup(s) saved",
                "style": "",
                "layout": "",
                "is_backup_entry": True,
            }
        )

    return result


def list_layouts_json():
    """List all layouts in JSON format with their matching styles and backups."""
    layouts_data = list_layouts()
    layouts_json = json.dumps(layouts_data, indent=4)
    print(layouts_json)
    sys.exit(0)


def parse_json_file(filepath):
    """Parse a JSON file and return the data."""
    with open(filepath, "r") as file:
        data = json.load(file)
    return data


def modify_json_key(data, key, value):
    """Recursively modify the specified key with the given value in the JSON data."""
    if isinstance(data, dict):
        for k, v in data.items():
            if k == key:
                data[k] = value
            elif isinstance(v, dict):
                modify_json_key(v, key, value)
            elif isinstance(v, list):
                for item in v:
                    if isinstance(item, dict):
                        modify_json_key(item, key, value)
    return data


def write_style_file(style_filepath, source_filepath):
    """Override the style file with the given source style."""
    wallbash_gtk_css_file = os.path.join(
        str(xdg_cache_home()), "hyde", "wallbash", "gtk.css"
    )
    wallbash_gtk_css_file_str = (
        f'@import "{wallbash_gtk_css_file}";'
        if os.path.exists(wallbash_gtk_css_file)
        else "/*  wallbash gtk.css not found   */"
    )
    style_css = f"""
    /*!  DO NOT EDIT THIS FILE */
    /*
    *     ░▒▒▒░░░▓▓           ___________
    *   ░░▒▒▒░░░░░▓▓        //___________/
    *  ░░▒▒▒░░░░░▓▓     _   _ _    _ _____
    *  ░░▒▒░░░░░▓▓▓▓▓ | | | | |  | |  __/
    *   ░▒▒░░░░▓▓   ▓▓ | |_| | |_/ /| |___
    *    ░▒▒░▓▓   ▓▓   |__  |____/ |____/
    *      ░▒▓▓   ▓▓  //____/
    */

    /* Modified by Hyde */

    /* Modify/add style in ~/.config/waybar/styles/ */
    @import "{source_filepath}";

    /* Imports wallbash colors */
    {wallbash_gtk_css_file_str}

    /* Colors and theme configuration is generated through the `theme.css` file */
    @import "theme.css";

    /* Users who want to override the current style add/edit 'user-style.css' */
    @import "user-style.css";
    """
    with open(style_filepath, "w") as file:
        file.write(style_css)
    logger.debug(f"Successfully wrote style to '{style_filepath}'")


def signal_handler(sig, frame):
    subprocess.run(["killall", "waybar"])
    sys.exit(0)


def run_waybar_command(command):
    """Run a Waybar command and redirect its output to the Waybar log file."""
    log_dir = os.path.join(str(xdg_runtime_dir()), "hyde")
    os.makedirs(log_dir, exist_ok=True)
    log_file = os.path.join(log_dir, "waybar.log")
    with open(log_file, "a") as file:
        file.write(
            f"{time.strftime('%Y-%m-%d %H:%M:%S')} - Running command: {command}\n"
        )
        subprocess.run(command, shell=True, stdout=file, stderr=file)
    logger.debug(f"Waybar log written to '{log_file}'")


def kill_waybar():
    """Kill only the Waybar process, not anything with 'waybar' in the name."""
    subprocess.run(["pkill", "-x", "waybar"])
    logger.debug("Killed Waybar processes.")


def kill_waybar_and_watcher():
    """Kill all Waybar instances and watcher scripts."""
    subprocess.run(["pkill", "-x", "waybar"])
    logger.debug("Killed Waybar processes.")

    try:
        current_pid = os.getpid()
        result = subprocess.run(
            ["pgrep", "-f", "waybar.py"], capture_output=True, text=True
        )

        if result.returncode == 0:
            pids = result.stdout.strip().split("\n")
            for pid in pids:
                if pid.strip() and int(pid.strip()) != current_pid:
                    try:
                        subprocess.run(["kill", pid.strip()])
                        logger.debug(
                            f"Killed waybar.py process with PID: {pid.strip()}"
                        )
                    except Exception as e:
                        logger.debug(f"Failed to kill PID {pid.strip()}: {e}")

        logger.debug("Killed all waybar.py watcher scripts.")
    except Exception as e:
        logger.error(f"Error killing waybar.py processes: {e}")


def ensure_directory_exists(filepath):
    """Ensure the directory for the given filepath exists."""
    directory = os.path.dirname(filepath)
    if not os.path.exists(directory):
        os.makedirs(directory)


def rofi_selector():
    """List all layout names in a rofi selector."""
    layouts_data = list_layouts()
    layout_names = [pair["name"] for pair in layouts_data["layouts"]]

    current_layout_name = get_state_value("WAYBAR_LAYOUT_NAME")
    if not current_layout_name:
        current_layout_path = get_state_value("WAYBAR_LAYOUT_PATH")
        if current_layout_path:
            current_layout_name = os.path.basename(current_layout_path).replace(
                ".jsonc", ""
            )

    logger.debug(f"Current layout from state: {current_layout_name}")

    hyprland = HYPRLAND.HyprctlWrapper()

    override_string = hyprland.get_rofi_override_string()
    rofi_pos_string = hyprland.get_rofi_pos()

    rofi_flags = [
        "-p",
        "Select layout:",
        "-select",
        current_layout_name,
        "-theme",
        "clipboard",
        "-theme-str",
        override_string,
        "-theme-str",
        rofi_pos_string,
    ]
    selected_layout = rofi_dmenu(
        layout_names,
        rofi_flags,
    )
    logger.debug(f"Selected layout: {selected_layout}")
    if selected_layout:
        selected_layout_path = None
        for pair in layouts_data["layouts"]:
            if pair["name"] == selected_layout:
                if pair.get("is_backup_entry", False):
                    handle_backup_display()
                    return
                selected_layout_path = pair["layout"]
                style_path = pair["style"]
                break

        if selected_layout_path:
            logger.debug(f"Updating config with layout: {selected_layout_path}")
            shutil.copyfile(selected_layout_path, CONFIG_JSONC)

            set_state_value("WAYBAR_LAYOUT_PATH", selected_layout_path)
            set_state_value("WAYBAR_LAYOUT_NAME", selected_layout)
            set_state_value("WAYBAR_STYLE_PATH", style_path)

            style_filepath = os.path.join(str(xdg_config_home()), "waybar", "style.css")
            write_style_file(style_filepath, style_path)
            update_icon_size()
            update_border_radius()
            generate_includes()
            update_global_css()
            notify.send("Waybar", f"Layout changed to {selected_layout}", replace_id=9)
            run_waybar_command("killall waybar; waybar & disown")
        else:
            logger.error(f"Could not find layout path for {selected_layout}")

    ensure_state_file()
    sys.exit(0)


def backup_layout(layout_name):
    """Backup the current config.jsonc file to a layout-specific named backup.

    Args:
        layout_name: Name of the layout to use in backup filename
    Returns:
        str: Path to the created backup file
    """
    if not CONFIG_JSONC.exists():
        logger.debug("No config file to backup")
        return None

    config_dir = CONFIG_JSONC.parent
    layouts_dir = os.path.join(str(config_dir), "layouts")
    os.makedirs(layouts_dir, exist_ok=True)
    backup_dir = os.path.join(layouts_dir, "backup")
    os.makedirs(backup_dir, exist_ok=True)

    timestamp = time.strftime("%Y%m%d_%H%M%S")
    backup_filename = f"{layout_name}_{timestamp}.jsonc"
    backup_path = os.path.join(backup_dir, backup_filename)

    try:
        shutil.copyfile(CONFIG_JSONC, backup_path)
        logger.debug(f"Created backup at {backup_path}")
        return str(backup_path)
    except Exception as e:
        logger.error(f"Failed to create backup: {e}")
        return None


def handle_backup_display():
    """Show a menu of backup layouts and allow trying them before applying."""
    layouts_data = list_layouts()
    backup_layouts = layouts_data["backups"]

    if not backup_layouts:
        notify.send("Waybar", "No backup layouts found", replace_id=9)
        return

    backup_names = [pair["name"] for pair in backup_layouts]

    hyprland = HYPRLAND.HyprctlWrapper()
    override_string = hyprland.get_rofi_override_string()
    rofi_pos_string = hyprland.get_rofi_pos()

    rofi_flags = [
        "-p",
        "Select a backup to try:",
        "-theme",
        "clipboard",
        "-theme-str",
        override_string,
        "-theme-str",
        rofi_pos_string,
    ]

    rofi_dmenu(
        backup_names,
        rofi_flags,
    )
    sys.exit(0)


def manage_waybar_lock(action="toggle"):
    """Manage the waybar hide lock file.

    Args:
        action: "toggle", "hide", or "show"
    Returns:
        bool: True if waybar should be hidden, False otherwise
    """
    lock_file = os.path.join(str(xdg_runtime_dir()), "hyde", "waybar_hide.lock")
    lock_file_path = Path(lock_file)
    lock_file_path.parent.mkdir(parents=True, exist_ok=True)

    if action == "toggle":
        if lock_file_path.exists():
            lock_file_path.unlink()
            logger.debug("Removed waybar hide lock file")
            return False
        else:
            lock_file_path.touch()
            logger.debug("Created waybar hide lock file")
            return True
    elif action == "hide":
        lock_file_path.touch()
        logger.debug("Created waybar hide lock file")
        return True
    elif action == "show":
        if lock_file_path.exists():
            lock_file_path.unlink()
            logger.debug("Removed waybar hide lock file")
        return False


def cleanup():
    """Clean up resources and lock files."""
    lock_file = os.path.join(str(xdg_runtime_dir()), "hyde", "waybar_hide.lock")
    lock_file_path = Path(lock_file)

    if lock_file_path.exists():
        try:
            result = subprocess.run(
                ["pgrep", "-c", "waybar.py"], capture_output=True, text=True
            )
            if result.returncode == 0 and int(result.stdout.strip()) <= 1:
                lock_file_path.unlink()
                logger.debug("Removed waybar hide lock file during cleanup")
        except Exception as e:
            logger.error(f"Failed to remove lock file during cleanup: {e}")


atexit.register(cleanup)


def main():
    logger.debug("Starting waybar.py")

    logger.debug(f"Looking for state file at: {STATE_FILE}")

    source_env_file(os.path.join(str(xdg_runtime_dir()), "hyde", "environment"))
    source_env_file(os.path.join(str(xdg_state_home()), "hyde", "config"))

    if STATE_FILE.exists():
        logger.debug(f"State file found: {STATE_FILE}")
        layout_path = get_state_value("WAYBAR_LAYOUT_PATH")

        if layout_path and os.path.exists(layout_path) and CONFIG_JSONC.exists():
            config_hash = get_file_hash(CONFIG_JSONC)
            layout_hash = get_file_hash(layout_path)

            if config_hash != layout_hash:
                logger.debug("Config hash differs from layout hash, creating backup")
                layout_name = os.path.basename(layout_path).replace(".jsonc", "")
                backup_layout(layout_name)

            try:
                shutil.copyfile(layout_path, CONFIG_JSONC)
                logger.debug("Updated config.jsonc with layout from state file")
            except Exception as e:
                logger.error(f"Failed to update config.jsonc: {e}")

        elif layout_path and not os.path.exists(layout_path) and CONFIG_JSONC.exists():
            logger.warning(f"Layout path in state file doesn't exist: {layout_path}")
            layout_name = get_state_value("WAYBAR_LAYOUT_NAME")
            if layout_name:
                logger.debug(f"Looking for layout by name: {layout_name}")
                layouts = find_layout_files()
                for layout in layouts:
                    if os.path.basename(layout).replace(".jsonc", "") == layout_name:
                        logger.debug(f"Found layout by name: {layout}")

                        config_hash = get_file_hash(CONFIG_JSONC)
                        layout_hash = get_file_hash(layout)

                        if config_hash != layout_hash:
                            backup_layout(layout_name)

                        set_state_value("WAYBAR_LAYOUT_PATH", layout)

                        try:
                            shutil.copyfile(layout, CONFIG_JSONC)
                            logger.debug("Updated config.jsonc with layout by name")
                        except Exception as e:
                            logger.error(f"Failed to update config.jsonc: {e}")
                        break
                else:
                    logger.error(f"Could not find layout by name: {layout_name}")
    else:
        logger.debug("State file not found, creating it")
        ensure_state_file()

    parser = argparse.ArgumentParser(description="Waybar configuration script")
    parser.add_argument("--set", type=str, help="Set a specific layout")
    parser.add_argument(
        "-n", "--next", action="store_true", help="Switch to the next layout"
    )
    parser.add_argument(
        "-p", "--prev", action="store_true", help="Switch to the previous layout"
    )
    parser.add_argument(
        "-u",
        "--update",
        action="store_true",
        help="Update all (icon size, border radius, includes, config, style)",
    )
    parser.add_argument(
        "-g",
        "--update-global-css",
        action="store_true",
        help="Update global.css file",
    )
    parser.add_argument(
        "-i",
        "--update-icon-size",
        action="store_true",
        help="Update icon size in JSON files",
    )
    parser.add_argument(
        "-b",
        "--update-border-radius",
        action="store_true",
        help="Update border radius in CSS file",
    )
    parser.add_argument(
        "-G",
        "--generate-includes",
        action="store_true",
        help="Generate includes.json file",
    )
    parser.add_argument(
        "-c", "--config", type=str, help="Path to the source config.jsonc file"
    )
    parser.add_argument(
        "-s", "--style", type=str, help="Path to the source style.css file"
    )
    parser.add_argument(
        "-w", "--watch", action="store_true", help="Watch and restart Waybar if it dies"
    )
    parser.add_argument(
        "--json", "-j", action="store_true", help="List all layouts in JSON format"
    )
    parser.add_argument(
        "--select", "-S", action="store_true", help="List all layout names"
    )
    parser.add_argument(
        "--kill",
        "-k",
        action="store_true",
        help="Kill all Waybar instances and watcher script",
    )
    parser.add_argument(
        "--hide",
        nargs="?",
        const="toggle",
        type=str,
        choices=["0", "1", "toggle"],
        help="Hide waybar (1), show waybar (0), or toggle hide state (no argument)",
    )

    if not STATE_FILE.exists() or STATE_FILE.stat().st_size == 0:
        logger.debug("State file doesn't exist or is empty, creating it")
        ensure_state_file()
    else:
        logger.debug(f"Using existing state file: {STATE_FILE}")

    source_env_file(os.path.join(str(xdg_runtime_dir()), "hyde", "environment"))
    source_env_file(os.path.join(str(xdg_state_home()), "hyde", "config"))

    args = parser.parse_args()

    ensure_state_file()

    if args.update:
        update_icon_size()
        update_border_radius()
        generate_includes()
        update_global_css()
        logger.debug("Updating config and style...")
    if args.update_global_css:
        update_global_css()
    if args.update_icon_size:
        update_icon_size()
    if args.update_border_radius:
        update_border_radius()
    if args.generate_includes:
        generate_includes()
    if args.config:
        update_config(args.config)
    if args.style:
        update_style(args.style)
    if args.next or args.prev or args.set:
        handle_layout_navigation(
            "--next" if args.next else "--prev" if args.prev else "--set"
        )
    if args.json:
        list_layouts_json()
    if args.select:
        rofi_selector()

    if args.hide is not None:
        if args.hide == "1":
            if manage_waybar_lock("hide"):
                kill_waybar()
                sys.exit(0)
        elif args.hide == "0":
            manage_waybar_lock("show")
            run_waybar_command("killall waybar; waybar & disown")
            sys.exit(0)
        else:  # args.hide == "toggle"
            if manage_waybar_lock("toggle"):
                kill_waybar()
            else:
                run_waybar_command("killall waybar; waybar & disown")
            sys.exit(0)

    if args.kill:
        kill_waybar_and_watcher()
        sys.exit(0)

    if args.watch:
        watch_waybar()
    else:
        # Check if waybar should be hidden before starting
        lock_file = os.path.join(str(xdg_runtime_dir()), "hyde", "waybar_hide.lock")
        if os.path.exists(lock_file):
            logger.debug("Waybar hide lock file exists, not starting waybar")
            return
            
        update_icon_size()
        update_border_radius()
        generate_includes()
        update_global_css()
        update_style(args.style)
        run_waybar_command("killall waybar; waybar & disown")
        return

    if not any(vars(args).values()):
        parser.print_help()
        sys.exit(0)


def update_icon_size():
    includes_file = os.path.join(
        str(xdg_config_home()), "waybar", "includes", "includes.json"
    )

    ensure_directory_exists(includes_file)

    if os.path.exists(includes_file):
        try:
            with open(includes_file, "r") as file:
                includes_data = json.load(file)
        except (json.JSONDecodeError, FileNotFoundError):
            includes_data = {"include": []}
    else:
        includes_data = {"include": []}

    icon_size = get_waybar_icon_size()

    updated_entries = {}

    for directory in MODULE_DIRS:
        for json_file in glob.glob(os.path.join(directory, "*.json")):
            data = parse_json_file(json_file)

            for key, value in data.items():
                if isinstance(value, dict):
                    icon_size_multiplier = value.get("icon-size-multiplier", 1)
                    final_icon_size = int(icon_size * icon_size_multiplier)

                    data[key] = modify_json_key(value, "icon-size", final_icon_size)
                    data[key] = modify_json_key(
                        value, "tooltip-icon-size", final_icon_size
                    )
                    data[key] = modify_json_key(value, "size", final_icon_size)

            updated_entries.update(data)

    includes_data.update(updated_entries)

    with open(includes_file, "w") as file:
        json.dump(includes_data, file, indent=4)
    logger.debug(
        f"Successfully updated icon sizes and appended to '{includes_file}' with {len(updated_entries)} entries."
    )


def update_global_css():
    """Generate dynamic global.css with font family and size based on theme and state file."""
    global_css_path = os.path.join(
        str(xdg_config_home()), "waybar", "includes", "global.css"
    )
    logger.debug(f"Updating global CSS in {global_css_path}")

    ensure_directory_exists(global_css_path)

    font_family = get_waybar_font_family()
    font_size = get_waybar_font_size()

    if font_family:
        font_family = font_family.strip().strip('"').strip("'")

    logger.debug(f"Final font family: {font_family}")
    logger.debug(f"Final font size: {font_size}")

    global_css_content = f"""/*
 Dynamic Style Configuration *
 This is handled by HyDE

 To generate a dynamic configuration 
 base on theme and user settings

*/

* {{
    border-radius: 0em;
    font-family: "{font_family}","JetBrainsMono Nerd Font";
    font-size: {font_size}px;
}}
"""

    with open(global_css_path, "w") as file:
        file.write(global_css_content)
    logger.debug(f"Successfully generated global CSS at '{global_css_path}'")


def get_waybar_value_from_sources(value_name, default_value, sources):

    def _try_parse_value(raw_value, source_name):
        if type(default_value) is str:
            return _try_parse_str_value(raw_value, source_name)
        if type(default_value) is int:
            return _try_parse_int_value(raw_value, source_name)

    def _try_parse_str_value(raw_value, source_name):
        """Helper function to parse str value and log appropriately."""
        if not raw_value:
            return None

        sanitized_value = raw_value.strip().strip('"').strip("'")
        logger.debug(f"Got {value_name} from {source_name}: {sanitized_value}")
        return sanitized_value

    def _try_parse_int_value(raw_value, source_name):
        """Helper function to parse int value and log appropriately."""
        if not raw_value:
            return None

        try:
            int_value = int(raw_value)
            logger.debug(f"Got {value_name} from {source_name}: {int_value}")
            return int_value
        except ValueError:
            logger.debug(f"Invalid {value_name} from {source_name}: {raw_value}")
            return None

    for get_source_func, source_name in sources:
        raw_value = get_source_func()
        parsed_value = _try_parse_value(raw_value, source_name)
        if parsed_value is not None:
            return parsed_value

    logger.debug(f"Using default {value_name}: {default_value}")
    return default_value


def get_waybar_font_family():
    """Get font family for waybar following the priority stack."""

    font_family_sources = [
        (lambda: get_config_value("WAYBAR_FONT"), "WAYBAR_FONT config"),
        (lambda: get_value_from_hypr_theme("$BAR_FONT"), "hypr.theme"),
        (lambda: get_state_value("BAR_FONT"), "state file"),
    ]

    return get_waybar_value_from_sources("font family", "JetBrainsMono Nerd Font", font_family_sources)


def get_waybar_font_size():
    """Get font size for waybar following the priority stack."""

    font_size_sources = [
        (lambda: get_config_value("WAYBAR_SCALE"), "WAYBAR_SCALE config"),
        (lambda: get_state_value("BAR_FONT_SIZE"), "state file"),
        (lambda: get_value_from_hypr_theme("$BAR_FONT_SIZE"), "hypr.theme"),
    ]

    return get_waybar_value_from_sources("font size", 10, font_size_sources)


def get_waybar_icon_size():
    """Get icon size for waybar following the priority stack."""

    icon_sources = [
        (lambda: get_config_value("WAYBAR_ICON_SIZE"), "WAYBAR_ICON_SIZE config"),
        (lambda: get_config_value("WAYBAR_SCALE"), "WAYBAR_SCALE config"),
        (lambda: get_state_value("BAR_ICON_SIZE"), "state file"),
        (lambda: get_value_from_hypr_theme("$BAR_ICON_SIZE"), "hypr.theme"),
    ]

    return get_waybar_value_from_sources("icon size", 10, icon_sources)


def get_value_from_hypr_theme(variable_name):
    """Get named setting from hypr.theme file using hyq."""
    theme_name = None
    if STATE_FILE.exists():
        try:
            with open(STATE_FILE, "r") as file:
                for line in file:
                    if line.startswith("HYDE_THEME="):
                        theme_name = line.strip().split("=", 1)[1].strip('"').strip("'")
                        logger.debug(f"Found theme name in state file: {theme_name}")
                        break
        except Exception as e:
            logger.error(f"Error reading state file: {e}")
            return None

    if not theme_name:
        logger.debug("No theme name found in state file")
        return None

    theme_dir = os.path.join(str(xdg_config_home()), "hyde", "themes", theme_name)
    logger.debug(f"Looking for theme directory at: {theme_dir}")

    if not os.path.exists(theme_dir):
        logger.debug(f"Theme directory not found at {theme_dir}")
        return None

    hypr_theme_path = os.path.join(theme_dir, "hypr.theme")
    if not os.path.exists(hypr_theme_path):
        logger.debug(f"hypr.theme not found at {hypr_theme_path}")
        return None

    logger.debug(f"Found hypr.theme at {hypr_theme_path}")

    try:
        import shlex

        cmd = [
            "hyq",
            shlex.quote(hypr_theme_path),
            "--query",
            variable_name,
        ]
        logger.debug(f"Running command: {' '.join(cmd)}")

        result = subprocess.run(cmd, capture_output=True, text=True)

        logger.debug(f"hyq command output: {result.stdout.strip()}")
        logger.debug(
            f"hyq command stderr: {result.stderr.strip() if result.stderr else 'None'}"
        )
        logger.debug(f"hyq exit code: {result.returncode}")

        if result.returncode == 0 and result.stdout:
            output_lines = result.stdout.strip().split("\n")
            for line in reversed(output_lines):
                clean_line = line.strip()
                if clean_line and not clean_line.startswith("#"):
                    logger.debug(
                        f"Successfully parsed {variable_name} from hyq: {clean_line}"
                    )
                    return clean_line

        logger.debug(f"No valid output from hyq for {variable_name}")
        return None
    except Exception as e:
        logger.error(f"Error running hyq command: {e}")
        return None


def update_border_radius():
    css_filepath = os.path.join(
        str(xdg_config_home()), "waybar", "includes", "border-radius.css"
    )
    logger.debug(f"Updating border radius in {css_filepath}")

    ensure_directory_exists(css_filepath)
    logger.debug("Directory for border-radius.css ensured")

    if not os.path.exists(css_filepath):
        for includes_dir in INCLUDES_DIRS:
            template_path = os.path.join(includes_dir, "border-radius.css")
            if os.path.exists(template_path):
                logger.debug(
                    f"Found template at {template_path}, copying to {css_filepath}"
                )
                shutil.copyfile(template_path, css_filepath)
                break
        else:
            logger.error("Template for border-radius.css not found in INCLUDES_DIRS")
            return

    border_radius = os.getenv("WAYBAR_BORDER_RADIUS")
    logger.debug(f"WAYBAR_BORDER_RADIUS environment variable: {border_radius}")

    if not border_radius:
        logger.debug(f"Looking for theme name in state file: {STATE_FILE}")

        theme_name = None
        if os.path.exists(STATE_FILE):
            try:
                with open(STATE_FILE, "r") as file:
                    for line in file:
                        if line.startswith("HYDE_THEME="):
                            theme_name = (
                                line.strip().split("=", 1)[1].strip('"').strip("'")
                            )
                            logger.debug(
                                f"Found theme name in state file: {theme_name}"
                            )
                            break
            except Exception as e:
                logger.error(f"Error reading state file: {e}")

        if theme_name:
            theme_dir = os.path.join(
                str(xdg_config_home()), "hyde", "themes", theme_name
            )
            logger.debug(f"Looking for theme directory at: {theme_dir}")

            if os.path.exists(theme_dir):
                hypr_theme_path = os.path.join(theme_dir, "hypr.theme")
                if os.path.exists(hypr_theme_path):
                    logger.debug(f"Found hypr.theme at {hypr_theme_path}")

                    try:
                        import shlex

                        cmd = [
                            "hyq",
                            shlex.quote(hypr_theme_path),
                            "--query",
                            "decoration:rounding",
                        ]
                        logger.debug(f"Running command: {' '.join(cmd)}")

                        border_radius_result = subprocess.run(
                            cmd, capture_output=True, text=True
                        )

                        logger.debug(
                            f"hyq command output: {border_radius_result.stdout.strip()}"
                        )
                        logger.debug(
                            f"hyq command stderr: {border_radius_result.stderr.strip() if border_radius_result.stderr else 'None'}"
                        )
                        logger.debug(
                            f"hyq exit code: {border_radius_result.returncode}"
                        )

                        if border_radius_result.stdout:
                            output_lines = border_radius_result.stdout.strip().split(
                                "\n"
                            )
                            for line in reversed(output_lines):
                                clean_line = line.strip()
                                if clean_line.isdigit():
                                    border_radius = int(clean_line)
                                    logger.debug(
                                        f"Successfully parsed border radius from hyq: {border_radius}"
                                    )
                                    break
                            else:
                                last_line = output_lines[-1].strip()
                                try:
                                    border_radius = int(last_line)
                                    logger.debug(
                                        f"Successfully parsed border radius from hyq last line: {border_radius}"
                                    )
                                except ValueError:
                                    logger.debug(
                                        f"Failed to parse border radius from hyq output: '{last_line}'"
                                    )
                                    border_radius = None
                        else:
                            logger.debug("Empty output from hyq command")
                            border_radius = None
                    except Exception as e:
                        logger.error(f"Error running hyq command: {e}")
                        border_radius = None
                else:
                    logger.debug(f"hypr.theme not found at {hypr_theme_path}")
            else:
                logger.debug(f"Theme directory not found at {theme_dir}")

    if not border_radius:
        logger.debug("Trying to get border radius from hyprctl")
        result = subprocess.run(
            ["hyprctl", "getoption", "decoration:rounding", "-j"],
            capture_output=True,
            text=True,
        )

        if result.returncode == 0:
            logger.debug(f"hyprctl command succeeded: {result.stdout}")
            try:
                data = json.loads(result.stdout)
                border_radius = data.get("int", 3)
                logger.debug(f"Parsed border radius from hyprctl: {border_radius}")
            except (json.JSONDecodeError, ValueError) as e:
                logger.error(f"Failed to parse JSON output: {e}")
                border_radius = 3
                logger.debug(f"Using fallback border radius: {border_radius}")
        else:
            logger.error(f"Failed to run hyprctl command: {result.stderr}")
            border_radius = 2
            logger.debug(f"Using second fallback border radius: {border_radius}")

    if border_radius is None or border_radius < 1:
        border_radius = 2
        logger.debug(f"Border radius is invalid, using default: {border_radius}")

    logger.debug(f"Final border radius value: {border_radius}")

    with open(css_filepath, "r") as file:
        content = file.read()
    logger.debug(f"Read {len(content)} bytes from {css_filepath}")

    updated_content = re.sub(r"\d+pt", f"{border_radius}pt", content)
    logger.debug("Applied border radius value to CSS content")

    with open(css_filepath, "w") as file:
        file.write(updated_content)
    logger.debug(f"Successfully updated border radius in {css_filepath}")


def generate_includes():
    includes_file = os.path.join(
        str(xdg_config_home()), "waybar", "includes", "includes.json"
    )

    ensure_directory_exists(includes_file)

    if os.path.exists(includes_file):
        with open(includes_file, "r") as file:
            includes_data = json.load(file)
    else:
        includes_data = {"include": []}

    includes = []
    for directory in MODULE_DIRS:
        if not os.path.isdir(directory):
            logger.debug(f"Directory '{directory}' does not exist, skipping...")
            continue
        includes.extend(glob.glob(os.path.join(directory, "*.json")))
        includes.extend(glob.glob(os.path.join(directory, "*.jsonc")))

    includes_data["include"] = list(dict.fromkeys(includes))

    with open(includes_file, "w") as file:
        json.dump(includes_data, file, indent=4)
    logger.debug(
        f"Successfully updated '{includes_file}' with {len(includes)} entries."
    )


def update_config(config_path):
    CONFIG_JSONC = os.path.join(str(xdg_config_home()), "waybar", "config.jsonc")
    shutil.copyfile(config_path, CONFIG_JSONC)
    logger.debug(f"Successfully copied config from '{config_path}' to '{CONFIG_JSONC}'")


def update_style(style_path):
    style_filepath = os.path.join(str(xdg_config_home()), "waybar", "style.css")
    user_style_filepath = os.path.join(
        str(xdg_config_home()), "waybar", "user-style.css"
    )
    theme_style_filepath = os.path.join(str(xdg_config_home()), "waybar", "theme.css")

    ensure_directory_exists(user_style_filepath)

    if not os.path.exists(user_style_filepath):
        with open(user_style_filepath, "w") as file:
            file.write("/* User custom styles */\n")
        logger.debug(f"Created '{user_style_filepath}'")

    if not os.path.exists(theme_style_filepath):
        logger.error(
            f"Missing '{theme_style_filepath}', Please run 'hyde-shell reload' to generate it."
        )

    if not style_path:
        current_layout = get_current_layout_from_config()
        logger.debug(f"Detected current layout: '{current_layout}'")
        if not current_layout:
            logger.error("Failed to get current layout from config.")
            sys.exit(1)
        style_path = resolve_style_path(current_layout)
    if not os.path.exists(style_path):
        logger.error(f"Cannot reconcile style path: {style_path}")
        sys.exit(1)
    write_style_file(style_filepath, style_path)


def watch_waybar():
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)
    lock_file = os.path.join(str(xdg_runtime_dir()), "hyde", "waybar_hide.lock")
    lock_file_path = Path(lock_file)

    while True:
        try:
            if lock_file_path.exists():
                time.sleep(2)
                continue

            result = subprocess.run(["ps", "-C", "waybar"], capture_output=True)
            if result.returncode != 0:
                run_waybar_command("killall waybar; waybar & disown")
                logger.debug("Waybar restarted")
        except Exception as e:
            logger.error(f"Error monitoring Waybar: {e}")
        time.sleep(2)


if __name__ == "__main__":
    main()
