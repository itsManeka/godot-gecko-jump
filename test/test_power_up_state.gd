extends GutTest

const NOME_A: StringName = &"fake_a"
const NOME_B: StringName = &"fake_b"
const NOME_CARGA: StringName = &"fake_carga"


class _FakeTemporizadoA extends PowerUpDeTeste:
	func _init() -> void:
		super(&"fake_a", 5.0)


class _FakeTemporizadoB extends PowerUpDeTeste:
	func _init() -> void:
		super(&"fake_b", 3.0)


class _FakeCarga extends PowerUpDeTeste:
	func _init() -> void:
		super(&"fake_carga", 0.0)


func before_each() -> void:
	PowerUps.limpar()


func after_each() -> void:
	PowerUps.restaurar_padrao()


func test_estado_novo_nasce_zerado() -> void:
	var estado := PowerUpState.new()
	assert_null(estado.ativo(), "estado novo sem temporizado ativo")
	assert_eq(estado.restante(), 0.0, "estado novo sem tempo restante")
	assert_eq(estado.carga(), 0, "estado novo sem carga")
	estado.tick(1.0)
	assert_null(estado.ativo(), "tick sem ativo nao cria nada")


func test_coletar_temporizado_ativa_e_guarda_duracao_cheia() -> void:
	var estado := PowerUpState.new()
	var a := _FakeTemporizadoA.new()
	estado.coletar(a)
	assert_eq(estado.ativo(), a, "o coletado fica ativo")
	assert_eq(a.ativacoes, 1, "ao_ativar chamado 1x")
	assert_eq(estado.restante(), 5.0, "duracao cheia ao coletar")


func test_coletar_b_com_a_ativo_encerra_a_e_ativa_b_com_duracao_cheia() -> void:
	var estado := PowerUpState.new()
	var a := _FakeTemporizadoA.new()
	var b := _FakeTemporizadoB.new()
	estado.coletar(a)
	estado.tick(2.0)
	estado.coletar(b)
	assert_eq(a.encerramentos, 1, "ao_encerrar de A chamado exatamente 1x")
	assert_eq(b.ativacoes, 1, "ao_ativar de B chamado 1x")
	assert_eq(b.encerramentos, 0, "B ainda nao encerrou")
	assert_eq(estado.ativo(), b, "so B ativo")
	assert_eq(estado.restante(), 3.0, "B com duracao cheia")


func test_coletar_a_com_a_ativo_reinicia_duracao_sem_encerrar() -> void:
	var estado := PowerUpState.new()
	var a := _FakeTemporizadoA.new()
	estado.coletar(a)
	estado.tick(4.0)
	assert_eq(estado.restante(), 1.0, "restante antes de recoletar")
	var outra_a := _FakeTemporizadoA.new()
	estado.coletar(outra_a)
	assert_eq(estado.restante(), 5.0, "duracao reiniciada")
	assert_eq(a.encerramentos, 0, "ao_encerrar NAO chamado ao recoletar o mesmo")
	assert_eq(estado.ativo(), a, "continua o A original ativo")


func test_carga_nao_passa_de_1_e_nao_depende_de_temporizado() -> void:
	var estado := PowerUpState.new()
	estado.coletar(_FakeCarga.new())
	estado.coletar(_FakeCarga.new())
	assert_eq(estado.carga(), 1, "coletar com 1 guardada nao soma")
	estado.coletar(_FakeTemporizadoA.new())
	assert_eq(estado.carga(), 1, "coletar temporizado nao altera a carga")
	estado.tick(10.0)
	assert_eq(estado.carga(), 1, "expirar o temporizado nao altera a carga")
	assert_true(estado.consumir_carga(), "consumir gasta a carga")
	assert_eq(estado.carga(), 0, "carga vai a 0")
	assert_false(estado.consumir_carga(), "sem carga nao consome")


func test_carga_nao_altera_temporizado_ativo() -> void:
	var estado := PowerUpState.new()
	var a := _FakeTemporizadoA.new()
	estado.coletar(a)
	estado.tick(1.0)
	estado.coletar(_FakeCarga.new())
	assert_eq(estado.ativo(), a, "carga nao troca o temporizado")
	assert_eq(estado.restante(), 4.0, "carga nao mexe no tempo")
	assert_eq(a.encerramentos, 0, "carga nao encerra o temporizado")


func test_expirar_por_tempo_encerra_uma_unica_vez() -> void:
	var estado := PowerUpState.new()
	var a := _FakeTemporizadoA.new()
	estado.coletar(a)
	estado.tick(4.9)
	assert_eq(a.encerramentos, 0, "antes do tempo nao encerra")
	estado.tick(0.2)
	assert_eq(a.encerramentos, 1, "expirar chama ao_encerrar 1x")
	assert_null(estado.ativo(), "ativo fica vazio")
	estado.tick(1.0)
	estado.tick(1.0)
	assert_eq(a.encerramentos, 1, "tick apos expirar nao chama de novo")
	assert_null(estado.ativo(), "ativo continua vazio")
	assert_eq(estado.restante(), 0.0, "restante zerado")


func test_registro_resolver_nome_desconhecido_devolve_null_sem_erro() -> void:
	assert_null(PowerUps.resolver(&"inexistente"), "nome desconhecido devolve null")
	PowerUps.registrar(NOME_A, _FakeTemporizadoA)
	assert_null(PowerUps.resolver(NOME_B), "nome nao registrado continua null")


func test_registro_registrar_resolver_e_limpar() -> void:
	PowerUps.registrar(NOME_A, _FakeTemporizadoA)
	var resolvido := PowerUps.resolver(NOME_A)
	assert_true(resolvido is _FakeTemporizadoA, "resolver devolve instancia do script registrado")
	assert_ne(resolvido, PowerUps.resolver(NOME_A), "cada resolver cria instancia nova")
	PowerUps.limpar()
	assert_null(PowerUps.resolver(NOME_A), "limpar esvazia o registro")


# C606 (f522 T3): o registro de producao contem o Camaleao; fake e PowerUpDeTeste ficam de fora.
# Substitui a conferencia do registro vazio (`size() == 0`): com os power-ups reais, o padrao tem nomes.
func test_registro_de_producao_tem_camaleao() -> void:
	PowerUps.registrar(NOME_A, _FakeTemporizadoA)
	PowerUps.restaurar_padrao()
	assert_true(PowerUps.nomes().has(&"camaleao"), "registro de producao contem camaleao")
	assert_eq(PowerUps.nomes().size(), 3, "camaleao, desacelera e segunda_chance sao os nomes de producao (f522 T4, f526 T1)")
	assert_true(PowerUps.nomes().has(&"desacelera"), "registro de producao contem desacelera")
	assert_false(PowerUps.nomes().has(NOME_A), "fake nao sobrevive ao restaurar_padrao")
	assert_null(PowerUps.resolver(NOME_A), "fake nao sobrevive ao restaurar_padrao")
	assert_false(PowerUps.nomes().has(PowerUpDeTeste.NOME_PADRAO), "PowerUpDeTeste nao esta no registro de producao")
	assert_null(PowerUps.resolver(PowerUpDeTeste.NOME_PADRAO), "PowerUpDeTeste nao resolve no registro de producao")
	var camaleao := PowerUps.resolver(&"camaleao")
	assert_ne(camaleao, null, "resolver devolve instancia do Camaleao de producao")
	assert_true(camaleao is PowerUpCamaleao, "o nome camaleao resolve o PowerUpCamaleao")
	assert_eq(camaleao.nome, &"camaleao", "nome do power-up resolvido")
	var desacelera := PowerUps.resolver(&"desacelera")
	assert_true(desacelera is PowerUpDesacelera, "o nome desacelera resolve o PowerUpDesacelera")
	assert_eq(desacelera.nome, &"desacelera", "nome do Desacelera resolvido")
