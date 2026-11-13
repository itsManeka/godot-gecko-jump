extends GutTest

# Reabertura do tutorial por Opcoes > Ver tutorial na Stage real (handoff 12.5): modal, mesma origem (pausa x menu),
# flag `tutorial/visto` intacta, card da 1a partida escondido enquanto o reaberto esta na tela.
const STAGE_SCENE := "res://scenes/Stage.tscn"
const TEST_PATH := "user://test_stage_tutorial_revisao.cfg"
const VISIVEL := Vector2(180.0, 320.0)
const SAFE_TOTAL := Rect2(0.0, 0.0, 180.0, 320.0)

var _opcoes_anteriores: OptionsStore = null


func before_each() -> void:
	_limpar()
	_opcoes_anteriores = Global.opcoes
	Global.usar_options_store(OptionsStore.new(TEST_PATH))
	Global.tutorial_visto_espelho = false
	Global.toque_detectado = true
	Global.dica_toque_mostrada = false
	Global.platforms = []
	Global.iniciado = false


func after_each() -> void:
	get_tree().paused = false
	Input.action_release("jump")
	Global.usar_options_store(_opcoes_anteriores)
	Global.tutorial_visto_espelho = false
	Global.toque_detectado = false
	Global.dica_toque_mostrada = false
	Global.platforms = []
	Global.iniciado = false
	_limpar()


func _limpar() -> void:
	for p in [TEST_PATH, TEST_PATH + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


func _stage_no_menu() -> Node:
	var stage: Node = add_child_autofree(load(STAGE_SCENE).instantiate())
	await wait_frames(2)
	stage.apply_layout(VISIVEL, SAFE_TOTAL)
	return stage


# Partida em curso e pausada; com `visto` o card da 1a partida nao abre
func _stage_pausado(visto: bool) -> Node:
	Global.tutorial_visto_espelho = visto
	var stage: Node = add_child_autofree(load(STAGE_SCENE).instantiate())
	await wait_frames(2)
	stage.apply_layout(VISIVEL, SAFE_TOTAL)
	stage._on_Play_button_down()
	await wait_process_frames(2)
	stage._pausar()
	return stage


func _toque(pos: Vector2, pressionado: bool = true) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.position = pos
	e.pressed = pressionado
	return e


func _acao(nome: String) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = nome
	e.pressed = true
	return e


func _flag_gravada() -> Variant:
	return Global.opcoes.load_value("tutorial", "visto", null)


func test_c219_origem_pausa_reabrir_e_voltar_mantem_a_pausa_e_o_overlay_como_estava() -> void:
	var stage := await _stage_pausado(true)
	stage.pause_overlay.opcoes.emit()
	assert_false(stage.pause_overlay.visible, "antes: overlay oculto com Opcoes aberta")
	stage.options_screen.ver_tutorial.emit()
	assert_true(stage.tutorial_revisao.esta_aberto(), "card reaberto na tela")
	assert_eq(stage.tutorial_revisao.modo(), TutorialCard.Modo.REABERTURA, "modo reabertura")
	assert_false(stage.options_screen.esta_aberta(), "Opcoes some enquanto o tutorial esta aberto")
	assert_true(get_tree().paused, "arvore segue pausada na reabertura")
	stage.tutorial_revisao.voltar.emit()
	assert_false(stage.tutorial_revisao.esta_aberto(), "Voltar fecha o card reaberto")
	assert_true(stage.options_screen.esta_aberta(), "Voltar devolve Opcoes")
	assert_eq(stage.options_screen.foco_atual(), OptionsScreen.Item.VER_TUTORIAL, "foco volta em Ver tutorial")
	assert_true(get_tree().paused, "arvore segue pausada apos Voltar")
	assert_false(stage.pause_overlay.visible, "overlay de pausa como estava (oculto com Opcoes aberta)")
	stage.options_screen.voltar.emit()
	assert_true(stage.pause_overlay.visible, "Voltar de Opcoes devolve o overlay de pausa")
	assert_eq(stage.pause_overlay.foco_atual(), PauseOverlay.Botao.OPCOES, "foco do overlay em Opcoes")
	assert_true(get_tree().paused, "ainda pausado")


func test_c220_origem_menu_mantem_menu_oculto_e_jump_suspenso_durante_o_tutorial() -> void:
	var stage := await _stage_no_menu()
	stage._abrir_opcoes_do_menu()
	stage.options_screen.ver_tutorial.emit()
	assert_true(stage.tutorial_revisao.esta_aberto(), "card reaberto")
	assert_false(stage.started, "started segue false")
	assert_false(stage.playbutton.visible, "Play oculto")
	assert_false(stage.lastscore.visible, "Last oculto")
	assert_false(stage.bestscore.visible, "Best oculto")
	assert_false(stage.opcoes_botao.visible, "botao Opcoes oculto")
	Input.action_press("jump")
	await wait_process_frames(3)
	assert_false(stage.started, "jump suspenso durante o tutorial reaberto")
	Input.action_release("jump")
	stage.tutorial_revisao.voltar.emit()
	assert_true(stage.options_screen.esta_aberta(), "Voltar devolve Opcoes")
	assert_false(stage.started, "started segue false depois de Voltar do tutorial")
	assert_false(stage.playbutton.visible, "menu segue oculto com Opcoes aberta")
	assert_false(stage.opcoes_botao.visible, "botao Opcoes segue oculto com Opcoes aberta")
	stage.options_screen.voltar.emit()
	assert_true(stage.playbutton.visible, "Play volta so depois de Voltar de Opcoes")
	assert_true(stage.lastscore.visible, "Last volta")
	assert_true(stage.bestscore.visible, "Best volta")
	assert_true(stage.opcoes_botao.visible, "botao Opcoes volta")


func test_c221_flag_visto_identica_antes_e_depois_com_a_flag_ausente() -> void:
	var stage := await _stage_pausado(false)
	var antes: Variant = _flag_gravada()
	assert_null(antes, "flag nao gravada antes da reabertura")
	stage.pause_overlay.opcoes.emit()
	stage.options_screen.ver_tutorial.emit()
	stage.tutorial_revisao.voltar.emit()
	assert_eq(_flag_gravada(), antes, "reabrir e voltar nao grava a flag")
	assert_false(stage.tutorial_flag.visto(), "a flag segue ausente")


func test_c221_flag_visto_identica_antes_e_depois_com_a_flag_gravada() -> void:
	Global.opcoes.save_value("tutorial", "visto", true)
	Global.tutorial_visto_espelho = false
	var stage := await _stage_pausado(true)
	var antes: Variant = _flag_gravada()
	assert_eq(antes, true, "flag gravada antes da reabertura")
	stage.pause_overlay.opcoes.emit()
	stage.options_screen.ver_tutorial.emit()
	stage.tutorial_revisao.voltar.emit()
	assert_eq(_flag_gravada(), antes, "reabrir e voltar nao muda a flag gravada")


func test_c222_reabertura_consome_todo_toque_fora_do_botao_e_a_dica_nao_aparece() -> void:
	var stage := await _stage_no_menu()
	stage._abrir_opcoes_do_menu()
	stage.options_screen.ver_tutorial.emit()
	var fora := Vector2(20.0, 100.0)
	assert_false(stage.tutorial_revisao.rect_pular().has_point(fora), "ponto fora do botao")
	assert_true(stage.tutorial_revisao.tratar_evento(_toque(fora, true)), "toque fora do botao e consumido")
	assert_true(stage.tutorial_revisao.tratar_evento(_toque(fora, false)), "soltar fora do botao e consumido")
	assert_true(stage.tutorial_revisao.esta_aberto(), "toque fora nao fecha o card")
	Input.parse_input_event(_toque(fora, true))
	Input.flush_buffered_events()
	await wait_frames(2)
	assert_false(stage.started, "toque real na reabertura nao inicia a partida")
	assert_false(stage.touch_controls.classificador.ativo(), "toque nao vira pulo nem andar")
	assert_false(stage.touch_hint.esta_mostrando(), "a dica nao aparece")


func test_c222_card_da_1a_partida_escondido_ao_reabrir_volta_ao_estado_ao_voltar() -> void:
	var stage := await _stage_pausado(false)
	assert_true(stage.tutorial_card.esta_aberto(), "card da 1a partida aberto ao pausar")
	stage.pause_overlay.opcoes.emit()
	stage.options_screen.ver_tutorial.emit()
	assert_false(stage.tutorial_card.visible, "card da 1a partida escondido durante a reabertura")
	assert_true(stage.tutorial_card.esta_aberto(), "card da 1a partida segue aberto (so oculto)")
	stage.tutorial_revisao.voltar.emit()
	assert_true(stage.tutorial_card.visible, "card da 1a partida volta ao estado ao Voltar")
	assert_true(stage.tutorial_card.esta_aberto(), "segue aberto")
	assert_false(stage.tutorial_flag.visto(), "a flag segue ausente")


func test_c222_fundo_de_tela_cheia_na_reabertura_nas_duas_origens_e_oculto_ao_voltar() -> void:
	var pausado := await _stage_pausado(true)
	pausado.pause_overlay.opcoes.emit()
	assert_false(pausado.tutorial_revisao.tela_visivel(), "antes: sem fundo")
	pausado.options_screen.ver_tutorial.emit()
	assert_true(pausado.tutorial_revisao.tela_visivel(), "origem pausa: fundo de tela cheia na reabertura")
	assert_eq(pausado.tutorial_revisao.layer, 12, "reabertura acima de Opcoes (11)")
	pausado.tutorial_revisao.voltar.emit()
	assert_false(pausado.tutorial_revisao.tela_visivel(), "origem pausa: fundo oculto apos Voltar")
	var menu := await _stage_no_menu()
	menu._abrir_opcoes_do_menu()
	menu.options_screen.ver_tutorial.emit()
	assert_true(menu.tutorial_revisao.tela_visivel(), "origem menu: fundo de tela cheia na reabertura")
	menu.tutorial_revisao.voltar.emit()
	assert_false(menu.tutorial_revisao.tela_visivel(), "origem menu: fundo oculto apos Voltar")


func test_c222_esc_no_card_reaberto_volta_a_opcoes() -> void:
	var stage := await _stage_pausado(true)
	stage.pause_overlay.opcoes.emit()
	stage.options_screen.ver_tutorial.emit()
	assert_true(stage.tutorial_revisao.tratar_evento(_acao("pause")), "acao pause consumida pelo card reaberto")
	assert_false(stage.tutorial_revisao.esta_aberto(), "Esc/P volta")
	assert_true(stage.options_screen.esta_aberta(), "Opcoes de volta")
	assert_true(get_tree().paused, "pause nao retoma a partida")
