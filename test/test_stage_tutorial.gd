extends GutTest

# Stage abre/fecha o card do tutorial e grava a flag "visto". O store da flag e um de caminho temporario
# (Global.opcoes trocado por teste e restaurado depois); nenhum teste toca user://options.cfg real.
const STAGE_SCENE := "res://scenes/Stage.tscn"
const TEST_PATH := "user://test_stage_tutorial.cfg"

var _opcoes_anteriores: OptionsStore = null


func before_each() -> void:
	_limpar()
	_opcoes_anteriores = Global.opcoes
	Global.usar_options_store(OptionsStore.new(TEST_PATH))
	Global.tutorial_visto_espelho = false
	Global.toque_detectado = false
	Global.platforms = []
	Global.iniciado = false


func after_each() -> void:
	get_tree().paused = false
	Global.usar_options_store(_opcoes_anteriores)
	Global.tutorial_visto_espelho = false
	Global.toque_detectado = false
	Global.platforms = []
	Global.iniciado = false
	_limpar()


func _limpar() -> void:
	for p in [TEST_PATH, TEST_PATH + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


func _novo_stage() -> Node:
	var stage: Node = add_child_autofree(load(STAGE_SCENE).instantiate())
	await wait_frames(2)
	return stage


func _visto_no_cfg() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(TEST_PATH) != OK:
		return false
	return cfg.get_value("tutorial", "visto", false) == true


func _perder(stage: Node) -> void:
	var player = stage.get_node("Node2D/Player")
	player.jumping = false
	stage._on_CheckPlayer_body_exited(player)


func test_c203_sem_flag_iniciar_abre_card_e_partida_ja_iniciada() -> void:
	var stage := await _novo_stage()
	assert_false(stage.tutorial_card.esta_aberto(), "no menu o card nao esta aberto")
	stage._on_Play_button_down()
	assert_true(stage.tutorial_card.esta_aberto(), "sem flag o card abre ao iniciar")
	assert_true(stage.tutorial_card.visible, "card visivel")
	assert_true(Global.is_iniciado(), "partida iniciada no mesmo frame, sem esperar o card")


func test_c203_pausa_funciona_com_card_aberto() -> void:
	var stage := await _novo_stage()
	stage._on_Play_button_down()
	assert_true(stage.tutorial_card.esta_aberto())
	assert_true(stage._pausar(), "_pausar() funciona com o card aberto")
	assert_true(get_tree().paused, "arvore pausada")
	assert_true(stage.tutorial_card.esta_aberto(), "pausar nao fecha o card")
	assert_false(_visto_no_cfg(), "pausar nao grava a flag")


func test_c204_pular_fecha_grava_e_stage_nova_nao_abre() -> void:
	var stage := await _novo_stage()
	stage._on_Play_button_down()
	stage.tutorial_card.pular.emit()
	assert_false(stage.tutorial_card.esta_aberto(), "Pular fecha o card")
	assert_true(_visto_no_cfg(), "Pular grava tutorial/visto=true")
	Global.tutorial_visto_espelho = false
	remove_child(stage)
	stage.free()
	var nova := await _novo_stage()
	nova._on_Play_button_down()
	assert_false(nova.tutorial_card.esta_aberto(), "Stage nova nao abre o card com a flag gravada")
	assert_false(nova.tutorial_card.visible, "card da Stage nova nao aparece")


func test_c205_primeiro_ponto_fecha_grava_e_segundo_nao_regrava() -> void:
	var stage := await _novo_stage()
	stage._on_Play_button_down()
	assert_eq(stage.points, -1)
	stage.player.add_point.emit()
	assert_eq(stage.points, 0, "1o ponto: points -1 -> 0")
	assert_false(stage.tutorial_card.esta_aberto(), "1o ponto fecha o card")
	assert_true(_visto_no_cfg(), "1o ponto grava a flag")
	_limpar()
	Global.tutorial_visto_espelho = false
	stage.player.add_point.emit()
	assert_eq(stage.points, 1)
	assert_false(stage.tutorial_card.esta_aberto(), "2o ponto nao reabre o card")
	assert_false(_visto_no_cfg(), "2o ponto nao regrava a flag")


func test_c206_derrota_com_card_aberto_nao_grava_e_stage_seguinte_abre() -> void:
	var stage := await _novo_stage()
	stage._on_Play_button_down()
	assert_true(stage.tutorial_card.esta_aberto())
	_perder(stage)
	assert_false(_visto_no_cfg(), "derrota nao grava a flag no cfg")
	assert_false(Global.tutorial_visto_espelho, "derrota nao liga o espelho")
	remove_child(stage)
	stage.free()
	var nova := await _novo_stage()
	nova._on_Play_button_down()
	assert_true(nova.tutorial_card.esta_aberto(), "Stage seguinte abre o card de novo")


func test_c207_flag_corrompida_abre_card_sem_crash() -> void:
	var f := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	f.store_string("@@ nao e cfg")
	f.close()
	var stage := await _novo_stage()
	stage._on_Play_button_down()
	assert_true(stage.tutorial_card.esta_aberto(), "flag corrompida = nao vista: o card abre")


func test_c207_flag_gravada_nenhum_card_aberto() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("tutorial", "visto", true)
	cfg.save(TEST_PATH)
	var stage := await _novo_stage()
	stage._on_Play_button_down()
	assert_false(stage.tutorial_card.esta_aberto(), "flag gravada: card nao abre")
	assert_false(stage.tutorial_card.visible, "flag gravada: card nao aparece")


func test_c208_card_oculto_no_menu_e_na_derrota() -> void:
	var stage := await _novo_stage()
	assert_false(stage.tutorial_card.visible, "oculto no menu")
	stage._on_Play_button_down()
	assert_true(stage.tutorial_card.visible)
	_perder(stage)
	assert_false(stage.tutorial_card.visible, "oculto na animacao de derrota")
	assert_false(stage.tutorial_card.esta_aberto())


func test_c209_variante_teclado_sem_toque() -> void:
	var stage := await _novo_stage()
	stage.touchscreen_disponivel = func() -> bool: return false
	stage._on_Play_button_down()
	assert_eq(stage.tutorial_card.variante(), TutorialCard.Variante.TECLADO)


func test_c209_variante_toque_com_toque_detectado() -> void:
	Global.toque_detectado = true
	var stage := await _novo_stage()
	stage.touchscreen_disponivel = func() -> bool: return false
	stage._on_Play_button_down()
	assert_eq(stage.tutorial_card.variante(), TutorialCard.Variante.TOQUE)


func test_c209_variante_toque_com_touchscreen_disponivel() -> void:
	var stage := await _novo_stage()
	stage.touchscreen_disponivel = func() -> bool: return true
	stage._on_Play_button_down()
	assert_eq(stage.tutorial_card.variante(), TutorialCard.Variante.TOQUE)


func test_c209_ponte_publica_tutorial_aberto_e_fechado() -> void:
	var stage := await _novo_stage()
	assert_eq(stage.ultimo_estado["tutorial"], "fechado", "menu: fechado")
	stage._on_Play_button_down()
	assert_eq(stage.ultimo_estado["tutorial"], "aberto", "partida iniciada sem flag: aberto")
	stage.tutorial_card.pular.emit()
	assert_eq(stage.ultimo_estado["tutorial"], "fechado", "apos Pular: fechado")
