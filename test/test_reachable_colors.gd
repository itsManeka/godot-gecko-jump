extends GutTest

# Funcoes puras ReachableColors: (a) escolher_cor_gecko, (b) cor_plataforma_movel com janela de K.

const COR_GECKO := Enums.COLOR.AZUL
const OUTRA := Enums.COLOR.VERDE
const SEMENTES := 200


func _rng(semente: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	return rng


func _saidas(semente: int) -> Array:
	var rng := _rng(semente)
	var saidas: Array = []
	var historico: Array = []
	for i in 30:
		saidas.append(
			ReachableColors.escolher_cor_gecko([Enums.COLOR.AZUL, Enums.COLOR.VERDE, Enums.COLOR.VERMELHO], rng)
		)
		var cor: int = ReachableColors.cor_plataforma_movel(COR_GECKO, historico, rng)
		historico.append(cor)
		saidas.append(cor)
	return saidas


func test_escolher_com_uma_candidata_sempre_devolve_ela() -> void:
	for semente in range(1, SEMENTES + 1):
		var cor: int = ReachableColors.escolher_cor_gecko([Enums.COLOR.AZUL], _rng(semente))
		assert_eq(cor, Enums.COLOR.AZUL, "candidata unica AZUL (seed %s)" % semente)


func test_escolher_com_duas_candidatas_so_devolve_elas_e_as_duas_aparecem() -> void:
	var vistas := {}
	for semente in range(1, SEMENTES + 1):
		var cor: int = ReachableColors.escolher_cor_gecko([Enums.COLOR.AZUL, Enums.COLOR.VERDE], _rng(semente))
		vistas[cor] = true
	assert_eq(vistas.size(), 2, "so AZUL e VERDE aparecem ao longo das sementes")
	assert_true(vistas.has(Enums.COLOR.AZUL), "AZUL aparece")
	assert_true(vistas.has(Enums.COLOR.VERDE), "VERDE aparece")


func test_escolher_lista_vazia_cai_no_fallback_valido_e_deterministico() -> void:
	var primeira: int = ReachableColors.escolher_cor_gecko([], _rng(7))
	var segunda: int = ReachableColors.escolher_cor_gecko([], _rng(7))
	assert_true(Enums.COLOR.values().has(primeira), "cor valida de Enums")
	assert_eq(segunda, primeira, "mesma seed, mesma cor no fallback")


func test_cor_movel_toda_janela_de_k_tem_a_cor_do_gecko() -> void:
	var k: int = ReachableColors.K
	for semente in range(1, SEMENTES + 1):
		var rng := _rng(semente)
		var sequencia: Array = []
		for i in 40:
			sequencia.append(ReachableColors.cor_plataforma_movel(COR_GECKO, sequencia, rng))
		for inicio in range(0, sequencia.size() - k + 1):
			var janela: Array = sequencia.slice(inicio, inicio + k)
			assert_true(janela.has(COR_GECKO), "toda janela de K tem a cor do gecko")


func test_cor_movel_k_menor_ou_igual_a_1_sempre_forca() -> void:
	for k in [0, 1, -2]:
		for semente in range(1, 51):
			var cor: int = ReachableColors.cor_plataforma_movel(COR_GECKO, [OUTRA, OUTRA], _rng(semente), k)
			assert_true(cor == COR_GECKO, "K<=1 sempre forca")


func test_cor_movel_nao_forca_quando_janela_ja_tem_a_cor() -> void:
	var houve_outra := false
	for semente in range(1, SEMENTES + 1):
		var cor: int = ReachableColors.cor_plataforma_movel(COR_GECKO, [OUTRA, COR_GECKO], _rng(semente))
		if cor != COR_GECKO:
			houve_outra = true
	assert_true(houve_outra, "com a cor do gecko na janela, aparece cor diferente em alguma seed")


func test_cor_movel_historico_curto_conta_como_sem_cor_e_forca() -> void:
	for semente in range(1, SEMENTES + 1):
		var vazio: int = ReachableColors.cor_plataforma_movel(COR_GECKO, [], _rng(semente))
		var curto: int = ReachableColors.cor_plataforma_movel(COR_GECKO, [OUTRA], _rng(semente))
		assert_true(vazio == COR_GECKO, "historico vazio forca")
		assert_true(curto == COR_GECKO, "historico menor que K-1 forca")


func test_mesma_seed_mesma_saida_em_a_e_b() -> void:
	assert_eq(_saidas(11), _saidas(11), "mesma seed, mesma sequencia de (a) e (b)")
	assert_ne(_saidas(11), _saidas(12), "seed diferente muda a sequencia")


func test_sem_rng_usa_sorteio_global_sem_erro() -> void:
	var cor_a: int = ReachableColors.escolher_cor_gecko([Enums.COLOR.AZUL])
	var cor_b: int = ReachableColors.cor_plataforma_movel(COR_GECKO, [OUTRA, OUTRA])
	var sorteada: int = ReachableColors.escolher_cor_gecko([])
	assert_eq(cor_a, Enums.COLOR.AZUL, "candidata unica sem rng")
	assert_eq(cor_b, COR_GECKO, "janela sem a cor forca sem rng")
	assert_true(Enums.COLOR.values().has(sorteada), "fallback sem rng devolve cor valida")
