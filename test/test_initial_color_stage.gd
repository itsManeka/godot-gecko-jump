extends GutTest

# Cena: o gerador estatico inicial (ScrollLevel.tscn) sempre tem uma plataforma com a cor inicial do Player.
const STAGE_SCENE := "res://scenes/Stage.tscn"
const GERADOR_INICIAL := "ScrollLevel/RunningPlatforms/RunningPlatforms"
const INSTANCIAS := 50


func before_each() -> void:
	Global.platforms = []
	Global.iniciado = false


func after_each() -> void:
	Global.platforms = []
	Global.iniciado = false


func _cores_do_gerador(gerador: Node) -> Array:
	var cores: Array = []
	for filho in gerador.get_children():
		if filho is Platform:
			cores.append(filho.color)
	return cores


func test_50_stages_sempre_tem_estatica_com_a_cor_do_player() -> void:
	var sem_cor := 0
	for i in INSTANCIAS:
		var stage: Node = load(STAGE_SCENE).instantiate()
		add_child(stage)
		var player = stage.get_node("Node2D/Player")
		var cores := _cores_do_gerador(stage.get_node(GERADOR_INICIAL))
		assert_eq(cores.size(), 3, "gerador inicial cria 3 estaticas")
		if not cores.has(player.color):
			sem_cor += 1
		stage.free()
	assert_eq(sem_cor, 0, "stages sem estatica da cor do Player")


func test_so_o_gerador_inicial_garante_a_cor() -> void:
	var stage: Node = add_child_autofree(load(STAGE_SCENE).instantiate())
	var com_flag := 0
	for gerador in stage.get_node("ScrollLevel/RunningPlatforms").get_children():
		if gerador.garantir_cor_inicial:
			com_flag += 1
			assert_eq(gerador.name, &"RunningPlatforms", "o flag esta so no gerador inicial")
	assert_eq(com_flag, 1, "um unico gerador com garantir_cor_inicial")

	var novo = load("res://scenes/RunningPlatforms.tscn").instantiate()
	assert_false(novo.garantir_cor_inicial, "default do gerador e false")
	novo.free()

	var scroll_src: String = FileAccess.get_file_as_string("res://scenes/ScrollLevel.gd")
	assert_false(scroll_src.contains("garantir_cor_inicial"), "ScrollLevel.gd nao liga o flag nos geradores novos")


func test_player_color_default_e_a_constante_compartilhada() -> void:
	var player = load("res://scenes/Player.tscn").instantiate()
	assert_eq(player.color, Enums.COR_INICIAL, "Player.color default = Enums.COR_INICIAL")
	player.free()

	var player_src: String = FileAccess.get_file_as_string("res://scenes/Player.gd")
	assert_false(player_src.contains("COLOR.AMARELO"), "Player.gd sem AMARELO literal")
	assert_true(player_src.contains("Enums.COR_INICIAL"), "Player.gd usa Enums.COR_INICIAL")

	var gerador_src: String = FileAccess.get_file_as_string("res://scenes/RunningPlatforms.gd")
	assert_true(gerador_src.contains("Enums.COR_INICIAL"), "gerador usa a mesma constante")
