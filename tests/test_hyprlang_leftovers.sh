#!/usr/bin/env bash
# The hyprlang configuration the Lua release deleted is still on every upgraded
# machine, because deployment overwrites files and never removes the ones that
# disappeared upstream. It is not inert: Hyprland falls back to hyprland.conf
# when no Lua config is found, and that file sources the rest, so a session can
# land on the pre-Lua configuration entirely.
#
# The migration moves it aside, and only when the Lua entry point is in place —
# taking the fallback away while nothing else can be found would leave Hyprland
# to generate a default config, which is worse than the leftovers.

. "$(dirname -- "$0")/lib/common.sh"

migration="$REPO_ROOT/Scripts/migrations/v26.8.2.sh"

if [ ! -f "$migration" ]; then
    fail "no migration retires the hyprlang configuration"
    finish
fi

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

home_dir="$work_dir/home"
config_home="$work_dir/config"
data_home="$work_dir/data"
state_home="$work_dir/state"

leftovers_config="animations.conf hyprland.conf keybindings.conf monitors.conf nvidia.conf shaders.conf userprefs.conf windowrules.conf workflows.conf"
leftovers_data="hypr/defaults.conf hypr/dynamic.conf hypr/env.conf hypr/finale.conf hypr/hyprland.conf hypr/migration.conf hypr/startup.conf hypr/variables.conf hypr/windowrules.conf hyde/hyprland.conf hyde/keybindings.conf"
# Still hyprlang, still shipped: these must survive untouched.
kept_config="hypridle.conf hyprlock.conf hyprsunset.conf"

seed() {
    rm -rf "$home_dir" "$config_home" "$data_home" "$state_home"
    mkdir -p "$home_dir" "$config_home/hypr" "$data_home/hypr" "$data_home/hyde" "$state_home"

    for rel in $leftovers_config $kept_config; do
        printf 'old %s\n' "$rel" >"$config_home/hypr/$rel"
    done
    mkdir -p "$config_home/hypr/animations" "$config_home/hypr/workflows" "$config_home/hypr/shaders"
    printf 'old animation\n' >"$config_home/hypr/animations/theme.conf"
    printf 'old workflow\n' >"$config_home/hypr/workflows/default.conf"
    printf 'still shipped\n' >"$config_home/hypr/shaders/wallbash.frag"

    for rel in $leftovers_data; do
        mkdir -p "$(dirname "$data_home/$rel")"
        printf 'old %s\n' "$rel" >"$data_home/$rel"
    done
    mkdir -p "$data_home/hyde/templates/hypr"
    printf 'old template\n' >"$data_home/hyde/templates/hypr/keybindings.conf"
    printf 'still shipped\n' >"$data_home/hypr/hyprlock.conf"

    # The gate: the entry point exists and the user's config loads it.
    printf 'hyde = hyde or {}\n' >"$data_home/hypr/hyde.lua"
    printf 'if not hyde then\nend\n' >"$config_home/hypr/hyprland.lua"
}

run_migration() {
    (
        HOME="$home_dir" XDG_CONFIG_HOME="$config_home" XDG_DATA_HOME="$data_home" \
            XDG_STATE_HOME="$state_home" sh "$migration" </dev/null
    ) >"$work_dir/out.log" 2>&1
}

backup="$state_home/hyde/migration/v26.8.2"

# The whole chain is retired, the files still in use are not, and every moved
# file is recoverable.
seed
run_migration
status=$?

[ "$status" -eq 0 ] || fail "the migration failed on a machine it should act on: $(cat "$work_dir/out.log")"

for rel in $leftovers_config; do
    [ -e "$config_home/hypr/$rel" ] && fail "$rel was left in place"
    [ -f "$backup/config/hypr/$rel" ] || fail "$rel was not kept in the backup"
done
for rel in $leftovers_data; do
    [ -e "$data_home/$rel" ] && fail "$rel was left in place"
    [ -f "$backup/data/$rel" ] || fail "$rel was not kept in the backup"
done
[ -e "$config_home/hypr/animations" ] && fail "the animations directory was left in place"
[ -e "$config_home/hypr/workflows" ] && fail "the workflows directory was left in place"
[ -e "$data_home/hyde/templates/hypr" ] && fail "the hyprlang templates were left in place"

for rel in $kept_config; do
    [ -f "$config_home/hypr/$rel" ] || fail "$rel is still hyprlang and still shipped, but was moved"
done
[ -f "$config_home/hypr/shaders/wallbash.frag" ] || fail "the shader directory was moved"
[ -f "$data_home/hypr/hyprlock.conf" ] || fail "the shipped hyprlock config was moved"
[ -f "$config_home/hypr/hyprland.lua" ] || fail "the Lua config was moved"
[ -f "$data_home/hypr/hyde.lua" ] || fail "the entry point was moved"

# Nothing to do on a second pass.
run_migration
[ "$?" -eq 0 ] || fail "a second run failed"

# No entry point: the fallback has to stay, or the machine is left with nothing
# to load at all.
seed
rm -f "$data_home/hypr/hyde.lua"
run_migration
[ "$?" -eq 0 ] || fail "the migration failed instead of skipping without an entry point"
[ -f "$config_home/hypr/hyprland.conf" ] ||
    fail "the fallback config was moved with no entry point to replace it"

# An unreadable entry point is no entry point: the loader opens it.
seed
chmod 000 "$data_home/hypr/hyde.lua"
run_migration
chmod 644 "$data_home/hypr/hyde.lua"
[ -f "$config_home/hypr/hyprland.conf" ] ||
    fail "the fallback config was moved while the entry point could not be read"

# The user's config does not load HyDE yet: same reasoning.
seed
printf 'hl.config({})\n' >"$config_home/hypr/hyprland.lua"
run_migration
[ -f "$config_home/hypr/hyprland.conf" ] ||
    fail "the fallback config was moved before the user's config could load HyDE"

# A retired path left as a dangling symlink still has to go, or it stays
# forever and the migration reports success.
seed
rm -f "$config_home/hypr/hyprland.conf"
ln -s "$work_dir/nothing-here.conf" "$config_home/hypr/hyprland.conf"
run_migration
[ -e "$config_home/hypr/hyprland.conf" ] || [ -L "$config_home/hypr/hyprland.conf" ] &&
    fail "a dangling symlink at a retired path was left behind"

finish
