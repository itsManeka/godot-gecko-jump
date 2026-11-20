extends GutTest

# Hook de regra de modo na Stage (f523 T4): derrota, pontuacao, recorde, fim por regra e power-ups pela regra.
const STAGE := "res://scenes/Stage.tscn"
const RegraDeTeste := preload("res://test/support/RegraDeTeste.gd")

var _stage: Node
var _p: Node
var _keeper_original: ScoreKeeper
var _sem_derrota_original: bool


func before_each() -> void:
	Global.tutorial_visto_espelho = true
	Global.platforms = []
	Global.iniciado = false
	_sem_derrota_original = Global.sem_derrota
	# Keeper limpo (sem store): o recorde observado e so desta rodada
	_keeper_original = Global.pontuacao
	Global.pontuacao = ScoreKeeper.new()


func after_each() -> void:
	if is_instance_valid(_p):
		_p.end = true
	Global.platforms = []
	Global.iniciado = false
	Global.sem_derrota = _sem_derrota_original
	Global.pontuacao = _keeper_original


# Stage real (sem o ScrollLevel quando `com_scroll` e falso) com a regra injetada antes do add_child.
func _spawn_stage(regra: GameModeRule = null, com_scroll: bool = false) -> void:
	_stage = load(STAGE).instantiate()
	if regra != null:
		_stage.regra = regra
	if not com_scroll:
		var scroll: Node = _stage.get_node("ScrollLevel")
		_stage.remove_child(scroll)
		scroll.free()
	add_child_autofree(_stage)
	_p = _stage.get_node("Node2D/Player")
	_p.set_physics_process(false)
	# Caindo, nao pulando: so assim o handler da linha de derrota considera a queda
	_p.jumping = false
	Global.platforms = []


func _regra(cair_encerra: bool = false, fim: bool = false, fator: int = 2, grava: bool = false, power_ups: bool = false):
	var r = RegraDeTeste.new()
	r.cair_encerra = cair_encerra
	r.fim = fim
	r.fator = fator
	r.grava = grava
	r.power_ups = power_ups
	return r


# C584
func test_regra_que_nao_encerra_cruzar_a_linha_de_derrota_nao_encerra_a_partida() -> void:
	_spawn_stage(_regra(false))
	Global.iniciado = true
	_stage._on_CheckPlayer_body_exited(_p)
	assert_false(_p.is_end(), "ao_cair false: cruzar a linha nao encerra a partida")
	assert_ne(_stage.ultimo_estado.get("state", ""), GameState.STATE_LOST, "estado publicado nao virou lost")


func test_classico_cruzar_a_linha_de_derrota_encerra_a_partida() -> void:
	_spawn_stage()
	Global.iniciado = true
	_stage._on_CheckPlayer_body_exited(_p)
	assert_true(_p.is_end(), "Classico: cruzar a linha encerra a partida")
	assert_eq(_stage.ultimo_estado.get("state", ""), GameState.STATE_LOST, "estado publicado lost")


# C585
func test_regra_soma_2x_add_point_entrega_dois_pontos_por_ponto_bruto() -> void:
	_spawn_stage(_regra(true, false, 2))
	_stage.add_point()
	assert_eq(_stage.points, 0, "o pouso inicial leva a 0 e nao conta")
	_stage.add_point()
	assert_eq(_stage.points, 2, "1 ponto bruto = exatamente 2 pontos pela regra")
	_stage.add_point()
	assert_eq(_stage.points, 4, "2 pontos brutos = 4")


func test_classico_add_point_entrega_um_ponto_por_ponto_bruto() -> void:
	_spawn_stage()
	_stage.add_point()
	_stage.add_point()
	assert_eq(_stage.points, 1, "Classico: 1 ponto bruto = 1 ponto")
	assert_eq(_stage.pointslabel.text, "1", "o placar mostra os pontos da regra")


# C586
func test_regra_sem_gravar_recorde_nao_grava_o_recorde_do_modo() -> void:
	_spawn_stage(_regra(true, false, 2, false))
	_stage.points = 5
	_stage._on_CheckPlayer_body_exited(_p)
	assert_true(_p.is_end(), "a partida encerrou")
	assert_eq(Global.get_best_score(), 0, "grava_recorde false: o recorde do modo continua 0")


func test_classico_grava_o_recorde_com_set_score_dos_pontos() -> void:
	_spawn_stage(_regra(true, false, 1, true))
	_stage.points = 5
	_stage._on_CheckPlayer_body_exited(_p)
	assert_eq(Global.get_best_score(), 5, "grava_recorde true: Global.set_score(points) grava o recorde")


func test_modo_classico_real_da_stage_grava_o_recorde_ao_perder() -> void:
	_spawn_stage()
	_stage.points = 3
	_stage._on_CheckPlayer_body_exited(_p)
	assert_eq(Global.get_best_score(), 3, "regra do Classico lida de Global: recorde gravado")


# C587
func test_power_ups_desligados_pela_regra_chegam_ao_scroll_level() -> void:
	_spawn_stage(_regra(true, false, 1, true, false), true)
	var scroll: ScrollLevel = _stage.get_node("ScrollLevel") as ScrollLevel
	assert_false(_stage.power_ups_habilitados, "a Stage leu false da regra")
	assert_false(scroll.power_ups_habilitados, "false da regra chegou ao ScrollLevel")


func test_power_ups_habilitados_pela_regra_chegam_ligados_ao_scroll_level() -> void:
	_spawn_stage(_regra(true, false, 1, true, true), true)
	var scroll: ScrollLevel = _stage.get_node("ScrollLevel") as ScrollLevel
	assert_true(scroll.power_ups_habilitados, "true da regra chega ligado ao ScrollLevel")


# C588
func test_fim_por_regra_encerra_so_com_a_partida_iniciada() -> void:
	_spawn_stage(_regra(true, true, 1, true))
	await wait_physics_frames(3)
	assert_false(_p.is_end(), "no menu (iniciado false) o fim por regra nao dispara")
	assert_ne(_stage.ultimo_estado.get("state", ""), GameState.STATE_LOST, "menu nao virou lost")
	_stage._on_Play_button_down()
	await wait_physics_frames(3)
	assert_true(_p.is_end(), "partida iniciada com fim_por_regra true encerra no _physics_process")
	assert_eq(_stage.ultimo_estado.get("state", ""), GameState.STATE_LOST, "estado publicado lost")


# C589
func test_sem_derrota_dos_smokes_segue_valendo_no_player_com_classico() -> void:
	Global.sem_derrota = true
	_spawn_stage()
	_p.color = Enums.COLOR.VERDE
	_p.change_color_random()
	assert_eq(_p.color, Enums.COR_INICIAL, "Player com sem_derrota fica na COR_INICIAL (ordem Player -> regra)")
	assert_true(_stage.regra is ClassicoRule, "a regra da Stage e a do Classico")
