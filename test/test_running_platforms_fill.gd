extends GutTest

# f413: linhas moveis nascem preenchidas. Sentido pelo sinal de velocity / ponto de nascimento, nunca pelo nome do
# enum (MOVE_TO_LEFT/MOVE_TO_RIGHT estao invertidos em relacao ao movimento, ver Platform.gd: velocity = -speed).

const GERADOR_SCENE := "res://scenes/RunningPlatforms.tscn"
const SPAWN_ESQUERDA_ANDA_DIREITA := -30.0 # MOVE_TO_LEFT: nasce a esquerda, anda a direita
const SPAWN_DIREITA_ANDA_ESQUERDA := 210.0 # MOVE_TO_RIGHT: nasce a direita, anda a esquerda
# Periodo do ciclo area_exited -> timer: ~61 ticks ate sair do CheckGenerate + 0.3 s (18 ticks) a 60 Hz
const PERIODO_FRAMES := 79
const TOLERANCIA_FRAMES := 2
const TOLERANCIA_PX := 2.0


func before_each() -> void:
	Global.platforms = []
	Global.iniciado = false


func after_each() -> void:
	Global.platforms = []
	Global.iniciado = false


func _criar_gerador(tipo: Enums.PLATFORM_TYPE) -> Node2D:
	var gerador: Node2D = load(GERADOR_SCENE).instantiate()
	gerador.platform_type = tipo
	gerador.position = Vector2(0, 100)
	Global.set_iniciado(true)
	return gerador


func _plataformas(gerador: Node) -> Array:
	var filhas: Array = []
	for filha in gerador.get_children():
		if filha is Platform and is_instance_valid(filha) and not filha.is_queued_for_deletion():
			filhas.append(filha)
	return filhas


func _xs_visiveis(gerador: Node) -> Array:
	var xs: Array = []
	for p in _plataformas(gerador):
		if p.position.x > -30.0 and p.position.x < 210.0:
			xs.append(p.position.x)
	xs.sort()
	return xs


func _esperados(spawn_x: float, toward_left: bool) -> Array:
	var xs: Array = []
	var passo: float = -MovingRowFill.ESPACAMENTO if toward_left else MovingRowFill.ESPACAMENTO
	for k in range(1, 4):
		xs.append(spawn_x + passo * k)
	xs.sort()
	return xs


# Registra o frame de fisica de cada plataforma criada no ponto de nascimento (inclui a do _ready)
func _registrar_nascimentos(gerador: Node2D, spawn_x: float, nascimentos: Array, plataformas: Array) -> void:
	gerador.child_entered_tree.connect(func(no: Node) -> void:
		if no is Platform and is_equal_approx(no.position.x, spawn_x):
			nascimentos.append(Engine.get_physics_frames())
			plataformas.append(no)
	)


func test_linha_movel_direita_nasce_com_3_plataformas_visiveis_no_1o_frame() -> void:
	var gerador := _criar_gerador(Enums.PLATFORM_TYPE.MOVE_TO_RIGHT)
	add_child_autofree(gerador)

	var xs := _xs_visiveis(gerador)
	var esperado := _esperados(SPAWN_DIREITA_ANDA_ESQUERDA, true)
	assert_eq(xs.size(), 3, "linha que nasce a direita deve ter 3 plataformas visiveis no 1o frame")
	for x in esperado:
		assert_true(xs.has(x), "linha que nasce a direita deve ter plataforma pre-colocada nos x de MovingRowFill")

	await wait_physics_frames(1)
	for p in _plataformas(gerador):
		assert_lt(p.velocity.x, 0.0, "linha que nasce a direita deve andar para a esquerda (velocity.x negativo)")


func test_linha_movel_esquerda_nasce_com_3_plataformas_visiveis_no_1o_frame() -> void:
	var gerador := _criar_gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT)
	add_child_autofree(gerador)

	var xs := _xs_visiveis(gerador)
	var esperado := _esperados(SPAWN_ESQUERDA_ANDA_DIREITA, false)
	assert_eq(xs.size(), 3, "linha que nasce a esquerda deve ter 3 plataformas visiveis no 1o frame")
	for x in esperado:
		assert_true(xs.has(x), "linha que nasce a esquerda deve ter plataforma pre-colocada nos x de MovingRowFill")

	await wait_physics_frames(1)
	for p in _plataformas(gerador):
		assert_gt(p.velocity.x, 0.0, "linha que nasce a esquerda deve andar para a direita (velocity.x positivo)")


func test_plataforma_do_ponto_de_nascimento_existe_no_ready_sem_timer() -> void:
	for caso in [[Enums.PLATFORM_TYPE.MOVE_TO_RIGHT, SPAWN_DIREITA_ANDA_ESQUERDA, -1.0], [Enums.PLATFORM_TYPE.MOVE_TO_LEFT, SPAWN_ESQUERDA_ANDA_DIREITA, 1.0]]:
		var gerador := _criar_gerador(caso[0])
		add_child_autofree(gerador)
		var spawn_x: float = caso[1]
		var sentido: float = caso[2]

		var no_spawn: Array = []
		for p in _plataformas(gerador):
			if is_equal_approx(p.position.x, spawn_x):
				no_spawn.append(p)
		assert_eq(no_spawn.size(), 1, "plataforma do ponto de nascimento deve existir no 1o frame, sem esperar o timer")
		var vizinha_x: float = spawn_x + sentido * MovingRowFill.ESPACAMENTO
		var tem_vizinha := false
		for p in _plataformas(gerador):
			if is_equal_approx(p.position.x, vizinha_x):
				tem_vizinha = true
		assert_true(tem_vizinha, "lacuna entre a de nascimento e a vizinha pre-colocada deve ser ESPACAMENTO")


func test_ritmo_entre_nascimentos_novos_e_o_periodo_do_ciclo() -> void:
	var gerador := _criar_gerador(Enums.PLATFORM_TYPE.MOVE_TO_RIGHT)
	var nascimentos: Array = []
	var plataformas: Array = []
	_registrar_nascimentos(gerador, SPAWN_DIREITA_ANDA_ESQUERDA, nascimentos, plataformas)
	add_child_autofree(gerador)

	await wait_physics_frames(PERIODO_FRAMES * 3 + 30)

	assert_gte(nascimentos.size(), 4, "ritmo: devem nascer ao menos 3 plataformas novas depois da do _ready")
	for i in range(2, nascimentos.size()):
		var intervalo: int = nascimentos[i] - nascimentos[i - 1]
		assert_almost_eq(float(intervalo), float(PERIODO_FRAMES), float(TOLERANCIA_FRAMES), "ritmo: intervalo entre nascimentos novos deve ser o periodo do ciclo")


# Um gerador por teste: dois geradores vivos no mesmo y se enxergam pela layer do CheckGenerate e disparam area_exited extra
func _medir_espacamento(tipo: Enums.PLATFORM_TYPE, spawn_x: float) -> Array:
	var gerador := _criar_gerador(tipo)
	var nascimentos: Array = []
	var plataformas: Array = []
	var distancias: Array = []
	gerador.child_entered_tree.connect(func(no: Node) -> void:
		if no is Platform and is_equal_approx(no.position.x, spawn_x) and not plataformas.is_empty():
			distancias.append(absf(plataformas.back().position.x - spawn_x))
	)
	_registrar_nascimentos(gerador, spawn_x, nascimentos, plataformas)
	add_child_autofree(gerador)

	await wait_physics_frames(PERIODO_FRAMES * 3 + 30)
	return distancias


func test_espacamento_medido_em_jogo_bate_com_constante_nascendo_a_direita() -> void:
	var distancias: Array = await _medir_espacamento(Enums.PLATFORM_TYPE.MOVE_TO_RIGHT, SPAWN_DIREITA_ANDA_ESQUERDA)
	assert_gte(distancias.size(), 3, "espacamento: devem existir ao menos 3 medidas entre plataformas geradas pelo ciclo")
	for d in distancias:
		assert_almost_eq(float(d), MovingRowFill.ESPACAMENTO, TOLERANCIA_PX, "espacamento medido em jogo deve bater com MovingRowFill.ESPACAMENTO")


func test_espacamento_medido_em_jogo_bate_com_constante_nascendo_a_esquerda() -> void:
	var distancias: Array = await _medir_espacamento(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, SPAWN_ESQUERDA_ANDA_DIREITA)
	assert_gte(distancias.size(), 3, "espacamento: devem existir ao menos 3 medidas entre plataformas geradas pelo ciclo")
	for d in distancias:
		assert_almost_eq(float(d), MovingRowFill.ESPACAMENTO, TOLERANCIA_PX, "espacamento medido em jogo deve bater com MovingRowFill.ESPACAMENTO")


# A ligacao com MovingRowFill e provada por comportamento (C106: x das plataformas = MovingRowFill.initial_xs)
func test_gerador_static_nao_pre_preenche() -> void:
	var gerador := _criar_gerador(Enums.PLATFORM_TYPE.STATIC)
	add_child_autofree(gerador)

	var xs: Array = []
	for p in _plataformas(gerador):
		xs.append(p.position.x)
	xs.sort()
	assert_eq(xs, [5.0, 90.0, 175.0], "gerador STATIC deve manter as 3 estaticas de sempre, sem pre-preenchimento movel")


func test_gerador_random_all_movel_tambem_nasce_preenchido() -> void:
	# Seed fixa: o sorteio de PlatformTypePicker (randi global) fica deterministico
	seed(413)
	var achou := false
	for i in 60:
		var gerador := _criar_gerador(Enums.PLATFORM_TYPE.RANDOM_ALL)
		add_child_autofree(gerador)
		if gerador.platform_type == Enums.PLATFORM_TYPE.STATIC:
			gerador.queue_free()
			continue
		achou = true
		assert_eq(_xs_visiveis(gerador).size(), 3, "gerador RANDOM_ALL que sorteou tipo movel deve nascer preenchido")
		break
	assert_true(achou, "RANDOM_ALL deve sortear tipo movel em 60 tentativas")
