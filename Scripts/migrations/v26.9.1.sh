#!/usr/bin/env sh

# "$ZDOTDIR/conf.d/binds.zsh" (default $ZDOTDIR: "$HOME/.config/zsh", the same
# fallback .zshenv itself uses for its conf.d glob) shipped bindkey lines that
# mapped the plain arrow keys' SS3 form ("^[OC"/"^[OD" -- what a terminal like
# kitty sends for Left/Right, per its own terminfo kcuf1/kcub1) to
# forward-word/backward-word instead of char movement. #2036 (d020fde0)
# already deleted the file from the repo, but .zshenv sources every
# "*.zsh" file it finds under conf.d/ by a directory glob, regardless of
# whether the repo still ships it -- an install from before that fix still
# has the file on disk, keeps sourcing it on every new shell, and silently
# turns the arrow keys back into word-jumps, the exact bug #2036 already
# fixed upstream (#1940, #1958).
#
# Nothing is deleted. The file is moved into a backup directory, so a user
# who deliberately repurposed it for their own bindings still has it on disk.

config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
zdotdir="${ZDOTDIR:-${config_home}/zsh}"
state_home="${XDG_STATE_HOME:-${HOME}/.local/state}"
backup_dir="${state_home}/hyde/migration/v26.9.1"

src="${zdotdir}/conf.d/binds.zsh"
dst="${backup_dir}/binds.zsh"

[ -e "${src}" ] || [ -L "${src}" ] || exit 0

# A rerun after the file was restored would otherwise destroy the copy kept
# by the first run, so an occupied destination is reported and left alone.
if [ -e "${dst}" ] || [ -L "${dst}" ]; then
    echo "  skipped conf.d/binds.zsh, a backup already exists at ${dst}" >&2
    exit 1
fi

if ! mkdir -p "${backup_dir}"; then
    echo "  failed to create ${backup_dir}" >&2
    exit 1
fi

if mv "${src}" "${dst}"; then
    echo "Moved the stale conf.d/binds.zsh (superseded by #2036) to ${backup_dir}"
    echo "Plain arrow keys move by character in zsh again."
    exit 0
fi

echo "  failed to move conf.d/binds.zsh" >&2
exit 1
