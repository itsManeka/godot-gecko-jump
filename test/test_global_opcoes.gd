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


# T4 (f495): sensibilidade do modo A. O store e sempre o temporario (gut_pre_run.gd / before_each), nunca o real.
const PADRAO: float = 1.0


func test_c463_store_sem_a_chave_toque_sensibilidade_cai_no_padrao_1x() -> void:
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))  # arquivo removido no before_each: chave ausente
	assert_eq(Global.get_touch_sensibilidade(), PADRAO, "chave ausente no store = 1,0x (padrao)")


func test_c464_store_com_tipo_errado_toque_sensibilidade_cai_no_padrao() -> void:
	var store := OptionsStore.new(TEMP_PATH)
	store.save_value(TouchTuning.SENSIBILIDADE_SECTION, TouchTuning.SENSIBILIDADE_KEY, "alta")
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	assert_eq(Global.get_touch_sensibilidade(), PADRAO, "String salvo no store = padrao")
	store.save_value(TouchTuning.SENSIBILIDADE_SECTION, TouchTuning.SENSIBILIDADE_KEY, true)
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	assert_eq(Global.get_touch_sensibilidade(), PADRAO, "bool salvo no store = padrao")


func test_c465_nan_recebido_pelo_setter_cai_no_padrao() -> void:
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	Global.set_touch_sensibilidade(NAN, false)
	assert_eq(Global.get_touch_sensibilidade(), PADRAO, "NaN no setter = padrao")


func test_c466_store_com_valor_fora_da_faixa_cai_no_padrao_e_valido_volta() -> void:
	var store := OptionsStore.new(TEMP_PATH)
	store.save_value(TouchTuning.SENSIBILIDADE_SECTION, TouchTuning.SENSIBILIDADE_KEY, 3.0)
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	assert_eq(Global.get_touch_sensibilidade(), PADRAO, "3,0 (acima da faixa) = padrao")
	store.save_value(TouchTuning.SENSIBILIDADE_SECTION, TouchTuning.SENSIBILIDADE_KEY, 0.1)
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	assert_eq(Global.get_touch_sensibilidade(), PADRAO, "0,1 (abaixo da faixa) = padrao")
	store.save_value(TouchTuning.SENSIBILIDADE_SECTION, TouchTuning.SENSIBILIDADE_KEY, 0.5)
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	assert_eq(Global.get_touch_sensibilidade(), 0.5, "0,5 (minimo valido) volta do store")


func test_c470_set_touch_sensibilidade_emite_sinal_e_persiste_no_store_temporario() -> void:
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	var recebidos: Array = []
	var handler := func(v: float) -> void: recebidos.append(v)
	Global.touch_sensibilidade_changed.connect(handler)
	Global.set_touch_sensibilidade(2.0)
	Global.touch_sensibilidade_changed.disconnect(handler)
	assert_eq(recebidos, [2.0], "sinal de troca emitido com o valor validado")
	assert_eq(
		OptionsStore.new(TEMP_PATH).load_value(
			TouchTuning.SENSIBILIDADE_SECTION, TouchTuning.SENSIBILIDADE_KEY, TouchTuning.SENSIBILIDADE_SEM_VALOR
		),
		2.0,
		"2,0 gravado no store temporario (persistencia)"
	)


func test_c471_sensibilidade_nunca_grava_no_options_cfg_real() -> void:
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	assert_ne(Global.opcoes.path, OptionsStore.DEFAULT_PATH, "store da suite aponta para caminho temporario")
	var existia := FileAccess.file_exists(OptionsStore.DEFAULT_PATH)
	var mtime := FileAccess.get_modified_time(OptionsStore.DEFAULT_PATH) if existia else 0
	Global.set_touch_sensibilidade(2.0)
	Global.set_touch_sensibilidade(1.0)
	assert_eq(
		FileAccess.file_exists(OptionsStore.DEFAULT_PATH), existia, "options.cfg real nao pode ser criado/removido"
	)
	if existia:
		assert_eq(FileAccess.get_modified_time(OptionsStore.DEFAULT_PATH), mtime, "options.cfg real nao pode mudar")
