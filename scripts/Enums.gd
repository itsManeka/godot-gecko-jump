extends Node

class_name Enums

enum COLOR {AMARELO, VERDE, AZUL, VERMELHO}

enum PLATFORM_TYPE {STATIC, MOVE_TO_LEFT, MOVE_TO_RIGHT, RANDOM_ALL, RANDON_DIRECTION}

static func get_cor(color) -> Color:
	match color:
		COLOR.AMARELO:
			return Color("#f6db61")
		COLOR.VERDE:
			return Color("#79cf5a")
		COLOR.AZUL:
			return Color("#5987e9")
		COLOR.VERMELHO:
			return Color("#ec4848")
	return Color("#ffffff")

static func get_random_color():
	return COLOR.values()[randi()%COLOR.size()]
