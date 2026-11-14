extends GutTest

const PERIODO := 3.0
const EPS := 0.01


class _FakePlataforma extends Platform:
	var trocas: Array[int] = []
	var travada := false

	func esta_travada() -> bool:
		return travada

	func trocar_cor(nova: int) -> void:
		trocas.append(nova)


func _rng(semente: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	return rng


func _ciclo(semente: int = 7, cor_inicial: int = Enums.COLOR.AMARELO) -> PlatformColorCycle:
	var ciclo := PlatformColorCycle.new()
	ciclo.iniciar(cor_inicial, PERIODO, _rng(semente))
	return ciclo


func _plataforma() -> _FakePlataforma:
	return autofree(_FakePlataforma.new())


func test_sequencia_nunca_tem_cor_consecutiva_igual_e_e_reprodutivel() -> void:
	for semente in [1, 2, 3, 42, 999, 12345]:
		var a := _ciclo(semente).get_sequencia()
		var b := _ciclo(semente).get_sequencia()
		assert_eq(a.size(), PlatformColorCycle.CORES_NA_SEQUENCIA, "tamanho da sequencia")
		assert_eq(a[0], Enums.COLOR.AMARELO, "a sequencia comeca na cor inicial")
		assert_eq(a, b, "mesma semente, mesma sequencia (semente %d)" % semente)
		for i in range(1, a.size()):
			assert_ne(a[i], a[i - 1], "cor %d repete a anterior (semente %d)" % [i, semente])


func test_cor_em_respeita_a_fronteira_do_periodo() -> void:
	var ciclo := _ciclo()
	var seq := ciclo.get_sequencia()
	assert_eq(ciclo.cor_em(0.0), seq[0], "cor_em(0) = cor atual")
	assert_eq(ciclo.cor_em(PERIODO - EPS), seq[0], "logo antes do periodo ainda e a atual")
	assert_eq(ciclo.cor_em(PERIODO + EPS), seq[1], "logo depois do periodo e a proxima")
	assert_eq(ciclo.cor_em(PERIODO), seq[1], "no periodo exato ja e a proxima")
	assert_eq(ciclo.cor_em(2.0 * PERIODO + EPS), seq[2], "dois periodos adiante")
	assert_eq(ciclo.proxima_cor(), seq[1], "proxima_cor e a segunda da sequencia")


func test_travada_nao_avanca_nem_troca_e_destravada_retoma_de_onde_parou() -> void:
	var ciclo := _ciclo()
	var seq := ciclo.get_sequencia()
	var plataforma := _plataforma()
	ciclo.ao_processar(plataforma, 2.0)
	plataforma.travada = true
	ciclo.ao_processar(plataforma, 5.0)
	assert_eq(plataforma.trocas.size(), 0, "travada nao chama trocar_cor")
	assert_eq(ciclo.cor_em(0.0), seq[0], "travada, a cor atual nao muda")
	assert_eq(ciclo.cor_em(0.9), seq[0], "o relogio parou em 2.0 s: 0.9 s ainda e a atual")
	assert_eq(ciclo.cor_em(1.1), seq[1], "o relogio parou em 2.0 s: 1.1 s cruza o periodo")
	plataforma.travada = false
	ciclo.ao_processar(plataforma, 0.9)
	assert_eq(plataforma.trocas.size(), 0, "destravada retoma de 2.0 s (nao reinicia): 2.9 s ainda nao troca")
	ciclo.ao_processar(plataforma, 0.2)
	assert_eq(plataforma.trocas.size(), 1, "completou o periodo: uma troca")
	assert_eq(plataforma.trocas[0], seq[1], "troca para a proxima cor")


func test_em_aviso_so_nos_ultimos_06_segundos() -> void:
	var ciclo := _ciclo()
	var plataforma := _plataforma()
	ciclo.ao_processar(plataforma, PERIODO - 0.7)
	assert_false(ciclo.em_aviso(), "faltando 0.7 s nao avisa")
	ciclo.ao_processar(plataforma, 0.2)
	assert_true(ciclo.em_aviso(), "faltando 0.5 s avisa")
	ciclo.ao_processar(plataforma, 0.5)
	assert_eq(plataforma.trocas.size(), 1, "a troca aconteceu")
	assert_false(ciclo.em_aviso(), "logo apos a troca o aviso apaga")


func test_resolver_nome_novo_e_nao_vale_em_linha_inicial() -> void:
	var mecanicas: Array[StringName] = [PlatformModifiers.PLATAFORMAS_QUE_MUDAM_DE_COR]
	var snapshot := DifficultySnapshot.new(
		DifficultyStage.SCROLL_PADRAO,
		DifficultyStage.SPEED_PADRAO,
		DifficultyStage.K_PADRAO,
		DifficultyStage.PROPORCAO_PADRAO,
		mecanicas
	)
	var resultado := PlatformModifiers.resolver(snapshot)
	assert_eq(resultado.size(), 1, "o nome novo esta registrado")
	assert_true(resultado[0] is PlatformColorCycle, "resolve para PlatformColorCycle")
	assert_false(resultado[0].vale_em_linha_inicial(), "nao vale na linha inicial")


func test_depois_da_ultima_cor_o_ciclo_mantem_a_ultima() -> void:
	var ciclo := _ciclo()
	var seq := ciclo.get_sequencia()
	var ultima: int = seq[seq.size() - 1]
	var plataforma := _plataforma()
	var passos := (PlatformColorCycle.CORES_NA_SEQUENCIA + 3) * 3
	for i in passos:
		ciclo.ao_processar(plataforma, PERIODO)
	assert_eq(plataforma.trocas.size(), PlatformColorCycle.CORES_NA_SEQUENCIA - 1, "uma troca por cor depois da 1a")
	assert_eq(ciclo.cor_atual(), ultima, "mantem a ultima cor")
	assert_eq(ciclo.proxima_cor(), ultima, "nao ha proxima alem da ultima")
	assert_eq(ciclo.cor_em(1000.0), ultima, "cor_em muito adiante nao estoura o indice")
	assert_false(ciclo.em_aviso(), "sem troca restante nao avisa")
