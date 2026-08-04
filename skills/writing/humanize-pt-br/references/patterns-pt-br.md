# Marcas de IA em português brasileiro: catálogo de detecção

Catálogo das marcas linguísticas que delatam texto gerado por LLM em PT-BR, com exemplos antes/depois. Carregue este arquivo quando for editar prosa em PT-BR: ele consome ~13k tokens.

Fontes: [blader/humanizer](https://github.com/blader/humanizer) (via fork [op7418/Humanizer-zh](https://github.com/op7418/Humanizer-zh)), [hardikpandya/stop-slop](https://github.com/hardikpandya/stop-slop), [Wikipedia:Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing), adaptados a PT-BR e enriquecidos com fontes brasileiras (lista completa no fim).

---

## Índice

**Vocabulário e léxico**
1. Vocabulário inflacionado de importância
2. Conectivos formais sobreusados
3. Frases-gatilho de abertura formulaica
4. Vocabulário etéreo corporativo
5. Arcaísmos jurídicos fora de contexto
6. Estrangeirismos desnecessários
7. Jargão corporativo nativo
8. Advérbios de intensidade em excesso
9. Extremos preguiçosos ("sempre", "nunca", "todo mundo")

**Gramática e sintaxe**
10. Nominalização excessiva
11. Voz passiva sintética impessoal
12. Cópula evasiva (evitar "ser/estar")
13. Gerúndio expletivo de análise rasa
14. Falsa agência (objeto inanimado agindo)
15. Hedging excessivo (sobre-modalização)
16. Pleonasmos canônicos

**Retórica e estrutura de frase**
17. Contrastes binários e paralelismo negativo
18. Lista negativa ("não é X… não é Y… é Z")
19. Tripla adjetival forçada
20. Falsa amplitude ("de X a Y")
21. Sinônimos forçados (rotação léxica)
22. Aforismos manufaturados ("X é o Y de Z")
23. Frases de efeito e staccato
24. Citáveis de LinkedIn
25. Perguntas e setups retóricos
26. Aberturas fake-cândidas
27. Tropos de autoridade
28. Narrador a distância ("as pessoas" em vez de "você")

**Conteúdo**
29. Exagero de significado e "tendências mais amplas"
30. Ênfase em notoriedade/cobertura midiática
31. Linguagem publicitária / "folder de turismo"
32. Atribuição vaga ("especialistas afirmam")
33. Preenchimento especulativo de lacuna
34. Seção "Desafios e Perspectivas Futuras"
35. Conclusão genérica positiva
36. Filler phrases e perífrases
37. Escrita ancorada em diff

**Estilo visual**
38. Travessão (regra dura)
39. Negrito decorativo
40. Listas com cabeçalho em negrito (inline header lists)
41. Emojis decorativos
42. Tabelas desnecessárias
43. Title Case em títulos
44. Cabeçalhos fragmentados
45. Hífen indevido em locuções

**Traços de conversa**
46. Bajulação e tom servil
47. Marcas de chatbot ("Espero que ajude!")
48. Disclaimers de cutoff de conhecimento
49. Sinalização e anúncios ("vamos mergulhar")

**O que NÃO sinalizar** (falsos positivos) · **Sinais de escrita humana** (preservar) · **Exemplo completo**

---

## Vocabulário e léxico

### 1. Vocabulário inflacionado de importância

**Palavras-bandeira (alta frequência em IA):** fundamental, essencial, crucial, vital, primordial, robusto, sofisticado, significativo, inovador, sem precedentes, vanguarda, fascinante, incrível, marco, paradigma.

**Problema:** A IA superestima a importância de qualquer assunto inflando adjetivos. Em texto humano, palavras como "fundamental" são raras; quando aparecem, têm peso real.

**Antes:**
> Esta solução robusta e inovadora representa um marco fundamental no cenário tecnológico contemporâneo, oferecendo uma abordagem sofisticada para desafios sem precedentes.

**Depois:**
> A ferramenta resolve dois problemas que existiam há anos: latência alta em queries paginadas e falta de retry automático.

---

### 2. Conectivos formais sobreusados

**Lista de conectivos suspeitos:** "além disso", "no entanto", "por outro lado", "portanto", "por conseguinte", "ou seja", "nesse contexto", "diante disso", "assim sendo", "por fim", "em suma", "em síntese", "dessa forma", "desse modo".

**Problema:** A IA conecta tudo mecanicamente. Texto humano usa conectores com parcimônia, ou solta frases sem ponte. Múltiplos parágrafos começando com "Além disso," / "Por outro lado," / "Por fim," é assinatura de IA.

**Antes:**
> O time aprovou a proposta. Além disso, definiu prazos. Por outro lado, alguns membros tinham dúvidas. Por fim, decidiu-se prosseguir.

**Depois:**
> O time aprovou a proposta e definiu prazos. Alguns membros ainda tinham dúvidas, mas o grupo decidiu prosseguir.

**Quando manter o conectivo:** quando há contraste real ou consequência lógica não óbvia. "No entanto" só vale se há tensão genuína entre as frases.

---

### 3. Frases-gatilho de abertura formulaica

**Lista:** "É importante ressaltar que…", "É importante destacar que…", "Cabe destacar que…", "Vale ressaltar que…", "Faz-se necessário…", "É fundamental compreender que…", "Convém mencionar que…".

**Problema:** Atrasam a frase principal. Em PT-BR formal, viraram clichê instantâneo de IA.

**Antes:**
> É importante ressaltar que o índice caiu 12% no último trimestre.

**Depois:**
> O índice caiu 12% no último trimestre.

---

### 4. Vocabulário etéreo corporativo

**Lista:** "ecossistema", "paradigma", "jornada", "universo", "panorama", "cenário", "essência", "DNA da marca", "framework", "narrativa", "verticalização", "disrupção".

**Problema:** Soam importantes, mas são semanticamente vagos. Quando aparecem em texto técnico ou jornalístico, quase sempre são IA ou marketing genérico.

**Antes:**
> No ecossistema atual de soluções digitais, navegamos uma jornada de transformação que redefine o paradigma do consumidor.

**Depois:**
> Mais empresas estão comprando software por assinatura, e os clientes esperam updates frequentes.

---

### 5. Arcaísmos jurídicos fora de contexto

**Lista:** "outrossim", "destarte", "ademais", "doravante", "amiúde", "por conseguinte", "nesse ínterim", "no afã de", "no diapasão".

**Problema:** A IA importa léxico de petições jurídicas para contextos casuais. Em texto informal ou técnico moderno, esses arcaísmos são marca forte de geração automática.

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

### 7. Jargão corporativo nativo

**Padrão:** verbos e locuções de reunião corporativa usados fora do contexto em que significam algo.

| IA usa | Troque por |
|---|---|
| alavancar | usar, aproveitar |
| endereçar (uma questão) | resolver, tratar de |
| performar | render, funcionar |
| trazer à mesa | oferecer, contribuir |
| navegar (um cenário) | lidar com |
| potencializar | melhorar, aumentar |
| impulsionar resultados | aumentar as vendas (o específico) |
| agregar valor | ajudar (diga como) |
| destravar (valor/potencial) | liberar, permitir (diga o quê) |
| mergulho profundo | análise |
| alinhar expectativas | combinar |

**Problema:** É a versão nativa do padrão que o stop-slop cataloga em inglês (navigate, unpack, lean into): verbo grandioso, referente vago. Um humano em contexto de trabalho fala "resolver o bug", não "endereçar a demanda".

**Antes:**
> Vamos alavancar nossa expertise para endereçar as dores do cliente e destravar valor na jornada de compra.

**Depois:**
> Vamos usar o que aprendemos com o suporte para cortar duas etapas do checkout.

---

### 8. Advérbios de intensidade em excesso

**Lista:** realmente, literalmente, genuinamente, honestamente, simplesmente, absolutamente, extremamente, incrivelmente, profundamente, verdadeiramente, fundamentalmente, essencialmente, basicamente, efetivamente.

**Problema:** A IA usa advérbios de intensidade como enchimento: a frase perde nada quando eles saem, e é isso que os denuncia. Não é uma proibição absoluta: advérbio que muda o sentido fica ("aumentou gradualmente"); advérbio que só infla, cai.

**Antes:**
> O resultado foi realmente impressionante e mostra que a equipe está genuinamente comprometida em entregar algo verdadeiramente diferente.

**Depois:**
> A equipe entregou a migração três semanas antes do prazo.

**Teste rápido:** releia a frase sem o advérbio. Se nada mudou, ele era enchimento.

---

### 9. Extremos preguiçosos

**Lista:** "todo mundo", "ninguém", "sempre", "nunca", "tudo", "qualquer um", "em todos os casos".

**Problema:** Absolutos usados como falsa autoridade: soam categóricos justamente porque não nomeiam nada verificável. Texto humano com opinião forte cita o caso concreto.

**Antes:**
> Todo mundo sabe que reuniões longas nunca funcionam e que ninguém lê atas.

**Depois:**
> Das últimas dez reuniões de mais de uma hora, oito terminaram sem decisão registrada.

---

## Gramática e sintaxe

### 10. Nominalização excessiva

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

### 11. Voz passiva sintética impessoal

**Lista:** "foi possível observar", "foi identificado", "verificou-se", "constatou-se", "pode-se afirmar", "pode-se concluir", "observou-se que".

**Problema:** Remove o agente, cria distância artificial. Em texto humano, dizemos "vimos", "encontramos", "concluímos". "Erros foram cometidos" esconde quem errou; nomeie o agente.

**Antes:**
> Foi possível observar que pode-se afirmar que verificou-se uma melhora.

**Depois:**
> Os números melhoraram.

**Strunk Rule 10:** prefira voz ativa. Em PT-BR isso significa cortar o "se" apassivador sempre que houver agente real.

---

### 12. Cópula evasiva

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

### 13. Gerúndio expletivo de análise rasa

**Padrão:** terminar frases com gerúndio para criar falsa profundidade.

**Verbos suspeitos no final:** destacando, evidenciando, demonstrando, refletindo, simbolizando, garantindo, fomentando, promovendo, contribuindo para, ressaltando, sublinhando.

**Problema:** Esses gerúndios não adicionam informação, só estendem a frase com aparência de análise.

**Antes:**
> O templo usa tons azuis, verdes e dourados, ressoando com a beleza natural da região, simbolizando a flora local e refletindo a conexão profunda da comunidade com a terra.

**Depois:**
> O templo usa azul, verde e dourado. O arquiteto disse que as cores remetem às flores nativas e ao mar.

---

### 14. Falsa agência

**Padrão:** objeto inanimado praticando ação humana.

**Lista:** "a decisão emerge", "os dados nos dizem", "a cultura muda", "o mercado recompensa", "a conversa caminha para", "a reclamação vira melhoria", "o projeto pede", "a arquitetura convida a".

**Problema:** Ninguém aparece fazendo nada: as coisas "acontecem sozinhas". É a marca que resta quando a IA evita nomear o agente sem usar voz passiva. Nomeie quem age; sem pessoa específica, use "você".

**Antes:**
> Quando a reclamação chega ao time certo, ela se transforma em melhoria e o produto evolui naturalmente.

**Depois:**
> Quando você encaminha a reclamação ao time certo, alguém corrige o fluxo e o produto melhora.

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

## Retórica e estrutura de frase

### 17. Contrastes binários e paralelismo negativo

**Padrão:** negar X para afirmar Y — a família inteira, não só "não apenas… mas também":

| Variante | Exemplo |
|---|---|
| não apenas X, mas também Y | "Não é apenas uma atualização, mas também uma mudança de rumo" |
| não é X. É Y. | "Não é um bug. É uma escolha de design." |
| o problema não é X, é Y | "O problema não é a ferramenta, é o processo" |
| não porque X, mas porque Y | "Não porque seja difícil, mas porque ninguém tentou" |
| parece X, na verdade é Y | "Parece economia. Na verdade é dívida técnica." |
| deixa de ser X e passa a ser Y | "O código deixa de ser custo e passa a ser ativo" |
| não significa X, e sim Y | "Não significa trabalhar mais, e sim trabalhar melhor" |
| mais do que X, é Y | "Mais do que uma métrica, é uma filosofia" |
| não se trata de X, trata-se de Y | "Não se trata de velocidade, trata-se de direção" |
| negação-cauda | "O deploy sai em um clique — sem configuração, sem surpresa." |

**Problema:** O striptease retórico infla uma afirmação simples. Afirme Y diretamente; a negação inteira cai, incluindo a cauda de negações penduradas no fim da frase.

**Antes:**
> Não se trata apenas de uma atualização, mas sim de uma revolução no modo como pensamos produtividade.

**Depois:**
> A atualização adiciona atalhos de teclado e modo offline.

**Quando manter:** em contexto retórico real (discurso, opinião explícita) e no máximo uma vez por texto. Em descrição factual, sempre corte.

---

### 18. Lista negativa

**Padrão:** "Não é um manual. Não é um curso. É um mapa."

**Problema:** Variante em série do contraste binário — três negações para revelar uma afirmação que caberia sozinha na primeira frase.

**Antes:**
> Isto não é um framework. Não é uma metodologia. Não é mais uma buzzword. É um jeito de trabalhar.

**Depois:**
> É um jeito de trabalhar: duas reuniões por semana e decisões registradas por escrito.

---

### 19. Tripla adjetival forçada

**Padrão:** três adjetivos/itens em sequência para criar ritmo aparente.

**Antes:**
> Uma solução eficaz, eficiente e inovadora, oferecendo uma experiência fluida, intuitiva e poderosa.

**Depois:**
> A solução é rápida e os usuários acharam fácil de usar.

**Regra prática:** se a tripla é gratuita, deixe dois itens ou quatro. Duplas batem triplas. Triplas só funcionam quando os três itens são distintos e necessários.

---

### 20. Falsa amplitude ("de X a Y")

**Padrão:** "desde X até Y", "de X a Y" — onde X e Y não estão numa escala real.

**Antes:**
> Nossa plataforma cobre desde startups iniciantes até multinacionais consolidadas, da inteligência artificial às soluções tradicionais.

**Depois:**
> A plataforma atende startups e grandes empresas, com módulos de IA e ferramentas convencionais.

---

### 21. Sinônimos forçados (rotação léxica)

**Padrão:** trocar de palavra a cada menção para "evitar repetição", mesmo quando a repetição seria natural.

**Antes:**
> O protagonista enfrenta desafios. O personagem principal supera obstáculos. A figura central vence as adversidades. O herói retorna ao lar.

**Depois:**
> O protagonista enfrenta vários desafios, vence e volta pra casa.

**Strunk Rule 12:** prefira termos definidos, específicos. Repetir o substantivo correto é melhor do que rotacionar sinônimos para parecer variado.

---

### 22. Aforismos manufaturados

**Padrão:** "X é o Y de Z" e frases-fórmula com cara de máxima.

**Lista:** "Dados são o novo petróleo", "A simetria é a linguagem da confiança", "Cultura é o que acontece quando ninguém está olhando", "Simplicidade é a sofisticação suprema".

**Problema:** A fórmula produz profundidade aparente sem afirmação verificável. Troque pela alegação concreta que o aforismo estava embrulhando.

**Antes:**
> Documentação é o amor que o time do futuro recebe do time do presente.

**Depois:**
> Quem entrar no time em março vai conseguir subir o ambiente sozinho lendo o README.

---

### 23. Frases de efeito e staccato

**Padrão:** fragmentos curtos empilhados para drama. "Sem preferência. Sem histórico. Sem nostalgia." / "[Substantivo]. É isso. Essa é a proposta."

**Problema:** Uma frase curta enfática funciona; três seguidas são percussão manufaturada. Varie o comprimento e troque o drama por um claim concreto.

**Antes:**
> Lançamos em março. Sem atraso. Sem desculpa. Sem drama. Só entrega.

**Depois:**
> Lançamos em março, dentro do prazo — a primeira vez em quatro releases. O que mudou foi o corte de escopo feito em janeiro.

---

### 24. Citáveis de LinkedIn

**Padrão:** frase construída para ser destacada, com cara de pull-quote motivacional.

**Problema:** Se a frase soa como legenda de post inspiracional ("Contrate por atitude, treine por habilidade"), ela foi otimizada para compartilhamento, não para o argumento. Reescreva no registro do texto, com o caso concreto.

**Antes:**
> No fim, não contratamos currículos. Contratamos histórias.

**Depois:**
> Nos últimos dois processos, os aprovados não tinham a stack da vaga — tinham projetos próprios que mostravam como aprendem.

---

### 25. Perguntas e setups retóricos

**Padrão:** pergunta que o próprio texto responde na frase seguinte, ou preparação que anuncia o que vem.

**Lista:** "E se eu te dissesse que…?", "Pense comigo:", "O que isso significa? Significa que…", "Quer saber o que aprendi?", "E é aí que entra o X", parágrafo começando com "Então,".

**Problema:** O leitor não perguntou; a pergunta é palco. Afirme direto. Pergunta genuína dirigida ao leitor (num texto interativo, num formulário) é legítima — a marca é a pergunta-palco autorespondida.

**Antes:**
> O que isso significa para o seu negócio? Significa que a margem vai cair. E se houvesse uma forma de evitar isso?

**Depois:**
> A margem vai cair. Dá para compensar renegociando o contrato de frete, que vence em abril.

---

### 26. Aberturas fake-cândidas

**Padrão:** falsa espontaneidade no início da frase: "Sinceramente?", "Olha,", "Vou ser honesto:", "A real é que", "Verdade seja dita".

**Problema:** A pausa teatral simula candura antes de uma resposta comum. Em texto genuinamente pessoal, uma dessas pode ser voz; em série, ou abrindo texto informativo, é figurino.

**Antes:**
> Sinceramente? Depende. Olha, a real é que nenhuma ferramenta resolve tudo.

**Depois:**
> Depende do tamanho do time: até cinco pessoas, planilha resolve; acima disso, vale ferramenta dedicada.

---

### 27. Tropos de autoridade

**Padrão:** fórmulas que simulam profundidade analítica.

**Lista:** "No fundo, o que realmente importa é…", "A verdadeira questão é…", "No final do dia…", "Em sua essência…", "O ponto central aqui é…".

**Problema:** Anunciam a chegada de uma verdade em vez de entregá-la. Afirme o ponto sem o tapete vermelho.

**Antes:**
> No final do dia, a verdadeira questão não é a tecnologia, mas as pessoas.

**Depois:**
> O gargalo é a fila de revisão: duas pessoas aprovam os PRs de quinze.

---

### 28. Narrador a distância

**Padrão:** voz de sociólogo de poltrona observando a humanidade de longe: "As pessoas tendem a…", "Ninguém planejou isso.", "Isso acontece porque as organizações…".

**Problema:** Generaliza sobre "as pessoas" quando poderia falar com o leitor. "Você" bate "as pessoas": coloca o leitor na cena e força o texto a ser verificável.

**Antes:**
> As pessoas tendem a adiar decisões difíceis quando não há um prazo claro, e as organizações raramente criam esses prazos.

**Depois:**
> Sem prazo, você adia a decisão — todo mundo adia. Marque a data da escolha na mesma reunião em que o problema aparecer.

---

## Conteúdo

### 29. Exagero de significado e "tendências mais amplas"

**Padrão:** afirmar que qualquer evento representa, simboliza, marca, ou contribui para uma tendência maior.

**Lista:** "marca um ponto de inflexão", "representa uma virada", "deixa uma marca duradoura", "reflete uma tendência mais ampla", "lança as bases para", "molda o futuro de", "no panorama em evolução de".

**Antes:**
> O Instituto de Estatística da Catalunha foi criado em 1989, marcando um ponto de inflexão na evolução da estatística regional na Espanha e refletindo um movimento mais amplo de descentralização administrativa.

**Depois:**
> O Instituto de Estatística da Catalunha foi criado em 1989 para coletar e publicar dados regionais separadamente do instituto nacional.

---

### 30. Ênfase em notoriedade/cobertura midiática

**Padrão:** listar veículos onde a pessoa foi citada, ou seguidores em redes sociais, sem contexto.

**Antes:**
> Suas opiniões foram citadas pelo Estado, Folha, BBC Brasil e G1. Tem presença ativa nas redes sociais com mais de 500 mil seguidores.

**Depois:**
> Em entrevista à Folha em 2024, defendeu que a regulação de IA deve focar em resultados, não em métodos.

---

### 31. Linguagem publicitária / "folder de turismo"

**Lista:** "vibrante", "pitoresco", "deslumbrante", "rica herança cultural", "imperdível", "cativante", "berço de", "no coração de", "aninhado em", "deslumbrante beleza natural", "encantador".

**Problema:** A IA falha em manter neutralidade descritiva, especialmente em verbetes geográficos e culturais.

**Antes:**
> Aninhado no coração da deslumbrante região serrana, Petrópolis é uma cidade vibrante com uma rica herança cultural e uma beleza natural cativante.

**Depois:**
> Petrópolis fica na região serrana do Rio de Janeiro, conhecida pelo Museu Imperial e pelo clima ameno.

---

### 32. Atribuição vaga

**Padrão:** "especialistas afirmam", "analistas indicam", "estudos apontam", "observadores apontam", "alguns críticos argumentam", "relatórios da indústria mostram" — sem citar fonte específica.

**Antes:**
> Estudos apontam que a IA terá um papel crucial nos próximos anos. Especialistas concordam que essa é uma transformação sem precedentes.

**Depois:**
> Um relatório do Gartner de 2024 estima que 75% das empresas vão usar IA generativa em produção até 2026.

---

### 33. Preenchimento especulativo de lacuna

**Padrão:** quando falta informação, a IA escreve um parágrafo sobre a falta e depois inventa um preenchimento plausível: "mantém um perfil discreto", "provavelmente cresceu em uma família de classe média", "acredita-se que tenha iniciado a carreira cedo".

**Problema:** É fabricação disfarçada de prudência. Diga o que não se sabe em uma frase, ou corte o tópico. Nunca disfarce um chute de fato.

**Antes:**
> Embora pouco se saiba sobre sua formação, é provável que tenha estudado em escolas públicas da região e desenvolvido cedo o interesse pela política local.

**Depois:**
> Não há registro público sobre sua formação escolar.

---

### 34. Seção "Desafios e Perspectivas Futuras"

**Padrão:** seção formulaica com obstáculos genéricos seguida de otimismo vago.

**Antes:**
> Apesar de seu crescimento industrial, Korattur enfrenta desafios típicos de áreas urbanas, incluindo congestionamento e escassez de água. No entanto, com sua localização estratégica e iniciativas em andamento, Korattur continua a prosperar como parte integral do crescimento de Chennai.

**Depois:**
> O congestionamento piorou em 2015 quando três parques industriais abriram. A prefeitura iniciou um projeto de drenagem em 2022 para resolver enchentes recorrentes.

---

### 35. Conclusão genérica positiva

**Lista:** "o futuro é promissor", "tempos empolgantes estão por vir", "fica claro que", "diante do exposto", "em suma, os benefícios são inúmeros", "abrindo caminho para um futuro melhor".

**Antes:**
> O futuro da empresa parece promissor. Tempos empolgantes virão e ela continua sua jornada de excelência. Diante do exposto, fica claro que este é um passo na direção certa.

**Depois:**
> A empresa planeja abrir duas lojas no ano que vem.

**Regra:** termine no último fato concreto. O texto acaba quando a informação acaba.

---

### 36. Filler phrases e perífrases

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

### 37. Escrita ancorada em diff

**Padrão:** documentação que narra a mudança em vez de descrever o estado atual: "Esta função foi adicionada para substituir…", "O parâmetro agora aceita…", "Diferente da versão anterior…".

**Problema:** O leitor de amanhã não conhece a versão anterior: a narrativa do diff só faz sentido para quem viu o antes. Descreva o que a coisa é e faz hoje. (Exceção óbvia: changelog, que existe para narrar diffs.)

**Antes:**
> Esta função foi adicionada para substituir o antigo helper de validação, que não suportava schemas aninhados.

**Depois:**
> Valida payloads contra o schema, incluindo objetos aninhados.

---

## Estilo visual

### 38. Travessão (regra dura)

**Regra:** a entrega final tem **zero** travessões (— e –). Substitutos: vírgula, ponto, dois-pontos ou parênteses. Antes de considerar o texto pronto, faça uma varredura literal procurando `—` e `–`.

**Por quê:** o travessão é a marca visual mais reconhecida de texto de IA em 2026: a frequência gerada é muitas vezes a humana. Regra de detecção e regra de produção são diferentes: um travessão num texto alheio não prova nada (ver falsos positivos), mas na SUA entrega a política é zero.

**Exceção única:** o autor forneceu amostra de escrita que usa travessão — a calibração de voz sobrepõe esta regra.

**Antes:**
> Este termo é promovido pelas instituições — não pelo povo. O erro continua — mesmo em documentos oficiais.

**Depois:**
> Este termo é promovido pelas instituições, não pelo povo. O erro continua mesmo em documentos oficiais.

---

### 39. Negrito decorativo

**Problema:** A IA enfatiza palavras em negrito mecanicamente, sem hierarquia de importância.

**Antes:**
> A solução combina **OKR (Objetivos e Resultados-Chave)**, **KPIs (Indicadores-Chave de Desempenho)** e ferramentas como **BMC (Business Model Canvas)** e **BSC (Balanced Scorecard)**.

**Depois:**
> A solução combina OKRs, KPIs, Business Model Canvas e Balanced Scorecard.

**Regra:** negrito só para o que realmente precisa de destaque. Mais de 2-3 negritos por parágrafo já é demais.

---

### 40. Listas com cabeçalho em negrito (inline header lists)

**Padrão:** lista onde cada item começa com substantivo em negrito + dois-pontos + frase que repete o substantivo.

**Antes:**
> - **Experiência do usuário:** A experiência do usuário melhorou com a nova interface.
> - **Desempenho:** O desempenho foi aprimorado por algoritmos otimizados.
> - **Segurança:** A segurança foi reforçada por criptografia ponta a ponta.

**Depois:**
> A atualização trouxe nova interface, carregamento mais rápido e criptografia ponta a ponta.

---

### 41. Emojis decorativos

**Padrão:** emojis no início de tópicos ou cabeçalhos, especialmente 🚀, 💡, ✅, 🎯, 📊, 🔥.

**Antes:**
> 🚀 **Lançamento:** O produto sai no Q3
> 💡 **Insight:** Usuários preferem simplicidade
> ✅ **Próximo passo:** Marcar follow-up

**Depois:**
> O produto sai no Q3. A pesquisa com usuários mostrou preferência por simplicidade. Próximo passo: marcar follow-up.

**Exceção:** o usuário pediu emojis explicitamente.

---

### 42. Tabelas desnecessárias

**Padrão:** tabela markdown pequena (2-3 linhas) para informação que seria prosa ou lista natural: "estatísticas-chave", comparação de dois itens, lista de cargos.

**Problema:** Chatbots geram tabelas onde nenhum humano tabularia. Tabela só se justifica com dados genuinamente tabulares: várias linhas E colunas realmente comparáveis. (Padrão expandido na Wikipedia:Signs of AI writing em jul/2026.)

**Antes:**
> | Métrica | Valor |
> |---|---|
> | Fundação | 1994 |
> | Sede | Curitiba |
> | Funcionários | 120 |

**Depois:**
> Fundada em 1994, a empresa tem sede em Curitiba e 120 funcionários.

---

### 43. Title Case em títulos

**Padrão:** capitalizar Cada Palavra Do Título, por contágio do inglês.

**Problema:** A norma PT-BR capitaliza só a primeira palavra e nomes próprios. "Estratégias De Crescimento E Parcerias Globais" delata template EN traduzido.

**Antes:**
> ## Principais Benefícios Da Nova Arquitetura De Microsserviços

**Depois:**
> ## Principais benefícios da nova arquitetura de microsserviços

---

### 44. Cabeçalhos fragmentados

**Padrão:** título seguido de uma frase de aquecimento que só repete o título antes do conteúdo real.

**Antes:**
> ## Configuração do ambiente
> Nesta seção, vamos ver como configurar o ambiente.
> Primeiro, instale as dependências…

**Depois:**
> ## Configuração do ambiente
> Primeiro, instale as dependências…

---

### 45. Hífen indevido em locuções

**Padrão:** hífen transplantado do padrão inglês de pares hifenizados ("high-quality report") para locuções PT que não pedem hífen.

**Antes:**
> Precisamos de decisões de longo-prazo e soluções de alta-qualidade.

**Depois:**
> Precisamos de decisões de longo prazo e soluções de alta qualidade.

**Regra PT-BR:** locução adjetiva com preposição não leva hífen. Hífen fica onde a norma pede (compostos consagrados: "segunda-feira", "guarda-chuva").

---

## Traços de conversa

### 46. Bajulação e tom servil

**Lista:** "Excelente pergunta!", "Certamente!", "Com toda certeza!", "Você está absolutamente certo!", "Que ótima observação!".

**Antes:**
> Excelente pergunta! Você está absolutamente certo de que esse é um tema complexo. Sobre os fatores econômicos, é uma ótima observação.

**Depois:**
> Os fatores econômicos que você mencionou são relevantes aqui.

---

### 47. Marcas de chatbot

**Lista:** "Espero que isso ajude!", "Claro!", "Com certeza!", "Aqui está…", "Se quiser que eu explique mais alguma coisa, é só pedir!", "Posso elaborar mais se precisar."

**Antes:**
> Aqui está um resumo sobre a Revolução Francesa. Espero que isso ajude! Se quiser que eu expanda alguma parte, é só pedir.

**Depois:**
> A Revolução Francesa começou em 1789, quando a crise fiscal e a escassez de comida geraram revolta generalizada.

---

### 48. Disclaimers de cutoff de conhecimento

**Lista:** "Até a data do meu último treinamento…", "Com base nas informações disponíveis…", "Embora detalhes específicos sejam limitados…", "Conforme os dados aos quais tenho acesso…".

**Antes:**
> Embora detalhes específicos sobre a fundação da empresa não estejam amplamente documentados nas fontes prontamente disponíveis, parece ter sido fundada em algum momento dos anos 1990.

**Depois:**
> Segundo o registro na Junta Comercial, a empresa foi fundada em 1994.

---

### 49. Sinalização e anúncios

**Lista:** "Vamos mergulhar em…", "Neste artigo, você vai descobrir…", "Sem mais delongas…", "Vamos direto ao ponto:" (seguido de rodeio), "Continue lendo para saber…".

**Problema:** O texto anuncia o que vai fazer em vez de fazer. Comece no conteúdo.

**Antes:**
> Neste post, vamos mergulhar fundo no funcionamento do cache. Sem mais delongas, vamos lá!

**Depois:**
> O cache guarda a resposta da primeira consulta e serve as seguintes direto da memória.

---

## O que NÃO sinalizar (falsos positivos)

A regra-guia: procure **clusters** de marcas, não marcas isoladas. Uma ocorrência única de quase qualquer item deste catálogo é normal em escrita humana. Não sinalize:

- **Gramática correta e formatação impecável**: humanos cuidadosos também revisam.
- **Registro misto** (formal com toques casuais): é traço humano, não inconsistência de IA.
- **Prosa "seca" sem nenhuma marca específica**: texto direto e neutro não é evidência de nada.
- **Vocabulário formal ou técnico isolado**: jargão da área em contexto adequado é legítimo.
- **Um único "no entanto", um único travessão, uma única frase curta enfática**: a marca é a frequência, não a existência.
- **"honestamente"/"sinceramente" no meio da frase**: a marca fake-cândida é na abertura, como palco.
- **Alegações sem fonte em texto casual**: a maior parte da escrita humana na web não cita fonte; exigir citação é para registro enciclopédico/jornalístico.
- **Texto de segunda mão**: nunca reescreva a frase-alvo dentro de citação, título de obra, nome próprio ou exemplo onde a construção está sendo *discutida*, não *usada* (este catálogo inteiro é um exemplo disso).

## Sinais de escrita humana (preservar)

Ao reescrever, estes traços são valor, não defeito — mantenha:

- Detalhe específico difícil de fabricar (o nome do bar, o valor exato da multa, o horário do commit).
- Sentimentos mistos e tensão não resolvida ("impressiona e incomoda ao mesmo tempo").
- Referências datadas ou geracionais espontâneas.
- Escolhas editoriais de primeira pessoa que o autor saberia justificar.
- Variedade genuína de comprimento de frase, incluindo alguma frase torta.
- Parênteses e autocorreções no meio do caminho ("aliás, corrijo: foram três").
- Contexto temporal: texto anterior a 30/nov/2022 (lançamento do ChatGPT) quase nunca é gerado por IA.

---

## Exemplo completo

**Antes (com marcas de IA):**
> A nova atualização do software configura-se como uma prova do compromisso da empresa com a inovação. Além disso, ela oferece uma experiência fluida, intuitiva e robusta — garantindo que os usuários possam atingir seus objetivos com eficiência. Não se trata apenas de uma atualização, mas sim de uma revolução no modo como pensamos a produtividade. Especialistas do setor afirmam que isso terá um impacto duradouro em todo o segmento, ressaltando o papel fundamental da empresa no cenário tecnológico em evolução.

**Depois (humanizado):**
> A atualização adiciona processamento em lote, atalhos de teclado e modo offline. Os testers iniciais relataram fechar tarefas mais rápido, e a maioria citou os atalhos como o maior ganho.

**Mudanças:**
- Cópula evasiva + exagero de significado ("configura-se como uma prova") → fato direto
- Conectivo automático ("Além disso") → cortado
- Tripla adjetival + publicidade ("fluida, intuitiva e robusta") → específicos
- Travessão + gerúndio analítico ("— garantindo que") → cortados na varredura final
- Paralelismo negativo ("Não se trata apenas… mas sim…") → afirmação direta
- Atribuição vaga ("especialistas afirmam") → reação específica dos testers
- Vocabulário etéreo ("cenário tecnológico em evolução") → cortado

---

## Referências

- [blader/humanizer](https://github.com/blader/humanizer) e [op7418/Humanizer-zh](https://github.com/op7418/Humanizer-zh) (fork intermediário de onde esta skill derivou)
- [hardikpandya/stop-slop](https://github.com/hardikpandya/stop-slop)
- [Wikipedia:Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing)
- Strunk — *The Elements of Style* ([gutenberg.org/ebooks/37134](https://www.gutenberg.org/ebooks/37134))
- Gazeta do Povo — Clichês de IA em textos de políticos brasileiros
- Envox — Os maiores vícios de linguagem de IA em 2026
- Hastewire — Como identificar texto de IA em português
- Advoco Brasil — 7 sinais que entregam texto gerado por IA
- Humanizar Textos — Lista de palavras e frases mais comuns do ChatGPT
- Norma Culta — Lista de pleonasmos mais comuns
