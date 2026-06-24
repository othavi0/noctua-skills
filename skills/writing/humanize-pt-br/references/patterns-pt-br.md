# Padrões de IA em Português Brasileiro — Referência Detalhada

Catálogo de padrões linguísticos que delatam texto gerado por LLM em PT-BR, com exemplos antes/depois. Carregue este arquivo apenas quando for editar prosa em PT-BR — ele consome ~9k tokens.

Base: adaptação de [blader/humanizer](https://github.com/blader/humanizer) e [Wikipedia:Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing), enriquecida com padrões específicos de PT-BR documentados em fontes brasileiras (Gazeta do Povo, Envox, Hastewire, Advoco Brasil, Humanizar Textos), e princípios de Strunk (*Elements of Style*).

---

## Índice

**Vocabulário e léxico**
1. Vocabulário inflacionado de importância
2. Conectivos formais sobreusados
3. Frases-gatilho de abertura formulaica
4. Vocabulário etéreo corporativo
5. Arcaísmos jurídicos fora de contexto
6. Estrangeirismos desnecessários

**Gramática e sintaxe**
7. Nominalização excessiva
8. Voz passiva sintética impessoal
9. Cópula evasiva (evitar "ser/estar")
10. Gerúndio expletivo de análise rasa
11. Paralelismo negativo ("não apenas… mas também")
12. Tripla adjetival forçada
13. Falsa amplitude ("de X a Y")
14. Sinônimos forçados (rotação léxica)
15. Hedging excessivo (sobre-modalização)
16. Pleonasmos canônicos

**Conteúdo e estrutura**
17. Exagero de significado e "tendências mais amplas"
18. Ênfase em notoriedade/cobertura midiática
19. Linguagem publicitária / "folder de turismo"
20. Atribuição vaga ("especialistas afirmam")
21. Seção "Desafios e Perspectivas Futuras"
22. Conclusão genérica positiva
23. Filler phrases e perífrases

**Estilo visual**
24. Travessão em excesso
25. Negrito decorativo
26. Listas com cabeçalho em negrito (inline header lists)
27. Emojis decorativos

**Traços de conversa**
28. Bajulação e tom servil
29. Marcas de chatbot ("Espero que ajude!")
30. Disclaimers de cutoff de conhecimento

**Princípios Strunk aplicáveis ao PT-BR**

---

## Vocabulário e léxico

### 1. Vocabulário inflacionado de importância

**Palavras-bandeira (alta frequência em IA):** fundamental, essencial, crucial, vital, primordial, robusto, sofisticado, significativo, inovador, sem precedentes, vanguarda, fascinante, incrível, marco, paradigma.

**Problema:** A IA superestima a importância de qualquer assunto inflando adjetivos. Em texto humano, palavras como "fundamental" são raras — quando aparecem, têm peso real.

**Antes:**
> Esta solução robusta e inovadora representa um marco fundamental no cenário tecnológico contemporâneo, oferecendo uma abordagem sofisticada para desafios sem precedentes.

**Depois:**
> A ferramenta resolve dois problemas que existiam há anos: latência alta em queries paginadas e falta de retry automático.

---

### 2. Conectivos formais sobreusados

**Listar de conectivos suspeitos:** "além disso", "no entanto", "por outro lado", "portanto", "por conseguinte", "ou seja", "nesse contexto", "diante disso", "assim sendo", "por fim", "em suma", "em síntese", "dessa forma", "desse modo".

**Problema:** A IA conecta tudo mecanicamente. Texto humano usa conectores com parcimônia, ou solta frases sem ponte. Múltiplos parágrafos começando com "Além disso," / "Por outro lado," / "Por fim," é assinatura de IA.

**Antes:**
> O time aprovou a proposta. Além disso, definiu prazos. Por outro lado, alguns membros tinham dúvidas. Por fim, decidiu-se prosseguir.

**Depois:**
> O time aprovou a proposta e definiu prazos. Alguns membros ainda tinham dúvidas, mas o grupo decidiu prosseguir.

**Quando manter o conectivo:** quando há contraste real ou consequência lógica não óbvia. "No entanto" só vale se há tensão genuína entre as frases.

---

### 3. Frases-gatilho de abertura formulaica

**Listar:** "É importante ressaltar que…", "É importante destacar que…", "Cabe destacar que…", "Vale ressaltar que…", "Faz-se necessário…", "É fundamental compreender que…", "Convém mencionar que…".

**Problema:** Atrasam a frase principal. Em PT-BR formal, viraram clichê instantâneo de IA.

**Antes:**
> É importante ressaltar que o índice caiu 12% no último trimestre.

**Depois:**
> O índice caiu 12% no último trimestre.

---

### 4. Vocabulário etéreo corporativo

**Listar:** "ecossistema", "paradigma", "jornada", "universo", "panorama", "cenário", "essência", "DNA da marca", "framework", "narrativa", "verticalização", "disrupção".

**Problema:** Soam importantes, mas são semanticamente vagos. Quando aparecem em texto técnico ou jornalístico, quase sempre são IA ou marketing genérico.

**Antes:**
> No ecossistema atual de soluções digitais, navegamos uma jornada de transformação que redefine o paradigma do consumidor.

**Depois:**
> Mais empresas estão comprando software por assinatura, e os clientes esperam updates frequentes.

---

### 5. Arcaísmos jurídicos fora de contexto

**Listar:** "outrossim", "destarte", "ademais", "doravante", "amiúde", "destarte", "por conseguinte", "nesse ínterim", "no afã de", "no diapasão".

**Problema:** A IA importa léxico de petições jurídicas para contextos casuais. Em texto informal ou técnico moderno, esses arcaísmos são sinal forte de geração automática.

**Antes:**
> O projeto será lançado em março. Outrossim, a equipe trabalhará em melhorias contínuas. Destarte, espera-se um produto maduro.

**Depois:**
> O projeto será lançado em março. A equipe continua iterando depois.

---

### 6. Estrangeirismos desnecessários

| IA usa | PT-BR preferível |
|---|---|
| expertise | experiência, conhecimento |
| approach | abordagem, caminho |
| background | histórico, formação |
| insights | percepções, descobertas |
| framework | estrutura, modelo |
| stakeholders | partes interessadas, envolvidos |
| deliverables | entregas |
| benchmark | referência, parâmetro |
| overview | visão geral, panorama |
| timeline | cronograma, prazo |

**Problema:** A IA mantém anglicismos quando o equivalente PT-BR é claro e mais natural.

**Exceções legítimas:** termos técnicos consagrados na área (ex: "deploy", "commit", "merge" no contexto de software).

---

## Gramática e sintaxe

### 7. Nominalização excessiva

**Padrão:** transformar verbos em substantivos derivados + verbo-suporte vazio.

| IA (nominalizado) | Humano (verbo direto) |
|---|---|
| realizou a análise | analisou |
| procedeu à verificação | verificou |
| efetuou a implementação | implementou |
| fez a utilização | usou |
| promoveu a integração | integrou |
| levou a cabo a execução | executou |
| deu início ao desenvolvimento | começou a desenvolver |

**Antes:**
> A equipe procedeu à realização da análise dos resultados, com vistas à identificação de gargalos.

**Depois:**
> A equipe analisou os resultados para identificar gargalos.

---

### 8. Voz passiva sintética impessoal

**Listar:** "foi possível observar", "foi identificado", "verificou-se", "constatou-se", "pode-se afirmar", "pode-se concluir", "observou-se que".

**Problema:** Remove o agente, cria distância artificial. Em texto humano, dizemos "vimos", "encontramos", "concluímos".

**Antes:**
> Foi possível observar que pode-se afirmar que verificou-se uma melhora.

**Depois:**
> Os números melhoraram.

**Strunk Rule 10:** prefira voz ativa. Em PT-BR isso significa cortar o "se" apassivador sempre que houver agente real.

---

### 9. Cópula evasiva

**Padrão:** substituir "ser/estar" por estruturas mais longas.

| IA | Humano |
|---|---|
| funciona como | é |
| representa um marco | é um marco |
| configura-se como | é |
| caracteriza-se por ser | é |
| constitui-se em | é |
| serve como | é |

**Antes:**
> A nova lei configura-se como um instrumento que serve como mecanismo de regulação.

**Depois:**
> A nova lei regula o setor.

---

### 10. Gerúndio expletivo de análise rasa

**Padrão:** terminar frases com gerúndio para criar falsa profundidade.

**Verbos suspeitos no final:** destacando, evidenciando, demonstrando, refletindo, simbolizando, garantindo, fomentando, promovendo, contribuindo para, ressaltando, sublinhando.

**Problema:** Esses gerúndios não adicionam informação — só estendem a frase com aparência de análise.

**Antes:**
> O templo usa tons azuis, verdes e dourados, ressoando com a beleza natural da região, simbolizando a flora local e refletindo a conexão profunda da comunidade com a terra.

**Depois:**
> O templo usa azul, verde e dourado. O arquiteto disse que as cores remetem às flores nativas e ao mar.

---

### 11. Paralelismo negativo

**Padrão:** "não apenas X, mas também Y" / "não é só X, é Y" / "mais do que X, é Y".

**Antes:**
> Não se trata apenas de uma atualização, mas sim de uma revolução no modo como pensamos produtividade.

**Depois:**
> A atualização adiciona atalhos de teclado e modo offline.

**Quando manter:** em contexto retórico real (discurso, opinião explícita). Em descrição factual, sempre corte.

---

### 12. Tripla adjetival forçada

**Padrão:** três adjetivos/itens em sequência para criar ritmo aparente.

**Antes:**
> Uma solução eficaz, eficiente e inovadora, oferecendo uma experiência fluida, intuitiva e poderosa.

**Depois:**
> A solução é rápida e os usuários acharam fácil de usar.

**Regra prática:** se a tripla é gratuita, deixe dois itens ou quatro. Triplas só funcionam quando os três itens são distintos e necessários.

---

### 13. Falsa amplitude ("de X a Y")

**Padrão:** "desde X até Y", "de X a Y" — onde X e Y não estão numa escala real.

**Antes:**
> Nossa plataforma cobre desde startups iniciantes até multinacionais consolidadas, da inteligência artificial às soluções tradicionais.

**Depois:**
> A plataforma atende startups e grandes empresas, com módulos de IA e ferramentas convencionais.

---

### 14. Sinônimos forçados (rotação léxica)

**Padrão:** trocar de palavra a cada menção para "evitar repetição", mesmo quando a repetição seria natural.

**Antes:**
> O protagonista enfrenta desafios. O personagem principal supera obstáculos. A figura central vence as adversidades. O herói retorna ao lar.

**Depois:**
> O protagonista enfrenta vários desafios, vence e volta pra casa.

**Strunk Rule 12:** prefira termos definidos, específicos. Repetir o substantivo correto é melhor do que rotacionar sinônimos para parecer variado.

---

### 15. Hedging excessivo (sobre-modalização)

**Padrão:** empilhar marcadores de incerteza.

**Antes:**
> Pode-se potencialmente considerar que talvez essa política possa eventualmente ter algum impacto nos resultados.

**Depois:**
> A política talvez afete os resultados.

**Strunk Rule 11:** ponha afirmações em forma positiva. Hedge só quando há incerteza real, não como tique.

---

### 16. Pleonasmos canônicos

| Pleonasmo | Versão limpa |
|---|---|
| panorama geral | panorama |
| conclusão final | conclusão |
| protagonista principal | protagonista |
| consenso geral | consenso |
| certeza absoluta | certeza |
| pequenos detalhes | detalhes |
| novidade inédita | novidade |
| planejar antecipadamente | planejar |
| na minha opinião pessoal | na minha opinião |
| elo de ligação | elo |
| há anos atrás | há anos / anos atrás |
| subir para cima | subir |

---

## Conteúdo e estrutura

### 17. Exagero de significado e "tendências mais amplas"

**Padrão:** afirmar que qualquer evento representa, simboliza, marca, ou contribui para uma tendência maior.

**Listar:** "marca um ponto de inflexão", "representa uma virada", "deixa uma marca duradoura", "reflete uma tendência mais ampla", "lança as bases para", "molda o futuro de", "no panorama em evolução de".

**Antes:**
> O Instituto de Estatística da Catalunha foi criado em 1989, marcando um ponto de inflexão na evolução da estatística regional na Espanha e refletindo um movimento mais amplo de descentralização administrativa.

**Depois:**
> O Instituto de Estatística da Catalunha foi criado em 1989 para coletar e publicar dados regionais separadamente do instituto nacional.

---

### 18. Ênfase em notoriedade/cobertura midiática

**Padrão:** listar veículos onde a pessoa foi citada, ou seguidores em redes sociais, sem contexto.

**Antes:**
> Suas opiniões foram citadas pelo Estado, Folha, BBC Brasil e G1. Tem presença ativa nas redes sociais com mais de 500 mil seguidores.

**Depois:**
> Em entrevista à Folha em 2024, defendeu que a regulação de IA deve focar em resultados, não em métodos.

---

### 19. Linguagem publicitária / "folder de turismo"

**Listar:** "vibrante", "pitoresco", "deslumbrante", "rica herança cultural", "imperdível", "cativante", "berço de", "no coração de", "aninhado em", "deslumbrante beleza natural", "encantador".

**Problema:** A IA falha em manter neutralidade descritiva, especialmente em verbetes geográficos e culturais.

**Antes:**
> Aninhado no coração da deslumbrante região serrana, Petrópolis é uma cidade vibrante com uma rica herança cultural e uma beleza natural cativante.

**Depois:**
> Petrópolis fica na região serrana do Rio de Janeiro, conhecida pelo Museu Imperial e pelo clima ameno.

---

### 20. Atribuição vaga

**Padrão:** "especialistas afirmam", "analistas indicam", "estudos apontam", "observadores apontam", "alguns críticos argumentam", "relatórios da indústria mostram" — sem citar fonte específica.

**Antes:**
> Estudos apontam que a IA terá um papel crucial nos próximos anos. Especialistas concordam que essa é uma transformação sem precedentes.

**Depois:**
> Um relatório do Gartner de 2024 estima que 75% das empresas vão usar IA generativa em produção até 2026.

---

### 21. Seção "Desafios e Perspectivas Futuras"

**Padrão:** seção formulaica com obstáculos genéricos seguida de otimismo vago.

**Antes:**
> Apesar de seu crescimento industrial, Korattur enfrenta desafios típicos de áreas urbanas, incluindo congestionamento e escassez de água. No entanto, com sua localização estratégica e iniciativas em andamento, Korattur continua a prosperar como parte integral do crescimento de Chennai.

**Depois:**
> O congestionamento piorou em 2015 quando três parques industriais abriram. A prefeitura iniciou um projeto de drenagem em 2022 para resolver enchentes recorrentes.

---

### 22. Conclusão genérica positiva

**Listar:** "o futuro é promissor", "tempos empolgantes estão por vir", "fica claro que", "diante do exposto", "em suma, os benefícios são inúmeros", "abrindo caminho para um futuro melhor".

**Antes:**
> O futuro da empresa parece promissor. Tempos empolgantes virão e ela continua sua jornada de excelência. Diante do exposto, fica claro que este é um passo na direção certa.

**Depois:**
> A empresa planeja abrir duas lojas no ano que vem.

---

### 23. Filler phrases e perífrases

| Filler IA | Versão limpa |
|---|---|
| para que se possa atingir esse objetivo | para isso |
| devido ao fato de | porque |
| nesse momento exato | agora |
| caso seja necessário | se precisar |
| o sistema tem a capacidade de processar | o sistema processa |
| vale notar que os dados mostram | os dados mostram |
| no que diz respeito a | sobre |
| em termos de | em / sobre |
| com o intuito de | para |
| no sentido de | para |

---

## Estilo visual

### 24. Travessão em excesso

**Problema:** A IA usa travessão (—) com frequência muito acima da humana. Em texto formal PT-BR, vírgula ou ponto resolvem na maioria dos casos.

**Antes:**
> Este termo é promovido pelas instituições — não pelo povo. Não se diz "Holanda, Europa" como endereço — mas o erro continua — mesmo em documentos oficiais.

**Depois:**
> Este termo é promovido pelas instituições, não pelo povo. Não se diz "Holanda, Europa" como endereço, mas o erro continua mesmo em documentos oficiais.

---

### 25. Negrito decorativo

**Problema:** A IA enfatiza palavras em negrito mecanicamente, sem hierarquia de importância.

**Antes:**
> A solução combina **OKR (Objetivos e Resultados-Chave)**, **KPIs (Indicadores-Chave de Desempenho)** e ferramentas como **BMC (Business Model Canvas)** e **BSC (Balanced Scorecard)**.

**Depois:**
> A solução combina OKRs, KPIs, Business Model Canvas e Balanced Scorecard.

**Regra:** negrito só para o que realmente precisa de destaque. Mais de 2-3 negritos por parágrafo já é demais.

---

### 26. Listas com cabeçalho em negrito (inline header lists)

**Padrão:** lista onde cada item começa com substantivo em negrito + dois-pontos + frase que repete o substantivo.

**Antes:**
> - **Experiência do usuário:** A experiência do usuário melhorou com a nova interface.
> - **Desempenho:** O desempenho foi aprimorado por algoritmos otimizados.
> - **Segurança:** A segurança foi reforçada por criptografia ponta a ponta.

**Depois:**
> A atualização trouxe nova interface, carregamento mais rápido e criptografia ponta a ponta.

---

### 27. Emojis decorativos

**Padrão:** emojis no início de tópicos ou cabeçalhos, especialmente 🚀, 💡, ✅, 🎯, 📊, 🔥.

**Antes:**
> 🚀 **Lançamento:** O produto sai no Q3
> 💡 **Insight:** Usuários preferem simplicidade
> ✅ **Próximo passo:** Marcar follow-up

**Depois:**
> O produto sai no Q3. A pesquisa com usuários mostrou preferência por simplicidade. Próximo passo: marcar follow-up.

**Exceção:** o usuário pediu emojis explicitamente.

---

## Traços de conversa

### 28. Bajulação e tom servil

**Listar:** "Excelente pergunta!", "Certamente!", "Com toda certeza!", "Você está absolutamente certo!", "Que ótima observação!".

**Antes:**
> Excelente pergunta! Você está absolutamente certo de que esse é um tema complexo. Sobre os fatores econômicos, é uma ótima observação.

**Depois:**
> Os fatores econômicos que você mencionou são relevantes aqui.

---

### 29. Marcas de chatbot

**Listar:** "Espero que isso ajude!", "Claro!", "Com certeza!", "Aqui está…", "Se quiser que eu explique mais alguma coisa, é só pedir!", "Posso elaborar mais se precisar."

**Antes:**
> Aqui está um resumo sobre a Revolução Francesa. Espero que isso ajude! Se quiser que eu expanda alguma parte, é só pedir.

**Depois:**
> A Revolução Francesa começou em 1789, quando a crise fiscal e a escassez de comida geraram revolta generalizada.

---

### 30. Disclaimers de cutoff de conhecimento

**Listar:** "Até a data do meu último treinamento…", "Com base nas informações disponíveis…", "Embora detalhes específicos sejam limitados…", "Conforme os dados aos quais tenho acesso…".

**Antes:**
> Embora detalhes específicos sobre a fundação da empresa não estejam amplamente documentados nas fontes prontamente disponíveis, parece ter sido fundada em algum momento dos anos 1990.

**Depois:**
> Segundo o registro na Junta Comercial, a empresa foi fundada em 1994.

---

## Princípios Strunk aplicáveis ao PT-BR

Sintetizados de *The Elements of Style* — todos reforçam o anti-IA:

### Strunk Rule 10 — Use voz ativa

Em PT-BR: corte o "se" apassivador quando há agente. "Verificou-se que" → "Vimos que". Voz passiva tem usos legítimos (quando o agente é desconhecido ou irrelevante), mas a IA usa em excesso.

### Strunk Rule 11 — Forma positiva

Diga o que algo é, não o que não é. "Não muito frequente" → "raro". "Não diferente de" → "como".

### Strunk Rule 12 — Linguagem definida, específica, concreta

Substitua adjetivos vagos por dados. "Significativa melhora" → "37% mais rápido". "Vários anos" → "oito anos". A IA gravita para o genérico — sempre busque o específico.

### Strunk Rule 13 — Omita palavras desnecessárias

A regra mais importante. "O sistema tem a capacidade de processar" → "o sistema processa". "Em virtude do fato de que" → "porque". Releia cada frase perguntando o que pode sair sem perda.

### Strunk Rule 16 — Mantenha palavras relacionadas juntas

A IA insere orações longas entre sujeito e verbo. "A empresa, fundada em 1994 pelos irmãos Silva durante a crise econômica que afetava o setor industrial, anunciou…" → "A empresa anunciou… Ela foi fundada em 1994 pelos irmãos Silva."

### Strunk Rule 18 — Palavras enfáticas no final

O fim da frase é posição de destaque. A IA enterra a informação importante no meio com gerúndios e perífrases. Reescreva para o ponto cair no fim.

---

## Personalidade e voz — não basta limpar

Remover padrões de IA é metade do trabalho. Texto estéril e sem voz parece IA também. Sinais de prosa sem alma:

- Todas as frases têm o mesmo comprimento e estrutura
- Sem opinião, só relato neutro
- Nunca admite incerteza ou complexidade
- Não usa primeira pessoa quando seria natural
- Sem humor, sem aresta, sem nada
- Lê como verbete de Wikipedia ou release corporativo

**Como adicionar voz:**

- **Tenha opinião.** Não só relate fatos — reaja a eles. "Honestamente, não sei o que pensar disso" é mais humano do que listar prós e contras.
- **Varie o ritmo.** Frases curtas e diretas. Seguidas de frases longas, que precisam de tempo para se desenvolver. Mistura é tudo.
- **Admita complexidade.** "Isso impressiona mas também incomoda" > "Isso impressiona".
- **Use "eu" quando couber.** Primeira pessoa não é falta de profissionalismo — é honestidade.
- **Permita alguma bagunça.** Estrutura perfeita parece algoritmo. Divagação, parêntese, ideia inacabada são marcas humanas.
- **Seja específico nos sentimentos.** Não "isso é preocupante", e sim "às três da manhã, com ninguém olhando, o agente continua rodando — isso incomoda".

**Antes (limpo mas sem alma):**
> O experimento gerou resultados interessantes. O agente produziu 3 milhões de linhas de código. Alguns desenvolvedores ficaram impressionados, outros céticos. As implicações ainda não estão claras.

**Depois (com voz):**
> Sinceramente não sei o que pensar. Três milhões de linhas de código, geradas enquanto a maioria dos humanos provavelmente estava dormindo. Metade da comunidade de devs surtou, a outra metade está explicando por que isso não conta. A verdade deve estar em algum lugar chato no meio — mas fico pensando nos agentes trabalhando madrugada adentro.

---

## Checklist final

Antes de entregar o texto:

- [ ] Três frases seguidas com mesmo comprimento? Quebre uma.
- [ ] Parágrafo termina com linha curta resumindo? Varie.
- [ ] Travessão antes de revelação? Apague.
- [ ] Explicando metáfora ou analogia? Confie no leitor.
- [ ] Usou "além disso", "no entanto", "por outro lado"? Considere cortar.
- [ ] Tripla adjetival? Troque por dois ou quatro itens.
- [ ] Algum "é importante ressaltar" / "vale destacar"? Apague.
- [ ] Algum "fundamental", "crucial", "robusto" gratuito? Substitua por específico ou corte.
- [ ] Nominalização ("realizou a análise")? Use o verbo direto.
- [ ] Voz passiva sem agente óbvio? Reescreva ativo.
- [ ] Conclusão genérica otimista? Substitua por fato concreto.
- [ ] Tem voz? Opinião? Ritmo variado? Ou está só limpo e morto?

---

## Sistema de pontuação

Avalie de 1 a 10 em cada dimensão (total 50):

| Dimensão | O que avaliar | Nota |
|---|---|---|
| **Direto ao ponto** | Vai direto ou faz cerimônia? 10 = direto, 1 = perífrase pesada | /10 |
| **Ritmo** | Comprimentos variam? 10 = mistura natural, 1 = monótono | /10 |
| **Confiança no leitor** | Respeita inteligência? 10 = enxuto, 1 = sobreexplica | /10 |
| **Autenticidade** | Soa como pessoa? 10 = humano, 1 = template | /10 |
| **Concisão** | Sobra o que cortar? 10 = nada de gordura, 1 = cheio | /10 |
| **Total** | | **/50** |

**Faixas:**
- 45-50: excelente, livre de marcas IA
- 35-44: bom, ainda dá pra melhorar
- < 35: precisa de outra revisão

---

## Exemplo completo

**Antes (com marcas de IA):**
> A nova atualização do software configura-se como uma prova do compromisso da empresa com a inovação. Além disso, ela oferece uma experiência fluida, intuitiva e robusta — garantindo que os usuários possam atingir seus objetivos com eficiência. Não se trata apenas de uma atualização, mas sim de uma revolução no modo como pensamos a produtividade. Especialistas do setor afirmam que isso terá um impacto duradouro em todo o segmento, ressaltando o papel fundamental da empresa no cenário tecnológico em evolução.

**Depois (humanizado):**
> A atualização adiciona processamento em lote, atalhos de teclado e modo offline. Os testers iniciais relataram fechar tarefas mais rápido — a maioria citou os atalhos como o maior ganho.

**Mudanças:**
- Removeu "configura-se como uma prova" (cópula evasiva + exagero de significado)
- Removeu "Além disso" (conectivo automático)
- Removeu "fluida, intuitiva e robusta" (tripla adjetival + publicidade)
- Removeu travessão antes do gerúndio analítico
- Removeu "Não se trata apenas… mas sim…" (paralelismo negativo)
- Removeu "especialistas afirmam" (atribuição vaga)
- Removeu "papel fundamental no cenário em evolução" (vocabulário etéreo)
- Substituiu por features concretas + reação específica dos testers

---

## Referências

- [Wikipedia:Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing)
- [blader/humanizer](https://github.com/blader/humanizer)
- [Strunk — The Elements of Style](../../skills/writing-clearly-and-concisely/elements-of-style.md)
- Gazeta do Povo — Clichês de IA em textos de políticos brasileiros
- Envox — Os maiores vícios de linguagem de IA em 2026
- Hastewire — Como identificar texto de IA em português
- Advoco Brasil — 7 sinais que entregam texto gerado por IA
- Humanizar Textos — Lista de palavras e frases mais comuns do ChatGPT
- Norma Culta — Lista de pleonasmos mais comuns
