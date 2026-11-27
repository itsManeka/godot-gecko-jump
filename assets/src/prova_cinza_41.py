# -*- coding: utf-8 -*-
"""Prova em cinza do #41 (acessibilidade sem cor). Uso: python prova_cinza_41.py [--folhas | --plataformas [--saida <png>]]

Com --plataformas le as pecas finais assets/plataforma-<cor>.png (96x40), compoe cada cor nas larguras
120/112/100/88 como o NinePatchRect (pontas 20/20, miolo TILE cortado a direita: x % 56), aplica a mesma
metrica por par em cada largura e checa o topo opaco <= 2 linhas. NAO grava em refs/ (prancha aprovada
intocada): sem --saida so imprime; --saida <caminho> grava a prancha (e recusa refs/). Cor ausente = PENDENTE.

Com --folhas le assets/gecko-<cor>.png (256x384, uma linha por animacao) e compara as 4 cores
quadro a quadro (mesma animacao e indice), com os mesmos limiares; nao grava prancha.

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


ANIMACOES = [("idle", 4), ("run", 4), ("jump", 2), ("fall", 2), ("lose", 3), ("color_change", 3)]
QUADRO = 64
CORPO = ("idle", "run", "jump", "fall", "lose")


def recortar(dados, size, linha, col):
    """Dados (luma, alfa) do quadro (linha, col) de uma folha com quadros QUADRO x QUADRO."""
    px, _ = dados
    larg = size[0]
    x0, y0 = col * QUADRO, linha * QUADRO
    out = []
    for y in range(y0, y0 + QUADRO):
        base = y * larg
        out.extend(px[base + x0 : base + x0 + QUADRO])
    return out, (QUADRO, QUADRO)


def folhas():
    """Modo --folhas: compara as 4 cores quadro a quadro (mesma animacao e indice), mesmos limiares."""
    print("formula: L = (299*R + 587*G + 114*B + 500) // 1000 (Rec.601, inteiro); alfa opaco >= %d" % ALFA_MIN)
    print("[folhas] assets/gecko-<cor>.png (MAD>=%.0f OU XOR>=%.0f%%), par por quadro" % (LIMIAR_MAD, LIMIAR_XOR))
    sheets = {}
    for cor in ORDEM:
        caminho = os.path.join(AQUI, "..", "gecko-%s.png" % cor)
        if not os.path.exists(caminho):
            print("folha %s: PENDENTE" % cor)
            continue
        im = Image.open(caminho).convert("RGBA")
        sheets[cor] = (carregar_im(im), im.size)
    total = falhas = falhas_corpo = 0
    for linha, (nome, n) in enumerate(ANIMACOES):
        for col in range(n):
            quadros = {c: recortar(d, size, linha, col) for c, (d, size) in sheets.items()}
            for ca, cb in combinations(quadros, 2):
                mad, xor = par(quadros[ca], quadros[cb])
                ok = mad >= LIMIAR_MAD or xor >= LIMIAR_XOR
                total += 1
                if not ok:
                    falhas += 1
                    falhas_corpo += 1 if nome in CORPO else 0
                print("  %s[%d] %s x %s: MAD=%.2f XOR=%.2f%% -> %s" % (
                    nome, col, ca, cb, mad, xor, "PASS" if ok else "FAIL"))
    print("pares=%d falhas=%d (corpo idle/run/jump/fall/lose=%d, color_change=%d)" % (
        total, falhas, falhas_corpo, falhas - falhas_corpo))
    return 1 if falhas else 0


def carregar_im(im):
    return [(luma(r, g, b), a) for (r, g, b, a) in im.getdata()], im.size


LARGURAS = [120, 112, 100, 88]
PONTA = 20  # patch_margin_left/right do NinePatchRect
MIOLO = 56  # miolo x 20..75 da peca 96x40, repetido (TILE) a partir da esquerda
ALTURA_PECA = 40
TOPO_MAX = 2  # D3: primeira linha opaca em 0..2


def montar(im, largura):
    """Reproduz o NinePatchRect (pontas 20/20, miolo TILE cortado a direita: x % 56)."""
    m = largura - 2 * PONTA
    out = Image.new("RGBA", (largura, ALTURA_PECA), (0, 0, 0, 0))
    out.paste(im.crop((0, 0, PONTA, ALTURA_PECA)), (0, 0))
    for x in range(m):
        i = x % MIOLO
        out.paste(im.crop((PONTA + i, 0, PONTA + i + 1, ALTURA_PECA)), (PONTA + x, 0))
    out.paste(im.crop((PONTA + MIOLO, 0, PONTA + MIOLO + PONTA, ALTURA_PECA)), (PONTA + m, 0))
    return out


def topo_opaco(im):
    """Indice da primeira linha com alfa >= ALFA_MIN (None se vazia)."""
    larg, alt = im.size
    for y in range(alt):
        for x in range(larg):
            if im.getpixel((x, y))[3] >= ALFA_MIN:
                return y
    return None


def plataformas(saida):
    """Modo --plataformas: le assets/plataforma-<cor>.png (finais), compoe as 4 larguras e mede os pares.

    Nao grava em refs/: a unica gravacao possivel e a prancha de --saida.
    """
    print("formula: L = (299*R + 587*G + 114*B + 500) // 1000 (Rec.601, inteiro); alfa opaco >= %d" % ALFA_MIN)
    print("[plataformas] assets/plataforma-<cor>.png, larguras %s (MAD>=%.0f OU XOR>=%.0f%%)" % (
        "/".join(str(w) for w in LARGURAS), LIMIAR_MAD, LIMIAR_XOR))
    pecas = {}
    falhas = 0
    for cor in ORDEM:
        caminho = os.path.join(AQUI, "..", "plataforma-%s.png" % cor)
        if not os.path.exists(caminho):
            print("plataforma %s: PENDENTE" % cor)
            continue
        im = Image.open(caminho).convert("RGBA")
        if im.size != (PONTA * 2 + MIOLO, ALTURA_PECA):
            print("  %s: tamanho %dx%d, esperado %dx%d -> FAIL" % (
                cor, im.size[0], im.size[1], PONTA * 2 + MIOLO, ALTURA_PECA))
            falhas += 1
            continue
        pecas[cor] = im
        topo = topo_opaco(im)
        ok = topo is not None and topo <= TOPO_MAX
        falhas += 0 if ok else 1
        print("  %s: topo opaco y=%s (<= %d) -> %s" % (cor, topo, TOPO_MAX, "PASS" if ok else "FAIL"))
    total = 0
    celulas = {}
    for w in LARGURAS:
        montadas = {c: montar(im, w) for c, im in pecas.items()}
        celulas[w] = montadas
        dados = {c: carregar_im(m) for c, m in montadas.items()}
        for ca, cb in combinations(dados, 2):
            mad, xor = par(dados[ca], dados[cb])
            ok = mad >= LIMIAR_MAD or xor >= LIMIAR_XOR
            total += 1
            falhas += 0 if ok else 1
            print("  w=%d %s x %s: MAD=%.2f XOR=%.2f%% -> %s" % (w, ca, cb, mad, xor, "PASS" if ok else "FAIL"))
    print("pares=%d falhas=%d" % (total, falhas))
    if saida:
        cores = [c for c in ORDEM if c in pecas]
        altura = MARGEM + len(cores) * (ALTURA_PECA * ESCALA + MARGEM)
        largura = MARGEM + len(LARGURAS) * (max(LARGURAS) * ESCALA + MARGEM)
        prancha = Image.new("L", (largura, altura), FUNDO)
        for r, cor in enumerate(cores):
            for c, w in enumerate(LARGURAS):
                la = para_cinza(carregar_im(celulas[w][cor])).resize((w * ESCALA, ALTURA_PECA * ESCALA), Image.NEAREST)
                prancha.paste(
                    la.getchannel("L"),
                    (MARGEM + c * (max(LARGURAS) * ESCALA + MARGEM), MARGEM + r * (ALTURA_PECA * ESCALA + MARGEM)),
                    la.getchannel("A").point(lambda a: 255 if a >= ALFA_MIN else 0),
                )
        prancha.save(saida, format="PNG", optimize=False, compress_level=9)
        print("saida: %s (%dx%d)" % (saida, largura, altura))
    return 1 if falhas else 0


def main():
    if len(sys.argv) > 1:
        if sys.argv[1] == "--folhas" and len(sys.argv) == 2:
            return folhas()
        if sys.argv[1] == "--plataformas":
            resto = sys.argv[2:]
            if not resto:
                return plataformas(None)
            if len(resto) == 2 and resto[0] == "--saida":
                destino = os.path.abspath(resto[1])
                if os.path.dirname(destino) == os.path.abspath(REFS):
                    print("--saida nao pode gravar em refs/")
                    return 2
                return plataformas(destino)
        print("uso: python prova_cinza_41.py [--folhas | --plataformas [--saida <caminho.png>]]")
        return 2
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
