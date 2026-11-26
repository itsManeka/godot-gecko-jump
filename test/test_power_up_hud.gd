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
	assert_almost_eq(hud.rect_barra_cheia().size.x, 40.0, 0.001, "metade do tempo = 40 px de 80")
	assert_eq(hud.rect_barra_cheia().position.x, 44.0, "barra comeca em x 44")
	var direita_metade: float = hud.rect_barra_cheia().end.x
	_estado()._restante = DURACAO / 4.0
	hud.atualizar()
	assert_almost_eq(hud.rect_barra_cheia().size.x, 20.0, 0.001, "um quarto do tempo = 20 px de 80")
	assert_eq(hud.rect_barra_cheia().position.x, 44.0, "x esquerdo fixo: encolhe pela direita")
	assert_lt(hud.rect_barra_cheia().end.x, direita_metade, "a borda direita recua com o tempo")
	assert_eq(hud.rect_barra().size, Vector2(80.0, 8.0), "area da barra segue 80x8")


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
	assert_eq(hud.rect_carga(), Rect2(180.0, 60.0, 32.0, 32.0), "slot da carga em x 180-212")
	assert_false(hud.icone_visivel(), "a carga nao acende o icone do temporizado")
	_estado().consumir_carga()
	hud.atualizar()
	assert_false(hud.carga_visivel(), "carga gasta: slot some")


# C560: retangulos iguais em 360x640 e 360x800 (y0 = s_top + 60) e reposicionados por apply_layout
func test_retangulos_iguais_em_640_e_800_e_seguem_o_topo_da_safe_area() -> void:
	_stage = await _novo_stage()
	var hud := _hud()
	_stage.call("apply_layout", Vector2(360.0, 640.0), Rect2(0.0, 0.0, 360.0, 640.0))
	var em_640: Array[Rect2] = [
		hud.rect_faixa(), hud.rect_icone(), hud.rect_barra(), hud.rect_segundos(), hud.rect_carga()
	]
	_stage.call("apply_layout", Vector2(360.0, 800.0), Rect2(0.0, 0.0, 360.0, 800.0))
	var em_800: Array[Rect2] = [
		hud.rect_faixa(), hud.rect_icone(), hud.rect_barra(), hud.rect_segundos(), hud.rect_carga()
	]
	assert_eq(em_800, em_640, "mesma medida em 360x640 e 360x800")
	assert_eq(em_640[0], Rect2(0.0, 60.0, 360.0, 32.0), "faixa x 0-360, y 60-92")
	assert_eq(em_640[1], Rect2(4.0, 60.0, 32.0, 32.0), "icone x 4-36")
	assert_eq(em_640[2], Rect2(44.0, 72.0, 80.0, 8.0), "barra x 44-124, y 72-80")
	assert_eq(em_640[3], Rect2(132.0, 60.0, 32.0, 32.0), "segundos x 132-164")
	assert_eq(em_640[4], Rect2(180.0, 60.0, 32.0, 32.0), "carga x 180-212")
	# safe area com topo em 48: a faixa desce junto (y0 = s_top + 60)
	_stage.call("apply_layout", Vector2(360.0, 800.0), Rect2(0.0, 48.0, 360.0, 752.0))
	assert_eq(hud.rect_faixa().position.y, 108.0, "y0 = s_top + 60")
	assert_eq(hud.rect_icone().position.y, 108.0, "icone acompanha a safe area")
	assert_eq(hud.rect_barra().position.y, 120.0, "barra acompanha a safe area")


# C828: moldura da barra de 2 px por fora dos 80x8; segundos e relogio nao passam de x=360 na fonte 32; desenhos em 32x32
func test_c828_moldura_relogio_e_desenhos_contidos_em_2x() -> void:
	_stage = await _novo_stage()
	var hud := _hud()
	_stage.call("apply_layout", Vector2(360.0, 640.0), Rect2(0.0, 0.0, 360.0, 640.0))
	var barra: Control = hud._barra
	assert_eq(barra.size, Vector2(84.0, 12.0), "moldura de 2 px por fora de 80x8")
	assert_eq(barra.position, Vector2(42.0, 70.0), "moldura comeca 2 px antes da barra")
	assert_lte(hud.rect_segundos().end.x, 360.0, "segundos dentro de x=360")
	assert_lte(hud.rect_relogio().end.x, 360.0, "relogio dentro de x=360")
	var fonte: Font = UiHelpers.FONTE
	var largura_relogio: float = fonte.get_string_size("0:59", HORIZONTAL_ALIGNMENT_LEFT, -1, UiHelpers.TAMANHO_TEXTO).x
	assert_lte(largura_relogio, hud.rect_relogio().size.x, "0:59 cabe na caixa do relogio na fonte 32")
	assert_lte(hud.rect_relogio().position.x + largura_relogio, 360.0, "0:59 nao passa de x=360")
	assert_eq(PowerUpDesenho.TAM, 32.0, "TAM do desenho = 32")
	assert_eq(PowerUpIcone.TAMANHO_PX, 32, "TAMANHO_PX do icone = 32")
	var caixa := Rect2(0.0, 0.0, 32.0, 32.0)
	for nome in [&"camaleao", &"desacelera", &"segunda_chance", &"fake_sem_forma"]:
		for c: Dictionary in PowerUpDesenho.comandos(nome):
			if c["forma"] == &"poly":
				for p: Vector2 in c["pontos"]:
					assert_true(caixa.has_point(p) or p.x == 32.0 or p.y == 32.0, "ponto %s de %s dentro de 32x32" % [p, nome])
			else:
				assert_true(caixa.encloses(c["rect"]), "rect %s de %s dentro de 32x32" % [c["rect"], nome])


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


# C617 [mutacao]: comandos_barra() so muda quando a largura inteira (ceil, 0..80 px) muda; restantes com a mesma
# largura inteira reusam o mesmo array (sem reconstruir a cada frame)
func test_comandos_barra_so_reconstroi_quando_a_largura_inteira_muda() -> void:
	_stage = await _novo_stage()
	var hud := _hud()
	_estado().coletar(FakeA.new())
	_estado()._restante = 5.1
	hud.atualizar()
	var primeiro: Array = hud.comandos_barra()
	assert_almost_eq(hud.rect_barra_cheia().size.x, 40.8, 0.001, "fixture: 5,1 s = 40,8 px (ceil 41)")
	_estado()._restante = 5.12
	hud.atualizar()
	assert_true(is_same(primeiro, hud.comandos_barra()), "mesma largura inteira (41 px): nao reconstroi")
	_estado()._restante = 5.2
	hud.atualizar()
	assert_false(is_same(primeiro, hud.comandos_barra()), "largura inteira mudou (42 px): reconstroi")
	assert_eq(hud.comandos_barra()[1]["rect"].size.x, 42.0, "a parte branca usa a largura inteira nova")


# C618: rect_barra_cheia() esvazia pela direita; extremos: restante cheio -> 80 px, restante 0 -> 0 px
func test_rect_barra_cheia_esvazia_pela_direita_nos_extremos() -> void:
	_stage = await _novo_stage()
	var hud := _hud()
	_estado().coletar(FakeA.new())
	_estado()._restante = DURACAO
	hud.atualizar()
	assert_eq(hud.rect_barra_cheia().size.x, 80.0, "restante cheio: 80 px")
	assert_eq(hud.rect_barra_cheia().position.x, 44.0, "restante cheio: x esquerdo em 44")
	_estado()._restante = 0.0
	hud.atualizar()
	assert_eq(hud.rect_barra_cheia().size.x, 0.0, "restante 0: 0 px")
	assert_eq(hud.rect_barra_cheia().position.x, 44.0, "restante 0: x esquerdo fixo em 44 (esvazia pela direita)")
