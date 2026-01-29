#!/bin/sh
set -e

cd /knowledge

git config user.email "knowledge@local"
git config user.name "Knowledge Bot"

if [ ! -d ".git" ]; then
  echo "ERROR: .git not found in /knowledge/.git. Mount the volume correctly."
  exit 1
fi

DOCS_PATH="/docs"
INDEX_FILE="/tmp/docs_index"
mkdir -p "$DOCS_PATH"

commit_to_docs() {
  MSG="$1"

  rm -f "$INDEX_FILE"
  if git rev-parse --verify docs >/dev/null 2>&1; then
    GIT_INDEX_FILE="$INDEX_FILE" git read-tree docs
  fi

  GIT_INDEX_FILE="$INDEX_FILE" GIT_WORK_TREE="$DOCS_PATH" git add -A

  if ! GIT_INDEX_FILE="$INDEX_FILE" git diff --cached --quiet; then
    TREE=$(GIT_INDEX_FILE="$INDEX_FILE" git write-tree)

    if git rev-parse --verify docs >/dev/null 2>&1; then
      PARENT=$(git rev-parse docs)
      COMMIT=$(git commit-tree "$TREE" -p "$PARENT" -m "$MSG")
    else
      COMMIT=$(git commit-tree "$TREE" -m "$MSG")
    fi

    git update-ref refs/heads/docs "$COMMIT"
    return 0
  fi
  return 1
}

if ! git rev-parse --verify docs >/dev/null 2>&1; then
  echo "Creating orphan branch 'docs'..."

  echo '*' > "$DOCS_PATH/.gitignore"
  cp /SETUP.md "$DOCS_PATH/MCP_SETUP.md"

  commit_to_docs "initial docs branch"
else
  # Extrair arquivos da branch docs para /docs
  git archive docs | tar -x -C "$DOCS_PATH"
fi

echo "Watching $DOCS_PATH for changes..."

cd "$DOCS_PATH"

while inotifywait -r -e close_write,move,create,delete "$DOCS_PATH" >/dev/null 2>&1; do
  now=$(date +"%Y-%m-%d %H:%M:%S")

  cd /knowledge
  if commit_to_docs "$now"; then
    echo "commited: $now"
  fi

  cd "$DOCS_PATH"
done
