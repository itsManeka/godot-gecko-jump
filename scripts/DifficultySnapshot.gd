# Foto imutavel dos parametros de dificuldade num instante (saida de DifficultyCurve.avaliar).
# Campos so por leitura: sem setters; mecanicas devolvida como copia.
class_name DifficultySnapshot
extends RefCounted

var _scroll: float
var _speed_moveis: float
var _k: int
var _proporcao_estaticas: float
var _mecanicas: Array[StringName]
var _largura_plataforma: float
var _atraso_desmoronar: float


# Parametros novos entram sempre no fim: chamadas posicionais antigas (ate o 4o) continuam validas.
func _init(
	scroll: float = DifficultyStage.SCROLL_PADRAO,
	speed_moveis: float = DifficultyStage.SPEED_PADRAO,
	k: int = DifficultyStage.K_PADRAO,
	proporcao_estaticas: float = DifficultyStage.PROPORCAO_PADRAO,
	mecanicas: Array[StringName] = [],
	largura_plataforma: float = DifficultyStage.LARGURA_PLATAFORMA_PADRAO,
	atraso_desmoronar: float = DifficultyStage.ATRASO_DESMORONAR_PADRAO
) -> void:
	_scroll = scroll
	_speed_moveis = speed_moveis
	_k = k
	_proporcao_estaticas = proporcao_estaticas
	_mecanicas = mecanicas.duplicate()
	_largura_plataforma = largura_plataforma
	_atraso_desmoronar = atraso_desmoronar


func get_scroll() -> float:
	return _scroll


func get_speed_moveis() -> float:
	return _speed_moveis


func get_k() -> int:
	return _k


func get_proporcao_estaticas() -> float:
	return _proporcao_estaticas


func get_mecanicas() -> Array[StringName]:
	return _mecanicas.duplicate()


func get_largura_plataforma() -> float:
	return _largura_plataforma


func get_atraso_desmoronar() -> float:
	return _atraso_desmoronar


# Foto vigente de um estado de dificuldade; sem estado (cena isolada, antes da injecao) = estagio 0
static func de(estado: DifficultyState) -> DifficultySnapshot:
	if estado == null:
		return DifficultySnapshot.new()
	return estado.snapshot()
