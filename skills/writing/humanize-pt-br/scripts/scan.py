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
    (AVISO, "1/4 léxico inflado", r"(?i)\b(?:crucial|robust[oa]s?|abrangente|potencializ\w+|fomentar|alavanc\w+|panorama|ecossistema|jornada)\b"),
]

NO_TEXTO = [
    (MARCA, "17 não é X. É Y", r"(?i)\bnão (?!porque\b)(\w+)\b[^.!?\n]{1,80}[.,]\s+\1\b"),
    (MARCA, "17 não só", r"(?i)\bnão (?:só|apenas|somente)\b[^.!?\n]{1,80}\bmas\b"),
    (MARCA, "18 Não porque", r"\bNão porque\b"),
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
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    sys.exit(main(sys.argv[1:]))
