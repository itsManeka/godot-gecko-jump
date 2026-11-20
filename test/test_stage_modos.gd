extends GutTest

# f523 T8: botao Modo e tela Modos na Stage real. Valores de layout do handoff (Modo 113-137, Play 147-173), nunca
# recalculados da implementacao.
const STAGE_SCENE := "res://scenes/Stage.tscn"
const VISIVEL := Vector2(180.0, 320.0)
const SAFE_TOTAL := Rect2(0.0, 0.0, 180.0, 320.0)
const ALTO := Vector2(180.0, 400.0)
const SAFE_ALTO := Rect2(0.0, 0.0, 180.0, 400.0)
const PLAY_CENTRO := Vector2(90.0, 160.0)

var _modo_original: StringName = GameModes.ID_CLASSICO
var _teste_original: bool = false


func before_each() -> void:
	_modo_original = Global.get_modo_jogo()
	_teste_original = Global.modos_teste_habilitado
	Global.modos_teste_habilitado = true
	Global.set_modo_jogo(GameModes.ID_CLASSICO, false)
	Global.tutorial_visto_espelho = true
	Global.platforms = []
	Global.iniciado = false
	# Recordes distintos por modo (e distintos de 0): Best/Last do menu seguem o modo escolhido
	var classico := Global.keeper_do_modo(GameModes.ID_CLASSICO)
	classico.load_best(4)
	classico.set_score(2)
	var teste := Global.keeper_do_modo(GameModeTeste.ID)
	teste.load_best(9)
	teste.set_score(7)


func after_each() -> void:
	Input.action_release("jump")
	get_tree().paused = false
	Global.platforms = []
	Global.iniciado = false
	Global.modos_teste_habilitado = _teste_original
	Global.set_modo_jogo(_modo_original, false)


func _novo_stage() -> Node:
	var stage: Node = add_child_autofree(load(STAGE_SCENE).instantiate())
	await wait_frames(2)
	stage.apply_layout(VISIVEL, SAFE_TOTAL)
	return stage


func _toque(pressionado: bool, pos: Vector2) -> InputEventScreenTouch:
	var ev := InputEventScreenTouch.new()
	ev.index = 0
	ev.pressed = pressionado
	ev.position = pos
	return ev


func _toque_real(pressionado: bool, pos: Vector2) -> void:
	Input.parse_input_event(_toque(pressionado, pos))
	Input.flush_buffered_events()
	await wait_frames(2)


func _tecla(keycode: Key) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.physical_keycode = keycode
	ev.pressed = true
	return ev


func _abrir_pelo_botao(stage: Node) -> void:
	var centro: Vector2 = stage.modo_botao.rect_botao().get_center()
	stage.modo_botao.tratar_evento(_toque(true, centro))
	stage.modo_botao.tratar_evento(_toque(false, centro))


func _apertar_ok(stage: Node) -> void:
	var centro: Vector2 = stage.modos_screen.rect_ok().get_center()
	stage.modos_screen.tratar_evento(_toque(true, centro))
	stage.modos_screen.tratar_evento(_toque(false, centro))


func test_c603_botao_modo_abre_a_tela_oculta_o_menu_e_suspende_o_inicio() -> void:
	var stage := await _novo_stage()
	assert_true(stage.modo_botao.visible, "botao Modo visivel no menu")
	_abrir_pelo_botao(stage)
	assert_true(stage.modos_screen.esta_aberta(), "tela Modos aberta")
	assert_false(stage.playbutton.visible, "Play oculto")
	assert_false(stage.lastscore.visible, "Last oculto")
	assert_false(stage.bestscore.visible, "Best oculto")
	assert_false(stage.opcoes_botao.visible, "botao Opcoes oculto")
	assert_false(stage.modo_botao.visible, "botao Modo oculto")
	assert_false(stage.started, "abrir a tela nao inicia a partida")
	Input.action_press("jump")
	await wait_process_frames(3)
	assert_false(stage.started, "jump nao inicia com a tela aberta")
	Input.action_release("jump")
	stage._input(_toque(true, Vector2(20.0, 100.0)))
	assert_false(stage.started, "toque no fundo da Stage nao inicia com a tela aberta")
	await _toque_real(true, PLAY_CENTRO)
	assert_false(stage.started, "toque real na area do Play nao inicia com a tela aberta")


func test_c604_ok_com_outro_modo_aplica_e_mostra_best_e_last_do_modo() -> void:
	var stage := await _novo_stage()
	assert_eq(stage.bestscore.text, "Best Score: 4", "Best do Classico no menu")
	_abrir_pelo_botao(stage)
	stage.modos_screen.tratar_evento(_tecla(KEY_RIGHT))
	assert_eq(stage.modos_screen.modo_exibido().id, GameModeTeste.ID, "carrossel no modo de teste")
	_apertar_ok(stage)
	assert_eq(Global.modo_jogo, GameModeTeste.ID, "Global.modo_jogo novo")
	assert_false(stage.modos_screen.esta_aberta(), "OK fecha a tela")
	assert_eq(stage.bestscore.text, "Best Score: 9", "Best do menu = recorde do modo escolhido")
	assert_eq(stage.lastscore.text, "Last Score: 7", "Last do modo escolhido")
	assert_true(stage.bestscore.visible, "Best volta ao menu")
	assert_eq(stage.ultimo_estado.get("modo"), "teste", "ponte republicada com o modo novo")


func test_c605_play_inicia_apos_fechar_e_toque_no_modo_nao_inicia() -> void:
	var stage := await _novo_stage()
	var modo_centro: Vector2 = stage.modo_botao.rect_botao().get_center()
	await _toque_real(true, modo_centro)
	assert_false(stage.started, "apertar o Modo nao inicia a partida")
	await _toque_real(false, modo_centro)
	assert_false(stage.started, "soltar o Modo nao inicia a partida")
	assert_true(stage.modos_screen.esta_aberta(), "soltar dentro abre a tela")
	_apertar_ok(stage)
	assert_false(stage.modos_screen.esta_aberta(), "OK fechou a tela")
	assert_false(stage.started, "fechar a tela nao inicia")
	await _toque_real(true, PLAY_CENTRO)
	assert_true(stage.started, "toque no Play (y 147-173) inicia a partida depois de fechar")


func test_c606_telas_modos_e_opcoes_se_excluem_e_modos_nao_abre_com_started() -> void:
	var stage := await _novo_stage()
	_abrir_pelo_botao(stage)
	stage._abrir_opcoes_do_menu()
	assert_false(stage.options_screen.esta_aberta(), "Opcoes nao abre com Modos aberta")
	assert_true(stage.modos_screen.esta_aberta(), "Modos segue aberta")
	_apertar_ok(stage)
	stage._abrir_opcoes_do_menu()
	assert_true(stage.options_screen.esta_aberta(), "Opcoes abre com Modos fechada")
	stage._abrir_modos_do_menu()
	assert_false(stage.modos_screen.esta_aberta(), "Modos nao abre com Opcoes aberta")
	stage.options_screen.voltar.emit()
	stage._on_Play_button_down()
	stage._abrir_modos_do_menu()
	assert_false(stage.modos_screen.esta_aberta(), "Modos nao abre com a partida iniciada")


func test_ui_up_com_foco_no_opcoes_volta_ao_play() -> void:
	var stage := await _novo_stage()
	stage.modo_botao.focar(false)
	stage.opcoes_botao.focar(true)
	# Acao `ui_up` (a seta para cima tambem e `jump` e iniciaria a partida): passa pelo `_input` dos filhos na ordem real
	var ev := InputEventAction.new()
	ev.action = "ui_up"
	ev.pressed = true
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
	await wait_frames(2)
	assert_false(stage.opcoes_botao.tem_foco(), "ui_up tira o foco do Opcoes (volta ao Play)")
	assert_false(stage.modo_botao.tem_foco(), "Modo nao toma o foco do ui_up que era do Opcoes")


func test_c607_ordem_dos_filhos_nao_rouba_o_play_e_layout_repassado_aos_dois() -> void:
	var stage := await _novo_stage()
	var opcoes_i: int = stage.opcoes_botao.get_index()
	var modo_i: int = stage.modo_botao.get_index()
	var modos_i: int = stage.modos_screen.get_index()
	assert_gt(modo_i, opcoes_i, "ModoBotao depois do botao Opcoes")
	assert_gt(modos_i, modo_i, "ModosScreen depois do ModoBotao")
	assert_lt(modos_i, stage.options_screen.get_index(), "ModosScreen antes da tela de Opcoes")
	assert_lt(modos_i, stage.tutorial_revisao.get_index(), "ModosScreen antes da revisao do tutorial")
	var play := Rect2(stage.playbutton.offset_left, stage.playbutton.offset_top, 56.0, 26.0)
	assert_false(stage.modo_botao.rect_botao().intersects(play), "botao Modo nao cobre o Play")
	stage.apply_layout(ALTO, SAFE_ALTO)
	assert_eq(stage.modo_botao.rect_botao(), Rect2(34.0, 113.0, 112.0, 24.0), "botao Modo com 180x400")
	assert_eq(stage.modos_screen.rect_ok(), Rect2(34.0, 283.0, 112.0, 32.0), "OK da tela com 180x400 (bloco centrado)")
	await _toque_real(true, PLAY_CENTRO)
	assert_true(stage.started, "o toque no Play nao e roubado pelo botao Modo")
