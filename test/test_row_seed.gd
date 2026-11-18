extends GutTest

# Testes do derivador de rng por linha (RowSeed): indice da linha pelo y local (geometria de
# InitialRows, nunca a ordem de criacao) e canais independentes layout/cor_movel com seed
# misturada por hash de [semente, indice, canal]. Sem arvore de cena: funcoes puras, seeds fixas.

const SEED := 4242
const INDICE := 7
const N_SORTEIOS := 12


func _sequencia(rng: RandomNumberGenerator, n: int) -> Array:
	var valores: Array = []
	for i in n:
		valores.append(rng.randi())
	return valores


# C476: mesma (seed, indice) -> mesma sequencia de randi() nos canais layout e cor_movel;
# (seed, indice) vizinhos divergem.
func test_mesma_seed_e_indice_reproduz_sequencia_e_vizinhos_divergem() -> void:
	var layout_a := RowSeed.rng_layout(SEED, INDICE)
	var layout_b := RowSeed.rng_layout(SEED, INDICE)
	assert_eq(
		_sequencia(layout_a, N_SORTEIOS),
		_sequencia(layout_b, N_SORTEIOS),
		"mesma (seed, indice) deveria reproduzir a sequencia de randi() do canal layout"
	)
	var cor_a := RowSeed.rng_cor_movel(SEED, INDICE)
	var cor_b := RowSeed.rng_cor_movel(SEED, INDICE)
	assert_eq(
		_sequencia(cor_a, N_SORTEIOS),
		_sequencia(cor_b, N_SORTEIOS),
		"mesma (seed, indice) deveria reproduzir a sequencia de randi() do canal cor_movel"
	)
	var base_layout := _sequencia(RowSeed.rng_layout(SEED, INDICE), N_SORTEIOS)
	var base_cor := _sequencia(RowSeed.rng_cor_movel(SEED, INDICE), N_SORTEIOS)
	for semente_vizinha in [SEED + 1, SEED - 1]:
		assert_ne(
			_sequencia(RowSeed.rng_layout(semente_vizinha, INDICE), N_SORTEIOS),
			base_layout,
			"vizinho (%s, %s) do canal layout repetiu a sequencia" % [semente_vizinha, INDICE]
		)
		assert_ne(
			_sequencia(RowSeed.rng_cor_movel(semente_vizinha, INDICE), N_SORTEIOS),
			base_cor,
			"vizinho (%s, %s) do canal cor_movel repetiu a sequencia" % [semente_vizinha, INDICE]
		)
	for indice_vizinho in [INDICE + 1, INDICE - 1]:
		assert_ne(
			_sequencia(RowSeed.rng_layout(SEED, indice_vizinho), N_SORTEIOS),
			base_layout,
			"vizinho (%s, %s) do canal layout repetiu a sequencia" % [SEED, indice_vizinho]
		)
		assert_ne(
			_sequencia(RowSeed.rng_cor_movel(SEED, indice_vizinho), N_SORTEIOS),
			base_cor,
			"vizinho (%s, %s) do canal cor_movel repetiu a sequencia" % [SEED, indice_vizinho]
		)


# C477: mistura por hash, nao soma: (s, i+1) difere de (s+1, i); seeds consecutivas nao
# deslocam linhas (com soma, a linha i-1 da seed seguinte repetiria a linha i da atual).
func test_mistura_por_hash_nao_soma_e_seed_consecutiva_nao_desloca() -> void:
	assert_ne(
		_sequencia(RowSeed.rng_layout(SEED, INDICE + 1), N_SORTEIOS),
		_sequencia(RowSeed.rng_layout(SEED + 1, INDICE), N_SORTEIOS),
		"(s, i+1) repetiu a sequencia de (s+1, i): a mistura esta somando em vez de usar hash"
	)
	assert_ne(
		_sequencia(RowSeed.rng_cor_movel(SEED, INDICE + 1), N_SORTEIOS),
		_sequencia(RowSeed.rng_cor_movel(SEED + 1, INDICE), N_SORTEIOS),
		"canal cor_movel: (s, i+1) repetiu a sequencia de (s+1, i)"
	)
	var referencia := _sequencia(RowSeed.rng_layout(SEED, INDICE), N_SORTEIOS)
	for deslocamento in range(-8, 9):
		assert_ne(
			_sequencia(RowSeed.rng_layout(SEED + 1, INDICE + deslocamento), N_SORTEIOS),
			referencia,
			"seed consecutiva deslocou as linhas: (s+1, %s) repetiu a sequencia de (s, %s)"
			% [INDICE + deslocamento, INDICE]
		)


# C478: canais layout e cor_movel da mesma (seed, indice) divergem entre si.
func test_canais_layout_e_cor_movel_divergem_entre_si() -> void:
	for indice in [-4, 0, 1, 7]:
		assert_ne(
			_sequencia(RowSeed.rng_layout(SEED, indice), N_SORTEIOS),
			_sequencia(RowSeed.rng_cor_movel(SEED, indice), N_SORTEIOS),
			"canais da mesma (seed, indice) colidem no indice %s" % indice
		)


# C479: indice por y local: -10 -> 0, -60 -> 1, 40 -> -1, 190 -> -4 (valores do requisito,
# formula InitialRows.Y_TOPO/ESPACAMENTO; indice negativo valido).
func test_indice_por_y_local_valores_do_requisito() -> void:
	assert_eq(RowSeed.indice_do_y(-10.0), 0, "y -10 (topo) deveria ter indice 0")
	assert_eq(RowSeed.indice_do_y(-60.0), 1, "y -60 (1a linha do scroll) deveria ter indice 1")
	assert_eq(RowSeed.indice_do_y(40.0), -1, "y 40 (2a linha do .tscn) deveria ter indice -1")
	assert_eq(RowSeed.indice_do_y(190.0), -4, "y 190 (5a linha do .tscn) deveria ter indice -4")


# Linha k do scroll (k >= 0) nasce em Y_TOPO - ESPACAMENTO * (k + 1) e recebe indice k + 1.
func test_linhas_do_scroll_recebem_indice_k_mais_1() -> void:
	for k in range(0, 40):
		var y := InitialRows.Y_TOPO - InitialRows.ESPACAMENTO * float(k + 1)
		assert_eq(
			RowSeed.indice_do_y(y),
			k + 1,
			"linha %s do scroll (y %s) deveria ter indice %s" % [k, y, k + 1]
		)


# As 5 linhas do .tscn (y -10, 40, 90, 140, 190) recebem indices 0, -1, -2, -3, -4.
func test_linhas_do_tscn_recebem_indices_zero_a_menos_quatro() -> void:
	var ys := [-10.0, 40.0, 90.0, 140.0, 190.0]
	var esperados := [0, -1, -2, -3, -4]
	for i in ys.size():
		assert_eq(
			RowSeed.indice_do_y(ys[i]),
			esperados[i],
			"linha de y %s deveria ter indice %s" % [ys[i], esperados[i]]
		)
