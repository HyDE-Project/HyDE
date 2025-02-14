#!/usr/bin/env bash
hyprctl dispatch "$1" $(((($(hyprctl activeworkspace -j | jq -r .id) - 1)  / 5) * 5 + $2))
