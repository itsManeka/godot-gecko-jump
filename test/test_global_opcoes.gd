extends GutTest

const TEMP_PATH := "user://options_test_global.cfg"

var _store_original: OptionsStore


func before_each() -> void:
	_store_original = Global.opcoes
	DirAccess.remove_absolute(TEMP_PATH)


func after_each() -> void:
	Global.usar_options_store(_store_original)
	DirAccess.remove_absolute(TEMP_PATH)


func _db(bus: String) -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus))


func _mudo(bus: String) -> bool:
	return AudioServer.is_bus_mute(AudioServer.get_bus_index(bus))


func test_c189_store_injetado_aplica_music_em_db_e_sfx_mudo() -> void:
	var store := OptionsStore.new(TEMP_PATH)
	store.save_music(0.5)
	store.save_sfx(0.0)
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	assert_almost_eq(_db("Music"), -6.02, 0.01, "Music 0.5 deve valer ~ -6.02 dB")
	assert_true(_mudo("SFX"), "SFX 0 deve deixar o bus mudo")
	assert_false(_mudo("Music"), "Music 0.5 nao fica mudo")


func test_c190_setter_muda_bus_na_hora_desmuta_e_persiste() -> void:
	var store := OptionsStore.new(TEMP_PATH)
	store.save_sfx(0.0)
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	assert_true(_mudo("SFX"), "pre-condicao: SFX mudo")
	Global.set_volume_sfx(0.5)
	assert_almost_eq(_db("SFX"), -6.02, 0.01, "setter aplica no bus imediatamente")
	assert_false(_mudo("SFX"), "SFX deixa de ficar mudo ao sair de 0")
	assert_eq(OptionsStore.new(TEMP_PATH).load_sfx(), 0.5, "novo store no mesmo caminho le 0.5")


func test_c191_getters_devolvem_ultimo_valor_aplicado() -> void:
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	Global.set_volume_music(0.25)
	Global.set_volume_sfx(0.75)
	assert_eq(Global.get_volume_music(), 0.25, "getter music")
	assert_eq(Global.get_volume_sfx(), 0.75, "getter sfx")
	Global.set_volume_music(0.0)
	assert_eq(Global.get_volume_music(), 0.0, "getter music apos mudar")


func test_c192_pre_run_isola_store_do_global_do_caminho_real() -> void:
	assert_ne(
		_store_original.path,
		OptionsStore.DEFAULT_PATH,
		"store do Global na suite deve apontar para caminho temporario"
	)
	var existia := FileAccess.file_exists(OptionsStore.DEFAULT_PATH)
	var mtime := FileAccess.get_modified_time(OptionsStore.DEFAULT_PATH) if existia else 0
	Global.usar_options_store(_store_original)
	Global.set_volume_music(0.3)
	Global.set_volume_music(1.0)
	assert_eq(
		FileAccess.file_exists(OptionsStore.DEFAULT_PATH), existia, "options.cfg real nao pode ser criado/removido"
	)
	if existia:
		assert_eq(FileAccess.get_modified_time(OptionsStore.DEFAULT_PATH), mtime, "options.cfg real nao pode mudar")
