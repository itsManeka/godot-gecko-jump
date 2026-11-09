extends GutTest

# Persistencia do recorde (BestScoreStore) e isolamento do GUT. Todo cenario de arquivo usa TEST_PATH;
# nenhum escreve em BestScoreStore.DEFAULT_PATH. Corrompido nunca chama push_error/push_warning.

const TEST_PATH := "user://test_best_score.cfg"
const OTHER_PATH := "user://test_best_score_b.cfg"
const MISSING_DIR_PATH := "user://naoexiste/x.cfg"
const STAGE_SCENE := "res://scenes/Stage.tscn"

var _default_existed_before: bool = false
var _default_bytes_before: PackedByteArray = PackedByteArray()
var _connections_after_hook: Array = []


func before_all() -> void:
	# Estado do arquivo real antes de qualquer cena (C39) e conexoes do Global apos o pre_run (C40)
	_default_existed_before = FileAccess.file_exists(BestScoreStore.DEFAULT_PATH)
	if _default_existed_before:
		_default_bytes_before = FileAccess.get_file_as_bytes(BestScoreStore.DEFAULT_PATH)
	_connections_after_hook = Global.pontuacao.get_signal_connection_list("best_changed")


func after_all() -> void:
	_limpar_arquivos()
	_assert_default_intacto("C39 after_all")
	assert_false(FileAccess.file_exists(TEST_PATH), "C43: user://test_best_score.cfg nao existe ao fim da suite")
	assert_false(FileAccess.file_exists(TEST_PATH + ".tmp"), "F406: nenhum .tmp de TEST_PATH sobra ao fim da suite")


func before_each() -> void:
	_limpar_arquivos()


func after_each() -> void:
	_limpar_arquivos()


# Apaga os arquivos de teste e os .tmp de escrita atomica (save_best grava <path>.tmp antes do rename).
func _limpar_arquivos() -> void:
	_apagar(TEST_PATH)
	_apagar(TEST_PATH + ".tmp")
	_apagar(OTHER_PATH)
	_apagar(OTHER_PATH + ".tmp")


func _apagar(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _escrever_texto(path: String, texto: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(texto)
	f.close()


func _assert_default_intacto(rotulo: String) -> void:
	var existe := FileAccess.file_exists(BestScoreStore.DEFAULT_PATH)
	assert_eq(existe, _default_existed_before, "%s: existencia do best_score.cfg real inalterada" % rotulo)
	if existe and _default_existed_before:
		assert_eq(
			FileAccess.get_file_as_bytes(BestScoreStore.DEFAULT_PATH),
			_default_bytes_before,
			"%s: bytes do best_score.cfg real inalterados" % rotulo
		)


func test_c30_grava_12_e_le_12_em_novo_store() -> void:
	var a := BestScoreStore.new(TEST_PATH)
	a.save_best(12)
	var b := BestScoreStore.new(TEST_PATH)
	assert_eq(b.load_best(), 12, "C30: novo store com o mesmo path le 12")


func test_c31_arquivo_ausente_devolve_zero_sem_criar() -> void:
	var store := BestScoreStore.new(TEST_PATH)
	assert_eq(store.load_best(), 0, "C31: arquivo ausente vale 0")
	assert_false(FileAccess.file_exists(TEST_PATH), "C31: a leitura nao cria arquivo")


func test_c32_corrompido_texto_lixo_devolve_zero() -> void:
	_escrever_texto(TEST_PATH, "@@ nao e cfg")
	assert_eq(BestScoreStore.new(TEST_PATH).load_best(), 0, "C32: texto lixo vale 0")


func test_c33_corrompido_sem_chave_best_devolve_zero() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("score", "outra", 5)
	cfg.save(TEST_PATH)
	assert_true(FileAccess.file_exists(TEST_PATH), "C33: fixture criada")
	assert_eq(BestScoreStore.new(TEST_PATH).load_best(), 0, "C33: cfg valido sem a chave best vale 0")


func test_c34_corrompido_best_string_devolve_zero() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("score", "best", "abc")
	cfg.save(TEST_PATH)
	assert_eq(BestScoreStore.new(TEST_PATH).load_best(), 0, "C34: best string vale 0")


func test_c35_corrompido_best_negativo_devolve_zero() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("score", "best", -4)
	cfg.save(TEST_PATH)
	assert_eq(BestScoreStore.new(TEST_PATH).load_best(), 0, "C35: best negativo vale 0")


func test_c36_recorde_so_sobe_e_grava_uma_vez() -> void:
	var store := BestScoreStore.new(TEST_PATH)
	var keeper := ScoreKeeper.new()
	keeper.best_changed.connect(store.save_best)
	watch_signals(keeper)
	keeper.set_score(9)
	keeper.set_score(3)
	keeper.set_score(9)
	assert_signal_emit_count(keeper, "best_changed", 1, "C36: so uma subida de recorde")
	assert_eq(keeper.best, 9, "C36: keeper.best = 9")
	assert_eq(store.load_best(), 9, "C36: arquivo guarda 9")


func test_c37_sem_gravacao_ao_igualar_nem_com_zero() -> void:
	var store := BestScoreStore.new(TEST_PATH)
	var keeper := ScoreKeeper.new()
	keeper.best_changed.connect(store.save_best)
	watch_signals(keeper)
	keeper.set_score(9)
	keeper.set_score(9)
	assert_signal_emit_count(keeper, "best_changed", 1, "C37: igualar o recorde nao emite de novo")

	_apagar(TEST_PATH)
	var novo := ScoreKeeper.new()
	novo.best_changed.connect(store.save_best)
	watch_signals(novo)
	novo.set_score(0)
	assert_signal_not_emitted(novo, "best_changed", "C37: set_score(0) com best 0 nao emite")
	assert_false(FileAccess.file_exists(TEST_PATH), "C37: set_score(0) nao cria arquivo")


func test_c38_recarregar_restaura_recorde_sem_emitir() -> void:
	var store := BestScoreStore.new(TEST_PATH)
	var keeper := ScoreKeeper.new()
	keeper.best_changed.connect(store.save_best)
	keeper.set_score(9)

	var recarregado := ScoreKeeper.new()
	recarregado.best_changed.connect(store.save_best)
	watch_signals(recarregado)
	recarregado.load_best(store.load_best())
	assert_eq(recarregado.best, 9, "C38: recorde restaurado = 9")
	assert_signal_not_emitted(recarregado, "best_changed", "C38: semeadura nao emite best_changed")


func test_c39_pouso_real_nao_toca_o_arquivo_real_do_dono() -> void:
	var stage: Node = add_child_autofree(load(STAGE_SCENE).instantiate())
	await wait_frames(2)
	Global.set_score(7)
	assert_eq(Global.get_best_score(), 7, "C39: pouso real registrou o recorde 7 em memoria")
	_assert_default_intacto("C39")
	assert_not_null(stage, "C39: Stage instanciada")
	# Devolve o keeper compartilhado ao estado inicial (sem conexao), para nao vazar best = 7 aos testes seguintes
	Global.pontuacao = ScoreKeeper.new()


func test_c40_hook_deixa_global_pontuacao_sem_conexao() -> void:
	assert_eq(_connections_after_hook.size(), 0, "C40: Global.pontuacao sem conexao em best_changed apos o pre_run")


func test_c41_paths_distintos_gravam_arquivos_distintos() -> void:
	var a := BestScoreStore.new(TEST_PATH)
	var b := BestScoreStore.new(OTHER_PATH)
	a.save_best(12)
	b.save_best(5)
	assert_eq(BestScoreStore.new(TEST_PATH).load_best(), 12, "C41: A = 12")
	assert_eq(BestScoreStore.new(OTHER_PATH).load_best(), 5, "C41: B = 5")
	assert_eq(BestScoreStore.new().path, BestScoreStore.DEFAULT_PATH, "C41: DEFAULT_PATH so e o default do _init")


func test_c42_falha_de_escrita_e_silenciosa() -> void:
	var store := BestScoreStore.new(MISSING_DIR_PATH)
	store.save_best(8)
	assert_eq(store.load_best(), 0, "C42: escrita em diretorio inexistente nao grava; leitura vale 0")
	assert_false(FileAccess.file_exists(MISSING_DIR_PATH), "C42: arquivo nao existe")


# C43: prova que o helper de limpeza usado por before_each/after_each remove o arquivo; a garantia de que
# nada sobra ao fim da suite inteira e o assert do after_all.
func test_c43_higiene_arquivo_de_teste_nao_sobra() -> void:
	BestScoreStore.new(TEST_PATH).save_best(3)
	assert_true(FileAccess.file_exists(TEST_PATH), "C43: fixture gravou o arquivo de teste")
	_apagar(TEST_PATH)
	assert_false(FileAccess.file_exists(TEST_PATH), "C43: arquivo de teste removido pela limpeza")


# F406 (a): gravacao pelo fluxo atomico (tmp + rename) deixa o recorde em <path> e le de volta.
func test_f406_a_grava_e_le_pelo_fluxo_atomico() -> void:
	BestScoreStore.new(TEST_PATH).save_best(21)
	assert_true(FileAccess.file_exists(TEST_PATH), "F406 a: o destino <path> existe apos gravar")
	assert_eq(BestScoreStore.new(TEST_PATH).load_best(), 21, "F406 a: grava 21 e le 21 pelo fluxo novo")


# F406 (b): gravacao bem-sucedida nao deixa <path>.tmp no disco.
func test_f406_b_nenhum_tmp_sobra_apos_gravacao() -> void:
	BestScoreStore.new(TEST_PATH).save_best(6)
	assert_false(FileAccess.file_exists(TEST_PATH + ".tmp"), "F406 b: nenhum .tmp sobra apos gravacao")


# F406 (c): .tmp orfao pre-existente (lixo) nao quebra load_best nem a gravacao seguinte, e some apos ela.
func test_f406_c_tmp_orfao_nao_quebra_leitura_nem_gravacao() -> void:
	_escrever_texto(TEST_PATH + ".tmp", "lixo orfao")
	var store := BestScoreStore.new(TEST_PATH)
	assert_eq(store.load_best(), 0, "F406 c: .tmp orfao sem <path> nao vale recorde; leitura vale 0")
	store.save_best(4)
	assert_eq(BestScoreStore.new(TEST_PATH).load_best(), 4, "F406 c: gravacao seguinte sobrescreve o lixo e grava 4")
	assert_false(FileAccess.file_exists(TEST_PATH + ".tmp"), "F406 c: o .tmp orfao some apos a gravacao seguinte")


# F406 (d): destino existente e substituido pelo valor novo (rename sobrescreve no Windows).
func test_f406_d_destino_existente_e_substituido() -> void:
	var store := BestScoreStore.new(TEST_PATH)
	store.save_best(5)
	store.save_best(12)
	assert_eq(BestScoreStore.new(TEST_PATH).load_best(), 12, "F406 d: o valor novo (12) substitui o antigo (5)")
	assert_false(FileAccess.file_exists(TEST_PATH + ".tmp"), "F406 d: nenhum .tmp sobra apos substituir")


# F406 (e): diretorio inexistente falha em silencio sem criar <path> nem <path>.tmp.
func test_f406_e_diretorio_inexistente_nao_cria_arquivo_nem_tmp() -> void:
	var store := BestScoreStore.new(MISSING_DIR_PATH)
	store.save_best(8)
	assert_false(FileAccess.file_exists(MISSING_DIR_PATH), "F406 e: <path> nao existe")
	assert_false(FileAccess.file_exists(MISSING_DIR_PATH + ".tmp"), "F406 e: <path>.tmp nao existe")
	assert_eq(store.load_best(), 0, "F406 e: leitura continua 0 em silencio")


# F406 (f): destino aberto por outro FileAccess faz o rename falhar no Windows; o .tmp nao fica no disco.
# Em SO onde o rename passa com o destino aberto, o .tmp tambem some (renomeado), entao a assercao vale nos dois.
func test_f406_f_rename_falho_nao_deixa_tmp() -> void:
	var store := BestScoreStore.new(TEST_PATH)
	store.save_best(5)
	var aberto := FileAccess.open(TEST_PATH, FileAccess.READ)
	assert_not_null(aberto, "F406 f: fixture abriu o destino para leitura")
	store.save_best(9)
	var tmp_sobrou := FileAccess.file_exists(TEST_PATH + ".tmp")
	aberto.close()
	assert_false(tmp_sobrou, "F406 f: rename falho remove o .tmp")
