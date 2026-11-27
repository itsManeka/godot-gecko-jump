extends RefCounted

class_name PlatformVisuais

# Fonte unica das texturas das plataformas (peca 96x40 9-sliceavel por cor; a cor e a textura, nao o modulate).
# Sem cena: so o mapa Enums.COLOR -> Texture2D, as rachaduras (overlay 96x40 por estagio) e o atlas de pedacos.
const TEXTURAS := {
	Enums.COLOR.AMARELO: preload("res://assets/plataforma-amarelo.png"),
	Enums.COLOR.VERDE: preload("res://assets/plataforma-verde.png"),
	Enums.COLOR.AZUL: preload("res://assets/plataforma-azul.png"),
	Enums.COLOR.VERMELHO: preload("res://assets/plataforma-vermelho.png"),
}

# Estagio de rachadura (1..3) -> overlay transparente; estagio 0 = sem textura
const RACHADURAS := {
	1: preload("res://assets/plataforma-rachadura-1.png"),
	2: preload("res://assets/plataforma-rachadura-2.png"),
	3: preload("res://assets/plataforma-rachadura-3.png"),
}

# Atlas 64x12 dos pedacos do desmoronamento (celulas 8x6)
const PEDACOS: Texture2D = preload("res://assets/plataforma-pedacos.png")


# Textura da cor pedida (cor fora do enum cai no amarelo, a cor inicial)
static func textura(cor: int) -> Texture2D:
	return TEXTURAS.get(cor, TEXTURAS[Enums.COLOR.AMARELO])


# Overlay do estagio de rachadura (fora de 1..3 = null: sem rachadura)
static func rachadura(estagio: int) -> Texture2D:
	return RACHADURAS.get(estagio, null)
