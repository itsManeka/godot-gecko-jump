extends GutTest

# Lado do toque (TouchClassifier.lado_de): unica regra que sobrou do classificador tap x segurar (removido na f493).


func test_fronteira_de_lado_em_180() -> void:
	assert_eq(TouchClassifier.lado_de(89.0, 180.0), TouchClassifier.Lado.ESQUERDA, "x=89 largura 180 esquerda")
	assert_eq(TouchClassifier.lado_de(90.0, 180.0), TouchClassifier.Lado.DIREITA, "x=90 largura 180 direita")
	assert_eq(TouchClassifier.lado_de(91.0, 180.0), TouchClassifier.Lado.DIREITA, "x=91 largura 180 direita")


func test_fronteira_de_lado_em_largura_240() -> void:
	assert_eq(TouchClassifier.lado_de(119.0, 240.0), TouchClassifier.Lado.ESQUERDA, "x=119 largura 240 esquerda")
	assert_eq(TouchClassifier.lado_de(120.0, 240.0), TouchClassifier.Lado.DIREITA, "x=120 largura 240 direita")
	assert_eq(TouchClassifier.lado_de(90.0, 240.0), TouchClassifier.Lado.ESQUERDA, "x=90 largura 240 esquerda")


func test_extremos_da_tela() -> void:
	assert_eq(TouchClassifier.lado_de(0.0, 180.0), TouchClassifier.Lado.ESQUERDA, "x=0 esquerda")
	assert_eq(TouchClassifier.lado_de(180.0, 180.0), TouchClassifier.Lado.DIREITA, "x=largura direita")
	assert_ne(TouchClassifier.lado_de(0.0, 180.0), TouchClassifier.Lado.NENHUM, "lado de um toque nunca e NENHUM")
