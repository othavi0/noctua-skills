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

T=$(mktemp)
printf 'O problema não é a máquina. É a instalação.\n' > "$T"
python3 "$SCAN" "$T" >/dev/null; check "marca sai com 1" "$?" "1"
printf 'Prosa limpa.\n' > "$T"
python3 "$SCAN" "$T" >/dev/null; check "sem marca sai com 0" "$?" "0"
rm -f "$T"

[ "$fails" -eq 0 ] && echo "todos ok" || { echo "$fails falhas"; exit 1; }
