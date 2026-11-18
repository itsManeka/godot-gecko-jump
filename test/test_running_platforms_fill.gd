extends GutTest

# f413: linhas moveis nascem preenchidas. f452: o nome do enum casa com o movimento (Platform.gd: velocity = -speed).

const GERADOR_SCENE := "res://scenes/RunningPlatforms.tscn"
const SPAWN_MOVE_TO_RIGHT := -30.0 # MOVE_TO_RIGHT: nasce a esquerda, anda a direita
const SPAWN_MOVE_TO_LEFT := 210.0 # MOVE_TO_LEFT: nasce a direita, anda a esquerda
# Periodo do ciclo area_exited -> timer: ~61 ticks ate sair do CheckGenerate + 0.3 s (18 ticks) a 60 Hz
const PERIODO_FRAMES := 79
const TOLERANCIA_FRAMES := 2
const TOLERANCIA_PX := 2.0
const SPEED_INTERMEDIARIA := 86.0
const SPEED_TETO := 100.0


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
	var esp := MovingRowFill.espacamento(60.0)
	var passo: float = -esp if toward_left else esp
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
	var gerador := _criar_gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT)
	add_child_autofree(gerador)

	var xs := _xs_visiveis(gerador)
	var esperado := _esperados(SPAWN_MOVE_TO_LEFT, true)
	assert_eq(xs.size(), 3, "linha que nasce a direita deve ter 3 plataformas visiveis no 1o frame")
	for x in esperado:
		assert_true(xs.has(x), "linha que nasce a direita deve ter plataforma pre-colocada nos x de MovingRowFill")

	await wait_physics_frames(1)
	for p in _plataformas(gerador):
		assert_lt(p.velocity.x, 0.0, "linha que nasce a direita deve andar para a esquerda (velocity.x negativo)")


func test_linha_movel_esquerda_nasce_com_3_plataformas_visiveis_no_1o_frame() -> void:
	var gerador := _criar_gerador(Enums.PLATFORM_TYPE.MOVE_TO_RIGHT)
	add_child_autofree(gerador)

	var xs := _xs_visiveis(gerador)
	var esperado := _esperados(SPAWN_MOVE_TO_RIGHT, false)
	assert_eq(xs.size(), 3, "linha que nasce a esquerda deve ter 3 plataformas visiveis no 1o frame")
	for x in esperado:
		assert_true(xs.has(x), "linha que nasce a esquerda deve ter plataforma pre-colocada nos x de MovingRowFill")

	await wait_physics_frames(1)
	for p in _plataformas(gerador):
		assert_gt(p.velocity.x, 0.0, "linha que nasce a esquerda deve andar para a direita (velocity.x positivo)")


func test_plataforma_do_ponto_de_nascimento_existe_no_ready_sem_timer() -> void:
	for caso in [[Enums.PLATFORM_TYPE.MOVE_TO_LEFT, SPAWN_MOVE_TO_LEFT, -1.0], [Enums.PLATFORM_TYPE.MOVE_TO_RIGHT, SPAWN_MOVE_TO_RIGHT, 1.0]]:
		var gerador := _criar_gerador(caso[0])
		add_child_autofree(gerador)
		var spawn_x: float = caso[1]
		var sentido: float = caso[2]

		var no_spawn: Array = []
		for p in _plataformas(gerador):
			if is_equal_approx(p.position.x, spawn_x):
				no_spawn.append(p)
		assert_eq(no_spawn.size(), 1, "plataforma do ponto de nascimento deve existir no 1o frame, sem esperar o timer")
		var vizinha_x: float = spawn_x + sentido * MovingRowFill.espacamento(60.0)
		var tem_vizinha := false
		for p in _plataformas(gerador):
			if is_equal_approx(p.position.x, vizinha_x):
				tem_vizinha = true
		assert_true(tem_vizinha, "lacuna entre a de nascimento e a vizinha pre-colocada deve ser espacamento(60)")


func test_ritmo_entre_nascimentos_novos_e_o_periodo_do_ciclo() -> void:
	var gerador := _criar_gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT)
	var nascimentos: Array = []
	var plataformas: Array = []
	_registrar_nascimentos(gerador, SPAWN_MOVE_TO_LEFT, nascimentos, plataformas)
	add_child_autofree(gerador)

	await wait_physics_frames(PERIODO_FRAMES * 3 + 30)

	assert_gte(nascimentos.size(), 4, "ritmo: devem nascer ao menos 3 plataformas novas depois da do _ready")
	for i in range(2, nascimentos.size()):
		var intervalo: int = nascimentos[i] - nascimentos[i - 1]
		assert_almost_eq(float(intervalo), float(PERIODO_FRAMES), float(TOLERANCIA_FRAMES), "ritmo: intervalo entre nascimentos novos deve ser o periodo do ciclo")


# Um gerador por teste: dois geradores vivos no mesmo y se enxergam pela layer do CheckGenerate e disparam area_exited extra
func _medir_espacamento(tipo: Enums.PLATFORM_TYPE, spawn_x: float, speed: float = 60.0) -> Array:
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
	_aplicar_speed(gerador, speed)

	await wait_physics_frames(PERIODO_FRAMES * 3 + 30)
	return distancias


# O _ready do gerador fixa speed 60 (a T9 liga a speed da curva): aqui a speed e setada pela instancia apos o _ready,
# no gerador (plataformas novas) e nas ja criadas. Sinal de speed = sentido (Platform.gd: velocity = -speed).
func _aplicar_speed(gerador: Node2D, speed: float) -> void:
	var sinal: float = -1.0 if gerador.speed < 0 else 1.0
	gerador.speed = speed * sinal
	for p in _plataformas(gerador):
		p.set_speed(speed * sinal)


func _checar_espacamento_medido(tipo: Enums.PLATFORM_TYPE, spawn_x: float, speed: float) -> void:
	var distancias: Array = await _medir_espacamento(tipo, spawn_x, speed)
	assert_gte(distancias.size(), 3, "espacamento: devem existir ao menos 3 medidas entre plataformas geradas pelo ciclo")
	for d in distancias:
		assert_almost_eq(float(d), MovingRowFill.espacamento(speed), TOLERANCIA_PX, "espacamento medido em jogo (speed %s) deve bater com MovingRowFill.espacamento(speed)" % speed)


func test_espacamento_60_e_79() -> void:
	assert_eq(MovingRowFill.espacamento(60.0), 79.0, "espacamento(60) = 79 px")


# Um gerador por teste (ver acima): um teste por speed e por lado.
func test_espacamento_medido_em_jogo_speed_60_nascendo_a_direita() -> void:
	await _checar_espacamento_medido(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, SPAWN_MOVE_TO_LEFT, 60.0)


func test_espacamento_medido_em_jogo_speed_60_nascendo_a_esquerda() -> void:
	await _checar_espacamento_medido(Enums.PLATFORM_TYPE.MOVE_TO_RIGHT, SPAWN_MOVE_TO_RIGHT, 60.0)


func test_espacamento_medido_em_jogo_speed_intermediaria_nascendo_a_direita() -> void:
	await _checar_espacamento_medido(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, SPAWN_MOVE_TO_LEFT, SPEED_INTERMEDIARIA)


func test_espacamento_medido_em_jogo_speed_intermediaria_nascendo_a_esquerda() -> void:
	await _checar_espacamento_medido(Enums.PLATFORM_TYPE.MOVE_TO_RIGHT, SPAWN_MOVE_TO_RIGHT, SPEED_INTERMEDIARIA)


func test_espacamento_medido_em_jogo_speed_do_teto_nascendo_a_direita() -> void:
	await _checar_espacamento_medido(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, SPAWN_MOVE_TO_LEFT, SPEED_TETO)


func test_espacamento_medido_em_jogo_speed_do_teto_nascendo_a_esquerda() -> void:
	await _checar_espacamento_medido(Enums.PLATFORM_TYPE.MOVE_TO_RIGHT, SPAWN_MOVE_TO_RIGHT, SPEED_TETO)


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
