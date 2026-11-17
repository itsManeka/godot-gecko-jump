extends GutTest

# Tela de Opcoes (OptionsScreen): layout do handoff 10.2 (com "Ver tutorial" entre SFX e Voltar; valores literais da tabela,
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


func test_c199_retangulos_batem_com_a_tabela_do_handoff_10_2_com_ver_tutorial() -> void:
	var o := _nova()
	assert_true(o.rect_music() == Rect2(8, 91, 164, 24), "180x320: Music x[8,172] y[91,115]")
	assert_true(o.rect_sfx() == Rect2(8, 142, 164, 24), "180x320: SFX x[8,172] y[142,166]")
	assert_true(o.rect_toque() == Rect2(34, 178, 112, 32), "180x320: Toque x[34,146] y[178,210]")
	assert_true(o.rect_ver_tutorial() == Rect2(34, 218, 112, 32), "180x320: Ver tutorial x[34,146] y[218,250]")
	assert_true(o.rect_voltar() == Rect2(34, 258, 112, 32), "180x320: Voltar x[34,146] y[258,290]")


func test_c217_retangulos_de_ver_tutorial_e_voltar_em_320_e_em_400() -> void:
	var o := _nova()
	assert_true(o.rect_ver_tutorial() == Rect2(34, 218, 112, 32), "180x320: Ver tutorial y[218,250]")
	assert_true(o.rect_voltar() == Rect2(34, 258, 112, 32), "180x320: Voltar y[258,290]")
	var alta := _nova(Vector2(180.0, 400.0))
	assert_true(alta.rect_toque() == Rect2(34, 218, 112, 32), "180x400: Toque y[218,250]")
	assert_true(alta.rect_ver_tutorial() == Rect2(34, 258, 112, 32), "180x400: Ver tutorial y[258,290]")
	assert_true(alta.rect_voltar() == Rect2(34, 298, 112, 32), "180x400: Voltar y[298,330]")


func test_c200_com_safe_area_todos_os_retangulos_ficam_dentro() -> void:
	var safe := Rect2(0, 20, 180, 294)
	var o := _nova(PEQUENA, safe)
	assert_true(o.rect_music() == Rect2(8, 98, 164, 24), "s_top 20 / s_bottom 6: Music y[98,122]")
	assert_true(o.rect_sfx() == Rect2(8, 149, 164, 24), "s_top 20 / s_bottom 6: SFX y[149,173]")
	assert_true(o.rect_toque() == Rect2(34, 185, 112, 32), "s_top 20 / s_bottom 6: Toque y[185,217]")
	assert_true(o.rect_ver_tutorial() == Rect2(34, 225, 112, 32), "s_top 20 / s_bottom 6: Ver tutorial y[225,257]")
	assert_true(o.rect_voltar() == Rect2(34, 265, 112, 32), "s_top 20 / s_bottom 6: Voltar y[265,297]")
	for r in [o.rect_music(), o.rect_sfx(), o.rect_toque(), o.rect_ver_tutorial(), o.rect_voltar()]:
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


func test_c204_foco_circula_music_sfx_ver_tutorial_voltar_e_accept_emite() -> void:
	var o := _nova()
	var tutoriais: Array[int] = [0]
	o.ver_tutorial.connect(func() -> void: tutoriais[0] += 1)
	assert_eq(o.foco_atual(), OptionsScreen.Item.MUSIC, "foco inicial em Music")
	o.tratar_evento(_acao("ui_up"))
	assert_eq(o.foco_atual(), OptionsScreen.Item.VOLTAR, "ui_up em Music circula para Voltar")
	o.tratar_evento(_acao("ui_down"))
	assert_eq(o.foco_atual(), OptionsScreen.Item.MUSIC, "ui_down em Voltar circula para Music")
	o.tratar_evento(_acao("ui_down"))
	assert_eq(o.foco_atual(), OptionsScreen.Item.SFX, "ui_down em Music vai a SFX")
	o.tratar_evento(_acao("ui_accept"))
	assert_eq(_voltou, 0, "ui_accept em slider nao emite voltar")
	assert_eq(tutoriais[0], 0, "ui_accept em slider nao emite ver_tutorial")
	o.tratar_evento(_acao("ui_down"))
	assert_eq(o.foco_atual(), OptionsScreen.Item.TOQUE, "ui_down em SFX vai a Toque")
	o.tratar_evento(_acao("ui_accept"))
	assert_eq(_voltou, 0, "ui_accept em Toque nao emite voltar")
	assert_eq(tutoriais[0], 0, "ui_accept em Toque nao emite ver_tutorial")
	o.tratar_evento(_acao("ui_down"))
	assert_eq(o.foco_atual(), OptionsScreen.Item.VER_TUTORIAL, "ui_down em Toque vai a Ver tutorial")
	o.tratar_evento(_acao("ui_accept"))
	assert_eq(tutoriais[0], 1, "ui_accept em Ver tutorial emite ver_tutorial")
	assert_eq(_voltou, 0, "ui_accept em Ver tutorial nao emite voltar")
	o.tratar_evento(_acao("ui_down"))
	assert_eq(o.foco_atual(), OptionsScreen.Item.VOLTAR, "ui_down em Ver tutorial vai a Voltar")
	o.tratar_evento(_acao("ui_accept"))
	assert_eq(_voltou, 1, "ui_accept em Voltar emite voltar")
	assert_eq(tutoriais[0], 1, "ui_accept em Voltar nao emite ver_tutorial")


func test_c218_ver_tutorial_so_aciona_ao_soltar_dentro() -> void:
	var o := _nova()
	var tutoriais: Array[int] = [0]
	o.ver_tutorial.connect(func() -> void: tutoriais[0] += 1)
	var dentro := o.rect_ver_tutorial().get_center()
	o.tratar_evento(_toque(dentro, true))
	assert_eq(tutoriais[0], 0, "pressionar em Ver tutorial ainda nao emite")
	o.tratar_evento(_toque(Vector2(5, 5), false))
	assert_eq(tutoriais[0], 0, "soltar fora nao emite ver_tutorial")
	o.tratar_evento(_toque(dentro, true))
	o.tratar_evento(_toque(dentro, false))
	assert_eq(tutoriais[0], 1, "soltar dentro emite ver_tutorial")
	assert_eq(_voltou, 0, "Ver tutorial nao emite voltar")


func test_abrir_com_foco_inicial_em_ver_tutorial() -> void:
	var o := _nova()
	o.abrir(OptionsScreen.Item.VER_TUTORIAL)
	assert_eq(o.foco_atual(), OptionsScreen.Item.VER_TUTORIAL, "abrir(foco) devolve o foco a Ver tutorial")


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
	o.tratar_evento(_toque(Vector2(90, cy), false))
	assert_eq(OptionsStore.new(TEMP_PATH).load_sfx(), 0.5, "novo store no mesmo caminho le 0.5")
	assert_eq(Global.get_volume_music(), 1.0, "Music nao muda ao arrastar SFX")


func test_arrasto_aplica_no_bus_mas_so_grava_ao_soltar() -> void:
	var o := _nova()
	var cy := o.rect_sfx().get_center().y
	o.tratar_evento(_toque(Vector2(90, cy), true))
	o.tratar_evento(_arrasto(Vector2(60, cy)))
	o.tratar_evento(_arrasto(Vector2(40, cy)))
	o.tratar_evento(_arrasto(Vector2(30, cy)))
	assert_lt(_db("SFX"), -6.0, "o bus ja segue o arrasto")
	assert_eq(OptionsStore.new(TEMP_PATH).load_sfx(), 1.0, "durante o arrasto o cfg ainda guarda o valor antigo")
	o.tratar_evento(_toque(Vector2(30, cy), false))
	assert_eq(OptionsStore.new(TEMP_PATH).load_sfx(), Global.get_volume_sfx(), "ao soltar o cfg guarda o valor novo")
	assert_lt(Global.get_volume_sfx(), 0.5, "o valor novo veio do arrasto")


func test_fechar_com_dedo_pressionado_grava_o_valor_arrastado() -> void:
	var o := _nova()
	var cy := o.rect_sfx().get_center().y
	o.tratar_evento(_toque(Vector2(90, cy), true))
	o.tratar_evento(_arrasto(Vector2(10, cy)))
	assert_eq(OptionsStore.new(TEMP_PATH).load_sfx(), 1.0, "antes de fechar o cfg ainda guarda o valor antigo")
	o.fechar()
	assert_eq(OptionsStore.new(TEMP_PATH).load_sfx(), 0.0, "fechar no meio do gesto grava o valor arrastado")


func test_app_perde_foco_no_meio_do_arrasto_grava_o_valor_arrastado() -> void:
	var o := _nova()
	var cy := o.rect_sfx().get_center().y
	o.tratar_evento(_toque(Vector2(90, cy), true))
	o.tratar_evento(_arrasto(Vector2(10, cy)))
	assert_eq(OptionsStore.new(TEMP_PATH).load_sfx(), 1.0, "durante o arrasto o cfg ainda guarda o valor antigo")
	o.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_eq(OptionsStore.new(TEMP_PATH).load_sfx(), 0.0, "perder o foco no meio do gesto grava o valor arrastado")


func test_pedido_de_fechar_janela_no_meio_do_arrasto_grava_o_valor_arrastado() -> void:
	var o := _nova()
	var cy := o.rect_sfx().get_center().y
	o.tratar_evento(_toque(Vector2(90, cy), true))
	o.tratar_evento(_arrasto(Vector2(10, cy)))
	o.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	assert_eq(OptionsStore.new(TEMP_PATH).load_sfx(), 0.0, "fechar a janela no meio do gesto grava o valor arrastado")


func test_notificacao_sem_arrasto_nao_grava_nada() -> void:
	var o := _nova()
	o.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	o.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	assert_false(FileAccess.file_exists(TEMP_PATH), "sem pendencia a notificacao nao cria o cfg")


func test_passo_de_teclado_grava_na_hora() -> void:
	Global.set_volume_music(0.5)
	var o := _nova()
	o.tratar_evento(_acao("ui_right"))
	assert_almost_eq(OptionsStore.new(TEMP_PATH).load_music(), 0.55, 0.0001, "ui_right grava 55 sem esperar soltar")


func _tocar_seletor(o: OptionsScreen) -> void:
	var centro := o.rect_toque().get_center()
	o.tratar_evento(_toque(centro, true))
	o.tratar_evento(_toque(centro, false))


func test_c408_tocar_o_seletor_vai_de_a_para_b() -> void:
	Global.set_touch_mode(TouchMode.Modo.A, false)
	var o := _nova()
	assert_eq(o.texto_toque(), "Toque: A", "abre mostrando o modo corrente")
	_tocar_seletor(o)
	assert_eq(Global.get_touch_mode(), TouchMode.Modo.B, "A -> B no Global")
	assert_eq(o.texto_toque(), "Toque: B", "rotulo mostra Toque: B")


func test_c409_tocar_o_seletor_vai_de_b_para_a() -> void:
	Global.set_touch_mode(TouchMode.Modo.B, false)
	var o := _nova()
	_tocar_seletor(o)
	assert_eq(Global.get_touch_mode(), TouchMode.Modo.A, "B -> A no Global")
	assert_eq(o.texto_toque(), "Toque: A", "rotulo mostra Toque: A")
	assert_eq(_voltou, 0, "o seletor nao emite voltar")


func test_c452_duas_pulsacoes_voltam_de_b_para_b_e_gravam_no_store() -> void:
	Global.set_touch_mode(TouchMode.Modo.B, false)
	var o := _nova()
	_tocar_seletor(o)
	var salvo: Variant = OptionsStore.new(TEMP_PATH).load_value(TouchMode.SECTION, TouchMode.KEY, TouchMode.SEM_VALOR)
	assert_eq(int(salvo), int(TouchMode.Modo.A), "C452: B -> A gravado no store temporario")
	_tocar_seletor(o)
	assert_eq(Global.get_touch_mode(), TouchMode.Modo.B, "C452: A -> B volta ao inicio")
	assert_eq(o.texto_toque(), "Toque: B", "C452: rotulo volta a Toque: B")
	salvo = OptionsStore.new(TEMP_PATH).load_value(TouchMode.SECTION, TouchMode.KEY, TouchMode.SEM_VALOR)
	assert_eq(int(salvo), int(TouchMode.Modo.B), "C452: B gravado no store temporario")


func test_c411_ui_accept_cicla_e_reabrir_mostra_o_modo_salvo() -> void:
	Global.set_touch_mode(TouchMode.Modo.A, false)
	var o := _nova()
	o.abrir(OptionsScreen.Item.TOQUE)
	o.tratar_evento(_acao("ui_accept"))
	assert_eq(o.texto_toque(), "Toque: B", "ui_accept com foco no item vai de A para B")
	var salvo: Variant = OptionsStore.new(TEMP_PATH).load_value(TouchMode.SECTION, TouchMode.KEY, TouchMode.SEM_VALOR)
	assert_eq(int(salvo), int(TouchMode.Modo.B), "o modo ficou gravado no store temporario")
	Global.usar_options_store(OptionsStore.new(TEMP_PATH))
	o.fechar()
	o.abrir()
	assert_eq(o.texto_toque(), "Toque: B", "reabrir a tela mostra o modo salvo")


func test_c412_bloco_de_5_itens_cabe_em_180x320_sem_sobrepor_voltar() -> void:
	var tela := Rect2(0.0, 0.0, 180.0, 320.0)
	var o := _nova()
	assert_true(tela.encloses(o.rect_toque()), "Toque dentro de 180x320")
	assert_true(tela.encloses(o.rect_voltar()), "Voltar dentro de 180x320")
	assert_false(o.rect_toque().intersects(o.rect_voltar()), "Toque nao sobrepoe Voltar")
	assert_false(o.rect_toque().intersects(o.rect_ver_tutorial()), "Toque nao sobrepoe Ver tutorial")
	assert_false(o.rect_toque().intersects(o.rect_sfx()), "Toque nao sobrepoe SFX")
	var safe := Rect2(0, 20, 180, 294)
	var com_safe := _nova(PEQUENA, safe)
	assert_true(safe.encloses(com_safe.rect_music()), "Music dentro da safe area")
	assert_true(safe.encloses(com_safe.rect_toque()), "Toque dentro da safe area")
	assert_true(safe.encloses(com_safe.rect_voltar()), "Voltar dentro da safe area")
	assert_false(com_safe.rect_toque().intersects(com_safe.rect_voltar()), "com safe area: Toque nao sobrepoe Voltar")
	var largura := UiHelpers.FONTE.get_string_size("> Toque: B", HORIZONTAL_ALIGNMENT_LEFT, -1, OptionsScreen.TAMANHO_TEXTO).x
	assert_lte(largura, o.rect_toque().size.x, "'> Toque: B' cabe no botao")


func test_c414_foco_percorre_os_5_itens_na_ordem_e_esc_continua_voltando() -> void:
	var o := _nova()
	var ordem: Array[int] = [OptionsScreen.Item.SFX, OptionsScreen.Item.TOQUE, OptionsScreen.Item.VER_TUTORIAL, OptionsScreen.Item.VOLTAR, OptionsScreen.Item.MUSIC]
	for esperado in ordem:
		o.tratar_evento(_acao("ui_down"))
		assert_eq(o.foco_atual(), esperado, "ui_down segue a ordem Music, SFX, Toque, Ver tutorial, Voltar")
	o.tratar_evento(_acao("pause"))
	assert_eq(_voltou, 1, "Esc continua emitindo voltar")
	var dentro := o.rect_voltar().get_center()
	o.tratar_evento(_toque(dentro, true))
	o.tratar_evento(_toque(dentro, false))
	assert_eq(_voltou, 2, "Voltar por toque continua igual")


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
