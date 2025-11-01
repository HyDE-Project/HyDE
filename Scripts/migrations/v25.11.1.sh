#!/usr/bin/env sh

if ! command -v dex >/dev/null 2>&1; then

    echo "'dex' package is required for this update. Please install it."
    echo "You can also run './install.sh' to install all missing dependencies."

fi
