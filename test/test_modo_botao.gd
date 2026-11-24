extends GutTest

# Botao Modo do menu isolado (sem Stage). Valores de layout do handoff-power-ups-e-modos.md:133, nunca recalculados
# da implementacao.
const STAGE_SCRIPT := preload("res://scenes/Stage.gd")
const SAFE_TOTAL := Rect2(0.0, 0.0, 180.0, 320.0)


func _novo(visivel: Vector2 = Vector2(180.0, 320.0), safe: Rect2 = SAFE_TOTAL) -> ModoBotao:
	var botao := ModoBotao.new()
	add_child_autofree(botao)
	botao.aplicar_layout(visivel, safe)
	return botao


func _toque(pressionado: bool, pos: Vector2) -> InputEventScreenTouch:
	var ev := InputEventScreenTouch.new()
	ev.index = 0
	ev.pressed = pressionado
	ev.position = pos
	return ev


func _arrasto(pos: Vector2) -> InputEventScreenDrag:
	var ev := InputEventScreenDrag.new()
	ev.index = 0
	ev.position = pos
	return ev


func _acao(nome: String) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = nome
	ev.pressed = true
	return ev


func _modo(rotulo: String) -> GameMode:
	return GameMode.new(StringName(rotulo.to_lower()), rotulo, rotulo, "descricao", ClassicoRule.new())


func test_c592_retangulo_do_botao_bate_com_o_handoff_em_180x320_e_180x400() -> void:
	var r: Rect2 = _novo().rect_botao()
	assert_eq(r.position, Vector2(34.0, 113.0), "origem em 180x320")
	assert_eq(r.end, Vector2(146.0, 137.0), "fim em 180x320")
	var alto: Rect2 = _novo(Vector2(180.0, 400.0), Rect2(0.0, 0.0, 180.0, 400.0)).rect_botao()
	assert_eq(alto.position, Vector2(34.0, 113.0), "origem em 180x400 (mesmo y)")
	assert_eq(alto.end, Vector2(146.0, 137.0), "fim em 180x400 (mesmo y)")
	var com_topo: Rect2 = _novo(Vector2(180.0, 320.0), Rect2(0.0, 20.0, 180.0, 294.0)).rect_botao()
	assert_eq(com_topo.position.y, 133.0, "y deslocado por safe.position.y")


func test_c593_botao_nao_intersecta_play_nem_opcoes_e_a_folga_ate_o_play_e_10() -> void:
	var r: Rect2 = _novo().rect_botao()
	var play := Rect2(62.0, STAGE_SCRIPT.PLAY_TOP, 56.0, STAGE_SCRIPT.PLAY_BOTTOM - STAGE_SCRIPT.PLAY_TOP)
	assert_false(r.intersects(play), "sem sobrepor o Play")
	assert_eq(STAGE_SCRIPT.PLAY_TOP - r.end.y, 10.0, "folga de 10 px ate o Play")
	var opcoes := OpcoesBotao.new()
	add_child_autofree(opcoes)
	opcoes.aplicar_layout(Vector2(180.0, 320.0), SAFE_TOTAL)
	assert_false(r.intersects(opcoes.rect_botao()), "sem sobrepor o botao Opcoes")


func test_c594_soltar_dentro_dispara_e_fora_ou_arrasto_para_fora_nao() -> void:
	var botao := _novo()
	var disparos: Array[int] = [0]
	botao.acionado.connect(func() -> void: disparos[0] += 1)
	var centro: Vector2 = botao.rect_botao().get_center()
	assert_true(botao.tratar_evento(_toque(true, centro)), "toque dentro e consumido")
	assert_true(botao.tratar_evento(_toque(false, centro)), "soltar dentro e consumido")
	assert_eq(disparos[0], 1, "soltar dentro dispara")
	botao.tratar_evento(_toque(true, centro))
	botao.tratar_evento(_toque(false, Vector2(5.0, 5.0)))
	assert_eq(disparos[0], 1, "soltar fora nao dispara")
	botao.tratar_evento(_toque(true, centro))
	botao.tratar_evento(_arrasto(Vector2(5.0, 5.0)))
	botao.tratar_evento(_toque(false, centro))
	assert_eq(disparos[0], 1, "arrasto que saiu do retangulo nao dispara")
	assert_false(botao.tratar_evento(_toque(true, Vector2(5.0, 5.0))), "toque fora nao e consumido")


func test_c595_botao_oculto_ignora_todo_toque_e_nao_consome() -> void:
	var botao := _novo()
	watch_signals(botao)
	botao.ocultar()
	var centro: Vector2 = botao.rect_botao().get_center()
	assert_false(botao.tratar_evento(_toque(true, centro)), "toque oculto nao e consumido")
	assert_false(botao.tratar_evento(_toque(false, centro)), "soltar oculto nao e consumido")
	assert_false(botao.tratar_evento(_arrasto(centro)), "arrasto oculto nao e consumido")
	assert_false(botao.tratar_evento(_acao("ui_up")), "tecla oculta nao e consumida")
	assert_signal_emit_count(botao, "acionado", 0, "oculto nunca dispara")


func test_c596_texto_muda_com_o_modo_exibido_e_nao_fala_em_toque() -> void:
	var botao := _novo()
	assert_eq(botao.texto(), "Modo: Classico", "modo padrao")
	botao.definir_modo(_modo("Tempo"))
	assert_eq(botao.texto(), "Modo: Tempo", "texto acompanha o modo exibido")
	botao.definir_modo(_modo("Diario"))
	assert_eq(botao.texto(), "Modo: Diario", "texto acompanha o novo modo")
	assert_false(botao.texto().to_lower().contains("toque"), "texto nao fala em toque")
	botao.focar(true)
	assert_eq(botao.texto(), "> Modo: Diario", "marcador de foco antes do texto")


func test_c597_foco_ui_up_do_play_vai_ao_modo_e_ui_down_do_modo_volta_ao_play() -> void:
	var botao := _novo()
	var opcoes := OpcoesBotao.new()
	add_child_autofree(opcoes)
	opcoes.aplicar_layout(Vector2(180.0, 320.0), SAFE_TOTAL)
	assert_false(botao.tem_foco(), "foco inicial no Play")
	assert_true(botao.tratar_evento(_acao("ui_up")), "ui_up consumido")
	assert_true(botao.tem_foco(), "foco no Modo")
	assert_true(botao.tratar_evento(_acao("ui_down")), "ui_down do Modo consumido")
	assert_false(botao.tem_foco(), "foco de volta ao Play")
	# ui_down do Play: o Modo nao consome e o Opcoes assume o foco
	assert_false(botao.tratar_evento(_acao("ui_down")), "ui_down do Play nao e do Modo")
	assert_true(opcoes.tratar_evento(_acao("ui_down")), "ui_down do Play continua no Opcoes")
	assert_true(opcoes.tem_foco(), "foco em Opcoes")
