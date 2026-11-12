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


# K do ultimo estagio (teto) da curva de producao, lido do .tres
func _k_do_teto() -> int:
	var curva: DifficultyCurve = load("res://ressources/curva_dificuldade.tres")
	return curva.estagios.back().k


# Gera a sequencia como o gerador: historico descarta o excedente de K-1; a janela de verificacao usa o mesmo k
func _verifica_janelas(k: int) -> void:
	for semente in range(1, SEMENTES + 1):
		var rng := _rng(semente)
		var sequencia: Array = []
		var historico: Array = []
		for i in 40:
			var cor: int = ReachableColors.cor_plataforma_movel(COR_GECKO, historico, rng, k)
			sequencia.append(cor)
			historico.append(cor)
			while historico.size() > maxi(k - 1, 0):
				historico.pop_front()
		for inicio in range(0, sequencia.size() - k + 1):
			var janela: Array = sequencia.slice(inicio, inicio + k)
			assert_true(janela.has(COR_GECKO), "toda janela de K=%s tem a cor do gecko (seed %s)" % [k, semente])


func test_cor_movel_toda_janela_de_k_3_tem_a_cor_do_gecko() -> void:
	_verifica_janelas(3)


func test_cor_movel_toda_janela_de_k_do_teto_tem_a_cor_do_gecko() -> void:
	var k: int = _k_do_teto()
	assert_gt(k, 3, "teto da curva tem K maior que o padrao")
	_verifica_janelas(k)


func test_cor_movel_sem_k_usa_k_padrao() -> void:
	for semente in range(1, 51):
		var padrao: int = ReachableColors.cor_plataforma_movel(COR_GECKO, [OUTRA, OUTRA], _rng(semente))
		var explicito: int = ReachableColors.cor_plataforma_movel(
			COR_GECKO, [OUTRA, OUTRA], _rng(semente), DifficultyStage.K_PADRAO
		)
		assert_eq(padrao, explicito, "default de k = K_PADRAO (seed %s)" % semente)


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


# --- (c) coleta da linha de cima (T3) ---

const LARGURA := 180.0
const Y_POUSO := 200.0
const Y_CIMA := Y_POUSO - InitialRows.ESPACAMENTO


func _entrada(y: float, x: float, cor: int) -> Dictionary:
	return {"y": y, "x": x, "cor": cor}


func _azul_e_verde() -> Array:
	var esperado: Array = [Enums.COLOR.AZUL, Enums.COLOR.VERDE]
	esperado.sort()
	return esperado


func test_coleta_so_a_linha_imediatamente_acima() -> void:
	var entradas: Array = [
		_entrada(Y_POUSO, 50.0, Enums.COLOR.AMARELO),
		_entrada(Y_CIMA, 50.0, Enums.COLOR.AZUL),
		_entrada(Y_CIMA + ReachableColors.TOLERANCIA_LINHA, 60.0, Enums.COLOR.VERDE),
		_entrada(Y_POUSO + InitialRows.ESPACAMENTO, 50.0, Enums.COLOR.VERMELHO),
		_entrada(Y_CIMA - InitialRows.ESPACAMENTO, 50.0, Enums.COLOR.AMARELO),
	]
	var cores: Array = ReachableColors.coletar_cores_linha_acima(entradas, Y_POUSO, LARGURA)
	cores.sort()
	assert_true(cores == _azul_e_verde(), "so a linha de cima entra; linha do pouso, abaixo e 2 acima ficam fora")


func test_coleta_exclui_x_fora_da_faixa_e_inclui_as_bordas() -> void:
	var entradas: Array = [
		_entrada(Y_CIMA, -1.0, Enums.COLOR.VERMELHO),
		_entrada(Y_CIMA, LARGURA + 1.0, Enums.COLOR.VERMELHO),
		_entrada(Y_CIMA, 0.0, Enums.COLOR.AZUL),
		_entrada(Y_CIMA, LARGURA, Enums.COLOR.VERDE),
	]
	var cores: Array = ReachableColors.coletar_cores_linha_acima(entradas, Y_POUSO, LARGURA)
	cores.sort()
	assert_true(cores == _azul_e_verde(), "x=0 e x=largura entram; fora da faixa nao")
	var larga: Array = ReachableColors.coletar_cores_linha_acima(entradas, Y_POUSO, LARGURA + 10.0)
	assert_eq(larga.size(), 3, "a largura vem do parametro, nao de literal")


func test_entradas_ignoram_null_liberada_e_a_propria_atual() -> void:
	var viva: Platform = _plataforma(Y_CIMA, 40.0, Enums.COLOR.AZUL)
	var atual: Platform = _plataforma(Y_CIMA, 60.0, Enums.COLOR.VERDE)
	var liberada: Platform = _plataforma(Y_CIMA, 80.0, Enums.COLOR.VERMELHO)
	remove_child(liberada)
	liberada.free()
	var entradas: Array = ReachableColors.entradas_de_plataformas([null, liberada, viva, atual], atual)
	assert_eq(entradas.size(), 1, "so a plataforma viva e diferente da atual entra")
	assert_eq(entradas[0]["cor"], Enums.COLOR.AZUL, "a entrada restante e a viva")
	assert_eq(entradas[0]["y"], Y_CIMA, "y global da plataforma")


func test_pouso_sem_plataforma_atual_cai_no_fallback_valido() -> void:
	var viva: Platform = _plataforma(Y_CIMA, 40.0, Enums.COLOR.AZUL)
	for semente in range(1, 51):
		var cor: int = ReachableColors.cor_no_pouso([viva], null, LARGURA, _rng(semente))
		assert_true(Enums.COLOR.values().has(cor), "atual null -> cor valida de Enums")


func _plataforma(y: float, x: float, cor: int) -> Platform:
	var p: Platform = add_child_autofree(load("res://scenes/Platform.tscn").instantiate())
	p.global_position = Vector2(x, y)
	p.set_color(cor)
	return p
