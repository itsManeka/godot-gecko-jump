extends GutTest

# Modo dica de toque (T5): decisor puro com trava is_debug, leitura fina da URL e wiring no Global.
# Estado global: after_each devolve Global.toque_detectado a false para nao vazar para outros testes.


func after_each() -> void:
	Global.toque_detectado = false


func test_dica_1_em_debug_forca_toque_detectado() -> void:
	Global.aplicar_modo_dica("1", true)
	assert_true(Global.toque_detectado, "dica=1 em debug deve forcar toque_detectado (dica visivel no smoke)")


func test_trava_release_ignora_valor_1_e_debug_liga() -> void:
	assert_false(ModoDicaToque.decide("1", false), "release ignora ?dica=1")
	assert_true(ModoDicaToque.decide("1", true), "debug com 1 liga")


func test_entradas_que_nao_ligam_em_debug() -> void:
	assert_false(ModoDicaToque.decide(null, true), "ausente nao liga")
	assert_false(ModoDicaToque.decide("", true), "vazio nao liga")
	assert_false(ModoDicaToque.decide("0", true), "0 nao liga")
	assert_false(ModoDicaToque.decide("true", true), "true nao liga")
	assert_false(ModoDicaToque.decide(" 1", true), "com espaco nao liga")
	assert_false(ModoDicaToque.decide("11", true), "11 nao liga")
	assert_false(ModoDicaToque.decide("-1", true), "-1 nao liga")
	assert_false(ModoDicaToque.decide(1, true), "nao-String nao liga")


func test_read_raw_fora_do_web_devolve_null() -> void:
	assert_eq(ModoDicaToque.read_raw() == null, true, "fora do web read_raw nao le a query")


func test_global_valor_inicial_e_false() -> void:
	Global.toque_detectado = false
	assert_false(Global.toque_detectado, "toque_detectado nasce false sem o parametro")


func test_global_sem_parametro_ou_release_nao_marca_toque() -> void:
	Global.aplicar_modo_dica(null, true)
	assert_false(Global.toque_detectado, "sem ?dica o Global nao marca toque")
	Global.aplicar_modo_dica("1", false)
	assert_false(Global.toque_detectado, "release nao liga o Global")
