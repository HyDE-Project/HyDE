set -l  wm 'close' 'close_prelight' 'close_unfocused' 'min' 'min_prelight' 'maximize' 'maximize_prelight'
set -l path '../../assets/'
for item in $wm
	inkscape -z $path$item.svg -e $path$item@2.png --export-dpi=192; optipng -o7 --quiet $path$item@2.png 
end
