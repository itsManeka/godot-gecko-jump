extends GutTest

# Testes do derivador de rng por linha (RowSeed): indice da linha pelo y local (geometria de
# InitialRows, nunca a ordem de criacao) e canais independentes layout/cor_movel com seed
# misturada por aritmetica int64 de [semente, indice, canal] (f528 T2, D9(a): sem hash(); a
# sequencia literal da semente 20000 e travada valor a valor). Sem arvore de cena: funcoes
# puras, seeds fixas.

const SEED := 4242
const INDICE := 7
const N_SORTEIOS := 12
# f528 T2 (C745-C748): semente do criterio da sequencia literal e quantos sorteios ela trava.
const SEED_LITERAL := 20000
const N_LITERAL := 6


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


# C479: indice por y local: -20 -> 0, -120 -> 1, 80 -> -1, 380 -> -4 (valores do requisito em 360x640,
# formula InitialRows.Y_TOPO/ESPACAMENTO; indice negativo valido).
func test_indice_por_y_local_valores_do_requisito() -> void:
	assert_eq(RowSeed.indice_do_y(-20.0), 0, "y -20 (topo) deveria ter indice 0")
	assert_eq(RowSeed.indice_do_y(-120.0), 1, "y -120 (1a linha do scroll) deveria ter indice 1")
	assert_eq(RowSeed.indice_do_y(80.0), -1, "y 80 (2a linha do .tscn) deveria ter indice -1")
	assert_eq(RowSeed.indice_do_y(380.0), -4, "y 380 (5a linha do .tscn) deveria ter indice -4")


# Linha k do scroll (k >= 0) nasce em Y_TOPO - ESPACAMENTO * (k + 1) e recebe indice k + 1.
func test_linhas_do_scroll_recebem_indice_k_mais_1() -> void:
	for k in range(0, 40):
		var y := InitialRows.Y_TOPO - InitialRows.ESPACAMENTO * float(k + 1)
		assert_eq(
			RowSeed.indice_do_y(y),
			k + 1,
			"linha %s do scroll (y %s) deveria ter indice %s" % [k, y, k + 1]
		)


# As 5 linhas do .tscn (y -20, 80, 180, 280, 380) recebem indices 0, -1, -2, -3, -4.
func test_linhas_do_tscn_recebem_indices_zero_a_menos_quatro() -> void:
	var ys := [-20.0, 80.0, 180.0, 280.0, 380.0]
	var esperados := [0, -1, -2, -3, -4]
	for i in ys.size():
		assert_eq(
			RowSeed.indice_do_y(ys[i]),
			esperados[i],
			"linha de y %s deveria ter indice %s" % [ys[i], esperados[i]]
		)


# C745: sequencia literal dos primeiros N randi() — valores fixos escritos no teste, nunca
# calculados por hash() nem pela propria funcao: a mistura int64 e travada valor a valor, igual
# em qualquer plataforma (D9(a)). Semente 20000 do criterio: canal layout nos indices 0 e -3
# (negativo valido) e canal cor_movel no indice 0.
func test_sequencia_literal_primeiros_randi_por_canal() -> void:
	assert_eq(
		_sequencia(RowSeed.rng_layout(SEED_LITERAL, 0), N_LITERAL),
		[2323418860, 613406681, 2132265877, 2290348420, 3339763203, 3417567397],
		"os primeiros %s randi() de rng_layout(20000, 0) divergem da sequencia travada" % N_LITERAL
	)
	assert_eq(
		_sequencia(RowSeed.rng_layout(SEED_LITERAL, -3), N_LITERAL),
		[1363711072, 3519825697, 3773012286, 1195651403, 2938333139, 4282479060],
		"os primeiros %s randi() de rng_layout(20000, -3) divergem da sequencia travada" % N_LITERAL
	)
	assert_eq(
		_sequencia(RowSeed.rng_cor_movel(SEED_LITERAL, 0), N_LITERAL),
		[1460957414, 3865415216, 1793235989, 915177896, 2936829050, 972154395],
		"os primeiros %s randi() de rng_cor_movel(20000, 0) divergem da sequencia travada" % N_LITERAL
	)


# C746: seeds consecutivas nao deslocam linhas nos dois canais — (s, i+1) != (s+1, i): com soma
# de semente e indice as duas colidem (s + i + 1); a mistura em campos distintos nao. A seed do
# rng e o campo do contrato (mesma seed, mesma sequencia), dump legivel na falha.
func test_seeds_consecutivas_nao_deslocam_linhas() -> void:
	for par in [[20000, 0], [20000, -3], [4242, 7]]:
		var s: int = par[0]
		var i: int = par[1]
		assert_ne(
			RowSeed.rng_layout(s, i + 1).seed,
			RowSeed.rng_layout(s + 1, i).seed,
			"canal layout: (s, i+1) colidiu com (s+1, i): seeds consecutivas deslocam as linhas"
		)
		assert_ne(
			RowSeed.rng_cor_movel(s, i + 1).seed,
			RowSeed.rng_cor_movel(s + 1, i).seed,
			"canal cor_movel: (s, i+1) colidiu com (s+1, i): seeds consecutivas deslocam as linhas"
		)


# C747: canais layout e cor_movel divergem para a mesma (semente, indice) — na semente do
# criterio, inclusive no indice negativo. A seed do rng e o campo do contrato (mesma seed, mesma
# sequencia), dump legivel na falha.
func test_canais_divergem_para_mesma_semente_e_indice_20000() -> void:
	for indice in [0, -3, 7]:
		assert_ne(
			RowSeed.rng_layout(SEED_LITERAL, indice).seed,
			RowSeed.rng_cor_movel(SEED_LITERAL, indice).seed,
			"canais layout e cor_movel colidem na mesma (semente, indice)"
		)


# C748: indice negativo valido: rng_layout(s, -1) deterministico entre chamadas e diferente de
# rng_layout(s, 1).
func test_indice_negativo_deterministico_e_distinto_do_positivo() -> void:
	var negativo_a := _sequencia(RowSeed.rng_layout(SEED_LITERAL, -1), N_SORTEIOS)
	var negativo_b := _sequencia(RowSeed.rng_layout(SEED_LITERAL, -1), N_SORTEIOS)
	assert_eq(
		negativo_a,
		negativo_b,
		"rng_layout(%s, -1) deveria ser deterministico entre chamadas" % SEED_LITERAL
	)
	assert_ne(
		negativo_a,
		_sequencia(RowSeed.rng_layout(SEED_LITERAL, 1), N_SORTEIOS),
		"rng_layout(%s, -1) repetiu a sequencia de rng_layout(%s, 1)" % [SEED_LITERAL, SEED_LITERAL]
	)
