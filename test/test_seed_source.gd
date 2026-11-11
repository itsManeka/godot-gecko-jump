extends GutTest

## Decisor puro da seed (SeedSource.decide). Sem arvore de cena, sem RNG global.


func test_sem_parametro_devolve_null_em_debug() -> void:
	assert_null(SeedSource.decide(null, true), "parametro ausente vira sorteio livre")


func test_string_vazia_devolve_null_em_debug() -> void:
	assert_null(SeedSource.decide("", true), "string vazia nao e seed")


func test_valor_valido_em_debug_devolve_inteiro() -> void:
	assert_eq(SeedSource.decide("123", true), 123, "digitos puros em debug viram o inteiro")


func test_zero_em_debug_e_seed_valida() -> void:
	assert_eq(SeedSource.decide("0", true), 0, "seed zero e valida, nao e ausente")


func test_mesmo_valor_em_release_devolve_null() -> void:
	assert_null(SeedSource.decide("123", false), "release ignora ?seed= mesmo com valor valido")


func test_zero_em_release_tambem_devolve_null() -> void:
	assert_null(SeedSource.decide("0", false), "a trava de release vale para qualquer valor")


func test_entradas_invalidas_devolvem_null_sem_erro() -> void:
	var invalidas: Array = ["abc", "-5", "99999999999999999999", "12abc", " 7 ", "+7", "1.5", "2147483648"]
	for entrada in invalidas:
		assert_null(SeedSource.decide(entrada, true), "entrada invalida vira null")


func test_nao_string_devolve_null_em_debug() -> void:
	assert_null(SeedSource.decide(123, true), "inteiro bruto nao e o formato da URL")


func test_limite_maximo_aceito_e_proximo_rejeitado() -> void:
	assert_eq(SeedSource.decide("2147483647", true), 2147483647, "MAX_SEED e aceito")
	assert_null(SeedSource.decide("2147483648", true), "um acima de MAX_SEED vira null")


func test_mesma_entrada_mesma_saida() -> void:
	var primeira: Variant = SeedSource.decide("4242", true)
	var segunda: Variant = SeedSource.decide("4242", true)
	assert_eq(primeira, segunda, "funcao pura: sem estado entre chamadas")
	assert_eq(primeira, 4242, "e o valor esperado")
