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
