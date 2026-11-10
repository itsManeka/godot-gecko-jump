extends GutTest

# Regra pura do preenchimento de linha movel (MovingRowFill.initial_xs). Sem cena: so numeros.
# Valores esperados vem da formula (spawn -/+ k * ESPACAMENTO), nunca copiados da saida da classe.
# O sentido e pelo ponto de nascimento e pelo lado do passo, nao pelo nome do enum (D1).


func test_nasce_em_210_anda_a_esquerda_largura_180() -> void:
	var s := MovingRowFill.ESPACAMENTO
	var xs := MovingRowFill.initial_xs(210.0, true, 180.0)
	assert_eq(xs.size(), 3, "largura 180, nascendo em 210 indo a esquerda: N = 3")
	assert_eq(xs[0], 210.0 - s, "1o x = 210 - S, o mais proximo do nascimento")
	assert_eq(xs[1], 210.0 - 2.0 * s, "2o x = 210 - 2S")
	assert_eq(xs[2], 210.0 - 3.0 * s, "3o x = 210 - 3S (borda, ~3 px visiveis)")
	assert_eq(MovingRowFill.initial_xs(210.0, true), xs, "largura default e 180")


func test_nasce_em_menos30_anda_a_direita_largura_180() -> void:
	var s := MovingRowFill.ESPACAMENTO
	var xs := MovingRowFill.initial_xs(-30.0, false, 180.0)
	assert_eq(xs.size(), 3, "largura 180, nascendo em -30 indo a direita: N = 3")
	assert_eq(xs[0], -30.0 + s, "1o x = -30 + S, o mais proximo do nascimento")
	assert_eq(xs[1], -30.0 + 2.0 * s, "2o x = -30 + 2S")
	assert_eq(xs[2], -30.0 + 3.0 * s, "3o x = -30 + 3S (borda, ~3 px visiveis)")


func test_nenhum_x_fora_da_janela_e_sem_ponto_de_nascimento() -> void:
	var casos := [[210.0, true, 180.0], [-30.0, false, 180.0], [128.0, true, 180.0], [-30.0, false, 256.0]]
	for caso in casos:
		var spawn: float = caso[0]
		var xs := MovingRowFill.initial_xs(spawn, caso[1], caso[2])
		for x in xs:
			assert_true(x > -30.0 and x < caso[2] + 30.0, "x %s fora de (-30, largura+30) com spawn %s" % [x, spawn])
			assert_ne(x, spawn, "o ponto de nascimento %s nunca entra na lista" % spawn)
	# Limite exclusivo: 286 = -30 + 4S cai em largura + 30 (256 + 30) e fica de fora; 49, 128, 207 ficam.
	assert_eq(MovingRowFill.initial_xs(-30.0, false, 256.0).size(), 3, "x = largura + 30 fica de fora")
	# Limite exclusivo do outro lado: 128 - S = 49 e 128 - 2S = -30 fica de fora.
	assert_eq(MovingRowFill.initial_xs(128.0, true, 180.0), [49.0], "x = -30 fica de fora")


func test_espacamento_consecutivo_igual_a_espacamento() -> void:
	var s := MovingRowFill.ESPACAMENTO
	assert_eq(s, 79.0, "fonte unica: ESPACAMENTO e 79 px")
	for largura in [180.0, 256.0, 400.0]:
		for lado in [true, false]:
			var spawn := 210.0 if lado else -30.0
			var xs := MovingRowFill.initial_xs(spawn, lado, largura)
			for i in range(1, xs.size()):
				assert_almost_eq(absf(xs[i] - xs[i - 1]), s, 0.0001, "passo consecutivo diferente de ESPACAMENTO")
			if xs.size() > 0:
				assert_almost_eq(absf(xs[0] - spawn), s, 0.0001, "1a plataforma a ESPACAMENTO do nascimento")


func test_largura_zero_ou_pequena_devolve_so_o_que_cabe() -> void:
	# Largura 0: janela (-30, 30). Nascendo em -30 indo a direita, o 1o passo (49) ja passa do limite: vazio.
	assert_eq(MovingRowFill.initial_xs(-30.0, false, 0.0), [], "nada cabe: lista vazia, sem erro")
	# Nascendo em 210 indo a esquerda, so -27 cai na janela (-30, 30); 131 e 52 ficam de fora.
	var xs_zero := MovingRowFill.initial_xs(210.0, true, 0.0)
	assert_eq(xs_zero, [210.0 - 3.0 * MovingRowFill.ESPACAMENTO], "largura 0: so o x que cabe na janela")
	# Largura crescente nunca diminui N (monotona) e nunca produz x fora da janela.
	var anterior := -1
	for largura_int in range(0, 401):
		var largura := float(largura_int)
		var xs := MovingRowFill.initial_xs(210.0, true, largura)
		assert_true(xs.size() >= anterior, "N caiu ao aumentar a largura para %s" % largura)
		anterior = xs.size()
		for x in xs:
			assert_true(x > -30.0 and x < largura + 30.0, "x %s fora da janela na largura %s" % [x, largura])
