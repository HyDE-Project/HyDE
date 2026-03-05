#! /bin/bash

INKSCAPE="/usr/bin/inkscape"
ZOPFLIPNG="/usr/bin/zopflipng"
SRC_PATH="./src/retrowave/gtk-2.0"

SRC_FILE="assets.svg"
ASSETS_DIR="assets"
INDEX="assets.txt"

for i in `cat $INDEX`
do 
if [ -f $ASSETS_DIR/$i.png ]; then
    echo $ASSETS_DIR/$i.png exists.
else
    echo
    echo Rendering $ASSETS_DIR/$i.png
    $INKSCAPE --export-id=$i \
              --export-id-only \
              --export-background-opacity=0 \
              --export-type="png" \
              --export-filename $ASSETS_DIR/$i.png \
              $SRC_FILE >/dev/null \
    && $ZOPFLIPNG -ym $ASSETS_DIR/$i.png $ASSETS_DIR/$i.png
fi
done
exit 0
