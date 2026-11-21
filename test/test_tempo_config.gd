extends GutTest

# Leitor da duracao do Contra o tempo (ressources/tempo.tres): fallback de 60 s e limite lido a cada chamada.

const CAMINHO_INEXISTENTE := "res://ressources/nao_existe_tempo.tres"
const CAMINHO_CURVA := "res://ressources/curva_dificuldade.tres"

var _original: Variant = null


func before_each() -> void:
	_original = TempoConfig.carregar().duracao_s
	Global.tempo_inicial_s = 0.0


func after_each() -> void:
	TempoConfig.carregar().duracao_s = _original
	Global.tempo_inicial_s = 0.0


func test_tres_versionado_carrega_60() -> void:
	var producao := TempoConfig.carregar()
	assert_eq(producao.resource_path, TempoConfig.CAMINHO_PADRAO, "o .tres de producao foi carregado (nao o fallback)")
	assert_eq(float(producao.duracao_s), 60.0, ".tres versionado guarda 60")
	assert_eq(producao.duracao_vigente(), 60.0, ".tres: duracao vigente = 60 (valor do ADR)")


func test_valor_zero_cai_em_60() -> void:
	var config := TempoConfig.new()
	config.duracao_s = 0.0
	assert_eq(config.duracao_vigente(), 60.0, "valor 0 cai em 60")


func test_valor_negativo_cai_em_60() -> void:
	var config := TempoConfig.new()
	config.duracao_s = -5.0
	assert_eq(config.duracao_vigente(), 60.0, "valor negativo cai em 60")


func test_tipo_errado_cai_em_60() -> void:
	var config := TempoConfig.new()
	config.duracao_s = "abc"
	assert_eq(config.duracao_vigente(), 60.0, "String cai em 60")


func test_recurso_ausente_ou_de_outro_tipo_cai_em_60() -> void:
	assert_eq(TempoConfig.carregar(CAMINHO_INEXISTENTE).duracao_vigente(), 60.0, "recurso ausente cai em 60")
	assert_eq(TempoConfig.carregar(CAMINHO_CURVA).duracao_vigente(), 60.0, "Resource de outro tipo cai em 60")


func test_valor_valido_e_mantido() -> void:
	var config := TempoConfig.new()
	config.duracao_s = 45
	assert_eq(config.duracao_vigente(), 45.0, "int positivo e aceito")
	config.duracao_s = 12.5
	assert_eq(config.duracao_vigente(), 12.5, "float positivo e mantido")


func test_mudar_o_tres_muda_o_limite_na_proxima_chamada() -> void:
	assert_eq(Global.limite_tempo_s(), 60.0, "limite inicial vem do .tres")
	TempoConfig.carregar().duracao_s = 20.0
	assert_eq(Global.limite_tempo_s(), 20.0, "valor novo do Resource vale na chamada seguinte (nao cacheia o numero)")


func test_seam_aplicado_depois_vale_na_proxima_chamada() -> void:
	assert_eq(Global.limite_tempo_s(), 60.0, "antes do seam: limite do .tres")
	Global.aplicar_tempo_inicial("5", true)
	assert_eq(Global.limite_tempo_s(), 5.0, "seam aplicado depois vale (ordem de init)")
	Global.aplicar_tempo_inicial("5", false)
	assert_eq(Global.limite_tempo_s(), 60.0, "release ignora o seam e volta ao .tres")
