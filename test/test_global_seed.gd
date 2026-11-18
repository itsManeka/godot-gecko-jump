extends GutTest

# Ligacao da seed no Global (T2): aplicar_seed(null) sorteia, aplicar_seed(n) fixa a sequencia.
# Estado global do RNG: after_each devolve o sorteio livre para nao vazar para outros testes.

const QTD_VALORES: int = 5
const SEED_N: int = 12345
const SEED_M: int = 54321


func after_each() -> void:
	randomize()


func _sequencia_apos(valor: Variant) -> Array:
	Global.aplicar_seed(valor)
	var out: Array = []
	for i in QTD_VALORES:
		out.append(randi())
	return out


func test_sem_seed_duas_aplicacoes_geram_sequencias_distintas() -> void:
	var primeira := _sequencia_apos(null)
	var segunda := _sequencia_apos(null)
	assert_true(primeira != segunda, "sem seed o RNG deve sortear")


func test_mesma_seed_aplicada_duas_vezes_gera_mesma_sequencia() -> void:
	var primeira := _sequencia_apos(SEED_N)
	var segunda := _sequencia_apos(SEED_N)
	assert_true(primeira == segunda, "mesma seed repete a sequencia")
	assert_eq(primeira.size(), QTD_VALORES, "a sequencia deve ter os 5 valores pedidos")


func test_seeds_distintas_geram_sequencias_distintas() -> void:
	var com_n := _sequencia_apos(SEED_N)
	var com_m := _sequencia_apos(SEED_M)
	assert_ne(com_n, com_m, "seeds distintas devem gerar sequencias distintas")


func test_read_raw_fora_do_web_devolve_null() -> void:
	assert_eq(SeedSource.read_raw(), null, "fora do web read_raw nao le a query e devolve null")
