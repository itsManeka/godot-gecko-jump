extends GutTest

# f528 T6 (C775-C788): bloqueio de inicio, gasto da tentativa, resultado do dia e UI do menu no Diario.
# Mesmo padrao do test_stage_diario_seed.gd: modo e relogio injetados ANTES do add_child (o _enter_tree le
# os dois), Stage na raiz com layout fixo 360x640 e a recarga espiada pela seam `recarregar_cena` (o GUT
# nao pode trocar a cena do proprio runner; a Stage que o reload real instanciaria e simulada instanciando
# outra com o modo persistido). O store do dia vive no caminho isolado pelo gut_pre_run (como o options
# store): cada teste comeca com ele limpo e nenhum teste grava o user://desafio_diario.cfg real.
# Derrotas usam o caminho real (_on_CheckPlayer_body_exited) e a Stage e liberada ANTES das assercoes que
# podem falhar: com a producao mutada o teste fica vermelho sem deixar a animacao de derrota viva na
# arvore (o _on_animation_end trocaria a cena do runner no meio da suite).

const STAGE_SCENE := "res://scenes/Stage.tscn"
# Plano de testes [T3/T5/T6]: base 1700000000 = dia UTC 19675 (par travado em test_dia_utc.gd e
# test_stage_diario_seed.gd); dia + 1 = 19676. `?dia=0` injeta unix 0 -> sentinela DIA_INVALIDO (C774).
const DIA_BASE := 19675
# Caminho isolado pelo gut_pre_run (nenhum teste grava o user:// real); limpo em before_each/after_each
const CAMINHO_STORE := "user://desafio_diario_test_suite.cfg"
const VISIVEL := Vector2(360.0, 640.0)
const SAFE := Rect2(0.0, 0.0, 360.0, 640.0)
const X_QUEDA := 40.0
const Y_QUEDA := 720.0

var _modo_original: StringName
var _dia_inicial_original: int
var _sem_derrota_original: bool
var _toque_detectado_original: bool
var _espelho_original: bool
var _cor_original: Enums.COLOR
# Pedidos de recarga registrados pela seam `recarregar_cena` das Stages deste teste
var _recargas: Array = []
# Contagem de sinais partida_iniciada conectada ad hoc por teste
var _inicios: int = 0


func before_each() -> void:
	_modo_original = Global.get_modo_jogo()
	_dia_inicial_original = Global.dia_inicial
	_sem_derrota_original = Global.sem_derrota
	_toque_detectado_original = Global.toque_detectado
	_espelho_original = Global.tutorial_visto_espelho
	_cor_original = Global.cor_gecko
	# Store do dia limpo por teste: nada do teste anterior (nem de outros arquivos) vaza para este
	DirAccess.remove_absolute(CAMINHO_STORE)
	Global.sem_derrota = false
	Global.tutorial_visto_espelho = true
	Global.toque_detectado = false
	Global.platforms = []
	Global.iniciado = false
	_recargas = []
	_inicios = 0


func after_each() -> void:
	Input.action_release("jump")
	get_tree().paused = false
	# iniciado = false antes de restaurar o modo (a troca e bloqueada com a partida iniciada) e de novo no fim
	Global.iniciado = false
	Global.set_modo_jogo(_modo_original)
	Global.dia_inicial = _dia_inicial_original
	Global.sem_derrota = _sem_derrota_original
	Global.toque_detectado = _toque_detectado_original
	Global.tutorial_visto_espelho = _espelho_original
	Global.cor_gecko = _cor_original
	Global.platforms = []
	Global.iniciado = false
	DirAccess.remove_absolute(CAMINHO_STORE)


# Store proprio do teste: mesma fonte da Stage (o caminho isolado pelo pre-run). Sempre NOVA instancia —
# o disco e a verdade compartilhada com o store que a Stage criou no _ready.
func _store() -> DesafioDiarioStore:
	return DesafioDiarioStore.new(CAMINHO_STORE)


# Stage no modo pedido, com a seam de recarga registrando pedidos (o reload real trocaria a cena do
# runner; a Stage que ele instanciaria e simulada instanciando outra com o modo persistido).
func _stage_de_modo(id: StringName) -> Node:
	Global.iniciado = false
	Global.set_modo_jogo(id, false)
	var stage: Node = load(STAGE_SCENE).instantiate()
	stage.recarregar_cena = func() -> void: _recargas.append("recarga")
	add_child(stage)
	stage.apply_layout(VISIVEL, SAFE)
	return stage


# Stage Diario com o relogio do dia injetado (padrao do test_stage_diario_seed.gd: modo e dia ANTES do
# add_child). dia = 0 injeta unix 0 (sentinela, relogio invalido).
func _stage_diario(dia: int) -> Node:
	Global.aplicar_dia_inicial(str(dia), true)
	return _stage_de_modo(GameModes.ID_DIARIO)


func _contar_inicio() -> void:
	_inicios += 1


# Derrota pela queda (caminho real): sem pulo em curso a linha de derrota encerra a partida
func _cair(stage: Node) -> void:
	var player = stage.player
	player.jumping = false
	player.global_position = Vector2(X_QUEDA, Y_QUEDA)
	stage._on_CheckPlayer_body_exited(player)


func _liberar(stage: Node) -> void:
	remove_child(stage)
	stage.free()


func _bytes_do_arquivo(caminho: String) -> PackedByteArray:
	if not FileAccess.file_exists(caminho):
		return PackedByteArray()
	return FileAccess.get_file_as_bytes(caminho)


# C775: 1o Play no dia -> started true e a tentativa do dia ja gasta ANTES do 1o ponto (o gasto conta
# desde o inicio, mesmo que o app feche logo depois; D7).
func test_C775_primeiro_play_no_dia_gasta_a_tentativa_antes_do_primeiro_ponto() -> void:
	var stage := _stage_diario(DIA_BASE)
	assert_false(stage.started, "fixture: a Stage nasce sem partida iniciada")
	stage._on_Play_button_down()
	assert_true(stage.started, "C775: o 1o Play do dia inicia a partida")
	assert_eq(stage.points, -1, "C775: nenhum ponto ainda (nem o pouso inicial aconteceu)")
	assert_false(_store().tentativa_disponivel(DIA_BASE), "C775: a tentativa do dia ja foi gasta antes do 1o ponto")
	assert_eq(_store().resultado_do(DIA_BASE), 0, "C775: sem derrota o resultado do dia segue 0")
	_liberar(stage)


# C776: 2a tentativa no mesmo dia — o Play nao inicia: sem started, sem tutorial, sem evento
# partida_iniciada; o botao aparece desabilitado com o texto do dia.
func test_C776_segunda_tentativa_play_nao_inicia_sem_tutorial_e_sem_partida_iniciada() -> void:
	var primeira := _stage_diario(DIA_BASE)
	primeira._on_Play_button_down()
	assert_true(primeira.started, "fixture: o 1o Play do dia gastou a tentativa")
	_liberar(primeira)
	# a 2a tentativa ve a Stage recarregada pelo fim da partida anterior: mesma tela, mesmo dia gasto
	var stage := _stage_diario(DIA_BASE)
	stage.partida_iniciada.connect(_contar_inicio)
	stage._on_Play_button_down()
	assert_false(stage.started, "C776: 2a tentativa no mesmo dia: o Play nao inicia")
	assert_eq(_inicios, 0, "C776: nenhum evento partida_iniciada")
	assert_false(stage.tutorial_card.esta_aberto(), "C776: sem tutorial")
	assert_true(stage.playbutton.disabled, "C776: o Play aparece desabilitado")
	assert_eq(stage.playbutton.text, "Ja jogado hoje", "C776: com o texto do dia")
	_liberar(stage)


# C777: 2a tentativa — a acao `jump` (caminho do _process) nao inicia a partida.
func test_C777_segunda_tentativa_acao_jump_nao_inicia() -> void:
	_store().gastar_tentativa(DIA_BASE)
	var stage := _stage_diario(DIA_BASE)
	Input.action_press("jump")
	stage._process(0.016)
	Input.action_release("jump")
	assert_false(stage.started, "C777: 2a tentativa: a acao jump (caminho do _process) nao inicia")
	assert_eq(_recargas.size(), 0, "C777: dia ja jogado: nenhuma recarga pedida (so a virada recarrega)")
	_liberar(stage)


# C778: 2a tentativa — o toque no fundo (caminho do _input) nao inicia a partida.
func test_C778_segunda_tentativa_toque_no_fundo_nao_inicia() -> void:
	_store().gastar_tentativa(DIA_BASE)
	var stage := _stage_diario(DIA_BASE)
	var toque := InputEventScreenTouch.new()
	toque.pressed = true
	toque.position = Vector2(180.0, 400.0)
	stage._input(toque)
	assert_false(stage.started, "C778: 2a tentativa: o toque no fundo (_input) nao inicia")
	assert_eq(_recargas.size(), 0, "C778: dia ja jogado: nenhuma recarga pedida")
	_liberar(stage)


# C779: Play desabilitado com o texto "Ja jogado hoje" quando _pode_iniciar() e falso; habilitado com o
# rotulo original quando verdadeiro — o estado do botao e o MESMO predicado da acao nos dois lados, e o
# texto do dia cabe no botao (legivel, dentro da tela: o que o gate visual C789 confere).
func test_C779_play_desabilitado_com_texto_do_dia_seguindo_o_predicado_nos_dois_lados() -> void:
	_store().gastar_tentativa(DIA_BASE)
	var stage := _stage_diario(DIA_BASE)
	assert_false(stage._pode_iniciar(), "fixture: o dia gasto nega o inicio")
	assert_true(stage.playbutton.disabled, "C779: Play desabilitado quando _pode_iniciar() e falso")
	assert_eq(stage.playbutton.text, "Ja jogado hoje", "C779: com o texto do dia (D3)")
	assert_eq(stage.playbutton.disabled, not stage._pode_iniciar(), "C779: o estado do botao e o mesmo predicado da acao")
	var largura_texto: float = stage.playbutton.get_theme_font("font").get_string_size(
		"Ja jogado hoje", HORIZONTAL_ALIGNMENT_LEFT, -1, 32
	).x
	assert_true(
		largura_texto <= stage.playbutton.size.x,
		"C779: o texto do dia (%.1f px) cabe no botao de %.1f px" % [largura_texto, stage.playbutton.size.x]
	)
	assert_true(
		stage.playbutton.position.x >= 0.0 and stage.playbutton.position.x + stage.playbutton.size.x <= VISIVEL.x,
		"C779: o botao com o texto fica dentro da tela"
	)
	_liberar(stage)
	# relogio no dia seguinte: a Stage recarregada (o que o inicio bloqueado pela virada faria) nasce
	# habilitada com o rotulo original — o mesmo predicado, o outro lado
	var nova := _stage_diario(DIA_BASE + 1)
	assert_true(nova._pode_iniciar(), "fixture: o dia novo libera o inicio")
	assert_false(nova.playbutton.disabled, "C779: habilitado quando _pode_iniciar() e verdadeiro")
	assert_eq(nova.playbutton.text, "Play", "C779: o rotulo original volta com o dia liberado")
	assert_eq(nova.playbutton.disabled, not nova._pode_iniciar(), "C779: mesmo predicado no lado habilitado")
	_liberar(nova)


# C780: relogio em dia + 1 -> inicia de novo e o Best do menu = 0 (a virada zera o resultado do dia; o do
# dia anterior segue intacto no store).
func test_C780_dia_seguinte_inicia_de_novo_e_best_do_menu_zera() -> void:
	var stage := _stage_diario(DIA_BASE)
	stage._on_Play_button_down()
	stage.points = 7
	_cair(stage)
	var estado: String = stage.ultimo_estado.get("state", "")
	_liberar(stage)
	assert_eq(estado, GameState.STATE_LOST, "fixture: a queda encerrou a partida")
	assert_eq(_store().resultado_do(DIA_BASE), 7, "fixture: o resultado do dia gravado")
	# menu da Stage do dia novo: Best zerado pela virada (resultado_do(dia + 1) == 0)
	var nova := _stage_diario(DIA_BASE + 1)
	assert_eq(nova.bestscore.text, "Best Score: 0", "C780: Best do menu = 0 no dia novo (virada zera)")
	nova._on_Play_button_down()
	assert_true(nova.started, "C780: inicia de novo no dia seguinte")
	assert_false(_store().tentativa_disponivel(DIA_BASE + 1), "C780: gastou a tentativa do dia novo")
	assert_eq(_store().resultado_do(DIA_BASE + 1), 0, "C780: o dia novo comeca com resultado 0")
	_liberar(nova)


# C781: derrota com N pontos -> resultado_do(dia) == N, e o best_score_* dos outros modos (arquivos e
# Global.get_best_score()) inalterados — o recorde proprio do dia nunca toca os outros modos.
func test_C781_derrota_grava_resultado_do_dia_sem_tocar_os_recordes_de_outros_modos() -> void:
	var arquivos := [
		"user://best_score.cfg", "user://best_score_puro.cfg", "user://best_score_tempo.cfg", "user://best_score_zen.cfg"
	]
	var antes := {}
	for caminho in arquivos:
		antes[caminho] = _bytes_do_arquivo(caminho)
	# recorde pre-gravado no Classico (keeper em memoria: o pre-run isola os stores)
	Global.set_modo_jogo(GameModes.ID_CLASSICO, false)
	Global.set_score(5)
	assert_eq(Global.get_best_score(), 5, "fixture: recorde do Classico pre-gravado")
	var stage := _stage_diario(DIA_BASE)
	stage._on_Play_button_down()
	stage.points = 9
	_cair(stage)
	var estado: String = stage.ultimo_estado.get("state", "")
	_liberar(stage)
	assert_eq(estado, GameState.STATE_LOST, "fixture: a queda encerrou a partida")
	assert_eq(_store().resultado_do(DIA_BASE), 9, "C781: derrota com N pontos -> resultado_do(dia) == N")
	assert_eq(Global.keeper_do_modo(GameModes.ID_DIARIO).best, 0, "C781: o keeper do Diario nao recebeu os pontos")
	assert_eq(Global.keeper_do_modo(GameModes.ID_CLASSICO).best, 5, "C781: o recorde do Classico ficou intacto")
	Global.iniciado = false
	Global.set_modo_jogo(GameModes.ID_CLASSICO, false)
	assert_eq(Global.get_best_score(), 5, "C781: Global.get_best_score() do Classico inalterado")
	assert_false(FileAccess.file_exists("user://best_score_diario.cfg"), "C781: nenhum best_score_diario.cfg nasce")
	for caminho in arquivos:
		assert_eq(_bytes_do_arquivo(caminho), antes[caminho], "C781: %s byte a byte igual antes/depois" % caminho)


# C782: fechar/liberar a Stage depois de iniciar, sem derrota -> tentativa gasta e resultado 0 (o gasto
# vale desde o inicio; o resultado so nasce na derrota — D7).
func test_C782_fechar_a_stage_sem_derrota_deixa_tentativa_gasta_e_resultado_zero() -> void:
	var stage := _stage_diario(DIA_BASE)
	stage._on_Play_button_down()
	assert_true(stage.started, "fixture: partida iniciada (tentativa gasta ao iniciar)")
	_liberar(stage)
	assert_false(_store().tentativa_disponivel(DIA_BASE), "C782: a tentativa ficou gasta (o gasto vale desde o inicio)")
	assert_eq(_store().resultado_do(DIA_BASE), 0, "C782: sem derrota o resultado do dia segue 0")


# C783: Stage criada no dia d, relogio avancado para d+1 ANTES do Play -> o inicio bloqueado pela virada
# pede a recarga com a seed de d+1 e so o Play na Stage nova gasta a tentativa de d+1 (a de d intacta).
func test_C783_virada_antes_do_play_recarrega_com_seed_nova_e_gasta_so_a_tentativa_do_dia_novo() -> void:
	var stage := _stage_diario(DIA_BASE)
	assert_eq(stage._dia_da_stage, DIA_BASE, "fixture: a Stage nasce no dia d")
	Global.aplicar_dia_inicial(str(DIA_BASE + 1), true)
	stage._on_Play_button_down()
	assert_false(stage.started, "C783: o Play com a Stage do dia antigo nao inicia nada")
	assert_eq(_recargas.size(), 1, "C783: o inicio bloqueado pela virada pede a recarga da Stage")
	assert_true(_store().tentativa_disponivel(DIA_BASE), "C783: a tentativa do dia antigo segue intacta")
	assert_true(_store().tentativa_disponivel(DIA_BASE + 1), "C783: a do dia novo ainda nao foi gasta pela recarga")
	_liberar(stage)
	# a Stage que o reload real instanciaria: nasce com a seed do dia novo e o Play seguinte gasta d+1
	var nova := _stage_diario(DIA_BASE + 1)
	assert_eq(nova.get_node("ScrollLevel").semente, DIA_BASE + 1, "C783: a Stage recarregada nasce com a seed de d+1")
	assert_eq(nova._dia_da_stage, DIA_BASE + 1, "C783: e guarda o dia novo")
	nova._on_Play_button_down()
	assert_true(nova.started, "C783: so entao (na Stage do dia novo) a partida inicia")
	assert_false(_store().tentativa_disponivel(DIA_BASE + 1), "C783: gastando a tentativa de d+1")
	assert_true(_store().tentativa_disponivel(DIA_BASE), "C783: a de d continua intacta (nunca foi gasta)")
	_liberar(nova)


# C784: virada no meio da partida — derrota APOS o relogio d+1 grava o resultado em d (dia do inicio) e o
# dia novo segue zerado e liberado.
func test_C784_virada_no_meio_da_partida_grava_o_resultado_no_dia_do_inicio() -> void:
	var stage := _stage_diario(DIA_BASE)
	stage._on_Play_button_down()
	stage.points = 11
	Global.aplicar_dia_inicial(str(DIA_BASE + 1), true)
	_cair(stage)
	var estado: String = stage.ultimo_estado.get("state", "")
	_liberar(stage)
	assert_eq(estado, GameState.STATE_LOST, "fixture: derrota apos a virada")
	assert_eq(_store().resultado_do(DIA_BASE), 11, "C784: o resultado foi gravado no dia do inicio (d)")
	assert_eq(_store().resultado_do(DIA_BASE + 1), 0, "C784: o dia novo segue com resultado 0")
	assert_true(_store().tentativa_disponivel(DIA_BASE + 1), "C784: e com a tentativa liberada (a virada zera)")


# C785: relogio invalido (sentinela) — nada inicia pelas tres entradas e o Play aparece desabilitado com o
# texto do dia; nenhuma recarga (a falha e do relogio, nao da virada).
func test_C785_relogio_invalido_nada_inicia_e_play_desabilitado_com_texto_do_dia() -> void:
	var stage := _stage_diario(0)
	assert_eq(stage._dia_da_stage, DiaUtc.DIA_INVALIDO, "fixture: relogio invalido guarda a sentinela")
	assert_false(stage._pode_iniciar(), "C785: relogio invalido nega o inicio")
	assert_true(stage.playbutton.disabled, "C785: Play desabilitado")
	assert_eq(stage.playbutton.text, "Ja jogado hoje", "C785: com o texto do dia (mesmo texto de D3)")
	stage.partida_iniciada.connect(_contar_inicio)
	stage._on_Play_button_down()
	assert_false(stage.started, "C785: o Play nao inicia")
	Input.action_press("jump")
	stage._process(0.016)
	Input.action_release("jump")
	assert_false(stage.started, "C785: a acao jump nao inicia")
	var toque := InputEventScreenTouch.new()
	toque.pressed = true
	stage._input(toque)
	assert_false(stage.started, "C785: o toque no fundo nao inicia")
	assert_eq(_inicios, 0, "C785: nenhum evento partida_iniciada")
	assert_eq(_recargas.size(), 0, "C785: relogio invalido nao pede recarga")
	_liberar(stage)


# C786: Classico/Puro/Tempo/Zen — _pode_iniciar() verdadeiro e inicio como hoje (regressao nas tres
# entradas: Play, acao jump do _process, toque do _input).
func test_C786_classico_puro_tempo_zen_pode_iniciar_verdadeiro_e_as_tres_entradas_iniciam() -> void:
	_modo_inicia_como_hoje(GameModes.ID_CLASSICO)
	_modo_inicia_como_hoje(GameModes.ID_PURO)
	_modo_inicia_como_hoje(GameModes.ID_TEMPO)
	_modo_inicia_como_hoje(GameModes.ID_ZEN)


# As tres entradas de inicio no modo pedido, uma Stage por entrada (started nao volta a false)
func _modo_inicia_como_hoje(id: StringName) -> void:
	var nome := String(id)
	var por_play := _stage_de_modo(id)
	assert_true(por_play._pode_iniciar(), "C786: %s pode iniciar como hoje" % nome)
	assert_false(por_play.playbutton.disabled, "C786: %s: Play habilitado como hoje" % nome)
	assert_eq(por_play.playbutton.text, "Play", "C786: %s: rotulo original do Play" % nome)
	por_play._on_Play_button_down()
	assert_true(por_play.started, "C786: %s: o Play inicia como hoje" % nome)
	_liberar(por_play)
	var por_jump := _stage_de_modo(id)
	Input.action_press("jump")
	por_jump._process(0.016)
	Input.action_release("jump")
	assert_true(por_jump.started, "C786: %s: a acao jump inicia como hoje" % nome)
	_liberar(por_jump)
	var por_toque := _stage_de_modo(id)
	var toque := InputEventScreenTouch.new()
	toque.pressed = true
	por_toque._input(toque)
	assert_true(por_toque.started, "C786: %s: o toque no fundo inicia como hoje" % nome)
	_liberar(por_toque)


# C787: Best do menu mostra resultado_do(dia_atual) com a string "Best Score: N" — reavaliado ao abrir o
# menu (a Stage nasce) e na troca de modo; o Last e a partida do dia (D4).
func test_C787_best_do_menu_mostra_resultado_do_dia_reavaliado_na_troca_de_modo_e_ao_abrir() -> void:
	var store := _store()
	store.gastar_tentativa(DIA_BASE)
	store.gravar_resultado(DIA_BASE, 12)
	var stage := _stage_diario(DIA_BASE)
	assert_eq(stage.bestscore.text, "Best Score: 12", "C787: Best mostra resultado_do(dia) com a string do menu")
	assert_eq(stage.lastscore.text, "Last Score: 12", "C787: Last = a partida do dia (D4)")
	# troca de modo: o placar reavalia pelo modo vigente
	stage._abrir_modos_do_menu()
	stage._fechar_modos(GameModes.classico())
	assert_eq(
		stage.bestscore.text,
		"Best Score: " + str(Global.get_best_score()),
		"C787: no Classico o Best volta ao recorde do modo"
	)
	# voltar ao Diario: o placar reavalia o resultado do dia (mesma Stage — a recarga virou pedido na seam)
	stage._abrir_modos_do_menu()
	stage._fechar_modos(GameModes.diario())
	assert_eq(stage.bestscore.text, "Best Score: 12", "C787: voltar ao Diario reavalia o resultado do dia")
	_liberar(stage)


# C788: pausa no Diario — so Continuar/Opcoes (permite_sair_pela_pausa false): o botao Sair fica invisivel
# e a acao de sair nao faz nada (arvore segue pausada). Contra-prova no Zen (permite_sair true): o mesmo
# overlay mostra o botao e a acao de sair despausa e recarrega — o teste nao e vacuo.
func test_C788_pausa_no_diario_so_continuar_e_opcoes_sem_botao_sair() -> void:
	assert_false(
		GameModes.diario().regra.permite_sair_pela_pausa(),
		"fixture: o Diario nao permite sair pela pausa (D8)"
	)
	var stage := _stage_diario(DIA_BASE)
	stage._on_Play_button_down()
	assert_true(stage._pausar(), "fixture: a pausa abriu o overlay no Diario")
	var permite_diario: bool = stage.pause_overlay.permite_sair
	var rect_diario: Rect2 = stage.pause_overlay.rect_sair()
	var arvore_pausada := get_tree().paused
	stage._sair_da_pausa()
	var segue_pausada := get_tree().paused
	get_tree().paused = false
	assert_eq(arvore_pausada, true, "fixture: a arvore pausou com a partida em curso")
	assert_false(permite_diario, "C788: no Diario o overlay nao permite Sair")
	assert_eq(rect_diario.size, Vector2.ZERO, "C788: no Diario o botao Sair nao ocupa area (oculto)")
	assert_eq(segue_pausada, true, "C788: a acao de sair nao faz nada no Diario (arvore segue pausada)")
	assert_eq(_recargas.size(), 0, "C788: nenhum pedido de recarga pelo Sair no Diario")
	_liberar(stage)
	# contra-prova no Zen: o mesmo overlay mostra o botao e a acao de sair vale
	var zen := _stage_de_modo(GameModes.ID_ZEN)
	zen._on_Play_button_down()
	assert_true(zen._pausar(), "fixture: a pausa abriu o overlay no Zen")
	assert_true(zen.pause_overlay.permite_sair, "fixture: no Zen (permite_sair true) o botao Sair aparece")
	assert_gt(zen.pause_overlay.rect_sair().size.x, 0.0, "fixture: no Zen o botao Sair ocupa area")
	zen._sair_da_pausa()
	assert_eq(get_tree().paused, false, "fixture: no Zen a acao de sair despausa")
	assert_eq(_recargas.size(), 1, "fixture: no Zen a saida pede a recarga da Stage")
	_liberar(zen)
