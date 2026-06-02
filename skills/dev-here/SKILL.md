---
name: dev-here
description: |
  Sobe o dev server desta pasta numa porta específica, abre uma aba do browser travada nessa
  porta e arma um vigia de erros — sem tocar nas abas de outros projetos. Use ao invocar
  `/dev-here <porta>` ou ao pedir pra subir/ver/monitorar o server de uma cópia numa porta sem
  mexer nas outras que rodam em paralelo.
---

# dev-here

## Por que existe

Várias cópias do mesmo projeto (branches em pastas irmãs), cada uma numa porta, com várias
instâncias do Claude Code no mesmo browser, compartilham **um único grupo de abas do MCP**
(`claude-in-chrome`) — então uma instância pode clicar na aba de outra. Esta skill prende cada
sessão à **sua** porta.

## Invocação

`/dev-here <porta>`. Sem argumento, pergunte a porta. A porta (`PORT`) é a fonte da verdade:
server bind nela, aba navega nela, Monitor vigia o log dela.

Dois princípios: **inspecione antes de perguntar** (ofereça opções com dados reais — apps,
browsers — nunca no abstrato); **investigue, não assuma** (agnóstica de stack: descubra como o
projeto roda olhando os arquivos).

## Fluxo

### 1. A porta já está ocupada?

```bash
ss -ltn "sport = :PORT" | grep -q LISTEN && echo OCUPADA || echo LIVRE
```

(`ss` checa quem *escuta*; `curl -sf` daria falso "livre" se a raiz responde 404/500.)
**Ocupada** → reaproveite, pule pro passo 3. **Livre** → suba.

### 2. Subir o server

1. **Ache o comando dev.** Leia o manifest. **Monorepo** (`workspaces`, `turbo.json`,
   `pnpm-workspace.yaml`, `nx.json`): o `dev` da raiz sobe *todos* os apps — liste os workspaces
   com script `dev` e, se houver mais de um, pergunte qual. Trabalhe no dir do app.
2. **Sobrescreva a porta:**
   - Comando já fixa porta (`--port N`, `-p N`, `PORT=N`) → **troque o número** por `PORT`.
   - Não fixa → adicione a flag do framework (se não souber, `<bin> --help` ou `find-docs`;
     fallback `PORT=PORT`).
   - **Force a porta exata** quando der (ex. Vite `--strictPort`) — sem auto-incremento.
3. **Rode em background** (`run_in_background: true`), com log dedicado:

   ```bash
   cd apps/<app> && ./node_modules/.bin/<bin> dev --port PORT > /tmp/dev-here-PORT.log 2>&1
   ```

4. **Espere o bind TCP**, em outro Bash background:

   ```bash
   until ss -ltn "sport = :PORT" | grep -q LISTEN; do sleep 0.5; done
   ```

   ~20s sem subir → leia o log e reporte o erro.

### 3. Conectar e travar a aba

1. **Selecione o browser.** `list_connected_browsers`, então pergunte (`AskUserQuestion`)
   listando todos (nomes + deviceIds) + a opção de confirmar no Chrome. Recomende o device
   marcado "on this computer": `localhost:PORT` só resolve na máquina onde o server subiu.
2. **Ache ou crie a aba.** `tabs_context_mcp` (`createIfEmpty: true`): se já houver aba em
   `localhost:PORT`, reuse-a; senão `tabs_create_mcp`. `navigate` pra `http://localhost:PORT`
   (se não carregar, tente `https://`).
3. **Grave o `tab_id` como `TARGET_TAB_ID`.**
4. **Cheque a URL final.** Se redirecionou pra login (`/login`, `/auth`, `/sign-in`, `/entrar`,
   `/acesso`, `/conta` e afins), **pare e peça pro usuário logar** — você nunca insere
   credenciais. Quando avisar, siga.

Sem screenshot — devolva o controle.

### 4. Armar o vigia (Monitor tool)

Vigia **erros/warnings no log** e a **porta (se cair)**. Vigiar a porta — não um PID — sobrevive
a reinícios do dev server:

```bash
tail -n 0 -f /tmp/dev-here-PORT.log | grep -E --line-buffered \
  "[Ee]rror|Exception|Traceback|[Ww]arn|Failed to compile|unhandled|ECONNREFUSED|EADDRINUSE|panic|FATAL" &
TPID=$!
miss=0
while true; do
  if lsof -ti tcp:PORT >/dev/null 2>&1; then miss=0; else miss=$((miss+1)); [ $miss -ge 2 ] && break; fi
  sleep 2
done
kill $TPID 2>/dev/null
echo "SERVER caiu na porta PORT — me peça pra subir de novo"
```

`description: "server na porta PORT"`, `persistent: true`. `tail -n 0` = só linhas novas; dois
misses (~4s sem a porta) = caiu de verdade, não um reinício. Server caiu → ofereça subir de
novo. Erro relevante → `PushNotification`.

### 5. Devolver o controle

Reporte curto: porta, log, `TARGET_TAB_ID`, Monitor armado. Pare.

## Regra de ouro do isolamento

- **Você possui uma aba: `TARGET_TAB_ID`** (`localhost:PORT`). Toda interação com o app vai nela.
- **Confirme a URL ao conectar**, depois use o `tab_id` direto; re-valide só se uma ação falhar.
- **Nunca** aja numa aba `localhost:<outra-porta>` — são de outros projetos/instâncias.
- Abas que não são a sua não são problema seu — não as toque, não as bloqueie.
## Interagir e debugar a aba (depois do setup)

- **Texto > print.** Pra inspecionar/clicar, use `find` ou `read_page` (`filter=interactive`) —
  barato e dá refs. Screenshot (~1,5k tok, só viewport, sem refs) só pro visual (layout/CSS/render).
- **Passos previsíveis → `browser_batch`.** Encadeie ações conhecidas (`navigate`+`read_page`,
  `form_input` em vários refs, click+type+press) numa só chamada e corte round-trips. Ele **não
  passa saída→entrada**: se o próximo passo depende de um ref que você só descobre agora, vá normal.
- **Server é vigiado; client é sob demanda.** O Monitor é passivo e te avisa sozinho — mas só
  do **log do server** (stdout). O lado **client** (React, `fetch` 4xx/5xx, exceção no browser)
  vive no **console do browser**, que o shell não consegue observar → **não há notificação
  automática**. Pra ver, rode `read_console_messages` (`onlyErrors`)/`read_network_requests` na
  aba **quando** a tela parecer quebrada ou uma ação falhar — não conte com aviso espontâneo.
- **Storage/cookies.** `javascript_tool` lê `localStorage`/`sessionStorage` e cookies
  não-HttpOnly direto. Cookie de sessão **HttpOnly** o JS não enxerga — e ver isso exigiria
  CDP/debug port, que abandonaria este setup; então fica fora do alcance da skill.

## Encerrar

Quando a tarefa terminar, **pergunte se quer encerrar**. Se sim: derrube o server
(`lsof -ti tcp:PORT | xargs -r kill`), `TaskStop` no Monitor, `tabs_close_mcp` no
`TARGET_TAB_ID` (só a sua aba), e remova o log.
