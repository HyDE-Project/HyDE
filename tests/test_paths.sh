#!/usr/bin/env sh
# The Hyprland config resolves its paths through hyde.path, which runs before
# anything else in the session. An environment it cannot cope with takes the
# whole config down, so the resolver has to survive a missing or empty variable
# rather than error on a nil concatenation.

# shellcheck source=tests/lib/common.sh
. "$(dirname -- "$0")/lib/common.sh"

if ! command -v lua >/dev/null 2>&1; then
    skip "lua is not installed"
    finish
fi

path_module="$REPO_ROOT/Configs/.local/share/hypr/lua/hyde/path.lua"
[ -f "$path_module" ] || {
    fail "hyde/path.lua is missing"
    finish
}

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
mkdir -p "$work_dir/home/.config"

# Prints the resolved value of one field, or "error" when loading blew up. A
# module that fails to load exits non-zero as well: a case that expects a path
# not to be chosen would otherwise be satisfied by the module never running.
resolve() {
    lua -e "
        local ok, err = pcall(dofile, [[$path_module]])
        if not ok then
            io.write('error: ', tostring(err))
            os.exit(1)
        end

        io.write(tostring(hyde.path.$1))
    " 2>&1
}

config=$(HOME="$work_dir/home" XDG_CONFIG_HOME='' resolve config)
[ "$config" = "$work_dir/home/.config" ] ||
    fail "an empty XDG_CONFIG_HOME did not fall back to HOME: $config"

config=$(HOME="$work_dir/home" XDG_CONFIG_HOME="$work_dir/elsewhere" resolve config)
[ "$config" = "$work_dir/elsewhere" ] ||
    fail "a set XDG_CONFIG_HOME was not honoured: $config"

# A session without HOME cannot resolve the fallback, but it must not error:
# an unresolved path is skippable, a raised error is not.
config=$(env -u HOME -u XDG_CONFIG_HOME lua -e "
    local ok, err = pcall(dofile, [[$path_module]])
    if not ok then
        io.write('error: ', tostring(err))
    else
        io.write(tostring(hyde.path.config))
    end
" 2>&1)
case $config in
error*) fail "an absent HOME raised instead of leaving the path unresolved: $config" ;;
nil) ;;
*) fail "an absent HOME resolved a path out of nowhere: $config" ;;
esac

# An empty value is unset, and a directory with no meaningful default stays
# unresolved rather than becoming "" — paths built on that resolve against the
# working directory instead of failing where they can be seen.
runtime=$(HOME="$work_dir/home" XDG_RUNTIME_DIR='' resolve runtime)
[ "$runtime" = "nil" ] ||
    fail "an empty XDG_RUNTIME_DIR did not read as unset: [$runtime]"

runtime=$(HOME="$work_dir/home" XDG_RUNTIME_DIR="$work_dir/run" resolve runtime)
[ "$runtime" = "$work_dir/run" ] ||
    fail "a set XDG_RUNTIME_DIR was not honoured: $runtime"

# A home directory is allowed to contain a quote: it has to be found, and it
# must not be able to run anything. The probe no longer goes through a shell,
# which is what makes the second half of that hold; the case stays as the guard
# that says so.
quoted_home="$work_dir/qu'ote"
mkdir -p "$quoted_home/.local/lib"
lib=$(HOME="$quoted_home" resolve lib)
[ "$lib" = "$quoted_home/.local/lib" ] ||
    fail "a home directory containing a quote was skipped: $lib"

marker="$work_dir/executed"
HOME="$work_dir/x'; touch \"$marker\"; echo '" resolve lib >/dev/null 2>&1
[ -e "$marker" ] &&
    fail "a crafted HOME executed a command through the directory probe"

# A candidate that is not a directory has to be rejected, and a FIFO is the one
# that can do more than that: opening it with no writer on the other end blocks
# until one turns up, and this resolver runs before the session has a window on
# screen. It must answer, and it must answer no.
if command -v mkfifo >/dev/null 2>&1 && command -v timeout >/dev/null 2>&1; then
    fifo_home="$work_dir/fifo"
    mkdir -p "$fifo_home/.local"
    mkfifo "$fifo_home/.local/lib"

    lib=$(HOME="$fifo_home" timeout 5 lua -e "
        local ok, err = pcall(dofile, [[$path_module]])
        if not ok then
            io.write('error: ', tostring(err))
            os.exit(1)
        end

        io.write(tostring(hyde.path.lib))
    " 2>&1)
    case $? in
    0) ;;
    124) fail "a FIFO in place of a candidate directory hung the resolver" ;;
    *) fail "the resolver raised on a FIFO candidate instead of skipping it: $lib" ;;
    esac
    [ "$lib" = "$fifo_home/.local/lib" ] &&
        fail "a FIFO was resolved as a directory: $lib"
else
    skip "mkfifo or timeout is not available, FIFO case not run"
fi

# A regular file where a directory is expected is the same question without the
# hazard, and the answer has to be the same.
file_home="$work_dir/file"
mkdir -p "$file_home/.local"
: > "$file_home/.local/lib"
lib=$(HOME="$file_home" resolve lib) ||
    fail "the resolver raised on a regular file candidate: $lib"
[ "$lib" = "$file_home/.local/lib" ] &&
    fail "a regular file was resolved as a directory: $lib"

# A directory that grants search but not read still serves files by name, which
# is all package.path asks of it, so it counts. Running as root makes the
# distinction disappear, and the case then only asserts the ordinary answer.
xonly_home="$work_dir/xonly"
mkdir -p "$xonly_home/.local/lib"
chmod 111 "$xonly_home/.local/lib"
lib=$(HOME="$xonly_home" resolve lib)
chmod 755 "$xonly_home/.local/lib"
[ "$lib" = "$xonly_home/.local/lib" ] ||
    fail "an unreadable candidate directory was skipped: $lib"

# The consumer has to be prepared for that, otherwise the guard above buys
# nothing: dynamic.lua must not concatenate the config path unconditionally.
dynamic="$REPO_ROOT/Configs/.local/share/hypr/lua/dynamic.lua"
grep -q 'os.getenv("XDG_CONFIG_HOME") \.\.' "$dynamic" &&
    fail "dynamic.lua still builds the config path by concatenating os.getenv"

# Every probe of an optional file has to close what it opened; a bare
# `if io.open(path) then` leaks a handle on every config reload.
grep -qE '^[[:space:]]*if io\.open\(' "$dynamic" &&
    fail "dynamic.lua tests a file with io.open without closing the handle"

printf '    %d path field(s) checked\n' 5

finish
