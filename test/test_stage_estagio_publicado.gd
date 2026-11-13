extends GutTest

# Stage publica dificuldade.estagio na ponte e republica quando o estagio muda por tempo (C226-C230). Ticks fisicos
# a mao (_physics_process); o progresso inicial entra por Global.progresso_inicial, restaurado em after_each.
# Sem JavaScriptBridge: le Stage.ultimo_estado. Cada publicacao cria um Dictionary novo, entao is_same conta republicacoes.
const STAGE_SCENE := "res://scenes/Stage.tscn"
# Soma 2.0 s (> 1.8 s: 0.34 + 1.8/180 cairia exatamente na fronteira 0.35)
const TICK := 0.5
const TICKS_ATE_ESTAGIO_1 := 4


func before_each() -> void:
	Global.tutorial_visto_espelho = true
	Global.set_iniciado(false)
	Global.progresso_inicial = 0.0


func after_each() -> void:
	Global.set_iniciado(false)
	Global.progresso_inicial = 0.0


func _stage() -> Node:
	return add_child_autofree(load(STAGE_SCENE).instantiate())


func _estagio_publicado(stage: Node) -> int:
	return int((stage.ultimo_estado["dificuldade"] as Dictionary)["estagio"])


func test_menu_publica_estagio_zero() -> void:
	var stage = _stage()
	assert_eq(_estagio_publicado(stage), 0, "menu publica estagio 0")
	assert_eq(stage.ultimo_estado["state"], "menu", "estado de menu")


func test_estagio_republicado_quando_o_tempo_muda_de_estagio() -> void:
	Global.progresso_inicial = 0.34
	var stage = _stage()
	stage._on_Play_button_down()
	assert_eq(_estagio_publicado(stage), 0, "0.34 ainda e estagio 0 no Play")
	for i in TICKS_ATE_ESTAGIO_1:
		stage._physics_process(TICK)
	assert_eq(_estagio_publicado(stage), 1, "estagio 1 publicado so pelo tempo")
	assert_eq(stage.ultimo_estado["state"], "playing", "segue playing")


func test_republica_uma_vez_por_mudanca_e_nao_por_frame() -> void:
	Global.progresso_inicial = 0.34
	var stage = _stage()
	stage._on_Play_button_down()
	for i in TICKS_ATE_ESTAGIO_1:
		stage._physics_process(TICK)
	assert_eq(_estagio_publicado(stage), 1, "ja no estagio 1")
	var anterior: Dictionary = stage.ultimo_estado
	var republicacoes := 0
	for i in 60:
		stage._physics_process(1.0 / 60.0)
		if not is_same(stage.ultimo_estado, anterior):
			republicacoes += 1
			anterior = stage.ultimo_estado
	assert_eq(republicacoes, 0, "sem nova mudanca de estagio, nenhuma republicacao em 60 ticks")
	# 1x por mudanca: um tick que cruza a fronteira republica exatamente uma vez
	Global.set_iniciado(true)
	var estado_antes: Dictionary = stage.ultimo_estado
	stage.dificuldade.progresso_inicial = 0.7
	stage._physics_process(TICK)
	assert_false(is_same(stage.ultimo_estado, estado_antes), "mudanca republica")
	assert_eq(_estagio_publicado(stage), 2, "estagio 2")
	var depois: Dictionary = stage.ultimo_estado
	for i in 60:
		stage._physics_process(1.0 / 60.0)
	assert_true(is_same(stage.ultimo_estado, depois), "60 ticks pos-mudanca nao republicam")


func test_nao_republica_apos_derrota() -> void:
	Global.progresso_inicial = 0.34
	var stage = _stage()
	stage._on_Play_button_down()
	stage._publicar_estado(GameState.STATE_LOST, false)
	for i in TICKS_ATE_ESTAGIO_1:
		stage._physics_process(TICK)
	assert_eq(stage.ultimo_estado["state"], "lost", "estado publicado segue lost")
	assert_eq(_estagio_publicado(stage), 0, "estagio nao regrava apos a derrota")


func test_stage_nova_volta_ao_estagio_do_progresso_inicial() -> void:
	Global.progresso_inicial = 0.34
	var antiga = _stage()
	antiga._on_Play_button_down()
	for i in TICKS_ATE_ESTAGIO_1:
		antiga._physics_process(TICK)
	assert_eq(_estagio_publicado(antiga), 1, "partida antiga subiu")
	var nova = _stage()
	assert_eq(_estagio_publicado(nova), 0, "reload volta a estagio(progresso_inicial)")
	assert_false(Global.is_iniciado(), "reload nao herda partida iniciada")
