class_name PowerUpIcone
extends Node2D

# Icone de power-up sobre a plataforma: Node2D sem colisao, 16x16, branco com contorno preto de 1 px.
# Placeholder gerado em codigo: a forma (quadrado, losango ou triangulo) deriva do nome do tipo, entao a pista
# nunca e so cor.

const TAMANHO_PX: int = 16
const CONTORNO_PX: int = 1
const FORMAS: int = 3

var tipo: StringName = &""
var tamanho: Vector2 = Vector2(TAMANHO_PX, TAMANHO_PX)


func _draw() -> void:
	var forma: int = int(String(tipo).hash() % FORMAS)
	draw_colored_polygon(_poligono(forma, TAMANHO_PX / 2.0), UiHelpers.COR_CONTORNO)
	draw_colored_polygon(_poligono(forma, TAMANHO_PX / 2.0 - CONTORNO_PX), UiHelpers.COR_TEXTO)


# Vertices da forma centrada na origem; `meio` e a meia-largura
func _poligono(forma: int, meio: float) -> PackedVector2Array:
	match forma:
		0:
			return PackedVector2Array(
				[Vector2(-meio, -meio), Vector2(meio, -meio), Vector2(meio, meio), Vector2(-meio, meio)]
			)
		1:
			return PackedVector2Array([Vector2(0, -meio), Vector2(meio, 0), Vector2(0, meio), Vector2(-meio, 0)])
		_:
			return PackedVector2Array([Vector2(0, -meio), Vector2(meio, meio), Vector2(-meio, meio)])
