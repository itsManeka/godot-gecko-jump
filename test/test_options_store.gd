extends GutTest

# Persistencia das opcoes (OptionsStore). Todo cenario usa TEST_PATH; nenhum escreve em OptionsStore.DEFAULT_PATH.

const TEST_PATH := "user://test_options_store.cfg"
const MISSING_DIR_PATH := "user://naoexiste_opcoes/x.cfg"


func before_each() -> void:
	_limpar()


func after_each() -> void:
	_limpar()


func _limpar() -> void:
	for p in [TEST_PATH, TEST_PATH + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


func _escrever_texto(path: String, texto: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(texto)
	f.close()


func _escrever_cfg(music: Variant, sfx: Variant) -> void:
	var cfg := ConfigFile.new()
	if music != null:
		cfg.set_value("audio", "music", music)
	if sfx != null:
		cfg.set_value("audio", "sfx", sfx)
	cfg.save(TEST_PATH)


func test_c179_grava_e_le_de_volta_music_e_sfx() -> void:
	var a := OptionsStore.new(TEST_PATH)
	a.save_music(0.5)
	a.save_sfx(0.25)
	var b := OptionsStore.new(TEST_PATH)
	assert_eq(b.load_music(), 0.5, "C179: music 0.5")
	assert_eq(b.load_sfx(), 0.25, "C179: sfx 0.25")


func test_c180_arquivo_ausente_devolve_default_sem_criar() -> void:
	var store := OptionsStore.new(TEST_PATH)
	assert_eq(store.load_music(), 1.0, "C180: music default 1.0")
	assert_eq(store.load_sfx(), 1.0, "C180: sfx default 1.0")
	assert_false(FileAccess.file_exists(TEST_PATH), "C180: a leitura nao cria arquivo")


func test_c181_corrompido_e_chave_ausente_devolvem_default() -> void:
	_escrever_texto(TEST_PATH, "@@ nao e cfg")
	var lixo := OptionsStore.new(TEST_PATH)
	assert_eq(lixo.load_music(), 1.0, "C181: lixo music 1.0")
	assert_eq(lixo.load_sfx(), 1.0, "C181: lixo sfx 1.0")
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "outra", 0.3)
	cfg.save(TEST_PATH)
	var sem_chave := OptionsStore.new(TEST_PATH)
	assert_eq(sem_chave.load_music(), 1.0, "C181: chave ausente music 1.0")
	assert_eq(sem_chave.load_sfx(), 1.0, "C181: chave ausente sfx 1.0")


func test_c182_tipo_errado_cai_no_default_so_naquele_canal() -> void:
	_escrever_cfg("alto", 0.3)
	var store := OptionsStore.new(TEST_PATH)
	assert_eq(store.load_music(), 1.0, "C182: music string vale 1.0")
	assert_eq(store.load_sfx(), 0.3, "C182: sfx valido preservado")


func test_c183_valor_negativo_devolve_default() -> void:
	_escrever_cfg(-0.1, 0.4)
	var store := OptionsStore.new(TEST_PATH)
	assert_eq(store.load_music(), 1.0, "C183: -0.1 vale 1.0")
	assert_eq(store.load_sfx(), 0.4, "C183: outro canal preservado")


func test_c184_valor_maior_que_um_devolve_default() -> void:
	_escrever_cfg(1.5, 0.4)
	var store := OptionsStore.new(TEST_PATH)
	assert_eq(store.load_music(), 1.0, "C184: 1.5 vale 1.0")
	assert_eq(store.load_sfx(), 0.4, "C184: outro canal preservado")


func test_c185_valor_nan_devolve_default() -> void:
	_escrever_cfg(NAN, 0.4)
	var store := OptionsStore.new(TEST_PATH)
	assert_eq(store.load_music(), 1.0, "C185: NaN vale 1.0")
	assert_eq(store.load_sfx(), 0.4, "C185: outro canal preservado")


func test_c186_gravar_um_canal_preserva_o_outro_e_chave_extra() -> void:
	var store := OptionsStore.new(TEST_PATH)
	store.save_music(0.5)
	store.save_sfx(0.25)
	store.save_value("tutorial", "visto", true)
	store.save_music(0.75)
	var lido := OptionsStore.new(TEST_PATH)
	assert_eq(lido.load_music(), 0.75, "C186: music atualizado")
	assert_eq(lido.load_sfx(), 0.25, "C186: gravar music preserva sfx")
	assert_eq(lido.load_value("tutorial", "visto", false), true, "C186: chave extra nao e apagada")
	store.save_sfx(0.1)
	assert_eq(OptionsStore.new(TEST_PATH).load_music(), 0.75, "C186: gravar sfx preserva music")
	assert_eq(OptionsStore.new(TEST_PATH).load_value("tutorial", "visto", false), true, "C186: extra segue apos sfx")


func test_c187_nenhum_tmp_sobra_e_rename_falho_remove_tmp_em_silencio() -> void:
	var store := OptionsStore.new(TEST_PATH)
	store.save_music(0.5)
	assert_true(FileAccess.file_exists(TEST_PATH), "C187: destino existe apos gravar")
	assert_false(FileAccess.file_exists(TEST_PATH + ".tmp"), "C187: nenhum .tmp sobra apos sucesso")
	# Destino aberto: no Windows o rename falha; o .tmp nao pode ficar (nos demais SO o rename passa e o .tmp tambem some)
	var aberto := FileAccess.open(TEST_PATH, FileAccess.READ)
	assert_not_null(aberto, "C187: fixture abriu o destino")
	store.save_sfx(0.2)
	var tmp_sobrou := FileAccess.file_exists(TEST_PATH + ".tmp")
	aberto.close()
	assert_false(tmp_sobrou, "C187: rename falho remove o .tmp")
	# Diretorio inexistente: falha silenciosa, sem arquivo nem .tmp
	var ruim := OptionsStore.new(MISSING_DIR_PATH)
	ruim.save_music(0.3)
	assert_false(FileAccess.file_exists(MISSING_DIR_PATH), "C187: destino invalido nao criado")
	assert_false(FileAccess.file_exists(MISSING_DIR_PATH + ".tmp"), "C187: .tmp do destino invalido nao existe")
	assert_eq(ruim.load_music(), 1.0, "C187: leitura segue no default")


func test_c188_volume_linear_para_db() -> void:
	assert_eq(OptionsStore.volume_linear_to_db(1.0), 0.0, "C188: 1.0 = 0 dB")
	assert_almost_eq(OptionsStore.volume_linear_to_db(0.5), -6.02, 0.01, "C188: 0.5 ~ -6.02 dB")
	assert_eq(OptionsStore.volume_linear_to_db(0.0), -80.0, "C188: 0.0 = piso -80 dB")
	assert_false(is_inf(OptionsStore.volume_linear_to_db(0.0)), "C188: piso finito, nao -INF")
