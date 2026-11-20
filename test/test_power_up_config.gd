extends GutTest

const CAMINHO_INEXISTENTE := "res://ressources/nao_existe_power_ups.tres"
const CAMINHO_CURVA := "res://ressources/curva_dificuldade.tres"
const DURACAO_ADR := 5.0
const FATOR_ADR := 0.5


func test_duracao_e_fator_invalidos_caem_no_padrao_do_adr() -> void:
	var config := PowerUpConfig.new()
	for duracao: float in [0.0, -1.0]:
		config.duracao_camaleao_s = duracao
		assert_eq(config.duracao_camaleao_vigente(), DURACAO_ADR, "duracao %s do Camaleao cai em 5.0" % duracao)
		config.duracao_desacelera_s = duracao
		assert_eq(config.duracao_desacelera_vigente(), DURACAO_ADR, "duracao %s do Desacelera cai em 5.0" % duracao)
	for fator: float in [0.0, -0.5, 1.5]:
		config.fator_desacelera = fator
		assert_eq(config.fator_desacelera_vigente(), FATOR_ADR, "fator %s cai em 0.5" % fator)
	config.fator_desacelera = 1.0
	assert_eq(config.fator_desacelera_vigente(), 1.0, "fator 1.0 e aceito (limite superior de (0,1])")
	config.duracao_camaleao_s = 3.0
	assert_eq(config.duracao_camaleao_vigente(), 3.0, "duracao valida e mantida")


func test_caminho_injetavel_cai_no_padrao_e_tres_de_producao_carrega() -> void:
	var ausente := PowerUpConfig.carregar(CAMINHO_INEXISTENTE)
	assert_not_null(ausente, "caminho inexistente devolve instancia (fallback)")
	assert_eq(ausente.duracao_camaleao_vigente(), DURACAO_ADR, "fallback: duracao do Camaleao do ADR")
	assert_eq(ausente.duracao_desacelera_vigente(), DURACAO_ADR, "fallback: duracao do Desacelera do ADR")
	assert_eq(ausente.fator_desacelera_vigente(), FATOR_ADR, "fallback: fator do ADR")

	var outro_tipo := PowerUpConfig.carregar(CAMINHO_CURVA)
	assert_not_null(outro_tipo, "Resource de outro tipo devolve instancia (fallback)")
	assert_eq(outro_tipo.fator_desacelera_vigente(), FATOR_ADR, "Resource invalido: fator do ADR")

	var producao := PowerUpConfig.carregar()
	assert_eq(producao.resource_path, PowerUpConfig.CAMINHO_PADRAO, "o .tres de producao foi carregado (nao o fallback)")
	assert_eq(producao.duracao_camaleao_vigente(), DURACAO_ADR, ".tres: duracao do Camaleao = ADR")
	assert_eq(producao.duracao_desacelera_vigente(), DURACAO_ADR, ".tres: duracao do Desacelera = ADR")
	assert_eq(producao.fator_desacelera_vigente(), FATOR_ADR, ".tres: fator do Desacelera = ADR")


func test_curva_de_producao_tem_pesos_nos_4_estagios() -> void:
	var curva: DifficultyCurve = load(CAMINHO_CURVA)
	assert_eq(curva.estagios.size(), 4, "curva tem 4 estagios")
	for estagio: DifficultyStage in curva.estagios:
		var pesos: Dictionary = estagio.pesos_power_ups
		assert_false(pesos.is_empty(), "estagio tem pesos_power_ups nao vazio")
		assert_gt(float(pesos.get(&"camaleao", 0.0)), 0.0, "peso do camaleao > 0 no estagio")
		assert_gt(float(pesos.get(&"desacelera", 0.0)), 0.0, "peso do desacelera > 0 no estagio")
		assert_eq(estagio.raridade_power_up, 0.04, "raridade_power_up 0.04 no estagio")
