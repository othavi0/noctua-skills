# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Sem versionamento por tag ainda, este arquivo acompanha o `main`.

## [Unreleased]

- `humanize-pt-br`: o `scripts/scan.py` pega as formas fixas de mais 24
  marcas do catálogo. Entram como marca as variantes do contraste 17 ("não se
  trata de X, trata-se de Y", "deixa de ser X e passa a ser Y", "não X, e sim
  Y", "mais do que X, é Y", "parece X. Na verdade é Y"), a lista negativa 18, a
  abertura formulaica 3, o staccato "Sem X. Sem Y." (23), o setup retórico 25, a
  conclusão genérica 35, o hífen indevido 45 e as frases de chatbot 46 a 49.
  Entram como aviso 5, 7, 16, 26, 27, 36, 39 e 41, que têm uso legítimo. Antes o
  scan pegava 9 de 33 frases plantadas com uma marca mecânica cada, e 1 de 28
  frases novas escritas depois. Agora pega 33 de 33 e 24 de 28. Nos 31 `.md`
  do repo, fora o catálogo, as regras novas não acham nada, e os 228 achados
  das regras antigas continuam os mesmos. Nas 16 frases limpas de teste, o scan
  dá 0 achados. O formato de saída e o código de saída não mudam.

- `nuvem`: o `fetch` baixa só os arquivos que a API marca `downloadable`. Os
  12 "download(s) failed" e os curl 22 com 400 de 10 a 14 de novembro eram todos
  o arquivo de apoio (`*-apoio.tar.gz`) que o próprio `start` envia. A API
  lista esse arquivo na sessão e responde 400 `file_not_downloadable`, e o
  filtro antigo pulava só o nome fixo `support.tar.gz`. O download que falha
  agora diz o código HTTP, o endpoint e a mensagem da API. A listagem segue o
  cursor `page`/`next_page` no lugar do `after_id`. O header perde o
  `files-api-2025-04-14`: a Files API saiu do beta, e em 24 de novembro cada
  GET do script deu o mesmo código com e sem ele. A cópia instalada já mandava só
  `managed-agents-2026-04-01` desde 13 de novembro. O SKILL.md diz que o
  `start` roda na sessão principal ou no coordenador do workflow, porque o
  classificador do auto mode negou o `start` de um subagente 3 vezes em 14 de
  novembro. Entra o `evals/nuvem-script.test.sh`, com um curl falso no PATH.

- Saem as skills `mobile-up` e `claude-md-prune`, a pedido do dono. Nos
  transcripts de 10 a 24 de novembro a `mobile-up` não teve nenhum uso e a
  `claude-md-prune` só rodou neste repo. As `description` da `dev-up` e da
  `dev-up-agent-browser` deixam de citar a `mobile-up`, e o README passa a
  dizer que as duas leem o nome da própria pasta.

- `dev-up-agent-browser`: quando o próprio user digita `/dev-up-agent-browser
  PORTA`, a janela abre visível (`show`), e a palavra "headless" no pedido
  mantém headless. Agente, workflow e subagente que usam a skill como prova
  seguem headless. Em 21 chamadas do user de 10 a 24 de novembro, 13 pediam
  "abre visualmente". A janela visível passa `--idle-timeout 0` em toda chamada
  e não fecha mais por ociosidade, depois de 26 avisos "had closed; reopened"
  nos transcripts. A sessão headless segue fechando em 30 minutos, e
  `DEV_UP_AB_IDLE` troca esse prazo. O daemon aplica o valor novo sem relançar o
  browser (medido: o mesmo pid e o mesmo `launchHash` antes e depois de 12 s
  parado, com `DEV_UP_AB_IDLE=5s`). Entram `login PORTA [USUÁRIO]` e
  `recipe [set 'CMD' [USUÁRIO] | rm]`. A receita de login de cada repo mora em
  `~/.config/dev-up-ab/logins/`, com a URL do `origin` como chave, e todo
  worktree e clone do repo acha a mesma. Ela guarda só um comando do projeto
  que loga sem imprimir a senha, com `{port}` e `{user}`, e recusa comando com
  senha. Sai a receita `fill @ref "$(jq ...)"`, que um hook barrou e a sessão
  isolada em worktree recusa. Sem receita, o agente pede ao user para logar na
  janela e oferece salvar uma. O `show` que falha diz o motivo do
  agent-browser e se o servidor caiu. O `FAILED` de 17 de novembro era um
  `ERR_CONNECTION_REFUSED`, porque o servidor tinha acabado de cair por OOM.

- `dev-up` e `dev-up-agent-browser`: as duas skills levam o mesmo
  `scripts/dev-up.sh`, byte a byte, e cada eval falha com `cmp` quando as
  cópias divergem. Antes eram dois scripts de 384 e 548 linhas, e toda correção
  entrava duas vezes. O script lê o nome da pasta acima de `scripts/`
  (resolvendo symlink) e escolhe por ele o cache (`~/.cache/dev-up` ou
  `~/.cache/dev-up-ab`) e a chave própria do estado (`tab_id` ou `ab_mode`).
  Na `dev-up`, `ab`, `show`, `hide`, `dash` e `browser` seguem como
  comando desconhecido, e o `state PORT show` segue sem a linha do navegador. A
  `dev-up` ganha por tabela o que a `dev-up-agent-browser` já tinha: o
  reinício em falha (`Restart=on-failure`, no máximo 5 partidas em 10 minutos)
  com a linha `dev-up: server exited` no log, no `watch` e no hook, o aviso de
  unidade viva sem porta aberta, `state PORT resume` e `logs PORT [N]`. O
  teste de bash 3.2 monta a pasta da skill, para o script achar o próprio nome.

- `dev-up-agent-browser`: o `serve` sobe a unidade com `Restart=on-failure`,
  1 s de espera e no máximo 5 partidas em 10 minutos. Nos transcripts de 10 a 24
  de novembro, o `wait` falhou 17 de 101 vezes, 15 delas porque o `next dev`
  16.4 sai com código 1 para mostrar o aviso de upgrade quando vê um agente no
  ambiente (`CLAUDECODE`, `AI_AGENT`, que o `serve` copia) e só sobe na
  repetição. O journal tem 4 `oom-kill` de unidades `dev-up-N` no mesmo
  período. As duas quedas agora voltam sozinhas, e cada uma grava no log a linha
  `dev-up: server exited result=R code=C status=S`, que o `watch` repassa, e o
  hook também quando não há watcher. O `stop` não grava linha, qualquer que
  seja o código de saída. Servidor que cai 5 vezes em 10 minutos, rápido ou
  devagar, fica parado e o `wait` dá `DIED`. O hook avisa também a unidade
  viva sem porta aberta e fica calado só no segundo do reinício. Entram `state PORT
  resume` e `logs PORT [N]`, que os agentes chamaram 6 vezes sem existir. O
  `ab PORT screenshot` cria a pasta quando o último argumento é caminho de
  imagem (sem diferenciar maiúsculas) e não seletor, depois de 36 falhas por
  pasta inexistente, e o `ab` sai com código 3 e um `ERROR` quando o próprio
  `agent-browser` não executa, no lugar de dizer que reabriu a sessão.

- `dev-up-agent-browser`: `ab PORT js '<código>'` roda o `agent-browser eval`, e
  `ab PORT js -` lê o código do stdin. Uma sessão isolada em worktree recusa
  todo comando com a palavra `eval`, então a skill e as references ensinam
  `js`. `ab PORT eval` segue funcionando.

- `dev-up` e `dev-up-agent-browser`: o `serve` sobe toda unidade com teto de
  4G de RAM (`MemoryMax`) e 1G de swap (`MemorySwapMax`). Antes o teto só
  entrava com `--mem`, e só de RAM. Em 11 de novembro de 2026, dois servidores
  `next dev` subidos sem `--mem` tinham `MemoryMax=infinity`, pico de 5,1 e 5,6
  GiB de RAM e 2,9 e 2,3 GiB de swap cada, e a máquina de 15 GiB chegou a 20 GiB
  de swap em uso. `--mem SIZE` e o novo `--swap SIZE` trocam os tetos,
  `DEV_UP_MEM` e `DEV_UP_SWAP` trocam o padrão, e `--mem none` tira os dois. O
  servidor que passa do teto morre sozinho, e o troubleshooting manda subir de
  novo com teto maior.

- `dev-up` e `dev-up-agent-browser`: a convenção do atalho mostra o caminho
  inteiro do script e manda nunca guardá-lo em variável. Nos transcripts de 14
  dias, 135 de 199 chamadas do `dev-up-agent-browser` e 27 do `dev-up` vieram
  como `S="bash ..."; $S ...`, fora do `allowed-tools`, com 8 recusas do guard
  de sessão isolada em worktree. As duas ganharam a seção `Gotchas`: caminho
  inteiro, script rodado de dentro do worktree, e a porta que o `warn pinned
  port` aponta, porque o Better Auth recusou o login do crm-next na porta 3003
  com 403 `Invalid origin`. O comando de dev leva cada variável das linhas
  `warn` apontada para a porta servida. As `description` separam a aba do
  Claude in Chrome (`dev-up`), o teste headless (`dev-up-agent-browser`) e o
  site público (`agent-browser`), e o eval de gatilho do `dev-up` ganha o
  negativo `/dev-up-agent-browser 3000`.
- `dev-up-agent-browser`: a pedido do user, o agente entra com usuário de seed
  cuja senha está num arquivo local do repo, preenchendo o campo de dentro do
  comando, sem o valor passar pelo transcript. Na `dev-up` o login continua
  com o user, porque as ferramentas da aba recebem o valor como parâmetro.
- `claude-md-prune`: a fase 3 ganha um segundo teste, "Claude gastaria muitas
  chamadas para redescobrir isto em toda sessão?". Ficam os comandos de
  verificação (teste, typecheck, lint, teste único) e o ponteiro de uma linha
  para onde algo mora quando o nome óbvio engana. A descoberta inclui
  `.claude/CLAUDE.md`, `.claude/rules/` e os arquivos de `@path`, e separa o que
  carrega no início da sessão do que carrega sob demanda. O escopo do projeto
  segue sem pergunta. A poda de memória virou seção própria. Saem a seção `Why
  this skill exists`, com três citações que a página best-practices não traz
  mais, a versão do `/doctor` e o aviso de compactação, porque o `SKILL.md`
  caiu de 13.953 para 11.915 bytes e cabe nos 5.000 tokens que voltam depois
  dela. O template do relatório foi para `references/report-template.md`. A
  contagem de linhas deixa de valer como prova do resultado. Eval de saída
  novo: `evals/fixture/` é um repo mínimo e `evals/prune-check.sh` confere que
  cada linha de `expected/keep.txt` sobrevive literal e nenhuma de
  `expected/cut.txt` fica.
- `claude-md-prune`: a descoberta cita a auto-memória por projeto em
  `~/.claude/projects/*/memory/`. Sai a seção `When to trigger`, que repetia a
  `description`, e a `description` nomeia o `claude-md-improver`.
- `humanize-pt-br`: sai a referência ao `verificador-factual`, agente que não
  existe. A lista de marcas que mais escapam ganha o comentário curto para rede
  social que reconta a fonte ou anuncia o gênero.

- Skill nova `nuvem`: manda a tarefa pesada a uma sessão do Claude Managed
  Agents, espera, baixa o patch e o traz para revisar e entregar aqui. O crédito
  mensal da API é teto: o script soma o gasto das sessões do mês e o teto das
  que ainda rodam, e recusa a sessão nova que não cabe no crédito e no limite do
  Console, ou quando não consegue ler o gasto. As notas de cada repo ficam em
  `~/.config/nuvem/`, fora da skill.
- `dev-up-agent-browser`: `browser PORT` não quebra mais quando nenhum
  navegador está configurado (sem `chrome-headless-shell` do Playwright e sem
  `AGENT_BROWSER_EXECUTABLE_PATH`). O `ab_env` desfaz a variável para a sessão
  cair no Chrome do agent-browser, e o `cmd_browser` lia ela sem default sob
  `set -u`, saindo com `unbound variable`. Ganhou uma checagem no eval.

- `dev-up-agent-browser`, atritos de uma validação com dois subagentes em
  paralelo: o `ab` desliga a checagem de versão do Chrome
  (`AGENT_BROWSER_NO_VERSION_CHECK=1`), que imprimia um aviso de CVE em todo
  launch e consultava o blog de releases do Google; o título com a porta volta
  depois de todo carregamento completo de página, não só do `open`; e a
  `interacting.md` manda esperar a navegação da SPA com `wait --url` antes do
  `get url`, que devolvia a URL antiga logo depois do clique.

- `dev-up` e `dev-up-agent-browser`: o watcher avisa cada queda do servidor.
  Antes, o laço de queda avisava `SERVER DOWN` uma vez e terminava, e o tail
  seguia vivo. Como o Restart só re-arma um watcher morto, uma segunda queda
  depois do Restart passava calada até o próximo prompt. Achado num statechart
  do fluxo e reproduzido no script.
- `dev-up-agent-browser`: um comando `ab` numa sessão que fechou por
  inatividade reabria o browser em `about:blank` e falhava com `Element not
  found`. Agora o `ab` reabre a sessão na raiz do app e avisa no stderr. O
  `show` e o `hide` perdiam o login feito numa janela que fechou por
  inatividade antes da troca. Agora eles leem o perfil da sessão fechada sem
  abrir janela (`DEV_UP_AB_NOWINDOW=1`) e levam o login para o outro modo.

- `dev-up-agent-browser`, skill nova: o `dev-up` com uma sessão do
  agent-browser por porta no lugar da aba do Claude in Chrome. Headless roda o
  `chrome-headless-shell` do Playwright, com 176 MB por sessão contra 350 MB do
  Brave e 7 a 10 ms por clique, medidos em 4 de novembro numa máquina de 16 GB.
  O script ganhou `ab` (toda chamada com as mesmas opções de launch, porque o
  agent-browser relança o browser quando duas chamadas divergem), `show` e
  `hide` (janela visível e volta, levando cookies e storage por `state save` e
  `state load`), `dash` (dashboard ao vivo) e `browser`. A janela leva a classe
  `agent-browser`; no Hyprland, uma regra com `no_initial_focus` e
  `focus_on_activate = false` manteve o foco parado em 174 amostras durante 20
  ações. O `dev-up` não muda.

- `dev-up` decide a porta sem perguntar. Processo alheio na porta pedida fica
  como está: a skill sobe na próxima porta livre e diz numa linha quem ocupa a
  pedida. No `Restart` com `via=other`, mesma regra, sem `stop --force`. O
  `preflight` ganhou a linha `warn served` quando a pasta já serve outra porta,
  e a skill passa a usar esse servidor, porque o Next 16 aceita um `next dev`
  por pasta. `owner` sai 0 com `mine=yes`, como já saía com `FREE`. Na
  auditoria de 21 de outubro foram 7 perguntas de porta e 2 servidores de outra
  sessão derrubados.

- `dev-up` ficou mais enxuto: as references caíram de 269 para 165 linhas.
  `browser-cache.md` e `coexistence.md` saíram, e as regras que valiam entraram
  no passo 4 do `SKILL.md`. O `navigate` avulso antes do primeiro
  `browser_batch` saiu, porque o batch já começa com `navigate`. Do
  `troubleshooting.md` saíram os itens repetidos do `SKILL.md` (porta fixa,
  login perdido ao trocar de porta, dependência faltando), e as references
  perderam travessões e negritos. O `dev-up.sh help` cortava o cabeçalho no
  meio da frase, e um comando desconhecido não listava o `unwatched`. Agora os
  dois imprimem o cabeçalho inteiro. A aba ganhou o prefixo `[PORTA]` no
  título, aplicado depois de cada `navigate` por um `MutationObserver` que o
  repõe quando o app troca o título numa rota SPA. Nenhuma tool renomeia o
  grupo: a extensão só usa o `displayName` do `session_scope`, que o CLI não
  manda. Um reload completo tira o prefixo até o próximo `navigate`.

- `humanize-pt-br` passou a rodar só quando o usuário digita `/humanize-pt-br`
  (`disable-model-invocation: true`). Das 142 chamadas em 141 sessões, 140
  vieram do agente, quase sempre antes de `gh pr create`. A skill ganhou
  `scripts/scan.py`, que acha travessão, meia-risca, seta e contraste de palco
  fora de código e de aspas, e avisa rótulo em negrito e Title Case, com teste em
  `evals/scan.test.sh`. O motor de 4 passos e o auto-score saíram (0 de 30
  sessões fizeram o score). No lugar das regras-mestras entrou a lista das 9
  marcas que escaparam em PRs. A não-fabricação passou a cobrir vivência,
  consequência inferida e troca de força. O registro técnico não recebe mais
  voz. O `evals/trigger-eval.json` saiu, porque a skill não dispara sozinha. Vem
  da retro de 30 sessões de 27/08 a 25/09.

- `dev-up` sobe o servidor como unidade `dev-up-PORT` do systemd do usuário,
  fora das tasks de background do Claude Code. O limite de tempo e a limpeza
  por pouca memória do Claude Code não derrubam mais o servidor. O `serve`
  passa o ambiente do shell para a unidade e retorna na hora; `--mem` vira o
  `MemoryMax` da unidade. O hook não pede mais rearme do watcher: imprime os
  erros do log desde o último prompt. O primeiro `browser_batch` começa com
  `navigate`, e um servidor com cwd apagado (worktree removido) cai sem
  pergunta, com PID e cwd no relatório. Vem da retro de 23/09 a 07/10.
  Servidores subidos pela versão anterior não estão numa unidade: aparecem
  como `via=other` e só caem com `stop PORT --force`, com o OK do user. O
  systemd-oomd ainda pode escolher a unidade sob pressão de memória, porque
  ela fica no `app.slice`; nesse caso ele mata o cgroup do servidor.

- `dev-up` ganhou `scripts/dev-up.sh`, que faz a parte mecânica: dono da porta
  pela árvore de processos, preflight de worktree, launch, espera pelo pid do
  servidor, filtro do watcher, `.state` por sessão e stop por SIGTERM. Um hook
  `UserPromptSubmit` da skill avisa quando o watcher morreu ou o servidor caiu.
  A skill ganhou a seção Restart, a sequência fixa da aba e regras para edição
  de código, browser remoto e porta fixa no `package.json`. O shutdown foi para
  `references/shutdown.md`, e o `SKILL.md` caiu de 346 para 180 linhas. Vem da
  retro de 30 sessões de 25/08 a 05/10.

- `dev-up` não desliga mais servidor, watcher e aba por conta própria ao fim
  de uma tarefa autônoma. Eles ficam de pé até o usuário pedir, também quando
  não há ninguém para responder, e o handback diz que ficaram rodando.

- `dev-up` não indica mais outra ferramenta de browser quando o `resize_window`
  falha. A largura exata se mede na própria aba, com um iframe de mesma origem.

- `dev-up` arma o Monitor com `timeout_ms: 1800000`, porque o `persistent`
  não existe no Claude Code 2.1.280 e todo Monitor expira em até 30 minutos.
  Expiração sem evento e sem prompt do usuário espera o próximo prompt para
  re-armar, e o gate do passo 5 aceita o retorno real do Monitor (issue #5).

- `mobile-up` ganhou suporte a dev client. Com `expo-dev-client` no app, os
  alvos `emulator`, `app` e `status` usam o development build no lugar do Expo
  Go: deep link `exp+<slug>`, guarda de emulador ocupado que lê o cliente em
  primeiro plano (Expo Go ou dev client) e falha rápida quando o APK instalado
  é release ou preview. Chaves novas no conf do projeto: `CLIENT`,
  `ANDROID_PACKAGE`, `EXPO_SLUG` e `AVD` (issue #3).

- README, seis correções de prosa. Abertura genérica, fórmula repetida "exists
  because", frase de sujeito duplo, tricolon do convite a fork, promessa sem
  ressalva sobre o Metro em `mobile-up`, cobertura de sintomas desatualizada em
  `mobile-up`.
- README, três links corrigidos. `othavio.com` removido por não resolver,
  `agent-bar` atualizado para `omarchy-agent-bar`, doc do `claude-in-chrome`
  apontada para a página certa da extensão.
- `.gitignore` ganhou a entrada `.DS_Store`.
- `dev-up` ganhou checagem de dono de processo antes de reusar porta ocupada,
  kill do shutdown condicionado a servidor iniciado nesta sessão e fallback
  para `lsof` quando `ss` não existe, entre outros ajustes de robustez e prosa.
- `mobile-up` ganhou `disable-model-invocation` no frontmatter, validação
  numérica de timeouts e portas, `10.0.2.2` para o alvo `emulator` e correção
  da comparação de versão do Expo Go, entre outros ajustes de robustez e prosa.
- `claude-md-prune` corrigiu a citação fabricada atribuída a Boris Cherny,
  removeu o percentual de adesão sem fonte e alinhou o template do relatório
  às categorias reais da Phase 3, entre outros ajustes.
- `humanize-pt-br` removeu o travessão dos próprios exemplos "Depois" e
  esclareceu a relação entre a exceção de amostra de autor e a regra do
  `unslop`, entre outros ajustes.

## Histórico

Retrospecto reconstruído do `git log`, sem data de release formal.

- Skill `dev-here` renomeada para `dev-up`, com endurecimento do fluxo de
  watcher e gate de Monitor.
- Skill `dev-up-setup`, redundante com `dev-up`, removida.
- Skill `code-review` de três eixos removida inteira.
- Skills reorganizadas em `skills/engineering/` e `skills/writing/`, repo
  renomeada de `othavi0/skills` para `othavi0/noctua-skills`.
- Skill `mobile-up` adicionada, cobrindo dev server, Metro e emulador Android
  para apps Expo.
- Skills `humanize-pt-br` e `claude-md-prune` adicionadas.
