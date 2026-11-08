extends GutTest

# Testes das cores (scripts/Enums.gd): paleta exata, fallback e sorteio com RNG injetavel.


func test_get_cor_amarelo_e_a_cor_da_paleta() -> void:
	assert_eq(Enums.get_cor(Enums.COLOR.AMARELO), Color("#f6db61"))


func test_get_cor_verde_e_a_cor_da_paleta() -> void:
	assert_eq(Enums.get_cor(Enums.COLOR.VERDE), Color("#79cf5a"))


func test_get_cor_azul_e_a_cor_da_paleta() -> void:
	assert_eq(Enums.get_cor(Enums.COLOR.AZUL), Color("#5987e9"))


func test_get_cor_vermelho_e_a_cor_da_paleta() -> void:
	assert_eq(Enums.get_cor(Enums.COLOR.VERMELHO), Color("#ec4848"))


func test_get_cor_valor_invalido_cai_no_branco_e_cores_sao_distintas() -> void:
	var branco := Color("#ffffff")
	assert_eq(Enums.get_cor(99), branco)
	var cores: Array[Color] = [
		Enums.get_cor(Enums.COLOR.AMARELO),
		Enums.get_cor(Enums.COLOR.VERDE),
		Enums.get_cor(Enums.COLOR.AZUL),
		Enums.get_cor(Enums.COLOR.VERMELHO),
		branco,
	]
	for i in range(cores.size()):
		for j in range(i + 1, cores.size()):
			assert_ne(cores[i], cores[j], "cores %d e %d devem ser distintas" % [i, j])


func test_get_random_color_sem_argumento_devolve_valor_valido() -> void:
	var valores: Array = Enums.COLOR.values()
	var sorteada = Enums.get_random_color()
	assert_true(valores.has(sorteada), "valor sorteado deve pertencer a COLOR")


func test_get_random_color_sem_rng_so_devolve_valores_de_color() -> void:
	var valores: Array = Enums.COLOR.values()
	for _i in range(200):
		var sorteada = Enums.get_random_color()
		assert_true(valores.has(sorteada), "sorteio %d fora de COLOR" % _i)


func test_get_random_color_com_rng_cobre_as_4_cores() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var vistas: Dictionary = {}
	for _i in range(200):
		vistas[Enums.get_random_color(rng)] = true
	assert_eq(vistas.size(), 4, "com seed fixa devem aparecer as 4 cores")


func test_get_random_color_mesma_seed_produz_mesma_sequencia() -> void:
	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 777
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 777
	var seq_a: Array = []
	var seq_b: Array = []
	for _i in range(50):
		seq_a.append(Enums.get_random_color(rng_a))
		seq_b.append(Enums.get_random_color(rng_b))
	assert_eq(seq_a, seq_b, "mesma seed deve dar a mesma sequencia")
