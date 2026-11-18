extends GutTest

# ModoToqueInicial (`?toque=`, so debug): forca o modo de toque da sessao sem gravar no store.
# Cenarios C375 (forca e nao grava) e C376 (invalido/ausente/release nao muda).

var _modo_antes: int
var _salvo_antes: Variant


func before_each() -> void:
	_modo_antes = Global.get_touch_mode()
	_salvo_antes = Global.opcoes.load_value(TouchMode.SECTION, TouchMode.KEY, TouchMode.SEM_VALOR)


func after_each() -> void:
	Global.set_touch_mode(_modo_antes, false)
	Global.opcoes.save_value(TouchMode.SECTION, TouchMode.KEY, _salvo_antes)


func test_c375_toque_a_b_forca_modo_sem_gravar() -> void:
	Global.set_touch_mode(TouchMode.Modo.B, true)
	var salvo_antes: Variant = Global.opcoes.load_value(TouchMode.SECTION, TouchMode.KEY, TouchMode.SEM_VALOR)

	assert_eq(ModoToqueInicial.decide("a", true), TouchMode.Modo.A, "decide: a -> A")
	assert_eq(ModoToqueInicial.decide("b", true), TouchMode.Modo.B, "decide: b -> B")

	Global.aplicar_modo_toque_inicial("a", true)
	assert_eq(Global.get_touch_mode(), TouchMode.Modo.A, "o parametro a forca A na sessao")
	assert_eq(
		Global.opcoes.load_value(TouchMode.SECTION, TouchMode.KEY, TouchMode.SEM_VALOR),
		salvo_antes,
		"forcar o modo nao grava no store (user:// intocado)"
	)


func test_c451_decide_c_nao_forca_a_b_forcam() -> void:
	Global.set_touch_mode(TouchMode.Modo.B, false)
	assert_eq(ModoToqueInicial.decide("c", true), ModoToqueInicial.SEM_FORCA, "C451: c (modo removido) nao forca")
	assert_eq(ModoToqueInicial.decide("a", true), TouchMode.Modo.A, "C451: a forca em debug")
	assert_eq(ModoToqueInicial.decide("b", true), TouchMode.Modo.B, "C451: b forca em debug")
	assert_eq(ModoToqueInicial.decide("a", false), ModoToqueInicial.SEM_FORCA, "C451: release ignora a")
	assert_eq(ModoToqueInicial.decide("b", false), ModoToqueInicial.SEM_FORCA, "C451: release ignora b")
	assert_eq(Global.get_touch_mode(), TouchMode.Modo.B, "C451: decide e puro, o modo nao muda")


func test_c376_valor_invalido_vazio_ausente_nao_muda_modo() -> void:
	Global.set_touch_mode(TouchMode.Modo.B, false)
	var invalidos: Array = [null, "", "d", "A", "a|b", " a", "a ", 1, 1.0, ["a"]]
	for raw in invalidos:
		assert_eq(ModoToqueInicial.decide(raw, true), ModoToqueInicial.SEM_FORCA, "decide ignora %s" % str(raw))
		Global.aplicar_modo_toque_inicial(raw, true)
		assert_eq(Global.get_touch_mode(), TouchMode.Modo.B, "modo intacto com %s" % str(raw))


func test_c376_release_ignora_parametro() -> void:
	Global.set_touch_mode(TouchMode.Modo.B, false)
	assert_eq(ModoToqueInicial.decide("a", false), ModoToqueInicial.SEM_FORCA, "release devolve SEM_FORCA")
	Global.aplicar_modo_toque_inicial("a", false)
	assert_eq(Global.get_touch_mode(), TouchMode.Modo.B, "release nao aplica ?toque=")
