#!/usr/bin/env bash

HYDE_CLONE_PATH=$(git rev-parse --show-toplevel)
HYDE_BRANCH=$(git rev-parse --abbrev-ref HEAD)
HYDE_REMOTE=$(git config --get remote.origin.url)
HYDE_VERSION=$(git describe --tags --always)
HYDE_COMMIT_HASH=$(git rev-parse HEAD)
HYDE_VERSION_COMMIT_MSG=$(git log -1 --pretty=%B)
HYDE_VERSION_LAST_CHECKED=$(date +%Y-%m-%d\ %H:%M%S\ %z)

generate_release_notes() {
  local latest_tag
  local commits

  latest_tag=$(git describe --tags --abbrev=0 2>/dev/null)

  if [[ -z "$latest_tag" ]]; then
    echo "No release tags found"
    return
  fi

  echo "=== Changes since $latest_tag ==="

  commits=$(git log --oneline --pretty=format:"• %s" "$latest_tag"..HEAD 2>/dev/null)

  if [[ -z "$commits" ]]; then
    echo "No commits since last release"
    return
  fi

  echo "$commits"
}

HYDE_RELEASE_NOTES=$(generate_release_notes)

echo "HyDE $HYDE_VERSION built from branch $HYDE_BRANCH at commit ${HYDE_COMMIT_HASH:0:12} ($HYDE_VERSION_COMMIT_MSG)"
echo "Date: $HYDE_VERSION_LAST_CHECKED"
echo "Repository: $HYDE_CLONE_PATH"
echo "Remote: $HYDE_REMOTE"
echo ""

if [[ "$1" == "--cache" ]]; then
  state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hyde"
  mkdir -p "$state_dir"
  version_file="$state_dir/version"

  cat >"$version_file" <<EOL
HYDE_CLONE_PATH='$HYDE_CLONE_PATH'
HYDE_BRANCH='$HYDE_BRANCH'
HYDE_REMOTE='$HYDE_REMOTE'
HYDE_VERSION='$HYDE_VERSION'
HYDE_VERSION_LAST_CHECKED='$HYDE_VERSION_LAST_CHECKED'
HYDE_VERSION_COMMIT_MSG='$HYDE_VERSION_COMMIT_MSG'
HYDE_COMMIT_HASH='$HYDE_COMMIT_HASH'
HYDE_RELEASE_NOTES='$HYDE_RELEASE_NOTES'
EOL

  echo -e "Version cache output to $version_file\n"

elif [[ "$1" == "--release-notes" ]]; then
  echo "$HYDE_RELEASE_NOTES"

fi
