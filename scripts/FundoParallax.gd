class_name FundoParallax
extends RefCounted

# Regra pura do parallax do fundo (f559 T5), sem cena: fator por camada, offset com wrap na altura da PROPRIA textura
# e contagem de tiles. A altura da textura sempre vem de quem chama (get_height()); nada aqui fixa 960/1200/1440.
# O ceu nao entra aqui: fica preso ao topo da tela (fator 0, sem offset, sem repeticao).

# Fator de cada camada c0, c1, c2 (fracao do scroll acumulado)
const FATORES: Array[float] = [0.05, 0.15, 0.30]


# Offset da camada em [0, altura_tex): scroll acumulado x fator, com wrap. Scroll negativo ou textura sem altura = 0
# (o offset nunca volta para tras nem enrola para valor negativo).
static func offset(scroll_acumulado: float, fator: float, altura_tex: float) -> float:
	if altura_tex <= 0.0:
		return 0.0
	return fposmod(maxf(scroll_acumulado, 0.0) * fator, altura_tex)


# Tiles por camada para cobrir [0, altura_tela] em qualquer offset: ceil(H_tela / H_tex) + 1
static func quantidade_tiles(altura_tela: float, altura_tex: float) -> int:
	if altura_tex <= 0.0:
		return 0
	return ceili(altura_tela / altura_tex) + 1


# y do tile `indice` (0..n-1): o offset arredondado para inteiro, com o 1o tile uma altura acima (cobre o topo)
static func y_do_tile(offset_camada: float, altura_tex: float, indice: int) -> float:
	return roundf(offset_camada) + float(indice - 1) * altura_tex
