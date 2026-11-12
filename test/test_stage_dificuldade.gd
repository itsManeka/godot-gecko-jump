extends GutTest

# Stage cria o DifficultyState em _ready e o atualiza: pontos em add_point, tempo em _physics_process (so com partida
# iniciada). Cenarios C158 (estado reflete pontos/tempo), C159 (Stage isolada sem partida = estagio 0), C160 (Stage nova
# zera). O esperado vem de DifficultyCurve.avaliar do .tres de producao, nunca de literais. O reload do Stage e simulado
# por uma Stage nova (o change_scene_to_file real nao roda no runner do GUT); os _physics_process sao chamados a mao
# porque os testes nao aguardam frames.
const STAGE_SCENE := "res://scenes/Stage.tscn"
const CURVA := preload("res://ressources/curva_dificuldade.tres")


func before_each() -> void:
	Global.set_iniciado(false)


func after_each() -> void:
	Global.set_iniciado(false)


func _stage() -> Node:
	# autofree libera a Stage mesmo se um assert abortar o teste
	return add_child_autofree(load(STAGE_SCENE).instantiate())


func _assert_snapshot_igual(snap: DifficultySnapshot, esperado: DifficultySnapshot, msg: String) -> void:
	assert_eq(snap.get_scroll(), esperado.get_scroll(), msg + " (scroll)")
	assert_eq(snap.get_speed_moveis(), esperado.get_speed_moveis(), msg + " (speed)")
	assert_eq(snap.get_k(), esperado.get_k(), msg + " (k)")
	assert_eq(snap.get_proporcao_estaticas(), esperado.get_proporcao_estaticas(), msg + " (proporcao)")


func test_stage_isolada_sem_partida_usa_estagio_zero() -> void:
	var stage = _stage()
	assert_not_null(stage.dificuldade, "Stage cria o estado em _ready, sem partida iniciada")
	var estagio_zero: DifficultySnapshot = CURVA.avaliar(0, 0.0)
	_assert_snapshot_igual(stage.dificuldade.snapshot(), estagio_zero, "sem partida = estagio 0")
	# Tempo de menu nao conta: tick com a partida parada nao sai do estagio 0
	stage._physics_process(90.0)
	_assert_snapshot_igual(stage.dificuldade.snapshot(), estagio_zero, "menu nao acumula tempo")


func test_partida_iniciada_reflete_pontos_e_tempo_no_snapshot() -> void:
	var stage = _stage()
	stage._physics_process(90.0)
	stage._on_Play_button_down()
	assert_true(Global.is_iniciado(), "partida iniciada")
	stage._physics_process(90.0)
	# points inicia em -1: 10 pontos viram 9 (set_pontos recebe o valor de points)
	for i in 10:
		stage.add_point()
	var esperado: DifficultySnapshot = CURVA.avaliar(9, 90.0)
	_assert_snapshot_igual(stage.dificuldade.snapshot(), esperado, "pontos e tempo da partida")
	assert_ne(
		stage.dificuldade.snapshot().get_scroll(),
		CURVA.avaliar(0, 0.0).get_scroll(),
		"o snapshot saiu do estagio 0 com pontos e tempo acumulados"
	)


func test_stage_nova_apos_reload_entrega_estado_zerado() -> void:
	var antiga = _stage()
	antiga._on_Play_button_down()
	antiga._physics_process(90.0)
	for i in 10:
		antiga.add_point()
	assert_ne(
		antiga.dificuldade.snapshot().get_scroll(),
		CURVA.avaliar(0, 0.0).get_scroll(),
		"a partida antiga esta fora do estagio 0 antes do reload"
	)
	# Reload: a Stage nova nasce com Global.iniciado false (Stage._ready) e um estado proprio
	var nova = _stage()
	assert_ne(nova.dificuldade, antiga.dificuldade, "a Stage nova tem estado proprio")
	_assert_snapshot_igual(nova.dificuldade.snapshot(), CURVA.avaliar(0, 0.0), "reload entrega estagio 0")
	assert_false(Global.is_iniciado(), "reload nao herda partida iniciada")
