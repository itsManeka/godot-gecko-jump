extends GutTest

# DesafioDiarioStore (T3): estado do dia em user:// (caminho injetavel, gravacao atomica tmp+rename
# como o BestScoreStore; leitura de arquivo ausente/corrompido/valores invalidos = nao jogado,
# resultado 0, nunca crash). Cenarios C751-C756. Todo cenario de arquivo usa TEST_PATH/BEST_DIR
# (user:// de teste); o caminho padrao real so entra no snapshot do before_all/after_all (intacto)
# e no isolamento do pre_run (C756).
# preload em vez do nome global: roda igual com ou sem o cache de classes do editor
# (as rodadas dirigidas da task nao passam pelo passo --import do .verify.mjs).

const DiarioStoreScript := preload("res://scripts/DesafioDiarioStore.gd")

const TEST_PATH := "user://test_desafio_diario.cfg"
const OTHER_PATH := "user://test_desafio_diario_b.cfg"
const MISSING_DIR_PATH := "user://naoexiste_diario/x.cfg"
const BEST_DIR := "user://test_desafio_diario_best"
const DIARIO_BEST_PATH := BEST_DIR + "/desafio_diario.cfg"
const DIA := 20000
const DIA_SEGUINTE := 20001
const BEST_SCORE_NOMES := ["best_score.cfg", "best_score_puro.cfg", "best_score_tempo.cfg", "best_score_zen.cfg"]

var _default_existed_before := false
var _default_bytes_before := PackedByteArray()


func before_all() -> void:
	_default_existed_before = FileAccess.file_exists(DiarioStoreScript.CAMINHO_PADRAO)
	if _default_existed_before:
		_default_bytes_before = FileAccess.get_file_as_bytes(DiarioStoreScript.CAMINHO_PADRAO)


func after_all() -> void:
	_limpar_arquivos()
	_assert_caminho_padrao_intacto("after_all")
	assert_false(FileAccess.file_exists(TEST_PATH), "nenhum TEST_PATH sobra ao fim da suite")
	assert_false(FileAccess.file_exists(TEST_PATH + ".tmp"), "nenhum .tmp de TEST_PATH sobra ao fim da suite")
	assert_false(FileAccess.file_exists(OTHER_PATH), "nenhum OTHER_PATH sobra ao fim da suite")
	assert_false(FileAccess.file_exists(DIARIO_BEST_PATH), "nenhum DIARIO_BEST_PATH sobra ao fim da suite")
	assert_false(FileAccess.file_exists(DiarioStoreScript.caminho_padrao()), "C756: arquivo isolado do pre_run nao sobra ao fim da suite")


func before_each() -> void:
	_limpar_arquivos()


func after_each() -> void:
	_limpar_arquivos()


# Cenario [mutacao] C751: gastar bloqueia o dia; a virada (d+1) libera e zera sem apagar nada.
func test_c751_gastar_bloqueia_o_dia_e_a_virada_libera_e_zera() -> void:
	var store := DiarioStoreScript.new(TEST_PATH)
	store.gastar_tentativa(DIA)
	assert_false(store.tentativa_disponivel(DIA), "C751: dia gasto fica indisponivel")
	assert_true(store.tentativa_disponivel(DIA_SEGUINTE), "C751: virada libera o dia seguinte")
	assert_eq(store.resultado_do(DIA_SEGUINTE), 0, "C751: virada zera o resultado do dia seguinte")
	store.gastar_tentativa(DIA)
	assert_false(store.tentativa_disponivel(DIA), "C751: gastar de novo no mesmo dia nao libera")
	assert_true(store.tentativa_disponivel(DIA_SEGUINTE), "C751: dia seguinte segue disponivel")


# C752: resultado gravado em d volta em nova instancia do store (persistencia por caminho injetado).
func test_c752_resultado_gravado_volta_em_nova_instancia() -> void:
	var store := DiarioStoreScript.new(TEST_PATH)
	store.gastar_tentativa(DIA)
	store.gravar_resultado(DIA, 17)
	var novo := DiarioStoreScript.new(TEST_PATH)
	assert_eq(novo.resultado_do(DIA), 17, "C752: resultado 17 persiste em nova instancia")
	assert_false(novo.tentativa_disponivel(DIA), "C752: tentativa gasta persiste em nova instancia")
	assert_eq(novo.resultado_do(DIA_SEGUINTE), 0, "C752: dia consultado diferente do salvo vale 0")


# Cenario [mutacao] C753: arquivo ausente/corrompido, resultado negativo ou dia de tipo errado
# (String/float) = disponivel e resultado 0, sem crash.
func test_c753_arquivo_invalido_vale_nao_jogado_e_resultado_zero() -> void:
	assert_true(DiarioStoreScript.new(TEST_PATH).tentativa_disponivel(DIA), "C753: arquivo ausente = disponivel")
	assert_eq(DiarioStoreScript.new(TEST_PATH).resultado_do(DIA), 0, "C753: arquivo ausente = resultado 0")

	_escrever_texto(TEST_PATH, "@@ nao e cfg")
	var lixo := DiarioStoreScript.new(TEST_PATH)
	assert_true(lixo.tentativa_disponivel(DIA), "C753: corrompido (texto lixo) = disponivel")
	assert_eq(lixo.resultado_do(DIA), 0, "C753: corrompido (texto lixo) = resultado 0")

	_escrever_registro_cfg(DIA, true, -7)
	var negativo := DiarioStoreScript.new(TEST_PATH)
	assert_true(negativo.tentativa_disponivel(DIA), "C753: resultado negativo = disponivel")
	assert_eq(negativo.resultado_do(DIA), 0, "C753: resultado negativo vale 0")

	_escrever_registro_cfg("20000", true, 5)
	var dia_string := DiarioStoreScript.new(TEST_PATH)
	assert_true(dia_string.tentativa_disponivel(DIA), "C753: dia String = disponivel")
	assert_eq(dia_string.resultado_do(DIA), 0, "C753: dia String = resultado 0")

	_escrever_registro_cfg(20000.5, true, 5)
	var dia_float := DiarioStoreScript.new(TEST_PATH)
	assert_true(dia_float.tentativa_disponivel(DIA), "C753: dia float = disponivel")
	assert_eq(dia_float.resultado_do(DIA), 0, "C753: dia float = resultado 0")


# Cenario [mutacao] C754: falha de escrita (caminho nao gravavel) nao lanca nem corrompe o estado
# em memoria — o gasto e o resultado seguem validos na instancia que gravou.
func test_c754_falha_de_escrita_nao_lanca_nem_corrompe_estado_em_memoria() -> void:
	var store := DiarioStoreScript.new(MISSING_DIR_PATH)
	store.gastar_tentativa(DIA)
	assert_false(store.tentativa_disponivel(DIA), "C754: gasto vale em memoria mesmo sem gravar")
	store.gravar_resultado(DIA, 10)
	assert_eq(store.resultado_do(DIA), 10, "C754: resultado em memoria mesmo sem gravar")
	assert_true(store.tentativa_disponivel(DIA_SEGUINTE), "C754: virada segue coerente em memoria")
	assert_false(FileAccess.file_exists(MISSING_DIR_PATH), "C754: caminho nao gravavel continua sem arquivo")
	assert_false(FileAccess.file_exists(MISSING_DIR_PATH + ".tmp"), "C754: nenhum .tmp no caminho nao gravavel")


# Cenario [mutacao] C755: best_score.cfg e best_score_<id>.cfg dos outros modos byte a byte iguais
# antes/depois de gastar e gravar no Diario (o Diario grava so no proprio arquivo).
func test_c755_gastar_e_gravar_no_diario_nao_alteram_os_best_score() -> void:
	DirAccess.make_dir_recursive_absolute(BEST_DIR)
	var caminhos: Array = []
	var bytes_antes := {}
	for indice in BEST_SCORE_NOMES.size():
		var nome: String = BEST_SCORE_NOMES[indice]
		var caminho := BEST_DIR + "/" + nome
		_escrever_bytes(caminho, PackedByteArray([indice + 1, 0xAB, 0xCD, 0xEF]))
		caminhos.append(caminho)
		bytes_antes[caminho] = FileAccess.get_file_as_bytes(caminho)

	var diario := DiarioStoreScript.new(DIARIO_BEST_PATH)
	diario.gastar_tentativa(DIA)
	diario.gravar_resultado(DIA, 21)
	assert_true(FileAccess.file_exists(DIARIO_BEST_PATH), "C755: o Diario gravou (a comparacao nao e vacua)")
	assert_eq(DiarioStoreScript.new(DIARIO_BEST_PATH).resultado_do(DIA), 21, "C755: gravacao do dia vale 21")

	for caminho in caminhos:
		assert_eq(FileAccess.get_file_as_bytes(caminho), bytes_antes[caminho], "C755: %s byte a byte igual" % caminho)


# C756: o pre_run isola o caminho padrao do Diario; nenhum teste grava o user://desafio_diario.cfg real.
func test_c756_pre_run_isola_o_caminho_padrao_do_diario() -> void:
	assert_ne(DiarioStoreScript.caminho_padrao(), DiarioStoreScript.CAMINHO_PADRAO, "C756: caminho padrao isolado pelo pre_run")
	var store := DiarioStoreScript.new()
	assert_ne(store.caminho, DiarioStoreScript.CAMINHO_PADRAO, "C756: store sem caminho cai no isolado")
	var existia_antes := FileAccess.file_exists(DiarioStoreScript.CAMINHO_PADRAO)
	store.gastar_tentativa(DIA)
	store.gravar_resultado(DIA, 3)
	assert_true(FileAccess.file_exists(store.caminho), "C756: gravou no caminho isolado")
	assert_eq(FileAccess.file_exists(DiarioStoreScript.CAMINHO_PADRAO), existia_antes, "C756: arquivo real do Diario nao nasce na suite")
	_assert_caminho_padrao_intacto("C756")


# Consulta em arquivo ausente nao cria arquivo (mesma higiene do load_best do BestScoreStore).
func test_consulta_nao_cria_arquivo() -> void:
	var store := DiarioStoreScript.new(TEST_PATH)
	store.tentativa_disponivel(DIA)
	store.resultado_do(DIA)
	assert_false(FileAccess.file_exists(TEST_PATH), "consulta em arquivo ausente nao cria arquivo")


# gravar_resultado com pontos negativos guarda 0: o resultado do dia e sempre int >= 0.
func test_gravar_resultado_negativo_guarda_zero() -> void:
	var store := DiarioStoreScript.new(TEST_PATH)
	store.gastar_tentativa(DIA)
	store.gravar_resultado(DIA, -3)
	assert_eq(store.resultado_do(DIA), 0, "pontos negativos guardam 0 em memoria")
	assert_eq(DiarioStoreScript.new(TEST_PATH).resultado_do(DIA), 0, "pontos negativos persistem como 0")


func _limpar_arquivos() -> void:
	_apagar(TEST_PATH)
	_apagar(TEST_PATH + ".tmp")
	_apagar(OTHER_PATH)
	_apagar(OTHER_PATH + ".tmp")
	_apagar(DIARIO_BEST_PATH)
	_apagar(DIARIO_BEST_PATH + ".tmp")
	for nome in BEST_SCORE_NOMES:
		_apagar(BEST_DIR + "/" + nome)
		_apagar(BEST_DIR + "/" + nome + ".tmp")
	_apagar(DiarioStoreScript.caminho_padrao())
	_apagar(DiarioStoreScript.caminho_padrao() + ".tmp")
	if DirAccess.dir_exists_absolute(BEST_DIR):
		DirAccess.remove_absolute(BEST_DIR)


func _apagar(caminho: String) -> void:
	if FileAccess.file_exists(caminho):
		DirAccess.remove_absolute(caminho)


func _escrever_texto(caminho: String, texto: String) -> void:
	var f := FileAccess.open(caminho, FileAccess.WRITE)
	f.store_string(texto)
	f.close()


func _escrever_bytes(caminho: String, bytes: PackedByteArray) -> void:
	var f := FileAccess.open(caminho, FileAccess.WRITE)
	f.store_buffer(bytes)
	f.close()


# Escreve um registro cru (sem validacao) para fixture de arquivo invalido.
func _escrever_registro_cfg(dia: Variant, gasta: Variant, resultado: Variant) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(DiarioStoreScript.SECTION, DiarioStoreScript.KEY_DIA, dia)
	cfg.set_value(DiarioStoreScript.SECTION, DiarioStoreScript.KEY_TENTATIVA, gasta)
	cfg.set_value(DiarioStoreScript.SECTION, DiarioStoreScript.KEY_RESULTADO, resultado)
	cfg.save(TEST_PATH)


func _assert_caminho_padrao_intacto(rotulo: String) -> void:
	var existe := FileAccess.file_exists(DiarioStoreScript.CAMINHO_PADRAO)
	assert_eq(existe, _default_existed_before, "%s: existencia do desafio_diario.cfg real inalterada" % rotulo)
	if existe and _default_existed_before:
		assert_eq(
			FileAccess.get_file_as_bytes(DiarioStoreScript.CAMINHO_PADRAO),
			_default_bytes_before,
			"%s: bytes do desafio_diario.cfg real inalterados" % rotulo
		)
