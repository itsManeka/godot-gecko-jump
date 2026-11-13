extends GutTest

# Origem menu da tela de Opcoes na Stage real: botao Opcoes entre Play e Last, inicio suspenso com a tela aberta,
# Voltar devolve o menu com foco no botao. Valores de layout do handoff (secao 11), nunca recalculados da implementacao.
const STAGE_SCENE := "res://scenes/Stage.tscn"
const VISIVEL := Vector2(180.0, 320.0)
const SAFE_TOTAL := Rect2(0.0, 0.0, 180.0, 320.0)
const SAFE_COM_TOPO := Rect2(0.0, 20.0, 180.0, 294.0)


func before_each() -> void:
	Global.tutorial_visto_espelho = true
	Global.platforms = []
	Global.iniciado = false


func after_each() -> void:
	Input.action_release("jump")
	get_tree().paused = false
	Global.platforms = []
	Global.iniciado = false


func _novo_stage(safe: Rect2 = SAFE_TOTAL) -> Node:
	var stage: Node = add_child_autofree(load(STAGE_SCENE).instantiate())
	await wait_frames(2)
	stage.apply_layout(VISIVEL, safe)
	return stage


func _toque(pressionado: bool, pos: Vector2) -> InputEventScreenTouch:
	var ev := InputEventScreenTouch.new()
	ev.index = 0
	ev.pressed = pressionado
	ev.position = pos
	return ev


# Toque real pela cadeia de entrada do Godot (ordem dos filhos da Stage)
func _toque_real(pressionado: bool, pos: Vector2) -> void:
	Input.parse_input_event(_toque(pressionado, pos))
	Input.flush_buffered_events()
	await wait_frames(2)


func _acao(nome: String) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = nome
	ev.pressed = true
	return ev


func _abrir_pelo_botao(stage: Node) -> void:
	var centro: Vector2 = stage.opcoes_botao.rect_botao().get_center()
	stage.opcoes_botao.tratar_evento(_toque(true, centro))
	stage.opcoes_botao.tratar_evento(_toque(false, centro))


func test_acionar_opcoes_no_menu_abre_a_tela_sem_iniciar_e_oculta_o_menu() -> void:
	var stage := await _novo_stage()
	assert_true(stage.opcoes_botao.visible, "botao visivel no menu")
	_abrir_pelo_botao(stage)
	assert_false(stage.started, "partida nao inicia")
	assert_true(stage.options_screen.esta_aberta(), "tela aberta")
	assert_false(stage.playbutton.visible, "Play oculto")
	assert_false(stage.lastscore.visible, "Last oculto")
	assert_false(stage.bestscore.visible, "Best oculto")
	assert_false(stage.opcoes_botao.visible, "botao Opcoes oculto")
	assert_false(get_tree().paused, "menu nao pausa a arvore")
	await wait_process_frames(3)
	assert_true(stage.options_screen.esta_aberta(), "tela segue aberta (nao fecha por falta de pausa)")


func test_com_a_tela_aberta_jump_e_toque_nao_iniciam() -> void:
	var stage := await _novo_stage()
	_abrir_pelo_botao(stage)
	Input.action_press("jump")
	await wait_process_frames(3)
	assert_false(stage.started, "jump nao inicia com a tela aberta")
	Input.action_release("jump")
	stage._input(_toque(true, Vector2(20.0, 100.0)))
	assert_false(stage.started, "toque na Stage nao inicia com a tela aberta")
	await _toque_real(true, Vector2(20.0, 100.0))
	assert_false(stage.started, "toque real nao inicia com a tela aberta")


func test_voltar_restaura_o_menu_com_foco_no_botao_e_o_inicio_volta() -> void:
	var stage := await _novo_stage()
	_abrir_pelo_botao(stage)
	stage.options_screen.voltar.emit()
	assert_false(stage.options_screen.esta_aberta(), "tela fechada")
	assert_true(stage.playbutton.visible, "Play visivel")
	assert_true(stage.lastscore.visible, "Last visivel")
	assert_true(stage.bestscore.visible, "Best visivel")
	assert_true(stage.opcoes_botao.visible, "botao visivel")
	assert_true(stage.opcoes_botao.tem_foco(), "foco no botao Opcoes")
	assert_false(stage.started, "voltar nao inicia")
	Input.action_press("jump")
	await wait_process_frames(3)
	assert_true(stage.started, "jump volta a iniciar a partida")


func test_play_volta_a_iniciar_depois_de_voltar() -> void:
	var stage := await _novo_stage()
	_abrir_pelo_botao(stage)
	stage.options_screen.voltar.emit()
	stage._on_Play_button_down()
	assert_true(stage.started, "Play inicia depois de voltar")


func test_botao_some_ao_iniciar_e_nao_aparece_apos_a_derrota() -> void:
	var stage := await _novo_stage()
	stage._on_Play_button_down()
	assert_false(stage.opcoes_botao.visible, "botao some ao iniciar")
	var player = stage.get_node("Node2D/Player")
	player.jumping = false
	stage._on_CheckPlayer_body_exited(player)
	await wait_frames(2)
	assert_true(stage.started, "started segue true na derrota")
	assert_false(stage.opcoes_botao.visible, "botao nao aparece na derrota")
	stage._abrir_opcoes_do_menu()
	assert_false(stage.options_screen.esta_aberta(), "tela nao abre com a partida iniciada")


func test_retangulo_do_botao_bate_com_o_handoff_e_a_folga_ate_play_e_last() -> void:
	var stage := await _novo_stage()
	var r: Rect2 = stage.opcoes_botao.rect_botao()
	assert_eq(r.position, Vector2(46.0, 189.0), "origem em 180x320")
	assert_eq(r.end, Vector2(134.0, 213.0), "fim em 180x320")
	assert_eq(r.position.y - 173.0, 16.0, "folga ate o Play")
	assert_eq(230.0 - r.end.y, 17.0, "folga ate o Last")
	var play := Rect2(stage.playbutton.offset_left, stage.playbutton.offset_top, 56.0, 26.0)
	assert_false(r.intersects(play), "sem sobrepor o Play")
	var last := Rect2(0.0, stage.lastscore.offset_top, 180.0, 17.0)
	assert_false(r.intersects(last), "sem sobrepor o Last")
	var hint: TouchHint = stage.touch_hint
	assert_false(r.intersects(hint.rect_bloco(TouchHint.Lado.ESQUERDA)), "sem sobrepor a dica esquerda")
	assert_false(r.intersects(hint.rect_bloco(TouchHint.Lado.DIREITA)), "sem sobrepor a dica direita")
	stage.apply_layout(VISIVEL, SAFE_COM_TOPO)
	var rs: Rect2 = stage.opcoes_botao.rect_botao()
	assert_eq(rs.position, Vector2(46.0, 209.0), "origem com s_top 20")
	assert_eq(rs.end, Vector2(134.0, 233.0), "fim com s_top 20")


func test_toque_no_retangulo_do_botao_nao_inicia_a_partida() -> void:
	var stage := await _novo_stage()
	var centro: Vector2 = stage.opcoes_botao.rect_botao().get_center()
	await _toque_real(true, centro)
	assert_false(stage.started, "toque no botao nao inicia a partida")
	await _toque_real(false, centro)
	assert_false(stage.started, "soltar no botao nao inicia")
	assert_true(stage.options_screen.esta_aberta(), "soltar dentro abre a tela")


func test_toque_que_fecha_a_tela_nao_conta_como_inicio() -> void:
	var stage := await _novo_stage()
	_abrir_pelo_botao(stage)
	var voltar: Vector2 = stage.options_screen.rect_voltar().get_center()
	await _toque_real(true, voltar)
	await _toque_real(false, voltar)
	assert_false(stage.options_screen.esta_aberta(), "Voltar fechou a tela")
	assert_false(stage.started, "o toque do Voltar nao inicia a partida")


func _tecla(keycode: Key) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.physical_keycode = keycode
	ev.pressed = true
	return ev


func test_espaco_com_foco_no_botao_nao_reabre_a_tela_e_enter_abre() -> void:
	var stage := await _novo_stage()
	_abrir_pelo_botao(stage)
	stage.options_screen.voltar.emit()
	assert_true(stage.opcoes_botao.tem_foco(), "foco no botao Opcoes depois de voltar")
	var consumido: bool = stage.opcoes_botao.tratar_evento(_tecla(KEY_SPACE))
	assert_false(consumido, "Espaco (jump) com foco no botao nao e consumido")
	assert_false(stage.options_screen.esta_aberta(), "Espaco nao reabre a tela de Opcoes")
	stage.opcoes_botao.tratar_evento(_tecla(KEY_ENTER))
	assert_true(stage.options_screen.esta_aberta(), "Enter com foco abre a tela de Opcoes")


func test_espaco_real_com_foco_no_botao_inicia_a_partida() -> void:
	var stage := await _novo_stage()
	_abrir_pelo_botao(stage)
	stage.options_screen.voltar.emit()
	Input.parse_input_event(_tecla(KEY_SPACE))
	Input.flush_buffered_events()
	await wait_frames(3)
	assert_false(stage.options_screen.esta_aberta(), "Espaco real nao reabre a tela")
	assert_true(stage.started, "Espaco real inicia a partida")


func test_ui_down_leva_o_foco_para_opcoes_e_ui_accept_abre_a_tela() -> void:
	var stage := await _novo_stage()
	assert_false(stage.opcoes_botao.tem_foco(), "foco inicial no Play")
	var consumido: bool = stage.opcoes_botao.tratar_evento(_acao("ui_down"))
	assert_true(consumido, "ui_down consumido")
	assert_true(stage.opcoes_botao.tem_foco(), "foco em Opcoes")
	assert_eq(stage.opcoes_botao.texto(), "> Opcoes", "marcador > no botao")
	assert_false(stage.options_screen.esta_aberta(), "ainda nao abriu")
	stage.opcoes_botao.tratar_evento(_acao("ui_accept"))
	assert_true(stage.options_screen.esta_aberta(), "ui_accept abre a tela")
	assert_false(stage.started, "nao inicia")
