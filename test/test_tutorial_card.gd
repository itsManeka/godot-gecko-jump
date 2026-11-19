extends GutTest

# Card do tutorial (TutorialCard): medidas do handoff 12.2 (valores literais da tabela, nao da formula do codigo),
# texto dentro de 148 px medido com a fonte real, variantes toque x teclado, amostras e legenda (12.3), botao Pular
# (aciona ao soltar dentro; 12.4) e reabertura modal com Voltar (12.5).
const PEQUENA := Vector2(180.0, 320.0)
const GRANDE := Vector2(180.0, 400.0)

var _pulou: int = 0
var _voltou: int = 0


func before_each() -> void:
	_pulou = 0
	_voltou = 0


func _novo(
	variante: int = TutorialCard.Variante.TOQUE,
	modo: int = TutorialCard.Modo.PARTIDA,
	tamanho: Vector2 = PEQUENA,
	s_top: float = 0.0
) -> TutorialCard:
	var c := TutorialCard.new()
	add_child_autofree(c)
	c.aplicar_layout(tamanho, Rect2(0.0, s_top, tamanho.x, tamanho.y - s_top))
	c.pular.connect(func() -> void: _pulou += 1)
	c.voltar.connect(func() -> void: _voltou += 1)
	c.abrir(variante, modo)
	return c


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


func _clique(pos: Vector2, pressed: bool) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.position = pos
	e.pressed = pressed
	e.button_index = MOUSE_BUTTON_LEFT
	return e


func _tecla(keycode: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = keycode
	e.physical_keycode = keycode
	e.pressed = true
	return e


func _labels(no: Node) -> Array[Label]:
	var out: Array[Label] = []
	for filho in no.get_children():
		if filho is Label:
			out.append(filho)
		out.append_array(_labels(filho))
	return out


func _textos(c: TutorialCard) -> Array[String]:
	var out: Array[String] = []
	for l in _labels(c):
		out.append(l.text)
	return out


func _controles(no: Node) -> Array[Control]:
	var out: Array[Control] = []
	for filho in no.get_children():
		if filho is Control:
			out.append(filho)
		out.append_array(_controles(filho))
	return out


func _fundo_cor(c: TutorialCard, nome: String) -> Color:
	var p := c.find_child(nome, true, false) as Panel
	return (p.get_theme_stylebox("panel") as StyleBoxFlat).bg_color


func test_c195_fundo_do_card_164x172_termina_em_y_210_nas_duas_alturas() -> void:
	# Teclado: 1 linha de controle (medida original do handoff)
	for tamanho in [PEQUENA, GRANDE]:
		var c := _novo(TutorialCard.Variante.TECLADO, TutorialCard.Modo.PARTIDA, tamanho)
		var r := c.rect_fundo()
		assert_eq(r, Rect2(8, 38, 164, 172), "fundo x[8,172] y[38,210] em %s" % [tamanho])
		assert_eq(r.end.y, 210.0, "termina em y = 210")


func test_c195_toque_cresce_17_px_por_linha_de_controle_extra() -> void:
	for modo in [TouchMode.Modo.A, TouchMode.Modo.B]:
		Global.set_touch_mode(modo, false)
		var c := _novo(TutorialCard.Variante.TOQUE)
		assert_eq(c.rect_fundo(), Rect2(8, 38, 164, 206), "3 linhas de controle: termina em y = 244")
	Global.set_touch_mode(TouchMode.padrao(), false)


func test_c195_s_top_soma_ao_y_do_card_e_do_botao() -> void:
	var c := _novo(TutorialCard.Variante.TECLADO, TutorialCard.Modo.PARTIDA, PEQUENA, 20.0)
	assert_eq(c.rect_fundo(), Rect2(8, 58, 164, 172), "fundo desce s_top")
	assert_eq(c.rect_pular(), Rect2(108, 64, 56, 24), "Pular desce s_top")
	var fundo := c.find_child("Fundo", true, false) as Control
	assert_eq(fundo.global_position.y, 58.0, "o no desenhado desce s_top")


func test_c196_rect_pular_bate_com_o_handoff() -> void:
	var c := _novo()
	var r := c.rect_pular()
	assert_eq(r.position.x, 108.0, "x inicial")
	assert_eq(r.end.x, 164.0, "x final")
	assert_eq(r.position.y, 44.0, "y inicial")
	assert_eq(r.end.y, 68.0, "y final")


func test_c197_nenhuma_linha_de_texto_estoura_148_px_nas_duas_variantes() -> void:
	for variante in [TutorialCard.Variante.TOQUE, TutorialCard.Variante.TECLADO]:
		var c := _novo(variante)
		var textos := _labels(c)
		assert_gt(textos.size(), 10, "o card tem as linhas esperadas")
		for l in textos:
			var largura := TutorialCard.largura_texto(l.text)
			assert_lte(largura, l.size.x, "'%s' cabe na caixa de %s px" % [l.text, l.size.x])
			assert_lte(l.size.x, 148.0, "caixa de '%s' dentro da area de 148" % l.text)
			assert_lte(l.position.x + l.size.x, 164.0, "caixa de '%s' (texto %s px, pos %s, size %s) termina em x <= 164" % [l.text, largura, l.position, l.size])


func test_c198_variante_teclado_mostra_setas_e_espaco() -> void:
	var c := _novo(TutorialCard.Variante.TECLADO)
	assert_eq(c.variante(), TutorialCard.Variante.TECLADO, "variante guardada")
	assert_true(_textos(c).has("Setas e espaco"), "teclado mostra 'Setas e espaco'")
	for modo in [TouchMode.Modo.A, TouchMode.Modo.B]:
		for texto in TutorialCard.linhas_controle_toque(modo):
			assert_false(_textos(c).has(texto), "teclado nao mostra o texto de toque '%s'" % texto)
	for texto in _textos(c):
		assert_false(texto.begins_with("Toque:"), "teclado nao mostra o nome do modo: '%s'" % texto)
		assert_false(texto.contains("Flick") or texto.contains("Joy"), "teclado nao cita nome de modo: '%s'" % texto)


func _texto_controle(c: TutorialCard) -> Array[String]:
	var out: Array[String] = []
	for nome in ["Controle", "Controle1", "Controle2"]:
		var l := c.find_child(nome, true, false) as Label
		if l.visible:
			out.append(l.text)
	return out


func test_c419_variante_toque_mostra_o_texto_do_modo_e_so_ele() -> void:
	for modo in [TouchMode.Modo.A, TouchMode.Modo.B]:
		Global.set_touch_mode(modo, false)
		var c := _novo(TutorialCard.Variante.TOQUE)
		assert_eq(c.variante(), TutorialCard.Variante.TOQUE, "variante guardada")
		assert_eq(_texto_controle(c), TutorialCard.linhas_controle_toque(modo), "modo %s mostra as linhas dele" % TouchMode.nome(modo))
		var outro: int = TouchMode.Modo.B if modo == TouchMode.Modo.A else TouchMode.Modo.A
		for texto in TutorialCard.linhas_controle_toque(outro):
			assert_false(_textos(c).has(texto), "modo %s nao mostra '%s' do outro" % [TouchMode.nome(modo), texto])
		assert_false(_textos(c).has("Setas e espaco"), "toque nao mostra o texto de teclado")
	Global.set_touch_mode(TouchMode.padrao(), false)


func test_c476_texto_de_controle_de_a_difere_do_de_b_e_nenhum_e_vazio() -> void:
	var a := TutorialCard.linhas_controle_toque(TouchMode.Modo.A)
	var b := TutorialCard.linhas_controle_toque(TouchMode.Modo.B)
	assert_gt(a.size(), 0, "A tem texto")
	assert_gt(b.size(), 0, "B tem texto")
	assert_ne(a, b, "A difere de B")
	for linha in a + b:
		assert_ne(linha.strip_edges(), "", "linha de controle nao vazia")


func test_c477_cada_linha_de_controle_cabe_em_148_px_nos_dois_modos() -> void:
	for modo in [TouchMode.Modo.A, TouchMode.Modo.B]:
		for linha in TutorialCard.linhas_controle_toque(modo):
			assert_lte(TutorialCard.largura_texto(linha), TutorialCard.LARGURA_CONTEUDO, "'%s' cabe em 148 px" % linha)


func test_c520_primeira_linha_do_card_e_o_rotulo_do_modo() -> void:
	assert_eq(TutorialCard.linhas_controle_toque(TouchMode.Modo.A)[0], "Toque: Flick", "A: 1a linha = rotulo")
	assert_eq(TutorialCard.linhas_controle_toque(TouchMode.Modo.B)[0], "Toque: Joy invisivel", "B: 1a linha = rotulo")
	for modo in [TouchMode.Modo.A, TouchMode.Modo.B]:
		assert_eq(TutorialCard.linhas_controle_toque(modo)[0], TouchMode.rotulo(modo), "fonte unica TouchMode.rotulo")
		Global.set_touch_mode(modo, false)
		var c := _novo(TutorialCard.Variante.TOQUE)
		assert_eq((c.find_child("Controle", true, false) as Label).text, TouchMode.rotulo(modo), "Controle renderiza o rotulo")
	Global.set_touch_mode(TouchMode.padrao(), false)


func test_c521_card_tem_no_maximo_3_linhas_e_renderiza_exatamente_elas() -> void:
	assert_eq(TutorialCard.LINHAS_CONTROLE_MAX, 3, "teto de 3 linhas")
	for modo in [TouchMode.Modo.A, TouchMode.Modo.B]:
		var linhas := TutorialCard.linhas_controle_toque(modo)
		assert_lte(linhas.size(), TutorialCard.LINHAS_CONTROLE_MAX, "modo %s cabe no teto" % TouchMode.nome(modo))
		Global.set_touch_mode(modo, false)
		var c := _novo(TutorialCard.Variante.TOQUE)
		assert_eq(_texto_controle(c), linhas, "card renderiza exatamente as linhas do modo %s" % TouchMode.nome(modo))
		assert_eq(_texto_controle(c).size(), linhas.size(), "Controle, Controle1, Controle2 visiveis")
	Global.set_touch_mode(TouchMode.padrao(), false)


func test_c522_toda_linha_com_o_nome_cabe_em_148_px_e_o_fundo_segue_em_180x320() -> void:
	for modo in [TouchMode.Modo.A, TouchMode.Modo.B]:
		for linha in TutorialCard.linhas_controle_toque(modo):
			assert_lte(TutorialCard.largura_texto(linha), 148.0, "'%s' cabe em 148 px" % linha)
		Global.set_touch_mode(modo, false)
		var c := _novo(TutorialCard.Variante.TOQUE)
		assert_true(Rect2(0.0, 0.0, 180.0, 320.0).encloses(c.rect_fundo()), "fundo %s dentro de 180x320 com 3 linhas" % c.rect_fundo())
	Global.set_touch_mode(TouchMode.padrao(), false)


func test_c523_b_nao_mostra_zonas_invisiveis_e_a_mantem_sensibilidade() -> void:
	var a := TutorialCard.linhas_controle_toque(TouchMode.Modo.A)
	var b := TutorialCard.linhas_controle_toque(TouchMode.Modo.B)
	assert_eq(a, ["Toque: Flick", "Arraste anda, flick pula", "Sensibilidade: Opcoes"] as Array[String], "linhas do A")
	assert_eq(b, ["Toque: Joy invisivel", "Esquerda segura: anda", "Direita toca: pula"] as Array[String], "linhas do B")
	assert_false(b.has("Zonas invisiveis"), "B sem 'Zonas invisiveis'")
	assert_true(a.has("Sensibilidade: Opcoes"), "A mantem a Sensibilidade")


func test_c528_modo_fora_da_faixa_cai_no_rotulo_do_padrao_no_card() -> void:
	assert_eq(TutorialCard.linhas_controle_toque(2)[0], "Toque: Joy invisivel", "valor 2 cai em B")
	assert_eq(TutorialCard.linhas_controle_toque(99)[0], TouchMode.rotulo(TouchMode.padrao()), "valor 99 cai no padrao")


func test_c478_fundo_dentro_de_180_x_altura_util_com_safe_area_topo() -> void:
	for modo in [TouchMode.Modo.A, TouchMode.Modo.B]:
		Global.set_touch_mode(modo, false)
		for tamanho in [PEQUENA, GRANDE]:
			var c := _novo(TutorialCard.Variante.TOQUE, TutorialCard.Modo.PARTIDA, tamanho, 24.0)
			var util := Rect2(0.0, 0.0, tamanho.x, tamanho.y)
			assert_true(util.encloses(c.rect_fundo()), "fundo %s dentro de %s no modo %s" % [c.rect_fundo(), util, TouchMode.nome(modo)])
	Global.set_touch_mode(TouchMode.padrao(), false)


func test_c479_modo_forcado_altera_o_texto_e_valor_fora_da_faixa_cai_em_b() -> void:
	Global.set_touch_mode(TouchMode.Modo.A, false)
	assert_eq(_texto_controle(_novo()), TutorialCard.linhas_controle_toque(TouchMode.Modo.A), "A forcado")
	Global.set_touch_mode(TouchMode.Modo.B, false)
	assert_eq(_texto_controle(_novo()), TutorialCard.linhas_controle_toque(TouchMode.Modo.B), "B forcado")
	Global.set_touch_mode(99, false)
	assert_eq(_texto_controle(_novo()), TutorialCard.linhas_controle_toque(TouchMode.Modo.B), "fora da faixa cai em B")
	assert_eq(TutorialCard.linhas_controle_toque(2), TutorialCard.linhas_controle_toque(TouchMode.Modo.B), "valor 2 cai em B")
	Global.set_touch_mode(TouchMode.padrao(), false)


func test_c480_pular_nao_intersecta_as_linhas_de_controle() -> void:
	for modo in [TouchMode.Modo.A, TouchMode.Modo.B]:
		Global.set_touch_mode(modo, false)
		var c := _novo()
		for nome in ["Controle", "Controle1", "Controle2"]:
			var l := c.find_child(nome, true, false) as Label
			var r := Rect2(l.position + Vector2(0.0, c.rect_fundo().position.y - 38.0), l.size)
			assert_false(c.rect_pular().intersects(r), "Pular fora da linha %s no modo %s" % [nome, TouchMode.nome(modo)])
	Global.set_touch_mode(TouchMode.padrao(), false)


func test_c199_amostras_diferem_por_marca_e_rotulo_nao_so_por_cor() -> void:
	var c := _novo()
	assert_eq((c.find_child("Amostra0Marca", true, false) as Label).text, "=", "marca da amostra igual")
	assert_eq((c.find_child("Amostra1Marca", true, false) as Label).text, "X", "marca da amostra diferente")
	assert_eq((c.find_child("Amostra0Rotulo", true, false) as Label).text, "igual", "rotulo igual")
	assert_eq((c.find_child("Amostra1Rotulo", true, false) as Label).text, "diferente", "rotulo diferente")
	var gecko_a := _fundo_cor(c, "Amostra0Gecko")
	var gecko_b := _fundo_cor(c, "Amostra1Gecko")
	assert_eq(gecko_a, Enums.get_cor(Enums.COLOR.AMARELO), "gecko amarelo na amostra igual")
	assert_eq(gecko_b, Enums.get_cor(Enums.COLOR.AMARELO), "gecko amarelo na amostra diferente")
	assert_eq(_fundo_cor(c, "Amostra0Plataforma"), Enums.get_cor(Enums.COLOR.AMARELO), "plataforma igual amarela")
	assert_eq(_fundo_cor(c, "Amostra1Plataforma"), Enums.get_cor(Enums.COLOR.AZUL), "plataforma diferente azul")
	var g := c.find_child("Amostra0Gecko", true, false) as Control
	var p := c.find_child("Amostra0Plataforma", true, false) as Control
	assert_eq(g.size, Vector2(12, 16), "miniatura do gecko 12x16")
	assert_eq(p.size, Vector2(32, 8), "plataforma 32x8")


func test_c199_legenda_tem_4_nomes_e_quadrado_12x12_com_as_cores_do_jogo() -> void:
	var c := _novo()
	var nomes := ["amarelo", "verde", "azul", "vermelho"]
	var cores := [Color("#f6db61"), Color("#79cf5a"), Color("#5987e9"), Color("#ec4848")]
	for i in 4:
		assert_eq((c.find_child("Legenda%dNome" % i, true, false) as Label).text, nomes[i], "nome %d" % i)
		var q := c.find_child("Legenda%dQuadro" % i, true, false) as Control
		assert_eq(q.size, Vector2(12, 12), "quadrado %d de 12x12" % i)
		assert_eq(_fundo_cor(c, "Legenda%dQuadro" % i), cores[i], "cor do quadrado %d" % i)
		var estilo := q.get_theme_stylebox("panel") as StyleBoxFlat
		assert_eq(estilo.border_width_left, 1, "contorno de 1 px no quadrado %d" % i)
		assert_eq(estilo.border_color, Color.BLACK, "contorno preto no quadrado %d" % i)
	var q0 := c.find_child("Legenda0Quadro", true, false) as Control
	var q3 := c.find_child("Legenda3Quadro", true, false) as Control
	assert_eq(q0.position, Vector2(16, 151), "amarelo na 1a coluna, 1a linha")
	assert_eq(q3.position, Vector2(90, 168), "vermelho na 2a coluna, 2a linha")


func test_c200_pular_so_aciona_ao_soltar_dentro_do_retangulo() -> void:
	var c := _novo()
	var dentro := Vector2(130, 56)
	assert_true(c.tratar_evento(_toque(dentro, true)), "pressionar dentro e do botao")
	assert_eq(_pulou, 0, "pressionar nao aciona")
	assert_true(c.tratar_evento(_toque(dentro, false)), "soltar dentro consome")
	assert_eq(_pulou, 1, "soltar dentro aciona uma vez")


func test_c200_soltar_fora_ou_arrastar_para_fora_nao_aciona() -> void:
	var c := _novo()
	var dentro := Vector2(130, 56)
	var fora := Vector2(40, 150)
	c.tratar_evento(_toque(dentro, true))
	c.tratar_evento(_toque(fora, false))
	assert_eq(_pulou, 0, "pressionar dentro e soltar fora nao aciona")
	c.tratar_evento(_toque(dentro, true))
	c.tratar_evento(_arrasto(fora))
	c.tratar_evento(_toque(fora, false))
	assert_eq(_pulou, 0, "arrastar para fora e soltar nao aciona")
	c.tratar_evento(_toque(fora, true))
	c.tratar_evento(_toque(dentro, false))
	assert_eq(_pulou, 0, "comecar fora e soltar dentro nao aciona")


func test_c200_clique_de_mouse_tem_a_mesma_regra_do_toque() -> void:
	var c := _novo()
	c.tratar_evento(_clique(Vector2(130, 56), true))
	c.tratar_evento(_clique(Vector2(130, 56), false))
	assert_eq(_pulou, 1, "clique solto dentro aciona")
	c.tratar_evento(_clique(Vector2(130, 56), true))
	c.tratar_evento(_clique(Vector2(10, 300), false))
	assert_eq(_pulou, 1, "clique solto fora nao aciona")


func test_c201_partida_devolve_false_para_toque_fora_de_pular() -> void:
	var c := _novo()
	var fora := Vector2(40, 150)
	assert_false(c.tratar_evento(_toque(fora, true)), "toque no resto do card atravessa")
	assert_false(c.tratar_evento(_toque(fora, false)), "soltar fora atravessa")
	assert_false(c.tratar_evento(_arrasto(fora)), "arrasto fora atravessa")
	assert_false(c.tratar_evento(_tecla(KEY_ENTER)), "tecla nao e do card na partida")


func test_c201_reabertura_consome_todo_toque_fora_do_botao() -> void:
	var c := _novo(TutorialCard.Variante.TOQUE, TutorialCard.Modo.REABERTURA)
	var fora := Vector2(40, 250)
	assert_true(c.tratar_evento(_toque(fora, true)), "pressionar fora e consumido")
	assert_true(c.tratar_evento(_toque(fora, false)), "soltar fora e consumido")
	assert_eq(_voltou, 0, "toque fora nao aciona Voltar")
	assert_true(c.tratar_evento(_toque(Vector2(130, 56), true)), "pressionar no botao e consumido")
	assert_true(c.tratar_evento(_toque(Vector2(130, 56), false)), "soltar no botao e consumido")
	assert_eq(_voltou, 1, "soltar dentro aciona Voltar")
	assert_eq(_pulou, 0, "reabertura nao emite pular")


func test_c201_pular_nao_e_focavel() -> void:
	var c := _novo()
	for ctrl in _controles(c):
		assert_eq(ctrl.focus_mode, Control.FOCUS_NONE, "%s fora da cadeia de foco" % ctrl.name)
		assert_eq(ctrl.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s sem area de toque propria" % ctrl.name)


func test_c202_reabertura_comeca_com_foco_em_voltar_marcado_com_seta() -> void:
	var c := _novo(TutorialCard.Variante.TECLADO, TutorialCard.Modo.REABERTURA)
	var rotulo := (c.find_child("Pular", true, false) as Control).get_child(0) as Label
	assert_eq(rotulo.text, "> Voltar", "marcador > antes do rotulo")
	assert_true((c.find_child("Moldura", true, false) as Control).visible, "moldura de foco visivel")
	assert_lte(TutorialCard.largura_texto(rotulo.text), 56.0, "'> Voltar' cabe no botao de 56 px")
	assert_eq(c.rect_pular(), Rect2(108, 44, 56, 24), "Voltar tem a medida do Pular")


func test_c202_partida_mostra_pular_sem_marcador_nem_moldura() -> void:
	var c := _novo()
	var rotulo := (c.find_child("Pular", true, false) as Control).get_child(0) as Label
	assert_eq(rotulo.text, "Pular", "rotulo Pular")
	assert_false((c.find_child("Moldura", true, false) as Control).visible, "sem moldura de foco")


func test_c202_ui_accept_aciona_voltar_com_tecla_real() -> void:
	var c := _novo(TutorialCard.Variante.TECLADO, TutorialCard.Modo.REABERTURA)
	assert_true(c.tratar_evento(_tecla(KEY_ENTER)), "Enter consumido")
	assert_eq(_voltou, 1, "ui_accept aciona voltar")
	assert_true(c.tratar_evento(_tecla(KEY_SPACE)), "Espaco (ui_accept) consumido")
	assert_eq(_voltou, 2, "Espaco tambem aciona voltar")


func test_c202_esc_e_p_voltam() -> void:
	var c := _novo(TutorialCard.Variante.TECLADO, TutorialCard.Modo.REABERTURA)
	assert_true(c.tratar_evento(_tecla(KEY_ESCAPE)), "Esc consumido")
	assert_true(c.tratar_evento(_tecla(KEY_P)), "P consumido")
	assert_eq(_voltou, 2, "Esc e P acionam voltar")


func test_card_fechado_nao_consome_nada_e_fechar_emite_fechado_apos_o_fade() -> void:
	var c := _novo(TutorialCard.Variante.TOQUE, TutorialCard.Modo.REABERTURA)
	watch_signals(c)
	c.fechar()
	assert_false(c.esta_aberto(), "fechar marca como fechado")
	assert_false(c.tratar_evento(_toque(Vector2(130, 56), true)), "fechado nao consome")
	await wait_seconds(TutorialCard.FADE_S + 0.2)
	assert_false(c.visible, "oculto depois do fade")
	assert_signal_emit_count(c, "fechado", 1)


func test_fechar_imediato_oculta_no_mesmo_frame() -> void:
	var c := _novo()
	c.fechar(true)
	assert_false(c.visible, "oculto sem fade")
	assert_false(c.esta_aberto(), "fechado")
