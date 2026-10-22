# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Sem versionamento por tag ainda, este arquivo acompanha o `main`.

## [Unreleased]

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
