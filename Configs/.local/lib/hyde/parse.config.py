#!/usr/bin/env python
import tomllib
import argparse
import os
import time
import threading
import subprocess
import pyutils.logger as logger

logger = logger.get_logger()


def parse_toml_to_env(toml_file, env_file=None, export=False):
    try:
        with open(toml_file, "rb") as file:
            toml_content = tomllib.load(file)
    except FileNotFoundError as e:
        error_message = f"TOML file not found: {e}"
        logger.error("TOML file not found: %s", e)
        subprocess.run(["notify-send", "HyDE Error", error_message], check=True)
        return
    except tomllib.TOMLDecodeError as e:
        error_message = f"Error decoding TOML file: {e}"
        logger.error("Error decoding TOML file: %s", e)
        subprocess.run(["notify-send", "HyDE Error", error_message], check=True)
        return
    except IOError as e:
        error_message = f"IO error: {e}"
        logger.error("IO error: %s", e)
        subprocess.run(["notify-send", "HyDE Error", error_message], check=True)
        return

    def flatten_dict(d, parent_key=""):
        items = []
        for k, v in d.items():
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
            "Environment variables have been written to %s", env_file
        )  # Use % lazy formatting for better performance in logger

    else:
        logger.debug("\n".join(output))


def watch_file(toml_file, env_file=None, export=False):
    last_mtime = os.path.getmtime(toml_file)
    while True:
        time.sleep(1)
        current_mtime = os.path.getmtime(toml_file)
        if current_mtime != last_mtime:
            last_mtime = current_mtime
            parse_toml_to_env(toml_file, env_file, export)


def parse_args():
    parser = argparse.ArgumentParser(
        description="Parse a TOML file and optionally watch for changes."
    )
    parser.add_argument("input_toml_file", help="The input TOML file to parse.")
    parser.add_argument(
        "output_env_file", nargs="?", help="The output environment file."
    )
    parser.add_argument(
        "--daemon", action="store_true", help="Run in daemon mode to watch for changes."
    )
    parser.add_argument("--export", action="store_true", help="Export the parsed data.")
    return parser.parse_args()


def main():
    args = parse_args()

    input_toml_file = args.input_toml_file
    output_env_file = args.output_env_file
    daemon_mode = args.daemon
    export_mode = args.export

    if daemon_mode:
        # Generate the config on launch
        parse_toml_to_env(input_toml_file, output_env_file, export_mode)

        watcher_thread = threading.Thread(
            target=watch_file, args=(input_toml_file, output_env_file, export_mode)
        )
        watcher_thread.daemon = True
        watcher_thread.start()
        logger.debug("Watching %s for changes...", input_toml_file)  # Same as line 77
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            logger.info("Daemon mode stopped.")
    else:
        parse_toml_to_env(input_toml_file, output_env_file, export_mode)


if __name__ == "__main__":
    main()
