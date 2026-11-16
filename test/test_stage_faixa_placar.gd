extends GutTest
## f472 T3: faixa de fundo atras do bloco Last/Best do menu (legibilidade sobre as plataformas da paleta).

const STAGE: String = "res://scenes/Stage.tscn"
const LIMIAR_AA: float = 4.5
# Paleta de plataformas (Enums.gd / CLAUDE.md do eco); amarelo e o pior caso
const PLATAFORMAS: Array[String] = ["#f6db61", "#79cf5a", "#5987e9", "#ec4848"]

var _stage: Node


func before_each() -> void:
	Global.tutorial_visto_espelho = true
	Global.platforms = []
	Global.iniciado = false
	_stage = add_child_autofree(load(STAGE).instantiate())
	var scroll: Node = _stage.get_node("ScrollLevel")
	_stage.remove_child(scroll)
	scroll.free()
	_stage.apply_layout(Vector2(180.0, 320.0), Rect2(0.0, 0.0, 180.0, 320.0))


func after_each() -> void:
	Global.platforms = []
	Global.iniciado = false


func _no(nome: String) -> Control:
	return _stage.get_node("CanvasLayer/" + nome) as Control


func _canal_linear(c: float) -> float:
	return c / 12.92 if c <= 0.03928 else pow((c + 0.055) / 1.055, 2.4)


# Luminancia relativa WCAG
func _luminancia(c: Color) -> float:
	return 0.2126 * _canal_linear(c.r) + 0.7152 * _canal_linear(c.g) + 0.0722 * _canal_linear(c.b)


func _razao(a: Color, b: Color) -> float:
	var la := _luminancia(a)
	var lb := _luminancia(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


# Cor da faixa composta (alfa) sobre a plataforma
func _composta(faixa: Color, plataforma: Color) -> Color:
	return Color(
		faixa.r * faixa.a + plataforma.r * (1.0 - faixa.a),
		faixa.g * faixa.a + plataforma.g * (1.0 - faixa.a),
		faixa.b * faixa.a + plataforma.b * (1.0 - faixa.a),
		1.0
	)


# C350: a faixa existe, usa o fundo do overlay de pausa e cobre Last e Best.
func test_c350_faixa_existe_com_cor_da_pausa_e_cobre_last_e_best() -> void:
	var faixa := _stage.get_node_or_null("CanvasLayer/FaixaPlacar") as ColorRect
	assert_not_null(faixa, "faixa de fundo do placar existe")
	if faixa == null:
		return
	assert_eq(faixa.color, PauseOverlay.COR_FUNDO, "cor/alfa da faixa = COR_FUNDO do PauseOverlay")
	var r := faixa.get_global_rect()
	assert_true(r.encloses(_no("Last").get_global_rect()), "faixa cobre Last")
	assert_true(r.encloses(_no("Best").get_global_rect()), "faixa cobre Best")


# C351: contraste texto x faixa composta sobre cada plataforma >= 4.5:1 (WCAG AA); amarelo e o pior caso.
func test_c351_contraste_do_texto_sobre_a_faixa_em_cada_plataforma() -> void:
	var faixa := _stage.get_node("CanvasLayer/FaixaPlacar") as ColorRect
	var texto: Color = _no("Last").get_theme_color("font_color")
	for hex in PLATAFORMAS:
		var fundo := _composta(faixa.color, Color(hex))
		var razao := _razao(texto, fundo)
		assert_gte(razao, LIMIAR_AA, "contraste %s (razao %.2f)" % [hex, razao])


# C352: contorno do texto continua em 1 px, a 16 px.
func test_c352_contorno_do_placar_permanece_1px_a_16px() -> void:
	for nome in ["Last", "Best"]:
		var l := _no(nome)
		assert_eq(l.get_theme_constant("outline_size"), 1, "%s outline 1 px" % nome)
		assert_eq(l.get_theme_font_size("font_size"), 16, "%s fonte 16 px" % nome)


# C353: a faixa nao intercepta toque e nao encosta no Play nem no botao Opcoes.
func test_c353_faixa_ignora_mouse_e_nao_sobrepoe_play_nem_opcoes() -> void:
	var faixa := _no("FaixaPlacar")
	assert_eq(faixa.mouse_filter, Control.MOUSE_FILTER_IGNORE, "faixa ignora mouse/toque")
	var r := faixa.get_global_rect()
	assert_false(r.intersects(_no("Play").get_global_rect()), "faixa x Play")
	assert_true(_no("Play").visible, "Play segue visivel")
	assert_false(r.intersects(_stage.opcoes_botao.rect_botao()), "faixa x botao Opcoes")
