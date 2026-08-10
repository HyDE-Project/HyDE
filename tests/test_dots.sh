#!/usr/bin/env sh
# The installer's dot metafiles have to be well formed.

. "$(dirname -- "$0")/lib/common.sh"

if ! command -v python3 >/dev/null 2>&1; then
    skip "python3 is not installed"
    finish
fi

python3 "$TESTS_DIR/python/check_dots.py" || fail "check_dots reported defects"

hyde_metafile="$REPO_ROOT/Scripts/dots/hyde.toml"
official_grimblast='source = "blob+https://raw.githubusercontent.com/hyprwm/contrib/refs/heads/main/grimblast/grimblast"'

grep -Fqx "$official_grimblast" "$hyde_metafile" ||
    fail "grimblast is not sourced from the fixed upstream main branch"

if grep -q 'feature-grimblast-toplevel-handle' "$hyde_metafile"; then
    fail "grimblast still uses the double-selection experimental branch"
fi

# Dots are deployed in the order the group lists them. The archives download
# over the network and write into /usr/local under sudo, so they are the most
# likely member of the core group to fail and the least important one to have.
# Everything the desktop is made of has to be deployed before them.
core_group="$REPO_ROOT/Scripts/dots-groups/core.toml"
core_order=$(sed -n '/include = \[/,/^ *\]/p' "$core_group" |
    sed -n 's|.*"\.\./dots/\([A-Za-z0-9_-]*\)\.toml".*|\1|p')

position_in_core() {
    printf '%s\n' "$core_order" | grep -nxF "$1" | head -n 1 | cut -d: -f1
}

archives_at=$(position_in_core archives)
# The packages the rest of the group needs are installed by the first entry,
# so it is the one member whose position is fixed rather than merely early.
deps_at=$(position_in_core deps)
if [ -z "$deps_at" ]; then
    fail "the core group no longer includes deps.toml"
elif [ "$deps_at" -ne 1 ]; then
    fail "deps.toml is no longer the first entry in the core group"
fi

if [ -z "$archives_at" ]; then
    fail "the core group no longer includes archives.toml, or the include list could not be read"
else
    for required in hyde hyprland; do
        required_at=$(position_in_core "$required")
        if [ -z "$required_at" ]; then
            fail "the core group no longer includes $required.toml"
        elif [ "$required_at" -gt "$archives_at" ]; then
            fail "$required.toml is deployed after archives.toml in the core group"
        fi
    done
fi

finish
