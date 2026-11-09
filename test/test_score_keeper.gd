extends GutTest

# Regra de pontuacao/recorde extraida de Global.gd para ScoreKeeper (sem arvore de cena).

var keeper: ScoreKeeper


func before_each() -> void:
	keeper = ScoreKeeper.new()
	Global.pontuacao = ScoreKeeper.new()


func after_each() -> void:
	Global.pontuacao = ScoreKeeper.new()


func test_recorde_sobe_com_pontuacao_maior() -> void:
	keeper.set_score(5)
	keeper.set_score(9)
	assert_eq(keeper.best, 9, "recorde sobe para 9")
	assert_eq(keeper.last, 9, "ultima pontuacao e 9")


func test_pontuacao_menor_nao_reduz_recorde() -> void:
	keeper.set_score(9)
	keeper.set_score(3)
	assert_eq(keeper.last, 3, "ultima pontuacao e 3")
	assert_eq(keeper.best, 9, "recorde continua 9")


func test_pontuacao_igual_nao_altera_recorde() -> void:
	keeper.set_score(9)
	keeper.set_score(9)
	assert_eq(keeper.best, 9, "recorde continua 9")
	assert_eq(keeper.last, 9, "ultima pontuacao continua 9")


func test_valor_inicial_e_zero() -> void:
	assert_eq(Global.get_last_score(), 0, "ultima pontuacao inicial e 0")
	assert_eq(Global.get_best_score(), 0, "recorde inicial e 0")
	var novo := ScoreKeeper.new()
	assert_eq(novo.last, 0, "ScoreKeeper novo comeca com last = 0")
	assert_eq(novo.best, 0, "ScoreKeeper novo comeca com best = 0")


func test_menos_um_grava_last_sem_alterar_recorde() -> void:
	keeper.set_score(-1)
	assert_eq(keeper.last, -1, "-1 e gravado como ultima pontuacao (comportamento do HEAD)")
	assert_eq(keeper.best, 0, "-1 nao altera o recorde")


func test_wiring_global_delega() -> void:
	Global.set_score(7)
	assert_eq(Global.get_last_score(), 7, "get_last_score devolve 7")
	assert_eq(Global.get_best_score(), 7, "get_best_score devolve 7")
