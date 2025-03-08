#!/usr/bin/env python3

import json
import os
import glob
import logging
import subprocess
import re
import argparse
import shutil
import time
import sys
import hashlib
import signal


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

if os.getenv("DEBUG"):
    logger.setLevel(logging.DEBUG)


MODULE_DIRS = [
    os.path.expanduser(os.getenv("XDG_CONFIG_HOME", "~/.config") + "/waybar/modules/"),
    os.path.expanduser(
        os.getenv("XDG_DATA_HOME", "~/.local/share") + "/waybar/modules/"
    ),
    "/usr/local/share/waybar/modules/",
    "/usr/share/waybar/modules/",
]

LAYOUT_DIRS = [
    os.path.expanduser(os.getenv("XDG_CONFIG_HOME", "~/.config") + "/waybar/layouts"),
    os.path.expanduser(
        os.getenv("XDG_DATA_HOME", "~/.local/share") + "/waybar/layouts"
    ),
    "/usr/local/share/waybar/layouts",
    "/usr/share/waybar/layouts",
]

STYLE_DIRS = [
    os.path.expanduser(os.getenv("XDG_CONFIG_HOME", "~/.config") + "/waybar/styles"),
    os.path.expanduser(os.getenv("XDG_DATA_HOME", "~/.local/share") + "/waybar/styles"),
]

INCLUDES_DIRS = [
    os.path.expanduser(os.getenv("XDG_CONFIG_HOME", "~/.config") + "/waybar/includes"),
    os.path.expanduser(
        os.getenv("XDG_DATA_HOME", "~/.local/share") + "/waybar/includes"
    ),
    "/usr/local/share/waybar/includes",
    "/usr/share/waybar/includes",
]

CONFIG_JSONC = os.path.expanduser(
    os.getenv("XDG_CONFIG_HOME", "~/.config") + "/waybar/config.jsonc"
)


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


LAYOUT_DIRS = [
    os.path.expanduser(os.getenv("XDG_CONFIG_HOME", "~/.config") + "/waybar/layouts"),
    os.path.expanduser(
        os.getenv("XDG_DATA_HOME", "~/.local/share") + "/waybar/layouts"
    ),
    "/usr/local/share/waybar/layouts",
    "/usr/share/waybar/layouts",
]


def find_layout_files():
    """Recursively find all layout files in the specified directories."""
    layouts = []
    for layout_dir in LAYOUT_DIRS:
        for root, _, files in os.walk(layout_dir):
            for file in files:
                if file.endswith(".jsonc"):
                    layouts.append(os.path.join(root, file))
    return sorted(layouts)


def get_current_layout_from_config():
    """Get the current layout by comparing the hash of the files in the layout directories with the current config.jsonc."""
    logger.debug("Getting current layout from config")
    CONFIG_JSONC = os.path.expanduser(
        os.getenv("XDG_CONFIG_HOME", "~/.config") + "/waybar/config.jsonc"
    )
    logger.debug(f"Checking config: {CONFIG_JSONC}")
    if not os.path.exists(CONFIG_JSONC):
        logger.error("Config file not found")
        os.makedirs(os.path.dirname(CONFIG_JSONC), exist_ok=True)
        with open(CONFIG_JSONC, "w") as f:
            json.dump({}, f)
    config_hash = get_file_hash(CONFIG_JSONC)
    layouts = find_layout_files()
    for layout in layouts:
        if get_file_hash(layout) == config_hash:
            logger.debug(f"Found current layout: {layout}")
            return layout
        layout = None
    if not layout:
        logger.debug("No current layout found")
        config_dir = os.path.dirname(CONFIG_JSONC)
        layouts_dir = os.path.join(config_dir, "layouts")
        os.makedirs(layouts_dir, exist_ok=True)
        timestamp = time.strftime("%Y%m%d_%H%M%S")
        backup_path = os.path.join(layouts_dir, f"{timestamp}_config.jsonc")
        shutil.copyfile(CONFIG_JSONC, backup_path)
        logger.debug(f"Saved current config to {backup_path}")
        layouts = find_layout_files()
        layout = layouts[0]
    return layout


def ensure_state_file():
    """Ensure the state file has the necessary entries."""
    state_file = os.path.expanduser(
        os.getenv("HYDE_STATE_HOME", "~/.local/state") + "/staterc"
    )
    if not os.path.exists(state_file) or os.path.getsize(state_file) == 0:
        current_layout = get_current_layout_from_config()
        if current_layout:
            with open(state_file, "w") as file:
                file.write(f"WAYBAR_LAYOUT_PATH={current_layout}\n")
                style_path = resolve_style_path(current_layout)
                file.write(f"WAYBAR_STYLE_PATH={style_path}\n")
    else:
        with open(state_file, "r") as file:
            lines = file.readlines()
        layout_path_exists = any(
            line.startswith("WAYBAR_LAYOUT_PATH=") for line in lines
        )
        style_path_exists = any(line.startswith("WAYBAR_STYLE_PATH=") for line in lines)
        if not layout_path_exists or not style_path_exists:
            current_layout = get_current_layout_from_config()
            if current_layout:
                with open(state_file, "a") as file:
                    if not layout_path_exists:
                        file.write(f"WAYBAR_LAYOUT_PATH={current_layout}\n")
                    if not style_path_exists:
                        style_path = resolve_style_path(current_layout)
                        file.write(f"WAYBAR_STYLE_PATH={style_path}\n")


def resolve_style_path(layout_path):
    """Resolve the style path based on the layout path."""
    name = os.path.basename(layout_path).replace(".jsonc", "")

    for style_dir in STYLE_DIRS:
        style_path = glob.glob(os.path.join(style_dir, f"{name}*.css"))

        if style_path:
            logger.debug(f"Resolved style path: {style_path[0]}")
            return style_path[0]

        name = name.split("#")[0]
        style_path = glob.glob(os.path.join(style_dir, f"{name}*.css"))
        if style_path:
            logger.debug(f"Resolved style path with #: {style_path[0]}")
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
    layout_style_pairs = list_layouts()
    layout_path = None

    for pair in layout_style_pairs:
        if layout == pair["layout"] or layout == pair["name"]:
            layout_path = pair["layout"]
            break

    if not layout_path:
        logger.error(f"Layout {layout} not found")
        sys.exit(1)

    style_path = resolve_style_path(layout_path)

    state_file = os.path.expanduser(
        os.getenv("HYDE_STATE_HOME", "~/.local/state") + "/staterc"
    )
    with open(state_file, "r") as file:
        lines = file.readlines()
    with open(state_file, "w") as file:
        for line in lines:
            if line.startswith("WAYBAR_LAYOUT_PATH="):
                file.write(f"WAYBAR_LAYOUT_PATH={layout_path}\n")
            elif line.startswith("WAYBAR_STYLE_PATH="):
                file.write(f"WAYBAR_STYLE_PATH={style_path}\n")
            else:
                file.write(line)

    CONFIG_JSONC = os.path.expanduser(
        os.getenv("XDG_CONFIG_HOME", "~/.config") + "/waybar/config.jsonc"
    )
    style_filepath = os.path.expanduser(
        os.getenv("XDG_CONFIG_HOME", "~/.config") + "/waybar/style.css"
    )
    shutil.copyfile(layout_path, CONFIG_JSONC)
    write_style_file(style_filepath, style_path)
    subprocess.run(["pkill", "-SIGUSR2", "waybar"])


def handle_layout_navigation(option):
    """Handle --next, --prev, and --set options."""
    layouts = find_layout_files()
    state_file = os.path.expanduser(
        os.getenv("HYDE_STATE_HOME", "~/.local/state") + "/staterc"
    )
    current_layout = None
    with open(state_file, "r") as file:
        for line in file:
            if line.startswith("WAYBAR_LAYOUT_PATH="):
                current_layout = line.split("=")[1].strip()
                break

    if not current_layout:
        logger.error("Current layout not found in state file.")
        return

    if current_layout not in layouts:
        logger.warning("Current layout file not found, re-caching layouts.")
        current_layout = get_current_layout_from_config()
        if not current_layout:
            logger.error("Failed to recache current layout.")
            return

    current_index = layouts.index(current_layout)
    if option == "--next":
        next_index = (current_index + 1) % len(layouts)
        set_layout(layouts[next_index])
    elif option == "--prev":
        prev_index = (current_index - 1 + len(layouts)) % len(layouts)
        set_layout(layouts[prev_index])
    elif option == "--set":
        if len(sys.argv) < 3:
            logger.error("Usage: --set <layout>")
            return
        layout = sys.argv[2]
        set_layout(layout)


def list_layouts():
    """List all layouts with their matching styles."""
    layouts = find_layout_files()
    layout_style_pairs = []
    for layout in layouts:
        for layout_dir in LAYOUT_DIRS:
            if layout.startswith(layout_dir):
                relative_path = os.path.relpath(layout, start=layout_dir)
                name = relative_path.replace(".jsonc", "")
                style_path = resolve_style_path(layout)
                layout_style_pairs.append(
                    {"layout": layout, "name": name, "style": style_path}
                )
                break
    return layout_style_pairs


def list_layouts_json():
    """List all layouts in JSON format with their matching styles."""
    layout_style_pairs = list_layouts()
    layouts_json = json.dumps(layout_style_pairs, indent=4)
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
    wallbash_gtk_css_file = os.path.expanduser(
        os.getenv("XDG_CACHE_HOME", "~/.cache") + "/hyde/wallbash/gtk.css"
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
    *    ░▒▒░░▓▓   ▓▓   |__  |____/ |____/
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
    log_dir = os.path.expanduser(os.getenv("XDG_RUNTIME_DIR", "/tmp") + "/hyde")
    os.makedirs(log_dir, exist_ok=True)
    log_file = os.path.join(log_dir, "waybar.log")
    with open(log_file, "a") as file:
        file.write(
            f"{time.strftime('%Y-%m-%d %H:%M:%S')} - Running command: {command}\n"
        )
        subprocess.run(command, shell=True, stdout=file, stderr=file)
    logger.debug(f"Waybar log written to '{log_file}'")


def list_layout_names():
    """List all layout layout_names."""
    layout_style_pairs = list_layouts()
    layout_names = [pair["name"] for pair in layout_style_pairs]
    for name in layout_names:
        print(name)
    sys.exit(0)


def kill_waybar():
    """Kill any running Waybar instances and the watcher script."""
    subprocess.run(["pkill", "-f", "waybar"])
    logger.debug("Killed all Waybar instances and watcher script.")


def ensure_directory_exists(filepath):
    """Ensure the directory for the given filepath exists."""
    directory = os.path.dirname(filepath)
    if not os.path.exists(directory):
        os.makedirs(directory)


def main():
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
    args = parser.parse_args()

    ensure_state_file()

    source_env_file(
        os.path.expanduser(
            os.getenv("XDG_RUNTIME_DIR", "~/.runtime") + "/hyde/environment"
        )
    )
    source_env_file(
        os.path.expanduser(
            os.getenv("XDG_STATE_HOME", "~/.local/state") + "/hyde/config"
        )
    )
    get_current_layout_from_config()
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
        list_layout_names()
    if args.kill:
        kill_waybar()
        sys.exit(0)

    if args.watch:
        watch_waybar()
    else:
        update_icon_size()
        update_border_radius()
        generate_includes()
        update_style(args.style)
        run_waybar_command("killall waybar; waybar & disown")
        return

    if not any(vars(args).values()):
        parser.print_help()
        sys.exit(0)


def update_icon_size():
    includes_file = os.path.join(
        os.getenv("XDG_CONFIG_HOME", os.path.expanduser("~/.config")),
        "waybar/includes",
        "includes.json",
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

    font_size = os.getenv("WAYBAR_FONT_SIZE", os.getenv("FONT_SIZE", "10"))
    icon_size = int(os.getenv("WAYBAR_ICON_SIZE", font_size) or "10")

    updated_entries = {}

    for directory in MODULE_DIRS:
        for json_file in glob.glob(os.path.join(directory, "*.json")):
            data = parse_json_file(json_file)

            for key, value in data.items():
                if isinstance(value, dict):
                    icon_size_multiplier = value.get("icon-size-multiplier", 1)
                    final_icon_size = icon_size * icon_size_multiplier

                    data[key] = modify_json_key(value, "icon-size", final_icon_size)
                    data[key] = modify_json_key(
                        value, "tooltip-icon-size", final_icon_size
                    )

            updated_entries.update(data)

    includes_data.update(updated_entries)

    with open(includes_file, "w") as file:
        json.dump(includes_data, file, indent=4)
    logger.debug(
        f"Successfully updated icon sizes and appended to '{includes_file}' with {len(updated_entries)} entries."
    )


def update_global_css():
    global_css_path = os.path.expanduser(
        os.getenv("XDG_CONFIG_HOME", "~/.config") + "/waybar/includes/global.css"
    )

    ensure_directory_exists(global_css_path)

    if not os.path.exists(global_css_path):
        for includes_dir in INCLUDES_DIRS:
            template_path = os.path.join(includes_dir, "global.css")
            if os.path.exists(template_path):
                shutil.copyfile(template_path, global_css_path)
                break
        else:
            logger.error("Template for global.css not found in INCLUDES_DIRS")
            return


def update_border_radius():
    css_filepath = os.path.expanduser(
        os.getenv("XDG_CONFIG_HOME", "~/.config") + "/waybar/includes/border-radius.css"
    )

    ensure_directory_exists(css_filepath)

    if not os.path.exists(css_filepath):
        for includes_dir in INCLUDES_DIRS:
            template_path = os.path.join(includes_dir, "border-radius.css")
            if os.path.exists(template_path):
                shutil.copyfile(template_path, css_filepath)
                break
        else:
            logger.error("Template for border-radius.css not found in INCLUDES_DIRS")
            return

    border_radius = os.getenv("WAYBAR_BORDER_RADIUS")

    if not border_radius:
        hyde_hypr_theme = os.path.join(os.getenv("HYDE_THEME_DIR", ""), "hypr.theme")

        border_radius = subprocess.run(
            ["hyq", hyde_hypr_theme, "--query", "decoration:rounding"],
            capture_output=True,
            text=True,
        )
        border_radius = (
            int(border_radius.stdout.strip()) if border_radius.stdout else None
        )

    if not border_radius:
        result = subprocess.run(
            ["hyprctl", "getoption", "decoration:rounding", "-j"],
            capture_output=True,
            text=True,
        )

        if result.returncode == 0:
            try:
                data = json.loads(result.stdout)
                border_radius = data.get("int", 3)
            except json.JSONDecodeError as e:
                logger.error(f"Failed to parse JSON output: {e}")
                border_radius = 3
        else:
            logger.error(f"Failed to run hyprctl command: {result.stderr}")
            border_radius = 2

    if border_radius is None or border_radius < 1:
        border_radius = 2
    with open(css_filepath, "r") as file:
        content = file.read()
    updated_content = re.sub(r"\d+pt", f"{border_radius}pt", content)
    with open(css_filepath, "w") as file:
        file.write(updated_content)


def generate_includes():
    includes_file = os.path.join(
        os.getenv("XDG_CONFIG_HOME", os.path.expanduser("~/.config")),
        "waybar",
        "includes",
        "includes.json",
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
    xdg_config_home = os.getenv("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
    CONFIG_JSONC = os.path.join(xdg_config_home, "waybar", "config.jsonc")
    shutil.copyfile(config_path, CONFIG_JSONC)
    logger.debug(f"Successfully copied config from '{config_path}' to '{CONFIG_JSONC}'")


def update_style(style_path):
    xdg_config_home = os.getenv("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
    style_filepath = os.path.join(xdg_config_home, "waybar", "style.css")
    user_style_filepath = os.path.join(xdg_config_home, "waybar", "user-style.css")
    theme_style_filepath = os.path.join(xdg_config_home, "waybar", "theme.css")

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
    while True:
        try:
            result = subprocess.run(["pgrep", "waybar"], capture_output=True)
            if result.returncode != 0:
                run_waybar_command("killall waybar; waybar & disown")
                logger.debug("Waybar restarted")
        except Exception as e:
            logger.error(f"Error monitoring Waybar: {e}")
        time.sleep(2)


if __name__ == "__main__":
    main()
