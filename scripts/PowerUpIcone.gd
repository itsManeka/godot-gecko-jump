class_name PowerUpIcone
extends Node2D

# Icone de power-up sobre a plataforma: Node2D sem colisao, 32x32, centrado na origem. Desenha os mesmos comandos
# do HUD (PowerUpDesenho, fonte unica): fundo preto e forma branca, a pista nunca e so cor.

const TAMANHO_PX: int = 32

var tipo: StringName = &""
var tamanho: Vector2 = Vector2(TAMANHO_PX, TAMANHO_PX)


func _draw() -> void:
	draw_set_transform(retangulo_local().position)
	PowerUpDesenho.desenhar(self, comandos())


# Comandos de desenho do tipo, em coordenadas 32x32 do canto superior esquerdo (iguais aos do HUD)
func comandos() -> Array:
	return PowerUpDesenho.comandos(tipo)


# Area ocupada pelo icone em coordenadas do no (centrada na origem)
func retangulo_local() -> Rect2:
	return Rect2(-tamanho / 2.0, tamanho)
