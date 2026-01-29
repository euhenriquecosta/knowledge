#!/bin/sh
set -e

cd /knowledge

if [ ! -d ".git" ]; then
  echo "ERROR: .git not found in /knowledge/.git. Mount the volume correctly."
  exit 1
fi

if ! git rev-parse --verify docs >/dev/null 2>&1; then
  echo "Creating orphan branch 'docs'..."
  git switch --orphan docs 2>/dev/null || git checkout --orphan docs
  git rm -rf . >/dev/null 2>&1 || true
  echo "# Knowledge" > README.md
  git add .
  git commit -m "initial docs branch"

  git push -u origin docs || echo "WARNING: unable to push initial docs branch"
else
  echo "Switching to branch 'docs'..."
  git switch docs 2>/dev/null || git checkout docs
fi

echo "Watching /knowledge for changes..."

while true; do
  inotifywait -r -e close_write,move,create,delete . >/dev/null 2>&1
  now=$(date +"%Y-%m-%d %H:%M:%S")
  git add .
  git commit --allow-empty -m "auto: $now"
  git push origin docs || echo "WARNING: git push failed"
  echo "$now"
done
