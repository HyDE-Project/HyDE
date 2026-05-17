#!/usr/bin/env bash

HALLWAYDE_CLONE_PATH=$(git rev-parse --show-toplevel)
HALLWAYDE_BRANCH=$(git rev-parse --abbrev-ref HEAD)
HALLWAYDE_REMOTE=$(git config --get remote.origin.url)
HALLWAYDE_VERSION=$(git describe --tags --always)
HALLWAYDE_COMMIT_HASH=$(git rev-parse HEAD)
HALLWAYDE_VERSION_COMMIT_MSG=$(git log -1 --pretty=%B)
HALLWAYDE_VERSION_LAST_CHECKED=$(date +%Y-%m-%d\ %H:%M%S\ %z)

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

# HALLWAYDE_RELEASE_NOTES=$(generate_release_notes)

echo "HALLwayDE $HALLWAYDE_VERSION built from branch $HALLWAYDE_BRANCH at commit ${HALLWAYDE_COMMIT_HASH:0:12} ($HALLWAYDE_VERSION_COMMIT_MSG)"
echo "Date: $HALLWAYDE_VERSION_LAST_CHECKED"
echo "Repository: $HALLWAYDE_CLONE_PATH"
echo "Remote: $HALLWAYDE_REMOTE"
echo ""

if [[ "$1" == "--cache" ]]; then
  state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hallwayde"
  mkdir -p "$state_dir"
  version_file="$state_dir/version"

  cat >"$version_file" <<EOL
HALLWAYDE_CLONE_PATH='$HALLWAYDE_CLONE_PATH'
HALLWAYDE_BRANCH='$HALLWAYDE_BRANCH'
HALLWAYDE_REMOTE='$HALLWAYDE_REMOTE'
HALLWAYDE_VERSION='$HALLWAYDE_VERSION'
HALLWAYDE_VERSION_LAST_CHECKED='$HALLWAYDE_VERSION_LAST_CHECKED'
HALLWAYDE_VERSION_COMMIT_MSG='$HALLWAYDE_VERSION_COMMIT_MSG'
HALLWAYDE_COMMIT_HASH='$HALLWAYDE_COMMIT_HASH'
EOL
# HALLWAYDE_RELEASE_NOTES='$HALLWAYDE_RELEASE_NOTES'

  echo -e "Version cache output to $version_file\n"

elif [[ "$1" == "--release-notes" ]]; then
  echo "$HALLWAYDE_RELEASE_NOTES"

fi
