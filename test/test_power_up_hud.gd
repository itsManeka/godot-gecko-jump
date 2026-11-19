extends GutTest

# T5 (f521): faixa de HUD da duracao do power-up na Stage real. Cenarios C558-C562 do 05-test-plan.
# O estado e manipulado direto no PowerUpState da Stage (coletar/_restante) e o HUD e sincronizado por
# atualizar(), sem esperar frames: a leitura do estado e o que se prova, nao o relogio.

const STAGE_SCENE := "res://scenes/Stage.tscn"
const DURACAO := 10.0

var _stage: Node = null
var _iniciado_original := false
var _plataformas_original: Array = []
var _tutorial_espelho_original := false


class FakeA:
	extends PowerUp

	func _init() -> void:
		nome = &"fake_hud_a"
		duracao = DURACAO


class FakeB:
	extends PowerUp

	func _init() -> void:
		nome = &"fake_hud_b"
		duracao = DURACAO


class FakeCarga:
	extends PowerUp

	func _init() -> void:
		nome = &"fake_hud_carga"
		duracao = 0.0


func before_each() -> void:
	_iniciado_original = Global.iniciado
	_plataformas_original = Global.platforms
	_tutorial_espelho_original = Global.tutorial_visto_espelho
	Global.tutorial_visto_espelho = true
	Global.platforms = []
	Global.iniciado = false


func after_each() -> void:
	get_tree().paused = false
	_stage = null
	Global.iniciado = _iniciado_original
	Global.platforms = _plataformas_original
	Global.tutorial_visto_espelho = _tutorial_espelho_original


func _novo_stage() -> Node:
	var stage: Node = add_child_autofree(load(STAGE_SCENE).instantiate())
	await wait_frames(2)
	return stage


func _estado() -> PowerUpState:
	return _stage.get("power_up_estado") as PowerUpState


func _hud() -> PowerUpHud:
	return _stage.get("power_up_hud") as PowerUpHud


# C558: segundos = teto do restante; barra proporcional ao restante, x esquerdo fixo (encolhe pela direita)
func test_segundos_teto_do_restante_e_barra_proporcional_encolhe_pela_direita() -> void:
	_stage = await _novo_stage()
	var hud := _hud()
	assert_ne(hud, null, "fixture: a Stage cria a faixa de HUD")
	assert_eq(hud.estado, _estado(), "o HUD le o estado da partida da Stage")
	_estado().coletar(FakeA.new())
	_estado()._restante = 4.2
	hud.atualizar()
	assert_eq(hud.texto_segundos(), "5", "4,2 s mostra 5 (teto do restante)")
	_estado()._restante = 4.0
	hud.atualizar()
	assert_eq(hud.texto_segundos(), "4", "4,0 s mostra 4 (inteiro exato nao sobe)")
	_estado()._restante = DURACAO / 2.0
	hud.atualizar()
	assert_almost_eq(hud.rect_barra_cheia().size.x, 20.0, 0.001, "metade do tempo = 20 px de 40")
	assert_eq(hud.rect_barra_cheia().position.x, 22.0, "barra comeca em x 22")
	var direita_metade: float = hud.rect_barra_cheia().end.x
	_estado()._restante = DURACAO / 4.0
	hud.atualizar()
	assert_almost_eq(hud.rect_barra_cheia().size.x, 10.0, 0.001, "um quarto do tempo = 10 px de 40")
	assert_eq(hud.rect_barra_cheia().position.x, 22.0, "x esquerdo fixo: encolhe pela direita")
	assert_lt(hud.rect_barra_cheia().end.x, direita_metade, "a borda direita recua com o tempo")
	assert_eq(hud.rect_barra().size, Vector2(40.0, 4.0), "moldura da barra segue 40x4")


# C559: ao expirar a faixa some por inteiro; sem carga o slot da carga e ausente, com carga o "+" aparece
func test_expirar_oculta_a_faixa_e_carga_so_aparece_com_carga() -> void:
	_stage = await _novo_stage()
	var hud := _hud()
	hud.atualizar()
	assert_false(hud.icone_visivel(), "sem power-up: icone ausente")
	assert_false(hud.barra_visivel(), "sem power-up: barra ausente")
	assert_false(hud.segundos_visivel(), "sem power-up: segundos ausentes")
	assert_false(hud.carga_visivel(), "sem carga: slot ausente")
	_estado().coletar(FakeA.new())
	hud.atualizar()
	assert_true(hud.icone_visivel(), "temporizado ativo: icone visivel")
	assert_true(hud.barra_visivel(), "temporizado ativo: barra visivel")
	assert_true(hud.segundos_visivel(), "temporizado ativo: segundos visiveis")
	assert_false(hud.carga_visivel(), "temporizado nao acende o slot da carga")
	_estado().tick(DURACAO + 1.0)
	hud.atualizar()
	assert_false(hud.icone_visivel(), "expirou: icone some")
	assert_false(hud.barra_visivel(), "expirou: barra some")
	assert_false(hud.segundos_visivel(), "expirou: segundos somem")
	_estado().coletar(FakeCarga.new())
	hud.atualizar()
	assert_true(hud.carga_visivel(), "com carga o '+' aparece")
	assert_eq(hud.rect_carga(), Rect2(90.0, 30.0, 16.0, 16.0), "slot da carga em x 90-106")
	assert_false(hud.icone_visivel(), "a carga nao acende o icone do temporizado")
	_estado().consumir_carga()
	hud.atualizar()
	assert_false(hud.carga_visivel(), "carga gasta: slot some")


# C560: retangulos iguais em 180x320 e 180x400 (y0 = s_top + 30) e reposicionados por apply_layout
func test_retangulos_iguais_em_320_e_400_e_seguem_o_topo_da_safe_area() -> void:
	_stage = await _novo_stage()
	var hud := _hud()
	_stage.call("apply_layout", Vector2(180.0, 320.0), Rect2(0.0, 0.0, 180.0, 320.0))
	var em_320: Array[Rect2] = [
		hud.rect_faixa(), hud.rect_icone(), hud.rect_barra(), hud.rect_segundos(), hud.rect_carga()
	]
	_stage.call("apply_layout", Vector2(180.0, 400.0), Rect2(0.0, 0.0, 180.0, 400.0))
	var em_400: Array[Rect2] = [
		hud.rect_faixa(), hud.rect_icone(), hud.rect_barra(), hud.rect_segundos(), hud.rect_carga()
	]
	assert_eq(em_400, em_320, "mesma medida em 180x320 e 180x400")
	assert_eq(em_320[0], Rect2(0.0, 30.0, 180.0, 16.0), "faixa x 0-180, y 30-46")
	assert_eq(em_320[1], Rect2(2.0, 30.0, 16.0, 16.0), "icone x 2-18")
	assert_eq(em_320[2], Rect2(22.0, 36.0, 40.0, 4.0), "barra x 22-62, y 36-40")
	assert_eq(em_320[3], Rect2(66.0, 30.0, 16.0, 16.0), "segundos x 66-82")
	assert_eq(em_320[4], Rect2(90.0, 30.0, 16.0, 16.0), "carga x 90-106")
	# safe area com topo em 24: a faixa desce junto (y0 = s_top + 30)
	_stage.call("apply_layout", Vector2(180.0, 400.0), Rect2(0.0, 24.0, 180.0, 376.0))
	assert_eq(hud.rect_faixa().position.y, 54.0, "y0 = s_top + 30")
	assert_eq(hud.rect_icone().position.y, 54.0, "icone acompanha a safe area")
	assert_eq(hud.rect_barra().position.y, 60.0, "barra acompanha a safe area")


# C561: card do tutorial aberto oculta a faixa inteira (mesmo com fake ativo) e ao fechar ela volta
func test_card_do_tutorial_aberto_oculta_a_faixa_e_ao_fechar_volta() -> void:
	_stage = await _novo_stage()
	var hud := _hud()
	_stage.call("_on_Play_button_down")
	_estado().coletar(FakeA.new())
	_estado().coletar(FakeCarga.new())
	hud.atualizar()
	assert_true(hud.icone_visivel(), "fixture: faixa visivel antes do card")
	assert_true(hud.carga_visivel(), "fixture: carga visivel antes do card")
	var card: TutorialCard = _stage.get("tutorial_card") as TutorialCard
	card.abrir(TutorialCard.Variante.TECLADO)
	assert_true(card.esta_aberto(), "fixture: card aberto")
	hud.atualizar()
	assert_false(hud.icone_visivel(), "card aberto: icone oculto")
	assert_false(hud.barra_visivel(), "card aberto: barra oculta")
	assert_false(hud.segundos_visivel(), "card aberto: segundos ocultos")
	assert_false(hud.carga_visivel(), "card aberto: carga oculta")
	card.fechar(true)
	assert_false(card.esta_aberto(), "fixture: card fechado")
	hud.atualizar()
	assert_true(hud.icone_visivel(), "card fechado: icone volta")
	assert_true(hud.barra_visivel(), "card fechado: barra volta")
	assert_true(hud.segundos_visivel(), "card fechado: segundos voltam")
	assert_true(hud.carga_visivel(), "card fechado: carga volta")


# C562: forma do icone distinta por tipo; o desenho do HUD so usa branco e preto (nunca cor de plataforma)
func test_forma_do_icone_distinta_por_tipo_e_desenho_so_em_branco_e_preto() -> void:
	_stage = await _novo_stage()
	var hud := _hud()
	_estado().coletar(FakeA.new())
	hud.atualizar()
	var forma_a: Array = hud.comandos_icone().duplicate(true)
	_estado().coletar(FakeB.new())
	hud.atualizar()
	var forma_b: Array = hud.comandos_icone().duplicate(true)
	assert_gt(forma_a.size(), 1, "o icone tem desenho alem do fundo")
	assert_ne(forma_a, forma_b, "dois tipos dao desenhos diferentes")
	assert_ne(
		PowerUpHud.comandos_do_tipo(&"camaleao"),
		PowerUpHud.comandos_do_tipo(&"desacelera"),
		"formas proprias distintas (camaleao x ampulheta)"
	)
	_estado().coletar(FakeCarga.new())
	hud.atualizar()
	var todos: Array = []
	todos.append_array(hud.comandos_icone())
	todos.append_array(hud.comandos_barra())
	todos.append_array(hud.comandos_carga())
	for nome in [&"camaleao", &"desacelera", &"segunda_chance"]:
		todos.append_array(PowerUpHud.comandos_do_tipo(nome))
	assert_gt(todos.size(), 6, "fixture: ha comandos de desenho para conferir")
	var cores_plataforma: Array[Color] = []
	for c in Enums.COLOR.values():
		cores_plataforma.append(Enums.get_cor(c))
	for comando in todos:
		var cor: Color = comando["cor"]
		assert_true(cor == Color(1, 1, 1, 1) or cor == Color(0, 0, 0, 1), "so branco ou preto: %s" % cor)
		assert_false(cores_plataforma.has(cor), "nunca a cor de uma plataforma: %s" % cor)
