#!/usr/bin/env sh
# Everything HyDE installs for the user lives in ~/.local/bin, so the fish
# drop-in has to put that directory on PATH. It is easy to get wrong in a way
# nothing reports: fish_add_path takes one directory per argument, does not
# split on ":", and drops a path that does not exist without a word. A
# colon-joined string therefore adds nothing at all and the shell comes up
# looking healthy with no hyde-shell in it.

# shellcheck source=tests/lib/common.sh
. "$(dirname -- "$0")/lib/common.sh"

drop_in="$REPO_ROOT/Configs/.config/fish/conf.d/hyde.fish"

[ -f "$drop_in" ] || {
    fail "the fish drop-in is missing"
    finish
}

# Resolved here rather than called by name below: the run is started with a
# PATH of its own, and a fish installed anywhere but there would not be found.
fish_bin=$(command -v fish 2>/dev/null)
if [ -z "$fish_bin" ]; then
    skip "fish is not installed"
    finish
fi

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

home="$work_dir/home"
mkdir -p "$home/.local/bin" "$work_dir/data" "$work_dir/config"

# An isolated home keeps the universal variables fish_add_path writes out of
# the one running the suite. Past the line under test the drop-in calls a
# function defined elsewhere in the shipped config, which is not sourced here;
# fish reports that on stderr and carries on, so stderr is discarded rather
# than the rest of the configuration being pulled in to silence it.
path_entries=$(
    env -i HOME="$home" \
        XDG_DATA_HOME="$work_dir/data" \
        XDG_CONFIG_HOME="$work_dir/config" \
        PATH=/usr/bin:/bin \
        TERM=dumb \
        "$fish_bin" -c "source '$drop_in' 2>/dev/null; for entry in \$PATH; echo \$entry; end" 2>/dev/null
)

printf '%s\n' "$path_entries" | grep -qxF "$home/.local/bin" ||
    fail "the drop-in did not put ~/.local/bin on PATH, so no HyDE command resolves in fish"

# The failure this case exists for leaves a single entry holding the whole
# joined string, which is a path in name only. Only the entries this drop-in
# contributes are judged; what the machine's own fish configuration puts on
# PATH is not this file's business.
stray=$(printf '%s\n' "$path_entries" | grep "^$home" | grep ':')
[ -n "$stray" ] &&
    fail "PATH holds a colon-joined entry, which is one path that exists nowhere: $stray"

printf '    %d PATH entry(ies) checked\n' "$(printf '%s\n' "$path_entries" | grep -c .)"

finish
