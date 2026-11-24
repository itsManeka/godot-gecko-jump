extends GutTest

# f526 T1: Segunda chance = power-up de carga (duracao 0), maximo 1 guardada, sem tempo.


func before_each() -> void:
	PowerUps.restaurar_padrao()


func after_each() -> void:
	PowerUps.restaurar_padrao()


func test_registro_de_producao_restaura_segunda_chance_como_carga() -> void:
	PowerUps.restaurar_padrao()
	var resolvido := PowerUps.resolver(&"segunda_chance")
	assert_true(resolvido is PowerUpSegundaChance, "o nome segunda_chance resolve o PowerUpSegundaChance")
	assert_eq(resolvido.nome, &"segunda_chance", "nome canonico do power-up")
	assert_eq(resolvido.duracao, 0.0, "segunda_chance e carga: duracao 0, nunca temporizado")
	assert_true(PowerUps.nomes().has(&"segunda_chance"), "registro de producao contem segunda_chance")
	assert_true(PowerUps.nomes().has(&"camaleao"), "registro de producao segue com camaleao")
	assert_true(PowerUps.nomes().has(&"desacelera"), "registro de producao segue com desacelera")


func test_coletar_segunda_chance_com_temporizado_ativo_mantem_o_temporizado() -> void:
	var estado := PowerUpState.new()
	var temporizado := PowerUpDeTeste.new(&"fake_temporizado", 5.0)
	estado.coletar(temporizado)
	estado.tick(1.0)
	estado.coletar(PowerUpSegundaChance.new())
	assert_eq(estado.ativo(), temporizado, "o temporizado segue ativo")
	assert_eq(estado.restante(), 4.0, "o tempo restante nao muda")
	assert_eq(temporizado.encerramentos, 0, "o temporizado nao foi encerrado")
	assert_eq(estado.carga(), 1, "a carga foi guardada")


func test_coletar_temporizado_com_carga_guardada_mantem_carga_1() -> void:
	var estado := PowerUpState.new()
	estado.coletar(PowerUpSegundaChance.new())
	estado.coletar(PowerUpDeTeste.new(&"fake_temporizado", 5.0))
	assert_eq(estado.carga(), 1, "coletar temporizado com carga guardada mantem carga em 1")


func test_tick_longo_nao_expira_a_carga() -> void:
	var estado := PowerUpState.new()
	estado.coletar(PowerUpSegundaChance.new())
	estado.tick(1000.0)
	assert_eq(estado.carga(), 1, "tick longo nao expira a carga")


func test_consumir_carga_gasta_uma_vez_e_coletar_de_novo_volta_a_1() -> void:
	var estado := PowerUpState.new()
	estado.coletar(PowerUpSegundaChance.new())
	assert_true(estado.consumir_carga(), "1a chamada gasta a carga")
	assert_eq(estado.carga(), 0, "carga vai a 0")
	assert_false(estado.consumir_carga(), "2a chamada devolve false")
	estado.coletar(PowerUpSegundaChance.new())
	assert_eq(estado.carga(), 1, "coletar de novo apos gastar volta a 1")


func test_partida_nova_nasce_sem_carga() -> void:
	var estado := PowerUpState.new()
	assert_eq(estado.carga(), 0, "partida nova sem carga")
