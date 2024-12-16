#!/bin/env python
import tomllib
import sys
import os
import time
import threading
import subprocess
import argparse


def parse_toml_to_env(toml_file, env_file=None, export=False):
    try:
        with open(toml_file, "rb") as file:
            toml_content = tomllib.load(file)
    except Exception as e:
        error_message = f"Error parsing TOML file: {e}"
        print(error_message)
        subprocess.run(["notify-send", "HyDE Error", error_message])
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
        with open(env_file, "w") as file:
            file.write("\n".join(output) + "\n")
        print(f"Environment variables have been written to {env_file}")
    else:
        print("\n".join(output))


def watch_toml(toml_file, env_file=None, export=False):
    last_mtime = os.path.getmtime(toml_file)
    while True:
        time.sleep(1)
        current_mtime = os.path.getmtime(toml_file)
        if current_mtime != last_mtime:
            last_mtime = current_mtime
            parse_toml_to_env(toml_file, env_file, export)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Parse TOML file to environment variables."
    )
    parser.add_argument("input_toml_file", help="Input TOML file")
    parser.add_argument("--output-toml", help="Output environment file", default=None)
    parser.add_argument(
        "--watch-toml",
        action="store_true",
        help="Watch TOML file for changes",
    )

    parser.add_argument("--export", action="store_true", help="Export variables")

    args = parser.parse_args()

    input_toml_file = args.input_toml_file
    output_env_file = args.output_toml
    daemon_mode = args.watch_toml
    export_mode = args.export

    if daemon_mode:
        # Generate the config on launch
        parse_toml_to_env(input_toml_file, output_env_file, export_mode)

        watcher_thread = threading.Thread(
            target=watch_toml,
            args=(input_toml_file, output_env_file, export_mode),
        )
        watcher_thread.daemon = True
        watcher_thread.start()
        print(f"Watching {input_toml_file} for changes...")
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            print("Daemon mode stopped.")
    else:
        parse_toml_to_env(input_toml_file, output_env_file, export_mode)
