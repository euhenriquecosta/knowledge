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
