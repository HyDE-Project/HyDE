#!/usr/bin/env bash
# wallbash-matugen.sh - Alternative color extraction using matugen (Material You)
# Drop-in replacement for wallbash.sh when imagemagick fails or user prefers matugen
# Generates a dcol-compatible file (89 lines) from matugen's tonal palettes
#
# Usage: wallbash-matugen.sh [OPTIONS] <image> [output_prefix]
# Options are accepted for compatibility with wallbash.sh but most are ignored
# since matugen handles its own color generation algorithm.

sortMode="auto"

while [ $# -gt 0 ]; do
    case "$1" in
        -v | --vibrant | -p | --pastel | -m | --mono | -c | --custom)
            # Accept but ignore profile flags - matugen has its own algorithm
            # For --custom, consume the extra argument
            if [[ "$1" == "-c" || "$1" == "--custom" ]]; then shift; fi
            ;;
        -d | --dark)
            sortMode="dark"
            ;;
        -l | --light)
            sortMode="light"
            ;;
        *) break ;;
    esac
    shift
done

wallbashImg="$1"
wallbashOut="${2:-"$wallbashImg"}.dcol"

if [ -z "$wallbashImg" ] || [ ! -f "$wallbashImg" ]; then
    echo "Error: Input file not found!"
    exit 1
fi

if ! command -v matugen &>/dev/null; then
    echo "Error: matugen not found. Install with: paru -S matugen-bin"
    exit 1
fi

echo -e "wallbash-matugen :: $sortMode :: \"$wallbashOut\""

# Get matugen colors as stripped hex (no #)
# --prefer saturation: pick the most saturated source color (closest to wallbash behavior)
# --dry-run: don't deploy any templates
matugen_json=$(matugen image --json strip --dry-run --prefer saturation "$wallbashImg" 2>/dev/null)

if [ -z "$matugen_json" ] || ! echo "$matugen_json" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
    echo "Error: matugen failed to process image"
    exit 1
fi

# Determine mode if auto
if [ "$sortMode" == "auto" ]; then
    # Use matugen's own dark mode detection
    is_dark=$(echo "$matugen_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print('true' if d.get('is_dark_mode', True) else 'false')")
    if [ "$is_dark" == "true" ]; then
        sortMode="dark"
    else
        sortMode="light"
    fi
fi

# Generate dcol file from matugen palettes
# Mapping strategy:
#   dcol group 1 <- primary palette   (main theme color)
#   dcol group 2 <- secondary palette  (muted variant)
#   dcol group 3 <- tertiary palette   (complementary accent)
#   dcol group 4 <- neutral palette    (background/surface tones)
#
# For each group:
#   pry  <- tone 30 (dark) or tone 70 (light) = "the base color"
#   txt  <- tone 90 (dark) or tone 10 (light) = "readable text on pry"
#   xa1-xa9 <- 9 tones spread across the scale (dark-to-bright or bright-to-dark)

python3 -c "
import sys, json

data = json.loads('''${matugen_json}''')
mode = '${sortMode}'
palettes = data['palettes']

# Map palette names to dcol groups
# Group 1 = neutral (dark background, used as pry1 for bg color)
# Group 2 = primary (main accent color)
# Group 3 = secondary (muted accent)
# Group 4 = tertiary (complementary accent)
palette_map = ['neutral', 'primary', 'secondary', 'tertiary']

# Tone selections for accents (xa1=darkest to xa9=brightest in dark mode)
# We pick 9 well-distributed tones from the 18 available
# Available tones: 0, 5, 10, 15, 20, 25, 30, 35, 40, 50, 60, 70, 80, 90, 95, 98, 99, 100
if mode == 'dark':
    # Dark mode: xa1=dark, xa9=bright (matches wallbash curve behavior)
    accent_tones = [10, 20, 25, 30, 35, 40, 50, 60, 80]
    pry_tone = 10   # Very dark primary (matches wallbash: darkest dominant color)
    txt_tone = 95   # Very light text for contrast
else:
    # Light mode: xa1=bright, xa9=dark (reversed)
    accent_tones = [95, 80, 70, 60, 50, 40, 35, 30, 20]
    pry_tone = 90   # Very light primary
    txt_tone = 10   # Very dark text

def hex_to_rgba(hex_str):
    r = int(hex_str[0:2], 16)
    g = int(hex_str[2:4], 16)
    b = int(hex_str[4:6], 16)
    return f'rgba({r},{g},{b},\\\\1)'

lines = []
lines.append(f'dcol_mode=\"{mode}\"')

for group_idx, palette_name in enumerate(palette_map, 1):
    palette = palettes[palette_name]
    # Build tone lookup {int_tone: hex_color}
    tone_lookup = {int(k): v['color'].upper() for k, v in palette.items()}

    # Primary color for this group
    pry = tone_lookup[pry_tone]
    lines.append(f'dcol_pry{group_idx}=\"{pry}\"')
    lines.append(f'dcol_pry{group_idx}_rgba=\"{hex_to_rgba(pry)}\"')

    # Text color
    txt = tone_lookup[txt_tone]
    lines.append(f'dcol_txt{group_idx}=\"{txt}\"')
    lines.append(f'dcol_txt{group_idx}_rgba=\"{hex_to_rgba(txt)}\"')

    # Accent colors xa1-xa9
    for acnt_idx, tone in enumerate(accent_tones, 1):
        acol = tone_lookup[tone]
        lines.append(f'dcol_{group_idx}xa{acnt_idx}=\"{acol}\"')
        lines.append(f'dcol_{group_idx}xa{acnt_idx}_rgba=\"{hex_to_rgba(acol)}\"')

# Output all lines
print('\n'.join(lines))
" > "$wallbashOut"

# Validate output has exactly 89 lines
line_count=$(wc -l < "$wallbashOut")
if [ "$line_count" -ne 89 ]; then
    echo "Warning: Generated $line_count lines (expected 89)"
    exit 1
fi

echo "wallbash-matugen :: Generated $wallbashOut ($line_count lines)"
