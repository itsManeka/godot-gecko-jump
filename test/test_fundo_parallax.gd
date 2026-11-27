extends GutTest

# f559 T5: controlador de fundo (Fundo + FundoParallax). Alturas de textura sempre passadas como parametro (imagens em
# memoria): nenhum teste fixa a altura dos PNG provisorios nem le pixel deles.
const STAGE := "res://scenes/Stage.tscn"
const LARGURA := 360
const ALTURA_CEU := 1034
const EPS := 0.001
var _sv: SubViewport
var _scroll: ScrollLevel
var _fundo: Fundo
var _stage: Node
var _p: Node


func before_each() -> void:
	Global.tutorial_visto_espelho = true
	Global.platforms = []
	Global.iniciado = false


func after_each() -> void:
	get_tree().paused = false
	if is_instance_valid(_p):
		_p.end = true
	Global.set_modo_jogo(GameModes.ID_CLASSICO)
	Global.platforms = []
	Global.iniciado = false


func _textura(altura: int) -> ImageTexture:
	return ImageTexture.create_from_image(Image.create(LARGURA, altura, false, Image.FORMAT_RGBA8))


# Fundo avulso num SubViewport da altura dada, com um ScrollLevel solto (so position_scrolled/fator_forcado) como fonte
func _spawn_fundo(alturas: Array, altura_tela: int = 640) -> void:
	_sv = SubViewport.new()
	_sv.size = Vector2i(LARGURA, altura_tela)
	add_child_autofree(_sv)
	_scroll = ScrollLevel.new()
	autofree(_scroll)
	_fundo = Fundo.new()
	_fundo.scroll_level = _scroll
	_fundo.definir_texturas(
		[_textura(ALTURA_CEU), _textura(alturas[0]), _textura(alturas[1]), _textura(alturas[2])]
	)
	_sv.add_child(_fundo)
	await wait_process_frames(1)


# Stage real em SubViewport 360x640 com a regra injetada; fisica desligada (os testes dirigem o scroll a mao)
func _spawn_stage(regra: GameModeRule) -> void:
	_sv = SubViewport.new()
	_sv.size = Vector2i(LARGURA, 640)
	add_child_autofree(_sv)
	_stage = load(STAGE).instantiate()
	_stage.regra = regra
	_sv.add_child(_stage)
	_scroll = _stage.get_node("ScrollLevel")
	_p = _stage.get_node("Node2D/Player")
	_scroll.set_physics_process(false)
	_p.set_physics_process(false)
	_stage.set_physics_process(false)
	await wait_process_frames(1)


# Cobertura vertical da uniao dos retangulos: y do inicio, maior furo entre retangulos e y do fim; x inteiro em [0,360]
func _uniao(retangulos: Array[Rect2]) -> Dictionary:
	var ordenados: Array[Rect2] = retangulos.duplicate()
	ordenados.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.y < b.position.y)
	var inicio: float = ordenados[0].position.y
	var alcance: float = ordenados[0].end.y
	var furo: float = 0.0
	var x_ok: bool = true
	for r in ordenados:
		furo = maxf(furo, r.position.y - alcance)
		alcance = maxf(alcance, r.end.y)
		x_ok = x_ok and r.position.x <= 0.0 and r.end.x >= float(LARGURA)
	return {"inicio": inicio, "furo": furo, "fim": alcance, "x_ok": x_ok}


func _offsets() -> Array[float]:
	return [_fundo.offset_camada(0), _fundo.offset_camada(1), _fundo.offset_camada(2)]


# --- FundoParallax (regra pura) ---


func test_offset_puro_e_proporcional_com_wrap_na_altura_da_textura() -> void:
	assert_almost_eq(FundoParallax.offset(100.0, 0.05, 960.0), 5.0, EPS, "scroll 100 a 0.05 = 5")
	assert_almost_eq(FundoParallax.offset(0.0, 0.3, 960.0), 0.0, EPS, "scroll 0 = offset 0")
	assert_almost_eq(FundoParallax.offset(3200.0, 0.3, 960.0), 0.0, EPS, "3200 x 0.3 = 960 volta a 0")
	assert_almost_eq(FundoParallax.offset(3300.0, 0.3, 1000.0), 990.0, EPS, "wrap na altura da propria textura (1000)")


func test_offset_puro_degenerado_nao_e_negativo_nem_divide_por_zero() -> void:
	assert_almost_eq(FundoParallax.offset(-500.0, 0.3, 960.0), 0.0, EPS, "scroll negativo = 0")
	assert_almost_eq(FundoParallax.offset(500.0, 0.3, 0.0), 0.0, EPS, "textura sem altura = 0")
	assert_eq(FundoParallax.quantidade_tiles(640.0, 0.0), 0, "textura sem altura = 0 tiles")


func test_quantidade_de_tiles_e_teto_da_razao_mais_um() -> void:
	assert_eq(FundoParallax.quantidade_tiles(640.0, 960.0), 2, "640/960 -> 1 + 1")
	assert_eq(FundoParallax.quantidade_tiles(924.0, 960.0), 2, "924/960 -> 1 + 1")
	assert_eq(FundoParallax.quantidade_tiles(1034.0, 960.0), 3, "1034/960 -> 2 + 1")
	assert_eq(FundoParallax.quantidade_tiles(960.0, 960.0), 2, "960/960 exato -> 1 + 1")


func test_biomas_tem_4_entradas_de_4_texturas() -> void:
	for bioma in range(FundoBiomas.QUANTIDADE):
		var texturas: Array = FundoBiomas.texturas(bioma)
		assert_eq(texturas.size(), 4, "bioma %d: ceu + c0 + c1 + c2" % bioma)
		assert_eq(texturas[0].get_height(), ALTURA_CEU, "bioma %d: ceu 1034 de altura" % bioma)
		for i in range(1, 4):
			assert_gte(texturas[i].get_height(), 960, "bioma %d: camada %d com H >= 960" % [bioma, i])


# --- C900 ---


func test_cobertura_no_pior_offset_sem_faixa_em_todas_as_alturas() -> void:
	var conjuntos: Array = [[960, 960, 960], [1558, 1558, 1558], [300, 513, 777]]
	for alturas: Array in conjuntos:
		for altura_tela in [640, 800, 924, 1034]:
			await _spawn_fundo(alturas, altura_tela)
			for i in range(3):
				var h: float = float(alturas[i])
				for offset_alvo in [0.0, h - 0.01]:
					_fundo.acumulado = offset_alvo / FundoParallax.FATORES[i]
					_fundo.atualizar_posicoes()
					var rotulo := "C900 H_tex=%d camada %d tela %d offset %.2f" % [int(h), i, altura_tela, offset_alvo]
					var uniao: Dictionary = _uniao(_fundo.retangulos_camada(i))
					assert_lte(float(uniao["inicio"]), 0.0, rotulo + ": a uniao comeca em y <= 0")
					assert_lte(float(uniao["furo"]), EPS, rotulo + ": nenhum furo entre tiles")
					assert_gte(float(uniao["fim"]), float(altura_tela), rotulo + ": a uniao chega a altura da tela")
					assert_true(bool(uniao["x_ok"]), rotulo + ": cobre [0,360] em x")
			_sv.queue_free()
			await wait_process_frames(1)


# --- C901 ---


func test_offset_parado_sem_partida_com_pausa_e_com_scroll_forcado_zero() -> void:
	await _spawn_fundo([960, 1200, 1440])
	Global.iniciado = false
	_scroll.position_scrolled = 100.0
	_fundo.atualizar()
	assert_eq(_offsets(), [0.0, 0.0, 0.0] as Array[float], "C901: sem partida iniciada o offset nao anda")

	Global.iniciado = true
	get_tree().paused = true
	_scroll.position_scrolled = 200.0
	_fundo.atualizar()
	get_tree().paused = false
	assert_eq(_offsets(), [0.0, 0.0, 0.0] as Array[float], "C901: com a arvore pausada o offset nao anda")

	_scroll.fator_forcado = 0.0
	_scroll.position_scrolled = 300.0
	_fundo.atualizar()
	assert_eq(_offsets(), [0.0, 0.0, 0.0] as Array[float], "C901: Zen (fator_forcado 0) mesmo com position_scrolled andando")

	_scroll.fator_forcado = 1.0
	_scroll.position_scrolled = 400.0
	_fundo.atualizar()
	assert_almost_eq(_fundo.offset_camada(0), 5.0, EPS, "C901: so o scroll depois de voltar a partida ativa conta (100 px)")


func test_zen_na_stage_com_avancar_camera_mantem_o_offset_parado_e_classico_anda() -> void:
	var limite: float = CameraFollow.limite_y(640.0)
	await _spawn_stage(ZenRule.new())
	Global.iniciado = true
	_p.global_position.y = limite - 100.0
	_scroll.avancar_camera(_p, limite)
	assert_gt(_scroll.position_scrolled, 0.0, "pre-condicao: avancar_camera moveu position_scrolled")
	await wait_process_frames(1)
	assert_eq(_stage.fundo.acumulado, 0.0, "Zen: o avanco da camera nao move o fundo")

	_p.end = true
	_sv.queue_free()
	await wait_process_frames(1)
	Global.iniciado = false
	await _spawn_stage(ClassicoRule.new())
	Global.iniciado = true
	_p.global_position.y = limite - 100.0
	_scroll.avancar_camera(_p, limite)
	await wait_process_frames(1)
	assert_gt(_stage.fundo.acumulado, 0.0, "Classico: o avanco da camera move o fundo")


# --- C902 ---


func test_partida_ativa_offset_e_o_scroll_vezes_0_05_0_15_0_30() -> void:
	await _spawn_fundo([960, 1200, 1440])
	Global.iniciado = true
	_scroll.position_scrolled = 100.0
	_fundo.atualizar()
	assert_almost_eq(_fundo.offset_camada(0), 5.0, EPS, "C902: scroll 100 -> c0 = 5")
	assert_almost_eq(_fundo.offset_camada(1), 15.0, EPS, "C902: scroll 100 -> c1 = 15")
	assert_almost_eq(_fundo.offset_camada(2), 30.0, EPS, "C902: scroll 100 -> c2 = 30")
	_scroll.position_scrolled = 300.0
	_fundo.atualizar()
	assert_almost_eq(_fundo.offset_camada(0), 15.0, EPS, "C902: scroll 300 -> c0 = 15 (acumula o delta)")
	assert_almost_eq(_fundo.offset_camada(1), 45.0, EPS, "C902: scroll 300 -> c1 = 45")
	assert_almost_eq(_fundo.offset_camada(2), 90.0, EPS, "C902: scroll 300 -> c2 = 90")
	var y_c0: float = _fundo.tiles_da_camada(0)[1].position.y
	assert_almost_eq(y_c0, 15.0, EPS, "C902: o tile 1 de c0 desenha no offset arredondado (15)")


# --- C903 ---


func test_camadas_abaixo_do_jogo_e_do_hud_na_stage() -> void:
	await _spawn_stage(ClassicoRule.new())
	var fundo: Fundo = _stage.fundo
	assert_not_null(fundo, "C903: a Stage cria o Fundo")
	assert_lt(fundo.layer, 0, "C903: layer do fundo abaixo de 0 (jogo)")
	assert_lt(fundo.layer, _stage.level_up_frame.layer, "C903: abaixo do LevelUpFrame")
	assert_lt(fundo.layer, (_stage.get_node("CanvasLayer") as CanvasLayer).layer, "C903: abaixo do HUD")
	assert_eq(_stage.get_child(_stage.get_child_count() - 1), _stage.tutorial_revisao, "C903: a revisao segue o ultimo filho")


# --- C904 ---


func test_size_changed_refaz_a_contagem_de_tiles_sem_reiniciar_o_offset() -> void:
	await _spawn_fundo([300, 300, 300], 640)
	_fundo.acumulado = 400.0
	var antes: Array[float] = _offsets()
	assert_eq(_fundo.tiles_da_camada(0).size(), 4, "C904: 640 com textura 300 -> ceil(2,13) + 1 = 4 tiles")
	_sv.size = Vector2i(LARGURA, 924)
	await wait_process_frames(2)
	assert_eq(_fundo.tiles_da_camada(0).size(), 5, "C904: 924 com textura 300 -> ceil(3,08) + 1 = 5 tiles")
	assert_eq(_offsets(), antes, "C904: o offset nao reinicia no resize")
	var uniao: Dictionary = _uniao(_fundo.retangulos_camada(0))
	assert_gte(float(uniao["fim"]), 924.0, "C904: os tiles novos cobrem a altura nova")


# --- C905 ---


func test_delta_negativo_ou_zero_nao_move_o_offset_para_tras() -> void:
	await _spawn_fundo([960, 1200, 1440])
	Global.iniciado = true
	_scroll.position_scrolled = 100.0
	_fundo.atualizar()
	_scroll.position_scrolled = 40.0
	_fundo.atualizar()
	assert_almost_eq(_fundo.offset_camada(0), 5.0, EPS, "C905: delta negativo nao recua o offset")
	_fundo.atualizar()
	assert_almost_eq(_fundo.offset_camada(0), 5.0, EPS, "C905: delta zero mantem o offset")
	_fundo.acumulado = -500.0
	for i in range(3):
		assert_gte(_fundo.offset_camada(i), 0.0, "C905: camada %d nunca com offset negativo" % i)
	_fundo.acumulado = 1.0e9
	for i in range(3):
		var altura: float = float(_fundo.tiles_da_camada(i)[0].texture.get_height())
		assert_lt(_fundo.offset_camada(i), altura, "C905: camada %d com offset sempre < H_tex" % i)


# --- C936 ---


func test_ceu_fica_fixo_no_topo_e_cobre_360x1034_enquanto_as_camadas_andam() -> void:
	await _spawn_fundo([960, 1200, 1440])
	var ceu: Sprite2D = _fundo.ceu()
	assert_eq(ceu.position, Vector2.ZERO, "C936: ceu no topo da tela")
	assert_eq(Rect2(ceu.position, ceu.texture.get_size()), Rect2(0, 0, LARGURA, ALTURA_CEU), "C936: ceu cobre [0,360] x [0,1034]")
	var y_c0_antes: float = _fundo.tiles_da_camada(0)[1].position.y
	var y_c1_antes: float = _fundo.tiles_da_camada(1)[1].position.y
	var y_c2_antes: float = _fundo.tiles_da_camada(2)[1].position.y
	Global.iniciado = true
	_scroll.position_scrolled = 2000.0
	_fundo.atualizar()
	assert_eq(ceu.position, Vector2.ZERO, "C936: o ceu nao muda de posicao com o scroll")
	assert_ne(_fundo.tiles_da_camada(0)[1].position.y, y_c0_antes, "C936: c0 anda no mesmo quadro")
	assert_ne(_fundo.tiles_da_camada(1)[1].position.y, y_c1_antes, "C936: c1 tambem anda")
	assert_ne(_fundo.tiles_da_camada(2)[1].position.y, y_c2_antes, "C936: c2 tambem anda")
	var camadas_do_ceu: int = 0
	for filho in _fundo.get_children():
		if filho is Sprite2D and (filho as Sprite2D).texture == ceu.texture:
			camadas_do_ceu += 1
	assert_eq(camadas_do_ceu, 1, "C936: sem tiles repetidos do ceu")
