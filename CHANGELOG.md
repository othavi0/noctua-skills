# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Sem versionamento por tag ainda, este arquivo acompanha o `main`.

## [Unreleased]

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
