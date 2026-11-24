extends GutTest

# Recorde por modo (BestScoreStore.para_modo): Classico em BestScoreStore.DEFAULT_PATH (ou no caminho injetado),
# demais modos em best_score_<id>.cfg no mesmo diretorio. Todo cenario de arquivo usa TEST_DIR (user:// temporario);
# nenhum escreve em BestScoreStore.DEFAULT_PATH real.

const TEST_DIR := "user://test_modos_f523"
const CLASSICO_PATH := TEST_DIR + "/best_score.cfg"
const TESTE_PATH := TEST_DIR + "/best_score_teste.cfg"

var _flag_antes: bool = false


func before_each() -> void:
	_flag_antes = Global.modos_teste_habilitado
	Global.modos_teste_habilitado = true
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	_limpar_arquivos()


func after_each() -> void:
	_limpar_arquivos()
	DirAccess.remove_absolute(TEST_DIR)
	Global.modos_teste_habilitado = _flag_antes


# Apaga os arquivos de recorde de teste e os .tmp de escrita atomica.
func _limpar_arquivos() -> void:
	for caminho in [CLASSICO_PATH, TESTE_PATH]:
		_apagar(caminho)
		_apagar(caminho + ".tmp")


func _apagar(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _escrever_bytes(path: String, bytes: PackedByteArray) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_buffer(bytes)
	f.close()


# C571: best_score.cfg com N; store do Classico le N; store de `teste` le 0 (nao herda N).
func test_c571_migracao_classico_le_n_e_teste_nao_herda() -> void:
	BestScoreStore.new(CLASSICO_PATH).save_best(12)
	assert_eq(BestScoreStore.para_modo("classico", CLASSICO_PATH).load_best(), 12, "C571: Classico le 12 do arquivo antigo")
	assert_eq(BestScoreStore.para_modo("teste", CLASSICO_PATH).load_best(), 0, "C571: teste nao herda o 12 do Classico")


# C572: gravar no store de `teste` nao altera valor nem arquivo do Classico, e vice-versa.
func test_c572_gravar_em_um_modo_nao_altera_o_outro() -> void:
	var classico := BestScoreStore.para_modo("classico", CLASSICO_PATH)
	var teste := BestScoreStore.para_modo("teste", CLASSICO_PATH)
	classico.save_best(12)
	var bytes_classico_antes := FileAccess.get_file_as_bytes(CLASSICO_PATH)

	teste.save_best(5)
	assert_eq(FileAccess.get_file_as_bytes(CLASSICO_PATH), bytes_classico_antes, "C572: gravar teste nao muda o arquivo do Classico")
	assert_eq(classico.load_best(), 12, "C572: Classico continua 12 apos gravar teste")
	assert_eq(teste.load_best(), 5, "C572: teste le 5 que gravou")

	var bytes_teste_antes := FileAccess.get_file_as_bytes(TESTE_PATH)
	classico.save_best(9)
	assert_eq(FileAccess.get_file_as_bytes(TESTE_PATH), bytes_teste_antes, "C572: gravar Classico nao muda o arquivo de teste")
	assert_eq(teste.load_best(), 5, "C572: teste continua 5 apos gravar Classico")


# C573: arquivo de modo ausente ou corrompido (bytes lixo) vale 0 sem crash.
func test_c573_arquivo_de_modo_ausente_ou_corrompido_vale_zero() -> void:
	assert_eq(BestScoreStore.para_modo("teste", CLASSICO_PATH).load_best(), 0, "C573: arquivo de teste ausente vale 0")
	_escrever_bytes(TESTE_PATH, PackedByteArray([0xFF, 0xFE, 0x00, 0x01, 0x80]))
	assert_eq(BestScoreStore.para_modo("teste", CLASSICO_PATH).load_best(), 0, "C573: bytes lixo no arquivo de teste valem 0")


# C574: id em caminho (`../x`), vazio, nulo ou desconhecido nao compoem caminho arbitrario: caem no Classico.
func test_c574_id_invalido_nao_compoe_caminho_arbitrario() -> void:
	var entradas: Array = ["../x", "", null, "xyz", "teste/../../x"]
	for entrada in entradas:
		var store := BestScoreStore.para_modo(entrada, CLASSICO_PATH)
		assert_eq(store.path, CLASSICO_PATH, "C574: id %s cai no caminho do Classico" % str(entrada))
		assert_eq(store.path.find(".."), -1, "C574: caminho nao contem ..")
	var de_teste := BestScoreStore.para_modo("teste", CLASSICO_PATH)
	assert_eq(de_teste.path, TESTE_PATH, "C574: id valido `teste` compoe best_score_teste.cfg no diretorio injetado")
	assert_eq(de_teste.path.get_file(), "best_score_teste.cfg", "C574: nome do arquivo vem do id validado")


# C575: DEFAULT_PATH e o caminho do Classico, definido uma so vez.
func test_c575_default_path_e_o_store_do_classico() -> void:
	assert_eq(BestScoreStore.DEFAULT_PATH, "user://best_score.cfg", "C575: DEFAULT_PATH e user://best_score.cfg")
	assert_eq(BestScoreStore.para_modo("classico").path, BestScoreStore.DEFAULT_PATH, "C575: store do Classico usa DEFAULT_PATH")
