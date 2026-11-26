class_name PowerUpDesenho
extends RefCounted

# Fonte unica do desenho do icone de power-up (plataforma e HUD usam a mesma lista de comandos). Coordenadas
# locais 32x32 (origem no canto superior esquerdo): fundo preto e forma branca, nunca cor de plataforma.
# Camaleao = 4 quadrantes; Desacelera = ampulheta (2 triangulos); Segunda chance = cruz (slot da carga).
# Tipo sem forma propria (ex.: fakes de teste) ganha um glifo 4x4 derivado do nome, estavel entre chamadas.
# Comando: {"forma": &"rect", "rect", "cor"} ou {"forma": &"poly", "pontos", "cor"}.

const TAM: float = 32.0
const COR_BRANCO: Color = UiHelpers.COR_TEXTO
const COR_PRETO: Color = UiHelpers.COR_CONTORNO


static func comandos(nome: StringName) -> Array:
	var fundo: Dictionary = _rect(Rect2(0.0, 0.0, TAM, TAM), COR_PRETO)
	match nome:
		&"camaleao":
			return [
				fundo,
				_rect(Rect2(2.0, 2.0, 12.0, 12.0), COR_BRANCO),
				_rect(Rect2(18.0, 2.0, 12.0, 12.0), COR_BRANCO),
				_rect(Rect2(2.0, 18.0, 12.0, 12.0), COR_BRANCO),
				_rect(Rect2(18.0, 18.0, 12.0, 12.0), COR_BRANCO),
			]
		&"desacelera":
			return [
				fundo,
				_poly(PackedVector2Array([Vector2(6, 2), Vector2(26, 2), Vector2(16, 16)]), COR_BRANCO),
				_poly(PackedVector2Array([Vector2(16, 16), Vector2(6, 30), Vector2(26, 30)]), COR_BRANCO),
			]
		&"segunda_chance":
			return [
				fundo,
				_rect(Rect2(12.0, 4.0, 8.0, 24.0), COR_BRANCO),
				_rect(Rect2(4.0, 12.0, 24.0, 8.0), COR_BRANCO),
			]
	var bits: int = nome.hash() & 0xFFFF
	if bits == 0:
		bits = 1
	var lista: Array = [fundo]
	for i in 16:
		if (bits >> i) & 1 == 1:
			lista.append(_rect(Rect2(4.0 + (i & 3) * 6.0, 4.0 + (i >> 2) * 6.0, 6.0, 6.0), COR_BRANCO))
	return lista


# Executa a lista de comandos num CanvasItem (dentro do seu _draw)
static func desenhar(alvo: CanvasItem, lista: Array) -> void:
	for c: Dictionary in lista:
		if c["forma"] == &"poly":
			alvo.draw_colored_polygon(c["pontos"], c["cor"])
		else:
			alvo.draw_rect(c["rect"], c["cor"])


static func _rect(r: Rect2, cor: Color) -> Dictionary:
	return {"forma": &"rect", "rect": r, "cor": cor}


static func _poly(pontos: PackedVector2Array, cor: Color) -> Dictionary:
	return {"forma": &"poly", "pontos": pontos, "cor": cor}
