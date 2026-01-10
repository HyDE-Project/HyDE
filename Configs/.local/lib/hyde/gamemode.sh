#!/usr/bin/env bash
HYPRGAMEMODE=$(hyprctl getoption animations:enabled | sed -n '1p' | awk '{print $2}')
if [ "$HYPRGAMEMODE" = 1 ]; then
    hyde-shell workflows --set gaming
else
    hyde-shell workflows --set default
fi
