extends GutTest

# Botao de pausa por toque (PauseBotao): retangulo do handoff 7.1, visibilidade do predicado 7.2 e arbitragem
# do toque 7.3 (aciona ao soltar dentro; fora/entrada por arraste/saida por arraste nao pausam).
# Valores esperados vem do handoff, nunca da formula do codigo. Layout injetado, sem janela.
const PEQUENA := Vector2(180.0, 320.0)
const STAGE_SCRIPT := "res://scenes/Stage.gd"


class FakePlayer:
	extends Node
	var fim: bool = false

	func is_end() -> bool:
		return fim


var _fake: FakePlayer
var _pedidos: int = 0


func before_each() -> void:
	Global.iniciado = false
	_pedidos = 0


func after_each() -> void:
	Global.iniciado = false


func _novo_botao(safe: Rect2 = Rect2(Vector2.ZERO, PEQUENA)) -> PauseBotao:
	_fake = FakePlayer.new()
	add_child_autofree(_fake)
	var b := PauseBotao.new()
	b.player = _fake
	add_child_autofree(b)
	b.aplicar_layout(PEQUENA, safe)
	b.pausar_pedido.connect(func() -> void: _pedidos += 1)
	return b


func _ativo(b: PauseBotao) -> void:
	Global.iniciado = true
	_fake.fim = false
	b.atualizar_visibilidade()


func _toque(pos: Vector2, pressionado: bool, idx: int = 0) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.index = idx
	e.position = pos
	e.pressed = pressionado
	return e


func _arraste(pos: Vector2, idx: int = 0) -> InputEventScreenDrag:
	var e := InputEventScreenDrag.new()
	e.index = idx
	e.position = pos
	return e


func test_retangulo_sem_safe_area_e_x2_26_y2_26() -> void:
	var b := _novo_botao()
	var r := b.rect_botao()
	assert_eq(r.position, Vector2(2.0, 2.0), "origem do retangulo com s_* = 0 deve ser (2, 2)")
	assert_eq(r.end, Vector2(26.0, 26.0), "fim do retangulo com s_* = 0 deve ser (26, 26)")


func test_retangulo_com_s_top_20_e_y22_46() -> void:
	var b := _novo_botao(Rect2(0.0, 20.0, 180.0, 300.0))
	var r := b.rect_botao()
	assert_eq(r.position, Vector2(2.0, 22.0), "origem com s_top = 20 deve ser (2, 22)")
	assert_eq(r.end, Vector2(26.0, 46.0), "fim com s_top = 20 deve ser (26, 46)")


func test_retangulo_com_s_left_soma_no_x() -> void:
	var b := _novo_botao(Rect2(10.0, 0.0, 170.0, 320.0))
	var r := b.rect_botao()
	assert_eq(r.position.x, 12.0, "x inicial com s_left = 10 deve ser 12")
	assert_eq(r.end.x, 36.0, "x final com s_left = 10 deve ser 36")


func test_folga_de_15_px_ate_o_placar() -> void:
	var b := _novo_botao()
	var stage = load(STAGE_SCRIPT)
	var placar_x: float = 180.0 - stage.HUD_RIGHT_MARGIN - stage.POINTS_WIDTH
	assert_eq(placar_x - b.rect_botao().end.x, 15.0, "folga ate o placar com s_* = 0 deve ser 15 px")


func test_oculto_no_menu() -> void:
	var b := _novo_botao()
	Global.iniciado = false
	b.atualizar_visibilidade()
	assert_false(b.visible, "no menu (nao iniciado) o botao deve estar oculto")


func test_visivel_so_em_partida_ativa() -> void:
	var b := _novo_botao()
	_ativo(b)
	assert_true(b.visible, "em partida ativa o botao deve estar visivel")


func test_oculto_na_derrota_e_na_animacao_de_derrota() -> void:
	var b := _novo_botao()
	_ativo(b)
	_fake.fim = true
	b.atualizar_visibilidade()
	assert_false(b.visible, "com end ja true (animacao de derrota) o botao deve estar oculto")
	assert_false(b.tratar_evento(_toque(Vector2(10.0, 10.0), true)), "botao oculto nao recebe toque")


func test_soltar_dentro_pausa() -> void:
	var b := _novo_botao()
	_ativo(b)
	assert_true(b.tratar_evento(_toque(Vector2(10.0, 10.0), true)), "pressionar dentro pertence ao botao")
	assert_eq(_pedidos, 0, "pressionar nao pausa, so ativa o estado pressed")
	assert_true(b.esta_pressionado(), "pressionar dentro ativa o estado pressed")
	b.tratar_evento(_toque(Vector2(12.0, 12.0), false))
	assert_eq(_pedidos, 1, "soltar dentro do retangulo deve pausar 1 vez")
	assert_false(b.esta_pressionado(), "soltar limpa o estado pressed")


func test_soltar_fora_nao_pausa() -> void:
	var b := _novo_botao()
	_ativo(b)
	b.tratar_evento(_toque(Vector2(10.0, 10.0), true))
	b.tratar_evento(_toque(Vector2(100.0, 100.0), false))
	assert_eq(_pedidos, 0, "soltar fora do retangulo nao deve pausar")


func test_arrastar_de_fora_para_dentro_nao_pausa() -> void:
	var b := _novo_botao()
	_ativo(b)
	assert_false(b.tratar_evento(_toque(Vector2(100.0, 100.0), true)), "toque que comeca fora nao e do botao")
	assert_false(b.tratar_evento(_arraste(Vector2(10.0, 10.0))), "arraste de fora entrando nao e do botao")
	assert_false(b.tratar_evento(_toque(Vector2(10.0, 10.0), false)), "soltar dentro de toque que veio de fora nao e do botao")
	assert_eq(_pedidos, 0, "toque que comecou fora e entrou no retangulo nao deve pausar")


func test_arrastar_de_dentro_para_fora_cancela() -> void:
	var b := _novo_botao()
	_ativo(b)
	b.tratar_evento(_toque(Vector2(10.0, 10.0), true))
	b.tratar_evento(_arraste(Vector2(100.0, 100.0)))
	assert_false(b.esta_pressionado(), "sair do retangulo cancela o estado pressed")
	b.tratar_evento(_toque(Vector2(10.0, 10.0), false))
	assert_eq(_pedidos, 0, "arrastar para fora e voltar a soltar dentro nao deve pausar")


func _clique(pos: Vector2, pressed: bool, device: int = 0, button: int = MOUSE_BUTTON_LEFT) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.position = pos
	e.pressed = pressed
	e.button_index = button
	e.device = device
	return e


func test_clique_de_mouse_dentro_pausa() -> void:
	var b := _novo_botao()
	_ativo(b)
	assert_true(b.tratar_evento(_clique(Vector2(10.0, 10.0), true)), "pressionar dentro com mouse pertence ao botao")
	assert_eq(_pedidos, 0, "pressionar com mouse nao pausa")
	b.tratar_evento(_clique(Vector2(12.0, 12.0), false))
	assert_eq(_pedidos, 1, "clique de mouse dentro do retangulo deve pausar 1 vez")


func test_clique_de_mouse_emulado_nao_pausa() -> void:
	var b := _novo_botao()
	_ativo(b)
	assert_false(b.tratar_evento(_clique(Vector2(10.0, 10.0), true, InputEvent.DEVICE_ID_EMULATION)), "mouse emulado nao e do botao")
	assert_false(b.tratar_evento(_clique(Vector2(10.0, 10.0), false, InputEvent.DEVICE_ID_EMULATION)), "soltar mouse emulado nao e do botao")
	assert_eq(_pedidos, 0, "mouse emulado a partir do toque nao deve pausar")


func test_clique_de_mouse_soltar_fora_nao_pausa() -> void:
	var b := _novo_botao()
	_ativo(b)
	b.tratar_evento(_clique(Vector2(10.0, 10.0), true))
	b.tratar_evento(_clique(Vector2(100.0, 100.0), false))
	assert_eq(_pedidos, 0, "pressionar dentro e soltar fora com mouse nao deve pausar")
	assert_false(b.esta_pressionado(), "soltar fora com mouse limpa o estado pressed")


func test_cancelar_zera_pressed_e_release_posterior_nao_pausa() -> void:
	var b := _novo_botao()
	_ativo(b)
	b.tratar_evento(_toque(Vector2(10.0, 10.0), true))
	assert_true(b.esta_pressionado(), "precondicao: dedo pressionado no botao")
	b.cancelar()
	assert_false(b.esta_pressionado(), "cancelar() deixa o botao nao pressionado")
	b.tratar_evento(_toque(Vector2(12.0, 12.0), false))
	assert_eq(_pedidos, 0, "release posterior do mesmo dedo apos cancelar() nao deve pausar")


func test_clique_direito_de_mouse_dentro_nao_pausa() -> void:
	var b := _novo_botao()
	_ativo(b)
	assert_false(b.tratar_evento(_clique(Vector2(10.0, 10.0), true, 0, MOUSE_BUTTON_RIGHT)), "pressionar dentro com botao direito nao pertence ao botao")
	assert_false(b.esta_pressionado(), "botao direito nao ativa o estado pressed")
	assert_false(b.tratar_evento(_clique(Vector2(12.0, 12.0), false, 0, MOUSE_BUTTON_RIGHT)), "soltar dentro com botao direito nao pertence ao botao")
	assert_eq(_pedidos, 0, "clique direito dentro do retangulo nao deve pausar")


func test_toque_e_mouse_misturados_dentro_nao_pausam() -> void:
	var b := _novo_botao()
	_ativo(b)
	assert_true(b.tratar_evento(_toque(Vector2(10.0, 10.0), true)), "toque pressionado dentro pertence ao botao")
	assert_false(b.tratar_evento(_clique(Vector2(12.0, 12.0), false)), "soltar mouse esquerdo de outro ponteiro nao e consumido")
	assert_eq(_pedidos, 0, "toque pressionado + mouse solto dentro nao deve pausar")
	b.cancelar()
	assert_true(b.tratar_evento(_clique(Vector2(10.0, 10.0), true)), "mouse esquerdo pressionado dentro pertence ao botao")
	assert_false(b.tratar_evento(_toque(Vector2(12.0, 12.0), false)), "soltar toque de outro ponteiro nao e consumido")
	assert_eq(_pedidos, 0, "mouse pressionado + toque solto dentro nao deve pausar")
