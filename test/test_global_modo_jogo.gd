extends GutTest

# Selecao do modo de jogo e keepers por modo em Global (persistencia no OptionsStore, recorde por modo, isolamento).

const TMP_OPCOES := "user://options_modo_jogo_test.cfg"
const TMP_RECORDE_DIR := "user://modo_jogo_test_recordes"
const TMP_RECORDE := TMP_RECORDE_DIR + "/best_score.cfg"

var _opcoes_original: OptionsStore
var _flag_original: bool
var _iniciado_original: bool
var _pontuacao_original: ScoreKeeper
var _caminho_recorde_original: String


func before_each() -> void:
	_opcoes_original = Global.opcoes
	_flag_original = Global.modos_teste_habilitado
	_iniciado_original = Global.iniciado
	_pontuacao_original = Global.pontuacao
	_caminho_recorde_original = Global.caminho_recorde_classico
	Global.set_iniciado(false)
	DirAccess.remove_absolute(TMP_OPCOES)


func after_each() -> void:
	Global.set_iniciado(_iniciado_original)
	Global.modos_teste_habilitado = _flag_original
	Global.usar_options_store(_opcoes_original)
	Global.caminho_recorde_classico = _caminho_recorde_original
	DirAccess.remove_absolute(TMP_RECORDE)
	DirAccess.remove_absolute(TMP_RECORDE_DIR)
	Global.isolar_recordes()
	Global.pontuacao = _pontuacao_original
	DirAccess.remove_absolute(TMP_OPCOES)


func _grava_modo_bruto(valor: Variant) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(Global.MODO_SECTION, Global.MODO_KEY, valor)
	cfg.save(TMP_OPCOES)


func test_modo_salvo_ausente_vira_classico() -> void:
	Global.modos_teste_habilitado = true
	Global.usar_options_store(OptionsStore.new(TMP_OPCOES))
	assert_eq(Global.modo_jogo, GameModes.ID_CLASSICO, "C576: sem modo salvo, Classico")


func test_modo_salvo_invalido_ou_desconhecido_vira_classico() -> void:
	Global.modos_teste_habilitado = true
	for valor: Variant in [42, "", "inexistente", "../x", 3.5]:
		_grava_modo_bruto(valor)
		Global.usar_options_store(OptionsStore.new(TMP_OPCOES))
		assert_eq(Global.modo_jogo, GameModes.ID_CLASSICO, "C576: valor salvo %s cai no Classico" % str(valor))


func test_set_modo_jogo_persiste_e_novo_store_le() -> void:
	Global.modos_teste_habilitado = true
	Global.usar_options_store(OptionsStore.new(TMP_OPCOES))
	Global.set_modo_jogo("teste")
	assert_eq(Global.modo_jogo, &"teste", "C577: modo aplicado")
	Global.usar_options_store(OptionsStore.new(TMP_OPCOES))
	assert_eq(Global.modo_jogo, &"teste", "C577: novo OptionsStore no mesmo caminho devolve teste")


func test_modo_teste_salvo_com_flag_desligada_vira_classico() -> void:
	Global.modos_teste_habilitado = true
	Global.usar_options_store(OptionsStore.new(TMP_OPCOES))
	Global.set_modo_jogo("teste")
	Global.modos_teste_habilitado = false
	Global.usar_options_store(OptionsStore.new(TMP_OPCOES))
	assert_eq(Global.modo_jogo, GameModes.ID_CLASSICO, "C578: release le teste salvo como Classico")


func test_trocar_modo_troca_pontuacao_e_recorde_por_modo() -> void:
	Global.modos_teste_habilitado = true
	Global.usar_options_store(OptionsStore.new(TMP_OPCOES))
	Global.set_modo_jogo("classico")
	Global.set_score(5)
	var keeper_classico := Global.pontuacao
	Global.set_modo_jogo("teste")
	assert_ne(Global.pontuacao, keeper_classico, "C579: pontuacao aponta para outro keeper")
	assert_eq(Global.get_best_score(), 0, "C579: recorde do teste comeca em 0")
	Global.set_score(9)
	assert_eq(Global.get_best_score(), 9, "C579: recorde do teste e 9")
	Global.set_modo_jogo("classico")
	assert_eq(Global.get_best_score(), 5, "C579: recorde do Classico segue 5")
	Global.set_score(2)
	Global.set_modo_jogo("teste")
	assert_eq(Global.get_best_score(), 9, "C579: set_score no Classico nao altera o recorde do teste")


func test_set_modo_jogo_ignorado_com_partida_iniciada() -> void:
	Global.modos_teste_habilitado = true
	Global.usar_options_store(OptionsStore.new(TMP_OPCOES))
	Global.set_modo_jogo("classico")
	Global.set_iniciado(true)
	Global.set_modo_jogo("teste")
	assert_eq(Global.modo_jogo, GameModes.ID_CLASSICO, "C580: modo inalterado com iniciado")
	var guardado: Variant = Global.opcoes.load_value(Global.MODO_SECTION, Global.MODO_KEY, "")
	assert_ne(str(guardado), "teste", "C580: modo persistido inalterado")
	Global.set_iniciado(false)


func test_recordes_isolados_apos_pre_run() -> void:
	Global.modos_teste_habilitado = true
	for modo in GameModes.lista(true):
		Global.keeper_do_modo(modo.id)
		var store := Global.store_do_modo(modo.id)
		var caminho := "" if store == null else store.path
		assert_false(caminho.begins_with("user://best_score"), "C581: modo %s sem store real (%s)" % [modo.id, caminho])
	assert_eq(Global.pontuacao.get_signal_connection_list("best_changed").size(), 0, "C581: pontuacao sem conexao")


func test_usar_options_store_nao_religa_keeper_ao_store_real() -> void:
	Global.usar_options_store(OptionsStore.new(TMP_OPCOES))
	for modo in GameModes.lista(true):
		var store := Global.store_do_modo(modo.id)
		assert_null(store, "C581: usar_options_store nao liga o modo %s a store" % modo.id)


func test_usar_options_store_com_mesmo_modo_nao_reaplica() -> void:
	Global.modos_teste_habilitado = true
	Global.usar_options_store(OptionsStore.new(TMP_OPCOES))
	var keeper := ScoreKeeper.new()
	Global.pontuacao = keeper
	watch_signals(Global)
	Global.usar_options_store(OptionsStore.new(TMP_OPCOES))
	assert_eq(Global.pontuacao, keeper, "keeper atribuido sobrevive a troca de store com o mesmo modo")
	assert_signal_not_emitted(Global, "modo_jogo_changed", "mesmo modo nao emite modo_jogo_changed")


# Estado do Global antes do 1o carregamento em producao: sem isolamento e sem keeper/store criado
func _simular_boot_sem_isolamento() -> void:
	Global._recordes_isolados = false
	Global._keepers.clear()
	Global._stores.clear()


func test_primeiro_carregamento_liga_o_keeper_do_classico_ao_store() -> void:
	DirAccess.make_dir_recursive_absolute(TMP_RECORDE_DIR)
	var caminho := TMP_RECORDE
	DirAccess.remove_absolute(caminho)
	Global.caminho_recorde_classico = caminho
	_simular_boot_sem_isolamento()
	# Estado de boot: modo Classico por valor de campo, sem passar por _aplicar_modo
	Global.modo_jogo = GameModes.ID_CLASSICO
	Global._iniciar_keeper()
	Global.set_score(6)
	var store := BestScoreStore.new(caminho)
	assert_eq(store.load_best(), 6, "1o carregamento: set_score acima do best grava no store do Classico")
	_simular_boot_sem_isolamento()
	Global._iniciar_keeper()
	assert_eq(Global.get_best_score(), 6, "1o carregamento: recorde salvo e carregado no keeper do Classico")


func test_pontuacao_segue_membro_atribuivel() -> void:
	var proprio := ScoreKeeper.new()
	Global.pontuacao = proprio
	Global.set_score(4)
	assert_eq(proprio.best, 4, "C583: keeper atribuido recebe a pontuacao")
	assert_eq(Global.get_best_score(), 4, "C583: get_best_score le o keeper atribuido")
