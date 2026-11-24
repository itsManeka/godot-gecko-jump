extends GutTest

# Definicao de modo (GameMode), contrato da regra (GameModeRule) e a regra do Classico (C570): valores
# literais do jogo de hoje, nao "plausiveis". O modo de teste (GameModeTeste) e Classico com recorde proprio.


# C570: cada valor e o comportamento vigente do jogo, assertado de forma literal.
func test_c570_classico_rule_segura_o_jogo_de_hoje() -> void:
	var regra := ClassicoRule.new()
	assert_true(regra.ao_cair({}), "C570: ao_cair encerra a partida")
	assert_false(regra.fim_por_regra({}), "C570: Classico nunca encerra por regra propria")
	assert_eq(regra.pontuar(7), 7, "C570: pontuar(7) devolve 7 (pontos passam direto)")
	assert_true(regra.grava_recorde(), "C570: Classico grava recorde")
	assert_true(regra.power_ups_habilitados(), "C570: Classico habilita power-ups")


# O contrato (base sem sobrescrita) segue o jogo de hoje: os modos so sobrescrevem o que mudam.
func test_game_mode_rule_defaults_seguem_o_jogo_de_hoje() -> void:
	var regra := GameModeRule.new()
	assert_true(regra.ao_cair({}), "contrato: ao_cair padrao encerra")
	assert_false(regra.fim_por_regra({}), "contrato: sem fim por regra no padrao")
	assert_eq(regra.pontuar(7), 7, "contrato: pontuar padrao devolve os brutos")
	assert_true(regra.grava_recorde(), "contrato: grava recorde no padrao")
	assert_true(regra.power_ups_habilitados(), "contrato: power-ups habilitados no padrao")


# C707 [mutacao]: defaults dos hooks novos em instancia nua (mutar um default faz este teste falhar).
func test_c707_defaults_dos_hooks_novos_em_instancia_nua() -> void:
	var regra := GameModeRule.new()
	assert_eq(regra.fator_scroll_forcado(), 1.0, "C707: scroll forcado padrao e 1.0 (curva normal)")
	assert_false(regra.reposiciona_ao_cair(), "C707: padrao nao reposiciona ao cair")
	assert_true(regra.mostra_recorde(), "C707: padrao mostra o recorde")


# C708: Classico, Puro e Tempo sem os overrides que repetiam o default mantem o comportamento de antes.
func test_c708_classico_puro_tempo_mantem_comportamento_apos_limpeza() -> void:
	var antigo_tempo := Global.tempo_inicial_s
	Global.tempo_inicial_s = 7.5
	var classico := ClassicoRule.new()
	var puro := PuroRule.new()
	var tempo := TempoRule.new()
	for par in [["Classico", classico], ["Puro", puro], ["Tempo", tempo]]:
		var regra: GameModeRule = par[1]
		assert_true(regra.ao_cair({}), "C708: %s encerra ao cair" % par[0])
		assert_eq(regra.pontuar(3), 3, "C708: %s pontua direto" % par[0])
		assert_true(regra.grava_recorde(), "C708: %s grava recorde" % par[0])
	assert_true(classico.power_ups_habilitados(), "C708: Classico habilita power-ups")
	assert_false(puro.power_ups_habilitados(), "C708: Puro desabilita power-ups")
	assert_true(tempo.power_ups_habilitados(), "C708: Tempo habilita power-ups")
	assert_false(classico.fim_por_regra({PartidaCtx.TEMPO: 999.0}), "C708: Classico sem fim por regra com o relogio alto")
	assert_false(puro.fim_por_regra({PartidaCtx.TEMPO: 999.0}), "C708: Puro sem fim por regra com o relogio alto")
	assert_false(tempo.fim_por_regra({PartidaCtx.TEMPO: 0.0}), "C708: Tempo nao termina com relogio zerado")
	assert_true(tempo.fim_por_regra({PartidaCtx.TEMPO: 7.5}), "C708: Tempo termina com relogio no limite")
	Global.tempo_inicial_s = antigo_tempo


# C709: os tres hooks novos tem o valor default nos modos antigos (nenhum reposiciona nem esconde recorde).
func test_c709_modos_antigos_herdam_os_hooks_novos_com_default() -> void:
	for par in [["Classico", ClassicoRule.new()], ["Puro", PuroRule.new()], ["Tempo", TempoRule.new()]]:
		var regra: GameModeRule = par[1]
		assert_eq(regra.fator_scroll_forcado(), 1.0, "C709: %s mantem o scroll da curva" % par[0])
		assert_false(regra.reposiciona_ao_cair(), "C709: %s nao reposiciona ao cair" % par[0])
		assert_true(regra.mostra_recorde(), "C709: %s mostra o recorde" % par[0])


# GameMode guarda os dados de exibicao e a regra do hook (sem cena: puro dado + regra).
func test_game_mode_guarda_dados_e_regra() -> void:
	var regra := GameModeRule.new()
	var modo := GameMode.new(&"x", "Rotulo", "Nome", "Descricao", regra)
	assert_eq(modo.id, &"x", "id guardado")
	assert_eq(modo.rotulo, "Rotulo", "rotulo curto guardado")
	assert_eq(modo.nome, "Nome", "nome guardado")
	assert_eq(modo.descricao, "Descricao", "descricao guardada")
	assert_eq(modo.regra, regra, "regra guardada")


# Modo de teste: id estavel `teste`, rotulo curto, regra = Classico e recorde proprio (id != classico).
func test_game_mode_teste_e_classico_com_recorde_proprio() -> void:
	var modo := GameModeTeste.criar()
	assert_eq(modo.id, &"teste", "modo de teste tem o id estavel teste")
	assert_true(modo.rotulo.length() <= 8, "rotulo curto do modo de teste tem ate 8 caracteres")
	assert_true(modo.regra is ClassicoRule, "regra do modo de teste e a do Classico")
	assert_true(modo.id != GameModes.ID_CLASSICO, "id distinto do Classico: recorde proprio")
	assert_true(modo.regra.ao_cair({}), "modo de teste encerra ao cair como o Classico")
