extends GutTest

# Tela de Opcoes (OptionsScreen): layout do handoff 10.2 (opcao A, sem "Ver tutorial"; valores literais da tabela,
# nao da formula do codigo), arrasto dos sliders (10.3), Voltar, teclado e consumo de toque/mouse.
const PEQUENA := Vector2(180.0, 320.0)
const TEMP_PATH := "user://options_test_screen.cfg"

var _store_original: OptionsStore
var _voltou: int = 0


func before_each() -> void:
	_store_original = Global.opcoes
	DirAccess.remove_absolute(TEMP_PATH)
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	_voltou = 0


func after_each() -> void:
	Global.usar_options_store(_store_original)
	DirAccess.remove_absolute(TEMP_PATH)


func _nova(tamanho: Vector2 = PEQUENA, safe: Rect2 = Rect2()) -> OptionsScreen:
	var o := OptionsScreen.new()
	add_child_autofree(o)
	var area := safe if safe.size != Vector2.ZERO else Rect2(Vector2.ZERO, tamanho)
	o.aplicar_layout(tamanho, area)
	o.voltar.connect(func() -> void: _voltou += 1)
	o.abrir()
	return o


func _acao(nome: String) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = nome
	e.pressed = true
	return e


func _toque(pos: Vector2, pressed: bool, index: int = 0) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.position = pos
	e.pressed = pressed
	e.index = index
	return e


func _arrasto(pos: Vector2, index: int = 0) -> InputEventScreenDrag:
	var e := InputEventScreenDrag.new()
	e.position = pos
	e.index = index
	return e


func _clique(pos: Vector2, pressed: bool, device: int = 0) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.position = pos
	e.pressed = pressed
	e.button_index = MOUSE_BUTTON_LEFT
	e.device = device
	return e


func _db(bus: String) -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus))


func _mudo(bus: String) -> bool:
	return AudioServer.is_bus_mute(AudioServer.get_bus_index(bus))


func test_c199_retangulos_batem_com_a_tabela_do_handoff_10_2_opcao_a() -> void:
	var o := _nova()
	assert_true(o.rect_music() == Rect2(8, 131, 164, 24), "180x320: Music x[8,172] y[131,155]")
	assert_true(o.rect_sfx() == Rect2(8, 182, 164, 24), "180x320: SFX x[8,172] y[182,206]")
	assert_true(o.rect_voltar() == Rect2(34, 218, 112, 32), "180x320: Voltar x[34,146] y[218,250]")


func test_c200_com_safe_area_todos_os_retangulos_ficam_dentro() -> void:
	var safe := Rect2(0, 20, 180, 294)
	var o := _nova(PEQUENA, safe)
	assert_true(o.rect_music() == Rect2(8, 138, 164, 24), "s_top 20 / s_bottom 6: Music y[138,162]")
	assert_true(o.rect_sfx() == Rect2(8, 189, 164, 24), "s_top 20 / s_bottom 6: SFX y[189,213]")
	assert_true(o.rect_voltar() == Rect2(34, 225, 112, 32), "s_top 20 / s_bottom 6: Voltar y[225,257]")
	for r in [o.rect_music(), o.rect_sfx(), o.rect_voltar()]:
		assert_true(safe.encloses(r), "retangulo %s dentro da safe area" % str(r))


func test_c201_arrasto_fora_da_area_mantem_valor_limitado_e_nao_perde_o_ponteiro() -> void:
	var o := _nova()
	var cy := o.rect_music().get_center().y
	o.tratar_evento(_toque(Vector2(90, cy), true))
	assert_eq(o.valor_slider(0), 50, "pressionar na trilha leva o cursor ao ponto tocado")
	o.tratar_evento(_arrasto(Vector2(500, 10)))
	assert_eq(o.valor_slider(0), 100, "fora da area em y e alem de 164 em x: limitado em 100")
	o.tratar_evento(_arrasto(Vector2(-40, 400)))
	assert_eq(o.valor_slider(0), 0, "fora da area em y e antes de 16 em x: limitado em 0")
	o.tratar_evento(_arrasto(Vector2(90, 5)))
	assert_eq(o.valor_slider(0), 50, "eixo vertical ignorado: so o x conta")
	o.tratar_evento(_arrasto(Vector2(500, 10)))
	o.tratar_evento(_toque(Vector2(500, 10), false))
	assert_eq(o.valor_slider(0), 100, "soltar fora da area mantem o valor limitado")
	assert_eq(Global.get_volume_music(), 1.0, "o Global recebe o valor limitado")
	assert_eq(_voltou, 0, "arrastar slider nao emite voltar")


func test_c202_voltar_so_aciona_ao_soltar_dentro() -> void:
	var o := _nova()
	var dentro := o.rect_voltar().get_center()
	o.tratar_evento(_toque(dentro, true))
	assert_eq(_voltou, 0, "pressionar em Voltar ainda nao emite")
	assert_true(o.tratar_evento(_toque(Vector2(5, 5), false)), "soltar fora e consumido")
	assert_eq(_voltou, 0, "soltar fora de Voltar nao emite voltar")
	o.tratar_evento(_toque(dentro, true))
	o.tratar_evento(_toque(dentro, false))
	assert_eq(_voltou, 1, "soltar dentro de Voltar emite voltar")


func test_c203_acao_pause_emite_voltar_e_nao_retomar() -> void:
	var o := _nova()
	assert_true(o.tratar_evento(_acao("pause")), "pause e consumida com a tela aberta")
	assert_eq(_voltou, 1, "pause com a tela aberta emite voltar")
	assert_false(o.has_signal("retomar"), "a tela de Opcoes nao tem sinal de retomar")
	o.fechar()
	assert_false(o.tratar_evento(_acao("pause")), "pause com a tela fechada nao e dela")
	assert_eq(_voltou, 1, "pause com a tela fechada nao emite voltar")


func test_c204_foco_circula_music_sfx_voltar_e_accept_em_voltar_emite() -> void:
	var o := _nova()
	assert_eq(o.foco_atual(), OptionsScreen.Item.MUSIC, "foco inicial em Music")
	o.tratar_evento(_acao("ui_up"))
	assert_eq(o.foco_atual(), OptionsScreen.Item.VOLTAR, "ui_up em Music circula para Voltar")
	o.tratar_evento(_acao("ui_down"))
	assert_eq(o.foco_atual(), OptionsScreen.Item.MUSIC, "ui_down em Voltar circula para Music")
	o.tratar_evento(_acao("ui_down"))
	assert_eq(o.foco_atual(), OptionsScreen.Item.SFX, "ui_down em Music vai a SFX")
	o.tratar_evento(_acao("ui_accept"))
	assert_eq(_voltou, 0, "ui_accept em slider nao emite voltar")
	o.tratar_evento(_acao("ui_down"))
	assert_eq(o.foco_atual(), OptionsScreen.Item.VOLTAR, "ui_down em SFX vai a Voltar")
	o.tratar_evento(_acao("ui_accept"))
	assert_eq(_voltou, 1, "ui_accept em Voltar emite voltar")


func test_passo_de_teclado_ui_left_e_ui_right_limitados() -> void:
	Global.set_volume_music(0.97)
	var o := _nova()
	assert_eq(o.valor_slider(0), 97, "tela abre com o valor do Global")
	o.tratar_evento(_acao("ui_right"))
	assert_eq(o.valor_slider(0), 100, "97 + 5 limita em 100")
	assert_eq(Global.get_volume_music(), 1.0, "teclado aplica no Global")
	Global.set_volume_music(0.03)
	o.abrir()
	o.tratar_evento(_acao("ui_left"))
	assert_eq(o.valor_slider(0), 0, "3 - 5 limita em 0")
	assert_eq(Global.get_volume_music(), 0.0, "0 chega ao Global")


func test_c205_arrasto_atualiza_bus_sfx_em_tempo_real_e_persiste() -> void:
	var o := _nova()
	var cy := o.rect_sfx().get_center().y
	o.tratar_evento(_toque(Vector2(90, cy), true))
	assert_almost_eq(_db("SFX"), -6.02, 0.01, "SFX em 50 vale ~ -6.02 dB durante o arrasto")
	assert_false(_mudo("SFX"), "SFX em 50 nao fica mudo")
	o.tratar_evento(_arrasto(Vector2(10, cy)))
	assert_true(_mudo("SFX"), "SFX em 0 deixa o bus mudo")
	assert_eq(_db("SFX"), OptionsStore.MUTE_DB, "SFX em 0 vale o piso de dB")
	o.tratar_evento(_arrasto(Vector2(90, cy)))
	assert_false(_mudo("SFX"), "SFX volta a soar ao sair de 0")
	assert_eq(OptionsStore.new(TEMP_PATH).load_sfx(), 0.5, "novo store no mesmo caminho le 0.5")
	assert_eq(Global.get_volume_music(), 1.0, "Music nao muda ao arrastar SFX")


func test_c206_toque_no_fundo_consumido_e_mouse_emulado_nao_duplica() -> void:
	var o := _nova()
	assert_true(o.tratar_evento(_toque(Vector2(5, 5), true)), "toque no fundo e consumido")
	assert_true(o.tratar_evento(_toque(Vector2(5, 5), false)), "soltar no fundo e consumido")
	assert_true(o.tratar_evento(_arrasto(Vector2(90, 143))), "arrasto sem toque em slider e consumido")
	assert_eq(_voltou, 0, "fundo nao emite voltar")
	assert_eq(o.valor_slider(0), 100, "fundo nao muda Music")
	assert_eq(o.valor_slider(1), 100, "fundo nao muda SFX")
	var cy := o.rect_music().get_center().y
	var emulado := InputEvent.DEVICE_ID_EMULATION
	assert_false(o.tratar_evento(_clique(Vector2(90, cy), true, emulado)), "mouse emulado nao e da tela")
	assert_false(o.tratar_evento(_clique(Vector2(90, cy), false, emulado)), "soltar mouse emulado nao e da tela")
	assert_eq(o.valor_slider(0), 100, "mouse emulado nao muda o slider (um so efeito por toque)")
	assert_true(o.tratar_evento(_clique(Vector2(90, cy), true)), "clique real de mouse e consumido")
	assert_eq(o.valor_slider(0), 50, "clique real de mouse move o slider")
	o.tratar_evento(_clique(Vector2(90, cy), false))
	assert_eq(_voltou, 0, "clique no slider nao emite voltar")
