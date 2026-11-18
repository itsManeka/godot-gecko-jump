# DifficultyState (f458 T3): estado por partida, tempo so com Global.is_iniciado().
# Curva local de dois estagios (nao o .tres de producao) para o tempo ser observavel no scroll:
# estagio 0 scroll 20, estagio 1 (progresso 0.5) scroll 40, segundos_plato 100 -> 50 s = teto.
extends GutTest

var _iniciado_antes: bool


func before_each() -> void:
	_iniciado_antes = Global.is_iniciado()
	Global.set_iniciado(false)


func after_each() -> void:
	Global.set_iniciado(_iniciado_antes)


func _curva_teste() -> DifficultyCurve:
	var curva := DifficultyCurve.new()
	curva.pontos_plato = 1000000.0
	curva.segundos_plato = 100.0
	var e0 := DifficultyStage.new()
	e0.progresso_inicio = 0.0
	e0.scroll = 20.0
	var e1 := DifficultyStage.new()
	e1.progresso_inicio = 0.5
	e1.scroll = 40.0
	curva.estagios.append(e0)
	curva.estagios.append(e1)
	return curva


func test_nova_instancia_comeca_no_estagio_0() -> void:
	var estado := DifficultyState.new(_curva_teste())
	assert_almost_eq(estado.snapshot().get_scroll(), 20.0, 0.001, "nova instancia deve estar no estagio 0")


func test_sem_curva_injetada_usa_defaults_do_estagio_0() -> void:
	var estado := DifficultyState.new()
	var s := estado.snapshot()
	assert_almost_eq(s.get_scroll(), DifficultyStage.SCROLL_PADRAO, 0.001, "scroll default")
	assert_almost_eq(s.get_speed_moveis(), DifficultyStage.SPEED_PADRAO, 0.001, "speed default")
	assert_eq(s.get_k(), DifficultyStage.K_PADRAO, "K default")


func test_tempo_nao_acumula_com_jogo_nao_iniciado() -> void:
	# C150: Global.is_iniciado() == false (before_each): 10 s de tick nao sobem do estagio 0.
	var estado := DifficultyState.new(_curva_teste())
	for i in range(5):
		estado.tick(2.0)
	assert_almost_eq(estado.snapshot().get_scroll(), 20.0, 0.001, "tempo fora da partida nao conta")


func test_tempo_acumula_com_jogo_iniciado_e_para_ao_voltar_false() -> void:
	# C151: 25 s iniciado -> progresso 0.25 -> scroll 30; depois de false, tick nao acumula mais.
	var estado := DifficultyState.new(_curva_teste())
	Global.set_iniciado(true)
	estado.tick(25.0)
	assert_almost_eq(estado.snapshot().get_scroll(), 30.0, 0.001, "25 s iniciado devem interpolar para 30")
	Global.set_iniciado(false)
	estado.tick(1000.0)
	assert_almost_eq(estado.snapshot().get_scroll(), 30.0, 0.001, "tempo acumulado se mantem apos voltar a false")


func test_nova_instancia_apos_reload_volta_ao_estagio_0() -> void:
	# C152: a anterior chega ao teto; a nova (simula reload do Stage) volta ao estagio 0.
	var anterior := DifficultyState.new(_curva_teste())
	Global.set_iniciado(true)
	anterior.tick(100.0)
	assert_almost_eq(anterior.snapshot().get_scroll(), 40.0, 0.001, "pre-condicao: anterior no teto")
	var nova := DifficultyState.new(_curva_teste())
	assert_almost_eq(nova.snapshot().get_scroll(), 20.0, 0.001, "instancia nova zerada apos reload")


func test_pontos_negativos_geram_snapshot_do_estagio_0() -> void:
	# C153: Stage inicia em -1 pontos; snapshot identico ao de um estado sem pontos.
	var sem_pontos := DifficultyState.new(_curva_teste()).snapshot()
	var estado := DifficultyState.new(_curva_teste())
	estado.set_pontos(-1)
	var com_negativo := estado.snapshot()
	assert_almost_eq(com_negativo.get_scroll(), sem_pontos.get_scroll(), 0.001, "scroll igual ao estagio 0")
	assert_almost_eq(com_negativo.get_speed_moveis(), sem_pontos.get_speed_moveis(), 0.001, "speed igual")
	assert_eq(com_negativo.get_k(), sem_pontos.get_k(), "K igual")
	assert_almost_eq(
		com_negativo.get_proporcao_estaticas(), sem_pontos.get_proporcao_estaticas(), 0.001, "proporcao igual"
	)


func test_tick_com_delta_negativo_nao_reduz_o_tempo() -> void:
	# Caso degenerado: 50 s iniciado (teto de 100 s -> progresso 0.5 -> scroll 40); delta negativo ignorado.
	var estado := DifficultyState.new(_curva_teste())
	Global.set_iniciado(true)
	estado.tick(50.0)
	estado.tick(-1000.0)
	assert_almost_eq(estado.snapshot().get_scroll(), 40.0, 0.001, "delta negativo nao volta o tempo")


func test_snapshot_e_imutavel() -> void:
	# C154: alterar o snapshot devolvido (copia de mecanicas e leitura) nao muda o proximo snapshot().
	var estado := DifficultyState.new(_curva_teste())
	var primeiro := estado.snapshot()
	var copia := primeiro.get_mecanicas()
	copia.append(&"intruso")
	assert_eq(primeiro.get_mecanicas().size(), 0, "copia de mecanicas nao altera o snapshot")
	Global.set_iniciado(true)
	estado.tick(100.0)
	var segundo := estado.snapshot()
	assert_almost_eq(primeiro.get_scroll(), 20.0, 0.001, "snapshot antigo nao muda com o tick")
	assert_almost_eq(segundo.get_scroll(), 40.0, 0.001, "snapshot novo reflete o tempo")
	assert_eq(estado.snapshot().get_mecanicas().size(), 0, "proximo snapshot nao herda a alteracao")


func _estado_producao() -> DifficultyState:
	return DifficultyState.new(load("res://ressources/curva_dificuldade.tres") as DifficultyCurve)


func test_estagio_de_estado_novo_e_zero() -> void:
	assert_eq(_estado_producao().estagio(), 0, "estado novo no estagio 0")


func test_progresso_inicial_e_offset_no_canal_do_tempo() -> void:
	# C217: 0.34 -> estagio 0 em t=0; com partida iniciada, 2 s de tick cruzam a fronteira 0.35.
	var estado := _estado_producao()
	estado.progresso_inicial = 0.34
	assert_eq(estado.estagio(), 0, "t=0 ainda no estagio 0")
	Global.set_iniciado(true)
	estado.tick(2.0)
	assert_eq(estado.estagio(), 1, "tempo de partida soma ao offset")


func test_progresso_inicial_nao_anda_sem_partida_iniciada() -> void:
	# C218: Global.iniciado desligado (before_each): 10 s de tick nao mexem no estagio.
	var estado := _estado_producao()
	estado.progresso_inicial = 0.34
	estado.tick(10.0)
	assert_eq(estado.estagio(), 0, "sem partida o tempo nao anda")


func test_progresso_inicial_meio_e_saturacao() -> void:
	# C219: 0.5 -> estagio 1 em t=0; 7.0 satura no estagio final; -1.0 satura em 0.
	var estado := _estado_producao()
	estado.progresso_inicial = 0.5
	assert_eq(estado.estagio(), 1, "0.5 -> estagio 1")
	estado.progresso_inicial = 7.0
	assert_eq(estado.estagio(), 3, "7.0 satura no estagio final")
	estado.progresso_inicial = -1.0
	assert_eq(estado.estagio(), 0, "-1.0 satura em 0")


# f469 T1: sinal estagio_mudou. Curva local de 4 estagios (fronteiras 0, 0.25, 0.5, 0.75),
# pontos_plato e segundos_plato 100 -> 25 pontos ou 25 s = estagio 1, 50 = 2, 75 = 3.
func _curva_quatro_estagios() -> DifficultyCurve:
	var curva := DifficultyCurve.new()
	curva.pontos_plato = 100.0
	curva.segundos_plato = 100.0
	for inicio in [0.0, 0.25, 0.5, 0.75]:
		var e := DifficultyStage.new()
		e.progresso_inicio = inicio
		curva.estagios.append(e)
	return curva


func _estado_observado() -> DifficultyState:
	var estado := DifficultyState.new(_curva_quatro_estagios())
	watch_signals(estado)
	return estado


func _novo_de(estado: DifficultyState, indice: int) -> int:
	return int(get_signal_parameters(estado, "estagio_mudou", indice)[0])


func test_linha_de_base_no_primeiro_tick_fora_de_partida_nao_emite() -> void:
	# C334: progresso_inicial 0.5 (estagio 2); tick no menu fixa a base; iniciar e ticar no mesmo estagio nao emite.
	var estado := _estado_observado()
	estado.progresso_inicial = 0.5
	estado.tick(1.0)
	Global.set_iniciado(true)
	estado.tick(1.0)
	assert_eq(get_signal_emit_count(estado, "estagio_mudou"), 0, "partida que nasce no estagio 2 nao avisa")


func test_subida_0_para_1_por_tempo_emite_uma_vez() -> void:
	# C335
	var estado := _estado_observado()
	Global.set_iniciado(true)
	estado.tick(0.0)
	estado.tick(25.0)
	assert_signal_emit_count(estado, "estagio_mudou", 1, "1 emissao")
	assert_eq(_novo_de(estado, 0), 1, "novo == 1")


func test_subida_1_para_2_por_pontos_emite_uma_vez() -> void:
	# C336
	var estado := _estado_observado()
	Global.set_iniciado(true)
	estado.set_pontos(0)
	estado.set_pontos(25)
	estado.set_pontos(50)
	assert_signal_emit_count(estado, "estagio_mudou", 2, "0->1 e 1->2")
	assert_eq(_novo_de(estado, 1), 2, "novo == 2")


func test_subida_2_para_3_emite_uma_vez() -> void:
	# C337
	var estado := _estado_observado()
	Global.set_iniciado(true)
	estado.set_pontos(50)
	estado.set_pontos(75)
	assert_signal_emit_count(estado, "estagio_mudou", 1, "so a subida 2->3 apos a base no 2")
	assert_eq(_novo_de(estado, 0), 3, "novo == 3")


func test_salto_de_varios_estagios_emite_uma_vez_com_o_final() -> void:
	# C338: base no estagio 0, set_pontos(50) pula direto para o estagio 2.
	var estado := _estado_observado()
	Global.set_iniciado(true)
	estado.set_pontos(0)
	estado.set_pontos(50)
	assert_signal_emit_count(estado, "estagio_mudou", 1, "1 emissao no salto")
	assert_eq(_novo_de(estado, 0), 2, "estagio final")


func test_estagio_0_ticks_repetidos_e_queda_nao_emitem() -> void:
	# C339: 60 ticks no estagio 0 -> 0; ao cair de estagio (progresso_inicial 0.5 -> 0) -> 0 emissoes novas.
	var estado := _estado_observado()
	Global.set_iniciado(true)
	for i in range(60):
		estado.tick(0.1)
	assert_eq(get_signal_emit_count(estado, "estagio_mudou"), 0, "estagio 0 nao emite")
	estado.progresso_inicial = 0.5
	estado.tick(0.1)
	assert_eq(get_signal_emit_count(estado, "estagio_mudou"), 1, "subida por offset emite 1x")
	estado.progresso_inicial = 0.0
	estado.tick(0.1)
	estado.tick(0.1)
	assert_eq(get_signal_emit_count(estado, "estagio_mudou"), 1, "queda de estagio nao emite")


func test_tick_fora_de_partida_cruzando_limiar_nao_emite_nem_fica_pendente() -> void:
	# C340
	var estado := _estado_observado()
	estado.tick(0.0)
	estado.progresso_inicial = 0.5
	estado.tick(1.0)
	Global.set_iniciado(true)
	estado.tick(0.0)
	assert_eq(
		get_signal_emit_count(estado, "estagio_mudou"), 0, "subida fora de partida nao emite nem fica pendente"
	)


func test_nova_instancia_nasce_zerada_sem_baseline_nem_emissao() -> void:
	# C341: a anterior sobe e emite; a nova nao herda base nem emissao.
	var anterior := _estado_observado()
	Global.set_iniciado(true)
	anterior.set_pontos(0)
	anterior.set_pontos(50)
	assert_signal_emit_count(anterior, "estagio_mudou", 1, "pre-condicao: anterior emitiu")
	var nova := _estado_observado()
	assert_signal_emit_count(nova, "estagio_mudou", 0, "nova instancia sem emissao")
	nova.set_pontos(50)
	assert_signal_emit_count(nova, "estagio_mudou", 0, "base da nova nasce no estagio vigente")


func test_snapshot_com_progresso_inicial_zero_igual_ao_da_curva() -> void:
	# C216: offset 0 nao altera avaliar().
	var estado := DifficultyState.new(_curva_teste())
	Global.set_iniciado(true)
	estado.tick(25.0)
	estado.progresso_inicial = 0.0
	assert_almost_eq(estado.snapshot().get_scroll(), 30.0, 0.001, "igual ao snapshot sem offset")
