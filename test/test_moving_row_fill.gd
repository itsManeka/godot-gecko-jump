extends GutTest

# Regra pura do preenchimento de linha movel (MovingRowFill.initial_xs). Sem cena: so numeros.
# Valores esperados vem da formula (spawn -/+ k * ESPACAMENTO), nunca copiados da saida da classe.
# O sentido e pelo ponto de nascimento e pelo lado do passo, nao pelo nome do enum (D1).
# Resolucao 360x640 (f565): distancias e velocidades 2x; os ticks por plataforma (79 a 120 px/s) nao mudam.


const SPEED_BASE := 120.0
const SPEED_INTERMEDIARIA := 172.0
const SPEED_TETO := 200.0
const SPAWN_ESQUERDA := 420.0 # nasce a direita, anda a esquerda
const SPAWN_DIREITA := -60.0 # nasce a esquerda, anda a direita
const LARGURA := 360.0


func test_espacamento_na_speed_120_e_158() -> void:
	assert_eq(MovingRowFill.espacamento(SPEED_BASE), 158.0, "espacamento(120) = 79 ticks * 2 px = 158 px")


# Referencia do layout 180x320: (ceil(60.2995 / (v/60)) + 18) * v/60. O 2x dobra a velocidade e mantem os ticks.
func test_espacamento_de_2v_e_o_dobro_do_antigo_com_os_mesmos_ticks() -> void:
	for v in [60.0, 72.0, 86.0, 100.0]:
		var por_tick: float = v / 60.0
		var ticks: float = ceilf(60.2995 / por_tick) + 18.0
		assert_almost_eq(MovingRowFill.espacamento(2.0 * v), 2.0 * ticks * por_tick, 0.0001, "espacamento(2*%s) = 2 * espacamento antigo(%s)" % [v, v])
		assert_almost_eq(MovingRowFill.espacamento(2.0 * v) / (2.0 * por_tick), ticks, 0.0001, "espacamento(2*%s) em ticks = o mesmo numero de ticks de %s" % [v, v])


func test_espacamento_cresce_com_a_speed_pela_formula() -> void:
	for speed in [SPEED_BASE, SPEED_INTERMEDIARIA, SPEED_TETO]:
		var por_tick: float = speed / 60.0
		var esperado: float = (ceilf(120.599 / por_tick) + 18.0) * por_tick
		assert_almost_eq(MovingRowFill.espacamento(speed), esperado, 0.0001, "espacamento(%s) = (ticks de saida + 18) * speed/60" % speed)
		assert_between(MovingRowFill.espacamento(speed), 120.599 + 0.3 * speed, 120.599 + 0.3 * speed + por_tick + 0.0001, "dentro de 1 tick da formula linear")
	assert_gt(MovingRowFill.espacamento(SPEED_TETO), MovingRowFill.espacamento(SPEED_BASE), "speed maior, espacamento maior")


func test_initial_xs_sem_speed_e_igual_ao_estagio_0() -> void:
	for lado in [true, false]:
		var spawn := SPAWN_ESQUERDA if lado else SPAWN_DIREITA
		assert_eq(MovingRowFill.initial_xs(spawn, lado), MovingRowFill.initial_xs(spawn, lado, LARGURA, SPEED_BASE), "sem speed = speed 120")
		assert_eq(MovingRowFill.initial_xs(spawn, lado, 512.0), MovingRowFill.initial_xs(spawn, lado, 512.0, SPEED_BASE), "largura sem speed = speed 120")
	assert_eq(MovingRowFill.initial_xs(SPAWN_ESQUERDA, true), [SPAWN_ESQUERDA - 158.0, SPAWN_ESQUERDA - 2.0 * 158.0, SPAWN_ESQUERDA - 3.0 * 158.0], "estagio 0 = passos de 158")


func test_initial_xs_usa_o_espacamento_da_speed() -> void:
	for speed in [SPEED_INTERMEDIARIA, SPEED_TETO]:
		var s := MovingRowFill.espacamento(speed)
		var xs := MovingRowFill.initial_xs(SPAWN_ESQUERDA, true, LARGURA, speed)
		assert_gt(xs.size(), 0, "ha ao menos 1 x pre-colocado")
		for i in range(xs.size()):
			assert_almost_eq(xs[i], SPAWN_ESQUERDA - s * float(i + 1), 0.0001, "x[%d] a (i+1) * espacamento(%s) do nascimento" % [i, speed])


func test_nasce_em_420_anda_a_esquerda_largura_360() -> void:
	var s := MovingRowFill.espacamento(SPEED_BASE)
	var xs := MovingRowFill.initial_xs(SPAWN_ESQUERDA, true, LARGURA)
	assert_eq(xs.size(), 3, "largura 360, nascendo em 420 indo a esquerda: N = 3")
	assert_eq(xs[0], SPAWN_ESQUERDA - s, "1o x = 420 - S, o mais proximo do nascimento")
	assert_eq(xs[1], SPAWN_ESQUERDA - 2.0 * s, "2o x = 420 - 2S")
	assert_eq(xs[2], SPAWN_ESQUERDA - 3.0 * s, "3o x = 420 - 3S (borda, ~6 px visiveis)")
	assert_eq(MovingRowFill.initial_xs(SPAWN_ESQUERDA, true), xs, "largura default e 360")


func test_nasce_em_menos60_anda_a_direita_largura_360() -> void:
	var s := MovingRowFill.espacamento(SPEED_BASE)
	var xs := MovingRowFill.initial_xs(SPAWN_DIREITA, false, LARGURA)
	assert_eq(xs.size(), 3, "largura 360, nascendo em -60 indo a direita: N = 3")
	assert_eq(xs[0], SPAWN_DIREITA + s, "1o x = -60 + S, o mais proximo do nascimento")
	assert_eq(xs[1], SPAWN_DIREITA + 2.0 * s, "2o x = -60 + 2S")
	assert_eq(xs[2], SPAWN_DIREITA + 3.0 * s, "3o x = -60 + 3S (borda, ~6 px visiveis)")


func test_nenhum_x_fora_da_janela_e_sem_ponto_de_nascimento() -> void:
	var casos := [[SPAWN_ESQUERDA, true, LARGURA], [SPAWN_DIREITA, false, LARGURA], [256.0, true, LARGURA], [SPAWN_DIREITA, false, 512.0]]
	for caso in casos:
		var spawn: float = caso[0]
		var xs := MovingRowFill.initial_xs(spawn, caso[1], caso[2])
		for x in xs:
			assert_true(x > -60.0 and x < caso[2] + 60.0, "x %s fora de (-60, largura+60) com spawn %s" % [x, spawn])
			assert_ne(x, spawn, "o ponto de nascimento %s nunca entra na lista" % spawn)
	# Limite exclusivo: -60 + 4S = 572 cai em largura + 60 (512 + 60) e fica de fora; 98, 256, 414 ficam.
	assert_eq(MovingRowFill.initial_xs(SPAWN_DIREITA, false, 512.0).size(), 3, "x = largura + 60 fica de fora")
	# Limite exclusivo do outro lado: 256 - S = 98 e 256 - 2S = -60 fica de fora.
	assert_eq(MovingRowFill.initial_xs(256.0, true, LARGURA), [98.0], "x = -60 fica de fora")


func test_espacamento_consecutivo_igual_a_espacamento() -> void:
	for speed in [SPEED_BASE, SPEED_INTERMEDIARIA, SPEED_TETO]:
		var s := MovingRowFill.espacamento(speed)
		for largura in [360.0, 512.0, 800.0]:
			for lado in [true, false]:
				var spawn := SPAWN_ESQUERDA if lado else SPAWN_DIREITA
				var xs := MovingRowFill.initial_xs(spawn, lado, largura, speed)
				for i in range(1, xs.size()):
					assert_almost_eq(absf(xs[i] - xs[i - 1]), s, 0.0001, "passo consecutivo diferente de espacamento(%s)" % speed)
				if xs.size() > 0:
					assert_almost_eq(absf(xs[0] - spawn), s, 0.0001, "1a plataforma a espacamento(%s) do nascimento" % speed)


func test_largura_zero_ou_pequena_devolve_so_o_que_cabe() -> void:
	# Largura 0: janela (-60, 60). Nascendo em -60 indo a direita, o 1o passo (98) ja passa do limite: vazio.
	assert_eq(MovingRowFill.initial_xs(SPAWN_DIREITA, false, 0.0), [], "nada cabe: lista vazia, sem erro")
	# Nascendo em 420 indo a esquerda, so -54 cai na janela (-60, 60); 262 e 104 ficam de fora.
	var xs_zero := MovingRowFill.initial_xs(SPAWN_ESQUERDA, true, 0.0)
	assert_eq(xs_zero, [SPAWN_ESQUERDA - 3.0 * MovingRowFill.espacamento(SPEED_BASE)], "largura 0: so o x que cabe na janela")
	# Largura crescente nunca diminui N (monotona) e nunca produz x fora da janela.
	var anterior := -1
	for largura_int in range(0, 801):
		var largura := float(largura_int)
		var xs := MovingRowFill.initial_xs(SPAWN_ESQUERDA, true, largura)
		assert_true(xs.size() >= anterior, "N caiu ao aumentar a largura para %s" % largura)
		anterior = xs.size()
		for x in xs:
			assert_true(x > -60.0 and x < largura + 60.0, "x %s fora da janela na largura %s" % [x, largura])
