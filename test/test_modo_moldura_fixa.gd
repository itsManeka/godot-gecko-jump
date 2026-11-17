extends GutTest

# Moldura fixa de debug (f469 T4): decisor puro com trava is_debug, leitura fina da URL e wiring no Global.
# Estado global: after_each devolve Global.moldura_fixa a false para nao vazar para outros testes.


func after_each() -> void:
	Global.moldura_fixa = false
	Global.moldura_lenta = false


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


# Pulso lento (f490 T2): decisor proprio, exclusivo do modo fixa, trava de release, wiring no Global e duracoes
# do pulso multiplicadas no LevelUpFrame.

func test_c453_release_ignora_lenta_e_debug_aplica_somente_com_valor_exato() -> void:
	assert_false(ModoMolduraLenta.decide("lenta", false), "release ignora ?moldura=lenta")
	assert_true(ModoMolduraLenta.decide("lenta", true), "debug com lenta aplica")
	assert_false(ModoMolduraLenta.decide(null, true), "ausente nao aplica em debug")
	assert_false(ModoMolduraLenta.decide("", true), "vazio nao aplica em debug")
	assert_false(ModoMolduraLenta.decide("LENTA", true), "caixa diferente nao aplica em debug")
	assert_false(ModoMolduraLenta.decide(1, true), "nao-String nao aplica em debug")


func test_c454_fixa_e_lenta_sao_decisores_exclusivos() -> void:
	assert_false(ModoMolduraFixa.decide("lenta", true), "lenta nao liga o modo fixa")
	assert_false(ModoMolduraLenta.decide("fixa", true), "fixa nao liga o modo lenta")


func test_c454_global_aplica_lenta_respeitando_a_trava() -> void:
	Global.aplicar_moldura_lenta("lenta", false)
	assert_false(Global.moldura_lenta, "release nao aplica no Global")
	Global.aplicar_moldura_lenta("lenta", true)
	assert_true(Global.moldura_lenta, "debug aplica no Global")


func _nova_frame_lenta(lenta: bool) -> LevelUpFrame:
	var f := LevelUpFrame.new()
	add_child_autofree(f)
	f.aplicar_layout(Vector2(180.0, 320.0), Rect2(Vector2.ZERO, Vector2(180.0, 320.0)))
	f.lenta = lenta
	return f


func test_c455_com_lenta_subida_queda_e_intervalo_ficam_mais_lentos() -> void:
	var f := _nova_frame_lenta(true)
	f.pulsar(2)
	f._tween.pause()
	# Subida: no tempo da constante (0,06 s) o pico ainda nao veio; sem lenta o alpha ja estaria em 1
	f._tween.custom_step(LevelUpFrame.SUBIDA_S)
	assert_lt(f.alpha(), 1.0, "subida com lenta nao completa em SUBIDA_S")
	assert_gt(f.alpha(), 0.0, "o pulso real esta em curso")
	# Queda: no tempo do pulso inteiro sem lenta (subida + queda = 0,25 s) o aviso ainda esta aceso
	f._tween.custom_step(LevelUpFrame.QUEDA_S)
	assert_gt(f.alpha(), 0.0, "queda com lenta em curso depois do pulso inteiro sem lenta")
	# Intervalo: passadas a subida e a queda lentas completas, o 2o pulso ainda nao comecou
	f._tween.custom_step(LevelUpFrame.SUBIDA_S * LevelUpFrame.LENTA_VEZES + LevelUpFrame.QUEDA_S * LevelUpFrame.LENTA_VEZES)
	assert_eq(f.alpha(), 0.0, "queda lenta terminou (alpha 0)")
	assert_true(f.pulsando(), "intervalo com lenta: o 2o pulso ainda nao comecou")


func test_c455_sem_lenta_o_pulso_segue_os_valores_do_spec() -> void:
	var f := _nova_frame_lenta(false)
	f.pulsar(1)
	f._tween.pause()
	f._tween.custom_step(LevelUpFrame.SUBIDA_S)
	assert_almost_eq(f.alpha(), 1.0, 0.001, "subida do spec (0,06 s) completa o pico")
	# Folga de 10 ms: o callback de termino roda no passo seguinte ao fim da queda
	f._tween.custom_step(LevelUpFrame.QUEDA_S + 0.01)
	assert_false(f.pulsando(), "pulso do spec termina em SUBIDA_S + QUEDA_S (0,25 s)")
	assert_eq(f.alpha(), 0.0, "termina apagado")
