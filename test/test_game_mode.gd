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
