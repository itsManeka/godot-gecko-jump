extends GutTest

# Matematica pura do slider de volume (SliderMath): posicao -> valor, passo de teclado e rotulo.


func test_c193_x_16_vale_0() -> void:
	assert_eq(SliderMath.valor_de_x(16.0), 0, "x = 16 (borda esquerda da trilha) vale 0")


func test_c194_x_164_vale_100() -> void:
	assert_eq(SliderMath.valor_de_x(164.0), 100, "x = 164 (borda direita da trilha) vale 100")


func test_c195_x_90_vale_50() -> void:
	assert_eq(SliderMath.valor_de_x(90.0), 50, "x = 90 (meio da trilha) vale 50")


func test_c196_x_fora_da_trilha_fica_limitado() -> void:
	assert_eq(SliderMath.valor_de_x(-40.0), 0, "x < 16 vale 0")
	assert_eq(SliderMath.valor_de_x(500.0), 100, "x > 164 vale 100")


func test_c197_passo_de_teclado_de_5_limitado_em_0_e_100() -> void:
	assert_eq(SliderMath.passo(97, 1), 100, "97 + 5 limita em 100")
	assert_eq(SliderMath.passo(3, -1), 0, "3 - 5 limita em 0")
	assert_eq(SliderMath.passo(50, 1), 55, "50 + 5 = 55")
	assert_eq(SliderMath.passo(50, -1), 45, "50 - 5 = 45")


func test_c198_rotulo_mudo_em_0_e_percentual_nos_demais() -> void:
	assert_eq(SliderMath.rotulo(0), "mudo", "0 vale mudo")
	assert_eq(SliderMath.rotulo(1), "1%", "1 vale 1%")
	assert_eq(SliderMath.rotulo(100), "100%", "100 vale 100%")


func test_x_do_valor_e_inverso_de_valor_de_x_nas_pontas_e_no_meio() -> void:
	assert_eq(SliderMath.x_do_valor(0), 16.0, "valor 0 no x 16")
	assert_eq(SliderMath.x_do_valor(100), 164.0, "valor 100 no x 164")
	assert_eq(SliderMath.x_do_valor(50), 90.0, "valor 50 no x 90")
