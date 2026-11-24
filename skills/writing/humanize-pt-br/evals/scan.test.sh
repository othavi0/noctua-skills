#!/usr/bin/env bash
# Roda scripts/scan.py contra frases reais que escaparam em PRs e contra prosa limpa.
# Uso: bash evals/scan.test.sh   (python3)
set -uo pipefail
SCAN="$(cd "$(dirname "$0")/.." && pwd)/scripts/scan.py"
fails=0
check() { if [[ "$2" == $3 ]]; then echo "ok   $1"; else echo "FAIL $1: got '$2', want '$3'"; fails=$((fails + 1)); fi; }
scan() { printf '%s\n' "$1" | python3 "$SCAN" - 2>&1; }

check "meia-risca em intervalo" "$(scan 'Rodamos W1–W16 e as migrations 068–070.')" "*marca: 38 travessão*"
check "travessão" "$(scan 'A barra recalcula — e não avisa.')" "*marca: 38 travessão*"
check "seta na prosa" "$(scan 'O modo passou de 100644 -> 100755.')" "*marca: seta*"
check "contraste com o mesmo verbo" "$(scan 'O fluxo não quebra pela tecnologia. Quebra por processo.')" "*marca: 17 não é X. É Y*"
check "contraste com cópula" "$(scan 'O problema não é a máquina. É a instalação.')" "*marca: 17 não é X. É Y*"
check "não só, mas" "$(scan 'O fix não só corrige o bug, mas também acelera o build.')" "*marca: 17 não só*"
check "Não porque" "$(scan 'Não porque o teste falhou. Porque o CI caiu.')" "*marca: 18 Não porque*"
check "rótulo em negrito é aviso" "$(scan '**Glossário.** O CONTEXT.md define os termos.')" "*aviso: 40 rótulo em negrito*0 marcas, 1 avisos"
check "item com rótulo é aviso" "$(scan '- **Copiar link** abre o modal.')" "*aviso: 40 rótulo*"
check "Title Case é aviso" "$(scan '## Blast Radius')" "*aviso: 43 Title Case*"
check "léxico é aviso" "$(scan 'Ficou um fluxo robusto.')" "*aviso: 1/4 léxico*"

check "código inline e bloco ficam de fora" "$(scan $'Rode `a -> b` e `x — y`.\n```\nfoo — bar -> baz\n```')" "0 marcas, 0 avisos"
check "exemplo entre aspas fica de fora" "$(scan $'Corte o contraste "não é X. É Y" e o "W1–W16".\nTroque “não só X, mas Y”.')" "0 marcas, 0 avisos"
check "Não porque conta uma vez" "$(scan 'Não porque o teste falhou. Porque o CI caiu.' | tail -1)" "1 marcas, 0 avisos"
check "negação factual com outro verbo passa" "$(scan 'O job não roda no CI. Foi removido em #12.')" "0 marcas, 0 avisos"
check "não só sem mas passa" "$(scan 'O bug não só aparece no Android.')" "0 marcas, 0 avisos"
check "prosa limpa passa" "$(scan $'Medi a faixa e achei 343 px.\n\nO teste cobre o caso do token vencido.')" "0 marcas, 0 avisos"
check "frase com hífen composto passa" "$(scan 'O pós-processamento usa guarda-chuva e bem-vindo.')" "0 marcas, 0 avisos"

check "não se trata, trata-se" "$(scan 'Não se trata de velocidade, trata-se de direção.')" "*marca: 17 trata-se de*"
check "deixa de ser, passa a ser" "$(scan 'O código deixa de ser custo e passa a ser ativo.')" "*marca: 17 deixa de ser*"
check "não X, e sim Y" "$(scan 'Não significa trabalhar mais, e sim trabalhar melhor.')" "*marca: 17 e sim*"
check "mais do que X, é Y" "$(scan 'Mais do que uma métrica, é uma filosofia.')" "*marca: 17 mais do que*"
check "parece X. Na verdade é Y" "$(scan 'Parece economia. Na verdade é dívida técnica.')" "*marca: 17 na verdade*"
check "lista negativa" "$(scan 'Isto não é um framework. Não é uma metodologia.')" "*marca: 18 lista negativa*"
check "abertura formulaica" "$(scan 'É importante ressaltar que o índice caiu 12%.')" "*marca: 3 abertura formulaica*"
check "vale ressaltar" "$(scan 'Vale ressaltar que o job roda à noite.')" "*marca: 3 abertura formulaica*"
check "staccato com Sem" "$(scan 'Lançamos em março. Sem atraso. Sem desculpa.')" "*marca: 23 staccato*"
check "setup retórico" "$(scan 'E é aí que entra o cache de segundo nível.')" "*marca: 25 setup retórico*"
check "conclusão genérica" "$(scan 'O futuro é promissor para a equipe.')" "*marca: 35 conclusão genérica*"
check "hífen indevido" "$(scan 'Precisamos de decisões de longo-prazo.')" "*marca: 45 hífen indevido*"
check "bajulação" "$(scan 'Excelente pergunta! O cache resolve isso.')" "*marca: 46 bajulação*"
check "marca de chatbot" "$(scan 'O resumo está acima. Espero que isso ajude!')" "*marca: 47 chatbot*"
check "disclaimer de cutoff" "$(scan 'Até a data do meu último treinamento, a lib não tinha a API.')" "*marca: 48 cutoff*"
check "sinalização" "$(scan 'Neste post, vamos mergulhar no funcionamento do cache.')" "*marca: 49 sinalização*"
check "fake-cândida é aviso" "$(scan 'Sinceramente? Depende do tamanho do time.')" "*aviso: 26 fake-cândida*0 marcas, 1 avisos"
check "tropo de autoridade é aviso" "$(scan 'No final do dia, a fila de revisão decide.')" "*aviso: 27 tropo*"
check "filler é aviso" "$(scan 'O deploy atrasou devido ao fato de a fila travar.')" "*aviso: 36 filler*"
check "pleonasmo é aviso" "$(scan 'A conclusão final saiu na ata.')" "*aviso: 16 pleonasmo*"
check "arcaísmo é aviso" "$(scan 'Outrossim, a equipe segue iterando.')" "*aviso: 5 arcaísmo*"
check "jargão é aviso" "$(scan 'Vamos agregar valor ao cliente.')" "*aviso: 7 jargão*"
check "negrito decorativo é aviso" "$(scan 'Usamos **OKR**, **KPI**, **BMC** e **BSC** no plano.')" "*aviso: 39 negrito decorativo*"
check "emoji no começo é aviso" "$(scan '🚀 O produto sai no Q3.')" "*aviso: 41 emoji*"
check "negação comum com mas passa" "$(scan 'O job não roda no CI, mas compila. Falta o segredo.')" "0 marcas, 0 avisos"
check "intervalo de datas passa" "$(scan 'O log cobre de março a maio. Sem o log de abril, o gráfico fica vazio.')" "0 marcas, 0 avisos"
check "hífen de composto consagrado passa" "$(scan 'A reunião é na segunda-feira e o prazo é curto.')" "0 marcas, 0 avisos"
check "Sem com oração passa" "$(scan 'Sem o token, a chamada falha. Sem a rede, ela trava.')" "0 marcas, 0 avisos"
check "final do dia literal passa" "$(scan 'No final do dia 3 o lote fecha.')" "0 marcas, 0 avisos"
check "negrito único passa" "$(scan 'Rode **antes** do deploy.')" "0 marcas, 0 avisos"

T=$(mktemp)
printf 'O problema não é a máquina. É a instalação.\n' > "$T"
python3 "$SCAN" "$T" >/dev/null; check "marca sai com 1" "$?" "1"
printf 'Prosa limpa.\n' > "$T"
python3 "$SCAN" "$T" >/dev/null; check "sem marca sai com 0" "$?" "0"
rm -f "$T"

[ "$fails" -eq 0 ] && echo "todos ok" || { echo "$fails falhas"; exit 1; }
