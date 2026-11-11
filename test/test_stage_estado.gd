extends GutTest

# Stage publica o estado da ponte do smoke (GameState) nas transicoes: menu, playing, lost.
const STAGE_SCENE := "res://scenes/Stage.tscn"


func before_each() -> void:
	Global.platforms = []
	Global.iniciado = false


func after_each() -> void:
	Global.platforms = []
	Global.iniciado = false


func _novo_stage() -> Node:
	var stage: Node = add_child_autofree(load(STAGE_SCENE).instantiate())
	await wait_frames(2)
	return stage


func test_ready_publica_menu_com_score_zero_e_vivo() -> void:
	var stage := await _novo_stage()
	var e: Dictionary = stage.ultimo_estado
	assert_eq(e["state"], "menu", "estado inicial deve ser menu")
	assert_eq(e["score"], 0, "score inicial deve ser 0")
	assert_true(e["player"]["alive"], "player deve estar vivo no menu")


func test_queda_publica_lost_e_alive_false_no_mesmo_instante() -> void:
	var stage := await _novo_stage()
	stage._on_Play_button_down()
	var player = stage.get_node("Node2D/Player")
	player.jumping = false
	stage._on_CheckPlayer_body_exited(player)
	var e: Dictionary = stage.ultimo_estado
	assert_eq(e["state"], "lost", "queda deve publicar state lost sem esperar a animacao")
	assert_false(e["player"]["alive"], "queda deve publicar alive false sem esperar a animacao")


func test_add_point_tardio_depois_de_lost_nao_volta_a_playing() -> void:
	var stage := await _novo_stage()
	stage._on_Play_button_down()
	var player = stage.get_node("Node2D/Player")
	player.jumping = false
	stage._on_CheckPlayer_body_exited(player)
	stage.add_point()
	var e: Dictionary = stage.ultimo_estado
	assert_eq(e["state"], "lost", "add_point tardio nao pode regredir o estado publicado de lost")
	assert_false(e["player"]["alive"], "add_point tardio nao pode ressuscitar o player publicado")


func test_pouso_sobe_score_exatamente_1_e_state_playing() -> void:
	# Chama add_point() direto; o caminho real do pouso (sinal do Player) e coberto em
	# test/test_modo_sem_derrota_plataformas.gd (integracao com Stage real).
	var stage := await _novo_stage()
	stage._on_Play_button_down()
	stage.add_point()
	var antes: int = stage.ultimo_estado["score"]
	stage.add_point()
	var e: Dictionary = stage.ultimo_estado
	assert_eq(e["score"], antes + 1, "pouso deve subir o score exatamente 1")
	assert_eq(e["state"], "playing", "pouso deve manter state playing")


func test_recarga_volta_a_menu_com_score_zero_e_best_preservado() -> void:
	var stage := await _novo_stage()
	stage._on_Play_button_down()
	stage.add_point()
	stage.add_point()
	stage.add_point()
	Global.set_score(stage.points)
	var best: int = Global.get_best_score()
	remove_child(stage)
	stage.free()
	var nova := await _novo_stage()
	var e: Dictionary = nova.ultimo_estado
	assert_eq(e["state"], "menu", "recarga deve voltar a menu")
	assert_eq(e["score"], 0, "recarga deve zerar o score")
	assert_true(e["player"]["alive"], "recarga deve ter player vivo")
	assert_eq(e["best"], best, "recarga deve preservar o best")
