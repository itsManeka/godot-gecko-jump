extends GutTest

# Testes da escolha do tipo concreto de gerador (PlatformTypePicker), sem arvore de cena.
# Sorteios com RandomNumberGenerator de seed fixa: determinismo entre execucoes.

const SEED := 4242
const N_SORTEIOS := 300

func _sortear(tipo: Enums.PLATFORM_TYPE, n: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var resultados: Array = []
	for i in n:
		resultados.append(PlatformTypePicker.resolve(tipo, rng))
	return resultados

func test_random_all_so_devolve_tipos_concretos():
	var resultados := _sortear(Enums.PLATFORM_TYPE.RANDOM_ALL, N_SORTEIOS)
	var concretos := [
		Enums.PLATFORM_TYPE.STATIC,
		Enums.PLATFORM_TYPE.MOVE_TO_LEFT,
		Enums.PLATFORM_TYPE.MOVE_TO_RIGHT,
	]
	for r in resultados:
		assert_true(r in concretos, "RANDOM_ALL devolveu tipo nao concreto: %s" % r)

func test_random_all_sorteia_static():
	var resultados := _sortear(Enums.PLATFORM_TYPE.RANDOM_ALL, N_SORTEIOS)
	assert_true(resultados.has(Enums.PLATFORM_TYPE.STATIC), "RANDOM_ALL nunca sorteou STATIC")

func test_random_all_sorteia_move_to_left():
	var resultados := _sortear(Enums.PLATFORM_TYPE.RANDOM_ALL, N_SORTEIOS)
	assert_true(resultados.has(Enums.PLATFORM_TYPE.MOVE_TO_LEFT), "RANDOM_ALL nunca sorteou MOVE_TO_LEFT")

func test_random_all_sorteia_move_to_right():
	var resultados := _sortear(Enums.PLATFORM_TYPE.RANDOM_ALL, N_SORTEIOS)
	assert_true(resultados.has(Enums.PLATFORM_TYPE.MOVE_TO_RIGHT), "RANDOM_ALL nunca sorteou MOVE_TO_RIGHT")

func test_random_direction_so_devolve_esquerda_ou_direita():
	var resultados := _sortear(Enums.PLATFORM_TYPE.RANDOM_DIRECTION, N_SORTEIOS)
	for r in resultados:
		assert_true(
			r == Enums.PLATFORM_TYPE.MOVE_TO_LEFT or r == Enums.PLATFORM_TYPE.MOVE_TO_RIGHT,
			"RANDOM_DIRECTION devolveu tipo fora de LEFT/RIGHT: %s" % r
		)
		assert_ne(r, Enums.PLATFORM_TYPE.STATIC)

func test_random_direction_sorteia_os_dois_sentidos():
	var resultados := _sortear(Enums.PLATFORM_TYPE.RANDOM_DIRECTION, N_SORTEIOS)
	assert_true(resultados.has(Enums.PLATFORM_TYPE.MOVE_TO_LEFT), "RANDOM_DIRECTION nunca sorteou MOVE_TO_LEFT")
	assert_true(resultados.has(Enums.PLATFORM_TYPE.MOVE_TO_RIGHT), "RANDOM_DIRECTION nunca sorteou MOVE_TO_RIGHT")

func test_tipo_static_passa_intacto():
	var resultados := _sortear(Enums.PLATFORM_TYPE.STATIC, 10)
	for r in resultados:
		assert_eq(r, Enums.PLATFORM_TYPE.STATIC)

func test_tipo_move_to_left_passa_intacto():
	var resultados := _sortear(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, 10)
	for r in resultados:
		assert_eq(r, Enums.PLATFORM_TYPE.MOVE_TO_LEFT)

func test_tipo_move_to_right_passa_intacto():
	var resultados := _sortear(Enums.PLATFORM_TYPE.MOVE_TO_RIGHT, 10)
	for r in resultados:
		assert_eq(r, Enums.PLATFORM_TYPE.MOVE_TO_RIGHT)

# Golden capturada do HEAD (randi() % 3, seed 4242) antes da proporcao parametrizada; enum: STATIC=0, LEFT=1, RIGHT=2.
const GOLDEN_RANDOM_ALL := [
	2, 1, 0, 2, 0, 0, 1, 0, 1, 2, 0, 2, 2, 0, 0, 0, 2, 0, 2, 1,
	0, 0, 2, 0, 2, 0, 0, 1, 0, 1, 1, 0, 0, 0, 0, 2, 0, 1, 1, 2,
]

func _sortear_prop(tipo: Enums.PLATFORM_TYPE, n: int, proporcao: float) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var resultados: Array = []
	for i in n:
		resultados.append(PlatformTypePicker.resolve(tipo, rng, proporcao))
	return resultados

func test_proporcao_estagio_0_reproduz_golden_do_randi_modulo_3():
	var resultados := _sortear_prop(
		Enums.PLATFORM_TYPE.RANDOM_ALL, GOLDEN_RANDOM_ALL.size(), DifficultyStage.PROPORCAO_PADRAO
	)
	var inteiros: Array = []
	for r in resultados:
		inteiros.append(int(r))
	assert_true(inteiros == GOLDEN_RANDOM_ALL, "estagio 0 deve manter a sequencia seedada de antes")

func test_proporcao_omitida_reproduz_golden():
	var inteiros: Array = []
	for r in _sortear(Enums.PLATFORM_TYPE.RANDOM_ALL, GOLDEN_RANDOM_ALL.size()):
		inteiros.append(int(r))
	assert_eq(inteiros, GOLDEN_RANDOM_ALL)

func test_proporcao_zero_nunca_devolve_static():
	var resultados := _sortear_prop(Enums.PLATFORM_TYPE.RANDOM_ALL, 1000, 0.0)
	assert_eq(resultados.size(), 1000)
	assert_false(resultados.has(Enums.PLATFORM_TYPE.STATIC), "proporcao 0.0 devolveu STATIC")

func test_proporcao_um_so_devolve_static():
	for r in _sortear_prop(Enums.PLATFORM_TYPE.RANDOM_ALL, 200, 1.0):
		assert_eq(r, Enums.PLATFORM_TYPE.STATIC)

func test_proporcao_do_teto_respeitada_e_moveis_divididas_meio_a_meio():
	var n := 4000
	var proporcao := 0.1
	var resultados := _sortear_prop(Enums.PLATFORM_TYPE.RANDOM_ALL, n, proporcao)
	var estaticas := resultados.count(Enums.PLATFORM_TYPE.STATIC)
	var esquerda := resultados.count(Enums.PLATFORM_TYPE.MOVE_TO_LEFT)
	var direita := resultados.count(Enums.PLATFORM_TYPE.MOVE_TO_RIGHT)
	assert_eq(estaticas + esquerda + direita, n)
	assert_almost_eq(float(estaticas) / n, proporcao, 0.03, "fracao de estaticas fora da tolerancia")
	var moveis := esquerda + direita
	assert_gt(moveis, 0)
	assert_almost_eq(float(esquerda) / moveis, 0.5, 0.04, "esquerda/direita fora de ~50/50")

func test_random_direction_e_concretos_inalterados_com_proporcao_nao_padrao():
	for r in _sortear_prop(Enums.PLATFORM_TYPE.RANDOM_DIRECTION, 200, 1.0):
		assert_true(r == Enums.PLATFORM_TYPE.MOVE_TO_LEFT or r == Enums.PLATFORM_TYPE.MOVE_TO_RIGHT)
	var dir := _sortear_prop(Enums.PLATFORM_TYPE.RANDOM_DIRECTION, 200, 1.0)
	assert_true(dir.has(Enums.PLATFORM_TYPE.MOVE_TO_LEFT) and dir.has(Enums.PLATFORM_TYPE.MOVE_TO_RIGHT))
	for tipo in [Enums.PLATFORM_TYPE.STATIC, Enums.PLATFORM_TYPE.MOVE_TO_LEFT, Enums.PLATFORM_TYPE.MOVE_TO_RIGHT]:
		for r in _sortear_prop(tipo, 20, 0.9):
			assert_eq(r, tipo)

func test_mesma_seed_produz_mesma_sequencia():
	var a := _sortear(Enums.PLATFORM_TYPE.RANDOM_ALL, 50)
	var b := _sortear(Enums.PLATFORM_TYPE.RANDOM_ALL, 50)
	assert_eq(a, b, "mesma seed deveria dar a mesma sequencia de tipos")
