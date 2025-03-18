#!/usr/bin/env python

import tomllib as toml
import json
import os
import argparse


def toml_to_json(toml_file_path):
    with open(toml_file_path, "rb") as toml_file:
        toml_content = toml.load(toml_file)
    json_content = json.dumps(toml_content, indent=4)
    return json_content


def toml_to_config(toml_file_path):
    def parse_section(section, parent_key=""):
        config_content = []
        for key, value in section.items():
            full_key = f"{parent_key}.{key}" if parent_key else key
            if isinstance(value, dict):
                if "description" in value or "default" in value:
                    config_content.append(f"[{full_key}]")
                config_content.extend(parse_section(value, full_key))
            else:
                if isinstance(value, list):
                    value = ", ".join(map(str, value))
                description = section.get("description", "")
                config_content.append(
                    f"{full_key.split('.')[-1]} = {value} # {description}"
                )
        return config_content

    def remap_structure(toml_content):
        remapped_content = {}
        for key, value in toml_content.items():
            if isinstance(value, dict):
                remapped_content[key] = remap_structure(value)
            else:
                remapped_content[key] = value
        return remapped_content

    def generate_output(remapped_content):
        output = []
        for key, value in remapped_content.items():
            if isinstance(value, dict):
                output.append(f"[{key}]")
                output.extend(generate_output(value))
            else:
                output.append(f"{key} = {value}")
        return output

    with open(toml_file_path, "rb") as toml_file:
        toml_content = toml.load(toml_file)
    remapped_content = remap_structure(toml_content)
    config_content = generate_output(remapped_content)
    config_content.insert(0, "# Configuration file for HyDE")
    config_content.insert(1, "# Environment variables should be on top")
    config_content.insert(
        2,
        "# Updated config.toml file can be found at $HOME/.local/share/hyde/config.toml",
    )
    config_content.insert(3, "WARP_ENABLE_WAYLAND = 1")
    config_content.insert(4, "")
    return "\n".join(config_content)


def main():
    parser = argparse.ArgumentParser(
        description="Generate JSON or table from TOML file."
    )
    parser.add_argument(
        "file",
        nargs="?",
        default="./config.toml",
        help="Path to the TOML file (default: ./config.toml)",
    )
    parser.add_argument("--json", action="store_true", help="Generate JSON output")
    parser.add_argument("--config", action="store_true", help="Generate config output")
    args = parser.parse_args()

    toml_file_path = args.file
    if not os.path.exists(toml_file_path):
        print(f"Error: {toml_file_path} does not exist.")
        return

    if args.json:
        json_content = toml_to_json(toml_file_path)
        print(json_content)
    elif args.config:
        config_content = toml_to_config(toml_file_path)
        print(config_content)
    else:
        print("Error: Please specify --json or --config option.")


if __name__ == "__main__":
    main()
