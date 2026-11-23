extends GutTest

# Decisor puro do `?dia=` (T7): sem ambiente, so `decide(raw, is_debug)`.

const SEM := ModoDiaInicial.SEM_OVERRIDE


func after_each() -> void:
	Global.aplicar_dia_inicial(null, false)


func test_release_sempre_ignora_dia() -> void:
	assert_eq(ModoDiaInicial.decide("5", false), SEM, "release ignora valor valido")
	assert_eq(ModoDiaInicial.decide("0", false), SEM, "release ignora zero")
	assert_eq(ModoDiaInicial.decide("20000", false), SEM, "release ignora valor do meio da faixa")
	assert_eq(ModoDiaInicial.decide(null, false), SEM, "release sem parametro")


func test_debug_aceita_so_inteiro_na_faixa() -> void:
	assert_eq(ModoDiaInicial.decide("0", true), 0, "debug aceita 0")
	assert_eq(ModoDiaInicial.decide("20000", true), 20000, "debug aceita inteiro comum")
	assert_eq(ModoDiaInicial.decide("2147483647", true), 2147483647, "debug aceita o maximo (SeedSource.MAX_SEED)")
	assert_eq(ModoDiaInicial.decide("abc", true), SEM, "texto nao numerico")
	assert_eq(ModoDiaInicial.decide("", true), SEM, "vazio")
	assert_eq(ModoDiaInicial.decide("-1", true), SEM, "negativo")
	assert_eq(ModoDiaInicial.decide("2147483648", true), SEM, "acima do maximo")
	assert_eq(ModoDiaInicial.decide("99999999999999999999", true), SEM, "estouro de inteiro")
	assert_eq(ModoDiaInicial.decide("5.5", true), SEM, "float")
	assert_eq(ModoDiaInicial.decide("+5", true), SEM, "sinal de mais")
	assert_eq(ModoDiaInicial.decide(5, true), SEM, "nao-String")
	assert_eq(ModoDiaInicial.decide(null, true), SEM, "ausente")


func test_relogio_do_dia_segue_o_override() -> void:
	Global.aplicar_dia_inicial("5", true)
	var relogio: Callable = Global.relogio_do_dia()
	assert_true(relogio.is_valid(), "com override o relogio e injetado")
	assert_eq(DiaUtc.new(relogio).dia_atual(), 5, "DiaUtc com o relogio do override le o dia forcado")
	Global.aplicar_dia_inicial("5", false)
	assert_false(Global.relogio_do_dia().is_valid(), "release: sem override, DiaUtc usa o relogio do sistema")
