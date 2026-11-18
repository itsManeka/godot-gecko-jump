extends GutTest

# Modo tutorial visto (T7, `?tutorial=visto`): decisor puro com trava is_debug, wiring no Global e marca so em memoria.
# Estado global: before/after_each devolvem Global.tutorial_visto_espelho a false. Nenhum teste toca user://options.cfg real.

const TEST_PATH := "user://test_modo_tutorial_visto.cfg"


func before_each() -> void:
	Global.tutorial_visto_espelho = false
	_limpar()


func after_each() -> void:
	Global.tutorial_visto_espelho = false
	_limpar()


func _limpar() -> void:
	for p in [TEST_PATH, TEST_PATH + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


func test_c223_ausente_invalido_nao_marca() -> void:
	assert_false(ModoTutorialVisto.decide(null, true), "ausente nao marca")
	assert_false(ModoTutorialVisto.decide("", true), "vazio nao marca")
	assert_false(ModoTutorialVisto.decide("1", true), "1 nao marca")
	assert_false(ModoTutorialVisto.decide("Visto", true), "maiuscula nao marca")
	assert_false(ModoTutorialVisto.decide(" visto", true), "com espaco nao marca")
	assert_false(ModoTutorialVisto.decide(1, true), "nao-String nao marca")
	Global.aplicar_modo_tutorial(null, true)
	assert_false(Global.tutorial_visto_espelho, "sem ?tutorial o Global nao marca")
	Global.aplicar_modo_tutorial("1", true)
	assert_false(Global.tutorial_visto_espelho, "?tutorial=1 nao marca o Global")


func test_c223_visto_em_debug_marca() -> void:
	assert_true(ModoTutorialVisto.decide("visto", true), "debug com visto marca")
	Global.aplicar_modo_tutorial("visto", true)
	assert_true(Global.tutorial_visto_espelho, "?tutorial=visto em debug marca o espelho")


func test_c224_visto_em_release_nao_marca() -> void:
	assert_false(ModoTutorialVisto.decide("visto", false), "release ignora ?tutorial=visto")
	Global.aplicar_modo_tutorial("visto", false)
	assert_false(Global.tutorial_visto_espelho, "release nao liga o espelho do Global")


func test_c225_marca_so_em_memoria_cfg_sem_visto() -> void:
	var store := OptionsStore.new(TEST_PATH)
	Global.aplicar_modo_tutorial("visto", true)
	assert_true(TutorialFlag.new(store).visto(), "a marca vale na sessao pelo espelho")
	assert_false(FileAccess.file_exists(TEST_PATH), "o modo nao cria o .cfg")
	assert_false(OptionsStore.new(TEST_PATH).load_value("tutorial", "visto", false), "o store nao recebe tutorial/visto")
