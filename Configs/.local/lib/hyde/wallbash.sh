#!/usr/bin/env bash
colorProfile="default"
wallbashCurve="32 50\n42 46\n49 40\n56 39\n64 38\n76 37\n90 33\n94 29\n100 20"
sortMode="auto"
while [ $# -gt 0 ]; do
    case "$1" in
        -v | --vibrant)
            colorProfile="vibrant"
            wallbashCurve="18 99\n32 97\n48 95\n55 90\n70 80\n80 70\n88 60\n94 40\n99 24"
            ;;
        -p | --pastel)
            colorProfile="pastel"
            wallbashCurve="10 99\n17 66\n24 49\n39 41\n51 37\n58 34\n72 30\n84 26\n99 22"
            ;;
        -m | --mono)
            colorProfile="mono"
            wallbashCurve="10 0\n17 0\n24 0\n39 0\n51 0\n58 0\n72 0\n84 0\n99 0"
            ;;
        -c | --custom)
            shift
            if [ -n "$1" ] && [[ $1 =~ ^([0-9]+[[:space:]][0-9]+\\n){8}[0-9]+[[:space:]][0-9]+$ ]]; then
                colorProfile="custom"
                wallbashCurve="$1"
            else
                echo "Error: Custom color curve format is incorrect $1"
                exit 1
            fi
            ;;
        -d | --dark)
            sortMode="dark"
            colSort=""
            ;;
        -l | --light)
            sortMode="light"
            colSort="-r"
            ;;
        *) break ;;
    esac
    shift
done
wallbashImg="$1"
wallbashColors=4
wallbashFuzz=70
wallbashRaw="${2:-"$wallbashImg"}.mpc"
wallbashOut="${2:-"$wallbashImg"}.dcol"
wallbashCache="${2:-"$wallbashImg"}.cache"
pryDarkBri=116
pryDarkSat=110
pryDarkHue=88
pryLightBri=100
pryLightSat=100
pryLightHue=114
txtDarkBri=188
txtLightBri=16
if [ -z "$wallbashImg" ] || [ ! -f "$wallbashImg" ]; then
    echo "Error: Input file not found!"
    exit 1
fi
if ! magick -ping "$wallbashImg" -format "%t" info: &> /dev/null; then
    echo "Error: Unsuppoted image format $wallbashImg"
    exit 1
fi
echo -e "wallbash $colorProfile profile :: $sortMode :: Colors $wallbashColors :: Fuzzy $wallbashFuzz :: \"$wallbashOut\""
cacheDir="${cacheDir:-$XDG_CACHE_HOME/hyde}"
thmDir="${thmDir:-$cacheDir/thumbs}"
mkdir -p "$thmDir"
: > "$wallbashOut"
rgb_negative() {
    local inCol=$1
    local r=${inCol:0:2}
    local g=${inCol:2:2}
    local b=${inCol:4:2}
    local r16=$((16#$r))
    local g16=$((16#$g))
    local b16=$((16#$b))
    r=$(printf "%02X" $((255 - r16)))
    g=$(printf "%02X" $((255 - g16)))
    b=$(printf "%02X" $((255 - b16)))
    echo "$r$g$b"
}
rgba_convert() {
    local inCol=$1
    local r=${inCol:0:2}
    local g=${inCol:2:2}
    local b=${inCol:4:2}
    local r16=$((16#$r))
    local g16=$((16#$g))
    local b16=$((16#$b))
    printf "rgba(%d,%d,%d,\1341)\n" "$r16" "$g16" "$b16"
}
fx_brightness() {
    local inCol="$1"
    local fxb
    fxb=$(magick "$inCol" -colorspace gray -format "%[fx:mean]" info:)
    if awk -v fxb="$fxb" 'BEGIN {exit !(fxb < 0.5)}'; then
        return 0
    else
        return 1
    fi
}
luminance() {
    # WCAG relative luminance (0-1) of a hex color (RRGGBB)
    local r=$((16#${1:0:2})) g=$((16#${1:2:2})) b=$((16#${1:4:2}))
    awk -v r="$r" -v g="$g" -v b="$b" '
        function chan(v,   c) { c = v / 255; return (c <= 0.03928) ? c / 12.92 : ((c + 0.055) / 1.055) ^ 2.4 }
        BEGIN { printf "%.6f", 0.2126 * chan(r) + 0.7152 * chan(g) + 0.0722 * chan(b) }'
}
contrast_ratio() {
    # WCAG contrast ratio (1-21) between two hex colors
    local l1 l2
    l1=$(luminance "$1")
    l2=$(luminance "$2")
    awk -v l1="$l1" -v l2="$l2" 'BEGIN { hi = (l1 > l2) ? l1 : l2; lo = (l1 > l2) ? l2 : l1; printf "%.3f", (hi + 0.05) / (lo + 0.05) }'
}
magick -quiet -regard-warnings "$wallbashImg"[0] -alpha off +repage "$wallbashRaw"
readarray -t dcolRaw <<< "$(magick "$wallbashRaw" -depth 8 -fuzz $wallbashFuzz% +dither -kmeans $wallbashColors -depth 8 -format "%c" histogram:info: | sed -n 's/^[ ]*\(.*\):.*[#]\([0-9a-fA-F]*\) .*$/\1,\2/p' | sort -r -n -k 1 -t ",")"
if [ ${#dcolRaw[*]} -lt $wallbashColors ]; then
    echo -e "RETRYING :: distinct colors ${#dcolRaw[*]} is less than $wallbashColors palette color..."
    readarray -t dcolRaw <<< "$(magick "$wallbashRaw" -depth 8 -fuzz $wallbashFuzz% +dither -kmeans $((wallbashColors + 2)) -depth 8 -format "%c" histogram:info: | sed -n 's/^[ ]*\(.*\):.*[#]\([0-9a-fA-F]*\) .*$/\1,\2/p' | sort -r -n -k 1 -t ",")"
fi
if [ "$sortMode" == "auto" ]; then
    if fx_brightness "$wallbashRaw"; then
        sortMode="dark"
        colSort=""
    else
        sortMode="light"
        colSort="-r"
    fi
fi
echo "dcol_mode=\"$sortMode\"" >> "$wallbashOut"
mapfile -t dcolHex < <(echo -e "${dcolRaw[@]:0:wallbashColors}" | tr ' ' '\n' | awk -F ',' '{print $2}' | sort ${colSort:+"$colSort"})
greyCheck=$(magick "$wallbashRaw" -colorspace HSL -channel g -separate +channel -format "%[fx:mean]" info:)
if (($(awk 'BEGIN {print ('"$greyCheck"' < 0.12)}'))); then
    wallbashCurve="10 0\n17 0\n24 0\n39 0\n51 0\n58 0\n72 0\n84 0\n99 0"
fi
# ANSI terminal slots 0/7/8/15 (kitty.dcol) are, by convention, near-black/near-white
# regardless of theme -- apps like nmtui/newt rely on that pairing for legible dialogs.
# The per-group accent curve (dcol_NxaM below) has no such guarantee: a mid-curve point
# can land close in luminance to the background it's drawn against, camouflaging text
# (#2185). Derive a dedicated, lightly hue-tinted black/white pair instead, verified to
# clear WCAG AAA (7:1) against each other, with a flat neutral fallback if it doesn't.
ansiHue=$(magick xc:"#${dcolHex[0]}" -colorspace HSB -format "%c" histogram:info: | awk -F '[hsb(,]' '{print $2}')
dcol_ansi_black=$(magick xc:"hsb($ansiHue,35%,12%)" -depth 8 -format "%c" histogram:info: | sed -n 's/^[ ]*\(.*\):.*[#]\([0-9a-fA-F]*\) .*$/\2/p')
dcol_ansi_white=$(magick xc:"hsb($ansiHue,12%,96%)" -depth 8 -format "%c" histogram:info: | sed -n 's/^[ ]*\(.*\):.*[#]\([0-9a-fA-F]*\) .*$/\2/p')
if awk -v r="$(contrast_ratio "$dcol_ansi_black" "$dcol_ansi_white")" 'BEGIN {exit !(r < 7)}'; then
    dcol_ansi_black="121212"
    dcol_ansi_white="F2F2F2"
fi
echo "dcol_ansi_black=\"$dcol_ansi_black\"" >> "$wallbashOut"
echo "dcol_ansi_white=\"$dcol_ansi_white\"" >> "$wallbashOut"
for ((i = 0; i < wallbashColors; i++)); do
    if [ -z "${dcolHex[i]}" ]; then
        if fx_brightness "xc:#${dcolHex[i - 1]}"; then
            modBri=$pryDarkBri
            modSat=$pryDarkSat
            modHue=$pryDarkHue
        else
            modBri=$pryLightBri
            modSat=$pryLightSat
            modHue=$pryLightHue
        fi
        echo -e "dcol_pry$((i + 1)) :: regen missing color"
        dcolHex[i]=$(magick xc:"#${dcolHex[i - 1]}" -depth 8 -normalize -modulate $modBri,$modSat,$modHue -depth 8 -format "%c" histogram:info: | sed -n 's/^[ ]*\(.*\):.*[#]\([0-9a-fA-F]*\) .*$/\2/p')
    fi
    echo "dcol_pry$((i + 1))=\"${dcolHex[i]}\"" >> "$wallbashOut"
    echo "dcol_pry$((i + 1))_rgba=\"$(rgba_convert "${dcolHex[i]}")\"" >> "$wallbashOut"
    nTxt=$(rgb_negative "${dcolHex[i]}")
    if fx_brightness "xc:#${dcolHex[i]}"; then
        modBri=$txtDarkBri
    else
        modBri=$txtLightBri
    fi
    tcol=$(magick xc:"#$nTxt" -depth 8 -normalize -modulate $modBri,10,100 -depth 8 -format "%c" histogram:info: | sed -n 's/^[ ]*\(.*\):.*[#]\([0-9a-fA-F]*\) .*$/\2/p')
    # fx_brightness is a rough proxy (raw gray mean vs. a fixed 50% cutoff) and can still
    # pick a hue-tinted text color that reads poorly against a mid-luminance background
    # (#2185). Verify the actual WCAG contrast ratio and, if it falls short of AA (4.5:1),
    # blend toward whichever of pure black/white contrasts better, in steps up to the pure
    # color -- only kicks in for the borderline cases fx_brightness gets wrong.
    if awk -v r="$(contrast_ratio "$tcol" "${dcolHex[i]}")" 'BEGIN {exit !(r < 4.5)}'; then
        if awk -v w="$(contrast_ratio "FFFFFF" "${dcolHex[i]}")" -v b="$(contrast_ratio "000000" "${dcolHex[i]}")" 'BEGIN {exit !(w > b)}'; then
            safeTarget="FFFFFF"
        else
            safeTarget="000000"
        fi
        origTcol="$tcol"
        for pct in 25 50 75 100; do
            tcol=$(magick xc:"#$origTcol" \( xc:"#$safeTarget" \) -compose blend -define compose:args=$pct -composite -depth 8 -format "%c" histogram:info: | sed -n 's/^[ ]*\(.*\):.*[#]\([0-9a-fA-F]*\) .*$/\2/p')
            awk -v r="$(contrast_ratio "$tcol" "${dcolHex[i]}")" 'BEGIN {exit !(r >= 4.5)}' && break
        done
    fi
    echo "dcol_txt$((i + 1))=\"$tcol\"" >> "$wallbashOut"
    echo "dcol_txt$((i + 1))_rgba=\"$(rgba_convert "$tcol")\"" >> "$wallbashOut"
    xHue=$(magick xc:"#${dcolHex[i]}" -colorspace HSB -format "%c" histogram:info: | awk -F '[hsb(,]' '{print $2}')
    acnt=1
    echo -e "$wallbashCurve" | sort -n ${colSort:+"$colSort"} | while read -r xBri xSat; do
        acol=$(magick xc:"hsb($xHue,$xSat%,$xBri%)" -depth 8 -format "%c" histogram:info: | sed -n 's/^[ ]*\(.*\):.*[#]\([0-9a-fA-F]*\) .*$/\2/p')
        echo "dcol_$((i + 1))xa$acnt=\"$acol\"" >> "$wallbashOut"
        echo "dcol_$((i + 1))xa${acnt}_rgba=\"$(rgba_convert "$acol")\"" >> "$wallbashOut"
        ((acnt++))
    done
done
rm -f "$wallbashRaw" "$wallbashCache"
