extends GutTest

# Origem pausa da tela de Opcoes na Stage real: Pausa -> Opcoes -> Voltar devolve ao overlay com foco em Opcoes,
# sem nunca retomar a partida.
const STAGE_SCENE := "res://scenes/Stage.tscn"

var _retomadas: int = 0


func before_each() -> void:
	Global.platforms = []
	Global.iniciado = false
	_retomadas = 0


func after_each() -> void:
	get_tree().paused = false
	Input.action_release("pause")
	Global.platforms = []
	Global.iniciado = false


func _novo_stage_pausado() -> Node:
	var stage: Node = add_child_autofree(load(STAGE_SCENE).instantiate())
	await wait_frames(2)
	stage._on_Play_button_down()
	await wait_frames(2)
	stage._pausar()
	return stage


func _acao_pause() -> void:
	var ev := InputEventAction.new()
	ev.action = "pause"
	ev.pressed = true
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
	await wait_frames(2)


func _contar_retomada() -> void:
	_retomadas += 1


func test_opcoes_abre_a_tela_oculta_o_overlay_e_mantem_a_pausa() -> void:
	var stage := await _novo_stage_pausado()
	stage.pause_overlay.opcoes.emit()
	assert_true(stage.options_screen.esta_aberta(), "tela de Opcoes aberta")
	assert_false(stage.pause_overlay.visible, "overlay de pausa oculto")
	assert_true(get_tree().paused, "arvore segue pausada")
	assert_true(Global.is_iniciado(), "Global.is_iniciado segue true")


func test_voltar_devolve_o_overlay_com_foco_em_opcoes_e_continuar_retoma() -> void:
	var stage := await _novo_stage_pausado()
	stage.pause_overlay.opcoes.emit()
	stage.options_screen.voltar.emit()
	assert_false(stage.options_screen.esta_aberta(), "tela de Opcoes fechada")
	assert_true(stage.pause_overlay.visible, "overlay visivel")
	assert_eq(stage.pause_overlay.foco_atual(), PauseOverlay.Botao.OPCOES, "foco em Opcoes")
	assert_true(get_tree().paused, "ainda pausado")
	stage.pause_overlay.retomar.emit()
	assert_false(get_tree().paused, "Continuar retoma")


func test_pause_com_a_tela_aberta_nao_retoma() -> void:
	var stage := await _novo_stage_pausado()
	stage.pause_overlay.opcoes.emit()
	await _acao_pause()
	assert_true(get_tree().paused, "pause com Opcoes aberta nao retoma")
	assert_true(Global.is_iniciado(), "partida segue iniciada")
	assert_true(stage.pause_overlay.visible, "pause fechou Opcoes e devolveu o overlay")


func test_overlay_nao_processa_entrada_com_a_tela_aberta() -> void:
	var stage := await _novo_stage_pausado()
	stage.pause_overlay.retomar.connect(_contar_retomada)
	stage.pause_overlay.opcoes.emit()
	var centro: Vector2 = stage.pause_overlay.rect_continuar().get_center()
	var toque := InputEventScreenTouch.new()
	toque.index = 0
	toque.pressed = true
	toque.position = centro
	var consumido_ao_apertar: bool = stage.pause_overlay.tratar_evento(toque)
	toque.pressed = false
	var consumido_ao_soltar: bool = stage.pause_overlay.tratar_evento(toque)
	assert_false(consumido_ao_apertar or consumido_ao_soltar, "overlay nao consome entrada")
	assert_eq(_retomadas, 0, "toque em Continuar nao retoma")
	assert_true(get_tree().paused, "segue pausado")


func test_pausa_terminada_por_outro_caminho_fecha_a_tela_de_opcoes() -> void:
	var stage := await _novo_stage_pausado()
	stage.pause_overlay.opcoes.emit()
	get_tree().paused = false
	await wait_frames(2)
	assert_false(stage.options_screen.esta_aberta(), "tela de Opcoes fechada sozinha")


func test_abrir_do_overlay_sem_argumento_foca_continuar() -> void:
	var overlay: PauseOverlay = add_child_autofree(PauseOverlay.new())
	overlay.abrir(PauseOverlay.Botao.OPCOES)
	overlay.abrir()
	assert_eq(overlay.foco_atual(), PauseOverlay.Botao.CONTINUAR, "abrir() sem argumento foca Continuar")
