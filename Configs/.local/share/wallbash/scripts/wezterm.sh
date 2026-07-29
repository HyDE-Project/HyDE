#!/usr/bin/env bash

# Applies a freshly generated wallbash palette to WezTerm.
#
# WezTerm watches its configuration and reloads on change, so there is no
# signal to send. It only watches files it read while evaluating the config,
# and a colour file that did not exist on the last evaluation is not among
# them, so the entry point is touched to force one reload.

confDir="${confDir:-$HOME/.config}"
weztermConf="${confDir}/wezterm/wezterm.lua"

[ -f "$weztermConf" ] || exit 0

touch "$weztermConf"
