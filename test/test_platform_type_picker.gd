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
		assert_ne(r, Enums.PLATFORM_TYPE.RANDOM_ALL)
		assert_ne(r, Enums.PLATFORM_TYPE.RANDOM_DIRECTION)

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

func test_mesma_seed_produz_mesma_sequencia():
	var a := _sortear(Enums.PLATFORM_TYPE.RANDOM_ALL, 50)
	var b := _sortear(Enums.PLATFORM_TYPE.RANDOM_ALL, 50)
	assert_eq(a, b, "mesma seed deveria dar a mesma sequencia de tipos")
