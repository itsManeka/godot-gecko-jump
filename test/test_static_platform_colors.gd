extends GutTest

# Funcao pura StaticPlatformColors.sortear: 3 cores, com a cor inicial garantida em posicao sorteada.

const TODAS := [
	Enums.COLOR.AMARELO,
	Enums.COLOR.VERDE,
	Enums.COLOR.AZUL,
	Enums.COLOR.VERMELHO,
]


func _rng(semente: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	return rng


func test_sortear_devolve_3_cores_contendo_a_cor_inicial_para_as_4_cores() -> void:
	for cor in TODAS:
		for semente in range(1, 40):
			var cores: Array = StaticPlatformColors.sortear(cor, _rng(semente))
			assert_eq(cores.size(), 3, "3 cores (cor %s, seed %s)" % [cor, semente])
			assert_true(cores.has(cor), "contem a cor inicial %s (seed %s)" % [cor, semente])


func test_posicao_da_cor_inicial_varia_entre_as_3_posicoes() -> void:
	var posicoes := {}
	for semente in range(1, 80):
		var cores: Array = StaticPlatformColors.sortear(Enums.COR_INICIAL, _rng(semente))
		posicoes[cores.find(Enums.COR_INICIAL)] = true
	assert_true(posicoes.has(0), "cor inicial aparece na posicao 0")
	assert_true(posicoes.has(1), "cor inicial aparece na posicao 1")
	assert_true(posicoes.has(2), "cor inicial aparece na posicao 2")


func test_cores_restantes_sao_validas_e_continuam_sorteadas() -> void:
	var vistas := {}
	for semente in range(1, 120):
		var cores: Array = StaticPlatformColors.sortear(Enums.COLOR.AZUL, _rng(semente))
		for c in cores:
			assert_true(TODAS.has(c), "cor %s esta em Enums.COLOR" % c)
			vistas[c] = true
	assert_eq(vistas.size(), 4, "as 4 cores aparecem entre as restantes ao longo das seeds")
