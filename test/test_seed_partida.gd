extends GutTest

# f528 T1: SeedPartida.validar e a borda da Stage (semente_partida -> ScrollLevel.semente). Cobre C741-C744:
# inteiro valido passa inalterado; tudo que nao e int na faixa 0..MAX_SEED vira null; Stage com seed invalida
# nasce sem seed (nenhuma linha com rng); Stage com 42 entrega 42 (regressao f517); SeedSource.decide valido
# passa em validar.

const STAGE := "res://scenes/Stage.tscn"


func _stage_com_semente(valor: Variant) -> Node:
	var stage: Node = load(STAGE).instantiate()
	stage.semente_partida = valor
	add_child_autofree(stage)
	return stage


# C741: inteiros validos devolvidos com igualdade exata e tipo int (limites 0 e MAX_SEED incluidos)
func test_validar_devolve_o_proprio_int_nos_limites() -> void:
	for valor in [0, 20000, 2147483647]:
		var devolvido: Variant = SeedPartida.validar(valor)
		assert_eq(typeof(devolvido), TYPE_INT, "validar(%s) deveria devolver int" % valor)
		assert_eq(devolvido, valor, "validar(%s) deveria devolver o proprio valor" % valor)


# C742 [mutacao]: entradas que nao sao int na faixa devolvem null (por valor, nao por not is_int)
func test_validar_devolve_null_para_entradas_invalidas() -> void:
	var invalidas: Array = [-1, 2147483648, "123", "abc", 5.0, true, [1], {}, null]
	for valor in invalidas:
		assert_null(SeedPartida.validar(valor), "entrada invalida deveria devolver null")


# C743 [mutacao]: Stage com semente nao inteira nasce sem seed; nenhuma linha passa por RowSeed (sem 0 espurio)
func test_stage_com_semente_nao_inteira_nasce_sem_seed() -> void:
	for valor in ["abc", 3.7]:
		var stage := _stage_com_semente(valor)
		var scroll_level: ScrollLevel = stage.get_node("ScrollLevel") as ScrollLevel
		assert_null(scroll_level.semente, "semente invalida deveria chegar ao ScrollLevel como null")
		for linha in scroll_level.get_node("RunningPlatforms").get_children():
			assert_null(linha.rng, "com semente invalida %s a linha %s nao deveria ter rng" % [str(valor), linha.name])
			assert_null(linha.rng_cor_movel, "com semente invalida %s a linha %s nao deveria ter rng_cor_movel" % [str(valor), linha.name])


# Regressao f517: semente valida 42 chega ao ScrollLevel inalterada
func test_stage_com_semente_42_entrega_42_ao_scroll_level() -> void:
	var stage := _stage_com_semente(42)
	var scroll_level: ScrollLevel = stage.get_node("ScrollLevel") as ScrollLevel
	assert_eq(scroll_level.semente, 42, "semente_partida 42 deveria chegar ao ScrollLevel como 42")


# C744: saida de SeedSource.decide(raw, true) com valor valido passa em validar inalterada (limite MAX_SEED)
func test_seed_source_decide_valido_passa_inalterada_em_validar() -> void:
	for raw in ["0", "20000", "2147483647"]:
		var decidido: Variant = SeedSource.decide(raw, true)
		assert_eq(SeedPartida.validar(decidido), decidido, "decide(%s, true) deveria passar em validar inalterada" % raw)
		assert_not_null(decidido, "decide(%s, true) deveria aceitar valor valido" % raw)
