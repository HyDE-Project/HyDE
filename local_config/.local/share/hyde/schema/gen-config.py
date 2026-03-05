#!/usr/bin/env python

import tomllib as toml
import os
import argparse


def generate_default_config(toml_file_path):
    """Generate a default config.toml file from the schema."""
    
    def extract_defaults(properties, prefix=""):
        """Recursively extract default values from the schema."""
        config_lines = []
        
        for key, value in properties.items():
            if key.startswith("$") or key == "type":
                continue
                
            current_key = f"{prefix}.{key}" if prefix else key
            
            if isinstance(value, dict):
                if "default" in value:
                    # This is a leaf node with a default value
                    default_val = value["default"]
                    description = value.get("description", "")
                    
                    # Format the default value appropriately
                    if isinstance(default_val, str):
                        if '"' in default_val:
                            formatted_val = f"'{default_val}'"
                        else:
                            formatted_val = f'"{default_val}"'
                    elif isinstance(default_val, list):
                        if not default_val:  # Empty list
                            formatted_val = "[]"
                        else:
                            # Format list elements
                            formatted_items = []
                            for item in default_val:
                                if isinstance(item, str):
                                    if '"' in item:
                                        formatted_items.append(f"'{item}'")
                                    else:
                                        formatted_items.append(f'"{item}"')
                                else:
                                    formatted_items.append(str(item))
                            formatted_val = f"[{', '.join(formatted_items)}]"
                    elif isinstance(default_val, bool):
                        formatted_val = str(default_val).lower()
                    else:
                        formatted_val = str(default_val)
                    
                    config_lines.append(f"{key} = {formatted_val}  # {description}")
                    
                elif "properties" in value:
                    # This is a section with subsections
                    if "description" in value:
                        config_lines.append(f"# {value['description']}")
                    config_lines.append(f"[{current_key}]")
                    config_lines.extend(extract_defaults(value["properties"], current_key))
                    config_lines.append("")  # Add empty line after each section
        
        return config_lines

    with open(toml_file_path, "rb") as toml_file:
        toml_content = toml.load(toml_file)
    
    # Start with header
    config_lines = [
        "# HyDE Configuration File",
        "# This file contains default values for all configuration options",
        "# Generated from schema",
        "",
        "\"$schema\" = \"https://raw.githubusercontent.com/HyDE-Project/HyDE/refs/heads/master/Configs/.local/share/hyde/schema/config.toml.json\"",
        "",
    ]
    
    # Extract properties
    if "properties" in toml_content:
        config_lines.extend(extract_defaults(toml_content["properties"]))
    
    return "\n".join(config_lines)


def main():
    parser = argparse.ArgumentParser(
        description="Generate default config.toml from schema."
    )
    parser.add_argument(
        "file",
        nargs="?",
        default="./config.toml",
        help="Path to the TOML schema file (default: ./config.toml)",
    )
    args = parser.parse_args()

    toml_file_path = args.file
    if not os.path.exists(toml_file_path):
        print(f"Error: {toml_file_path} does not exist.")
        return

    config_content = generate_default_config(toml_file_path)
    print(config_content)


if __name__ == "__main__":
    main()
