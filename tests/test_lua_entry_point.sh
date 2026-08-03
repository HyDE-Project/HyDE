#!/usr/bin/env bash
# The file Hyprland actually loads has to load HyDE.
#
# Hyprland resolves "$XDG_CONFIG_HOME/hypr/hyprland.lua" ahead of hyprland.conf
# and ignores the latter once the former exists. HyDE deploys that path as the
# user's override layer, which hyde.lua pulls in last, and keeps its own entry
# point in the data directory where Hyprland never looks. Without the loader a
# session started with no HYPRLAND_CONFIG gets a valid empty configuration: no
# error, no bar, no binds.

. "$(dirname -- "$0")/lib/common.sh"

template="$REPO_ROOT/Configs/.config/hypr/hyprland.lua"
migration="$REPO_ROOT/Scripts/migrations/v26.8.1.sh"

grep -q '^if not hyde then$' "$template" ||
    fail "the shipped hyprland.lua does not load HyDE when it is the entry point"

grep -q 'hypr/hyde.lua' "$template" ||
    fail "the shipped hyprland.lua does not name HyDE's entry point"

[ -f "$migration" ] || {
    fail "no migration adds the loader to the copies already deployed"
    finish
}

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

home_dir="$work_dir/home"
config_home="$work_dir/config"
state_home="$work_dir/state"
mkdir -p "$home_dir" "$config_home/hypr" "$state_home"

target="$config_home/hypr/hyprland.lua"
user_line='hl.config({ general = { gaps_in = 7 } })'

run_migration() {
    (
        HOME="$home_dir" XDG_CONFIG_HOME="$config_home" XDG_STATE_HOME="$state_home" \
            sh "$migration" </dev/null
    ) >"$work_dir/out.log" 2>&1
}

# A file without the loader gets it, keeps what the user wrote, and the copy
# from before the change is recoverable.
printf '%s\n' "$user_line" >"$target"
run_migration
status=$?

[ "$status" -eq 0 ] || fail "the migration failed on a file that needed the loader: $(cat "$work_dir/out.log")"
grep -q '^if not hyde then$' "$target" || fail "the migration did not add the loader"
grep -qxF "$user_line" "$target" || fail "the migration dropped what the user had written"
[ "$(head -n 1 "$target")" != "$user_line" ] || fail "the loader was not added before the user's own config"
grep -qxF "$user_line" "$state_home/hyde/migration/v26.8.1/hyprland.lua" ||
    fail "the migration kept no recoverable copy of the original"

# Running it again changes nothing.
before=$(cat "$target")
run_migration
[ "$(cat "$target")" = "$before" ] || fail "a second run of the migration changed the file again"
[ "$(grep -c '^if not hyde then$' "$target")" -eq 1 ] || fail "a second run added the loader twice"

# No file, nothing to do.
rm -f "$target"
run_migration
[ "$?" -eq 0 ] || fail "the migration failed when there was no file to change"
[ -f "$target" ] && fail "the migration created a config that was not there"

# The loader itself: it runs when HyDE has not been loaded, and stays out of
# the way when HyDE is the one loading this file.
command -v lua >/dev/null 2>&1 || {
    skip "lua is not installed, the loader was not executed"
    finish
}

mkdir -p "$work_dir/data/hypr"
printf 'hyde = hyde or {}\nloaded = (loaded or 0) + 1\n' >"$work_dir/data/hypr/hyde.lua"
printf '%s\n' "$user_line" >"$target"
run_migration

entry_runs=$(XDG_DATA_HOME="$work_dir/data" lua -e "
    local ok, err = pcall(dofile, '$target')
    if not ok and not tostring(err):match('hl') then print('error: ' .. tostring(err)) end
    print(loaded or 0)
" 2>/dev/null | tail -n 1)
[ "$entry_runs" = "1" ] || fail "the loader did not reach HyDE when the file was the entry point, got '$entry_runs'"

layer_runs=$(XDG_DATA_HOME="$work_dir/data" lua -e "
    hyde = {}
    local ok, err = pcall(dofile, '$target')
    if not ok and not tostring(err):match('hl') then print('error: ' .. tostring(err)) end
    print(loaded or 0)
" 2>/dev/null | tail -n 1)
[ "$layer_runs" = "0" ] || fail "the loader ran again while HyDE was loading this file, got '$layer_runs'"

finish
