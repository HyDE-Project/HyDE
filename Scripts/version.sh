#!/usr/bin/env bash

DOORWAYDE_CLONE_PATH=$(git rev-parse --show-toplevel)
DOORWAYDE_BRANCH=$(git rev-parse --abbrev-ref HEAD)
DOORWAYDE_REMOTE=$(git config --get remote.origin.url)
DOORWAYDE_VERSION=$(git describe --tags --always)
DOORWAYDE_COMMIT_HASH=$(git rev-parse HEAD)
DOORWAYDE_VERSION_COMMIT_MSG=$(git log -1 --pretty=%B)
DOORWAYDE_VERSION_LAST_CHECKED=$(date +%Y-%m-%d\ %H:%M%S\ %z)

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

# DOORWAYDE_RELEASE_NOTES=$(generate_release_notes)

echo "DOORwayDE $DOORWAYDE_VERSION built from branch $DOORWAYDE_BRANCH at commit ${DOORWAYDE_COMMIT_HASH:0:12} ($DOORWAYDE_VERSION_COMMIT_MSG)"
echo "Date: $DOORWAYDE_VERSION_LAST_CHECKED"
echo "Repository: $DOORWAYDE_CLONE_PATH"
echo "Remote: $DOORWAYDE_REMOTE"
echo ""

if [[ "$1" == "--cache" ]]; then
  state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/doorwayde"
  mkdir -p "$state_dir"
  version_file="$state_dir/version"

  cat >"$version_file" <<EOL
DOORWAYDE_CLONE_PATH='$DOORWAYDE_CLONE_PATH'
DOORWAYDE_BRANCH='$DOORWAYDE_BRANCH'
DOORWAYDE_REMOTE='$DOORWAYDE_REMOTE'
DOORWAYDE_VERSION='$DOORWAYDE_VERSION'
DOORWAYDE_VERSION_LAST_CHECKED='$DOORWAYDE_VERSION_LAST_CHECKED'
DOORWAYDE_VERSION_COMMIT_MSG='$DOORWAYDE_VERSION_COMMIT_MSG'
DOORWAYDE_COMMIT_HASH='$DOORWAYDE_COMMIT_HASH'
EOL
# DOORWAYDE_RELEASE_NOTES='$DOORWAYDE_RELEASE_NOTES'

  echo -e "Version cache output to $version_file\n"

elif [[ "$1" == "--release-notes" ]]; then
  echo "$DOORWAYDE_RELEASE_NOTES"

fi
