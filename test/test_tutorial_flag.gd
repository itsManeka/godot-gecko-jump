extends GutTest

# Flag "tutorial visto" (TutorialFlag). Todo cenario usa TEST_PATH; nenhum toca user://options.cfg real.

const TEST_PATH := "user://test_tutorial_flag.cfg"
const BAD_PATH := "user://naoexiste_tutorial/x.cfg"


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


func _escrever_cfg_visto(valor: Variant) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("tutorial", "visto", valor)
	cfg.save(TEST_PATH)


func test_sem_arquivo_nao_visto() -> void:
	assert_false(TutorialFlag.new(OptionsStore.new(TEST_PATH)).visto())


func test_marcar_grava_e_visto_vira_true() -> void:
	var flag := TutorialFlag.new(OptionsStore.new(TEST_PATH))
	flag.marcar()
	assert_true(flag.visto())
	var cfg := ConfigFile.new()
	assert_eq(cfg.load(TEST_PATH), OK)
	assert_eq(cfg.get_value("tutorial", "visto", null), true)


func test_valor_true_gravado_conta_como_visto() -> void:
	_escrever_cfg_visto(true)
	assert_true(TutorialFlag.new(OptionsStore.new(TEST_PATH)).visto())


func test_c189_tipo_errado_nao_conta_como_visto() -> void:
	for valor in ["sim", 1, null]:
		_escrever_cfg_visto(valor)
		assert_false(
			TutorialFlag.new(OptionsStore.new(TEST_PATH)).visto(), "valor %s nao deve contar" % str(valor)
		)


func test_c190_cfg_com_lixo_nao_visto_sem_erro() -> void:
	var f := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	f.store_string("@@ nao e cfg")
	f.close()
	assert_false(TutorialFlag.new(OptionsStore.new(TEST_PATH)).visto(), "cfg com lixo nao conta como visto")


func test_c191_marcar_preserva_volumes_gravados() -> void:
	var store := OptionsStore.new(TEST_PATH)
	store.save_music(0.25)
	store.save_sfx(0.5)
	TutorialFlag.new(store).marcar()
	var lido := OptionsStore.new(TEST_PATH)
	assert_eq(lido.load_music(), 0.25, "music preservado apos marcar")
	assert_eq(lido.load_sfx(), 0.5, "sfx preservado apos marcar")


func test_c192_escrita_falha_nao_lanca_e_espelho_vale() -> void:
	var flag := TutorialFlag.new(OptionsStore.new(BAD_PATH))
	assert_false(flag.visto())
	flag.marcar()
	assert_true(flag.visto(), "espelho vale com a escrita falhando")
	assert_false(FileAccess.file_exists(BAD_PATH))
