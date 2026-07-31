#!/usr/bin/env sh
# Generated schema artifacts must not restore commands removed by migrations.

. "$(dirname -- "$0")/lib/common.sh"

schema_dir="$REPO_ROOT/Configs/.local/share/hyde/schema"
artifacts="
schema.toml
config.toml
config.toml.json
config.md
"

for artifact in $artifacts; do
    path="$schema_dir/$artifact"

    if grep -q 'batterynotify\.sh' "$path"; then
        fail "$artifact still references the removed batterynotify.sh"
    fi

    if ! grep -q 'batterynotify\.lua' "$path"; then
        fail "$artifact does not reference batterynotify.lua"
    fi
done

finish
