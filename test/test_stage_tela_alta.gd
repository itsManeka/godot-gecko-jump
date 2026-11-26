extends GutTest

# T6 (f410): Stage real em 360x640, 360x800 e 360x924 com safe area simulada; zona de derrota e HUD juntos,
# e uma partida completa em 360x800 em que a derrota ocorre na borda inferior real (nao em y=620).
const STAGE := "res://scenes/Stage.tscn"
const ALTURA_ANTIGA := 620.0
var _stage: Node
var _p: Node

func before_each() -> void:
	Global.tutorial_visto_espelho = true
	Global.platforms = []
	Global.iniciado = false

func after_each() -> void:
	# A liberacao do Stage no teardown dispara body_exited; end evita o handler tocar audio fora da arvore.
	if is_instance_valid(_p):
		_p.end = true
	Global.platforms = []
	Global.iniciado = false

func _spawn_stage(size: Vector2, safe: Rect2, iniciar: bool) -> void:
	_stage = add_child_autofree(load(STAGE).instantiate())
	var scroll: Node = _stage.get_node("ScrollLevel")
	_stage.remove_child(scroll)
	scroll.free()
	_stage.apply_layout(size, safe)
	_p = _stage.get_node("Node2D/Player")
	if iniciar:
		Global.iniciado = true
		_p.set_physics_process(false)
		_stage._on_Play_button_down()
		Global.platforms = []

func _rect(nome: String) -> Rect2:
	return (_stage.get_node("CanvasLayer/" + nome) as Control).get_global_rect()

func _top_of_check() -> float:
	var col: CollisionShape2D = _stage.get_node("CheckPlayer/CollisionShape2D")
	return col.position.y - (col.shape as RectangleShape2D).size.y / 2.0

func _free_stage() -> void:
	if is_instance_valid(_p):
		_p.end = true
	_stage.queue_free()
	await wait_frames(1)

# C81: zona de derrota abaixo da borda visivel e HUD contido/sem sobreposicao, nas duas alturas.
func test_zona_e_hud_juntos_em_640_800_e_924_com_safe_area() -> void:
	for altura in [640.0, 800.0, 924.0]:
		var tamanho := Vector2(360.0, altura)
		var safe := Rect2(0.0, 60.0, tamanho.x, altura - 60.0)
		_spawn_stage(tamanho, safe, false)
		assert_gte(_top_of_check(), altura, "zona de derrota em y >= %s" % altura)
		assert_almost_eq(_top_of_check(), altura, 0.001, "topo da zona exatamente na altura %s" % altura)
		var visivel := Rect2(Vector2.ZERO, tamanho)
		for nome in ["Pontos", "Play", "Last", "Best"]:
			assert_true(visivel.encloses(_rect(nome)), "%s na area visivel %s" % [nome, tamanho])
			assert_true(safe.encloses(_rect(nome)), "%s na safe area %s" % [nome, tamanho])
			assert_lt(_rect(nome).end.y, _top_of_check(), "%s acima da zona de derrota %s" % [nome, tamanho])
		assert_false(_rect("Play").intersects(_rect("Last")), "Play x Last")
		assert_false(_rect("Play").intersects(_rect("Best")), "Play x Best")
		assert_false(_rect("Last").intersects(_rect("Best")), "Last x Best")
		assert_false(_rect("Pontos").intersects(_rect("Play")), "Pontos x Play")
		await _free_stage()

# C81 (mutacao): com altura 800 a zona nao pode ficar em y=620.
func test_zona_nao_fica_na_altura_antiga_com_altura_800() -> void:
	_spawn_stage(Vector2(360.0, 800.0), Rect2(0.0, 60.0, 360.0, 740.0), false)
	assert_gt(_top_of_check(), ALTURA_ANTIGA, "topo da zona acima de 620 nao vale com altura 800")
	assert_almost_eq(_top_of_check(), 800.0, 0.001, "topo da zona na borda inferior real")

# C81: Stage dentro de um SubViewport, sem apply_layout a mao: o _ready le a altura do viewport (400) e o
# size_changed real reposiciona faixa e HUD quando o tamanho muda (640 de altura, 924, depois 480 de largura).
func test_stage_em_subviewport_reposiciona_pelo_size_changed_real() -> void:
	var sv := SubViewport.new()
	sv.size = Vector2i(360, 800)
	add_child_autofree(sv)
	_stage = load(STAGE).instantiate()
	var scroll: Node = _stage.get_node("ScrollLevel")
	_stage.remove_child(scroll)
	scroll.free()
	sv.add_child(_stage)
	_p = _stage.get_node("Node2D/Player")
	_p.set_physics_process(false)
	assert_almost_eq(_top_of_check(), 800.0, 0.001, "_ready posiciona a faixa em y=800 pelo viewport")
	assert_almost_eq(_rect("Last").size.x, 360.0, 0.001, "HUD na largura 360 pelo _ready")
	sv.size = Vector2i(360, 640)
	await wait_process_frames(2)
	assert_almost_eq(_top_of_check(), 640.0, 0.001, "size_changed reposicionou a faixa para y=640")
	sv.size = Vector2i(360, 924)
	await wait_process_frames(2)
	assert_almost_eq(_top_of_check(), 924.0, 0.001, "size_changed reposicionou a faixa para y=924")
	sv.size = Vector2i(480, 800)
	await wait_process_frames(2)
	assert_almost_eq(_top_of_check(), 800.0, 0.001, "size_changed reposicionou a faixa para y=800")
	var faixa: CollisionShape2D = _stage.get_node("CheckPlayer/CollisionShape2D")
	assert_almost_eq((faixa.shape as RectangleShape2D).size.x, 480.0, 0.001, "faixa com a largura 480")
	assert_almost_eq(_rect("Last").size.x, 480.0, 0.001, "HUD refeito para a largura 480")
	assert_almost_eq(_rect("Play").get_center().x, 240.0, 0.001, "Play centrado na largura 480")

# C82: partida completa em 360x800; o gecko cai alem da borda real e so entao perde.
func test_partida_em_360x800_perde_na_borda_inferior_real() -> void:
	_spawn_stage(Vector2(360.0, 800.0), Rect2(0.0, 60.0, 360.0, 740.0), true)
	_p.position = Vector2(180.0, 660.0)
	_p.velocity = Vector2.ZERO
	await wait_physics_frames(2)
	_p.set_physics_process(true)
	var y_final := 0.0
	for i in 240:
		_p.can_change_color = false
		await wait_physics_frames(1)
		if _p.is_end():
			y_final = _p.position.y
			break
	assert_true(_p.is_end(), "caiu pela borda inferior sem pular: partida perdida")
	assert_gte(y_final, 800.0, "derrota ocorreu alem da borda inferior real (y=%s), nao em y=620" % y_final)
