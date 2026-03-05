set -l red (set_color -o red)
set -l cyan (set_color -o cyan)

for i in assets/*;
	set -l file_name (basename $i .svg)
	if test -f ./$file_name'.png'
		echo $red$file_name exists
	else
		echo $cyan'Creating '$file_name'.png'
		convert -background none $i ./$file_name'.png'
	end
;end
