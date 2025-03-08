#!/usr/bin/env python3
import json
import argparse
import sys
import re
import pyutils.logger as logger

logger = logger.get_logger()


def remove_comments(json_data):
    """Remove single-line and multi-line comments from JSON data."""
    json_data = re.sub(r"//.*", "", json_data)  # Remove single-line comments
    json_data = re.sub(
        r"/\*.*?\*/", "", json_data, flags=re.DOTALL
    )  # Remove multi-line comments
    return json_data


def parse_json(json_data, query, skip_comments, raw_output):
    """Parse JSON data and return the queried part."""
    if skip_comments:
        json_data = remove_comments(json_data)
    try:
        data = json.loads(json_data)
        if query == ".":
            result = data
        else:
            keys = re.findall(r'\["(.*?)"\]|(\w+)', query)
            for key in keys:
                key = key[0] or key[1]
                if isinstance(data, list):
                    key = int(key)  # Convert to int if accessing a list index
                data = data[key]
            result = data
        if raw_output and isinstance(result, str):
            return result
        return json.dumps(result, indent=4)
    except (json.JSONDecodeError, KeyError, IndexError, ValueError) as e:
        return f"Error: {e}"


def update_json(json_data, key, value, skip_comments):
    """Update the JSON data with the specified key and value."""
    if skip_comments:
        json_data = remove_comments(json_data)
    try:
        data = json.loads(json_data)
        keys = re.findall(r'\["(.*?)"\]|(\w+)', key)
        d = data
        for k in keys[:-1]:
            k = k[0] or k[1]
            if k not in d:
                d[k] = {}
            d = d[k]
        final_key = keys[-1][0] or keys[-1][1]
        d[final_key] = value
        result = json.dumps(data, indent=4)
        return result, None
    except (json.JSONDecodeError, KeyError, IndexError, ValueError) as e:
        return None, f"Error: {e}"


def arg_parser():
    parser = argparse.ArgumentParser(description="A simple JSON parser similar to jq.")
    parser.add_argument(
        "file",
        type=str,
        help="The JSON file to parse, or '-' to read from stdin.",
    )
    parser.add_argument(
        "--query",
        "-Q",
        help="The query to apply to the JSON data.",
    )
    parser.add_argument(
        "--skip-comments",
        "-C",
        action="store_true",
        help="Skip comments in the JSON data.",
    )
    parser.add_argument(
        "--raw-output",
        "-R",
        action="store_true",
        help="Remove quotes from output if the result is a string.",
    )
    parser.add_argument(
        "--update",
        "-U",
        nargs=2,
        metavar=("KEY", "VALUE"),
        help="Update the JSON data with the specified key and value.",
    )
    return parser.parse_args()


def main():
    args = arg_parser()
    if args.file == "-":
        json_data = sys.stdin.read()
    else:
        with open(args.file, "r+", encoding="UTF-8") as f:
            json_data = f.read()

    if args.update:
        key, value = args.update
        result, error = update_json(json_data, key, value, args.skip_comments)
        if error:
            logger.error(error)
            sys.exit(1)
        if args.file == "-":
            print(result)
        else:
            with open(args.file, "w", encoding="UTF-8") as f:
                f.write(result)
    elif args.query:
        result = parse_json(json_data, args.query, args.skip_comments, args.raw_output)
        print(result)
    else:
        logger.error("Error: Either --query or --update must be specified.")
        sys.exit(1)


if __name__ == "__main__":
    main()
