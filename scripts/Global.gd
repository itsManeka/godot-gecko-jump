extends Node

var platforms = []
var iniciado : bool = false
var bestscore : int = 0
var lastscore : int = 0

func _ready():
	randomize()

func add_platform(platform: Platform):
	platforms.append(platform)

func player_color_changed(player_color, actual_platform: Platform):
	for platform in platforms:
		if platform != actual_platform:
			platform = platform as Platform
			if platform:
				platform.player_color_changed(player_color)

func att_actual_platform(player_color, actual_platform):
	platforms[platforms.find(actual_platform, 0)].player_color_changed(player_color)

func remove_platform(platform):
	platforms.remove(platforms.find(platform, 0))

func set_iniciado(b: bool):
	iniciado = b

func is_iniciado() -> bool:
	return iniciado

func set_score(score):
	lastscore = score
	if lastscore > bestscore:
		bestscore = lastscore

func get_last_score() -> int:
	return lastscore

func get_best_score() -> int:
	return bestscore
