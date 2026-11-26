extends GutTest

# O jogo e so retrato, largura logica sempre 360 (ADR 0002, ADR 0015). Janela larga ganha barras laterais
# (aspect keep_width), nao area de jogo mais larga. Le os ajustes de stretch do projeto.

func test_stretch_aspect_keep_width() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "keep_width",
		"aspect deve ser keep_width: largura logica fixa em 360, altura expande")

func test_stretch_mode_viewport_e_escala_inteira() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "viewport",
		"mode deve continuar viewport")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/scale_mode"), "integer",
		"scale_mode deve continuar integer")

# C815: viewport base 360x640 no projeto e na suite GUT (content_scale_size fixado pelo gut_pre_run).
func test_viewport_base_360x640_no_projeto_e_na_suite() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 360,
		"viewport_width base = 360")
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 640,
		"viewport_height base = 640")
	var raiz := Engine.get_main_loop().root as Window
	assert_eq(raiz.content_scale_size, Vector2i(360, 640),
		"gut_pre_run fixa content_scale_size em 360x640")

# C142/C815: fonte unica da largura jogavel; gerador e Player leem dela.
func test_largura_jogavel_de_fonte_unica() -> void:
	assert_eq(PlayArea.LARGURA, 360.0, "largura jogavel = 360")
	assert_eq(MovingRowFill.LARGURA_PADRAO, PlayArea.LARGURA, "gerador usa a mesma constante do Player")
