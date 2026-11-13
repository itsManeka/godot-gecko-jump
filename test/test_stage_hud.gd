extends GutTest

# T4 (f410): HUD (Pontos) e menu (Play, Last, Best) ancorados no topo da safe area injetada por apply_layout.
const STAGE := "res://scenes/Stage.tscn"
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

# C72: com safe.position.y = 0 o menu mantem os y de 180x320 do Stage.tscn.
func test_menu_mantem_y_de_180x320_sem_safe_area() -> void:
	_spawn_stage(Vector2(180.0, 320.0), Rect2(0.0, 0.0, 180.0, 320.0))
	assert_almost_eq(_rect("Play").position.y, 147.0, 0.001, "Play top")
	assert_almost_eq(_rect("Play").end.y, 173.0, 0.001, "Play bottom")
	assert_almost_eq(_rect("Last").position.y, 230.0, 0.001, "Last top")
	assert_almost_eq(_rect("Last").end.y, 247.0, 0.001, "Last bottom")
	assert_almost_eq(_rect("Best").position.y, 248.0, 0.001, "Best top")
	assert_almost_eq(_rect("Best").end.y, 265.0, 0.001, "Best bottom")

# C73: safe area com position.y = 30 desloca exatamente 30 todos os retangulos; Pontos nao sobe da safe area.
func test_safe_area_desloca_hud_e_menu_exatamente_30() -> void:
	_spawn_stage(Vector2(180.0, 320.0), Rect2(0.0, 0.0, 180.0, 320.0))
	var base := {}
	for nome in ["Pontos", "Play", "Last", "Best"]:
		base[nome] = _rect(nome)
	_stage.apply_layout(Vector2(180.0, 320.0), Rect2(0.0, 30.0, 180.0, 290.0))
	for nome in ["Pontos", "Play", "Last", "Best"]:
		var antes: Rect2 = base[nome]
		var depois := _rect(nome)
		assert_almost_eq(depois.position.y - antes.position.y, 30.0, 0.001, "%s desloca 30" % nome)
		assert_almost_eq(depois.size.y, antes.size.y, 0.001, "%s mantem a altura" % nome)
		assert_almost_eq(depois.position.x, antes.position.x, 0.001, "%s mantem x" % nome)
	assert_gte(_rect("Pontos").position.y, 30.0, "Pontos dentro da safe area")

# C74: tudo contido na area visivel e na safe area; Play/Last/Best sem sobreposicao.
func test_retangulos_contidos_e_menu_sem_sobreposicao() -> void:
	for tamanho in [Vector2(180.0, 400.0), Vector2(180.0, 320.0)]:
		var safe := Rect2(0.0, 30.0, tamanho.x, tamanho.y - 30.0)
		_spawn_stage(tamanho, safe)
		var visivel := Rect2(Vector2.ZERO, tamanho)
		for nome in ["Pontos", "Play", "Last", "Best"]:
			assert_true(visivel.encloses(_rect(nome)), "%s na area visivel %s" % [nome, tamanho])
			assert_true(safe.encloses(_rect(nome)), "%s na safe area %s" % [nome, tamanho])
		assert_false(_rect("Play").intersects(_rect("Last")), "Play x Last")
		assert_false(_rect("Play").intersects(_rect("Best")), "Play x Best")
		assert_false(_rect("Last").intersects(_rect("Best")), "Last x Best")
		await _free_stage()

# C75: borda direita do Pontos acompanha a largura visivel (180 -> 240).
func test_pontos_acompanha_a_borda_direita() -> void:
	_spawn_stage(Vector2(180.0, 320.0), Rect2(0.0, 0.0, 180.0, 320.0))
	var margem_180 := 180.0 - _rect("Pontos").end.x
	_stage.apply_layout(Vector2(240.0, 320.0), Rect2(0.0, 0.0, 240.0, 320.0))
	assert_almost_eq(240.0 - _rect("Pontos").end.x, margem_180, 0.001, "mesma margem a direita")
	assert_gt(_rect("Pontos").end.x, 180.0, "borda direita passou de 180")
	assert_lte(_rect("Pontos").end.x, 240.0, "dentro da largura visivel")

# C76: Play centrado horizontalmente na largura visivel.
func test_play_centrado_na_largura_visivel() -> void:
	for largura in [180.0, 240.0]:
		_spawn_stage(Vector2(largura, 320.0), Rect2(0.0, 0.0, largura, 320.0))
		assert_almost_eq(_rect("Play").get_center().x, largura / 2.0, 0.001, "Play centrado em %s" % largura)
		await _free_stage()
