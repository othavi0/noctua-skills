#!/usr/bin/env python3
"""Varre prosa pt-BR por marcas de IA.

Uso: scan.py ARQUIVO... (ou - para ler stdin)
Ignora código e texto entre aspas, que é exemplo ou citação. Sai com 1 se achar alguma marca;
aviso só imprime, porque tem uso legítimo (cabeçalho fixo de template, termo técnico).
"""
import re
import sys

MARCA, AVISO = "marca", "aviso"

POR_LINHA = [
    (MARCA, "38 travessão ou meia-risca", r"[—–]"),
    (MARCA, "seta", r"(?<!-)->|→"),
    (AVISO, "hífen no lugar de travessão", r"\w - \w"),
    (AVISO, "40 rótulo em negrito", r"^\s*(?:(?:[-*]|\d+\.)\s+\*\*[^*\n]+\*\*|\*\*[^*\n]{1,80}[.:]\*\*)"),
    (AVISO, "43 Title Case", r"^#{1,6} [A-ZÁÉÍÓÚ]\w*(?: [A-ZÁÉÍÓÚ]\w*)+\s*$"),
    (AVISO, "1/4 léxico inflado", r"(?i)\b(?:crucial|robust[oa]s?|abrangente|potencializ\w+|fomentar|alavanc\w+|panorama|ecossistema|jornada|sem precedentes|vanguarda|primordial|paradigma|disrup\w+)\b"),
    (AVISO, "7 jargão corporativo", r"(?i)\b(?:agreg\w+ valor|trazer à mesa|destrav\w+ (?:o )?(?:valor|potencial)|mergulho profundo|alinh\w+ (?:as )?expectativas|endereç\w+ (?:a|as|o|os) (?:demandas?|dor|dores|questão|questões))\b"),
    (AVISO, "5 arcaísmo", r"(?i)\b(?:outrossim|destarte|ademais|doravante|amiúde|por conseguinte|nesse ínterim|no afã de|no diapasão)\b"),
    (AVISO, "16 pleonasmo", r"(?i)\b(?:panorama geral|conclusão final|protagonista principal|consenso geral|certeza absoluta|pequenos detalhes|novidade inédita|planejar antecipadamente|opinião pessoal|elo de ligação|subir para cima|descer para baixo|há (?:\w+ )?(?:anos|meses|semanas|dias) atrás)\b"),
    (AVISO, "36 filler", r"(?i)\b(?:devido ao fato de|no que diz respeito a|com o intuito de|tem a capacidade de|caso seja necessário|para que se possa)\b"),
    (AVISO, "26 fake-cândida", r"(?:^|[.!?]\s+)(?:Sinceramente\?|Honestamente\?|Olha, |Vou ser (?:honest|sincer)[oa]|A real é que|Verdade seja dita)"),
    (AVISO, "27 tropo de autoridade", r"(?i)\b(?:no final do dia(?=,)|a verdadeira questão|no fundo, o que (?:realmente )?importa|em sua essência|o ponto central aqui)\b"),
    (AVISO, "39 negrito decorativo", r"(?:\*\*[^*\n]+\*\*[^*\n]*){4}"),
    (AVISO, "41 emoji decorativo", r"^\s*(?:[-*]\s+|#{1,6}\s+)?[\U0001F300-\U0001FAFF\u2600-\u27BF]"),
    (MARCA, "3 abertura formulaica", r"(?i)\b(?:é (?:importante|fundamental|válido|interessante) (?:ressaltar|destacar|notar|mencionar|lembrar|frisar|salientar|compreender)|(?:cabe|vale|convém) (?:ressaltar|destacar|notar|mencionar|frisar|salientar)|faz-se necessário)\b"),
    (MARCA, "25 setup retórico", r"(?i)\b(?:e se eu te dissesse|pense comigo|quer saber o que|e é aí que entra)\b"),
    (MARCA, "35 conclusão genérica", r"(?i)\b(?:o futuro (?:é|parece) promissor|tempos empolgantes|diante do exposto|abrindo caminho para um futuro)\b"),
    (MARCA, "45 hífen indevido", r"(?i)\b(?:(?:longo|curto|médio)-prazo|alta-(?:qualidade|performance|disponibilidade)|tempo-real|ponta-a-ponta)\b"),
    (MARCA, "46 bajulação", r"(?i)\b(?:(?:excelente|ótima|boa) pergunta!|que ótima observação|você está (?:absolutamente|totalmente|completamente) cert[oa])"),
    (MARCA, "47 chatbot", r"(?i)\b(?:espero que (?:isso|isto) (?:ajude|tenha ajudado)|é só pedir|posso (?:elaborar|detalhar|expandir) mais|se quiser que eu)\b|^\s*(?:Claro|Com certeza|Certamente)!"),
    (MARCA, "48 cutoff", r"(?i)\b(?:meu último treinamento|com base nas informações disponíveis|(?:dados|informações) aos quais tenho acesso|embora detalhes específicos)\b"),
    (MARCA, "49 sinalização", r"(?i)\b(?:vamos mergulhar|sem mais delongas|continue lendo para|ne(?:ste|sta) (?:artigo|post|texto|guia|tutorial|seção),? (?:você vai|vamos))\b"),
]

NO_TEXTO = [
    (MARCA, "17 não é X. É Y", r"(?i)\bnão (?!porque\b)(\w+)\b[^.!?\n]{1,80}[.,]\s+\1\b"),
    (MARCA, "17 não só", r"(?i)\bnão (?:só|apenas|somente)\b[^.!?\n]{1,80}\bmas\b"),
    (MARCA, "18 Não porque", r"\bNão porque\b"),
    (MARCA, "17 trata-se de", r"(?i)\bnão se trata\b[^.!?\n]{1,80}[.,;]\s+trata-se\b"),
    (AVISO, "17 deixa de ser", r"(?i)\bdeixa(?:m|r)? de ser\b[^.!?\n]{1,80}\be passa(?:m|r)? a ser\b"),
    (AVISO, "17 e sim", r"(?i)\bnão\b[^.!?\n]{1,80},\s+e sim\b"),
    (MARCA, "17 mais do que", r"(?im)(?:^|[.!?]\s+)mais do que\b[^.!?\n]{1,60},\s+(?:é|são)\b"),
    (AVISO, "17 na verdade", r"(?i)\bparece\b[^.!?\n]{1,60}[.,]\s+na verdade,?\s+(?:é|são)\b"),
    (MARCA, "18 lista negativa", r"(?i)\bnão é\b[^.!?\n]{1,60}\.\s+não é\b"),
    (AVISO, "23 staccato", r"(?m)(?:^|[.!?]\s+)Sem [^.!?,\n]{1,30}\.\s+Sem [^.!?,\n]{1,30}\."),
    (AVISO, "17 , não X.", r", não (?:o|a|os|as|no|na|do|da|em|um|uma)\b[^.,;\n]{1,40}\."),
]


def so_linhas(m):
    return "\n" * m.group(0).count("\n")


def sem_segunda_mao(texto):
    texto = re.sub(r"```.*?```", so_linhas, texto, flags=re.S)
    texto = re.sub(r"`[^`\n]*`", "", texto)
    return re.sub(r'"[^"]{1,200}"|“[^”]{1,200}”', so_linhas, texto)


def varrer(texto):
    texto = sem_segunda_mao(texto)
    achados = []
    for n, linha in enumerate(texto.splitlines(), 1):
        for nivel, nome, padrao in POR_LINHA:
            if re.search(padrao, linha):
                achados.append((n, nivel, nome, linha.strip()))
    for nivel, nome, padrao in NO_TEXTO:
        for m in re.finditer(padrao, texto):
            n = texto.count("\n", 0, m.start()) + 1
            achados.append((n, nivel, nome, m.group(0).replace("\n", " ")))
    return sorted(achados)


def main(caminhos):
    marcas = avisos = 0
    for caminho in caminhos:
        texto = sys.stdin.read() if caminho == "-" else open(caminho, encoding="utf-8").read()
        for n, nivel, nome, trecho in varrer(texto):
            print(f"{caminho}:{n}: {nivel}: {nome}: {trecho[:100]}")
            if nivel == MARCA:
                marcas += 1
            else:
                avisos += 1
    print(f"{marcas} marcas, {avisos} avisos")
    return 1 if marcas else 0


if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        sys.exit(__doc__)
    sys.exit(main(sys.argv[1:]))
