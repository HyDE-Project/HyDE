#!/usr/bin/env sh

# Hyde's Shell Environment Initialization Script

# Basic PATH prepending (user local bin)
PATH="$HOME/.local/bin:$PATH"

# Less history file location
LESSHISTFILE="${LESSHISTFILE:-/tmp/less-hist}"

# Application config files
PARALLEL_HOME="$XDG_CONFIG_HOME/parallel"
SCREENRC="$XDG_CONFIG_HOME/screen/screenrc"

# Export all variables
export PATH LESSHISTFILE PARALLEL_HOME SCREENRC 
