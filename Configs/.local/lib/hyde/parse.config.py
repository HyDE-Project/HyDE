#!/usr/bin/env python
import tomllib
import argparse
import os
import time
import threading
import pyutils.logger as logger
import pyutils.wrapper.libnotify as notify
from pyutils.xdg_base_dirs import (
    xdg_config_home,
    xdg_state_home,
)


logger = logger.get_logger()


def load_toml_file(toml_file):
    try:
        with open(toml_file, "rb") as file:
            return tomllib.load(file)
    except FileNotFoundError as e:
        error_message = f"TOML file not found: {e}"
        logger.error("TOML file not found: %s", e)
        notify.send("HyDE Error", error_message)
        return None
    except tomllib.TOMLDecodeError as e:
        error_message = f"Error decoding TOML file: {e}"
        logger.error(f"Error decoding TOML file: {e}")
        notify.send("HyDE Error", error_message)
        return None
    except IOError as e:
        error_message = f"IO error: {e}"
        logger.error("IO error: %s", e)
        notify.send("HyDE Error", error_message)
        return None


def parse_toml_to_env(toml_file, env_file=None, export=False):
    ignored_keys = [
        "$schema",
        "$SCHEMA",
        "hyprland",
        "hyprland-ipc",
        "hyprland-start",
        "hyprland-env",
    ]

    toml_content = load_toml_file(toml_file)
    if toml_content is None:
        return

    def flatten_dict(d, parent_key=""):
        logger.debug(f"Parent key: {parent_key}")
        items = []
        for k, v in d.items():
            # Skip if current key or parent key is in ignored keys
            if k in ignored_keys or parent_key.startswith("hyprland"):
                logger.debug(f"Skipping ignored key: {k}")
                continue

            if k.startswith("$"):
                continue
            new_key = f"{parent_key}_{k.upper()}" if parent_key else k.upper()
            if isinstance(v, dict):
                items.extend(flatten_dict(v, new_key).items())
            elif isinstance(v, list):
                array_items = " ".join(f'"{item}"' for item in v)
                items.append((new_key, f"({array_items})"))
            elif isinstance(v, bool):
                items.append((new_key, str(v).lower()))
            elif isinstance(v, int):
                items.append((new_key, v))
            else:
                items.append((new_key, f'"{v}"'))
        return dict(items)

    flat_toml_content = flatten_dict(toml_content)
    output = [
        f"export {key}={value}" if export else f"{key}={value}"
        for key, value in flat_toml_content.items()
    ]

    if env_file:
        with open(env_file, "w", encoding="UTF-8") as file:  # Use UTF-8 encoding
            file.write("\n".join(output) + "\n")
        logger.debug(
            f"Environment variables have been written to {env_file}"
        )  # Use % lazy formatting for better performance in logger

    else:
        logger.debug("\n".join(output))


def parse_toml_to_hypr(toml_file, hypr_file=None):
    logger.debug("Parsing Hyprland variables...")
    toml_content = load_toml_file(toml_file)
    if toml_content is None:
        return

    def flatten_hypr_dict(d, parent_key=""):
        logger.debug(f"Parent key: {parent_key}")
        items = []
        for k, v in d.items():
            logger.debug(f"Current key=val: {k}={v}")
            # Track if we're inside a hyprland section
            is_hyprland_section = k.startswith("hyprland") or parent_key.startswith(
                "hyprland"
            )

            if is_hyprland_section:
                logger.debug(f"Found hyprland key: {k}")
                # Remove 'hyprland_' prefix if it exists
                new_key = k.replace("hyprland_", "") if k.startswith("hyprland_") else k
                # If parent_key exists, combine it with current key
                if parent_key and not parent_key.startswith("hyprland"):
                    new_key = f"{parent_key}_{new_key}"
                elif parent_key.startswith("hyprland"):
                    new_key = (
                        f"${parent_key[9:]}.{new_key.upper()}"
                        if parent_key[9:]
                        else f"${new_key.upper()}"
                    )

                if isinstance(v, dict):
                    items.extend(flatten_hypr_dict(v, new_key).items())
                elif isinstance(v, list):
                    array_items = ", ".join(str(item) for item in v)
                    items.append((new_key, array_items))
                elif isinstance(v, bool):
                    items.append((new_key, str(v).lower()))
                elif isinstance(v, (int, float)):
                    items.append((new_key, str(v)))
                else:
                    items.append((new_key, str(v)))

            else:
                logger.debug(f"Skipping key: {k}")
        return dict(items)

    flat_toml_content = flatten_hypr_dict(toml_content)
    logger.debug(f"Toml Content {toml_content}")
    output = [f"{key}={value}" for key, value in flat_toml_content.items()]

    if not hypr_file:
        hypr_file = HYPR_FILE

    if hypr_file:
        with open(hypr_file, "w", encoding="UTF-8") as file:
            file.write("\n".join(output) + "\n")
        logger.debug(f"Hyprland variables have been written to {hypr_file}")
    else:
        logger.debug("No hypr file specified.")
        logger.debug("\n".join(output))


def watch_file(toml_file, env_file=None, export=False):
    last_mtime = os.path.getmtime(toml_file)
    while True:
        time.sleep(1)
        current_mtime = os.path.getmtime(toml_file)
        if current_mtime != last_mtime:
            last_mtime = current_mtime
            parse_toml_to_env(toml_file, env_file, export)
            parse_toml_to_hypr(toml_file)


def parse_args():
    parser = argparse.ArgumentParser(
        description="Parse a TOML file and optionally watch for changes."
    )
    parser.add_argument(
        "--input",
        default=os.path.join(
            xdg_config_home(),
            "hyde/config.toml",
        ),
        help="The input TOML file to parse. Default is $XDG_CONFIG_HOME/hyde/config.toml",
    )
    parser.add_argument(
        "--env",
        default=os.path.join(
            xdg_state_home(),
            "hyde/config",
        ),
        help="The output environment file. Default is $XDG_STATE_HOME/hyde/config",
    )
    parser.add_argument(
        "--hypr",
        default=os.path.join(
            xdg_state_home(),
            "hyde/hyprland.conf",
        ),
        help="The output Hyprland file. Default is $XDG_STATE_HOME/hyprland.conf",
    )
    parser.add_argument(
        "--daemon", action="store_true", help="Run in daemon mode to watch for changes."
    )
    parser.add_argument("--export", action="store_true", help="Export the parsed data.")
    return parser.parse_args()


def main():
    args = parse_args()

    global CONFIG_FILE, ENV_FILE, HYPR_FILE
    CONFIG_FILE = args.input
    ENV_FILE = args.env
    HYPR_FILE = args.hypr

    daemon_mode = args.daemon
    export_mode = args.export

    if daemon_mode:
        # Generate the config on launch
        parse_toml_to_hypr(CONFIG_FILE, HYPR_FILE)
        parse_toml_to_env(CONFIG_FILE, ENV_FILE, export_mode)

        watcher_thread = threading.Thread(
            target=watch_file, args=(CONFIG_FILE, ENV_FILE, export_mode)
        )
        watcher_thread.daemon = True
        watcher_thread.start()
        logger.debug("Watching %s for changes...", CONFIG_FILE)
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            logger.info("Daemon mode stopped.")
    else:
        parse_toml_to_env(CONFIG_FILE, ENV_FILE, export_mode)
        parse_toml_to_hypr(CONFIG_FILE, HYPR_FILE)


if __name__ == "__main__":
    main()
