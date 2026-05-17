#!/usr/bin/env sh

if ! command -v uwsm >/dev/null 2>&1; then

    echo "'uwsm' package is required for this update. Please install it."
    echo "You can also run './install.sh' to install all missing dependencies."

fi

if command -v hallwayde-shell >/dev/null 2>&1; then
    echo "Reloading HALLwayDE shell shaders..."
    hallwayde-shell shaders --reload
fi
