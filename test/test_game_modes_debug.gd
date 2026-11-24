extends GutTest

# Decisor do seletor de modos (`?modos=teste`, so debug): release nunca inclui o modo de teste; debug so com o valor exato.

var _modos_teste_antes: bool


func before_each() -> void:
	_modos_teste_antes = Global.modos_teste_habilitado


func after_each() -> void:
	Global.modos_teste_habilitado = _modos_teste_antes


func test_c608_release_nunca_inclui_teste_mesmo_com_o_parametro() -> void:
	assert_false(GameModesDebug.decide("teste", false), "release: nao inclui mesmo com teste")
	assert_false(GameModesDebug.decide(null, false), "release sem parametro: nao inclui")


func test_c609_debug_so_inclui_com_teste_exato() -> void:
	assert_false(GameModesDebug.decide(null, true), "debug sem parametro: nao inclui")
	assert_true(GameModesDebug.decide("teste", true), "debug com teste: inclui")
	assert_false(GameModesDebug.decide("TESTE", true), "maiuscula: nao inclui")
	assert_false(GameModesDebug.decide("x", true), "valor desconhecido: nao inclui")
	assert_false(GameModesDebug.decide("", true), "string vazia: nao inclui")
	assert_false(GameModesDebug.decide(" teste", true), "espaco: nao inclui")
	assert_false(GameModesDebug.decide(&"teste", true), "StringName nao e String: nao inclui")
	assert_false(GameModesDebug.decide(1, true), "int: nao inclui")
	assert_false(GameModesDebug.decide(["teste"], true), "Array: nao inclui")


func test_c610_aplicar_modos_teste_atribui_a_flag_so_com_teste_em_debug() -> void:
	Global.aplicar_modos_teste("teste", true)
	assert_true(Global.modos_teste_habilitado, "debug com teste: liga a flag")
	Global.aplicar_modos_teste("teste", false)
	assert_false(Global.modos_teste_habilitado, "release: desliga a flag (atribui, nao so liga)")
	Global.aplicar_modos_teste("teste", true)
	Global.aplicar_modos_teste(null, true)
	assert_false(Global.modos_teste_habilitado, "debug sem parametro: desliga a flag")
