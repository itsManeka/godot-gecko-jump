class_name TempoConfig
extends Resource

# Duracao da partida do modo Contra o tempo (ADR 0014; D1 da f524). Caminho de producao: ressources/tempo.tres.
# Caminho ausente, Resource de outro tipo, valor nao numerico ou nao positivo: padrao do ADR, sem erro.
# O leitor devolve o Resource (cacheado pelo ResourceLoader), nunca o numero: mudar o valor vale na chamada seguinte.

const CAMINHO_PADRAO := "res://ressources/tempo.tres"
const DURACAO_PADRAO_S := 60.0

# Variant de proposito: o recurso editado a mao pode trazer tipo errado e o leitor cai no padrao
@export var duracao_s: Variant = DURACAO_PADRAO_S


# Resource por caminho: o leitor cacheia o Resource (nao o numero), entao editar o valor vale na chamada seguinte
static var _cache: Dictionary = {}


# Carrega o Resource do caminho dado; ausente ou de outro tipo = instancia com o padrao do ADR
static func carregar(caminho: String = CAMINHO_PADRAO) -> TempoConfig:
	var guardado: Variant = _cache.get(caminho)
	if guardado is TempoConfig:
		return guardado
	if not ResourceLoader.exists(caminho):
		return TempoConfig.new()
	var recurso: Resource = load(caminho)
	if recurso is TempoConfig:
		_cache[caminho] = recurso
		return recurso
	return TempoConfig.new()


# Duracao vigente em segundos: nao numerica, nao finita, 0 ou negativa cai em DURACAO_PADRAO_S
func duracao_vigente() -> float:
	if not (duracao_s is float or duracao_s is int):
		return DURACAO_PADRAO_S
	var valor: float = float(duracao_s)
	if is_nan(valor) or is_inf(valor) or valor <= 0.0:
		return DURACAO_PADRAO_S
	return valor
