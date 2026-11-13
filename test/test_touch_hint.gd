extends GutTest

# Dica visual das zonas de toque (TouchHint): visibilidade (toque x teclado, menu/derrota, 1a partida, fade-out),
# sem entrada, geometria do handoff 8.2 e coexistencia com a classificacao do TouchControls.
# O estado de dica vive no Global: before_each/after_each o devolvem ao padrao (nao vaza entre arquivos).
const STAGE := "res://scenes/Stage.tscn"
const GRANDE := Vector2(180.0, 400.0)
const PEQUENA := Vector2(180.0, 320.0)
const BLOCO_LARGURA_MAX := 76.0


class FakePlayer:
	extends Node
	var fim: bool = false

	func is_end() -> bool:
		return fim


var _fim_fake: FakePlayer


func before_each() -> void:
	Global.tutorial_visto_espelho = true
	Global.platforms = []
	Global.iniciado = false
	Global.toque_detectado = false
	Global.dica_toque_mostrada = false


func after_each() -> void:
	Global.platforms = []
	Global.iniciado = false
	Global.toque_detectado = false
	Global.dica_toque_mostrada = false


func _nova_dica(touchscreen: bool = false) -> TouchHint:
	_fim_fake = FakePlayer.new()
	add_child_autofree(_fim_fake)
	var h := TouchHint.new()
	h.player = _fim_fake
	h.touchscreen_disponivel = func() -> bool: return touchscreen
	add_child_autofree(h)
	h.aplicar_layout(PEQUENA, Rect2(Vector2.ZERO, PEQUENA))
	return h


func _toque(pressionado: bool = true) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.position = Vector2(20.0, 200.0)
	e.pressed = pressionado
	return e


func _controles(no: Node) -> Array:
	var out: Array = []
	for filho in no.get_children():
		if filho is Control:
			out.append(filho)
		out.append_array(_controles(filho))
	return out


func test_c168_toque_detectado_em_partida_em_curso_mostra_a_dica() -> void:
	var h := _nova_dica(true)
	Global.iniciado = true
	await wait_process_frames(2)
	assert_true(h.visible, "dispositivo de toque + partida em curso + 1a partida = dica visivel")


func test_c168_primeiro_toque_antes_da_partida_detecta_e_mostra_ao_iniciar() -> void:
	var h := _nova_dica(false)
	h._input(_toque())
	assert_true(Global.toque_detectado, "o primeiro InputEventScreenTouch marca toque detectado")
	assert_false(h.visible, "no menu a dica segue oculta mesmo com o toque")
	Global.iniciado = true
	await wait_process_frames(2)
	assert_true(h.visible, "partida em curso apos o 1o toque = visivel")
	assert_true(h.esta_mostrando(), "a dica nao some com o toque que iniciou a partida")


func test_c169_somente_teclado_oculta_e_nao_marca_a_flag() -> void:
	var h := _nova_dica(false)
	Global.iniciado = true
	await wait_process_frames(3)
	assert_false(h.visible, "sem toque a dica fica oculta")
	assert_false(Global.dica_toque_mostrada, "sem toque a flag da dica nao e marcada")
	assert_false(Global.toque_detectado, "sem toque o toque nao e marcado como detectado")


func test_c170_menu_oculta_mesmo_com_toque_detectado() -> void:
	var h := _nova_dica(true)
	Global.toque_detectado = true
	await wait_process_frames(3)
	assert_false(h.visible, "menu (partida nao iniciada) = dica oculta")
	assert_false(Global.dica_toque_mostrada, "oculta no menu nao marca a flag")


func test_c170_derrota_oculta_mesmo_com_toque_detectado() -> void:
	var h := _nova_dica(true)
	Global.iniciado = true
	await wait_process_frames(2)
	assert_true(h.visible, "pre-condicao: dica visivel na partida")
	_fim_fake.fim = true
	await wait_process_frames(2)
	assert_false(h.visible, "derrota (player is_end) oculta a dica")
	var h2 := _nova_dica(true)
	Global.dica_toque_mostrada = false
	_fim_fake.fim = true
	await wait_process_frames(2)
	assert_false(h2.visible, "partida que ja nasce em derrota nunca mostra a dica")


func test_c171_primeiro_toque_de_jogo_esconde_com_fade_de_0_3_s() -> void:
	var h := _nova_dica(true)
	Global.iniciado = true
	await wait_process_frames(2)
	assert_true(h.visible, "pre-condicao: visivel antes do toque")
	h._input(_toque())
	await wait_seconds(0.15)
	var alpha: float = h.get_child(0).modulate.a
	assert_true(h.visible, "durante o fade a dica segue visivel")
	assert_lt(alpha, 1.0, "durante o fade o alpha decresce")
	assert_gt(alpha, 0.0, "no meio do fade o alpha ainda nao zerou")
	await wait_seconds(0.4)
	assert_false(h.visible, "apos o fade (0.3 s) a dica fica oculta")
	assert_false(h.esta_mostrando(), "apos o fade a dica deixa de estar mostrando")


func test_c172_segunda_partida_com_flag_marcada_fica_oculta() -> void:
	var h := _nova_dica(true)
	Global.iniciado = true
	await wait_process_frames(2)
	assert_true(Global.dica_toque_mostrada, "a 1a partida marca a flag")
	h.free()
	var h2 := _nova_dica(true)
	await wait_process_frames(3)
	assert_true(Global.dica_toque_mostrada, "a flag sobrevive a recriacao da dica (Stage recriada)")
	assert_false(h2.visible, "2a partida = dica oculta")


func test_c172_after_each_devolve_o_global_ao_padrao() -> void:
	Global.dica_toque_mostrada = true
	Global.toque_detectado = true
	after_each()
	assert_false(Global.dica_toque_mostrada, "after_each limpa a flag")
	assert_false(Global.toque_detectado, "after_each limpa o toque detectado")


func test_c173_nenhum_no_da_dica_filtra_mouse() -> void:
	var h := _nova_dica(true)
	var todos := _controles(h)
	assert_gt(todos.size(), 6, "a dica monta linha, blocos, setas e textos")
	for c in todos:
		var ctl := c as Control
		assert_eq(ctl.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s ignora o mouse" % ctl.get_class())
		assert_eq(ctl.focus_mode, Control.FOCUS_NONE, "%s sem foco" % ctl.get_class())


func test_c174_geometria_em_180x320() -> void:
	var h := _nova_dica(false)
	h.aplicar_layout(PEQUENA, Rect2(Vector2.ZERO, PEQUENA))
	assert_eq(h.rect_bloco(TouchHint.Lado.ESQUERDA), Rect2(7.0, 220.0, 76.0, 60.0), "bloco esquerdo x[7,83] y[220,280]")
	assert_eq(h.rect_bloco(TouchHint.Lado.DIREITA), Rect2(97.0, 220.0, 76.0, 60.0), "bloco direito x[97,173] y[220,280]")
	assert_eq(h.rect_linha().position.x, 90.0, "linha divisoria em x = 90")
	assert_eq(h.rect_linha().position.y, 32.0, "linha comeca em y = 32")
	assert_eq(h.rect_linha().end.y, 320.0, "linha vai ate a base")


func test_c174_geometria_em_180x400() -> void:
	var h := _nova_dica(false)
	h.aplicar_layout(GRANDE, Rect2(Vector2.ZERO, GRANDE))
	assert_eq(h.rect_bloco(TouchHint.Lado.ESQUERDA), Rect2(7.0, 300.0, 76.0, 60.0), "bloco esquerdo x[7,83] y[300,360]")
	assert_eq(h.rect_bloco(TouchHint.Lado.DIREITA), Rect2(97.0, 300.0, 76.0, 60.0), "bloco direito x[97,173] y[300,360]")
	assert_eq(h.rect_linha().position.x, 90.0, "linha divisoria em x = 90")
	assert_eq(h.rect_linha().end.y, 400.0, "linha vai ate a base")


func _rect_hud(c: Control) -> Rect2:
	return Rect2(c.offset_left, c.offset_top, c.offset_right - c.offset_left, c.offset_bottom - c.offset_top)


func test_c175_blocos_nao_cobrem_placar_nem_hud_nos_dois_tamanhos() -> void:
	var stage: Node = add_child_autofree(load(STAGE).instantiate())
	await wait_process_frames(2)
	for tam in [PEQUENA, GRANDE]:
		stage.apply_layout(tam, Rect2(Vector2.ZERO, tam))
		var hud: Array = [_rect_hud(stage.pointslabel), _rect_hud(stage.playbutton)]
		for lado in [TouchHint.Lado.ESQUERDA, TouchHint.Lado.DIREITA]:
			var bloco: Rect2 = stage.touch_hint.rect_bloco(lado)
			assert_gt(bloco.size.x, 0.0, "bloco com area em %s" % tam)
			for r in hud:
				assert_false(bloco.intersects(r), "bloco %s nao intersecta o HUD %s em %s" % [bloco, r, tam])
		var placar: Rect2 = _rect_hud(stage.pointslabel)
		assert_gte(stage.touch_hint.rect_linha().position.y, placar.end.y + 2.0, "linha comeca abaixo do placar")


func test_c176_texto_segura_cabe_em_76_px_com_a_fonte_real() -> void:
	assert_lte(TouchHint.largura_texto(TouchHint.TEXTO_SEGURA), BLOCO_LARGURA_MAX, "TEXTO_SEGURA cabe em 76 px")
	assert_lte(TouchHint.largura_texto(TouchHint.TEXTO_PULA), BLOCO_LARGURA_MAX, "TEXTO_PULA cabe em 76 px")
	var h := _nova_dica(false)
	for lado in [TouchHint.Lado.ESQUERDA, TouchHint.Lado.DIREITA]:
		var largura: float = h.rect_bloco(lado).size.x
		for filho in h._bloco_esq.get_children() if lado == TouchHint.Lado.ESQUERDA else h._bloco_dir.get_children():
			if filho is Label:
				assert_lte((filho as Label).get_minimum_size().x, largura, "label '%s' cabe no bloco" % filho.text)


func test_c177_dica_visivel_nao_muda_a_classificacao_do_toque() -> void:
	var sem := await _classificar_tap(false)
	var com := await _classificar_tap(true)
	assert_eq(sem.size(), 2, "o tap gera um gesto sem a dica")
	assert_eq(com, sem, "mesmo tap, mesmo resultado e lado com a dica visivel")
	assert_eq(sem[0], TouchClassifier.Resultado.TAP, "o tap rapido e classificado como TAP")


func _classificar_tap(com_dica: bool) -> Array:
	Global.iniciado = true
	Global.dica_toque_mostrada = false
	var t: Array = [0]
	var c := TouchControls.new()
	c.relogio = func() -> int: return t[0]
	c.largura_visivel_fixa = 180.0
	var ator := FakePlayer.new()
	c.player = ator
	add_child_autofree(ator)
	add_child_autofree(c)
	var h: TouchHint = null
	if com_dica:
		h = _nova_dica(true)
		await wait_process_frames(2)
		assert_true(h.visible, "pre-condicao: dica visivel")
	var visto: Array = []
	c.gesto_concluido.connect(func(r: int, l: int) -> void: visto.append_array([r, l]))
	var e := _toque(true)
	c._input(e)
	t[0] = 50
	c._input(_toque(false))
	if h != null:
		h._input(e)
	return visto
