#!/usr/bin/env bash
#|---/ /+---------------------------------------------+---/ /|#
#|--/ /-| Script to generate color palette from image |--/ /-|#
#|-/ /--| Prasanth Rangan                             |-/ /--|#
#|/ /---+---------------------------------------------+/ /---|#

#// accent color profile

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
        if [ -n "${1}" ] && [[ "${1}" =~ ^([0-9]+[[:space:]][0-9]+\\n){8}[0-9]+[[:space:]][0-9]+$ ]]; then
            colorProfile="custom"
            wallbashCurve="${1}"
        else
            echo "Error: Custom color curve format is incorrect ${1}"
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
    *)
        break
        ;;
    esac
    shift
done

#// set variables

wallbashImg="${1}"
wallbashColors=4
wallbashFuzz=70
wallbashRaw="${2:-"${wallbashImg}"}.mpc"
wallbashOut="${2:-"${wallbashImg}"}.dcol"
wallbashCache="${2:-"${wallbashImg}"}.cache"

#// color modulations

pryDarkBri=116
pryDarkSat=110
pryDarkHue=88
pryLightBri=100
pryLightSat=100
pryLightHue=114
txtDarkBri=188
txtLightBri=16

#// input image validation

if [ -z "${wallbashImg}" ] || [ ! -f "${wallbashImg}" ]; then
    echo "Error: Input file not found!"
    exit 1
fi

# if [ $? -ne 0 ]; then
if ! magick -ping "${wallbashImg}" -format "%t" info: &>/dev/null; then
    echo "Error: Unsuppoted image format ${wallbashImg}"
    exit 1
fi

echo -e "wallbash ${colorProfile} profile :: ${sortMode} :: Colors ${wallbashColors} :: Fuzzy ${wallbashFuzz} :: \"${wallbashOut}\""
cacheDir="${cacheDir:-$XDG_CACHE_HOME/hyde}"
thmDir="${thmDir:-$cacheDir/thumbs}"
mkdir -p "${cacheDir}/${thmDir}"
: >"${wallbashOut}"
#// define functions

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
    echo "${r}${g}${b}"
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
    local inCol="${1}"
    local fxb
    fxb=$(magick "${inCol}" -colorspace gray -format "%[fx:mean]" info:)
    if awk -v fxb="${fxb}" 'BEGIN {exit !(fxb < 0.5)}'; then
        return 0 #// echo ":: ${fxb} :: dark :: ${inCol}"
    else
        return 1 #// echo ":: ${fxb} :: light :: ${inCol}"
    fi
}

#// quantize raw primary colors

magick -quiet -regard-warnings "${wallbashImg}"[0] -alpha off +repage "${wallbashRaw}"
readarray -t dcolRaw <<<"$(magick "${wallbashRaw}" -depth 8 -fuzz ${wallbashFuzz}% +dither -kmeans ${wallbashColors} -depth 8 -format "%c" histogram:info: | sed -n 's/^[ ]*\(.*\):.*[#]\([0-9a-fA-F]*\) .*$/\1,\2/p' | sort -r -n -k 1 -t ",")"

if [ ${#dcolRaw[*]} -lt ${wallbashColors} ]; then
    echo -e "RETRYING :: distinct colors ${#dcolRaw[*]} is less than ${wallbashColors} palette color..."
    readarray -t dcolRaw <<<"$(magick "${wallbashRaw}" -depth 8 -fuzz ${wallbashFuzz}% +dither -kmeans $((wallbashColors + 2)) -depth 8 -format "%c" histogram:info: | sed -n 's/^[ ]*\(.*\):.*[#]\([0-9a-fA-F]*\) .*$/\1,\2/p' | sort -r -n -k 1 -t ",")"
fi

#// sort colors based on image brightness

if [ "${sortMode}" == "auto" ]; then
    if fx_brightness "${wallbashRaw}"; then
        sortMode="dark"
        colSort=""
    else
        sortMode="light"
        colSort="-r"
    fi
fi

echo "dcol_mode=\"${sortMode}\"" >>"${wallbashOut}"
# dcolHex=($(echo -e "${dcolRaw[@]:0:$wallbashColors}" | tr ' ' '\n' | awk -F ',' '{print $2}' | sort ${colSort:+"$colSort"}))
mapfile -t dcolHex < <(echo -e "${dcolRaw[@]:0:$wallbashColors}" | tr ' ' '\n' | awk -F ',' '{print $2}' | sort ${colSort:+"$colSort"})
greyCheck=$(magick "${wallbashRaw}" -colorspace HSL -channel g -separate +channel -format "%[fx:mean]" info:)

if (($(awk 'BEGIN {print ('"$greyCheck"' < 0.12)}'))); then
    wallbashCurve="10 0\n17 0\n24 0\n39 0\n51 0\n58 0\n72 0\n84 0\n99 0"
fi

#// loop for derived colors

for ((i = 0; i < wallbashColors; i++)); do

    #// generate missing primary colors

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
        # dcol[i]=$(magick xc:"#${dcolHex[i - 1]}" -depth 8 -normalize -modulate ${modBri},${modSat},${modHue} -depth 8 -format "%c" histogram:info: | sed -n 's/^[ ]*\(.*\):.*[#]\([0-9a-fA-F]*\) .*$/\2/p')
        dcolHex[i]=$(magick xc:"#${dcolHex[i - 1]}" -depth 8 -normalize -modulate ${modBri},${modSat},${modHue} -depth 8 -format "%c" histogram:info: | sed -n 's/^[ ]*\(.*\):.*[#]\([0-9a-fA-F]*\) .*$/\2/p')

    fi

    echo "dcol_pry$((i + 1))=\"${dcolHex[i]}\"" >>"${wallbashOut}"
    echo "dcol_pry$((i + 1))_rgba=\"$(rgba_convert "${dcolHex[i]}")\"" >>"${wallbashOut}"

    #// generate primary text colors

    nTxt=$(rgb_negative "${dcolHex[i]}")

    if fx_brightness "xc:#${dcolHex[i]}"; then
        modBri=$txtDarkBri
    else
        modBri=$txtLightBri
    fi

    tcol=$(magick xc:"#${nTxt}" -depth 8 -normalize -modulate ${modBri},10,100 -depth 8 -format "%c" histogram:info: | sed -n 's/^[ ]*\(.*\):.*[#]\([0-9a-fA-F]*\) .*$/\2/p')
    echo "dcol_txt$((i + 1))=\"${tcol}\"" >>"${wallbashOut}"
    echo "dcol_txt$((i + 1))_rgba=\"$(rgba_convert "${tcol}")\"" >>"${wallbashOut}"

    #// generate accent colors

    xHue=$(magick xc:"#${dcolHex[i]}" -colorspace HSB -format "%c" histogram:info: | awk -F '[hsb(,]' '{print $2}')
    acnt=1

    echo -e "${wallbashCurve}" | sort -n ${colSort:+"$colSort"} | while read -r xBri xSat; do
        acol=$(magick xc:"hsb(${xHue},${xSat}%,${xBri}%)" -depth 8 -format "%c" histogram:info: | sed -n 's/^[ ]*\(.*\):.*[#]\([0-9a-fA-F]*\) .*$/\2/p')
        echo "dcol_$((i + 1))xa${acnt}=\"${acol}\"" >>"${wallbashOut}"
        echo "dcol_$((i + 1))xa${acnt}_rgba=\"$(rgba_convert "${acol}")\"" >>"${wallbashOut}"
        ((acnt++))
    done

done

#// cleanup temp cache

rm -f "${wallbashRaw}" "${wallbashCache}"
