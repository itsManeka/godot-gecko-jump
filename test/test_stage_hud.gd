extends GutTest

# T4 (f410): HUD (Pontos) e menu (Play, Last, Best) ancorados no topo da safe area injetada por apply_layout.
# f565 T4: escala 2x (viewport logico 360x640).
const STAGE := "res://scenes/Stage.tscn"
const STAGE_SCRIPT := preload("res://scenes/Stage.gd")
var _stage: Node

func before_each() -> void:
	Global.tutorial_visto_espelho = true
	Global.platforms = []
	Global.iniciado = false

func after_each() -> void:
	Global.platforms = []
	Global.iniciado = false

func _spawn_stage(size: Vector2, safe: Rect2) -> void:
	_stage = add_child_autofree(load(STAGE).instantiate())
	var scroll: Node = _stage.get_node("ScrollLevel")
	_stage.remove_child(scroll)
	scroll.free()
	_stage.apply_layout(size, safe)

func _rect(nome: String) -> Rect2:
	return (_stage.get_node("CanvasLayer/" + nome) as Control).get_global_rect()

func _free_stage() -> void:
	_stage.queue_free()
	await wait_frames(1)

# C72: com safe.position.y = 0 o menu mantem os y de 360x640 do Stage.tscn (C826: PLAY_BOTTOM=346 literal, expande a 354).
func test_menu_mantem_y_de_360x640_sem_safe_area() -> void:
	_spawn_stage(Vector2(360.0, 640.0), Rect2(0.0, 0.0, 360.0, 640.0))
	assert_eq(STAGE_SCRIPT.PLAY_BOTTOM, 346.0, "PLAY_BOTTOM literal 346")
	assert_almost_eq(_rect("Play").position.y, 294.0, 0.001, "Play top")
	assert_almost_eq(_rect("Play").end.y, 354.0, 0.001, "Play bottom (fonte 64 px + content_margin_bottom 8: altura minima 60)")
	assert_almost_eq(_rect("Last").position.y, 460.0, 0.001, "Last top")
	assert_almost_eq(_rect("Last").end.y, 494.0, 0.001, "Last bottom")
	assert_almost_eq(_rect("Best").position.y, 496.0, 0.001, "Best top")
	assert_almost_eq(_rect("Best").end.y, 530.0, 0.001, "Best bottom")

# C73: safe area com position.y = 60 desloca exatamente 60 todos os retangulos; Pontos nao sobe da safe area.
func test_safe_area_desloca_hud_e_menu_exatamente_60() -> void:
	_spawn_stage(Vector2(360.0, 640.0), Rect2(0.0, 0.0, 360.0, 640.0))
	var base := {}
	for nome in ["Pontos", "Play", "Last", "Best"]:
		base[nome] = _rect(nome)
	_stage.apply_layout(Vector2(360.0, 640.0), Rect2(0.0, 60.0, 360.0, 580.0))
	for nome in ["Pontos", "Play", "Last", "Best"]:
		var antes: Rect2 = base[nome]
		var depois := _rect(nome)
		assert_almost_eq(depois.position.y - antes.position.y, 60.0, 0.001, "%s desloca 60" % nome)
		assert_almost_eq(depois.size.y, antes.size.y, 0.001, "%s mantem a altura" % nome)
		assert_almost_eq(depois.position.x, antes.position.x, 0.001, "%s mantem x" % nome)
	assert_gte(_rect("Pontos").position.y, 60.0, "Pontos dentro da safe area")

# C74 / C826: tudo contido na area visivel e na safe area; Play/FaixaPlacar/Last/Best sem sobreposicao indevida.
func test_retangulos_contidos_e_menu_sem_sobreposicao() -> void:
	for tamanho in [Vector2(360.0, 800.0), Vector2(360.0, 640.0)]:
		var safe := Rect2(0.0, 60.0, tamanho.x, tamanho.y - 60.0)
		_spawn_stage(tamanho, safe)
		var visivel := Rect2(Vector2.ZERO, tamanho)
		for nome in ["Pontos", "Play", "FaixaPlacar", "Last", "Best"]:
			assert_true(visivel.encloses(_rect(nome)), "%s na area visivel %s" % [nome, tamanho])
			assert_true(safe.encloses(_rect(nome)), "%s na safe area %s" % [nome, tamanho])
		assert_false(_rect("Play").intersects(_rect("FaixaPlacar")), "Play x FaixaPlacar")
		assert_false(_rect("Play").intersects(_rect("Last")), "Play x Last")
		assert_false(_rect("Play").intersects(_rect("Best")), "Play x Best")
		assert_false(_rect("Last").intersects(_rect("Best")), "Last x Best")
		assert_true(_rect("FaixaPlacar").encloses(_rect("Last")), "FaixaPlacar cobre Last")
		assert_true(_rect("FaixaPlacar").encloses(_rect("Best")), "FaixaPlacar cobre Best")
		await _free_stage()

# C75: borda direita do Pontos acompanha a largura visivel (360 -> 480).
func test_pontos_acompanha_a_borda_direita() -> void:
	_spawn_stage(Vector2(360.0, 640.0), Rect2(0.0, 0.0, 360.0, 640.0))
	var margem_360 := 360.0 - _rect("Pontos").end.x
	_stage.apply_layout(Vector2(480.0, 640.0), Rect2(0.0, 0.0, 480.0, 640.0))
	assert_almost_eq(480.0 - _rect("Pontos").end.x, margem_360, 0.001, "mesma margem a direita")
	assert_gt(_rect("Pontos").end.x, 360.0, "borda direita passou de 360")
	assert_lte(_rect("Pontos").end.x, 480.0, "dentro da largura visivel")

# C76: Play centrado horizontalmente na largura visivel.
func test_play_centrado_na_largura_visivel() -> void:
	for largura in [360.0, 480.0]:
		_spawn_stage(Vector2(largura, 640.0), Rect2(0.0, 0.0, largura, 640.0))
		assert_almost_eq(_rect("Play").get_center().x, largura / 2.0, 0.001, "Play centrado em %s" % largura)
		await _free_stage()

# C827 [mutacao]: Diario bloqueado: "Ja jogado hoje" na fonte 32 (medida, nao constante) cabe em PLAY_WIDTH_DIA = 264.
func test_c827_texto_do_dia_na_fonte_32_cabe_em_play_width_dia() -> void:
	assert_eq(STAGE_SCRIPT.TAMANHO_TEXTO_DIA, UiHelpers.TAMANHO_TEXTO, "texto do dia usa TAMANHO_TEXTO (32)")
	assert_eq(STAGE_SCRIPT.PLAY_WIDTH_DIA, 264.0, "PLAY_WIDTH_DIA dobrou")
	var largura: float = UiHelpers.FONTE.get_string_size(
		STAGE_SCRIPT.TEXTO_DIA_JA_JOGADO, HORIZONTAL_ALIGNMENT_LEFT, -1, STAGE_SCRIPT.TAMANHO_TEXTO_DIA
	).x
	assert_lte(largura, STAGE_SCRIPT.PLAY_WIDTH_DIA, "texto do dia (%s px) cabe em PLAY_WIDTH_DIA" % largura)

# C829: faixa de derrota 360x40 em (180, 660) e a ponte publica a largura jogavel 360.
func test_c829_check_player_2x_e_ponte_publica_largura_360() -> void:
	_stage = add_child_autofree(load(STAGE).instantiate())
	var colisao: CollisionShape2D = _stage.get_node("CheckPlayer/CollisionShape2D")
	assert_eq(colisao.position, Vector2(180.0, 660.0), "CheckPlayer em (180, 660)")
	assert_eq((colisao.shape as RectangleShape2D).size, Vector2(360.0, 40.0), "CheckPlayer 360x40")
	assert_eq(STAGE_SCRIPT.CHECK_THICKNESS, 40.0, "CHECK_THICKNESS = 40")
	assert_eq(float(PlayArea.LARGURA), 360.0, "PlayArea.LARGURA = 360 (valor passado a ponte)")
	var fonte: String = FileAccess.get_file_as_string("res://scenes/Stage.gd")
	assert_ne(fonte.find("float(PlayArea.LARGURA)"), -1, "a ponte segue passando float(PlayArea.LARGURA)")
