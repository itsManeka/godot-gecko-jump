extends GutTest

# Moldura fixa de debug (f469 T4): decisor puro com trava is_debug, leitura fina da URL e wiring no Global.
# Estado global: after_each devolve Global.moldura_fixa a false para nao vazar para outros testes.


func after_each() -> void:
	Global.moldura_fixa = false


func test_trava_release_ignora_valor_e_debug_aplica() -> void:
	assert_false(ModoMolduraFixa.decide("fixa", false), "release ignora ?moldura=fixa")
	assert_true(ModoMolduraFixa.decide("fixa", true), "debug com fixa aplica")


func test_invalidos_devolvem_false_em_debug() -> void:
	assert_false(ModoMolduraFixa.decide(null, true), "ausente nao aplica")
	assert_false(ModoMolduraFixa.decide("", true), "vazio nao aplica")
	assert_false(ModoMolduraFixa.decide("1", true), "outro texto nao aplica")
	assert_false(ModoMolduraFixa.decide("FIXA", true), "caixa diferente nao aplica")
	assert_false(ModoMolduraFixa.decide(" fixa", true), "espaco nao aplica")
	assert_false(ModoMolduraFixa.decide(1, true), "nao-String nao aplica")


func test_read_raw_fora_do_web_devolve_null() -> void:
	assert_eq(ModoMolduraFixa.read_raw() == null, true, "sem o argumento read_raw nao le nada")


func test_global_valor_inicial_e_false() -> void:
	assert_false(Global.moldura_fixa, "moldura_fixa nasce false")


func test_global_aplica_moldura_respeitando_a_trava() -> void:
	Global.aplicar_moldura_fixa("fixa", false)
	assert_false(Global.moldura_fixa, "release nao aplica no Global")
	Global.aplicar_moldura_fixa("fixa", true)
	assert_true(Global.moldura_fixa, "debug aplica no Global")
