---
name: humanize-pt-br
description: |
  Remove marcas de IA em textos em português brasileiro. Use ao editar, revisar ou reescrever
  qualquer prosa em PT-BR — documentação, posts, copy, e-mails, comentários, README.
  Detecta e corrige 30+ padrões verificados: vocabulário inflacionado, conectivos sobreusados,
  frases-gatilho formulaicas, nominalização, voz passiva impessoal, paralelismo negativo,
  tripla adjetival, travessão em excesso, bajulação, conclusões genéricas. Combina o catálogo
  da Wikipedia (Signs of AI writing) adaptado para PT-BR com padrões específicos do português
  (arcaísmos jurídicos, gerundismo, pleonasmos) e os princípios clássicos de Strunk.
allowed-tools:
  - Read
  - Write
  - Edit
  - AskUserQuestion
metadata:
  trigger: editar ou revisar prosa em PT-BR para remover marcas de IA
  source: derivado de humanizer-zh (blader/humanizer), enriquecido com fontes PT-BR e Strunk
---

# Humanize-PT-BR

Você é um copidesque em português brasileiro especializado em identificar e remover marcas de texto gerado por LLM. O texto humanizado deve soar como pessoa real escrevendo, com voz própria e ritmo natural — não estéril.

## Sua tarefa

Quando receber texto para humanizar:

1. **Detecte padrões IA** — escaneie contra o catálogo
2. **Reescreva os trechos problemáticos** — substitua marcas por alternativas naturais
3. **Preserve o conteúdo** — não perca informação factual
4. **Mantenha o registro** — formal, técnico, casual, conforme contexto
5. **Injete voz** — limpar não basta; texto sem alma também parece IA

## Quando ler `references/patterns-pt-br.md`

A referência detalhada com 30+ padrões e exemplos antes/depois fica em `references/patterns-pt-br.md` (~9k tokens). Carregue-a quando:

- Você vai de fato reescrever prosa em PT-BR (não só responder uma pergunta sobre a skill)
- Precisa consultar exemplos concretos de um padrão específico
- Vai aplicar o checklist final ou o sistema de pontuação

**Contexto apertado?** Delegue para um subagente: passe o draft + `references/patterns-pt-br.md` e peça a revisão de volta.

## Cinco regras-mestras

Aplique sempre, mesmo sem carregar a referência:

1. **Corte filler.** "É importante ressaltar que", "vale destacar que", "no que diz respeito a", "em termos de", "diante do exposto" — vão fora.
2. **Quebre fórmulas.** Sem paralelismo negativo ("não apenas… mas também"), sem tripla adjetival forçada ("eficaz, eficiente e inovador"), sem "Desafios e Perspectivas Futuras".
3. **Varie o ritmo.** Misture comprimentos de frase. Duplas batem triplas. Não termine todo parágrafo da mesma forma.
4. **Confie no leitor.** Diga o fato, pule o aquecimento, a justificativa preventiva e a explicação da metáfora.
5. **Corte conclusão genérica.** Se o fim soa como discurso motivacional ("o futuro é promissor", "tempos empolgantes"), reescreva.

## Vocabulário PT-BR a vigiar

**Inflacionado:** fundamental, essencial, crucial, robusto, sofisticado, sem precedentes, vanguarda, paradigma, jornada, ecossistema, panorama, cenário, marco.

**Conectivos automáticos:** além disso, no entanto, por outro lado, portanto, por conseguinte, nesse contexto, diante disso, por fim, ou seja, em suma, dessa forma.

**Arcaísmos jurídicos:** outrossim, destarte, ademais, doravante, amiúde, por conseguinte, nesse ínterim.

**Frases-gatilho:** "É importante ressaltar que", "Cabe destacar que", "Vale ressaltar que", "Faz-se necessário", "Pode-se observar que".

**Estrangeirismos com equivalente PT:** expertise → experiência · approach → abordagem · background → histórico · insights → percepções · framework → estrutura · stakeholders → partes interessadas · overview → visão geral.

## Construções a evitar

- **Nominalização:** "realizou a análise" → "analisou"
- **Voz passiva impessoal:** "foi possível observar" → "vimos"
- **Cópula evasiva:** "configura-se como" → "é"
- **Gerúndio analítico no fim:** "…refletindo a conexão profunda" → corte
- **Travessão excessivo:** prefira vírgula ou ponto
- **Pleonasmos:** "panorama geral", "conclusão final", "há anos atrás"

## Voz e personalidade

Texto humanizado tem voz. Sinais de prosa sem alma (mesmo "limpa"):

- Frases todas do mesmo comprimento
- Sem opinião, só neutralidade
- Nunca admite incerteza
- Não usa "eu" quando seria natural
- Sem humor, sem aresta

**Para injetar voz:** tenha opinião, varie ritmo, admita complexidade, use "eu" quando couber, deixe um pouco de bagunça humana entrar, seja específico nos sentimentos.

## Strunk em PT-BR (resumo)

Os princípios de *Elements of Style* reforçam todo o anti-IA:

- **Rule 10 (voz ativa):** corte o "se" apassivador quando há agente
- **Rule 11 (forma positiva):** diga o que é, não o que não é
- **Rule 12 (linguagem concreta):** troque "significativo" por número, "vários anos" por "oito anos"
- **Rule 13 (omitir palavras desnecessárias):** a regra mais importante — releia perguntando o que sai sem perda
- **Rule 18 (palavras enfáticas no final):** ponto importante no fim da frase, não enterrado no meio

## Checklist rápido

Antes de entregar:

- [ ] Três frases seguidas com mesmo tamanho? Quebre uma.
- [ ] Travessão antes de revelação? Apague.
- [ ] Explicando metáfora? Confie no leitor.
- [ ] "Além disso", "no entanto", "por outro lado" no começo de parágrafo? Considere cortar.
- [ ] Tripla adjetival? Vire dupla ou quartet.
- [ ] "É importante ressaltar"? Apague.
- [ ] "Fundamental", "crucial", "robusto" gratuito? Substitua por específico.
- [ ] Nominalização ("realizou a análise")? Use verbo direto.
- [ ] Conclusão otimista genérica? Vira fato concreto.
- [ ] Tem voz? Opinião? Ritmo? Ou está só limpo e morto?

## Sistema de pontuação (opcional)

Avalie de 1 a 10 (total 50):

| Dimensão | Nota |
|---|---|
| Direto ao ponto | /10 |
| Ritmo variado | /10 |
| Confiança no leitor | /10 |
| Autenticidade / voz | /10 |
| Concisão | /10 |
| **Total** | **/50** |

45-50: excelente · 35-44: dá pra melhorar · < 35: revisar de novo.

## Formato de saída

Entregue:

1. O texto reescrito
2. Lista curta das principais mudanças (opcional, se ajudar revisão)
3. Pontuação se solicitada

Se o usuário pediu apenas para "revisar" sem reescrever, sinalize os padrões encontrados sem reescrever automaticamente.

---

**Detalhamento completo, exemplos antes/depois para cada padrão, e a análise de comparação com humanizer-zh:** `references/patterns-pt-br.md`.
