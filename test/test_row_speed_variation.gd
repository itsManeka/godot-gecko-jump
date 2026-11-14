extends GutTest

# f467 T4: speed por linha. Curva propria do teste: speed base 80, variacao 0.25 (faixa [60, 100]).

const GERADOR_SCENE := "res://scenes/RunningPlatforms.tscn"
const SPEED_BASE := 80.0
const VARIACAO := 0.25
const SPAWN_MOVE_TO_LEFT := 210.0
# Janela de medicao do espacamento: ~5 periodos do ciclo (79 ticks a 60 Hz, mais curto em speed maior) + folga
const FRAMES_MEDICAO := 79 * 5 + 30
const TOLERANCIA_PX := 2.0

var _cor_original: Enums.COLOR


func before_each() -> void:
	PlatformModifiers.restaurar_padrao()
	_cor_original = Global.cor_gecko
	Global.platforms = []
	Global.iniciado = false
	Global.sem_derrota = false


func after_each() -> void:
	PlatformModifiers.restaurar_padrao()
	Global.cor_gecko = _cor_original
	Global.platforms = []
	Global.iniciado = false
	Global.sem_derrota = false


func _rng(semente: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	return rng


func _estagio(inicio: float, mecanicas: Array[StringName]) -> DifficultyStage:
	var estagio := DifficultyStage.new()
	estagio.progresso_inicio = inicio
	estagio.speed_moveis = SPEED_BASE
	estagio.variacao_speed_linha = VARIACAO
	estagio.mecanicas = mecanicas
	return estagio


# 2 estagios com a mesma speed e variacao; o 2o liga a mecanica (progresso_inicial 1.0 satura nele)
func _estado(ligada: bool) -> DifficultyState:
	var vazio: Array[StringName] = []
	var com: Array[StringName] = [PlatformModifiers.SPEED_POR_LINHA]
	var curva := DifficultyCurve.new()
	curva.estagios = [_estagio(0.0, vazio), _estagio(0.5, com)]
	var estado := DifficultyState.new(curva)
	estado.progresso_inicial = 1.0 if ligada else 0.0
	return estado


func _gerador(tipo: Enums.PLATFORM_TYPE, estado: DifficultyState, rng: RandomNumberGenerator, inicial: bool = false, y: float = 100.0) -> Node2D:
	var gerador: Node2D = load(GERADOR_SCENE).instantiate()
	gerador.platform_type = tipo
	gerador.garantir_cor_inicial = inicial
	gerador.dificuldade = estado
	gerador.rng = rng
	gerador.position = Vector2(0, y)
	Global.set_iniciado(true)
	add_child_autofree(gerador)
	return gerador


func _plataformas(gerador: Node) -> Array:
	var filhas: Array = []
	for filha in gerador.get_children():
		if filha is Platform:
			filhas.append(filha)
	return filhas


func test_fator_fica_em_1_menos_v_a_1_mais_v_e_v_zero_devolve_1_exato() -> void:
	var rng := _rng(467)
	var variou := false
	for i in 200:
		var f: float = RowSpeedVariation.fator(rng, VARIACAO)
		assert_between(f, 1.0 - VARIACAO, 1.0 + VARIACAO, "fator dentro de [1-v, 1+v]")
		if not is_equal_approx(f, 1.0):
			variou = true
	assert_true(variou, "com v > 0 o fator varia")
	for i in 20:
		assert_eq(RowSpeedVariation.fator(rng, 0.0), 1.0, "v = 0 devolve exatamente 1.0")


func test_registro_resolve_speed_por_linha_e_ela_nao_entra_na_lista_de_plataforma() -> void:
	var mecanicas: Array[StringName] = [PlatformModifiers.SPEED_POR_LINHA]
	var snapshot := DifficultySnapshot.new(60.0, SPEED_BASE, 3, 0.5, mecanicas)
	var resolvidos: Array[PlatformModifier] = PlatformModifiers.resolver(snapshot)
	assert_eq(resolvidos.size(), 1, "nome conhecido: resolve 1 modificador (nome desconhecido seria ignorado com aviso)")
	assert_true(resolvidos[0] is RowSpeedVariation, "resolve para RowSpeedVariation")

	var gerador := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, _estado(true), _rng(1))
	var plataformas := _plataformas(gerador)
	assert_gt(plataformas.size(), 1, "linha nasce preenchida")
	for p in plataformas:
		assert_eq(p._modificadores.size(), 0, "mecanica de linha nao entra na lista de plataforma")


func test_duas_linhas_do_mesmo_estagio_tem_speeds_diferentes_dentro_da_faixa() -> void:
	var rng := _rng(467)
	var estado := _estado(true)
	var a := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, estado, rng, false, 100.0)
	var b := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, estado, rng, false, 220.0)
	for g in [a, b]:
		var speed: float = absf(g.speed)
		assert_between(speed, SPEED_BASE * (1.0 - VARIACAO), SPEED_BASE * (1.0 + VARIACAO), "speed da linha na faixa")
		for p in _plataformas(g):
			assert_eq(absf(p.speed), speed, "toda plataforma da linha usa a speed da linha")
	assert_ne(a.speed, b.speed, "duas linhas do mesmo estagio sorteiam speeds diferentes")


func test_speed_da_linha_mantem_o_sinal_do_sentido_e_a_magnitude_na_faixa() -> void:
	# A negacao do sentido direito vem depois do fator: o sinal nao pode ser perdido nem invertido.
	var rng := _rng(467)
	var estado := _estado(true)
	for i in 6:
		var esquerda := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, estado, rng, false, 100.0 + 40.0 * i)
		var direita := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_RIGHT, estado, rng, false, 120.0 + 40.0 * i)
		assert_gt(esquerda.speed, 0.0, "sentido esquerdo: speed positiva")
		assert_lt(direita.speed, 0.0, "sentido direito: speed negativa")
		for g in [esquerda, direita]:
			assert_between(absf(g.speed), SPEED_BASE * (1.0 - VARIACAO), SPEED_BASE * (1.0 + VARIACAO), "magnitude em [base*(1-v), base*(1+v)]")
		for p in _plataformas(direita):
			assert_lt(p.speed, 0.0, "plataforma do sentido direito herda o sinal negativo")


func test_sem_a_mecanica_a_speed_e_a_do_snapshot_exata() -> void:
	var rng := _rng(467)
	var estado := _estado(false)
	for tipo in [Enums.PLATFORM_TYPE.MOVE_TO_LEFT, Enums.PLATFORM_TYPE.MOVE_TO_RIGHT]:
		var g := _gerador(tipo, estado, rng)
		assert_eq(absf(g.speed), SPEED_BASE, "sem a mecanica: speed_moveis do snapshot exata")
		for p in _plataformas(g):
			assert_eq(absf(p.speed), SPEED_BASE, "plataforma com a speed do snapshot")


func test_espacamento_medido_bate_com_o_da_speed_sorteada() -> void:
	# Fixture: semente cujo 1o sorteio (o da linha) leva a speed bem acima da base (>= 95)
	var semente := 0
	while SPEED_BASE * RowSpeedVariation.fator(_rng(semente), VARIACAO) < 95.0:
		semente += 1
	var gerador := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, _estado(true), _rng(semente))
	var speed: float = absf(gerador.speed)
	assert_gt(speed - SPEED_BASE, 10.0, "fixture: speed sorteada difere da base")
	var plataformas: Array = []
	var distancias: Array = []
	gerador.child_entered_tree.connect(func(no: Node) -> void:
		if no is Platform and is_equal_approx(no.position.x, SPAWN_MOVE_TO_LEFT):
			if not plataformas.is_empty():
				distancias.append(absf(plataformas.back().position.x - SPAWN_MOVE_TO_LEFT))
			plataformas.append(no)
	)
	await wait_physics_frames(FRAMES_MEDICAO)

	assert_gte(distancias.size(), 3, "ao menos 3 medidas entre plataformas geradas pelo ciclo")
	for d in distancias:
		assert_almost_eq(float(d), MovingRowFill.espacamento(speed), TOLERANCIA_PX, "espacamento medido bate com espacamento(speed da linha)")


func test_linha_inicial_e_sem_derrota_mantem_speed_zero_com_a_mecanica_ligada() -> void:
	var estado := _estado(true)
	var inicial := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, estado, _rng(467), true, 100.0)
	assert_eq(absf(inicial.speed), SPEED_BASE, "linha inicial: speed do snapshot, sem sorteio")

	var estatica := _gerador(Enums.PLATFORM_TYPE.STATIC, estado, _rng(467), true, 220.0)
	for p in _plataformas(estatica):
		assert_eq(p.speed, 0, "estatica da linha inicial: speed 0")

	Global.sem_derrota = true
	var sem_derrota := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, estado, _rng(467), false, 340.0)
	assert_eq(absf(sem_derrota.speed), SPEED_BASE, "sem_derrota: speed do gerador sem sorteio")
	for p in _plataformas(sem_derrota):
		assert_eq(p.speed, 0, "sem_derrota: plataformas com speed 0")
