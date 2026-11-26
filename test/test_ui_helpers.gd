extends GutTest
## Helper de UI: valores esperados lidos do HEAD de OptionsScreen/OpcoesBotao/PauseOverlay (literais, nao calculados).

const COR_BOTAO: Color = Color("#5b8a4a")
const PRETO: Color = Color(0.0, 0.0, 0.0, 1.0)


func test_dedo_mouse_e_1000() -> void:
	assert_eq(UiHelpers.DEDO_MOUSE, 1000)


## Medicao (02-impact.md): unitsPerEm 1024 e grade de 64 unidades = 1/16 em, logo 16 px por pixel da fonte.
func test_fonte_nativo_e_16_e_tamanhos_ui_sao_multiplos_inteiros() -> void:
	assert_eq(UiHelpers.FONTE_NATIVO, 16)
	assert_gt(UiHelpers.TAMANHOS_UI.size(), 0)
	for t in UiHelpers.TAMANHOS_UI:
		assert_eq(t % 16, 0, "tamanho %d fora da grade nativa de 16" % t)


func test_tamanhos_ui_so_32_e_64() -> void:
	var esperado: Array[int] = [32, 64]
	assert_eq(UiHelpers.TAMANHOS_UI, esperado, "TAMANHOS_UI deve ser [32, 64]")
	for fora in [16, 20, 26, 36]:
		assert_false(UiHelpers.TAMANHOS_UI.has(fora), "tamanho %d fora da escala 2x" % fora)


func test_papeis_da_escala_ui_em_2x() -> void:
	assert_eq(UiHelpers.TAMANHO_TITULO, 64, "TAMANHO_TITULO")
	assert_eq(UiHelpers.TAMANHO_BOTAO, 64, "TAMANHO_BOTAO")
	assert_eq(UiHelpers.TAMANHO_TEXTO, 32, "TAMANHO_TEXTO")
	assert_eq(UiHelpers.RAIO_BOTAO, 8, "RAIO_BOTAO")


func test_estilo_opcoes_botao_tem_raio_8_borda_e_cor() -> void:
	var s: StyleBoxFlat = UiHelpers.estilo_opcoes(COR_BOTAO, 2, PRETO, COR_BOTAO)
	assert_eq(s.bg_color, COR_BOTAO)
	assert_eq(s.border_color, PRETO)
	assert_eq(s.border_width_left, 2)
	assert_eq(s.border_width_top, 2)
	assert_eq(s.border_width_right, 2)
	assert_eq(s.border_width_bottom, 2)
	assert_eq(s.corner_radius_top_left, 8)
	assert_eq(s.corner_radius_bottom_right, 8)


func test_estilo_opcoes_borda_1_do_botao_mantem_raio_8() -> void:
	var s: StyleBoxFlat = UiHelpers.estilo_opcoes(COR_BOTAO, 1, PRETO, COR_BOTAO)
	assert_eq(s.border_width_left, 1)
	assert_eq(s.corner_radius_top_right, 8)


func test_estilo_opcoes_outros_fundos_ficam_retos() -> void:
	var fundos: Array[Color] = [Color(0, 0, 0, 0), Color(0, 0, 0, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0.6)]
	for f in fundos:
		var s: StyleBoxFlat = UiHelpers.estilo_opcoes(f, 1, PRETO, COR_BOTAO)
		assert_eq(s.corner_radius_top_left, 0, "fundo %s" % f)
		assert_eq(s.corner_radius_bottom_left, 0, "fundo %s" % f)
		assert_eq(s.bg_color, f)


func test_estilo_opcoes_botao_sem_borda_fica_reto() -> void:
	var s: StyleBoxFlat = UiHelpers.estilo_opcoes(COR_BOTAO, 0, PRETO, COR_BOTAO)
	assert_eq(s.corner_radius_top_left, 0)
	assert_eq(s.border_width_left, 0)


func test_estilo_raio_explicito_para_pausa_e_opcoes_botao() -> void:
	var pausa: StyleBoxFlat = UiHelpers.estilo(Color(0, 0, 0, 0), 2, PRETO, 4)
	assert_eq(pausa.corner_radius_top_left, 4)
	assert_eq(pausa.border_width_top, 2)
	var reto: StyleBoxFlat = UiHelpers.estilo(COR_BOTAO, 1, PRETO, 0)
	assert_eq(reto.corner_radius_top_left, 0)


func test_novo_label_desenho_do_pause_overlay() -> void:
	var l: Label = autofree(UiHelpers.novo_label("Pausado", 32, 2))
	assert_eq(l.text, "Pausado")
	assert_eq(l.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(l.focus_mode, Control.FOCUS_NONE)
	assert_eq(l.horizontal_alignment, HORIZONTAL_ALIGNMENT_CENTER)
	assert_eq(l.vertical_alignment, VERTICAL_ALIGNMENT_CENTER)
	assert_eq(l.get_theme_font("font"), load("res://fonts/alterebro-pixel-font.ttf"))
	assert_eq(l.get_theme_font_size("font_size"), 32)
	assert_eq(l.get_theme_color("font_color"), Color(1.0, 1.0, 1.0, 1.0))
	assert_eq(l.get_theme_color("font_outline_color"), PRETO)
	assert_eq(l.get_theme_constant("outline_size"), 2)


func test_novo_label_alinhamento_explicito_das_opcoes() -> void:
	var esq: Label = autofree(UiHelpers.novo_label("Music", 16, 1, HORIZONTAL_ALIGNMENT_LEFT))
	var dir: Label = autofree(UiHelpers.novo_label("", 16, 1, HORIZONTAL_ALIGNMENT_RIGHT))
	assert_eq(esq.horizontal_alignment, HORIZONTAL_ALIGNMENT_LEFT)
	assert_eq(dir.horizontal_alignment, HORIZONTAL_ALIGNMENT_RIGHT)
	assert_eq(esq.get_theme_font_size("font_size"), 16)
	assert_eq(esq.get_theme_constant("outline_size"), 1)
