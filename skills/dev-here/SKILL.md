---
name: dev-here
description: |
  Sobe o dev server DESTA pasta numa porta específica, abre uma aba dedicada do browser travada
  nessa porta, e arma um vigia de erros — sem nunca tocar nas telas de outros projetos rodando
  em paralelo. Use sempre que invocar `/dev-here <porta>`, ou quando pedir pra "subir o server
  na porta X e ver/cuidar na tela", "rodar essa cópia e monitorar", ou quando estiver
  trabalhando com várias cópias do mesmo projeto (branches em pastas irmãs) e precisar isolar
  qual delas o Claude controla. Agnóstica de stack: descobre como rodar investigando o projeto.
---

# dev-here

Sobe o dev server desta pasta numa porta que você escolhe, conecta uma aba do browser travada
nessa porta, e arma um Monitor que avisa quando o server erra ou cai. Devolve o controle assim
que a aba abre — sem screenshot.

## Por que existe

Quando se roda **várias cópias do mesmo projeto** (branches em pastas irmãs), cada uma numa
porta diferente, e **várias instâncias do Claude Code** apontam pro mesmo browser, todas
compartilham o **mesmo grupo de abas do MCP** (`claude-in-chrome` usa um único "MCP tab group"
por browser). Sem disciplina, a instância da cópia A clica na aba da cópia B. Esta skill
garante que **você-aqui só mexe na SUA porta** — a proteção é por porta, não por "localhost
genérico" (ferramentas auxiliares como o visual-companion do `/brainstorming` também sobem
localhost em portas próprias e não devem ser bloqueadas).

## Invocação

`/dev-here <porta>` — ex: `/dev-here 3007`. Sem argumento, pergunte a porta antes de tudo. A
porta (`PORT` daqui em diante) é a fonte da verdade: o server bind nela, a aba navega nela, o
Monitor vigia a porta e o log dela.

**Princípio geral:** antes de perguntar qualquer coisa, **inspecione o que existe de fato** e
ofereça opções com dados reais (apps detectados, browsers conectados, porta) — nunca pergunte
no abstrato. E **investigue em vez de assumir**: esta skill é agnóstica de stack, então
descubra como o projeto roda olhando os arquivos, não chutando.

## Fluxo

### 1. A porta já está ocupada?

```bash
ss -ltn "sport = :PORT" | grep -q LISTEN && echo OCUPADA || echo LIVRE
```

(checa quem *escuta* a porta — não use `curl -sf`, que dá falso "livre" se a raiz responde 404/500.)

- **Ocupada** → assuma que o server desta pasta já está de pé; pule pro passo 3. (Se a aba
  mostrar algo que não bate com o projeto, é sinal de que outro app tomou a porta — avise.)
- **Livre** → suba (passo 2).

### 2. Subir o server (só se a porta estava livre)

Descubra **como rodar** investigando o projeto — não há tabela fixa de frameworks:

1. **Resolva o comando dev real.** Leia o manifest (`package.json` scripts, ou o equivalente
   do ecossistema). **Se for monorepo** (`workspaces` no package.json, `turbo.json`,
   `pnpm-workspace.yaml`, `nx.json`): o `dev` da raiz costuma subir *todos* os apps — não é o
   que você quer. Liste os workspaces que têm script `dev`; se houver mais de um, mostre-os e
   **pergunte qual** (dados reais). Trabalhe a partir do dir do app escolhido.
2. **Sobrescreva a porta de forma agnóstica:**
   - Se o comando dev **já fixa uma porta** (`--port N`, `-p N`, `PORT=N`), **troque o número**
     por `PORT`, preservando todo o resto do comando. (Funciona sem saber o framework — é só
     trocar o valor. Resolve cópias que hardcodam a mesma porta e colidiriam.)
   - Se **não** fixa porta, adicione a flag de porta do framework. Não decore: se não souber a
     flag, rode `<bin> --help` ou consulte a doc (`find-docs`). Fallback amplo: prefixe
     `PORT=PORT`.
   - **Force a porta exata** quando o framework permitir (ex. Vite `--strictPort`) — sem
     auto-incremento, senão a aba não casa com o server.
3. **Rode em background**, com stdout+stderr num log dedicado, e use `run_in_background: true`:

   ```bash
   # exemplo: app Next num monorepo cujo script era "next dev --port 3001"
   cd apps/<app> && bun run next dev --port PORT > /tmp/dev-here-PORT.log 2>&1
   ```

4. **Espere a porta abrir** (só o bind TCP, não é smoke check) com outro Bash em background:

   ```bash
   until ss -ltn "sport = :PORT" | grep -q LISTEN; do sleep 0.5; done
   ```

   Se passar ~20s sem subir, leia `/tmp/dev-here-PORT.log` e reporte o erro em vez de seguir cego.

### 3. Conectar e travar a aba

1. **Selecione o browser.** Pode haver mais de um dispositivo pareado. Chame
   `list_connected_browsers` e siga o protocolo do MCP: pergunte via `AskUserQuestion` listando
   **todos** (nomes + deviceIds reais) + a opção de confirmar dentro do Chrome — não escolha
   sozinho. **Prefira/recomende o device marcado como "on this computer"**: o server subiu
   nesta máquina e `localhost:PORT` só resolve localmente. Se escolher outra máquina, avise que
   a aba não alcançará o server.
2. `tabs_context_mcp` com `createIfEmpty: true` → `tabs_create_mcp` (**sempre aba nova**, não
   reaproveite — pode ser de outra cópia) → `navigate` pra `http://localhost:PORT`.
3. **Grave o `tab_id` como `TARGET_TAB_ID`** — a única aba que esta sessão possui.
4. **Cheque a URL final** (só a URL, não é screenshot). Se redirecionou pra login (`/login`,
   `/auth`, `/sign-in`, `/entrar`, `/acesso`, `/conta` e similares), **pare e peça pro usuário
   logar ele mesmo** — você **nunca insere credenciais**. Quando ele avisar, siga.

Fora a URL, não tire screenshot nem valide conteúdo — devolva o controle (passo 5).

### 4. Armar o vigia (Monitor tool)

O `Monitor` não é subagente e não roda em modelo próprio — faz streaming de linhas do log e
notifica, barato por natureza. Arme persistente, vigiando **conteúdo (erros + warnings)** e o
**processo (se cair)**:

```bash
SPID=$(lsof -ti tcp:PORT | head -1)
tail -n 0 -f /tmp/dev-here-PORT.log | grep -E --line-buffered \
  "[Ee]rror|ERR!|Exception|Traceback|[Ww]arn|Failed to compile|unhandled|ECONNREFUSED|EADDRINUSE|panic|FATAL" &
TPID=$!
while kill -0 "$SPID" 2>/dev/null; do sleep 2; done
kill $TPID 2>/dev/null
echo "SERVER caiu ou foi fechado na porta PORT — me peça pra subir de novo"
```

(`tail -n 0` só vê linhas **novas** — não re-notifica erros/warnings que já estavam no log
quando você armou o Monitor. `kill $TPID` evita deixar o `tail` órfão quando o server cai.)

`description: "server na porta PORT"`, `persistent: true`. (`SPID` via `lsof` funciona tanto se
você subiu o server quanto se reaproveitou um já rodando.) Quando o server cair, ofereça
**subir de novo** (refazer o passo 2). Num erro relevante, mande `PushNotification`.

### 5. Devolver o controle

Reporte curto: porta, log, `TARGET_TAB_ID`, Monitor armado. Pare — você abre/inspeciona a aba
quando o usuário pedir ou quando o Monitor sinalizar.

## Regra de ouro do isolamento

- **Você possui uma aba: `TARGET_TAB_ID`** (a de `localhost:PORT`). Toda interação com o app
  vai nela.
- **Confirme a URL ao conectar.** Depois use o `tab_id` direto; **só re-valide se uma ação
  falhar** ou se você criou/fechou abas no meio (revalidar antes de *cada* ação é caro e
  desnecessário — o tab_id é estável na sessão e cada instância só mexe na própria aba).
- **Nunca** aja numa aba `localhost:<outra-porta>` — são de outros projetos/instâncias. É o que
  o usuário não quer que você toque.
- **Abas que não são seu app são livres** (companion do brainstorming, docs, GitHub). A trava é
  **comportamental**: abrir outras abas pra outros fins continua permitido.

## Encerrar

`TaskStop` no Monitor e mate o server pela porta: `lsof -ti tcp:PORT | xargs -r kill`. Remova
`/tmp/dev-here-PORT.log` quando não precisar.
