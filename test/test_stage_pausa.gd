extends GutTest

# Pausa ligada na Stage real + TouchControls: arvore parada (fisica, scroll, dificuldade), retomada no mesmo estado,
# press pre-pausa descartado, zona morta do botao e acao `pause`.
const STAGE_SCENE := "res://scenes/Stage.tscn"
const TICKS: int = 12

var _agora_ms: int = 0


func before_each() -> void:
	Global.tutorial_visto_espelho = true
	Global.platforms = []
	Global.iniciado = false
	_agora_ms = 0


func after_each() -> void:
	get_tree().paused = false
	for acao in ["jump", "ui_left", "ui_right", "pause"]:
		Input.action_release(acao)
	Global.set_modo_jogo(GameModes.ID_CLASSICO)
	Global.platforms = []
	Global.iniciado = false


func _relogio() -> int:
	return _agora_ms


func _novo_stage(iniciar: bool = true) -> Node:
	var stage: Node = add_child_autofree(load(STAGE_SCENE).instantiate())
	await wait_frames(2)
	if iniciar:
		stage._on_Play_button_down()
		await wait_frames(2)
	return stage


# f527 T6: Stage no modo Zen (a regra vem do registro em _ready via `de_id`, como na producao)
func _novo_stage_zen(iniciar: bool = true) -> Node:
	Global.set_modo_jogo(GameModes.ID_ZEN)
	var stage: Node = add_child_autofree(load(STAGE_SCENE).instantiate())
	await wait_frames(2)
	if iniciar:
		stage._on_Play_button_down()
		await wait_frames(2)
	return stage


# Toque entregue direto ao overlay de pausa (mesma entrada que o `_input` dele receberia)
func _toque_no_overlay(pos: Vector2, pressionado: bool) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.pressed = pressionado
	e.position = pos
	return e


# Botoes visiveis do overlay (3 no Zen, 2 nos outros modos)
func _botoes_visiveis(overlay: PauseOverlay) -> int:
	var visiveis: int = 0
	for b in [PauseOverlay.Botao.CONTINUAR, PauseOverlay.Botao.OPCOES, PauseOverlay.Botao.SAIR]:
		if overlay._paineis[b].visible:
			visiveis += 1
	return visiveis


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


func test_pausa_congela_o_pulso_da_moldura_e_despausar_termina_invisivel() -> void:
	var stage := await _novo_stage()
	var frame: LevelUpFrame = stage.level_up_frame
	assert_ne(frame.process_mode, Node.PROCESS_MODE_ALWAYS, "a moldura e pausavel")
	frame.pulsar(2)
	await wait_process_frames(2)
	stage.pause_state.pausar()
	await wait_process_frames(1)
	var alpha_pausado: float = frame.alpha()
	await wait_process_frames(3)
	assert_eq(frame.alpha(), alpha_pausado, "alpha estavel entre frames pausados")
	assert_true(frame.pulsando(), "o pulso segue em curso durante a pausa")
	stage.pause_state.retomar()
	await wait_until(func() -> bool: return not frame.pulsando(), 3.0)
	assert_eq(frame.alpha(), 0.0, "termina apagada")
	assert_false(frame.visible, "termina invisivel")


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


func test_press_antes_da_pausa_solto_depois_nao_aciona_nada() -> void:
	var stage := await _novo_stage()
	stage.touch_controls.relogio = Callable(self, "_relogio")
	_agora_ms = 1000
	_toque(stage, true, Vector2(90.0, 200.0))
	assert_true(stage.touch_controls.gesto_ativo(), "precondicao: o press e um gesto em curso")
	stage._pausar()
	stage._retomar()
	assert_false(stage.touch_controls.gesto_ativo(), "a pausa descartou o press pendente")
	_agora_ms = 1500
	_toque(stage, false, Vector2(90.0, 200.0))
	assert_false(_alguma_acao_pressionada(), "release apos a retomada nao aciona nenhuma acao")
	assert_false(stage.touch_controls.gesto_ativo(), "sem press pendente")


func test_pausa_cancela_o_gesto_em_curso_e_solta_as_acoes() -> void:
	var stage := await _novo_stage()
	_toque(stage, true, Vector2(90.0, 200.0))
	assert_true(stage.touch_controls.gesto_ativo(), "precondicao: gesto em curso")
	stage._pausar()
	assert_false(stage.touch_controls.gesto_ativo(), "gesto em curso cancelado pela pausa")
	assert_false(_alguma_acao_pressionada(), "a pausa solta as acoes da camada")


func test_toque_no_botao_de_pausa_nunca_vira_gesto_de_jogo() -> void:
	var stage := await _novo_stage()
	var safe := Rect2(0.0, 40.0, 360.0, 588.0)
	stage.apply_layout(Vector2(360.0, 640.0), safe)
	var alvo: Vector2 = stage.pause_botao.rect_botao().get_center()
	assert_eq(stage.pause_botao.rect_botao().position.y, 44.0, "botao deslocado por s_top")
	_toque(stage, true, alvo)
	assert_false(stage.touch_controls.gesto_ativo(), "toque no botao nao vira press de jogo")
	assert_false(_alguma_acao_pressionada(), "toque no botao nao aciona nenhuma acao de jogo")
	_toque(stage, false, alvo)
	# Fora da zona (mesmo x/y sem deslocamento de s_top) o toque ainda e de jogo
	_toque(stage, true, Vector2(28.0, 120.0))
	assert_true(stage.touch_controls.gesto_ativo(), "toque fora do botao segue sendo gesto de jogo")
	_toque(stage, false, Vector2(28.0, 120.0))
	assert_false(stage.touch_controls.gesto_ativo(), "soltar encerra o gesto")


func _alguma_acao_pressionada() -> bool:
	for acao in ["jump", "ui_left", "ui_right"]:
		if Input.is_action_pressed(acao):
			return true
	return false


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
	var partidas: Array = []
	stage.partida_iniciada.connect(func() -> void: partidas.append(1))
	await _acao_pause()
	assert_true(stage.pause_overlay.esta_aberto(), "precondicao: overlay aberto")
	var fundo := Vector2(340.0, 600.0)
	await _toque_real(fundo, true)
	await _toque_real(fundo, false)
	assert_false(stage.touch_controls.gesto_ativo(), "toque no fundo com overlay aberto nao gera gesto de jogo")
	assert_false(_alguma_acao_pressionada(), "toque no fundo com overlay aberto nao aciona acao de jogo")
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


# C734 [f527 T6]: Zen abre o overlay com 3 botoes (Continuar, Opcoes, Sair); Classico/Puro/Tempo seguem com 2 —
# o predicado unico `permite_sair_pela_pausa()` decide a visibilidade (o Stage o injeta ao abrir o overlay).
func test_c734_zen_abre_o_overlay_com_3_botoes_e_classico_puro_tempo_com_2() -> void:
	var stage := await _novo_stage_zen()
	stage._pausar()
	assert_true(stage.pause_overlay.esta_aberto(), "precondicao: overlay aberto no Zen")
	assert_eq(_botoes_visiveis(stage.pause_overlay), 3, "C734: overlay do Zen tem Continuar, Opcoes e Sair")
	assert_true(stage.pause_overlay._paineis[PauseOverlay.Botao.SAIR].visible, "C734: botao Sair visivel no Zen")
	for par in [["classico", ClassicoRule.new()], ["puro", PuroRule.new()], ["tempo", TempoRule.new()]]:
		stage._retomar()
		stage.regra = par[1] as GameModeRule
		stage._pausar()
		assert_eq(_botoes_visiveis(stage.pause_overlay), 2, "C734: overlay do %s segue com 2 botoes" % par[0])
		assert_false(stage.pause_overlay._paineis[PauseOverlay.Botao.SAIR].visible, "C734: Sair oculto no %s" % par[0])


# C735 [f527 T6]: Sair acionado no Zen despausa a arvore e recarrega a Stage — a nova nasce no menu com
# `started == false` — sem `Global.set_score` (recorde do Zen inalterado) e sem som/animacao de derrota.
# O reload passa pelo Callable `recarregar_cena`: em teste registra o pedido (o GUT nao pode trocar a cena do
# proprio runner); sem injecao vale o `_on_animation_end` de producao.
func test_c735_sair_no_zen_despausa_e_recarrega_a_stage_sem_derrota_nem_recorde() -> void:
	var stage := await _novo_stage_zen()
	var recargas: Array = []
	stage.recarregar_cena = func() -> void: recargas.append(1)
	stage._pausar()
	assert_true(get_tree().paused, "precondicao: arvore pausada no Zen")
	var best_antes: int = Global.get_best_score()
	var last_antes: int = Global.get_last_score()
	var alvo: Vector2 = stage.pause_overlay.rect_sair().get_center()
	assert_true(stage.pause_overlay.tratar_evento(_toque_no_overlay(alvo, true)), "C735: toque em Sair pertence ao overlay")
	assert_true(stage.pause_overlay.tratar_evento(_toque_no_overlay(alvo, false)), "C735: soltar em Sair e consumido pelo overlay")
	assert_false(get_tree().paused, "C735: Sair despausa a arvore")
	assert_false(stage.pause_overlay.esta_aberto(), "C735: overlay fechado ao sair")
	assert_eq(recargas.size(), 1, "C735: Sair pede exatamente 1 reload da Stage")
	assert_false(stage.player.is_end(), "C735: sem lose_game: o jogador nao termina")
	assert_false(stage.loseaudio.playing, "C735: sem som de derrota")
	assert_ne(stage.animation.current_animation, "lose_animation", "C735: sem animacao de derrota")
	assert_eq(Global.get_best_score(), best_antes, "C735: nenhum set_score: recorde do Zen inalterado")
	assert_eq(Global.get_last_score(), last_antes, "C735: last do Zen inalterado")
	# O reload pedido carrega Stage.tscn de novo: a instancia fresca nasce no menu (`started == false`, ponte menu)
	var nova: Node = add_child_autofree(load(STAGE_SCENE).instantiate())
	await wait_frames(2)
	assert_false(nova.started, "C735: a Stage recarregada nasce com started == false")
	assert_eq(String(nova.ultimo_estado.get("state", "")), String(GameState.STATE_MENU), "C735: a Stage recarregada nasce no menu")


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
