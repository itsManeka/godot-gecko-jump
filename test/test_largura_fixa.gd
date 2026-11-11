extends GutTest

# f439 T1: o jogo e so retrato, largura logica sempre 180 (ADR 0002). Janela larga ganha barras laterais
# (aspect keep_width), nao area de jogo mais larga. Le os ajustes de stretch do projeto.

func test_stretch_aspect_keep_width() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "keep_width",
		"aspect deve ser keep_width: largura logica fixa em 180, altura expande")

func test_stretch_mode_viewport_e_escala_inteira() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "viewport",
		"mode deve continuar viewport")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/scale_mode"), "integer",
		"scale_mode deve continuar integer")

# C142: fonte unica da largura jogavel; gerador e Player leem dela.
func test_largura_jogavel_de_fonte_unica() -> void:
	assert_eq(PlayArea.LARGURA, 180.0, "largura jogavel = 180")
	assert_eq(MovingRowFill.LARGURA_PADRAO, PlayArea.LARGURA, "gerador usa a mesma constante do Player")
