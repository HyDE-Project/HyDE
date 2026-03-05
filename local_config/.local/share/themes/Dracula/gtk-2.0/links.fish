set -l files 'checkbox' 'radio'
set -l states 'unchecked' 'checked' 'mixed'
set -l sub_states 'active' 'hover' 'insensitive'

for f in $files;
	for s in $states;
		ln -sf ../../assets/$f-$s.png ./assets/$f-$s.png
		for i in $sub_states;
			ln -sf ../../assets/$f-$s-$i.png ./assets/$f-$s-$i.png
		;end
	;end

;end
