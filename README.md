# luna-tools

Seis ferramentas de linha de comando pequenas (sh e Python, só biblioteca padrão), feitas para uso diário de uma engenheira de sistemas. Licença MIT.

| Ferramenta | Para quê | Precisa de |
|---|---|---|
| `buscar "termo" [n]` | busca na web por uma SearXNG local (sem rastreio nem chave) | [SearXNG](https://github.com/searxng/searxng) instalada à parte (AGPL-3.0, não incluída), `curl` |
| `ficha <domínio\|IP\|URL>` | ficha pública para triagem: RDAP, DNS, SPF/DMARC, certificados | Python 3.9+ |
| `olhar <url\|arquivo.html> [pasta]` | prints de uma página (celular escuro e computador claro) para conferir antes de entregar | Chromium |
| `pre-commit-segredo` | hook que barra commit com cara de segredo (token, chave, senha) | `git`, `awk` |
| `resumir [-n N] -- comando` | roda um comando, guarda a saída inteira num arquivo e mostra só um resumo | Python 3.9+ |
| `risco <repo> [n]` | ranking dos arquivos onde vale olhar primeiro (mudanças recentes × tamanho × ramificações) | Python 3.9+, `git` |

## Uso rápido

```sh
git clone <este repositório> && cd luna-tools
cp pre-commit-segredo/pre-commit-segredo /caminho/do/seu/repo/.git/hooks/pre-commit
python3 ficha/ficha example.com
python3 risco/risco . 10
sh olhar/olhar pagina.html saida/        # CHROME=/caminho/do/chromium se não estiver no PATH
sh tests/run.sh                          # testes de fumaça e regressão
```

`buscar` usa `SEARXNG_PY` (python do venv do SearXNG) e `SEARXNG_SETTINGS` (configuração; modelo em `buscar/searxng-settings.exemplo.yml`: troque a `secret_key` com `openssl rand -hex 32`). Ele escuta só em `127.0.0.1:8888`.

## Atenção

- **`ficha` envia o alvo a terceiros** (rdap.org, cloudflare-dns.com, crt.sh). Endereços internos, reservados e nomes sem ponto ou com sufixo interno (`.local`, `.lan`, `.corp`…) nunca são enviados. Use só para triagem legítima de domínios e IPs, nunca para levantar dados de pessoas.
- `olhar` abre a URL num Chromium com sandbox ligado. `OLHAR_NO_SANDBOX=1` desliga (só dentro de container, nunca com URL desconhecida).
- `pre-commit-segredo` é rede de segurança contra descuido, não contra quem quer burlar (`--no-verify` ignora). O padrão `senha/token=valor` pode dar falso positivo em texto comum.
- `resumir` guarda a saída do comando em arquivo `0600` numa pasta `0700` do usuário (`RESUMIR_DIR` muda o lugar).

## Créditos

Ideias de: [Headroom](https://github.com/headroomlabs-ai/headroom) (`resumir`) e Repowise (`risco`). `buscar` depende do SearXNG (AGPL-3.0), só como link.
