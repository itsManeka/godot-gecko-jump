extends GutTest

# Overlay de pausa (PauseOverlay): layout do handoff 9.2 (valores literais da tabela, nao da formula do codigo),
# alvos de toque, foco por teclado/joypad, toque (soltar dentro aciona, fundo consumido) e a acao `pause`.
const ALTA := Vector2(180.0, 400.0)
const PEQUENA := Vector2(180.0, 320.0)

var _retomou: int = 0
var _abriu_opcoes: int = 0


func before_each() -> void:
	_retomou = 0
	_abriu_opcoes = 0


func _novo(tamanho: Vector2, safe: Rect2 = Rect2()) -> PauseOverlay:
	var o := PauseOverlay.new()
	add_child_autofree(o)
	var area := safe if safe.size != Vector2.ZERO else Rect2(Vector2.ZERO, tamanho)
	o.aplicar_layout(tamanho, area)
	o.retomar.connect(func() -> void: _retomou += 1)
	o.opcoes.connect(func() -> void: _abriu_opcoes += 1)
	o.abrir()
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
	assert_true(o.rect_continuar() == Rect2(34, 147, 112, 32), "180x320: Continuar x[34,146] y[147,179]")
	assert_true(o.rect_opcoes() == Rect2(34, 187, 112, 32), "180x320: Opcoes x[34,146] y[187,219]")
	var alta := _novo(ALTA)
	assert_true(alta.rect_continuar() == Rect2(34, 187, 112, 32), "180x400: Continuar x[34,146] y[187,219]")
	assert_true(alta.rect_opcoes() == Rect2(34, 227, 112, 32), "180x400: Opcoes x[34,146] y[227,259]")
	var entalhe := _novo(PEQUENA, Rect2(0, 20, 180, 294))
	assert_true(entalhe.rect_continuar() == Rect2(34, 154, 112, 32), "s_top 20 / s_bottom 6 (y0 = 108): Continuar y[154,186]")
	assert_true(entalhe.rect_opcoes() == Rect2(34, 194, 112, 32), "s_top 20 / s_bottom 6 (y0 = 108): Opcoes y[194,226]")


func test_c182_alvos_de_24_px_e_8_px_entre_botoes() -> void:
	for tamanho in [PEQUENA, ALTA]:
		var o := _novo(tamanho)
		assert_gte(o.rect_continuar().size.y, 24.0, "Continuar com altura >= 24")
		assert_gte(o.rect_opcoes().size.y, 24.0, "Opcoes com altura >= 24")
		assert_true(o.rect_opcoes().position.y - o.rect_continuar().end.y == 8.0, "8 px entre Continuar e Opcoes")


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
