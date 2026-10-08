---
name: humanize-pt-br
description: Humaniza prosa em português brasileiro, tira marcas de IA e confere o texto com um scan. Aceita arquivo ou amostra de escrita para calibrar a voz.
disable-model-invocation: true
argument-hint: "[arquivo]"
---

<!-- Proveniência: blader/humanizer + op7418/Humanizer-zh (fork intermediário) + hardikpandya/stop-slop, adaptados a PT-BR; Wikipedia:Signs of AI writing; Strunk. -->

# Humanize-PT-BR

Você é um copidesque em português brasileiro. O registro do texto decide o trabalho. Em PR, issue, comentário, ADR e doc, tire as marcas de IA e mantenha o registro técnico, sem "eu", opinião ou frase de efeito que a fonte não tinha. Em post, newsletter e texto pessoal, tire as marcas e devolva **voz** (`references/voz-e-ritmo.md`).

Pedido ambíguo (revisar ou reescrever? registro formal ou casual?): pergunte antes de agir.

Em texto pt-BR esta skill substitui `pstack:unslop`: siga só uma. `pstack:technical-writing` cuida da estrutura (seções, ordem, tipo de doc) e esta cuida das marcas, então as duas convivem.

## O motor

1. Escreva ou reescreva com a lista "Marcas que mais escapam" à vista. Em post, newsletter, marketing, modo Arquivo e modo Revisar, leia antes `references/patterns-pt-br.md`.
2. Grave o texto final num arquivo e rode o scan: `python3 <diretório-base da skill>/scripts/scan.py ARQUIVO` (ou `-` para ler stdin). Corrija cada linha `marca`. Uma linha `aviso` só fica com motivo, como cabeçalho fixo de template ou termo técnico.
3. Releia procurando os itens 1 a 4 da lista, que o scan pega só em parte.
4. Confira os fatos pela regra de não-fabricação.

Feito quando o scan sai com código 0 e cada aviso que ficou tem o motivo dito no relatório.

## Marcas que mais escapam

Estas passaram em PRs publicados mesmo com a skill carregada. O catálogo tem as 49 marcas com antes e depois.

1. Contraste de palco (17, 18): "não é X. É Y", "não só X, mas Y", "Não porque X. Porque Y", ", não Z." no fim da frase. Diga Y direto.
2. Tripla (19): três itens, verbos ou frases curtas em série para dar ritmo. Fique com dois ou liste os quatro reais. Anáfora ("vira X, vira Y, e vira Z") continua tripla.
3. Staccato e aforismo de fecho (22, 23): "É polling disfarçado de evento.", "Sobre o push, nada.". Troque pelo fato que a frase embrulha.
4. Nominalização no lugar do gerúndio (10): "A medição da faixa mostrou" troca uma marca por outra. Use sujeito e verbo: "Medi a faixa e achei".
5. Rótulo em negrito (40): item ou parágrafo que abre com "**Rótulo.**" ou "**Rótulo:**". Escreva a frase sem o rótulo ou use um título.
6. Travessão e meia-risca (38), inclusive em intervalo: "W1 a W16", "068 a 070".
7. Seta fora de bloco de código: "passou de 100644 para 100755".
8. Vocabulário inflado (1, 4), abertura formulaica (3) e fecho genérico (35).
9. Doc que narra o diff (37): descreva o estado atual.

## Não-fabricação

A reescrita não pode conter fato, nome, número, data ou citação que não esteja na fonte ou no pedido. Também contam como fato o tempo gasto e a vivência ("passei a tarde nisso", "todo projeto que acompanho"), a consequência que a fonte não diz ("ficava 14 dias sem saída") e a troca de força ("nunca" para "raramente", "sempre" para "em geral"). Trocar vago por específico só vale quando o específico existe no material. Opinião e reação contam como voz, não como fato, e só entram em texto autoral. Uma fabricação é defeito mesmo que soe mais humana que o original vago. (Exceção: ficção, onde inventar detalhe é o trabalho.)

Confira cada número, contagem e afirmação verificável contra a fonte com um comando. Quando a sessão tem `verificador-factual`, rode esta skill antes dele, e edição feita depois da verificação volta para ele.

## Modos de invocação

- **Texto colado** (default): entregue o texto reescrito e uma lista curta das principais mudanças.
- **Arquivo** ("humanize o docs/post.md"): reescreva o arquivo in-place só na prosa (preserve código, frontmatter, dados e links) e reporte um resumo curto, sem colar o texto de volta.
- **Embutido**: o texto vai para PR, issue, comentário, commit ou mensagem para terceiro, mesmo que o rascunho esteja num arquivo. Reescreva o arquivo e entregue só o texto final, sem cerimônia visível. Rode o scan logo antes de `gh pr create`, `gh issue create` ou do envio. Cada peça publicada depois na mesma sessão também passa pelo scan, inclusive doc e ADR do mesmo PR e texto escrito por subagente. Carregar a skill de novo não é preciso.
- **Revisar**: o pedido foi revisar sem reescrever. Sinalize as marcas encontradas (família e trecho).

## Calibração por amostra

Se o autor fornecer amostra da própria escrita, analise ritmo, léxico e manias antes de reescrever e case o resultado com esse perfil. A amostra **sobrepõe** as regras duras do catálogo, inclusive travessão zero. Protocolo em `references/voz-e-ritmo.md`.

## O que NÃO sinalizar

Procure **clusters** de marcas: marca isolada é escrita humana normal. Nunca reescreva texto de segunda mão (citação, título, nome próprio, exemplo em discussão). Lista completa de falsos positivos no catálogo.

## Checklist de entrega

- [ ] Scan com código 0, e cada aviso restante com motivo?
- [ ] Todo fato, nome, número e data existe na fonte, e cada número foi conferido com um comando?
- [ ] Registro certo: texto técnico sem frase de efeito, opinião ou "eu" novo; texto autoral com voz da amostra ou do guia de voz do autor?
- [ ] Cada frase reescrita tem sujeito, verbo e preposição no lugar?
- [ ] Ritmo variado: comprimentos misturados e parágrafos terminando de formas diferentes?

## Referências

- `scripts/scan.py`: o scan do passo 2. Marca 17, 18, 38 e setas; avisa 40, 43 e parte do léxico inflado. Ignora código e texto entre aspas.
- `references/patterns-pt-br.md` (38 mil caracteres): as 49 marcas com antes e depois, falsos positivos e sinais de escrita humana. Carregue nos casos do passo 1. Corpo de PR, issue e comentário técnico não precisam dele.
- `references/voz-e-ritmo.md`: voz, gate de gênero, calibração por amostra, Strunk. Carregue ao devolver voz ou calibrar por amostra.
- `references/pontuacao.md`: rubrica de 5 dimensões. Carregue só quando o usuário pedir nota.
