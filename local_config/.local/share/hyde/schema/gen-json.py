#!/usr/bin/env python

import tomllib as toml
import json
import os
import argparse


def toml_to_json(toml_file_path):
    """Convert TOML file to JSON schema."""
    with open(toml_file_path, "rb") as toml_file:
        toml_content = toml.load(toml_file)
    json_content = json.dumps(toml_content, indent=4)
    return json_content


def main():
    parser = argparse.ArgumentParser(
        description="Generate JSON schema from TOML file."
    )
    parser.add_argument(
        "file",
        nargs="?",
        default="./config.toml",
        help="Path to the TOML file (default: ./config.toml)",
    )
    args = parser.parse_args()

    toml_file_path = args.file
    if not os.path.exists(toml_file_path):
        print(f"Error: {toml_file_path} does not exist.")
        return

    json_content = toml_to_json(toml_file_path)
    print(json_content)


if __name__ == "__main__":
    main()
