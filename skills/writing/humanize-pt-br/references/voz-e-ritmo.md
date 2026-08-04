# Voz e ritmo: o lado positivo

Remover marcas é metade do trabalho. Texto limpo e sem **voz** continua parecendo IA. Este arquivo define o que adicionar, e quando não adicionar.

## Voz

Voz é a presença perceptível de uma pessoa no texto: opinião, escolha, aresta. Sinais de prosa sem voz:

- Todas as frases têm o mesmo comprimento e estrutura
- Sem opinião, só relato neutro
- Nunca admite incerteza ou complexidade
- Não usa primeira pessoa quando seria natural
- Sem humor, sem aresta, sem nada
- Lê como verbete de enciclopédia ou release corporativo

**Como adicionar voz:**

- **Tenha opinião.** Não só relate fatos: reaja a eles. "Honestamente, não sei o que pensar disso" é mais humano do que listar prós e contras.
- **Admita complexidade.** "Isso impressiona mas também incomoda" > "Isso impressiona".
- **Use "eu" quando couber.** Primeira pessoa não é falta de profissionalismo, é honestidade.
- **Permita alguma bagunça.** Estrutura perfeita parece algoritmo. Divagação, parêntese, ideia inacabada são marcas humanas.
- **Seja específico nos sentimentos.** Não "isso é preocupante", e sim "às três da manhã, com ninguém olhando, o agente continua rodando: isso incomoda".

**Antes (limpo mas sem voz):**
> O experimento gerou resultados interessantes. O agente produziu 3 milhões de linhas de código. Alguns desenvolvedores ficaram impressionados, outros céticos. As implicações ainda não estão claras.

**Depois (com voz):**
> Sinceramente não sei o que pensar. Três milhões de linhas de código, geradas enquanto a maioria dos humanos provavelmente estava dormindo. Metade da comunidade de devs surtou, a outra metade está explicando por que isso não conta. A verdade deve estar em algum lugar chato no meio, mas fico pensando nos agentes trabalhando madrugada adentro.

## Quando NÃO injetar voz (gate de gênero)

Voz pertence a texto que pede autor: blog, ensaio, opinião, post, newsletter, mensagem pessoal. Em texto enciclopédico, técnico, jurídico ou de referência, **neutro e plano É a voz humana correta**: empurrar "eu", opinião ou humor para um manual de API é tão artificial quanto o vocabulário inflacionado que este catálogo remove. Na dúvida, o registro do original manda.

## Calibração por amostra

Quando o autor fornece uma amostra da própria escrita, analise antes de reescrever:

1. **Ritmo**: comprimento médio de frase, variação, uso de pontuação (a pessoa usa ponto e vírgula? frases longas encadeadas? curtas e secas?)
2. **Léxico**: grau de formalidade, gírias, termos recorrentes, estrangeirismos que ela de fato usa
3. **Manias**: como abre parágrafos, conectivos favoritos, uso de parênteses, travessão, reticências

Case o resultado com esse perfil. **A amostra sobrepõe as regras duras do catálogo**, inclusive a de travessão zero: se o autor usa travessão na amostra, o texto humanizado pode usar na mesma frequência dele. O objetivo é soar como *aquela* pessoa, não como o "humano médio" do catálogo.

## Ritmo

- Misture comprimentos: frases curtas e diretas, seguidas de frases longas que precisam de tempo para se desenvolver.
- Termine parágrafos de formas diferentes: nem todo parágrafo fecha com síntese curta.
- Duplas batem triplas: dois itens soam escolhidos, três soam gerados.
- Deixe respirar: nem toda afirmação precisa de complemento na mesma frase.

## Strunk em PT-BR

Princípios de *The Elements of Style* que sustentam todo o resto:

- **Rule 10 (voz ativa).** Corte o "se" apassivador quando há agente. "Verificou-se que" → "Vimos que". Passiva tem uso legítimo quando o agente é desconhecido ou irrelevante.
- **Rule 11 (forma positiva).** Diga o que algo é, não o que não é. "Não muito frequente" → "raro". "Não diferente de" → "como".
- **Rule 12 (linguagem definida, específica, concreta).** Substitua adjetivo vago por dado. "Significativa melhora" → "37% mais rápido". "Vários anos" → "oito anos".
- **Rule 13 (omita palavras desnecessárias).** A regra mais importante. Releia cada frase perguntando o que sai sem perda.
- **Rule 16 (palavras relacionadas juntas).** A IA insere orações longas entre sujeito e verbo. "A empresa, fundada em 1994 pelos irmãos Silva durante a crise, anunciou…" → "A empresa anunciou… Foi fundada em 1994 pelos irmãos Silva."
- **Rule 18 (palavras enfáticas no final).** O fim da frase é posição de destaque; reescreva para o ponto importante cair lá, não enterrado no meio.
