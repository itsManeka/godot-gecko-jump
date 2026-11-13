extends GutTest

# Pausa ligada na Stage real + TouchControls: arvore parada (fisica, scroll, dificuldade), retomada no mesmo estado,
# press pre-pausa descartado, zona morta do botao e acao `pause`.
const STAGE_SCENE := "res://scenes/Stage.tscn"
const TICKS: int = 12

var _agora_ms: int = 0
var _gestos: Array = []


func before_each() -> void:
	Global.tutorial_visto_espelho = true
	Global.platforms = []
	Global.iniciado = false
	_agora_ms = 0
	_gestos = []


func after_each() -> void:
	get_tree().paused = false
	for acao in ["jump", "ui_left", "ui_right", "pause"]:
		Input.action_release(acao)
	Global.platforms = []
	Global.iniciado = false


func _relogio() -> int:
	return _agora_ms


func _registrar_gesto(resultado: int, lado: int) -> void:
	_gestos.append([resultado, lado])


func _novo_stage(iniciar: bool = true) -> Node:
	var stage: Node = add_child_autofree(load(STAGE_SCENE).instantiate())
	await wait_frames(2)
	if iniciar:
		stage._on_Play_button_down()
		await wait_frames(2)
	return stage


func _acao_pause() -> void:
	var ev := InputEventAction.new()
	ev.action = "pause"
	ev.pressed = true
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
	await wait_frames(2)


func _toque(stage: Node, pressionado: bool, pos: Vector2) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = 0
	ev.pressed = pressionado
	ev.position = pos
	stage.touch_controls._input(ev)


func test_arvore_pausada_nao_move_fisica_scroll_nem_dificuldade() -> void:
	var stage := await _novo_stage()
	await wait_physics_frames(3)
	stage.pause_state.pausar()
	assert_true(get_tree().paused, "arvore pausada")
	var player: Node = stage.player
	var scroll: Node = stage.get_node("ScrollLevel")
	var pos_player: Vector2 = player.position
	var y_scroll: float = scroll.running_platforms.position.y
	var rolado: float = scroll.position_scrolled
	var segundos: float = stage.dificuldade._segundos
	await wait_physics_frames(TICKS)
	assert_eq(player.position, pos_player, "Player parado durante a pausa")
	assert_eq(scroll.running_platforms.position.y, y_scroll, "y das plataformas parado durante a pausa")
	assert_eq(scroll.position_scrolled, rolado, "scroll parado durante a pausa")
	assert_eq(stage.dificuldade._segundos, segundos, "tempo da dificuldade parado durante a pausa")
	assert_true(Global.is_iniciado(), "Global.is_iniciado segue true durante a pausa")


func test_retomar_continua_do_mesmo_estado() -> void:
	var stage := await _novo_stage()
	await wait_physics_frames(3)
	stage._pausar()
	var pos_player: Vector2 = stage.player.position
	var pontos: int = stage.points
	await wait_physics_frames(TICKS)
	stage._retomar()
	assert_false(get_tree().paused, "arvore retomada")
	assert_eq(stage.player.position, pos_player, "posicao do Player igual a de antes da pausa")
	assert_eq(stage.points, pontos, "points igual ao de antes da pausa")
	assert_true(Global.is_iniciado(), "Global.is_iniciado segue true")


func test_press_antes_da_pausa_solto_depois_nao_emite_hold_nem_tap() -> void:
	var stage := await _novo_stage()
	stage.touch_controls.relogio = Callable(self, "_relogio")
	stage.touch_controls.gesto_concluido.connect(_registrar_gesto)
	_agora_ms = 1000
	_toque(stage, true, Vector2(45.0, 100.0))
	stage._pausar()
	_gestos.clear()  # o cancelamento da pausa e esperado; so conta o que vem depois
	stage._retomar()
	_agora_ms = 1500  # > 200 ms depois do press: sem o descarte viraria HOLD
	_toque(stage, false, Vector2(45.0, 100.0))
	assert_eq(_gestos.size(), 0, "release apos a retomada nao emite HOLD nem TAP (gestos: %s)" % [_gestos])
	assert_false(stage.touch_controls.classificador.ativo(), "classificador sem press pendente")


func test_pausa_cancela_o_gesto_em_curso_como_cancelado() -> void:
	var stage := await _novo_stage()
	stage.touch_controls.gesto_concluido.connect(_registrar_gesto)
	_toque(stage, true, Vector2(45.0, 100.0))
	stage._pausar()
	assert_eq(_gestos.size(), 1, "um unico gesto emitido ao pausar")
	assert_eq(_gestos[0][0], TouchClassifier.Resultado.CANCELADO, "gesto em curso cancelado pela pausa")


func test_toque_no_botao_de_pausa_nunca_vira_gesto_de_jogo() -> void:
	var stage := await _novo_stage()
	var safe := Rect2(0.0, 20.0, 180.0, 294.0)
	stage.apply_layout(Vector2(180.0, 320.0), safe)
	var alvo: Vector2 = stage.pause_botao.rect_botao().get_center()
	assert_eq(stage.pause_botao.rect_botao().position.y, 22.0, "botao deslocado por s_top")
	stage.touch_controls.gesto_concluido.connect(_registrar_gesto)
	_toque(stage, true, alvo)
	_toque(stage, false, alvo)
	assert_eq(_gestos.size(), 0, "toque no botao nao produz gesto_concluido de jogo (gestos: %s)" % [_gestos])
	assert_false(stage.touch_controls.classificador.ativo(), "toque no botao nao vira press de jogo")
	# Fora da zona (mesmo x/y sem deslocamento de s_top) o toque ainda e de jogo
	_toque(stage, true, Vector2(14.0, 60.0))
	_toque(stage, false, Vector2(14.0, 60.0))
	assert_eq(_gestos.size(), 1, "toque fora do botao segue sendo gesto de jogo")


func test_pause_no_menu_e_ignorada_e_play_nao_reinicia_apos_retomar() -> void:
	var stage := await _novo_stage(false)
	await _acao_pause()
	assert_false(get_tree().paused, "pause no menu nao pausa")
	assert_false(stage.pause_overlay.esta_aberto(), "overlay fechado no menu")
	stage._on_Play_button_down()
	await wait_frames(2)
	var iniciadas: Array = []
	stage.partida_iniciada.connect(func(): iniciadas.append(1))
	stage._pausar()
	stage._retomar()
	stage._on_Play_button_down()
	assert_eq(iniciadas.size(), 0, "Play apos retomar nao reinicia a partida")
	assert_true(stage.started, "started segue true")
	assert_true(Global.is_iniciado(), "Global.is_iniciado segue true")


func test_acao_pause_pausa_e_abre_overlay_e_a_mesma_acao_retoma() -> void:
	var stage := await _novo_stage()
	await _acao_pause()
	assert_true(get_tree().paused, "acao pause com partida ativa pausa a arvore")
	assert_true(stage.pause_overlay.esta_aberto(), "overlay aberto")
	assert_ne(stage.process_mode, Node.PROCESS_MODE_ALWAYS, "a Stage em si segue pausavel")
	assert_eq(stage.pause_overlay.process_mode, Node.PROCESS_MODE_ALWAYS, "overlay escuta com a arvore pausada")
	var pos_player: Vector2 = stage.player.position
	await wait_physics_frames(TICKS)
	assert_eq(stage.player.position, pos_player, "Player nao anda pausado")
	await _acao_pause()
	assert_false(get_tree().paused, "a mesma acao retoma")
	assert_false(stage.pause_overlay.esta_aberto(), "overlay fechado")


# Perda de foco (T6): a notificacao entregue a Stage em partida ativa pausa e abre o overlay. Cada notificacao tem o seu
# teste, para a mutacao de uma nao derrubar a outra.
func test_foco_perdido_da_aplicacao_pausa_partida_ativa_e_abre_overlay() -> void:
	var stage := await _novo_stage()
	await wait_physics_frames(2)
	stage.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_true(get_tree().paused, "APPLICATION_FOCUS_OUT pausa a arvore")
	assert_true(stage.pause_overlay.esta_aberto(), "APPLICATION_FOCUS_OUT abre o overlay")


func test_foco_perdido_da_janela_pausa_partida_ativa_e_abre_overlay() -> void:
	var stage := await _novo_stage()
	await wait_physics_frames(2)
	stage.notification(NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	assert_true(get_tree().paused, "WM_WINDOW_FOCUS_OUT pausa a arvore")
	assert_true(stage.pause_overlay.esta_aberto(), "WM_WINDOW_FOCUS_OUT abre o overlay")


# Foco perdido no menu e na derrota nao pausa; o foco de volta nunca retoma a partida pausada pelo foco.
func test_foco_perdido_no_menu_e_na_derrota_nao_pausa() -> void:
	var stage := await _novo_stage(false)
	stage.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	stage.notification(NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	assert_false(get_tree().paused, "foco perdido no menu nao pausa")
	assert_false(stage.pause_overlay.esta_aberto(), "overlay fechado no menu")
	stage._on_Play_button_down()
	stage.player.lose_game()
	assert_true(stage.player.is_end(), "derrota ativa (precondicao)")
	stage.notification(NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	assert_false(get_tree().paused, "foco perdido na derrota nao pausa")
	assert_false(stage.pause_overlay.esta_aberto(), "overlay fechado na derrota")


func test_foco_de_volta_nao_retoma_partida_pausada_pelo_foco() -> void:
	var stage := await _novo_stage()
	stage.notification(NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	stage.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	stage.notification(NOTIFICATION_WM_WINDOW_FOCUS_IN)
	assert_true(get_tree().paused, "foco de volta nao retoma")
	assert_true(stage.pause_overlay.esta_aberto(), "overlay segue aberto ate Continuar")


# Foco perdido com a partida ja pausada e idempotente: overlay nao duplica, paused segue true.
func test_foco_perdido_com_partida_ja_pausada_e_idempotente() -> void:
	var stage := await _novo_stage()
	stage._pausar()
	stage.notification(NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	assert_true(get_tree().paused, "paused segue true apos WM_WINDOW_FOCUS_OUT")
	assert_true(stage.pause_overlay.esta_aberto(), "overlay segue aberto apos WM_WINDOW_FOCUS_OUT")
	stage.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_true(get_tree().paused, "paused segue true apos APPLICATION_FOCUS_OUT")
	assert_true(stage.pause_overlay.esta_aberto(), "overlay segue aberto apos APPLICATION_FOCUS_OUT")
	var overlays: int = stage.get_children().filter(func(c): return c is PauseOverlay).size()
	assert_eq(overlays, 1, "overlay nao duplica")


# APPLICATION_PAUSED (Android/web em segundo plano) tem o mesmo efeito da perda de foco na Stage.
func test_app_pausada_pausa_partida_ativa_e_abre_overlay() -> void:
	var stage := await _novo_stage()
	await wait_physics_frames(2)
	stage.notification(NOTIFICATION_APPLICATION_PAUSED)
	assert_true(get_tree().paused, "APPLICATION_PAUSED pausa a arvore")
	assert_true(stage.pause_overlay.esta_aberto(), "APPLICATION_PAUSED abre o overlay")


# Botao de pausa com o dedo sobre ele quando a pausa acontece pela acao: o estado pressed nao fica preso.
func test_pausa_cancela_toque_pressionado_no_botao() -> void:
	var stage := await _novo_stage()
	stage.pause_botao.atualizar_visibilidade()
	var ev := InputEventScreenTouch.new()
	ev.index = 0
	ev.pressed = true
	ev.position = stage.pause_botao.rect_botao().get_center()
	stage.pause_botao.tratar_evento(ev)
	assert_true(stage.pause_botao.esta_pressionado(), "precondicao: dedo pressionado sobre o botao")
	await _acao_pause()
	assert_true(get_tree().paused, "acao pause pausa a partida")
	assert_false(stage.pause_botao.esta_pressionado(), "pausa cancela o botao pressionado")
	await _acao_pause()
	assert_false(get_tree().paused, "a mesma acao retoma")
	assert_false(stage.pause_botao.esta_pressionado(), "botao nao fica pressionado apos retomar")


# Acao `pause` so e consumida quando a pausa acontece: no menu ela segue e chega ao ouvinte posterior.
func test_acao_pause_no_menu_nao_e_consumida() -> void:
	var ouvinte := _ouvinte()
	await _novo_stage(false)
	await _acao_pause()
	assert_false(get_tree().paused, "pause no menu nao pausa")
	assert_eq(ouvinte.acoes_pause, 1, "pause no menu nao e consumida: chega ao ouvinte posterior")


func test_acao_pause_com_partida_ativa_e_consumida() -> void:
	var ouvinte := _ouvinte()
	await _novo_stage()
	await _acao_pause()
	assert_true(get_tree().paused, "pause com partida ativa pausa a arvore")
	assert_eq(ouvinte.acoes_pause, 0, "pause com partida ativa e consumida pela Stage (nao chega ao ouvinte)")


# Toque de verdade (Input.parse_input_event) no fundo com o overlay aberto: o overlay consome; nada chega ao jogo.
func test_toque_no_fundo_com_overlay_aberto_nao_chega_ao_jogo() -> void:
	var ouvinte := _ouvinte()
	var stage := await _novo_stage()
	stage.touch_controls.gesto_concluido.connect(_registrar_gesto)
	var partidas: Array = []
	stage.partida_iniciada.connect(func() -> void: partidas.append(1))
	await _acao_pause()
	assert_true(stage.pause_overlay.esta_aberto(), "precondicao: overlay aberto")
	var fundo := Vector2(170.0, 300.0)
	await _toque_real(fundo, true)
	await _toque_real(fundo, false)
	assert_eq(_gestos.size(), 0, "toque no fundo com overlay aberto nao gera gesto de jogo (gestos: %s)" % [_gestos])
	assert_true(stage.pause_overlay.esta_aberto(), "overlay segue aberto apos toque no fundo")
	assert_true(get_tree().paused, "arvore segue pausada apos toque no fundo")
	assert_eq(ouvinte.toques, 0, "toque no fundo e consumido pelo overlay (nao chega a camada posterior)")


# Toque sobre o botao de pausa, que fica sob o overlay: nao pede pausa nem retoma.
func test_toque_sobre_o_botao_de_pausa_com_overlay_aberto_nao_pausa_nem_retoma() -> void:
	var ouvinte := _ouvinte()
	var stage := await _novo_stage()
	await _acao_pause()
	var pedidos: Array = []
	stage.pause_botao.pausar_pedido.connect(func() -> void: pedidos.append(1))
	var alvo: Vector2 = stage.pause_botao.rect_botao().get_center()
	await _toque_real(alvo, true)
	await _toque_real(alvo, false)
	assert_eq(pedidos.size(), 0, "toque sobre o botao sob o overlay nao pede pausa")
	assert_true(stage.pause_overlay.esta_aberto(), "toque sobre o botao nao retoma: overlay segue aberto")
	assert_true(get_tree().paused, "toque sobre o botao nao retoma: arvore segue pausada")
	assert_eq(ouvinte.toques, 0, "toque sobre o botao e consumido pelo overlay")


func _toque_real(pos: Vector2, pressionado: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = 0
	ev.pressed = pressionado
	ev.position = pos
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
	await wait_frames(2)


# Ouvinte posterior a Stage na propagacao (criado antes dela): so recebe o que a Stage e o overlay nao consumiram.
func _ouvinte() -> OuvinteEntrada:
	var o := OuvinteEntrada.new()
	add_child_autofree(o)
	return o


class OuvinteEntrada:
	extends Node
	var acoes_pause: int = 0
	var toques: int = 0

	func _init() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			toques += 1

	func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("pause"):
			acoes_pause += 1
