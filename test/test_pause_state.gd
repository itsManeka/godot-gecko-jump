extends GutTest

class FakeTree:
	extends RefCounted
	var paused: bool = false

var _tree: FakeTree
var _started: bool
var _end: bool
var _estado: PauseState
var _iniciado_antes: bool
var _pontuacao_antes: ScoreKeeper


func before_each() -> void:
	_tree = FakeTree.new()
	_started = true
	_end = false
	_estado = PauseState.new(_tree, func() -> bool: return PauseState.partida_ativa(_started, _end))
	_iniciado_antes = Global.iniciado
	_pontuacao_antes = Global.pontuacao
	Global.pontuacao = ScoreKeeper.new()


func after_each() -> void:
	Global.iniciado = _iniciado_antes
	Global.pontuacao = _pontuacao_antes
	get_tree().paused = false


func test_partida_ativa_so_com_started_e_sem_end() -> void:
	assert_true(PauseState.partida_ativa(true, false))
	assert_false(PauseState.partida_ativa(false, false))
	assert_false(PauseState.partida_ativa(true, true))
	assert_false(PauseState.partida_ativa(false, true))


func test_pausar_em_partida_ativa_pausa_e_retomar_despausa() -> void:
	assert_true(_estado.pausar())
	assert_true(_tree.paused)
	_estado.retomar()
	assert_false(_tree.paused)


func test_pausar_antes_do_inicio_e_ignorado() -> void:
	_started = false
	assert_false(_estado.pausar(), "pausar antes do inicio deve ser ignorado")
	assert_false(_tree.paused, "tree.paused segue false antes do inicio")
	_estado.alternar()
	assert_false(_tree.paused, "alternar antes do inicio nao pausa")


func test_pausar_com_derrota_e_ignorado() -> void:
	_end = true
	assert_false(_estado.pausar(), "pausar com derrota deve ser ignorado")
	assert_false(_tree.paused, "tree.paused segue false com derrota")
	_estado.alternar()
	assert_false(_tree.paused, "alternar com derrota nao pausa")


func test_pausar_duas_vezes_e_retomar_sem_pausa_sao_idempotentes() -> void:
	_estado.retomar()
	assert_false(_tree.paused, "retomar sem pausa e no-op")
	_estado.pausar()
	_estado.pausar()
	assert_true(_tree.paused)
	_estado.retomar()
	_estado.retomar()
	assert_false(_tree.paused)


func test_pausar_e_retomar_nao_alteram_iniciado_nem_points() -> void:
	Global.iniciado = true
	Global.set_score(7)
	_estado.pausar()
	_estado.pausar()
	assert_true(Global.iniciado)
	assert_eq(Global.get_last_score(), 7)
	_estado.retomar()
	_estado.retomar()
	assert_true(Global.iniciado)
	assert_eq(Global.get_last_score(), 7)


func test_alternar_pausa_e_retoma() -> void:
	_estado.alternar()
	assert_true(_tree.paused)
	_estado.alternar()
	assert_false(_tree.paused)


func test_retomar_funciona_mesmo_se_partida_acabou_pausado() -> void:
	_estado.pausar()
	_end = true
	_estado.retomar()
	assert_false(_tree.paused)
