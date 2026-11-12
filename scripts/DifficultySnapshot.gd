# Foto imutavel dos parametros de dificuldade num instante (saida de DifficultyCurve.avaliar).
# Campos so por leitura: sem setters; mecanicas devolvida como copia.
class_name DifficultySnapshot
extends RefCounted

var _scroll: float
var _speed_moveis: float
var _k: int
var _proporcao_estaticas: float
var _mecanicas: Array[StringName]


func _init(
	scroll: float = DifficultyStage.SCROLL_PADRAO,
	speed_moveis: float = DifficultyStage.SPEED_PADRAO,
	k: int = DifficultyStage.K_PADRAO,
	proporcao_estaticas: float = DifficultyStage.PROPORCAO_PADRAO,
	mecanicas: Array[StringName] = []
) -> void:
	_scroll = scroll
	_speed_moveis = speed_moveis
	_k = k
	_proporcao_estaticas = proporcao_estaticas
	_mecanicas = mecanicas.duplicate()


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


# Foto vigente de um estado de dificuldade; sem estado (cena isolada, antes da injecao) = estagio 0
static func de(estado: DifficultyState) -> DifficultySnapshot:
	if estado == null:
		return DifficultySnapshot.new()
	return estado.snapshot()
