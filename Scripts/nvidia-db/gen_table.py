#/bin/env python3
import os
import argparse

def generate_table(directory):
    table = []
    for filename in os.listdir(directory):
        if filename.startswith("nvidia-"):
            with open(os.path.join(directory, filename), 'r') as file:
                lines = file.readlines()
                table.append(f"## {filename}\n")
                table.append("| NVE0 | NVE4 | GK104 | Description |\n")
                table.append("|------|------|-------|-------------|\n")
                for line in lines:
                    table.append(f"| {' | '.join(line.strip().split('|'))} |\n")
                table.append("\n")
    return table

def write_table_to_file(table, output_file, start_marker, end_marker):
    with open(output_file, 'r') as file:
        existing_content = file.readlines()

    try:
        start_index = existing_content.index(start_marker) + 1
        end_index = existing_content.index(end_marker)
        new_content = existing_content[:start_index] + table + existing_content[end_index:]
    except ValueError:
        new_content = existing_content + [start_marker] + table + [end_marker]

    with open(output_file, 'w') as file:
        file.writelines(new_content)

def generate_table_of_contents(directory):
    table_of_contents = []
    table_of_contents.append(f"# Table of Contents\n")
    for filename in os.listdir(directory):
        if filename.startswith("nvidia-"):
            table_of_contents.append(f"- [{filename}](#{filename})\n")
    return table_of_contents

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate Nvidia driver tables and table of contents.")
    parser.add_argument("-f", "--file", required=True, help="The output file to write the tables to.")
    args = parser.parse_args()

    directory = "."
    output_file = args.file

    nvidia_table = generate_table(directory)
    write_table_to_file(nvidia_table, output_file, "<!-- START NVIDIA TABLE -->\n", "<!-- END NVIDIA TABLE -->\n")

    table_of_contents = generate_table_of_contents(directory)
    write_table_to_file(table_of_contents, output_file, "<!-- START TABLE OF CONTENTS -->\n", "<!-- END TABLE OF CONTENTS -->\n")
