extends GutTest

# TouchMode (enum, validacao) e persistencia do modo de toque via Global/OptionsStore.
# Todo cenario usa TEMP_PATH injetado; nenhum escreve em OptionsStore.DEFAULT_PATH.

const TEMP_PATH := "user://options_test_touch_mode.cfg"

var _store_original: OptionsStore


func before_each() -> void:
	_store_original = Global.opcoes
	_limpar()


func after_each() -> void:
	Global.usar_options_store(_store_original)
	_limpar()


func _limpar() -> void:
	for p in [TEMP_PATH, TEMP_PATH + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


func _escrever_modo(valor: Variant) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(TouchMode.SECTION, TouchMode.KEY, valor)
	cfg.save(TEMP_PATH)


func test_c370_chave_ausente_devolve_padrao() -> void:
	assert_eq(TouchMode.de_valor(null), TouchMode.padrao(), "C370: null vale o padrao")
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", 0.5)
	cfg.save(TEMP_PATH)
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	assert_eq(Global.get_touch_mode(), TouchMode.padrao(), "C370: cfg sem controle/toque_modo vale o padrao")
	assert_eq(TouchMode.padrao(), TouchMode.Modo.C, "C370: padrao provisorio e C")


func test_c425_string_ou_fracionario_devolve_padrao() -> void:
	var padrao := TouchMode.padrao()
	assert_eq(TouchMode.de_valor("A"), padrao, "C425: string")
	assert_eq(TouchMode.de_valor("1"), padrao, "C425: string numerica")
	assert_eq(TouchMode.de_valor(0.5), padrao, "C425: float fracionario 0.5")
	assert_eq(TouchMode.de_valor(1.5), padrao, "C425: float fracionario 1.5")
	assert_eq(TouchMode.de_valor(true), padrao, "C425: bool")
	_escrever_modo("B")
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	assert_eq(Global.get_touch_mode(), padrao, "C425: string no cfg vale o padrao")
	_escrever_modo(0.5)
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	assert_eq(Global.get_touch_mode(), padrao, "C425: float no cfg vale o padrao")


func test_c426_negativo_ou_fora_da_faixa_devolve_padrao_e_validos_voltam_iguais() -> void:
	var padrao := TouchMode.padrao()
	assert_eq(TouchMode.de_valor(-1), padrao, "C426: negativo")
	assert_eq(TouchMode.de_valor(3), padrao, "C426: acima do ultimo modo")
	assert_eq(TouchMode.de_valor(99), padrao, "C426: muito acima")
	assert_eq(TouchMode.de_valor(NAN), padrao, "C426: NaN")
	assert_eq(TouchMode.de_valor(0), TouchMode.Modo.A, "C426: 0 = A")
	assert_eq(TouchMode.de_valor(1), TouchMode.Modo.B, "C426: 1 = B")
	assert_eq(TouchMode.de_valor(2), TouchMode.Modo.C, "C426: 2 = C")
	_escrever_modo(0)
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	assert_eq(Global.get_touch_mode(), TouchMode.Modo.A, "C426: A salvo volta como A")
	_escrever_modo(1)
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	assert_eq(Global.get_touch_mode(), TouchMode.Modo.B, "C426: B salvo volta como B")
	_escrever_modo(7)
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	assert_eq(Global.get_touch_mode(), padrao, "C426: 7 no cfg vale o padrao")


func test_c371_gravar_modo_preserva_audio_e_volume_preserva_modo() -> void:
	var seed_store := OptionsStore.new(TEMP_PATH)
	seed_store.save_music(0.5)
	seed_store.save_sfx(0.25)
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	Global.set_touch_mode(TouchMode.Modo.A, true)
	var lido := OptionsStore.new(TEMP_PATH)
	assert_eq(lido.load_music(), 0.5, "C371: modo nao apaga music")
	assert_eq(lido.load_sfx(), 0.25, "C371: modo nao apaga sfx")
	assert_eq(TouchMode.de_valor(lido.load_value(TouchMode.SECTION, TouchMode.KEY, TouchMode.SEM_VALOR)), TouchMode.Modo.A, "C371: modo gravado")
	Global.set_volume_music(0.75)
	Global.set_volume_sfx(0.1)
	var depois := OptionsStore.new(TEMP_PATH)
	assert_eq(depois.load_music(), 0.75, "C371: volume atualizado")
	assert_eq(TouchMode.de_valor(depois.load_value(TouchMode.SECTION, TouchMode.KEY, TouchMode.SEM_VALOR)), TouchMode.Modo.A, "C371: volume preserva o modo")


func test_c372_cfg_corrompido_cai_no_padrao_sem_erro() -> void:
	var f := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	f.store_string("@@ nao e cfg")
	f.close()
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	assert_eq(Global.get_touch_mode(), TouchMode.padrao(), "C372: cfg corrompido vale o padrao")
	var ausente := OptionsStore.new(TEMP_PATH + ".naoexiste")
	Global.usar_options_store(ausente)
	assert_eq(Global.get_touch_mode(), TouchMode.padrao(), "C372: cfg ausente vale o padrao")


func test_c373_set_touch_mode_so_grava_com_persistir() -> void:
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	Global.set_touch_mode(TouchMode.Modo.B, false)
	assert_eq(Global.get_touch_mode(), TouchMode.Modo.B, "C373: aplica em memoria sem persistir")
	assert_false(FileAccess.file_exists(TEMP_PATH), "C373: persistir=false nao grava o store")
	Global.set_touch_mode(TouchMode.Modo.A, true)
	assert_true(FileAccess.file_exists(TEMP_PATH), "C373: persistir=true grava o store")
	var novo := OptionsStore.new(TEMP_PATH)
	assert_eq(TouchMode.de_valor(novo.load_value(TouchMode.SECTION, TouchMode.KEY, TouchMode.SEM_VALOR)), TouchMode.Modo.A, "C373: novo store le o mesmo modo")
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	assert_eq(Global.get_touch_mode(), TouchMode.Modo.A, "C373: recarga do Global traz o modo salvo")


func test_c374_options_cfg_real_nao_muda() -> void:
	assert_ne(_store_original.path, OptionsStore.DEFAULT_PATH, "C374: store do Global na suite e temporario")
	var existia := FileAccess.file_exists(OptionsStore.DEFAULT_PATH)
	var mtime := FileAccess.get_modified_time(OptionsStore.DEFAULT_PATH) if existia else 0
	Global.usar_options_store(_store_original)
	Global.set_touch_mode(TouchMode.Modo.A, true)
	Global.set_touch_mode(TouchMode.Modo.C, true)
	assert_eq(FileAccess.file_exists(OptionsStore.DEFAULT_PATH), existia, "C374: options.cfg real nao criado/removido")
	if existia:
		assert_eq(FileAccess.get_modified_time(OptionsStore.DEFAULT_PATH), mtime, "C374: options.cfg real nao mudou")


func test_nome_devolve_rotulo_e_fora_da_faixa_cai_no_padrao() -> void:
	assert_eq(TouchMode.nome(TouchMode.Modo.A), "A", "nome A")
	assert_eq(TouchMode.nome(TouchMode.Modo.B), "B", "nome B")
	assert_eq(TouchMode.nome(TouchMode.Modo.C), "C", "nome C")
	assert_eq(TouchMode.nome(9), "C", "fora da faixa vale o nome do padrao")
