#!/usr/bin/env bash
for f in "$@"; do
	rsvg-convert -d 300 -p 300 -f svg "$f" -o "${f}.bak" ; mv "${f}.bak" "$f"
done
