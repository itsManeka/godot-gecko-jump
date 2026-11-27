class_name FundoBiomas
extends RefCounted

# Tabela bioma -> texturas do fundo (f559 T5): 4 biomas (e0..e3), cada um com [ceu, c0, c1, c2].
# O bioma ativo na T5 e sempre 0; a troca por estagio e da T6.

const QUANTIDADE: int = 4
const CEU: int = 0
const CAMADA_0: int = 1
const CAMADA_1: int = 2
const CAMADA_2: int = 3

const TEXTURAS: Array = [
	[
		preload("res://assets/fundo/e0-ceu.png"),
		preload("res://assets/fundo/e0-c0.png"),
		preload("res://assets/fundo/e0-c1.png"),
		preload("res://assets/fundo/e0-c2.png"),
	],
	[
		preload("res://assets/fundo/e1-ceu.png"),
		preload("res://assets/fundo/e1-c0.png"),
		preload("res://assets/fundo/e1-c1.png"),
		preload("res://assets/fundo/e1-c2.png"),
	],
	[
		preload("res://assets/fundo/e2-ceu.png"),
		preload("res://assets/fundo/e2-c0.png"),
		preload("res://assets/fundo/e2-c1.png"),
		preload("res://assets/fundo/e2-c2.png"),
	],
	[
		preload("res://assets/fundo/e3-ceu.png"),
		preload("res://assets/fundo/e3-c0.png"),
		preload("res://assets/fundo/e3-c1.png"),
		preload("res://assets/fundo/e3-c2.png"),
	],
]


# Sprite 8x8 da particula ambiental de cada bioma (f559 T7; provisorio)
const PARTICULAS: Array = [
	preload("res://assets/fundo/e0-particula.png"),
	preload("res://assets/fundo/e1-particula.png"),
	preload("res://assets/fundo/e2-particula.png"),
	preload("res://assets/fundo/e3-particula.png"),
]


# Textura da particula do bioma; indice fora de 0..3 vale o mais proximo
static func particula(bioma: int) -> Texture2D:
	return PARTICULAS[clampi(bioma, 0, QUANTIDADE - 1)]


# [ceu, c0, c1, c2] do bioma; indice fora de 0..3 vale o mais proximo
static func texturas(bioma: int) -> Array:
	return TEXTURAS[clampi(bioma, 0, QUANTIDADE - 1)]
