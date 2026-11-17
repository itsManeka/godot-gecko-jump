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
	Global.set_touch_mode(TouchMode.padrao(), false)


func after_each() -> void:
	Global.set_touch_mode(TouchMode.padrao(), false)
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


func test_f472_faixa_de_fundo_atras_dos_textos_de_cada_bloco() -> void:
	var h := _nova_dica(false)
	for bloco in [h._bloco_esq, h._bloco_dir]:
		var faixas: Array = []
		var labels: Array = []
		for filho in (bloco as Control).get_children():
			if filho is ColorRect:
				faixas.append(filho)
			elif filho is Label:
				labels.append(filho)
		assert_eq(faixas.size(), 1, "uma faixa por bloco")
		assert_eq(labels.size(), 2, "pula e segura: anda")
		var faixa := faixas[0] as ColorRect
		assert_eq(faixa.color, UiHelpers.COR_FUNDO_OVERLAY, "faixa usa a cor do fundo do overlay")
		assert_eq(faixa.mouse_filter, Control.MOUSE_FILTER_IGNORE, "faixa nao recebe mouse")
		assert_eq(faixa.get_index(), 0, "faixa fica atras dos textos")
		for l in labels:
			assert_true(faixa.get_global_rect().encloses((l as Label).get_global_rect()), "faixa cobre '%s'" % l.text)


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


func test_c176_textos_de_cada_modo_cabem_no_bloco_com_a_fonte_real() -> void:
	for modo in [TouchMode.Modo.B, TouchMode.Modo.C]:
		for lado in [TouchHint.Lado.ESQUERDA, TouchHint.Lado.DIREITA]:
			for t in TouchHint.textos_bloco(modo, lado):
				assert_lte(TouchHint.largura_texto(t), BLOCO_LARGURA_MAX, "'%s' cabe em 76 px" % t)
	Global.set_touch_mode(TouchMode.Modo.A, false)
	var h := _nova_dica(false)
	var centro: float = h.rect_bloco(TouchHint.Lado.CENTRO).size.x
	for t in TouchHint.textos_bloco(TouchMode.Modo.A, TouchHint.Lado.CENTRO):
		assert_lte(TouchHint.largura_texto(t), centro, "'%s' cabe no bloco central" % t)
	for lado in [TouchHint.Lado.ESQUERDA, TouchHint.Lado.DIREITA, TouchHint.Lado.CENTRO]:
		var largura: float = h.rect_bloco(lado).size.x
		for filho in h._bloco_de(lado).get_children():
			if filho is Label and filho.text != "":
				assert_lte((filho as Label).get_minimum_size().x, largura, "label '%s' cabe no bloco" % filho.text)


func _todos_os_textos(h: TouchHint) -> Array[String]:
	var out: Array[String] = []
	for lado in [TouchHint.Lado.ESQUERDA, TouchHint.Lado.DIREITA, TouchHint.Lado.CENTRO]:
		out.append_array(h.textos_atuais(lado))
	return out


func test_c415_modo_a_mostra_o_texto_curto_e_nao_desenha_zonas() -> void:
	Global.set_touch_mode(TouchMode.Modo.A, false)
	var h := _nova_dica(true)
	assert_eq(h.textos_atuais(TouchHint.Lado.CENTRO), ["arraste: anda", "flick: pula"], "bloco central com o texto do modo A")
	assert_true(h.bloco_visivel(TouchHint.Lado.CENTRO), "bloco central visivel")
	assert_false(h.bloco_visivel(TouchHint.Lado.ESQUERDA), "sem bloco esquerdo")
	assert_false(h.bloco_visivel(TouchHint.Lado.DIREITA), "sem bloco direito")
	assert_false(h._linha.visible, "sem linha divisoria")
	assert_eq(h.rect_linha(), Rect2(), "modo A nao tem zona: retangulo da linha vazio")


func test_c416_modo_b_mostra_linha_em_x_90_e_blocos_com_texto_do_modo_b() -> void:
	Global.set_touch_mode(TouchMode.Modo.B, false)
	var h := _nova_dica(true)
	assert_eq(h.rect_linha().position.x, 90.0, "linha divisoria em x = 90")
	assert_true(h._linha.visible, "linha visivel")
	assert_eq(h.textos_atuais(TouchHint.Lado.ESQUERDA), ["anda", "segura aqui"], "bloco esquerdo com o texto do modo B")
	assert_eq(h.textos_atuais(TouchHint.Lado.DIREITA), ["pula", "toque aqui"], "bloco direito com o texto do modo B")
	assert_true(h.bloco_visivel(TouchHint.Lado.ESQUERDA) and h.bloco_visivel(TouchHint.Lado.DIREITA), "blocos laterais visiveis")
	assert_false(h.bloco_visivel(TouchHint.Lado.CENTRO), "sem bloco central")


func test_c417_modo_c_mostra_linha_em_x_90_e_blocos_com_texto_do_modo_c() -> void:
	Global.set_touch_mode(TouchMode.Modo.C, false)
	var h := _nova_dica(true)
	assert_eq(h.rect_linha().position.x, 90.0, "linha divisoria em x = 90")
	assert_true(h._linha.visible, "linha visivel")
	assert_eq(h.textos_atuais(TouchHint.Lado.ESQUERDA), ["anda", "2o dedo pula"], "bloco esquerdo com o texto do modo C")
	assert_eq(h.textos_atuais(TouchHint.Lado.DIREITA), ["anda", "2o dedo pula"], "bloco direito com o texto do modo C")
	assert_true(h.bloco_visivel(TouchHint.Lado.ESQUERDA) and h.bloco_visivel(TouchHint.Lado.DIREITA), "blocos laterais visiveis")
	assert_false(h.bloco_visivel(TouchHint.Lado.CENTRO), "sem bloco central")


func test_c418_textos_renderizados_diferem_entre_os_modos_e_sem_o_esquema_velho() -> void:
	var vistos: Array = []
	for modo in [TouchMode.Modo.A, TouchMode.Modo.B, TouchMode.Modo.C]:
		Global.set_touch_mode(modo, false)
		var h := _nova_dica(true)
		var textos := _todos_os_textos(h)
		assert_false(textos.has("segura: anda"), "texto antigo 'segura: anda' ausente no modo %s" % TouchMode.nome(modo))
		var visiveis: Array[String] = []
		for lado in [TouchHint.Lado.ESQUERDA, TouchHint.Lado.DIREITA, TouchHint.Lado.CENTRO]:
			if h.bloco_visivel(lado):
				visiveis.append_array(h.textos_atuais(lado))
		assert_false(vistos.has(visiveis), "modo %s renderiza textos diferentes dos outros" % TouchMode.nome(modo))
		vistos.append(visiveis)
	assert_eq(vistos.size(), 3, "3 modos, 3 conjuntos de textos")


func test_c420_fade_preservado_nos_3_modos() -> void:
	for modo in [TouchMode.Modo.A, TouchMode.Modo.B, TouchMode.Modo.C]:
		Global.set_touch_mode(modo, false)
		Global.dica_toque_mostrada = false
		Global.iniciado = true
		var h := _nova_dica(true)
		await wait_process_frames(2)
		assert_true(h.visible, "modo %s: dica visivel" % TouchMode.nome(modo))
		h._input(_toque())
		await wait_seconds(0.15)
		assert_true(h.visible, "modo %s: durante o fade segue visivel" % TouchMode.nome(modo))
		assert_lt(h.get_child(0).modulate.a, 1.0, "modo %s: alpha decresce" % TouchMode.nome(modo))
		await wait_seconds(0.4)
		assert_false(h.visible, "modo %s: apos o fade a dica fica oculta" % TouchMode.nome(modo))
		h.free()


func test_c420_trocar_o_modo_rearma_a_dica_ja_mostrada() -> void:
	Global.set_touch_mode(TouchMode.Modo.C, false)
	var h := _nova_dica(true)
	Global.iniciado = true
	await wait_process_frames(2)
	h._input(_toque())
	await wait_seconds(0.6)
	assert_false(h.visible, "pre-condicao: dica oculta apos o fade")
	assert_true(Global.dica_toque_mostrada, "pre-condicao: flag marcada")
	Global.set_touch_mode(TouchMode.Modo.B, false)
	assert_false(Global.dica_toque_mostrada, "trocar o modo rearma a flag")
	await wait_process_frames(2)
	assert_true(h.visible, "a dica reaparece na partida em curso")
	assert_eq(h.textos_atuais(TouchHint.Lado.ESQUERDA), TouchHint.TEXTOS_B_ESQ, "reaparece com o texto do modo novo")


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
