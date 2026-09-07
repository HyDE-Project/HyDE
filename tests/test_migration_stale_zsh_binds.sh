#!/usr/bin/env sh
# Scripts/migrations/v26.9.1.sh must move a leftover conf.d/binds.zsh out of
# the way -- .zshenv sources every *.zsh file it finds under conf.d/ by a
# directory glob, so a copy left over from before #2036 deleted the file from
# the repo keeps re-applying its word-jumping arrow-key bindings on every new
# shell, regardless of what the current checkout ships (#1940, #1958).

. "$(dirname -- "$0")/lib/common.sh"

migration="$REPO_ROOT/Scripts/migrations/v26.9.1.sh"
[ -f "$migration" ] || {
    fail "migration not found at $migration"
    finish
}

work_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$work_dir"' EXIT

run_migration() {
    # Every env var the migration reads has to be pinned into the sandbox --
    # a real XDG_CONFIG_HOME leaking through here once made this test move
    # (and, via its own EXIT trap, delete) the real conf.d/binds.zsh on the
    # machine actually running the suite instead of a fixture.
    HOME="$work_dir/home" \
        XDG_CONFIG_HOME="$work_dir/home/.config" \
        XDG_STATE_HOME="$work_dir/state" \
        ZDOTDIR="${1:-}" \
        sh "$migration"
}

reset_sandbox() {
    rm -rf "$work_dir/home" "$work_dir/state"
    mkdir -p "$work_dir/home"
}

# Missing/absent: no such file at all, at the default ZDOTDIR location.
reset_sandbox
run_migration >"$work_dir/out" 2>&1
status=$?
[ "$status" -eq 0 ] || fail "a missing conf.d/binds.zsh made the migration exit $status"
[ -s "$work_dir/out" ] && fail "a missing conf.d/binds.zsh still produced output: $(cat "$work_dir/out")"
[ -d "$work_dir/state" ] && fail "a missing conf.d/binds.zsh still created a state/backup directory"

# Default ZDOTDIR ($HOME/.config/zsh, same fallback .zshenv itself uses):
# the file must be moved, its content preserved exactly, and the original
# location left empty.
reset_sandbox
mkdir -p "$work_dir/home/.config/zsh/conf.d"
original_content='bindkey "^[OC" forward-word
bindkey "^[OD" backward-word
'
printf '%s' "$original_content" >"$work_dir/home/.config/zsh/conf.d/binds.zsh"

run_migration >"$work_dir/out" 2>&1
status=$?
[ "$status" -eq 0 ] || fail "moving a present conf.d/binds.zsh exited $status: $(cat "$work_dir/out")"
[ -e "$work_dir/home/.config/zsh/conf.d/binds.zsh" ] &&
    fail "conf.d/binds.zsh is still at the original location after the migration ran"

backup="$work_dir/state/hyde/migration/v26.9.1/binds.zsh"
[ -f "$backup" ] || fail "no backup copy was created at $backup"
if [ -f "$backup" ]; then
    # cmp, not a $(...)-captured string compare: command substitution strips
    # trailing newlines from both sides, which would hide exactly the kind
    # of difference this check exists to catch.
    original="$work_dir/original-for-compare"
    printf '%s' "$original_content" >"$original"
    cmp -s "$original" "$backup" ||
        fail "the backed-up file's content does not match the original byte-for-byte"
fi

# A custom ZDOTDIR must be respected, not just the default fallback.
reset_sandbox
mkdir -p "$work_dir/home/custom-zdotdir/conf.d"
printf 'bindkey "^[OC" forward-word\n' >"$work_dir/home/custom-zdotdir/conf.d/binds.zsh"

run_migration "$work_dir/home/custom-zdotdir" >"$work_dir/out" 2>&1
[ -e "$work_dir/home/custom-zdotdir/conf.d/binds.zsh" ] &&
    fail "a custom ZDOTDIR's conf.d/binds.zsh was not moved"
[ -f "$work_dir/state/hyde/migration/v26.9.1/binds.zsh" ] ||
    fail "a custom ZDOTDIR's conf.d/binds.zsh was not backed up to the expected path"

# Idempotency: running again after a successful move must be a silent no-op,
# not an error and not a second backup attempt.
run_migration "$work_dir/home/custom-zdotdir" >"$work_dir/out2" 2>&1
status=$?
[ "$status" -eq 0 ] || fail "re-running after a successful move exited $status"
[ -s "$work_dir/out2" ] && fail "re-running after a successful move produced output: $(cat "$work_dir/out2")"

# Out-of-spec: the file comes back (e.g. a user restored it, or a stray sync)
# while a backup from an earlier run already exists -- the existing backup
# must survive untouched, not get silently overwritten or lost.
mkdir -p "$work_dir/home/custom-zdotdir/conf.d"
printf 'a different, user-restored version\n' >"$work_dir/home/custom-zdotdir/conf.d/binds.zsh"
run_migration "$work_dir/home/custom-zdotdir" >"$work_dir/out3" 2>&1
status=$?
[ "$status" -eq 0 ] && fail "a re-appeared file with an existing backup did not report a conflict"
[ -e "$work_dir/home/custom-zdotdir/conf.d/binds.zsh" ] ||
    fail "a re-appeared file was silently consumed instead of being left in place on conflict"
backup_after=$(cat "$work_dir/state/hyde/migration/v26.9.1/binds.zsh" 2>/dev/null)
case $backup_after in
*"forward-word"*) ;;
*) fail "the original backup was overwritten by the conflicting re-run" ;;
esac

# Out-of-spec: a broken symlink at the source path (present via -L, absent
# via -e) must still be treated as present and moved, not silently ignored.
reset_sandbox
mkdir -p "$work_dir/home/.config/zsh/conf.d"
ln -s "$work_dir/home/.config/zsh/conf.d/does-not-exist-target" "$work_dir/home/.config/zsh/conf.d/binds.zsh"
run_migration >"$work_dir/out4" 2>&1
status=$?
[ "$status" -eq 0 ] || fail "a broken-symlink source exited $status: $(cat "$work_dir/out4")"
[ -e "$work_dir/home/.config/zsh/conf.d/binds.zsh" ] || [ -L "$work_dir/home/.config/zsh/conf.d/binds.zsh" ] &&
    fail "a broken-symlink source was left in place instead of being moved"

# Not run through run_pending_migrations against the real Scripts/migrations
# directory: that would execute every other shipped migration too, each with
# whatever env vars *they* read, not just the ones this file's own sandbox
# happens to cover -- tests/test_migrations.sh already proves the generic
# runner mechanics (order, skip-if-applied, recording) against synthetic
# fixtures; nothing here suggests v26.9.1.sh needs its own copy of that.

finish
