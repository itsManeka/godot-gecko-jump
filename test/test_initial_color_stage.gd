extends GutTest

# Cena: o gerador estatico inicial (ScrollLevel.tscn) sempre tem uma plataforma com a cor inicial do Player.
const STAGE_SCENE := "res://scenes/Stage.tscn"
const GERADOR_INICIAL := "ScrollLevel/RunningPlatforms/RunningPlatforms"
const INSTANCIAS := 50


func before_each() -> void:
	Global.tutorial_visto_espelho = true
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
		# autofree garante a liberacao mesmo se um assert abortar o teste; queue_free solta a Stage ja nesta volta.
		var stage: Node = add_child_autofree(load(STAGE_SCENE).instantiate())
		var player = stage.get_node("Node2D/Player")
		var cores := _cores_do_gerador(stage.get_node(GERADOR_INICIAL))
		assert_eq(cores.size(), 3, "gerador inicial cria 3 estaticas")
		if not cores.has(player.color):
			sem_cor += 1
		stage.queue_free()
	assert_eq(sem_cor, 0, "stages sem estatica da cor do Player")


func test_so_o_gerador_inicial_garante_a_cor() -> void:
	var stage: Node = add_child_autofree(load(STAGE_SCENE).instantiate())
	var com_flag := 0
	for gerador in stage.get_node("ScrollLevel/RunningPlatforms").get_children():
		if gerador.garantir_cor_inicial:
			com_flag += 1
			assert_eq(gerador.name, &"RunningPlatforms", "o flag esta so no gerador inicial")
	assert_eq(com_flag, 1, "um unico gerador com garantir_cor_inicial")

	# Gerador criado pelo proprio ScrollLevel (create_new_running_platform, como ScrollLevel.gd:6 o instancia).
	var scroll: Node = stage.get_node("ScrollLevel")
	var antes: int = stage.get_node("ScrollLevel/RunningPlatforms").get_child_count()
	scroll.create_new_running_platform()
	await wait_frames(2)
	var geradores: Array = stage.get_node("ScrollLevel/RunningPlatforms").get_children()
	assert_gt(geradores.size(), antes, "o ScrollLevel criou um gerador novo")
	com_flag = 0
	for gerador in geradores:
		if gerador.garantir_cor_inicial:
			com_flag += 1
	assert_eq(com_flag, 1, "gerador novo do ScrollLevel segue aleatorio: o flag continua so no inicial")
	assert_false(geradores[-1].garantir_cor_inicial, "gerador criado pelo ScrollLevel tem garantir_cor_inicial=false")


func test_player_color_default_e_a_constante_compartilhada() -> void:
	var player = autofree(load("res://scenes/Player.tscn").instantiate())
	assert_eq(player.color, Enums.COR_INICIAL, "Player.color default = Enums.COR_INICIAL")

	# O gerador inicial usa a mesma constante: a estatica garantida tem a cor do Player recem-criado.
	var stage: Node = add_child_autofree(load(STAGE_SCENE).instantiate())
	var stage_player = stage.get_node("Node2D/Player")
	assert_eq(stage_player.color, Enums.COR_INICIAL, "Player da Stage nasce com Enums.COR_INICIAL")
	var cores := _cores_do_gerador(stage.get_node(GERADOR_INICIAL))
	assert_true(cores.has(Enums.COR_INICIAL), "gerador inicial garante estatica com Enums.COR_INICIAL")
