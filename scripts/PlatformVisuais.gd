extends RefCounted

class_name PlatformVisuais

# Fonte unica das texturas das plataformas (peca 96x40 9-sliceavel por cor; a cor e a textura, nao o modulate).
# Sem cena: so o mapa Enums.COLOR -> Texture2D.
const TEXTURAS := {
	Enums.COLOR.AMARELO: preload("res://assets/plataforma-amarelo.png"),
	Enums.COLOR.VERDE: preload("res://assets/plataforma-verde.png"),
	Enums.COLOR.AZUL: preload("res://assets/plataforma-azul.png"),
	Enums.COLOR.VERMELHO: preload("res://assets/plataforma-vermelho.png"),
}


# Textura da cor pedida (cor fora do enum cai no amarelo, a cor inicial)
static func textura(cor: int) -> Texture2D:
	return TEXTURAS.get(cor, TEXTURAS[Enums.COLOR.AMARELO])
