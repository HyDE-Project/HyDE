#!/usr/bin/env sh
# The tree must not hold a gitlink without a matching submodule declaration.
#
# A commit entry with no `.gitmodules` counterpart makes `git submodule` fail
# for everyone who clones, and takes down any tooling that walks submodules,
# `actions/checkout` among them.

. "$(dirname -- "$0")/lib/common.sh"

if ! command -v git >/dev/null 2>&1; then
    skip "git is not installed"
    finish
fi

if ! git -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    skip "not a git checkout"
    finish
fi

gitlinks=$(git -C "$REPO_ROOT" ls-tree -r HEAD | awk '$2 == "commit" { print $4 }')

count=0
for path in $gitlinks; do
    count=$((count + 1))

    if [ ! -f "$REPO_ROOT/.gitmodules" ]; then
        fail "$path is a gitlink but the tree has no .gitmodules"
        continue
    fi

    if ! grep -q "path *= *$path\$" "$REPO_ROOT/.gitmodules"; then
        fail "$path is a gitlink with no entry in .gitmodules"
    fi
done

printf '    %d gitlink(s) checked\n' "$count"
finish
