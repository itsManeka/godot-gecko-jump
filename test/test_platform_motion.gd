extends GutTest

# PlatformSineMotion e PlatformPingPongMotion (f467 T3): C270-C275. Passos manuais de physics frame (1/60 s):
# o ao_processar e chamado a mao em laco, sem esperar o loop do headless.

const PLATAFORMA_CENA := preload("res://scenes/Platform.tscn")
const PASSO := 1.0 / 60.0
const PERIODO_S := 2.5
# 2,5 s a 60 Hz = 150 passos por periodo
const PASSOS_POR_PERIODO := 150
const PERIODOS := 3
const TOLERANCIA_PX := 1.0
const SPEEDS := [60.0, 72.0, 86.0, 100.0, 115.0]


func before_each() -> void:
	Global.platforms.clear()
	Global.set_iniciado(true)


func after_each() -> void:
	Global.platforms.clear()
	Global.set_iniciado(false)


func _plataforma(speed: float) -> Platform:
	var plataforma: Platform = add_child_autofree(PLATAFORMA_CENA.instantiate())
	plataforma.speed = speed
	return plataforma


func _snapshot(amplitude: float, periodo: float = PERIODO_S) -> DifficultySnapshot:
	return DifficultySnapshot.new(60.0, 60.0, 1, 0.5, [], 44.0, 1.0, 0.0, 3.0, amplitude, periodo, 1.0, 0.5, 0.0)


func _rng(semente: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	return rng


# Roda `passos` passos e devolve os desvios_vx medidos a cada passo.
func _desvios(modificador: PlatformModifier, plataforma: Platform, passos: int) -> Array[float]:
	var saida: Array[float] = []
	for i in passos:
		modificador.ao_processar(plataforma, PASSO)
		saida.append(plataforma.desvio_vx)
	return saida


# Deslocamento acumulado (px) a cada passo: soma de desvio * PASSO.
func _deslocamentos(desvios: Array[float]) -> Array[float]:
	var acumulado := 0.0
	var saida: Array[float] = []
	for d in desvios:
		acumulado += d * PASSO
		saida.append(acumulado)
	return saida


# C270: a integral do desvio em N periodos inteiros e 0 (+-1 px); cada passo bate com A*w*cos(w*t+fase).
func test_seno_integral_do_desvio_em_periodos_inteiros_e_zero() -> void:
	var plataforma := _plataforma(60.0)
	var seno := PlatformSineMotion.new()
	seno.iniciar(_rng(7))
	seno.ao_criar(plataforma, _snapshot(8.0))
	var desvios := _desvios(seno, plataforma, PASSOS_POR_PERIODO * PERIODOS)
	var w := TAU / PERIODO_S
	var soma := 0.0
	for i in desvios.size():
		var t := (i + 1) * PASSO
		var esperado := 8.0 * w * cos(w * t + seno.get_fase())
		assert_almost_eq(desvios[i], esperado, 0.001, "passo %d: A*w*cos(w*t+fase)" % i)
		soma += desvios[i] * PASSO
	assert_almost_eq(soma, 0.0, TOLERANCIA_PX, "integral em %d periodos inteiros = 0" % PERIODOS)
	var nao_nulos := desvios.filter(func(d: float) -> bool: return absf(d) > 1.0)
	assert_gt(nao_nulos.size(), 100, "o desvio existe (nao e sempre 0)")


# C271: pico do deslocamento acumulado = amplitude, com amplitude 6 e 8.
func test_seno_pico_do_deslocamento_e_a_amplitude() -> void:
	for amplitude in [6.0, 8.0]:
		var plataforma := _plataforma(60.0)
		var seno := PlatformSineMotion.new()
		seno.iniciar(_rng(11))
		seno.ao_criar(plataforma, _snapshot(amplitude))
		var deslocamentos := _deslocamentos(_desvios(seno, plataforma, PASSOS_POR_PERIODO * 2))
		var pico: float = (deslocamentos.max() - deslocamentos.min()) / 2.0
		assert_almost_eq(pico, amplitude, TOLERANCIA_PX, "pico do deslocamento com amplitude %s" % amplitude)


# C272: speed - desvio e speed + desvio ficam do mesmo sinal da speed em todo instante (nunca inverte), media 0.
func test_vai_e_vem_nunca_inverte_o_sentido_nas_speeds_da_curva() -> void:
	for speed in SPEEDS:
		for amplitude in [6.0, 8.0]:
			var plataforma := _plataforma(speed)
			var vai_e_vem := PlatformPingPongMotion.new()
			vai_e_vem.iniciar(_rng(int(speed)))
			vai_e_vem.ao_criar(plataforma, _snapshot(amplitude))
			var desvios := _desvios(vai_e_vem, plataforma, PASSOS_POR_PERIODO * PERIODOS)
			var soma := 0.0
			var menor_folga := INF
			for d in desvios:
				menor_folga = minf(menor_folga, minf(speed - d, speed + d))
				soma += d
			assert_gt(menor_folga, 0.0, "speed %s amplitude %s: nunca inverte" % [speed, amplitude])
			assert_almost_eq(soma / desvios.size(), 0.0, 0.5, "media do desvio = 0 (speed %s)" % speed)
			var maximo := 0.0
			for d in desvios:
				maximo = maxf(maximo, absf(d))
			assert_gt(maximo, 10.0, "o desvio existe: pico %s (speed %s)" % [maximo, speed])


# C272 (forma): o pico de deslocamento do vai-e-vem e a amplitude (onda triangular de velocidade).
func test_vai_e_vem_pico_do_deslocamento_e_a_amplitude() -> void:
	var plataforma := _plataforma(100.0)
	var vai_e_vem := PlatformPingPongMotion.new()
	vai_e_vem.iniciar(_rng(3))
	vai_e_vem.ao_criar(plataforma, _snapshot(8.0))
	var deslocamentos := _deslocamentos(_desvios(vai_e_vem, plataforma, PASSOS_POR_PERIODO * 2))
	var pico: float = (deslocamentos.max() - deslocamentos.min()) / 2.0
	assert_almost_eq(pico, 8.0, TOLERANCIA_PX, "pico = amplitude")


# C273: speed 0 ou fora de is_iniciado(): desvio 0 e a fase (relogio) nao avanca.
func test_sem_movimento_o_desvio_e_zero_e_a_fase_nao_avanca() -> void:
	for modificador in [PlatformSineMotion.new(), PlatformPingPongMotion.new()]:
		var referencia: PlatformModifier = modificador.get_script().new()
		modificador.iniciar(_rng(5))
		referencia.iniciar(_rng(5))
		var plataforma := _plataforma(60.0)
		var plataforma_ref := _plataforma(60.0)
		modificador.ao_criar(plataforma, _snapshot(8.0))
		referencia.ao_criar(plataforma_ref, _snapshot(8.0))
		# parado por partida nao iniciada: 2 chamadas nao avancam nada
		Global.set_iniciado(false)
		modificador.ao_processar(plataforma, PASSO)
		modificador.ao_processar(plataforma, PASSO)
		assert_eq(plataforma.desvio_vx, 0.0, "fora de is_iniciado: desvio 0")
		Global.set_iniciado(true)
		modificador.ao_processar(plataforma, PASSO)
		referencia.ao_processar(plataforma_ref, PASSO)
		assert_ne(plataforma.desvio_vx, 0.0, "depois de iniciar o desvio existe")
		assert_eq(plataforma.desvio_vx, plataforma_ref.desvio_vx, "a fase nao avancou parada (mesmo desvio do 1o passo)")
		# parado por speed 0
		var parada := _plataforma(0.0)
		modificador.ao_processar(parada, PASSO)
		assert_eq(parada.desvio_vx, 0.0, "speed 0: desvio 0")
		modificador.ao_processar(parada, PASSO)
		plataforma.speed = 60.0
		modificador.ao_processar(plataforma, PASSO)
		referencia.ao_processar(plataforma_ref, PASSO)
		assert_eq(plataforma.desvio_vx, plataforma_ref.desvio_vx, "speed 0 tambem nao avanca a fase")


# C274: mesma semente = mesma fase; sementes distintas = fases distintas.
func test_mesma_semente_mesma_fase_e_sementes_distintas_fases_distintas() -> void:
	for classe in [PlatformSineMotion, PlatformPingPongMotion]:
		var a: PlatformModifier = classe.new()
		var b: PlatformModifier = classe.new()
		var c: PlatformModifier = classe.new()
		a.iniciar(_rng(42))
		b.iniciar(_rng(42))
		c.iniciar(_rng(43))
		assert_eq(a.get_fase(), b.get_fase(), "mesma semente, mesma fase")
		assert_ne(a.get_fase(), c.get_fase(), "sementes distintas, fases distintas")
		assert_between(a.get_fase(), 0.0, TAU, "fase em [0, 2pi)")


# C275: valem na linha inicial e snapshot de amplitude 0 = desvio sempre 0 (padrao sem efeito).
func test_amplitude_zero_nao_tem_efeito_e_vale_em_linha_inicial() -> void:
	for modificador in [PlatformSineMotion.new(), PlatformPingPongMotion.new()]:
		assert_true(modificador.vale_em_linha_inicial(), "vale em linha inicial")
		modificador.iniciar(_rng(9))
		var plataforma := _plataforma(60.0)
		modificador.ao_criar(plataforma, _snapshot(0.0))
		for d in _desvios(modificador, plataforma, PASSOS_POR_PERIODO):
			assert_eq(d, 0.0, "amplitude 0: desvio 0")
		var sem_snapshot := _plataforma(60.0)
		modificador.ao_criar(sem_snapshot, null)
		for d in _desvios(modificador, sem_snapshot, 10):
			assert_eq(d, 0.0, "sem snapshot: desvio 0")
