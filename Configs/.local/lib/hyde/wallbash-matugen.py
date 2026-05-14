#!/usr/bin/env python3
"""wallbash-matugen.py - Alternative color extraction using matugen (Material You)

Drop-in replacement for wallbash.sh when imagemagick fails or user prefers matugen.
Generates a dcol-compatible .mcol file (89 lines) from matugen's tonal palettes.

Usage: wallbash-matugen.py [OPTIONS] <image> [output_prefix]
Options are accepted for compatibility with wallbash.sh but most are ignored
since matugen handles its own color generation algorithm.
"""

import json
import os
import subprocess
import sys

# Mapping strategy:
#   dcol group 1 <- neutral palette    (dark bg/surface, used as pry1 background)
#   dcol group 2 <- primary palette    (main accent color)
#   dcol group 3 <- secondary palette  (muted accent)
#   dcol group 4 <- tertiary palette   (complementary accent)
PALETTE_MAP = ["neutral", "primary", "secondary", "tertiary"]

# Tone selections for accents
# Available tones: 0, 5, 10, 15, 20, 25, 30, 35, 40, 50, 60, 70, 80, 90, 95, 98, 99, 100
DARK_MODE = {
    "accent_tones": [10, 20, 25, 30, 35, 40, 50, 60, 80],  # xa1=dark, xa9=bright
    "pry_tone": 10,   # Very dark primary (matches wallbash: darkest dominant color)
    "txt_tone": 95,   # Very light text for contrast
}
LIGHT_MODE = {
    "accent_tones": [95, 80, 70, 60, 50, 40, 35, 30, 20],  # xa1=bright, xa9=dark
    "pry_tone": 90,   # Very light primary
    "txt_tone": 10,   # Very dark text
}


def hex_to_rgba(hex_str: str) -> str:
    r = int(hex_str[0:2], 16)
    g = int(hex_str[2:4], 16)
    b = int(hex_str[4:6], 16)
    return f"rgba({r},{g},{b},\\1)"


def run_matugen(image_path: str) -> dict:
    """Run matugen and return parsed JSON output."""
    try:
        result = subprocess.run(
            [
                "matugen", "image",
                "--json", "strip",
                "--dry-run",
                "--prefer", "saturation",
                image_path,
            ],
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        print("Error: matugen not found. Install with: paru -S matugen-bin", file=sys.stderr)
        sys.exit(1)

    if result.returncode != 0 or not result.stdout.strip():
        print(f"Error: matugen failed to process image: {result.stderr.strip()}", file=sys.stderr)
        sys.exit(1)

    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as e:
        print(f"Error: failed to parse matugen output: {e}", file=sys.stderr)
        sys.exit(1)


def generate_mcol(palettes: dict, mode: str) -> list[str]:
    """Generate 89 dcol-compatible lines from matugen palettes."""
    config = DARK_MODE if mode == "dark" else LIGHT_MODE
    pry_tone = config["pry_tone"]
    txt_tone = config["txt_tone"]
    accent_tones = config["accent_tones"]

    lines = [f'dcol_mode="{mode}"']

    for group_idx, palette_name in enumerate(PALETTE_MAP, 1):
        palette = palettes[palette_name]
        tone_lookup = {int(k): v["color"].upper() for k, v in palette.items()}

        # Primary color
        pry = tone_lookup[pry_tone]
        lines.append(f'dcol_pry{group_idx}="{pry}"')
        lines.append(f'dcol_pry{group_idx}_rgba="{hex_to_rgba(pry)}"')

        # Text color
        txt = tone_lookup[txt_tone]
        lines.append(f'dcol_txt{group_idx}="{txt}"')
        lines.append(f'dcol_txt{group_idx}_rgba="{hex_to_rgba(txt)}"')

        # Accent colors xa1-xa9
        for acnt_idx, tone in enumerate(accent_tones, 1):
            acol = tone_lookup[tone]
            lines.append(f'dcol_{group_idx}xa{acnt_idx}="{acol}"')
            lines.append(f'dcol_{group_idx}xa{acnt_idx}_rgba="{hex_to_rgba(acol)}"')

    return lines


def parse_args(argv: list[str]) -> tuple[str, str, str]:
    """Parse CLI args, return (sort_mode, image_path, output_prefix)."""
    sort_mode = "auto"
    args = argv[1:]
    positional = []

    i = 0
    while i < len(args):
        arg = args[i]
        if arg in ("-v", "--vibrant", "-p", "--pastel", "-m", "--mono"):
            pass  # Accept but ignore
        elif arg in ("-c", "--custom"):
            i += 1  # Skip the curve argument
        elif arg in ("-d", "--dark"):
            sort_mode = "dark"
        elif arg in ("-l", "--light"):
            sort_mode = "light"
        else:
            positional.append(arg)
        i += 1

    if not positional:
        print("Error: Input file not provided!", file=sys.stderr)
        sys.exit(1)

    image_path = positional[0]
    output_prefix = positional[1] if len(positional) > 1 else image_path

    return sort_mode, image_path, output_prefix


def main():
    sort_mode, image_path, output_prefix = parse_args(sys.argv)
    output_file = f"{output_prefix}.mcol"

    if not os.path.isfile(image_path):
        print(f"Error: Input file not found: {image_path}", file=sys.stderr)
        sys.exit(1)

    # Run matugen
    data = run_matugen(image_path)

    # Determine mode
    if sort_mode == "auto":
        sort_mode = "dark" if data.get("is_dark_mode", True) else "light"

    # Generate color lines
    lines = generate_mcol(data["palettes"], sort_mode)

    # Validate
    if len(lines) != 89:
        print(f"Warning: Generated {len(lines)} lines (expected 89)", file=sys.stderr)
        sys.exit(1)

    # Write output
    with open(output_file, "w") as f:
        f.write("\n".join(lines) + "\n")

    print(f"wallbash-matugen :: {sort_mode} :: \"{output_file}\" ({len(lines)} lines)")


if __name__ == "__main__":
    main()
