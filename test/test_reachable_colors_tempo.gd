extends GutTest

# ReachableColors com dimensao de tempo: janela da cicladora, tempo de pulo, forcar_cor_cicladora, entradas com ciclo.

const PlayerFisica := preload("res://scenes/Player.gd")
const LARGURA := 180.0
const Y_REF := 200.0
const Y_LINHA := Y_REF - 50.0
const PERIODO := 3.0
# Tolerancia declarada de tempo_de_pulo contra a simulacao frame a frame: 1 frame de fisica.
const TOLERANCIA_PULO := 1.0 / 60.0 + 1e-6


class FakePlataforma:
	extends Node2D
	var color: int = Enums.COLOR.AZUL
	var ciclo: PlatformColorCycle = null

	func obter_ciclo() -> PlatformColorCycle:
		return ciclo


func _ciclo(semente: int = 7) -> PlatformColorCycle:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var c := PlatformColorCycle.new()
	c.iniciar(Enums.COLOR.AZUL, PERIODO, rng)
	return c


func _entrada(cor: int, ciclo: PlatformColorCycle = null) -> Dictionary:
	var e := {"y": Y_LINHA, "x": 60.0, "cor": cor}
	if ciclo != null:
		e["ciclo"] = ciclo
	return e


# --- C246: janela [dt_chegada, dt_chegada + espera] ---


func test_cicladora_que_muda_dentro_da_janela_nao_contribui_com_nenhuma_cor() -> void:
	var c := _ciclo()
	var seq := c.get_sequencia()
	var cores: Array = ReachableColors.coletar_cores_linha_acima([_entrada(seq[0], c)], Y_REF, LARGURA, PERIODO - 0.3, 0.6)
	assert_eq(cores.size(), 0, "troca em t=3 dentro de [2.7, 3.3]: nem %s nem %s" % [seq[0], seq[1]])


func test_cicladora_cuja_cor_cobre_a_janela_inteira_contribui_com_essa_cor() -> void:
	var c := _ciclo()
	var seq := c.get_sequencia()
	var antes: Array = ReachableColors.coletar_cores_linha_acima([_entrada(seq[0], c)], Y_REF, LARGURA, 0.0, 0.6)
	assert_eq(antes, [seq[0]], "janela [0, 0.6] antes da troca = cor atual")
	var depois: Array = ReachableColors.coletar_cores_linha_acima(
		[_entrada(seq[0], c)], Y_REF, LARGURA, PERIODO + 0.1, 0.6
	)
	assert_eq(depois, [seq[1]], "janela [3.1, 3.7] depois da troca = proxima cor")


func test_cicladora_com_espera_zero_usa_cor_no_instante_de_chegada() -> void:
	var c := _ciclo()
	var seq := c.get_sequencia()
	var cores: Array = ReachableColors.coletar_cores_linha_acima([_entrada(seq[0], c)], Y_REF, LARGURA, PERIODO + 0.5, 0.0)
	assert_eq(cores, [seq[1]], "espera 0 = cor_em(dt_chegada)")


func test_entrada_sem_ciclo_continua_contribuindo_com_a_cor_estatica_na_janela() -> void:
	var cores: Array = ReachableColors.coletar_cores_linha_acima(
		[_entrada(Enums.COLOR.VERMELHO)], Y_REF, LARGURA, PERIODO - 0.3, 0.6
	)
	assert_eq(cores, [Enums.COLOR.VERMELHO], "estatica nao depende da janela")


# --- C247: defaults = comportamento atual ---


func test_defaults_sem_ciclo_identico_ao_comportamento_atual() -> void:
	var entradas: Array = [
		_entrada(Enums.COLOR.AZUL),
		{"y": Y_LINHA, "x": 500.0, "cor": Enums.COLOR.VERDE},
		{"y": Y_LINHA + 80.0, "x": 10.0, "cor": Enums.COLOR.VERMELHO},
		_entrada(Enums.COLOR.AMARELO),
	]
	var padrao: Array = ReachableColors.coletar_cores_linha_acima(entradas, Y_REF, LARGURA)
	var explicito: Array = ReachableColors.coletar_cores_linha_acima(entradas, Y_REF, LARGURA, 0.0, 0.0)
	assert_eq(padrao, [Enums.COLOR.AZUL, Enums.COLOR.AMARELO], "x fora da largura e outra linha ficam de fora")
	assert_eq(explicito, padrao, "dt/espera explicitos 0 = default")


func test_cor_no_pouso_sem_dt_usa_cor_estatica_da_plataforma() -> void:
	var atual: Platform = add_child_autofree(load("res://scenes/Platform.tscn").instantiate())
	atual.global_position = Vector2(60.0, Y_REF)
	var acima := FakePlataforma.new()
	add_child_autofree(acima)
	acima.global_position = Vector2(60.0, Y_LINHA)
	acima.color = Enums.COLOR.VERMELHO
	var cor: int = ReachableColors.cor_no_pouso([atual, acima], atual, LARGURA)
	assert_eq(cor, Enums.COLOR.VERMELHO, "unica candidata acima = cor estatica")


# --- C248: tempo_de_pulo contra a simulacao frame a frame da fisica do Player ---


# Simulacao independente: no tick i o gecko sobe -(JUMP_POWER + GRAVITY * i)/60 px e a linha desce scroll/60 px.
func _simula_pulo(scroll: float) -> float:
	var altura := 0.0
	for tick in range(1, 601):
		altura += -(float(PlayerFisica.JUMP_POWER) + float(PlayerFisica.GRAVITY) * tick) / 60.0
		var linha_acima: float = float(InitialRows.ESPACAMENTO) - scroll * tick / 60.0
		if altura >= linha_acima:
			return tick / 60.0
	return -1.0


func test_tempo_de_pulo_bate_com_simulacao_frame_a_frame() -> void:
	for scroll in [0.0, 20.0, 45.0, 90.0, 160.0]:
		var esperado := _simula_pulo(scroll)
		assert_gt(esperado, 0.0, "simulacao alcanca a linha (scroll %s)" % scroll)
		assert_almost_eq(ReachableColors.tempo_de_pulo(scroll), esperado, TOLERANCIA_PULO, "scroll %s" % scroll)


func test_tempo_de_pulo_sem_scroll_e_o_apice_do_pulo_e_diminui_com_o_scroll() -> void:
	assert_almost_eq(ReachableColors.tempo_de_pulo(0.0), 25.0 / 60.0, TOLERANCIA_PULO, "apice = 25 ticks")
	assert_lt(ReachableColors.tempo_de_pulo(90.0), ReachableColors.tempo_de_pulo(0.0), "scroll maior chega antes")


# --- C249: forcar_cor_cicladora ---


func _sem_consecutivas_iguais(seq: Array) -> bool:
	for i in range(1, seq.size()):
		if seq[i] == seq[i - 1]:
			return false
	return true


func test_forcar_cor_cicladora_poe_a_cor_do_gecko_e_mantem_cor_diferente_da_anterior() -> void:
	var alvo := Enums.COLOR.VERMELHO
	for semente in range(1, 80):
		# sequencia valida (cor != anterior) sem a cor do gecko, deslocada pela semente
		var outras := [Enums.COLOR.AZUL, Enums.COLOR.VERDE, Enums.COLOR.AMARELO]
		var seq: Array = []
		for i in 8:
			seq.append(outras[(i + semente) % 3])
		seq = ReachableColors.forcar_cor_cicladora(seq, alvo, PERIODO, PERIODO * 3.0)
		assert_true(alvo in seq.slice(0, 3), "cor do gecko dentro do alcance (seed %s): %s" % [semente, seq])
		assert_true(_sem_consecutivas_iguais(seq), "cor != anterior (seed %s): %s" % [semente, seq])


func test_forcar_cor_cicladora_corrige_vizinho_que_ja_era_a_cor_do_gecko() -> void:
	var alvo := Enums.COLOR.VERMELHO
	# alcance de 1 periodo: forca o indice 0; o vizinho no indice 1 ja era a cor do gecko e precisa mudar
	var saida: Array = ReachableColors.forcar_cor_cicladora(
		[Enums.COLOR.AZUL, alvo, Enums.COLOR.VERDE], alvo, PERIODO, PERIODO
	)
	assert_eq(saida[0], alvo, "forcada no periodo atual")
	assert_true(_sem_consecutivas_iguais(saida), "vizinho trocado: %s" % [saida])


func test_forcar_cor_cicladora_nao_altera_sequencia_que_ja_tem_a_cor() -> void:
	var alvo := Enums.COLOR.VERDE
	var seq: Array = [Enums.COLOR.AZUL, alvo, Enums.COLOR.AMARELO, Enums.COLOR.AZUL]
	var saida: Array = ReachableColors.forcar_cor_cicladora(seq, alvo, PERIODO)
	assert_eq(saida, seq, "ja tem a cor: igual")
	assert_eq(seq, [Enums.COLOR.AZUL, alvo, Enums.COLOR.AMARELO, Enums.COLOR.AZUL], "argumento intacto")


func test_forcar_cor_cicladora_com_sequencia_vazia_devolve_vazia() -> void:
	assert_eq(ReachableColors.forcar_cor_cicladora([], Enums.COLOR.AZUL, PERIODO), [], "vazia")


# --- C250: entradas_de_plataformas ---


func test_entradas_ignora_instancia_liberada_e_inclui_ciclo_so_de_quem_tem() -> void:
	var com_ciclo := FakePlataforma.new()
	add_child_autofree(com_ciclo)
	com_ciclo.ciclo = _ciclo()
	var sem_ciclo := FakePlataforma.new()
	add_child_autofree(sem_ciclo)
	var liberada := FakePlataforma.new()
	liberada.free()
	var entradas: Array = ReachableColors.entradas_de_plataformas([com_ciclo, null, liberada, sem_ciclo])
	assert_eq(entradas.size(), 2, "null e liberada ignoradas")
	assert_true(entradas[0].has("ciclo"), "plataforma com ciclo traz o ciclo")
	assert_eq(entradas[0]["ciclo"], com_ciclo.ciclo, "e o ciclo dela")
	assert_false(entradas[1].has("ciclo"), "sem ciclo nao tem a chave")
