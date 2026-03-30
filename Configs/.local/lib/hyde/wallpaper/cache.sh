#!/usr/bin/env bash

extract_thumbnail() {
    local x_wall="$1"
    x_wall=$(realpath "$x_wall")
    local temp_image="$2"
    ffmpeg -y -i "$x_wall" -vf "thumbnail,scale=1000:-1" -frames:v 1 -update 1 "$temp_image" &>/dev/null
}

wallpaper_cache_bootstrap() {
	if [[ ${HYDE_SHELL_INIT:-0} -ne 1 ]]; then
		eval "$(hyde-shell init)"
	else
		export_hyde_config
	fi
	export scrDir="${LIB_DIR:-$HOME/.local/lib}/hyde"
	export thmbDir
	export dcolDir
}

wallpaper_cache_init() {
	[ -d "$HYDE_THEME_DIR" ] && cacheIn="$HYDE_THEME_DIR" || {
		echo "Error: HYDE_THEME_DIR not found!"
		return 1
	}
	[ -d "$thmbDir" ] || mkdir -p "$thmbDir"
	[ -d "$dcolDir" ] || mkdir -p "$dcolDir"
	[ -d "$cacheDir/landing" ] || mkdir -p "$cacheDir/landing"
	[ -d "$cacheDir/wallbash" ] || mkdir -p "$cacheDir/wallbash"
	if [ -n "$wallbashCustomCurve" ] && [[ $wallbashCustomCurve =~ ^([0-9]+[[:space:]][0-9]+\\n){8}[0-9]+[[:space:]][0-9]+$ ]]; then
		export wallbashCustomCurve
		echo ":: wallbash --custom \"$wallbashCustomCurve\""
	else
		export wallbashCustomCurve="32 50\n42 46\n49 40\n56 39\n64 38\n76 37\n90 33\n94 29\n100 20"
	fi
}

fn_wallcache() {
	local x_hash="$1"
	local x_wall="$2"
	local is_video
	is_video=$(file --mime-type -b "$x_wall" | grep -c '^video/')
	if [ "$is_video" -eq 1 ]; then
		if [ ! -e "$thmbDir/$x_hash.thmb" ] || [ ! -e "$thmbDir/$x_hash.sqre" ] || [ ! -e "$thmbDir/$x_hash.blur" ] || [ ! -e "$thmbDir/$x_hash.quad" ] || [ ! -e "$dcolDir/$x_hash.dcol" ]; then
			local temp_image="/tmp/$x_hash.png"
			notify-send -a "HyDE wallpaper" "Extracting thumbnail from video wallpaper..."
			extract_thumbnail "$x_wall" "$temp_image"
			x_wall="$temp_image"
		fi
	fi
	[ ! -e "$thmbDir/$x_hash.thmb" ] && magick "$x_wall"[0] -strip -resize 1000 -gravity center -extent 1000 -quality 90 "$thmbDir/$x_hash.thmb"
	[ ! -e "$thmbDir/$x_hash.sqre" ] && magick "$x_wall"[0] -strip -thumbnail 500x500^ -gravity center -extent 500x500 "$thmbDir/$x_hash.sqre.png" && mv "$thmbDir/$x_hash.sqre.png" "$thmbDir/$x_hash.sqre"
	[ ! -e "$thmbDir/$x_hash.blur" ] && magick "$x_wall"[0] -strip -scale 10% -blur 0x3 -resize 100% "$thmbDir/$x_hash.blur"
	[ ! -e "$thmbDir/$x_hash.quad" ] && magick "$thmbDir/$x_hash.sqre" \( -size 500x500 xc:white -fill "rgba(0,0,0,0.7)" -draw "polygon 400,500 500,500 500,0 450,0" -fill black -draw "polygon 500,500 500,0 450,500" \) -alpha Off -compose CopyOpacity -composite "$thmbDir/$x_hash.quad.png" && mv "$thmbDir/$x_hash.quad.png" "$thmbDir/$x_hash.quad"
	{
		[ ! -e "$dcolDir/$x_hash.dcol" ] || [ "$(wc -l < "$dcolDir/$x_hash.dcol")" -ne 89 ]
	} && "$scrDir/wallbash.sh" --custom "$wallbashCustomCurve" "$thmbDir/$x_hash.thmb" "$dcolDir/$x_hash" &> /dev/null
	if [ "$is_video" -eq 1 ]; then
		rm -f "$temp_image"
	fi
}

fn_wallcache_force() {
	local x_hash="$1"
	local x_wall="$2"
	local is_video
	is_video=$(file --mime-type -b "$x_wall" | grep -c '^video/')
	if [ "$is_video" -eq 1 ]; then
		local temp_image="/tmp/$x_hash.png"
		extract_thumbnail "$x_wall" "$temp_image"
		x_wall="$temp_image"
	fi
	magick "$x_wall"[0] -strip -resize 1000 -gravity center -extent 1000 -quality 90 "$thmbDir/$x_hash.thmb"
	magick "$x_wall"[0] -strip -thumbnail 500x500^ -gravity center -extent 500x500 "$thmbDir/$x_hash.sqre.png" && mv "$thmbDir/$x_hash.sqre.png" "$thmbDir/$x_hash.sqre"
	magick "$x_wall"[0] -strip -scale 10% -blur 0x3 -resize 100% "$thmbDir/$x_hash.blur"
	magick "$thmbDir/$x_hash.sqre" \( -size 500x500 xc:white -fill "rgba(0,0,0,0.7)" -draw "polygon 400,500 500,500 500,0 450,0" -fill black -draw "polygon 500,500 500,0 450,500" \) -alpha Off -compose CopyOpacity -composite "$thmbDir/$x_hash.quad.png" && mv "$thmbDir/$x_hash.quad.png" "$thmbDir/$x_hash.quad"
	"$scrDir/wallbash.sh" --custom "$wallbashCustomCurve" "$thmbDir/$x_hash.thmb" "$dcolDir/$x_hash" &> /dev/null
	if [ "$is_video" -eq 1 ]; then
		rm -f "$temp_image"
	fi
}

fn_envar_cache() {
	if command -v rofi &> /dev/null; then
		if [[ ! $XDG_DATA_DIRS =~ share/hyde ]]; then
			mkdir -p "$XDG_DATA_HOME/rofi/themes"
			ln -snf "$XDG_DATA_HOME/hyde/rofi/themes"/* "$XDG_DATA_HOME/rofi/themes/"
		fi
	fi
}

wallpaper_cache_commence() {
	local mode=""
	local option

	wallpaper_cache_bootstrap || return 1
	wallpaper_cache_init || return 1

	# Backward compatibility: allow old plain command aliases.
	case "$1" in
		w)
			shift
			;;
		t)
			shift
			set -- -t "$@"
			;;
		f)
			shift
			set -- -f "$@"
			;;
	esac

	local OPTIND=1
	while getopts "w:t:f" option; do
		case $option in
			w)
				if [ -z "$OPTARG" ] || [ ! -f "$OPTARG" ]; then
					echo "Error: Input wallpaper \"$OPTARG\" not found!"
					return 1
				fi
				cacheIn="$OPTARG"
				;;
			t)
				cacheIn="$(dirname "$HYDE_THEME_DIR")/$OPTARG"
				if [ ! -d "$cacheIn" ]; then
					echo "Error: Input theme \"$OPTARG\" not found!"
					return 1
				fi
				;;
			f)
				cacheIn="$(dirname "$HYDE_THEME_DIR")"
				mode="_force"
				;;
			*)
				echo "... invalid option ..."
				echo "$(basename "$0") commence -[option]"
				echo "w : generate cache for input wallpaper"
				echo "t : generate cache for input theme"
				echo "f : full cache rebuild"
				return 1
				;;
		esac
	done

	fn_envar_cache
	wallPathArray=("$cacheIn")
	wallPathArray+=("${WALLPAPER_CUSTOM_PATHS[@]}")
	get_hashmap "${wallPathArray[@]}" --no-notify
	parallel --bar --link "fn_wallcache$mode" ::: "${wallHash[@]}" ::: "${wallList[@]}"
}

export -f fn_wallcache fn_wallcache_force fn_envar_cache wallpaper_cache_bootstrap wallpaper_cache_init wallpaper_cache_commence extract_thumbnail

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	subcommand="$1"
	case "$subcommand" in
		commence)
			[ -n "$subcommand" ] && shift
			wallpaper_cache_commence "$@"
			;;
		*)
			# Compatibility mode for older callers: treat direct args as commence args.
			wallpaper_cache_commence "$@"
			;;
	esac
fi
