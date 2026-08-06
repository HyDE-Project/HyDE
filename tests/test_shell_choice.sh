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

# Installing a dependency out of that group needs the managers declared in it.
grep -q 'global.package_managers' "$REPO_ROOT/Scripts/dots-groups/shell.toml" ||
    fail "the shell group declares no package managers, its dependencies cannot install"

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

# A shell that cannot be set is refused before chsh is reached.
grep -q 'shell_listed' "$REPO_ROOT/Scripts/restore_shl.sh" ||
    fail "restore_shl.sh changes the login shell without checking /etc/shells"

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
