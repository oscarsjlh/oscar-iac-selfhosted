#!/bin/bash
# Date: $(date +%Y-%m-%d)
set -euo pipefail
# Your script starts here

############################################
# CONFIGURATION
############################################

# GitHub info

# Forgejo info
source /home/oscar/git-mirror/.env
# Where to clone temporary mirrors

WORKDIR="/tmp/mirror"
mkdir -p "$WORKDIR"

echo "Fetching repos…"
repos=$(gh repo list $GITHUB_USER --source --limit 200 --json name,visibility)

echo "$repos" | jq -c '.[]' | while read -r repo; do
  name=$(echo "$repo" | jq -r '.name')
  echo "$name"
  private=$(echo "$repo" | jq -r '.visibility')
  is_private=$([[ "$private" == "private" ]] && echo true || echo false)

  echo "⚙️ Mirroring $name (private=$is_private)…"

  cd "$WORKDIR"
  if [ -d "$name".git ]; then continue; fi
  gh repo clone oscarsjlh/"$name" -- --mirror

  # Create repo on Forgejo
  curl -s -X POST "$FORGEJO_URL/api/v1/user/repos" \
    -H "Authorization: token $FORGEJO_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"$name\", \"private\": $is_private}" \
    >/dev/null 2>&1 || true
  cd $name.git || true
  # Push the mirror
  git push --mirror \
    "https://$FORGEJO_USER:$FORGEJO_TOKEN@git.oscarcorner.com/$FORGEJO_USER/$name.git" || true

  echo "✔ $name synced"
done

rm -rf $WORKDIR
