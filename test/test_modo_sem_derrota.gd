extends GutTest

# Modo sem derrota (T6): decisor puro com trava is_debug, leitura fina da URL e wiring no Global.
# Estado global: after_each devolve Global.sem_derrota a false para nao vazar para outros testes.


func after_each() -> void:
	Global.sem_derrota = false


func test_trava_release_ignora_valor_1_e_debug_liga() -> void:
	assert_false(ModoSemDerrota.decide("1", false), "release ignora ?semderrota=1")
	assert_true(ModoSemDerrota.decide("1", true), "debug com 1 liga")


func test_entradas_que_nao_ligam_em_debug() -> void:
	assert_false(ModoSemDerrota.decide(null, true), "ausente nao liga")
	assert_false(ModoSemDerrota.decide("", true), "vazio nao liga")
	assert_false(ModoSemDerrota.decide("0", true), "0 nao liga")
	assert_false(ModoSemDerrota.decide("true", true), "true nao liga")
	assert_false(ModoSemDerrota.decide(" 1", true), "com espaco nao liga")
	assert_false(ModoSemDerrota.decide("11", true), "11 nao liga")
	assert_false(ModoSemDerrota.decide("-1", true), "-1 nao liga")
	assert_false(ModoSemDerrota.decide(1, true), "nao-String nao liga")


func test_read_raw_fora_do_web_devolve_null() -> void:
	assert_eq(ModoSemDerrota.read_raw() == null, true, "fora do web read_raw nao le a query")


func test_global_valor_inicial_e_false() -> void:
	assert_false(Global.sem_derrota, "sem_derrota nasce false")


func test_global_aplica_modo_sem_derrota_respeitando_a_trava() -> void:
	Global.aplicar_modo_sem_derrota("1", false)
	assert_false(Global.sem_derrota, "release nao liga o Global")
	Global.aplicar_modo_sem_derrota("1", true)
	assert_true(Global.sem_derrota, "debug com 1 liga o Global")
