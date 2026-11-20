class_name PowerUpConfig
extends Resource

# Valores rebalanceaveis dos power-ups temporizados (ADR 0014). Caminho de producao: ressources/power_ups.tres.
# Caminho ausente ou Resource de outro tipo: padrao do ADR, sem erro. Valor fora da faixa: padrao do ADR.

const CAMINHO_PADRAO := "res://ressources/power_ups.tres"
const DURACAO_PADRAO_S := 5.0
const FATOR_PADRAO := 0.5

@export var duracao_camaleao_s: float = DURACAO_PADRAO_S
@export var duracao_desacelera_s: float = DURACAO_PADRAO_S
@export var fator_desacelera: float = FATOR_PADRAO


# Carrega o Resource do caminho dado; ausente ou de outro tipo = instancia com o padrao do ADR
static func carregar(caminho: String = CAMINHO_PADRAO) -> PowerUpConfig:
	if not ResourceLoader.exists(caminho):
		return PowerUpConfig.new()
	var recurso: Resource = load(caminho)
	if recurso is PowerUpConfig:
		return recurso
	return PowerUpConfig.new()


# Duracao vigente do Camaleao: ausente, 0 ou negativa cai em DURACAO_PADRAO_S
func duracao_camaleao_vigente() -> float:
	return _duracao(duracao_camaleao_s)


# Duracao vigente do Desacelera: ausente, 0 ou negativa cai em DURACAO_PADRAO_S
func duracao_desacelera_vigente() -> float:
	return _duracao(duracao_desacelera_s)


# Fator vigente do Desacelera: fora de (0,1] cai em FATOR_PADRAO (1.0 e aceito)
func fator_desacelera_vigente() -> float:
	return fator_desacelera if fator_desacelera > 0.0 and fator_desacelera <= 1.0 else FATOR_PADRAO


func _duracao(valor: float) -> float:
	return valor if valor > 0.0 else DURACAO_PADRAO_S
