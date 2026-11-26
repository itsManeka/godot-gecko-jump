extends GutTest

# Lado do toque (TouchClassifier.lado_de): unica regra que sobrou do classificador tap x segurar (removido na f493).


func test_fronteira_de_lado_em_360() -> void:
	assert_eq(TouchClassifier.lado_de(179.0, 360.0), TouchClassifier.Lado.ESQUERDA, "x=179 largura 360 esquerda")
	assert_eq(TouchClassifier.lado_de(180.0, 360.0), TouchClassifier.Lado.DIREITA, "x=180 largura 360 direita")
	assert_eq(TouchClassifier.lado_de(181.0, 360.0), TouchClassifier.Lado.DIREITA, "x=181 largura 360 direita")


func test_fronteira_de_lado_em_largura_480() -> void:
	assert_eq(TouchClassifier.lado_de(239.0, 480.0), TouchClassifier.Lado.ESQUERDA, "x=239 largura 480 esquerda")
	assert_eq(TouchClassifier.lado_de(240.0, 480.0), TouchClassifier.Lado.DIREITA, "x=240 largura 480 direita")
	assert_eq(TouchClassifier.lado_de(180.0, 480.0), TouchClassifier.Lado.ESQUERDA, "x=180 largura 480 esquerda")


func test_extremos_da_tela() -> void:
	assert_eq(TouchClassifier.lado_de(0.0, 360.0), TouchClassifier.Lado.ESQUERDA, "x=0 esquerda")
	assert_eq(TouchClassifier.lado_de(360.0, 360.0), TouchClassifier.Lado.DIREITA, "x=largura direita")
	assert_ne(TouchClassifier.lado_de(0.0, 360.0), TouchClassifier.Lado.NENHUM, "lado de um toque nunca e NENHUM")
