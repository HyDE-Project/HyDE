#!/usr/bin/env python

import tomllib as toml
import os
import argparse


def generate_markdown_table(toml_file_path):
    """Generate markdown tables from TOML schema."""
    
    def format_value(value):
        """Format a value for display in markdown table."""
        if isinstance(value, str):
            # Escape pipe characters in strings
            return value.replace("|", "\\|").replace("\n", " ")
        elif isinstance(value, list):
            if not value:
                return "[]"
            # Join list items with commas
            formatted_items = []
            for item in value:
                if isinstance(item, str):
                    formatted_items.append(f'"{item}"')
                else:
                    formatted_items.append(str(item))
            return f"[{', '.join(formatted_items)}]"
        elif isinstance(value, bool):
            return str(value).lower()
        else:
            return str(value)
    
    def generate_section_table(section_name, properties, description=""):
        """Generate a markdown table for a configuration section."""
        lines = []
        
        # Add section header
        clean_name = section_name.replace("properties.", "")
        lines.append(f"### [{clean_name}]")
        lines.append("")
        
        # Add description if available
        if description:
            lines.append(description)
            lines.append("")
        
        # Create table header
        lines.append("| Key | Description | Default |")
        lines.append("| --- | ----------- | ------- |")
        
        # Process each property in alphabetical order
        sorted_prop_keys = sorted(properties.keys())
        for key in sorted_prop_keys:
            value = properties[key]
            if isinstance(value, dict) and "default" in value:
                description = value.get("description", "")
                default = format_value(value["default"])
                lines.append(f"| {key} | {description} | {default} |")
        
        lines.append("")
        return lines
    
    def process_properties(properties, prefix=""):
        """Recursively process properties and generate tables."""
        all_lines = []
        
        # Sort keys alphabetically for consistent output
        sorted_keys = sorted(properties.keys())
        
        for key in sorted_keys:
            if key.startswith("$") or key == "type":
                continue
            
            value = properties[key]
            current_path = f"{prefix}.{key}" if prefix else key
            
            if isinstance(value, dict):
                if "properties" in value:
                    # This is a section with subsections
                    section_description = value.get("description", "")
                    
                    # Check if this section has direct properties with defaults
                    direct_props = {}
                    subsections = {}
                    
                    for subkey, subvalue in value["properties"].items():
                        if isinstance(subvalue, dict) and "default" in subvalue:
                            direct_props[subkey] = subvalue
                        elif isinstance(subvalue, dict) and "properties" in subvalue:
                            subsections[subkey] = subvalue
                    
                    # Generate table for direct properties if any exist
                    if direct_props:
                        all_lines.extend(generate_section_table(current_path, direct_props, section_description))
                    
                    # Process subsections recursively (will be sorted in recursive call)
                    if subsections:
                        all_lines.extend(process_properties(subsections, current_path))
                
                elif "default" in value:
                    # This is a leaf property, will be handled by parent
                    pass
        
        return all_lines

    with open(toml_file_path, "rb") as toml_file:
        toml_content = toml.load(toml_file)
    
    # Start with header
    output_lines = [
        "---",
    
        "HyDE exposes `xdg_config/hyde/config.toml` file for users to modify. This lets users have the ability to interact the scripts without using command arguments.",
        "",
        "Users are encouraged to use an editor that support schema validation to ensure the configuration file is valid.",
        "```toml",
        "\"$schema\" = \"https://raw.githubusercontent.com/HyDE-Project/HyDE/refs/heads/master/Configs/.local/share/hyde/schema/config.toml.json\"",
        "```",
        "---",
    ]
    
    # Process properties
    if "properties" in toml_content:
        output_lines.extend(process_properties(toml_content["properties"]))
    
    return "\n".join(output_lines)


def main():
    parser = argparse.ArgumentParser(
        description="Generate markdown table documentation from TOML schema."
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

    table_content = generate_markdown_table(toml_file_path)
    print(table_content)


if __name__ == "__main__":
    main()
