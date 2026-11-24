extends GutTest

# Decisor puro do `?powerup=` (smoke debug): release sempre vazio; so nome simples em minusculas vale em debug.


func test_release_ignora_o_parametro() -> void:
	assert_eq(ModoPowerUpInicial.decide("teste", false), "", "release: sempre vazio, mesmo com nome valido")


func test_debug_com_nome_valido_devolve_o_nome() -> void:
	assert_eq(ModoPowerUpInicial.decide("teste", true), "teste", "debug: nome valido devolve o nome")
	assert_eq(ModoPowerUpInicial.decide("camaleao_2", true), "camaleao_2", "debug: digito e underscore valem")


func test_debug_ausente_invalido_vazio_e_nao_string_devolvem_vazio() -> void:
	assert_eq(ModoPowerUpInicial.decide(null, true), "", "ausente (null): vazio")
	assert_eq(ModoPowerUpInicial.decide("", true), "", "string vazia: vazio")
	assert_eq(ModoPowerUpInicial.decide("Teste", true), "", "maiuscula: vazio")
	assert_eq(ModoPowerUpInicial.decide("a b", true), "", "espaco: vazio")
	assert_eq(ModoPowerUpInicial.decide("1teste", true), "", "comeca com digito: vazio")
	assert_eq(ModoPowerUpInicial.decide("te-ste", true), "", "simbolo: vazio")
	assert_eq(ModoPowerUpInicial.decide(1, true), "", "int: vazio")
	assert_eq(ModoPowerUpInicial.decide(&"teste", true), "", "StringName nao e String: vazio")
	assert_eq(ModoPowerUpInicial.decide(["teste"], true), "", "Array: vazio")
