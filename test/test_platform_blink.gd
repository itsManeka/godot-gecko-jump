extends GutTest

# Duracoes exatas em binario para as fronteiras serem comparaveis sem tolerancia.
const VISIVEL := 3.0
const INVISIVEL := 1.0
const AVISO := 0.5


class _FakePlataforma extends Platform:
	var travada := false

	func esta_travada() -> bool:
		return travada


func _rng(semente: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	return rng


func _blink(fase: float = 0.0, semente: int = 1) -> PlatformBlink:
	var blink := PlatformBlink.new()
	blink.iniciar(_rng(semente), VISIVEL, INVISIVEL, AVISO)
	blink.definir_fase(fase)
	return blink


func _plataforma() -> _FakePlataforma:
	return autofree(_FakePlataforma.new())


func test_mesma_semente_mesma_fase_e_sementes_distintas_cobrem_fases_distintas() -> void:
	var fases := {}
	for semente in range(1, 41):
		var a := PlatformBlink.new()
		a.iniciar(_rng(semente), VISIVEL, INVISIVEL, AVISO)
		var b := PlatformBlink.new()
		b.iniciar(_rng(semente), VISIVEL, INVISIVEL, AVISO)
		assert_eq(a.get_fase(), b.get_fase(), "mesma semente, mesma fase (semente %d)" % semente)
		assert_between(a.get_fase(), 0.0, VISIVEL + INVISIVEL, "fase dentro do ciclo")
		fases[snappedf(a.get_fase(), 0.001)] = true
	assert_gt(fases.size(), 10, "sementes distintas cobrem fases distintas")


func test_fronteiras_exatas_do_ciclo() -> void:
	var b := _blink(0.0)
	assert_true(b.esta_visivel(), "t=0 visivel")
	assert_false(b.em_aviso(), "t=0 sem aviso")
	# visivel ate visivel-aviso (2.5): sem aviso; no 2.5 exato comeca o aviso, ainda visivel
	assert_true(b.visivel_em(2.0), "t=2.0 visivel")
	assert_false(_blink(2.0).em_aviso(), "t=2.0 sem aviso")
	assert_false(_blink(2.25).em_aviso(), "t=2.25 sem aviso")
	assert_true(_blink(2.5).em_aviso(), "t=2.5 exato entra no aviso")
	assert_true(_blink(2.5).esta_visivel(), "aviso conta como visivel")
	assert_true(_blink(2.75).em_aviso(), "t=2.75 em aviso")
	assert_true(_blink(2.75).esta_visivel(), "t=2.75 ainda visivel")
	# t=3.0 exato: invisivel, sem aviso
	assert_false(_blink(3.0).esta_visivel(), "t=3.0 exato ja invisivel")
	assert_false(_blink(3.0).em_aviso(), "invisivel nao tem aviso")
	assert_false(_blink(3.5).esta_visivel(), "t=3.5 invisivel")
	# t=4.0 = ciclo: volta a visivel
	assert_true(_blink(4.0).esta_visivel(), "t=4.0 volta a visivel")
	assert_false(_blink(4.0).em_aviso(), "t=4.0 sem aviso")
	# previsao daqui a dt a partir da fase atual
	assert_true(b.visivel_em(2.99), "daqui a 2.99 visivel")
	assert_false(b.visivel_em(3.0), "daqui a 3.0 invisivel")
	assert_false(b.visivel_em(3.99), "daqui a 3.99 invisivel")
	assert_true(b.visivel_em(4.0), "daqui a 4.0 visivel")
	assert_true(b.visivel_em(-5.0), "dt negativo = agora")


func test_visivel_na_janela_so_se_cabe_inteira() -> void:
	var b := _blink(0.0)
	assert_true(b.visivel_na_janela(0.0, 2.9), "cabe inteira")
	assert_true(b.visivel_na_janela(1.0, 2.9), "cabe inteira, inicio adiante")
	assert_false(b.visivel_na_janela(0.0, 3.0), "fim no instante do sumico")
	assert_false(b.visivel_na_janela(0.0, 3.5), "cruza o sumico, fim invisivel")
	# inicio e fim visiveis, mas a janela cruza o sumico (fim = fase 0.5 do proximo ciclo)
	assert_true(b.visivel_em(2.0), "inicio visivel")
	assert_true(b.visivel_em(4.5), "fim visivel")
	assert_false(b.visivel_na_janela(2.0, 4.5), "cruza o invisivel mesmo com as pontas visiveis")
	# inicio invisivel / cruzando a volta
	assert_false(b.visivel_na_janela(3.5, 4.5), "comeca invisivel e cruza a volta")
	assert_false(b.visivel_na_janela(3.0, 3.2), "janela inteira invisivel")
	# fase deslocada: faltam 0.5 s para sumir
	var c := _blink(2.5)
	assert_true(c.visivel_na_janela(0.0, 0.25), "cabe nos 0.5 restantes")
	assert_false(c.visivel_na_janela(0.0, 0.5), "fim = sumico")


func test_duracao_zero_negativa_ou_proporcao_zero_e_sempre_visivel() -> void:
	var casos := [[0.0, 1.0], [3.0, 0.0], [-1.0, 1.0], [3.0, -2.0], [0.0, 0.0]]
	for c in casos:
		var b := PlatformBlink.new()
		b.iniciar(_rng(3), c[0], c[1], AVISO)
		assert_true(b.esta_visivel(), "visivel %s" % [c])
		assert_true(b.visivel_em(100.0), "visivel adiante %s" % [c])
		assert_true(b.visivel_na_janela(0.0, 50.0), "janela %s" % [c])
		assert_false(b.em_aviso(), "sem aviso %s" % [c])
		b.ao_processar(_plataforma(), 10.0)
		assert_true(b.esta_visivel(), "visivel apos processar %s" % [c])
	var p0 := PlatformBlink.new()
	p0.iniciar(_rng(3), VISIVEL, INVISIVEL, AVISO, 0.0)
	assert_true(p0.visivel_na_janela(0.0, 100.0), "proporcao 0 = sempre visivel")
	assert_true(p0.visivel_em(3.5), "proporcao 0 nunca some")
	var enorme := PlatformBlink.new()
	enorme.iniciar(_rng(3), 1.0e30, 1.0e30, 1.0e30)
	assert_true(enorme.esta_visivel(), "duracao enorme satura")
	assert_true(enorme.visivel_em(1000.0), "duracao enorme segue visivel")
	enorme.ao_processar(_plataforma(), 1000.0)
	assert_true(is_finite(enorme.get_fase()), "fase finita com duracao enorme")


func test_relogio_nao_avanca_com_delta_zero_nem_travada_e_retoma_do_ponto() -> void:
	var b := _blink(2.0)
	var plataforma := _plataforma()
	b.ao_processar(plataforma, 0.0)
	assert_eq(b.get_fase(), 2.0, "delta 0 nao avanca")
	plataforma.travada = true
	b.ao_processar(plataforma, 5.0)
	assert_eq(b.get_fase(), 2.0, "travada nao avanca")
	assert_true(b.esta_visivel(), "travada continua visivel")
	plataforma.travada = false
	b.ao_processar(plataforma, 0.5)
	assert_eq(b.get_fase(), 2.5, "destravar retoma do ponto, sem reiniciar a fase")
	assert_true(b.em_aviso(), "retomou e entrou no aviso")
	b.ao_processar(plataforma, 0.5)
	assert_false(b.esta_visivel(), "avancou ate o sumico")
	b.ao_processar(plataforma, 1.0)
	assert_true(b.esta_visivel(), "volta a visivel apos o ciclo")
	assert_eq(b.get_fase(), 0.0, "fase dentro do ciclo")


func test_nao_vale_na_linha_inicial() -> void:
	assert_false(PlatformBlink.new().vale_em_linha_inicial(), "linha inicial nunca pisca")
