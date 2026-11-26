extends GutTest

# Overlay de pausa (PauseOverlay): layout do handoff 9.2 (valores literais da tabela, nao da formula do codigo),
# alvos de toque, foco por teclado/joypad, toque (soltar dentro aciona, fundo consumido) e a acao `pause`.
const ALTA := Vector2(360.0, 800.0)
const PEQUENA := Vector2(360.0, 640.0)

var _retomou: int = 0
var _abriu_opcoes: int = 0
var _saiu: int = 0


func before_each() -> void:
	_retomou = 0
	_abriu_opcoes = 0
	_saiu = 0


func _novo(tamanho: Vector2, safe: Rect2 = Rect2()) -> PauseOverlay:
	var o := PauseOverlay.new()
	add_child_autofree(o)
	var area := safe if safe.size != Vector2.ZERO else Rect2(Vector2.ZERO, tamanho)
	o.aplicar_layout(tamanho, area)
	o.retomar.connect(func() -> void: _retomou += 1)
	o.opcoes.connect(func() -> void: _abriu_opcoes += 1)
	o.sair.connect(func() -> void: _saiu += 1)
	o.abrir()
	return o


# f527 T6: overlay no modo que permite saida pela pausa (a Stage injeta `regra.permite_sair_pela_pausa()` true)
func _novo_zen(tamanho: Vector2, safe: Rect2 = Rect2()) -> PauseOverlay:
	var o := _novo(tamanho, safe)
	o.definir_permite_sair(true)
	return o


func _acao(nome: String) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = nome
	e.pressed = true
	return e


func _toque(pos: Vector2, pressed: bool, index: int = 0) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.position = pos
	e.pressed = pressed
	e.index = index
	return e


func test_c181_retangulos_batem_com_a_tabela_do_handoff_9_2() -> void:
	var o := _novo(PEQUENA)
	assert_true(o.rect_continuar() == Rect2(68, 294, 224, 64), "360x640: Continuar x[68,292] y[294,358]")
	assert_true(o.rect_opcoes() == Rect2(68, 374, 224, 64), "360x640: Opcoes x[68,292] y[374,438]")
	var alta := _novo(ALTA)
	assert_true(alta.rect_continuar() == Rect2(68, 374, 224, 64), "360x800: Continuar x[68,292] y[374,438]")
	assert_true(alta.rect_opcoes() == Rect2(68, 454, 224, 64), "360x800: Opcoes x[68,292] y[454,518]")
	var entalhe := _novo(PEQUENA, Rect2(0, 40, 360, 588))
	assert_true(entalhe.rect_continuar() == Rect2(68, 308, 224, 64), "s_top 40 / s_bottom 12 (y0 = 216): Continuar y[308,372]")
	assert_true(entalhe.rect_opcoes() == Rect2(68, 388, 224, 64), "s_top 40 / s_bottom 12 (y0 = 216): Opcoes y[388,452]")


# C832: PauseOverlay (bloco de 236 px sem Sair) cabe em 640 e na safe area
func test_c832_bloco_de_236_cabe_em_640_e_na_safe_area() -> void:
	var tela := Rect2(0.0, 0.0, 360.0, 640.0)
	var o := _novo(PEQUENA)
	assert_true(tela.encloses(o.rect_continuar()), "Continuar dentro de 360x640")
	assert_true(tela.encloses(o.rect_opcoes()), "Opcoes dentro de 360x640")
	var safe := Rect2(0, 40, 360, 588)
	var entalhe := _novo(PEQUENA, safe)
	assert_true(safe.encloses(entalhe.rect_continuar()), "Continuar dentro da safe area")
	assert_true(safe.encloses(entalhe.rect_opcoes()), "Opcoes dentro da safe area")
	assert_eq(entalhe.rect_opcoes().end.y - (entalhe.rect_continuar().position.y - 92.0), 236.0, "altura do bloco sem Sair = 236")


func test_c182_alvos_de_48_px_e_16_px_entre_botoes() -> void:
	for tamanho in [PEQUENA, ALTA]:
		var o := _novo(tamanho)
		assert_gte(o.rect_continuar().size.y, 48.0, "Continuar com altura >= 48")
		assert_gte(o.rect_opcoes().size.y, 48.0, "Opcoes com altura >= 48")
		assert_true(o.rect_opcoes().position.y - o.rect_continuar().end.y == 16.0, "16 px entre Continuar e Opcoes")


func test_c183_foco_inicial_circula_e_accept_aciona_o_focado() -> void:
	var o := _novo(PEQUENA)
	assert_eq(o.foco_atual(), PauseOverlay.Botao.CONTINUAR, "foco inicial em Continuar")
	o.tratar_evento(_acao("ui_down"))
	assert_eq(o.foco_atual(), PauseOverlay.Botao.OPCOES, "ui_down: Continuar -> Opcoes")
	o.tratar_evento(_acao("ui_down"))
	assert_eq(o.foco_atual(), PauseOverlay.Botao.CONTINUAR, "ui_down em Opcoes volta a Continuar")
	o.tratar_evento(_acao("ui_up"))
	assert_eq(o.foco_atual(), PauseOverlay.Botao.OPCOES, "ui_up em Continuar vai a Opcoes")
	o.tratar_evento(_acao("ui_up"))
	assert_eq(o.foco_atual(), PauseOverlay.Botao.CONTINUAR, "ui_up em Opcoes volta a Continuar")
	o.tratar_evento(_acao("ui_accept"))
	assert_eq(_retomou, 1, "ui_accept em Continuar emite retomar")
	assert_eq(_abriu_opcoes, 0, "ui_accept em Continuar nao emite opcoes")
	o.tratar_evento(_acao("ui_down"))
	o.tratar_evento(_acao("ui_accept"))
	assert_eq(_abriu_opcoes, 1, "ui_accept em Opcoes emite opcoes")
	assert_eq(_retomou, 1, "ui_accept em Opcoes nao emite retomar")


func test_c184_toque_no_fundo_consumido_sem_retomar_e_soltar_dentro_aciona() -> void:
	var o := _novo(PEQUENA)
	assert_true(o.tratar_evento(_toque(Vector2(5, 5), true)), "toque no fundo e consumido")
	assert_true(o.tratar_evento(_toque(Vector2(5, 5), false)), "soltar no fundo e consumido")
	assert_eq(_retomou, 0, "toque no fundo nao retoma")
	assert_eq(_abriu_opcoes, 0, "toque no fundo nao abre opcoes")
	var dentro := o.rect_continuar().get_center()
	o.tratar_evento(_toque(dentro, true))
	assert_eq(_retomou, 0, "pressionar dentro ainda nao aciona")
	o.tratar_evento(_toque(Vector2(5, 5), false))
	assert_eq(_retomou, 0, "soltar fora do botao nao aciona")
	o.tratar_evento(_toque(dentro, true))
	o.tratar_evento(_toque(dentro, false))
	assert_eq(_retomou, 1, "soltar dentro de Continuar aciona")
	var op := o.rect_opcoes().get_center()
	o.tratar_evento(_toque(op, true))
	o.tratar_evento(_toque(op, false))
	assert_eq(_abriu_opcoes, 1, "soltar dentro de Opcoes emite opcoes")


func test_c185_acao_pause_com_overlay_aberto_emite_retomar() -> void:
	var o := _novo(PEQUENA)
	assert_true(o.tratar_evento(_acao("pause")), "pause e consumida com o overlay aberto")
	assert_eq(_retomou, 1, "pause com overlay aberto emite retomar")
	o.fechar()
	assert_false(o.tratar_evento(_acao("pause")), "pause com overlay fechado nao e do overlay")
	assert_eq(_retomou, 1, "pause com overlay fechado nao emite retomar")


# f527 T6 (D5): com Sair o bloco cresce de 236 para 316 px; o terceiro botao segue o estilo 224x64 com 16 px de
# espaco, centrado igual nas telas 2x do handoff 9.2 (valores literais, nao da formula do codigo).
func test_f527_t6_layout_do_zen_tem_sair_112x32_no_bloco_de_158() -> void:
	var o := _novo_zen(PEQUENA)
	assert_eq(o.rect_sair(), Rect2(68, 414, 224, 64), "360x640: Sair x[68,292] y[414,478]")
	assert_eq(o.rect_sair().position.y - o.rect_opcoes().end.y, 16.0, "16 px entre Opcoes e Sair")
	assert_eq(o.rect_sair().size, o.rect_opcoes().size, "Sair no mesmo tamanho 224x64 dos outros botoes")
	var alta := _novo_zen(ALTA)
	assert_eq(alta.rect_sair(), Rect2(68, 494, 224, 64), "360x800: Sair x[68,292] y[494,558]")
	var entalhe := _novo_zen(PEQUENA, Rect2(0, 40, 360, 588))
	assert_eq(entalhe.rect_sair(), Rect2(68, 428, 224, 64), "s_top 40 / s_bottom 12 (y0 = 176): Sair y[428,492]")
	assert_lt(entalhe.rect_sair().end.y, 628.0, "Sair dentro da safe area")
	assert_eq(entalhe.rect_sair().end.y - 176.0, 316.0, "bloco com Sair = 316")


# C736 [f527 T6]: teclado/gamepad percorre os 3 botoes na ordem Continuar, Opcoes, Sair (depois wrap de volta ao
# Continuar); ui_accept em Sair emite so `sair`; toque e clique arbitram como nos botoes atuais (pressionar nao
# aciona, soltar dentro aciona, soltar fora nao; mouse emulado e botao direito seguem fora do overlay).
func test_c736_teclado_percorre_continuar_opcoes_sair_e_toque_e_clique_arbitram_como_os_atuais() -> void:
	var o := _novo_zen(PEQUENA)
	assert_eq(o.foco_atual(), PauseOverlay.Botao.CONTINUAR, "C736: foco inicial em Continuar")
	o.tratar_evento(_acao("ui_down"))
	assert_eq(o.foco_atual(), PauseOverlay.Botao.OPCOES, "C736: 1o ui_down: Continuar -> Opcoes")
	o.tratar_evento(_acao("ui_down"))
	assert_eq(o.foco_atual(), PauseOverlay.Botao.SAIR, "C736: 2o ui_down: Opcoes -> Sair (apos Opcoes)")
	o.tratar_evento(_acao("ui_accept"))
	assert_eq(_saiu, 1, "C736: ui_accept em Sair emite sair")
	assert_eq(_retomou, 0, "C736: ui_accept em Sair nao emite retomar")
	assert_eq(_abriu_opcoes, 0, "C736: ui_accept em Sair nao emite opcoes")
	o.tratar_evento(_acao("ui_down"))
	assert_eq(o.foco_atual(), PauseOverlay.Botao.CONTINUAR, "C736: 3o ui_down: Sair -> Continuar (wrap)")
	o.tratar_evento(_acao("ui_up"))
	assert_eq(o.foco_atual(), PauseOverlay.Botao.OPCOES, "C736: ui_up segue o mesmo ciclo (Continuar -> Opcoes)")
	o.tratar_evento(_acao("ui_up"))
	assert_eq(o.foco_atual(), PauseOverlay.Botao.SAIR, "C736: ui_up em Opcoes vai a Sair")
	var dentro := o.rect_sair().get_center()
	o.tratar_evento(_toque(dentro, true))
	assert_eq(_saiu, 1, "C736: pressionar dentro de Sair ainda nao aciona")
	o.tratar_evento(_toque(Vector2(5, 5), false))
	assert_eq(_saiu, 1, "C736: soltar fora de Sair nao aciona")
	o.tratar_evento(_toque(dentro, true))
	o.tratar_evento(_toque(dentro, false))
	assert_eq(_saiu, 2, "C736: soltar dentro de Sair aciona ao toque")
	o.tratar_evento(_clique(dentro, true))
	o.tratar_evento(_clique(dentro, false))
	assert_eq(_saiu, 3, "C736: clique de mouse dentro de Sair aciona")
	assert_false(o.tratar_evento(_clique(dentro, true, InputEvent.DEVICE_ID_EMULATION)), "C736: mouse emulado nao e do overlay")
	assert_false(o.tratar_evento(_clique(dentro, true, 0, MOUSE_BUTTON_RIGHT)), "C736: botao direito nao e do overlay")
	assert_true(o.tratar_evento(_toque(Vector2(5, 5), true)), "C736: toque no fundo e consumido")


func test_permite_sair_voltando_a_false_com_foco_em_sair_devolve_o_foco_a_continuar() -> void:
	var o := _novo_zen(PEQUENA)
	o.tratar_evento(_acao("ui_up"))
	o.tratar_evento(_acao("ui_up"))
	assert_eq(o.foco_atual(), PauseOverlay.Botao.SAIR, "pre-condicao: foco em Sair")
	o.definir_permite_sair(false)
	assert_eq(o.foco_atual(), PauseOverlay.Botao.CONTINUAR, "Sair oculto: o foco volta a Continuar")
	o.tratar_evento(_acao("ui_accept"))
	assert_eq(_retomou, 1, "Enter aciona Continuar, o botao visivel")
	assert_eq(_saiu, 0, "Sair oculto nunca aciona")


# C737 [f527 T6]: com o Sair visivel, Continuar e Opcoes se comportam como hoje (`_acionar` do overlay:
# Continuar emite retomar, Opcoes emite opcoes, acao `pause` = Continuar); os testes do Classico (sem Sair)
# seguem verdes sem edicao.
func test_c737_com_o_sair_visivel_continuar_e_opcoes_comportam_se_como_hoje() -> void:
	var o := _novo_zen(PEQUENA)
	o.tratar_evento(_acao("ui_accept"))
	assert_eq(_retomou, 1, "C737: ui_accept em Continuar emite retomar como hoje")
	assert_eq(_saiu, 0, "C737: Continuar nao emite sair")
	o.tratar_evento(_acao("ui_down"))
	o.tratar_evento(_acao("ui_accept"))
	assert_eq(_abriu_opcoes, 1, "C737: ui_accept em Opcoes emite opcoes como hoje")
	assert_eq(_retomou, 1, "C737: Opcoes nao emite retomar")
	assert_true(o.tratar_evento(_acao("pause")), "C737: acao pause segue consumida com o overlay aberto")
	assert_eq(_retomou, 2, "C737: acao pause segue emitindo retomar (Esc/P = Continuar)")
	var c := o.rect_continuar().get_center()
	o.tratar_evento(_toque(c, true))
	o.tratar_evento(_toque(c, false))
	assert_eq(_retomou, 3, "C737: soltar dentro de Continuar retoma como hoje")
	var p := o.rect_opcoes().get_center()
	o.tratar_evento(_toque(p, true))
	o.tratar_evento(_toque(p, false))
	assert_eq(_abriu_opcoes, 2, "C737: soltar dentro de Opcoes abre opcoes como hoje")
	assert_eq(_saiu, 0, "C737: nenhum Sair acionado pelos botoes originais")


# f527 T6 (correcao 1): o Sair do Zen recarrega a cena e o overlay sai da arvore durante o `_input`; o viewport
# capturado antes de `tratar_evento` evita `set_input_as_handled` em null (SCRIPT ERROR do smoke `modo-zen`).
func test_f527_t6_input_em_sair_com_overlay_removido_da_arvore_nao_usa_viewport_nulo() -> void:
	var o := _novo_zen(PEQUENA)
	o.sair.connect(func() -> void: o.get_parent().remove_child(o))
	var dentro := o.rect_sair().get_center()
	o._input(_clique(dentro, true))
	o._input(_clique(dentro, false))
	assert_eq(_saiu, 1, "clique em Sair emitiu sair uma vez pelo _input")
	assert_false(o.is_inside_tree(), "overlay saiu da arvore durante o _input (simula o reload)")


func _clique(pos: Vector2, pressed: bool, device: int = 0, botao: int = MOUSE_BUTTON_LEFT) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.position = pos
	e.pressed = pressed
	e.button_index = botao
	e.device = device
	return e


func test_clique_de_mouse_dentro_de_continuar_emite_retomar() -> void:
	var o := _novo(PEQUENA)
	var dentro := o.rect_continuar().get_center()
	assert_true(o.tratar_evento(_clique(dentro, true)), "pressionar dentro de Continuar e consumido")
	assert_eq(_retomou, 0, "pressionar dentro ainda nao aciona")
	assert_true(o.tratar_evento(_clique(dentro, false)), "soltar dentro e consumido")
	assert_eq(_retomou, 1, "clique de mouse dentro de Continuar emite retomar")


func test_clique_de_mouse_no_fundo_e_consumido_e_nao_retoma() -> void:
	var o := _novo(PEQUENA)
	assert_true(o.tratar_evento(_clique(Vector2(5, 5), true)), "pressionar no fundo e consumido")
	assert_true(o.tratar_evento(_clique(Vector2(5, 5), false)), "soltar no fundo e consumido")
	assert_eq(_retomou, 0, "clique no fundo nao retoma")
	assert_eq(_abriu_opcoes, 0, "clique no fundo nao abre opcoes")


func test_clique_de_mouse_soltar_fora_nao_aciona() -> void:
	var o := _novo(PEQUENA)
	var dentro := o.rect_continuar().get_center()
	o.tratar_evento(_clique(dentro, true))
	assert_true(o.tratar_evento(_clique(Vector2(5, 5), false)), "soltar fora ainda e consumido pelo overlay")
	assert_eq(_retomou, 0, "pressionar dentro e soltar fora nao emite retomar")


func test_clique_de_mouse_emulado_nao_aciona_e_nao_e_consumido() -> void:
	var o := _novo(PEQUENA)
	var dentro := o.rect_continuar().get_center()
	assert_false(o.tratar_evento(_clique(dentro, true, InputEvent.DEVICE_ID_EMULATION)), "mouse emulado nao e do overlay")
	assert_false(o.tratar_evento(_clique(dentro, false, InputEvent.DEVICE_ID_EMULATION)), "soltar mouse emulado nao e do overlay")
	assert_eq(_retomou, 0, "mouse emulado a partir do toque nao emite retomar")


func test_clique_de_botao_direito_nao_aciona() -> void:
	var o := _novo(PEQUENA)
	var dentro := o.rect_continuar().get_center()
	assert_false(o.tratar_evento(_clique(dentro, true, 0, MOUSE_BUTTON_RIGHT)), "botao direito nao e do overlay")
	assert_false(o.tratar_evento(_clique(dentro, false, 0, MOUSE_BUTTON_RIGHT)), "soltar botao direito nao e do overlay")
	assert_eq(_retomou, 0, "botao direito nao emite retomar")
