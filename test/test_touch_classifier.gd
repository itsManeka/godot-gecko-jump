extends GutTest

# Classificador puro de toque x segurar (T1 da f457). Limiar sempre pelo simbolo, nunca literal.

const T0 := 1000


func _novo(largura: float = 180.0, mortas: Array[Rect2] = []) -> TouchClassifier:
	return TouchClassifier.new(largura, mortas)


func _toque(c: TouchClassifier, x: float, duracao: int) -> Dictionary:
	c.press(0, T0, Vector2(x, 100))
	return c.release(0, T0 + duracao)


func test_tap_abaixo_do_limiar_nos_dois_lados() -> void:
	var e: Dictionary = _toque(_novo(), 10.0, 50)
	assert_eq(e["resultado"], TouchClassifier.Resultado.TAP, "tap esquerda abaixo do limiar")
	assert_eq(e["lado"], TouchClassifier.Lado.ESQUERDA, "lado esquerda x=10")
	var d: Dictionary = _toque(_novo(), 170.0, 50)
	assert_eq(d["resultado"], TouchClassifier.Resultado.TAP, "tap direita abaixo do limiar")
	assert_eq(d["lado"], TouchClassifier.Lado.DIREITA, "lado direita x=170")


func test_hold_acima_do_limiar() -> void:
	var r: Dictionary = _toque(_novo(), 10.0, TouchClassifier.LIMIAR_MS + 300)
	assert_eq(r["resultado"], TouchClassifier.Resultado.HOLD, "hold acima do limiar")
	assert_eq(r["lado"], TouchClassifier.Lado.ESQUERDA, "hold lado esquerda")


func test_limiar_fronteira_exata_segue_hold_no_limiar_inclusivo() -> void:
	var antes: Dictionary = _toque(_novo(), 10.0, TouchClassifier.LIMIAR_MS - 1)
	var no: Dictionary = _toque(_novo(), 10.0, TouchClassifier.LIMIAR_MS)
	var depois: Dictionary = _toque(_novo(), 10.0, TouchClassifier.LIMIAR_MS + 1)
	assert_eq(antes["resultado"], TouchClassifier.Resultado.TAP, "limiar menos 1 e tap")
	var esperado: int = (
		TouchClassifier.Resultado.HOLD
		if TouchClassifier.hold_no_limiar_inclusivo
		else TouchClassifier.Resultado.TAP
	)
	assert_eq(no["resultado"], esperado, "duracao igual ao limiar segue hold_no_limiar_inclusivo")
	assert_eq(depois["resultado"], TouchClassifier.Resultado.HOLD, "limiar mais 1 e hold")


func test_fronteira_de_lado_em_180() -> void:
	assert_eq(_toque(_novo(), 89.0, 10)["lado"], TouchClassifier.Lado.ESQUERDA, "x=89 largura 180 esquerda")
	assert_eq(_toque(_novo(), 90.0, 10)["lado"], TouchClassifier.Lado.DIREITA, "x=90 largura 180 direita")
	assert_eq(_toque(_novo(), 91.0, 10)["lado"], TouchClassifier.Lado.DIREITA, "x=91 largura 180 direita")


func test_fronteira_de_lado_em_largura_240() -> void:
	assert_eq(_toque(_novo(240.0), 119.0, 10)["lado"], TouchClassifier.Lado.ESQUERDA, "x=119 largura 240 esquerda")
	assert_eq(_toque(_novo(240.0), 120.0, 10)["lado"], TouchClassifier.Lado.DIREITA, "x=120 largura 240 direita")
	assert_eq(_toque(_novo(240.0), 90.0, 10)["lado"], TouchClassifier.Lado.ESQUERDA, "x=90 largura 240 esquerda")


func test_zona_morta_ignora_e_lista_vazia_classifica() -> void:
	var mortas: Array[Rect2] = [Rect2(80, 0, 20, 50)]
	var c: TouchClassifier = _novo(180.0, mortas)
	assert_false(c.press(0, T0, Vector2(90, 10)), "press em zona morta nao e aceito")
	assert_eq(c.release(0, T0 + 10)["resultado"], TouchClassifier.Resultado.IGNORADO, "release de zona morta ignorado")
	assert_false(c.ativo(), "zona morta nao ativa dedo")
	var livre: TouchClassifier = _novo()
	assert_true(livre.press(0, T0, Vector2(90, 10)), "lista vazia aceita o mesmo x")
	assert_eq(livre.release(0, T0 + 10)["resultado"], TouchClassifier.Resultado.TAP, "lista vazia classifica tap")


func test_segundo_dedo_ignorado_sem_alterar_o_primeiro() -> void:
	var c: TouchClassifier = _novo()
	assert_true(c.press(0, T0, Vector2(10, 100)), "primeiro dedo aceito")
	assert_false(c.press(1, T0 + 20, Vector2(170, 100)), "segundo dedo ignorado")
	assert_eq(c.release(1, T0 + 30)["resultado"], TouchClassifier.Resultado.IGNORADO, "release do segundo dedo ignorado")
	var r: Dictionary = c.release(0, T0 + TouchClassifier.LIMIAR_MS + 50)
	assert_eq(r["resultado"], TouchClassifier.Resultado.HOLD, "primeiro dedo mantem hold")
	assert_eq(r["lado"], TouchClassifier.Lado.ESQUERDA, "primeiro dedo mantem lado esquerda")


func test_press_sem_release_e_cancelado() -> void:
	var c: TouchClassifier = _novo()
	c.press(0, T0, Vector2(10, 100))
	var r: Dictionary = c.cancelar(0)
	assert_eq(r["resultado"], TouchClassifier.Resultado.CANCELADO, "cancelado sem release")
	assert_ne(r["resultado"], TouchClassifier.Resultado.TAP, "cancelado nao e tap")
	assert_ne(r["resultado"], TouchClassifier.Resultado.HOLD, "cancelado nao e hold")
	assert_false(c.ativo(), "cancelar libera o dedo")


func test_release_sem_press_e_ignorado() -> void:
	var r: Dictionary = _novo().release(0, T0)
	assert_eq(r["resultado"], TouchClassifier.Resultado.IGNORADO, "release sem press ignorado")
