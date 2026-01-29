# Knowledge

Container para **base de conhecimento em Markdown** com:

- Filesystem MCP Server (Model Context Protocol) apontando para `/knowledge`
- Auto-versionamento com Git (`branch` orphan `docs`)
- Auto-commit/push em qualquer alteração sob `./docs`

Inspirado em práticas de projetos open source que usam `docs/` como raiz de documentação (MkDocs, Sphinx, etc.). [web:76][web:77][web:82]

Ideal para usar com Claude, Cursor e outros clientes MCP, mantendo documentação versionada em Git.

---

## Visão geral

Este container foi pensado para cenários onde:

- A IA (Claude, Cursor, etc.) manipula arquivos `.md` via **Filesystem MCP**
- Toda alteração em `./docs` deve ser:
    - versionada em Git
    - comitada automaticamente
    - enviada para um remote na branch `docs` (orphan)

A IA não precisa saber de Git: ela apenas lê/escreve arquivos; o container cuida de versionamento e push.

---

## Estrutura esperada no repositório

```text
meu-projeto/
├── .git/                 # repositório Git normal
├── src/                  # seu código (opcional)
├── docs/                 # documentação em Markdown
│   ├── README.md
│   ├── architecture/
│   │   ├── overview.md
│   │   └── decisions.md
│   ├── backend/
│   │   ├── api.md
│   │   └── database.md
│   └── devops/
│       ├── docker.md
│       └── kubernetes.md
├── Dockerfile
├── entrypoint.sh
└── docker-compose.yml
```

## Requisitos

- Git já inicializado no projeto (`.git` existente).
- Docker instalado.
- Remote `origin` configurado e com credenciais válidas para `git push`.

Estrutura mínima sugerida:

```text
meu-projeto/
├── .git/
├── docs/
│   └── README.md
└── (outros arquivos do projeto)
```

---

## Como usar a imagem

### 1. Criar e popular `docs/`

No seu projeto:

```bash
mkdir -p docs
echo "# Documentação do Projeto" > docs/README.md
git add .
git commit -m "chore: add docs folder"
```

### 2. Rodar o container

Usando a imagem pública:

```bash
docker run -d \
  --name knowledge \
  -v $(pwd)/.git:/knowledge/.git \
  -v $(pwd)/docs:/knowledge \
  matizzee/knowledge:latest
```

> **Nota:** O container usa **git worktree** internamente para trabalhar na branch `docs` em `/docs`, sem alterar a branch atual do seu repositório local.

Ou com `docker-compose`:

```yaml
version: "3.9"

services:
    knowledge:
        image: matizzee/knowledge:latest
        volumes:
            - ./.git:/knowledge/.git
            - ./docs:/knowledge
        restart: unless-stopped
```

Subir:

```bash
docker compose up -d knowledge
```

### 3. O que o container faz

Ao iniciar, ele:

1. Lê o `.git` montado em `/git`.
2. Garante que existe uma **branch órfã `docs`**:
    - Se não existir, cria uma orphan `docs`, cria arquivos iniciais (`README.md` e `MCP_SETUP.md`) e faz o primeiro commit.
3. Cria um **git worktree** em `/knowledge` apontando para a branch `docs`.
    - Isso isola completamente a branch `docs` sem alterar a branch atual do seu repositório local.
4. Sobe o **Filesystem MCP Server** com root em `/knowledge`.
5. Fica monitorando `/knowledge` com `inotifywait`:
    - Sempre que algum arquivo mudar, roda:
        - `git add .`
        - `git commit --allow-empty -m "auto: <timestamp>"`
        - `git push origin docs`

Você continua usando `main` (ou outra branch) para o código; a branch `docs` fica só para documentação. **Sua branch local nunca é alterada.**

---

## Conectando o MCP (Filesystem)

O servidor MCP roda dentro do container e é exposto via `docker exec` usando `stdio`.

### Comando base

Para testar no terminal:

```bash
docker exec -i knowledge \
  npx -y @modelcontextprotocol/server-filesystem /knowledge
```

### Exemplo de configuração – Claude / Cursor

No arquivo de configuração de MCP do seu cliente, adicione algo como:

```jsonc
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
                "/knowledge",
            ],
        },
    },
}
```

Depois disso, o cliente passa a enxergar o servidor `knowledge-fs` com tools:

- `read_file`
- `write_file`
- `edit_file`
- `list_directory`
- etc., sempre sob `/knowledge` (sua pasta `docs/`).

---

## Fluxo típico com IA

Com o MCP configurado:

- Peça algo como:
    - "Liste os arquivos de documentação disponíveis."
    - "Abra `architecture/overview.md`."
    - "Adicione uma nova seção explicando o fluxo de autenticação."
- A IA usa o Filesystem MCP para ler/editar arquivos em `/knowledge`.
- O container comita e dá push automaticamente na branch `docs`.

---

## Dica: `.gitignore` na branch principal

Como a branch `docs` é órfã (histórico independente), você pode opcionalmente adicionar `docs/` ao `.gitignore` da sua branch principal (`main`):

```gitignore
# Documentação gerenciada pela branch órfã 'docs'
docs/
```

**Prós:**

- Branch `main` fica mais limpa, sem duplicar arquivos de documentação
- Evita commits acidentais de `docs/` na branch errada

**Contras:**

- Perde a referência inicial de `docs/` na `main`

**Isso não causa problemas** porque:

- A branch `docs` tem histórico completamente separado
- O container trabalha exclusivamente na branch `docs`
- Não há conflito entre as branches

Essa configuração é **opcional** — escolha conforme sua preferência de organização.

```

```
