extends GutTest

# Decisor puro do `?tempo=<s>` (smoke debug): release sempre 0.0; so numero positivo vale em debug.


func test_release_ignora_o_parametro() -> void:
	assert_eq(ModoTempoInicial.decide("5", false), 0.0, "release: sempre 0.0, mesmo com valor valido")


func test_debug_com_valor_valido_devolve_o_valor() -> void:
	assert_eq(ModoTempoInicial.decide("5", true), 5.0, "debug: 5 devolve 5.0")
	assert_eq(ModoTempoInicial.decide("2.5", true), 2.5, "debug: decimal vale")


func test_debug_valor_enorme_e_limitado_ao_teto() -> void:
	assert_eq(ModoTempoInicial.decide("1e308", true), ModoTempoInicial.TETO_S, "1e308 vira o teto")
	assert_eq(ModoTempoInicial.decide("3600", true), 3600.0, "o proprio teto vale")
	assert_eq(ModoTempoInicial.decide("3601", true), ModoTempoInicial.TETO_S, "acima do teto vira o teto")


func test_debug_invalido_devolve_zero() -> void:
	assert_eq(ModoTempoInicial.decide("abc", true), 0.0, "texto: 0.0")
	assert_eq(ModoTempoInicial.decide("0", true), 0.0, "zero: 0.0")
	assert_eq(ModoTempoInicial.decide("-3", true), 0.0, "negativo: 0.0")
	assert_eq(ModoTempoInicial.decide("", true), 0.0, "vazio: 0.0")
	assert_eq(ModoTempoInicial.decide(null, true), 0.0, "ausente (null): 0.0")
	assert_eq(ModoTempoInicial.decide(5, true), 0.0, "int nao String: 0.0")


func test_global_aplica_o_seam_so_em_debug() -> void:
	Global.aplicar_tempo_inicial("5", true)
	assert_eq(Global.tempo_inicial_s, 5.0, "debug com valor 5: limite lido e 5")
	assert_eq(Global.limite_tempo_s(), 5.0, "limite usa o seam")
	Global.aplicar_tempo_inicial("5", false)
	assert_eq(Global.tempo_inicial_s, 0.0, "release ignora o valor")
	assert_eq(Global.limite_tempo_s(), 60.0, "release: limite e o do .tres")
	for invalido: String in ["abc", "0", "-3"]:
		Global.aplicar_tempo_inicial(invalido, true)
		assert_eq(Global.limite_tempo_s(), 60.0, "debug com '%s' ignorado: fallback do .tres" % invalido)
	Global.aplicar_tempo_inicial(null, true)
	Global.tempo_inicial_s = 0.0
