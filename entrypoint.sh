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
mkdir -p "$DOCS_PATH"

# Criar branch órfã 'docs' se não existir
if ! git rev-parse --verify docs >/dev/null 2>&1; then
  echo "Creating orphan branch 'docs'..."

  EMPTY_TREE=$(git hash-object -t tree /dev/null)
  COMMIT=$(git commit-tree "$EMPTY_TREE" -m "initial docs branch")
  git branch docs "$COMMIT"

  cat > "$DOCS_PATH/MCP_SETUP.md" << 'EOF'
# Configuração do MCP (Model Context Protocol)

Para conectar este servidor de conhecimento ao Claude, Cursor ou outro cliente MCP, adicione a seguinte configuração no arquivo de configuração do seu cliente:

## Localização do arquivo de configuração

- **Claude Desktop (macOS):** `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Claude Desktop (Windows):** `%APPDATA%\Claude\claude_desktop_config.json`
- **Cursor:** `.cursor/mcp.json` na raiz do projeto ou configurações globais

## Configuração

```json
{
  "mcpServers": {
    "knowledge": {
      "command": "docker",
      "args": [
        "exec",
        "-i",
        "knowledge",
        "npx",
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/docs"
      ]
    }
  }
}
```

## Ferramentas disponíveis após configuração

- `read_file` - Ler arquivos de documentação
- `write_file` - Criar novos arquivos
- `edit_file` - Editar arquivos existentes
- `list_directory` - Listar diretórios
- `create_directory` - Criar diretórios
- `move_file` - Mover/renomear arquivos

## Verificação

Para testar se o servidor está funcionando:

```bash
docker exec -i knowledge npx -y @modelcontextprotocol/server-filesystem /docs
```

Se o comando não retornar erro, o servidor está pronto para uso.
EOF

  GIT_WORK_TREE="$DOCS_PATH" git add -A
  GIT_WORK_TREE="$DOCS_PATH" git commit --allow-empty -m "initial docs branch"
  git push -u origin docs || echo "WARNING: unable to push initial docs branch"
else
  # Extrair arquivos da branch docs para /docs
  git archive docs | tar -x -C "$DOCS_PATH"
fi

echo "Watching $DOCS_PATH for changes..."

cd "$DOCS_PATH"

while true; do
  inotifywait -r -e close_write,move,create,delete . >/dev/null 2>&1
  now=$(date +"%Y-%m-%d %H:%M:%S")

  # Commit usando a branch docs diretamente
  cd /knowledge
  GIT_WORK_TREE="$DOCS_PATH" git add -A
  GIT_WORK_TREE="$DOCS_PATH" git diff --cached --quiet || \
    GIT_WORK_TREE="$DOCS_PATH" git commit -m "auto: $now"
  git push origin docs || echo "WARNING: git push failed"

  cd "$DOCS_PATH"
  echo "$now"
done
