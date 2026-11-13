extends GutTest

# Arbitragem de toque com o card do tutorial aberto (handoff 7.3, 8.1, 8.4, 12.4): zona morta do Pular na camada de
# toque, dica que espera o card fechar e flags "tutorial visto" x "dica mostrada" independentes. Os toques entram direto
# em `_input` de TouchControls/TouchHint (o card consumiria o toque no Pular antes, via cadeia de entrada): o que se
# prova aqui e a regra da propria camada, nao so a ordem dos nos.
const STAGE_SCENE := "res://scenes/Stage.tscn"
const TEST_PATH := "user://test_stage_tutorial_toque.cfg"

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
	for acao in ["jump", "ui_left", "ui_right"]:
		Input.action_release(acao)
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


# Stage em partida em curso (card aberto se a flag "visto" esta ausente; dica visivel se "mostrada" esta ausente)
func _stage_em_curso() -> Node:
	var stage: Node = add_child_autofree(load(STAGE_SCENE).instantiate())
	await wait_frames(2)
	stage._on_Play_button_down()
	await wait_process_frames(2)
	return stage


func _toque(pos: Vector2, pressionado: bool = true) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.position = pos
	e.pressed = pressionado
	return e


func _fade_iniciado(hint: TouchHint) -> bool:
	return hint._fade != null and hint._fade.is_valid()


func test_c210_toque_no_pular_com_card_aberto_nao_vira_gesto_nem_inicia_fade() -> void:
	var stage := await _stage_em_curso()
	assert_true(stage.tutorial_card.esta_aberto(), "card aberto")
	assert_true(stage.touch_hint.esta_mostrando(), "dica visivel")
	var pos: Vector2 = stage.tutorial_card.rect_pular().get_center()
	stage.touch_controls._input(_toque(pos))
	stage.touch_hint._input(_toque(pos))
	assert_false(stage.touch_controls.classificador.ativo(), "o toque no Pular e zona morta: nao vira pulo nem andar")
	assert_false(_fade_iniciado(stage.touch_hint), "a dica nao inicia o fade")
	assert_true(stage.touch_hint.esta_mostrando(), "a dica segue visivel")


func test_c211_toque_no_resto_do_card_vira_tap_e_nao_apaga_a_dica() -> void:
	var stage := await _stage_em_curso()
	assert_true(stage.tutorial_card.esta_aberto(), "card aberto")
	var pos: Vector2 = stage.tutorial_card.rect_fundo().position + Vector2(12.0, 100.0)
	assert_false(stage.tutorial_card.rect_pular().has_point(pos), "ponto fora do Pular")
	watch_signals(stage.touch_controls)
	stage.touch_controls._input(_toque(pos))
	stage.touch_hint._input(_toque(pos))
	assert_true(stage.touch_controls.classificador.ativo(), "o toque no card chega ao classificador (card nao modal)")
	stage.touch_controls._input(_toque(pos, false))
	assert_signal_emitted_with_parameters(
		stage.touch_controls, "gesto_concluido", [TouchClassifier.Resultado.TAP, TouchClassifier.Lado.ESQUERDA]
	)
	assert_false(_fade_iniciado(stage.touch_hint), "toque no card nao inicia o fade da dica")
	assert_true(stage.touch_hint.esta_mostrando(), "a dica segue visivel")


func test_c212_apos_fechar_o_card_o_1o_toque_inicia_o_fade_e_o_pular_volta_a_ser_toque_de_jogo() -> void:
	var stage := await _stage_em_curso()
	var pular: Rect2 = stage.tutorial_card.rect_pular()
	assert_true(stage.touch_controls.classificador.zonas_mortas.has(pular), "aberto: Pular e zona morta")
	stage.tutorial_card.pular.emit()
	assert_false(stage.tutorial_card.esta_aberto(), "card fechado")
	assert_false(stage.touch_controls.classificador.zonas_mortas.has(pular), "fechado: Pular deixa de ser zona morta")
	assert_eq(stage.touch_controls.classificador.zonas_mortas.size(), 1, "so o botao de pausa segue morto")
	assert_false(_fade_iniciado(stage.touch_hint), "fechar o card sozinho nao inicia o fade")
	stage.touch_controls._input(_toque(pular.get_center()))
	assert_true(stage.touch_controls.classificador.ativo(), "toque no antigo Pular agora e toque de jogo")
	stage.touch_hint._input(_toque(Vector2(20.0, 200.0)))
	assert_true(_fade_iniciado(stage.touch_hint), "1o toque de jogo apos o fechamento inicia o fade")


func test_c212_zona_morta_do_pular_acompanha_s_top_no_layout() -> void:
	var stage := await _stage_em_curso()
	stage.apply_layout(Vector2(180.0, 320.0), Rect2(Vector2(10.0, 24.0), Vector2(160.0, 280.0)))
	var pular: Rect2 = stage.tutorial_card.rect_pular()
	assert_eq(pular.position.y, 44.0 + 24.0, "Pular deslocado por s_top")
	assert_true(stage.touch_controls.classificador.zonas_mortas.has(pular), "zona morta recalculada no layout")


func test_c213_pausa_com_card_aberto_overlay_consome_o_pular_e_o_card_volta_ao_retomar() -> void:
	var stage := await _stage_em_curso()
	assert_true(stage.tutorial_card.esta_aberto(), "card aberto")
	var pos: Vector2 = stage.tutorial_card.rect_pular().get_center()
	assert_true(stage._pausar(), "pausa com o card aberto")
	assert_false(stage.tutorial_card.tratar_evento(_toque(pos)), "pausado: o card nao consome o Pular")
	assert_true(stage.pause_overlay.tratar_evento(_toque(pos)), "o overlay consome tambem o toque no Pular")
	assert_true(stage.tutorial_card.esta_aberto(), "o card segue aberto na pausa")
	assert_false(stage.tutorial_card.visible, "pausado: o card fica escondido pelo fundo da pausa (12.5)")
	stage._abrir_opcoes_da_pausa()
	assert_false(stage.tutorial_card.visible, "Opcoes da pausa: o card segue oculto")
	stage._abrir_tutorial_revisao()
	stage._fechar_tutorial_revisao()
	assert_true(get_tree().paused, "a volta da reabertura segue pausada")
	assert_false(stage.tutorial_card.visible, "volta da reabertura a Opcoes da pausa: o card segue oculto")
	assert_true(stage.tutorial_card.esta_aberto(), "o card segue aberto (nao fechou)")
	stage._retomar()
	assert_false(get_tree().paused, "retomou")
	assert_true(stage.tutorial_card.esta_aberto(), "o card volta ao estado anterior")
	assert_true(stage.tutorial_card.visible, "retomou: o card volta visivel")
	assert_true(stage.tutorial_card.tratar_evento(_toque(pos)), "apos retomar o Pular volta a ser do card")
	assert_true(stage.touch_controls.classificador.zonas_mortas.has(stage.tutorial_card.rect_pular()), "zona morta mantida")


func test_c213_card_fechado_antes_da_pausa_segue_invisivel_ao_retomar() -> void:
	var stage := await _stage_em_curso()
	stage.tutorial_card.fechar(true)
	assert_true(stage._pausar(), "pausa com o card fechado")
	assert_false(stage.tutorial_card.visible, "pausado: sem card")
	stage._retomar()
	assert_false(stage.tutorial_card.esta_aberto(), "segue fechado")
	assert_false(stage.tutorial_card.visible, "retomou: o card fechado nao reaparece")


func test_c214_tutorial_visto_e_dica_nao_mostrada_sem_card_e_dica_segue() -> void:
	Global.tutorial_visto_espelho = true
	var stage := await _stage_em_curso()
	assert_false(stage.tutorial_card.esta_aberto(), "tutorial visto: sem card")
	assert_true(stage.touch_hint.esta_mostrando(), "dica nao mostrada: a dica aparece")
	stage.touch_hint._input(_toque(Vector2(20.0, 200.0)))
	assert_true(_fade_iniciado(stage.touch_hint), "sem card o 1o toque inicia o fade (8.4)")


func test_c215_dica_mostrada_e_tutorial_nao_visto_card_sem_dica() -> void:
	Global.dica_toque_mostrada = true
	var stage := await _stage_em_curso()
	assert_true(stage.tutorial_card.esta_aberto(), "tutorial nao visto: card aparece")
	assert_false(stage.touch_hint.esta_mostrando(), "dica ja mostrada: sem dica")


func test_c216_ambas_ausentes_card_e_dica_juntos_ambas_setadas_nenhum() -> void:
	var stage := await _stage_em_curso()
	assert_true(stage.tutorial_card.esta_aberto(), "ambas ausentes: card")
	assert_true(stage.touch_hint.esta_mostrando(), "ambas ausentes: dica")
	remove_child(stage)
	stage.free()
	Global.iniciado = false
	Global.tutorial_visto_espelho = true
	Global.dica_toque_mostrada = true
	var outra := await _stage_em_curso()
	assert_false(outra.tutorial_card.esta_aberto(), "ambas setadas: sem card")
	assert_false(outra.touch_hint.esta_mostrando(), "ambas setadas: sem dica")
