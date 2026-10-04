#!/usr/bin/env sh
set -eu

repo_root=${REPO_ROOT:-$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)}
fish_bin=${FISH_BIN:-fish}
history_bindings=${HISTORY_BINDINGS:-$repo_root/Configs/.config/fish/functions/bind_M_n_history.fish}
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT HUP INT TERM
mkdir -p "$scratch/data/fish" "$scratch/config"

for mode in fish_default_key_bindings fish_vi_key_bindings; do
    : > "$scratch/data/fish/hyde_history_test_history"
    XDG_DATA_HOME="$scratch/data" XDG_CONFIG_HOME="$scratch/config" \
        fish_history=hyde_history_test KEY_MODE="$mode" \
        HISTORY_FILE="$scratch/data/fish/hyde_history_test_history" COMMAND_OUTPUT="$scratch/output" \
        HISTORY_BINDINGS="$history_bindings" \
        "$fish_bin" <<'FISH'
source "$HISTORY_BINDINGS"
set -g fish_key_bindings "$KEY_MODE"

function bind
    set -ga registered_commands "$argv[-1]"
end

function commandline
    test "$argv[1]" = -r; or exit 1
    set -g selected "$argv[2]"
end

test (count $history) -eq 0; or exit 1
bind_M_n_history
set -l expected_bindings 9
if test "$KEY_MODE" = fish_vi_key_bindings
    set expected_bindings 18
end
test (count $registered_commands) -eq $expected_bindings; or exit 1

# Let Fish advance its history read boundary before merging new entries.
printf '%s\n' '- cmd: printf old' '  when: 1' '- cmd: printf new' '  when: 2' >> "$HISTORY_FILE"
sleep 1
builtin history --merge
test (count $history) -eq 2; or exit 1
test "$history[1]" = 'printf new'; or exit 1
test "$history[2]" = 'printf old'; or exit 1

for index in (seq (count $registered_commands))
    set -l key $index
    if test "$KEY_MODE" = fish_vi_key_bindings
        set key (math "ceil($index / 2)")
    end
    set -g selected unchanged
    eval "$registered_commands[$index]" > "$COMMAND_OUTPUT"
    set -l output (string collect < "$COMMAND_OUTPUT")
    switch $key
        case 1
            test "$selected" = 'printf new'; or begin
                printf 'Alt+1 selected: %s\n' "$selected"
                exit 1
            end
        case 2
            test "$selected" = 'printf old'; or exit 1
        case '*'
            test "$selected" = unchanged; or exit 1
            test "$output" = "No history found for number $key"; or exit 1
    end
end
printf '%s\n' "$KEY_MODE: history added after startup is available"
FISH
done
