extends GutTest

# Progresso inicial de debug (f464 T3): decisor puro com trava is_debug, leitura fina da URL e wiring no Global.
# Estado global: after_each devolve Global.progresso_inicial a 0.0 para nao vazar para outros testes.


func after_each() -> void:
	Global.progresso_inicial = 0.0


func test_trava_release_ignora_valor_e_debug_aplica() -> void:
	assert_eq(ModoProgressoInicial.decide("0.5", false), 0.0, "release ignora ?progresso=0.5")
	assert_eq(ModoProgressoInicial.decide("0.5", true), 0.5, "debug com 0.5 aplica")


func test_decimal_034_em_debug() -> void:
	assert_eq(ModoProgressoInicial.decide("0.34", true), 0.34, "0.34 vira 0.34")


func test_inteiro_1_em_debug() -> void:
	assert_eq(ModoProgressoInicial.decide("1", true), 1.0, "1 vira 1.0")


func test_inteiro_0_em_debug() -> void:
	assert_eq(ModoProgressoInicial.decide("0", true), 0.0, "0 vira 0.0")


func test_invalidos_devolvem_zero_em_debug() -> void:
	assert_eq(ModoProgressoInicial.decide(null, true), 0.0, "ausente/nao-String nao aplica")
	assert_eq(ModoProgressoInicial.decide("", true), 0.0, "vazio nao aplica")
	assert_eq(ModoProgressoInicial.decide("abc", true), 0.0, "letras nao aplicam")
	assert_eq(ModoProgressoInicial.decide("-0.1", true), 0.0, "negativo nao aplica")
	assert_eq(ModoProgressoInicial.decide("1.5", true), 0.0, "acima de 1 nao satura: invalido")
	assert_eq(ModoProgressoInicial.decide("0.3.4", true), 0.0, "dois pontos nao aplica")
	assert_eq(ModoProgressoInicial.decide(" 0.3", true), 0.0, "espaco inicial nao aplica")
	assert_eq(ModoProgressoInicial.decide("1e-1", true), 0.0, "notacao cientifica nao aplica")
	assert_eq(ModoProgressoInicial.decide(0.5, true), 0.0, "float (nao-String) nao aplica")


func test_read_raw_fora_do_web_devolve_null() -> void:
	assert_eq(ModoProgressoInicial.read_raw() == null, true, "fora do web read_raw nao le a query")


func test_global_valor_inicial_e_zero() -> void:
	assert_eq(Global.progresso_inicial, 0.0, "progresso_inicial nasce 0.0")


func test_global_aplica_progresso_respeitando_a_trava() -> void:
	Global.aplicar_progresso_inicial("0.34", false)
	assert_eq(Global.progresso_inicial, 0.0, "release nao aplica no Global")
	Global.aplicar_progresso_inicial("0.34", true)
	assert_eq(Global.progresso_inicial, 0.34, "debug aplica no Global")
