# -*- coding: utf-8 -*-
"""Prova em cinza do #41 (acessibilidade sem cor). Uso: python prova_cinza_41.py

Le assets/src/refs/gecko-<cor>.png (64x64) e plataforma-<cor>.png (96x40), converte
para cinza e grava assets/src/refs/prova-cinza-41.png (deterministico, sem metadado).
Aceita 3 ou 4 geckos: sem gecko-vermelho.png a celula vira placeholder "PENDENTE"
e a metrica usa so os pares existentes.

Cinza: Rec.601, L = (299*R + 587*G + 114*B + 500) // 1000 (inteiro, arredondado).
Alfa: pixel "opaco" se A >= 128.

Metrica por par (A, B) do mesmo grupo:
  MAD = media de |L_A - L_B| sobre pixels opacos nos DOIS (interseccao), em niveis 0..255.
  XOR = pixels opacos em exatamente um / pixels opacos em pelo menos um (uniao), em %.
Par PASS se MAD >= LIMIAR_MAD OU XOR >= LIMIAR_XOR (distinguivel por tom ou por silhueta).

Limiar (fixado antes de rodar, nao ajustado ao resultado):
  LIMIAR_MAD = 10 niveis (~4% da escala; o doc de arte fixa degraus de 25-48 entre as ancoras,
               10 e uma folga bem abaixo disso, ainda visivel a 360 px sem cor).
  LIMIAR_XOR = 5 % (silhueta que muda em 1 de cada 20 pixels e perceptivel como forma).
"""
import hashlib
import os
import sys
from itertools import combinations

from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
REFS = os.path.join(AQUI, "refs")
SAIDA = os.path.join(REFS, "prova-cinza-41.png")

ORDEM = ["amarelo", "verde", "azul", "vermelho"]
ESCALA = 4
MARGEM = 16
FUNDO = 40
CINZA_PLACEHOLDER = 96
LIMIAR_MAD = 10.0
LIMIAR_XOR = 5.0
ALFA_MIN = 128

# fonte 3x5 em pixels para o rotulo do placeholder
GLIFOS = {
    "P": ["111", "101", "111", "100", "100"],
    "E": ["111", "100", "111", "100", "111"],
    "N": ["101", "111", "111", "111", "101"],
    "D": ["110", "101", "101", "101", "110"],
    "T": ["111", "010", "010", "010", "010"],
}


def luma(r, g, b):
    return (299 * r + 587 * g + 114 * b + 500) // 1000


def carregar(nome):
    caminho = os.path.join(REFS, nome)
    if not os.path.exists(caminho):
        return None
    im = Image.open(caminho).convert("RGBA")
    return [(luma(r, g, b), a) for (r, g, b, a) in im.getdata()], im.size


def para_cinza(dados):
    """dados -> imagem LA."""
    px, size = dados
    im = Image.new("LA", size)
    im.putdata([(l, a) for (l, a) in px])
    return im


def par(a, b):
    pa, pb = a[0], b[0]
    soma = n_inter = n_xor = n_uni = 0
    for (la, aa), (lb, ab) in zip(pa, pb):
        oa, ob = aa >= ALFA_MIN, ab >= ALFA_MIN
        if oa or ob:
            n_uni += 1
            if oa and ob:
                n_inter += 1
                soma += abs(la - lb)
            else:
                n_xor += 1
    mad = soma / n_inter if n_inter else 0.0
    xor = 100.0 * n_xor / n_uni if n_uni else 0.0
    return mad, xor


def grupo(titulo, prefixo, ausentes_ok):
    dados = {}
    for cor in ORDEM:
        d = carregar("%s-%s.png" % (prefixo, cor))
        if d is None:
            print("%s %s: PENDENTE" % (prefixo, cor))
        else:
            dados[cor] = d
    falhas = 0
    minimo = None
    print("[%s] pares=%d (MAD>=%.0f OU XOR>=%.0f%%)" % (titulo, len(list(combinations(dados, 2))), LIMIAR_MAD, LIMIAR_XOR))
    for ca, cb in combinations(dados, 2):
        mad, xor = par(dados[ca], dados[cb])
        ok = mad >= LIMIAR_MAD or xor >= LIMIAR_XOR
        falhas += 0 if ok else 1
        # "folga" do par = maior razao entre as duas metricas e seus limiares
        folga = max(mad / LIMIAR_MAD, xor / LIMIAR_XOR)
        minimo = folga if minimo is None else min(minimo, folga)
        print("  %s x %s: MAD=%.2f XOR=%.2f%% -> %s" % (ca, cb, mad, xor, "PASS" if ok else "FAIL"))
    print("  minimo do grupo (folga sobre o limiar, >=1.00 passa): %s | falhas=%d" % (
        "n/a" if minimo is None else "%.2f" % minimo, falhas))
    return dados, falhas


def desenhar_rotulo(im, texto, cx, cy, esc, cor):
    larg = len(texto) * 4 - 1
    x0 = cx - (larg * esc) // 2
    y0 = cy - (5 * esc) // 2
    for i, ch in enumerate(texto):
        for ry, linha in enumerate(GLIFOS[ch]):
            for rx, bit in enumerate(linha):
                if bit == "1":
                    px = x0 + (i * 4 + rx) * esc
                    py = y0 + ry * esc
                    for dy in range(esc):
                        for dx in range(esc):
                            im.putpixel((px + dx, py + dy), cor)


def celula(dados, size, escala):
    """Imagem L ampliada com inteiro (nearest) + mascara."""
    la = para_cinza(dados)
    la = la.resize((size[0] * escala, size[1] * escala), Image.NEAREST)
    return la


def main():
    print("formula: L = (299*R + 587*G + 114*B + 500) // 1000 (Rec.601, inteiro); alfa opaco >= %d" % ALFA_MIN)
    geckos, f1 = grupo("plataformas", "plataforma", False)  # placeholder; reatribuido abaixo
    plats = geckos
    geckos, f2 = grupo("geckos", "gecko", True)
    if "vermelho" not in geckos:
        print("gecko vermelho: PENDENTE")

    gw, gh = 64 * ESCALA, 64 * ESCALA
    pw, ph = 96 * ESCALA, 40 * ESCALA
    largura = MARGEM + 4 * (pw + MARGEM)
    altura = MARGEM + gh + MARGEM + ph + MARGEM
    prancha = Image.new("L", (largura, altura), FUNDO)

    # linha dos geckos (centralizados sobre a coluna de plataforma)
    for i, cor in enumerate(ORDEM):
        x = MARGEM + i * (pw + MARGEM) + (pw - gw) // 2
        y = MARGEM
        if cor in geckos:
            la = celula(geckos[cor], (64, 64), ESCALA)
            prancha.paste(la.getchannel("L"), (x, y), la.getchannel("A").point(lambda a: 255 if a >= ALFA_MIN else 0))
        else:
            prancha.paste(CINZA_PLACEHOLDER, (x, y, x + gw, y + gh))
            desenhar_rotulo(prancha, "PENDENTE", x + gw // 2, y + gh // 2, 3, FUNDO)
    # linha das plataformas
    for i, cor in enumerate(ORDEM):
        x = MARGEM + i * (pw + MARGEM)
        y = MARGEM + gh + MARGEM
        if cor in plats:
            la = celula(plats[cor], (96, 40), ESCALA)
            prancha.paste(la.getchannel("L"), (x, y), la.getchannel("A").point(lambda a: 255 if a >= ALFA_MIN else 0))
        else:
            prancha.paste(CINZA_PLACEHOLDER, (x, y, x + pw, y + ph))
            desenhar_rotulo(prancha, "PENDENTE", x + pw // 2, y + ph // 2, 3, FUNDO)

    prancha.save(SAIDA, format="PNG", optimize=False, compress_level=9)
    with open(SAIDA, "rb") as f:
        h = hashlib.sha256(f.read()).hexdigest()
    print("saida: %s (%dx%d)" % (SAIDA, largura, altura))
    print("sha256: %s" % h)
    return 1 if (f1 or f2) else 0


if __name__ == "__main__":
    sys.exit(main())
