#!/usr/bin/env bash
# The installer deploys the shell it was asked for, and only that one.

. "$(dirname -- "$0")/lib/common.sh"

# No other group may pull a shell in.
for group in core extra; do
    group_file="$REPO_ROOT/Scripts/dots-groups/$group.toml"
    [ -f "$group_file" ] || continue
    grep -qE '"\.\./dots/(zsh|fish)\.toml"' "$group_file" &&
        fail "the $group group installs a shell, so both are installed whatever was chosen"
done

grep -qE '"\.\./dots/zsh\.toml"' "$REPO_ROOT/Scripts/dots-groups/shell.toml" &&
    grep -qE '"\.\./dots/fish\.toml"' "$REPO_ROOT/Scripts/dots-groups/shell.toml" ||
    fail "the shell group no longer offers both shells to choose from"

# deez carries the package manager commands, so a group that repeats them only
# ships a second copy to keep in step.
grep -q 'global.package_managers' "$REPO_ROOT/Scripts/dots-groups/shell.toml" &&
    fail "the shell group repeats the package manager commands deez already carries"

# Both hand-offs name the chosen shell. The file is matched as one line
# because either command may be wrapped.
installer_flat=$(tr '\n' ' ' <"$REPO_ROOT/Scripts/install.sh")

case "$installer_flat" in
*'deps --install --config "${scrDir}/dots-groups/shell.toml"'*'--dots "${myShell}"'*) ;;
*) fail "the installer does not limit the shell dependency step to the chosen shell" ;;
esac

case "$installer_flat" in
*'dots-groups/shell.toml" dots --skip-git --deploy "${myShell}"'*) ;;
*) fail "the installer does not limit the shell deployment to the chosen shell" ;;
esac

# The two scripts are run for real against stubs, because a choice can be lost
# in either of them and a string match on the source would not notice.
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

clone_dir="$work_dir/clone"
home_dir="$work_dir/home"
stub_dir="$work_dir/bin"
mkdir -p "$clone_dir" "$home_dir/.local/state/hyde/python_env/bin" \
    "$home_dir/.local/lib/hyde/wallpaper" "$stub_dir"
cp -a "$REPO_ROOT/Scripts" "$clone_dir/Scripts"

# zsh is the shell the machine already carries and the first of the list, which
# is what used to be taken for the answer.
cat >"$stub_dir/pacman" <<'STUB'
#!/usr/bin/env sh
for arg in "$@"; do
    case "$arg" in
    zsh) exit 0 ;;
    esac
done
exit 1
STUB
cat >"$stub_dir/getent" <<'STUB'
#!/usr/bin/env sh
printf '%s:x:1000:1000::/home/%s:/usr/bin/zsh\n' "$2" "$2"
STUB
chmod +x "$stub_dir/pacman" "$stub_dir/getent"

deez_log="$work_dir/deez.log"
deez_exe="$home_dir/.local/state/hyde/python_env/bin/deez"
printf '#!/usr/bin/env sh\nprintf "%%s\\n" "$*" >>"%s"\nexit 0\n' "$deez_log" >"$deez_exe"
chmod +x "$deez_exe"
ln -sf "$(command -v python3)" "$home_dir/.local/state/hyde/python_env/bin/python"

for stub in install_pre install_aur install_pst restore_thm restore_svc; do
    printf '#!/usr/bin/env sh\nexit 0\n' >"$clone_dir/Scripts/$stub.sh"
    chmod +x "$clone_dir/Scripts/$stub.sh"
done
rm -f "$clone_dir/Scripts/migrations"/*.sh
mkdir -p "$clone_dir/Configs/.local/lib/hyde/pyutils"
for py in lua_env python_env; do
    printf 'import sys\nsys.exit(0)\n' >"$clone_dir/Configs/.local/lib/hyde/pyutils/$py.py"
done
for helper in "wallpaper/cache.sh" "theme.switch.sh" "waybar.py"; do
    printf '#!/usr/bin/env sh\nexit 0\n' >"$home_dir/.local/lib/hyde/$helper"
    chmod +x "$home_dir/.local/lib/hyde/$helper"
done

: >"$deez_log"
# The installer writes its generated configs through mktemp, and one of its
# traps overwrites another, so they are kept inside the case's own directory.
mkdir -p "$work_dir/tmp"
(
    env -u HYPRLAND_INSTANCE_SIGNATURE \
        TMPDIR="$work_dir/tmp" \
        PATH="$stub_dir:$PATH" \
        HOME="$home_dir" \
        XDG_STATE_HOME="$work_dir/state" \
        XDG_CACHE_HOME="$work_dir/cache" \
        CLONE_DIR="$clone_dir" \
        myShell=fish \
        "$clone_dir/Scripts/install.sh" -i -r -t <<<"n"
) >"$work_dir/install.log" 2>&1

grep -q 'shell.toml.*--dots fish' "$deez_log" ||
    grep -q 'dry-run.*fish' "$work_dir/install.log" ||
    fail "the installer did not keep to fish: $(grep -i shell "$work_dir/install.log" | head -n 3)"
grep -qE 'shell\.toml.*(--dots|--deploy) zsh' "$deez_log" &&
    fail "the installer reached for zsh although fish was chosen"
grep -q 'Defaulting to zsh' "$work_dir/install.log" &&
    fail "the installer ignored the choice and fell back to zsh"

# The script that sets the login shell keeps the same choice, does not pull the
# plugins of the other shell, and refuses a shell /etc/shells does not carry.
shell_log="$work_dir/restore_shl.log"
(
    env PATH="$stub_dir:$PATH" \
        HOME="$home_dir" \
        CLONE_DIR="$clone_dir" \
        myShell=fish \
        flg_DryRun=1 \
        "$clone_dir/Scripts/restore_shl.sh" <<<"n"
) >"$shell_log" 2>&1

grep -q 'fish' "$shell_log" ||
    fail "the shell setup lost the choice of fish: $(head -n 3 "$shell_log")"
grep -q 'shell to zsh' "$shell_log" &&
    fail "the shell setup switched the login shell to zsh although fish was chosen"
grep -qi 'oh-my-zsh' "$shell_log" &&
    fail "the shell setup installed zsh plugins for a fish user"

# A shell whose path /etc/shells does not carry is refused, because chsh turns
# it down and the run would end on a bare refusal.
printf '#!/usr/bin/env sh\nexit 0\n' >"$stub_dir/fish"
chmod +x "$stub_dir/fish"
unlisted_log="$work_dir/unlisted.log"
(
    env PATH="$stub_dir:$PATH" \
        HOME="$home_dir" \
        CLONE_DIR="$clone_dir" \
        myShell=fish \
        flg_DryRun=1 \
        "$clone_dir/Scripts/restore_shl.sh" <<<"n"
) >"$unlisted_log" 2>&1

grep -q '/etc/shells' "$unlisted_log" ||
    fail "the shell setup tried to set a shell /etc/shells does not carry: $(tail -n 2 "$unlisted_log")"
grep -q 'change.*shell to' "$unlisted_log" &&
    fail "the shell setup changed the login shell to a path /etc/shells does not carry"

probe() {
    # shellcheck disable=SC1090
    . "$REPO_ROOT/Scripts/global_fn.sh"
    pkg_installed() { return 0; }
    login_shell() { printf '%s\n' "$stub_login"; }
    resolve_shell >/dev/null 2>&1
    printf '%s\n' "${myShell:-}"
}

# An explicit choice outranks everything else.
chosen=$(myShell=fish stub_login=zsh bash -c "$(declare -f probe); probe" 2>/dev/null)
[ "$chosen" = "fish" ] ||
    fail "an explicit choice of fish resolved to '${chosen}'"

# With no choice made, the current login shell is kept.
kept=$(stub_login=fish bash -c "$(declare -f probe); unset myShell; probe" 2>/dev/null)
[ "$kept" = "fish" ] ||
    fail "a restore of its own moved a fish login to '${kept}'"

# A login shell outside the list still resolves to something installed.
other=$(stub_login=bash bash -c "$(declare -f probe); unset myShell; probe" 2>/dev/null)
[ -n "$other" ] ||
    fail "a login shell outside the list resolved to nothing"

# /etc/shells is matched by resolved path, and read whole.
listing() {
    # shellcheck disable=SC1090
    . "$REPO_ROOT/Scripts/global_fn.sh"
    work=$(mktemp -d)
    trap 'rm -rf "$work"' EXIT
    target="$work/bin/fish"
    mkdir -p "$work/bin" "$work/link"
    printf '#!/bin/sh\n' >"$target"
    chmod +x "$target"
    ln -s "$target" "$work/link/fish"

    printf '%s' "$work/link/fish" >"$work/no-newline"
    shell_listed "$target" "$work/no-newline" ||
        printf 'missed the last entry of a file with no trailing newline\n'

    printf '  %s  \n' "$work/link/fish" >"$work/padded"
    shell_listed "$target" "$work/padded" ||
        printf 'missed an entry written with surrounding spaces\n'

    printf '# %s\n' "$work/link/fish" >"$work/commented"
    shell_listed "$target" "$work/commented" &&
        printf 'accepted a commented out entry\n'

    : >"$work/empty"
    shell_listed "$target" "$work/empty" &&
        printf 'accepted a shell an empty file does not list\n'
    return 0
}

while IFS= read -r problem; do
    [ -n "$problem" ] && fail "$problem"
done <<EOF
$(bash -c "$(declare -f listing); listing" 2>/dev/null)
EOF

printf '    shell selection checked\n'

finish
