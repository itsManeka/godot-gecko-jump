extends Node

class_name Enums

# Enums e funções utilitárias para cores e tipos de plataforma

# Enumeração das cores disponíveis no jogo
enum COLOR {AMARELO, VERDE, AZUL, VERMELHO}

# Enumeração dos tipos de comportamento das plataformas
enum PLATFORM_TYPE {
	STATIC,             # Plataformas estáticas (não se movem)
	MOVE_TO_LEFT,       # Plataformas que se movem para a esquerda
	MOVE_TO_RIGHT,      # Plataformas que se movem para a direita
	RANDOM_ALL,         # Escolhe aleatoriamente entre todos os tipos
	RANDOM_DIRECTION    # Escolhe aleatoriamente apenas entre direções (esquerda/direita)
}

# Retorna a cor RGB correspondente ao enum de cor
static func get_cor(color) -> Color:
	match color:
		COLOR.AMARELO:
			return Color("#f6db61")  # Amarelo
		COLOR.VERDE:
			return Color("#79cf5a")  # Verde
		COLOR.AZUL:
			return Color("#5987e9")  # Azul
		COLOR.VERMELHO:
			return Color("#ec4848")  # Vermelho
	return Color("#ffffff")  # Branco como fallback

# Retorna uma cor aleatória do enum COLOR
static func get_random_color():
	return COLOR.values()[randi() % COLOR.size()]
