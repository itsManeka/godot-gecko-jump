extends GutTest

# T3 (f410): a zona de derrota (CheckPlayer) acompanha a borda inferior visivel injetada por apply_layout.
# Faixa com topo em y = altura visivel, espessura 20, largura = largura visivel. Fisica real, sem janela.
const STAGE := "res://scenes/Stage.tscn"
const THICKNESS := 20.0
var _stage: Node
var _p: Node

func before_each() -> void:
	Global.tutorial_visto_espelho = true
	Global.platforms = []
	Global.iniciado = true

func after_each() -> void:
	# A liberacao do Stage no teardown dispara body_exited; end evita o handler tocar audio fora da arvore.
	if is_instance_valid(_p):
		_p.end = true
	Global.platforms = []
	Global.iniciado = false

# Stage real sem o ScrollLevel, com o layout injetado. Fisica do Player desligada ate o teste liberar.
func _spawn_stage(size: Vector2) -> void:
	_stage = add_child_autofree(load(STAGE).instantiate())
	var scroll: Node = _stage.get_node("ScrollLevel")
	_stage.remove_child(scroll)
	scroll.free()
	_stage.apply_layout(size, Rect2(Vector2.ZERO, size))
	_p = _stage.get_node("Node2D/Player")
	_p.set_physics_process(false)
	_stage._on_Play_button_down()
	Global.platforms = []

func _check_shape() -> CollisionShape2D:
	return _stage.get_node("CheckPlayer/CollisionShape2D")

func _top_of_check() -> float:
	var col := _check_shape()
	return col.position.y - (col.shape as RectangleShape2D).size.y / 2.0

# Cai ate encerrar a partida (ou n frames); devolve a maior queda por frame observada.
func _fall_until_end(n: int) -> float:
	var maior := 0.0
	for i in n:
		_p.can_change_color = false
		var y_ant: float = _p.position.y
		var f_ant := Engine.get_physics_frames()
		await wait_physics_frames(1)
		# O await pode atravessar mais de um tick: queda por tick = deslocamento / ticks decorridos.
		var ticks := maxi(1, Engine.get_physics_frames() - f_ant)
		maior = maxf(maior, (_p.position.y - y_ant) / float(ticks))
		if _p.is_end():
			break
	return maior

# C66: topo da faixa >= altura visivel (320 e 400), espessura 20.
func test_topo_da_faixa_fica_na_altura_visivel() -> void:
	for altura in [320.0, 400.0]:
		_spawn_stage(Vector2(180.0, altura))
		assert_almost_eq(_top_of_check(), altura, 0.001, "topo da faixa na altura %s" % altura)
		assert_gte(_top_of_check(), altura, "faixa fora da area visivel (altura %s)" % altura)
		assert_almost_eq((_check_shape().shape as RectangleShape2D).size.y, THICKNESS, 0.001, "espessura 20")
		_stage.queue_free()
		await wait_frames(1)

# C67: largura da faixa == largura visivel passada.
func test_largura_da_faixa_e_a_largura_visivel() -> void:
	for largura in [180.0, 240.0]:
		_spawn_stage(Vector2(largura, 320.0))
		var shape := _check_shape().shape as RectangleShape2D
		assert_almost_eq(shape.size.x, largura, 0.001, "largura da faixa %s" % largura)
		assert_almost_eq(_check_shape().position.x, largura / 2.0, 0.001, "faixa centrada em %s" % largura)
		_stage.queue_free()
		await wait_frames(1)

# C68: gecko que cai por baixo da borda de altura 400 atravessa a faixa; derrota dispara uma vez.
func test_queda_pela_borda_de_altura_400_dispara_derrota_uma_vez() -> void:
	_spawn_stage(Vector2(180.0, 400.0))
	var check: Area2D = _stage.get_node("CheckPlayer")
	watch_signals(check)
	_p.position = Vector2(90.0, 380.0)
	_p.velocity = Vector2.ZERO
	await wait_physics_frames(2)
	_p.set_physics_process(true)
	await _fall_until_end(120)
	assert_true(_p.is_end(), "caiu pela borda inferior de 400 sem pular: partida perdida")
	assert_signal_emit_count(check, "body_exited", 1, "derrota dispara uma vez")

# C69: sem tunelamento, mesmo na velocidade maxima observada a queda por frame e menor que a espessura.
func test_sem_tunelamento_na_velocidade_maxima() -> void:
	_spawn_stage(Vector2(180.0, 320.0))
	var check: Area2D = _stage.get_node("CheckPlayer")
	watch_signals(check)
	_p.position = Vector2(90.0, 280.0)
	_p.velocity = Vector2(0.0, 1100.0)
	_p.set_physics_process(true)
	var maior := await _fall_until_end(120)
	assert_lt(maior, THICKNESS, "queda por frame (%s) menor que a espessura da faixa" % maior)
	assert_gt(maior, 10.0, "o teste exercitou uma queda rapida")
	assert_true(_p.is_end(), "body_exited disparou na velocidade maxima")
	assert_signal_emit_count(check, "body_exited", 1, "derrota dispara uma vez")

# C70: dentro da area visivel nunca perde; apply_layout de novo reposiciona a faixa (resize 320 -> 400).
func test_dentro_da_area_visivel_nao_perde_e_resize_reposiciona() -> void:
	_spawn_stage(Vector2(180.0, 320.0))
	var check: Area2D = _stage.get_node("CheckPlayer")
	watch_signals(check)
	_p.position = Vector2(90.0, 200.0)
	_p.velocity = Vector2.ZERO
	await wait_physics_frames(5)
	assert_false(_p.is_end(), "y < altura nao perde")
	assert_signal_not_emitted(check, "body_exited", "sem saida da faixa dentro da area visivel")
	assert_almost_eq(_top_of_check(), 320.0, 0.001, "faixa em 320")
	_stage.apply_layout(Vector2(180.0, 400.0), Rect2(0.0, 0.0, 180.0, 400.0))
	assert_almost_eq(_top_of_check(), 400.0, 0.001, "resize reposiciona a faixa em 400")
	await wait_physics_frames(5)
	assert_false(_p.is_end(), "resize nao gera derrota com o gecko na area visivel")
