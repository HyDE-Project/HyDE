#!/bin/env python
import tomllib
import argparse
import logging
import os
import time
import threading
import subprocess


def fmt_logging():
    class ColoredFormatter(logging.Formatter):
        COLORS = {
            "DEBUG": "\033[94m",  # Blue
            "INFO": "\033[92m",  # Green
            "WARNING": "\033[93m",  # Yellow
            "ERROR": "\033[91m",  # Red
            "CRITICAL": "\033[95m",  # Magenta
        }
        RESET = "\033[0m"
        DATE_COLOR = "\033[96m"  # Cyan

        def format(self, record):
            log_color = self.COLORS.get(record.levelname, self.RESET)
            record.levelname = f"{log_color}{record.levelname}{self.RESET}"
            record.asctime = (
                f"{self.DATE_COLOR}{self.formatTime(record, self.datefmt)}{self.RESET}"
            )
            return super().format(record)

    log_level = os.getenv("LOG_LEVEL", "INFO").upper()
    log_format = os.getenv(
        "LOG_FORMAT", "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )
    formatter = ColoredFormatter(log_format)
    handler = logging.StreamHandler()
    handler.setFormatter(formatter)
    logging.basicConfig(level=log_level, handlers=[handler])


def parse_toml_to_env(toml_file, env_file=None, export=False):
    try:
        with open(toml_file, "rb") as file:
            toml_content = tomllib.load(file)
    except Exception as e:
        error_message = f"Error parsing TOML file: {e}"
        logging.error(error_message)
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
        logging.debug(f"Environment variables have been written to {env_file}")

    else:
        logging.debug("\n".join(output))


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
    fmt_logging()
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
        logging.debug(f"Watching {input_toml_file} for changes...")
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            logging.info("Daemon mode stopped.")
    else:
        parse_toml_to_env(input_toml_file, output_env_file, export_mode)


if __name__ == "__main__":
    main()
