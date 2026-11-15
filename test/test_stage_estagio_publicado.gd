extends GutTest

# Stage publica dificuldade.estagio na ponte e republica quando o estagio muda por tempo (C226-C230). Ticks fisicos
# a mao (_physics_process); o progresso inicial entra por Global.progresso_inicial, restaurado em after_each.
# Sem JavaScriptBridge: le Stage.ultimo_estado. Cada publicacao cria um Dictionary novo, entao is_same conta republicacoes.
const STAGE_SCENE := "res://scenes/Stage.tscn"
# Soma 2.0 s (> 1.8 s: 0.34 + 1.8/180 cairia exatamente na fronteira 0.35)
const TICK := 0.5
const TICKS_ATE_ESTAGIO_1 := 4



# Moldura espia: registra os pulsos pedidos (estagio novo) e as interrupcoes; o resto e o LevelUpFrame real
class SpyFrame:
	extends LevelUpFrame
	var pulsos: Array[int] = []
	var interrupcoes: int = 0

	func pulsar(n: int) -> void:
		pulsos.append(n)
		super.pulsar(n)

	func interromper() -> void:
		interrupcoes += 1
		super.interromper()


# Corpo falso do CheckPlayer: nao pulando e nao terminado = derrota
class SpyBody:
	extends Node
	var perdeu: bool = false

	func is_jumping() -> bool:
		return false

	func is_end() -> bool:
		return false

	func lose_game() -> void:
		perdeu = true


func before_each() -> void:
	Global.tutorial_visto_espelho = true
	Global.set_iniciado(false)
	Global.progresso_inicial = 0.0


func after_each() -> void:
	Global.set_iniciado(false)
	Global.progresso_inicial = 0.0


func _stage() -> Node:
	return add_child_autofree(load(STAGE_SCENE).instantiate())


func _stage_com_espiao() -> Node:
	var stage: Node = _stage()
	var spy := SpyFrame.new()
	stage.add_child(spy)
	stage.level_up_frame = spy
	return stage


func _aviso_publicado(stage: Node) -> bool:
	return bool((stage.ultimo_estado["dificuldade"] as Dictionary)["aviso"])


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


func test_subida_de_estagio_pulsa_a_moldura_com_o_estagio_novo_nas_tres_subidas() -> void:
	Global.progresso_inicial = 0.34
	var stage = _stage_com_espiao()
	stage._on_Play_button_down()
	for i in TICKS_ATE_ESTAGIO_1:
		stage._physics_process(TICK)
	stage.dificuldade.progresso_inicial = 0.7
	stage._physics_process(TICK)
	stage.dificuldade.progresso_inicial = 1.0
	stage._physics_process(TICK)
	assert_eq(stage.dificuldade.estagio(), 3, "chegou ao estagio 3")
	assert_eq(stage.level_up_frame.pulsos.size(), 3, "uma chamada de pulsar por subida")
	assert_eq(stage.level_up_frame.pulsos[0], 1, "1a subida pulsa o estagio 1")
	assert_eq(stage.level_up_frame.pulsos[1], 2, "2a subida pulsa o estagio 2")
	assert_eq(stage.level_up_frame.pulsos[2], 3, "3a subida pulsa o estagio 3")
	assert_true(stage.level_up_frame.pulsando(), "moldura pulsando")


func test_sem_pulso_no_inicio_da_partida_estagio_zero_e_progresso_inicial_alto() -> void:
	var zero = _stage_com_espiao()
	zero._on_Play_button_down()
	for i in 5:
		zero._physics_process(0.01)
	assert_eq(zero.level_up_frame.pulsos.size(), 0, "estagio 0 ao dar Play nao pulsa")
	assert_false(zero.level_up_frame.pulsando(), "estagio 0: moldura apagada")
	Global.set_iniciado(false)
	Global.progresso_inicial = 0.9
	var alto = _stage_com_espiao()
	alto._on_Play_button_down()
	for i in 5:
		alto._physics_process(0.01)
	assert_gt(alto.dificuldade.estagio(), 0, "a partida nasce num estagio alto")
	assert_eq(alto.level_up_frame.pulsos.size(), 0, "progresso_inicial alto ao dar Play nao pulsa")
	assert_false(alto.level_up_frame.pulsando(), "progresso alto: moldura apagada")


func test_derrota_interrompe_o_pulso_e_subida_depois_da_derrota_nao_pulsa() -> void:
	Global.progresso_inicial = 0.34
	var stage = _stage_com_espiao()
	stage._on_Play_button_down()
	for i in TICKS_ATE_ESTAGIO_1:
		stage._physics_process(TICK)
	assert_true(stage.level_up_frame.pulsando(), "pulso em curso antes da derrota")
	var corpo := SpyBody.new()
	add_child_autofree(corpo)
	stage._on_CheckPlayer_body_exited(corpo)
	assert_true(corpo.perdeu, "derrota aplicada")
	assert_gt(stage.level_up_frame.interrupcoes, 0, "derrota interrompe a moldura")
	assert_false(stage.level_up_frame.pulsando(), "moldura apagada apos a derrota")
	assert_false(stage.level_up_frame.visible, "moldura invisivel apos a derrota")
	stage.dificuldade.progresso_inicial = 0.7
	stage._physics_process(TICK)
	assert_eq(stage.dificuldade.estagio(), 2, "o estagio subiu depois da derrota")
	assert_eq(stage.level_up_frame.pulsos, [1] as Array[int], "subida depois de STATE_LOST nao pulsa")
	assert_false(stage.level_up_frame.pulsando(), "segue apagada")


func test_reload_da_stage_recria_a_moldura_zerada() -> void:
	Global.progresso_inicial = 0.34
	var antiga = _stage()
	antiga._on_Play_button_down()
	for i in TICKS_ATE_ESTAGIO_1:
		antiga._physics_process(TICK)
	assert_true(antiga.level_up_frame.pulsando(), "partida antiga pulsando")
	Global.progresso_inicial = 0.0
	var nova = _stage()
	assert_ne(nova.level_up_frame, antiga.level_up_frame, "moldura propria")
	assert_eq(nova.dificuldade.estagio(), 0, "estagio 0")
	assert_false(nova.level_up_frame.visible, "moldura invisivel")
	assert_eq(nova.level_up_frame.alpha(), 0.0, "alpha 0")
	assert_false(nova.level_up_frame.pulsando(), "sem pulso herdado")


func test_ordem_de_desenho_moldura_abaixo_do_hud_e_da_pausa_acima_do_jogo() -> void:
	var stage = _stage()
	var hud: CanvasLayer = stage.get_node("CanvasLayer")
	var moldura: LevelUpFrame = stage.level_up_frame
	assert_eq(moldura.layer, LevelUpFrame.CAMADA, "layer da moldura = CAMADA")
	assert_lt(moldura.layer, hud.layer, "moldura abaixo do HUD")
	assert_lt(moldura.layer, stage.pause_overlay.layer, "moldura abaixo da pausa")
	var jogo: Node = stage.get_node("Node2D")
	assert_null(jogo.get_canvas_layer_node(), "o jogo desenha no canvas raiz (layer 0)")
	assert_gte(moldura.layer, 0, "moldura nao abaixo do jogo")
	assert_gt(moldura.get_index(), jogo.get_index(), "moldura depois do jogo na arvore")


func test_apply_layout_repassa_a_safe_area_a_moldura() -> void:
	var stage = _stage()
	var safe := Rect2(0.0, 24.0, 180.0, 340.0)
	stage.apply_layout(Vector2(180.0, 400.0), safe)
	assert_eq(stage.level_up_frame.rect_moldura(), safe, "moldura segue a safe area vigente")
	stage.apply_layout(Vector2(180.0, 320.0), Rect2(0.0, 0.0, 180.0, 320.0))
	assert_eq(stage.level_up_frame.rect_moldura(), Rect2(0.0, 0.0, 180.0, 320.0), "layout novo reaplicado")


func test_ponte_aviso_true_no_tick_do_pulso_republica_ao_terminar_e_apos_derrota() -> void:
	Global.progresso_inicial = 0.34
	var stage = _stage()
	stage._on_Play_button_down()
	assert_false(_aviso_publicado(stage), "aviso false ao dar Play")
	for i in TICKS_ATE_ESTAGIO_1:
		stage._physics_process(TICK)
	assert_eq(_estagio_publicado(stage), 1, "estagio 1 publicado")
	assert_true(_aviso_publicado(stage), "aviso true no tick em que o pulso comecou")
	var com_aviso: Dictionary = stage.ultimo_estado
	await wait_until(func() -> bool: return not stage.level_up_frame.pulsando(), 3.0)
	stage._physics_process(1.0 / 60.0)
	assert_false(is_same(stage.ultimo_estado, com_aviso), "republica ao terminar o pulso")
	assert_false(_aviso_publicado(stage), "aviso volta a false")
	var depois: Dictionary = stage.ultimo_estado
	for i in 60:
		stage._physics_process(1.0 / 60.0)
	assert_true(is_same(stage.ultimo_estado, depois), "0 republicacoes espurias em 60 ticks")
	# derrota com pulso em curso: aviso volta a false
	stage.dificuldade.progresso_inicial = 0.7
	stage._physics_process(TICK)
	assert_true(_aviso_publicado(stage), "novo pulso: aviso true")
	var corpo := SpyBody.new()
	add_child_autofree(corpo)
	stage._on_CheckPlayer_body_exited(corpo)
	assert_eq(stage.ultimo_estado["state"], "lost", "estado lost")
	assert_false(_aviso_publicado(stage), "apos interromper por derrota aviso e false")
