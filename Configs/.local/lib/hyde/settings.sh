#!/usr/bin/env sh
# @name: settings
# @short: Open HyDE Settings
# GTK introspection belongs to the distribution Python, not HyDE's isolated venv.
exec /usr/bin/python3 "$(dirname -- "$0")/settings.py" "$@"
