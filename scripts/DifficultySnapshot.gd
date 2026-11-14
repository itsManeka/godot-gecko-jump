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
var _proporcao_cicladoras: float
var _periodo_ciclo: float
var _amplitude_movimento: float
var _periodo_movimento: float
var _proporcao_oscilantes: float
var _proporcao_vai_e_vem: float
var _variacao_speed_linha: float


# Parametros novos entram sempre no fim: chamadas posicionais antigas (ate o 9o) continuam validas.
func _init(
	scroll: float = DifficultyStage.SCROLL_PADRAO,
	speed_moveis: float = DifficultyStage.SPEED_PADRAO,
	k: int = DifficultyStage.K_PADRAO,
	proporcao_estaticas: float = DifficultyStage.PROPORCAO_PADRAO,
	mecanicas: Array[StringName] = [],
	largura_plataforma: float = DifficultyStage.LARGURA_PLATAFORMA_PADRAO,
	atraso_desmoronar: float = DifficultyStage.ATRASO_DESMORONAR_PADRAO,
	proporcao_cicladoras: float = DifficultyStage.PROPORCAO_CICLADORAS_PADRAO,
	periodo_ciclo: float = DifficultyStage.PERIODO_CICLO_PADRAO,
	amplitude_movimento: float = DifficultyStage.AMPLITUDE_MOVIMENTO_PADRAO,
	periodo_movimento: float = DifficultyStage.PERIODO_MOVIMENTO_PADRAO,
	proporcao_oscilantes: float = DifficultyStage.PROPORCAO_OSCILANTES_PADRAO,
	proporcao_vai_e_vem: float = DifficultyStage.PROPORCAO_VAI_E_VEM_PADRAO,
	variacao_speed_linha: float = DifficultyStage.VARIACAO_SPEED_LINHA_PADRAO
) -> void:
	_scroll = scroll
	_speed_moveis = speed_moveis
	_k = k
	_proporcao_estaticas = proporcao_estaticas
	_mecanicas = mecanicas.duplicate()
	_largura_plataforma = largura_plataforma
	_atraso_desmoronar = atraso_desmoronar
	_proporcao_cicladoras = proporcao_cicladoras
	_periodo_ciclo = periodo_ciclo
	_amplitude_movimento = amplitude_movimento
	_periodo_movimento = periodo_movimento
	_proporcao_oscilantes = proporcao_oscilantes
	_proporcao_vai_e_vem = proporcao_vai_e_vem
	_variacao_speed_linha = variacao_speed_linha


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


func get_proporcao_cicladoras() -> float:
	return _proporcao_cicladoras


func get_periodo_ciclo() -> float:
	return _periodo_ciclo


func get_amplitude_movimento() -> float:
	return _amplitude_movimento


func get_periodo_movimento() -> float:
	return _periodo_movimento


func get_proporcao_oscilantes() -> float:
	return _proporcao_oscilantes


func get_proporcao_vai_e_vem() -> float:
	return _proporcao_vai_e_vem


func get_variacao_speed_linha() -> float:
	return _variacao_speed_linha


# Foto vigente de um estado de dificuldade; sem estado (cena isolada, antes da injecao) = estagio 0
static func de(estado: DifficultyState) -> DifficultySnapshot:
	if estado == null:
		return DifficultySnapshot.new()
	return estado.snapshot()
