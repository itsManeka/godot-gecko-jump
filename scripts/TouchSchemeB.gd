class_name TouchSchemeB
extends TouchScheme

# Modo B: dois polegares. Metade esquerda (TouchClassifier.lado_de; x == metade = direita) dirige: o deslocamento
# horizontal do dedo em relacao ao ponto de contato (zona morta TouchTuning.ZONA_MORTA_PX; a ancora segue o dedo a cada
# deslocamento valido) escolhe esquerda/direita, e o lado vale no chao e no ar. Metade direita: pulso de `jump` no
# press, sem limiar de tempo. O lado do dedo e decidido no press e fica fixo ate soltar; cada metade tem 1 vaga, entao
# um terceiro dedo (ou um 2o na mesma metade) e ignorado ate a vaga livrar.
const IMPLEMENTADO: bool = true

const SEM_DEDO: int = -1

var _dedo_dirige: int = SEM_DEDO
var _dedo_pulo: int = SEM_DEDO
var _ancora_x: float = 0.0
# -1 esquerda, 0 parado, 1 direita.
var _direcao: int = 0
var _pulo_pendente: bool = false


func _ao_pressionar(dedo: int, _t_ms: int, pos: Vector2) -> void:
	var lado: int = TouchClassifier.lado_de(pos.x, largura_visivel)
	if lado == TouchClassifier.Lado.ESQUERDA and _dedo_dirige == SEM_DEDO:
		_dedo_dirige = dedo
		_ancora_x = pos.x
		_direcao = 0
	elif lado == TouchClassifier.Lado.DIREITA and _dedo_pulo == SEM_DEDO:
		_dedo_pulo = dedo
		_pulo_pendente = true
	else:
		_dedos.erase(dedo)  # vaga da metade ocupada: dedo ignorado


func _ao_mover(dedo: int, pos: Vector2, _t_ms: int) -> void:
	if dedo != _dedo_dirige:
		return
	var dx: float = pos.x - _ancora_x
	if absf(dx) > TouchTuning.ZONA_MORTA_PX:
		_direcao = 1 if dx > 0.0 else -1
		_ancora_x = pos.x


func _ao_soltar(dedo: int, _t_ms: int) -> void:
	_liberar(dedo)


func _ao_cancelar(dedo: int) -> void:
	_liberar(dedo)


func _ao_cancelar_tudo() -> void:
	_dedo_dirige = SEM_DEDO
	_dedo_pulo = SEM_DEDO
	_direcao = 0
	_pulo_pendente = false


func _intencao(_t_ms: int) -> Dictionary:
	var r: Dictionary = TouchScheme.intencao_neutra()
	r["esquerda"] = _direcao < 0
	r["direita"] = _direcao > 0
	r["pulo"] = _pulo_pendente
	_pulo_pendente = false
	return r


func _liberar(dedo: int) -> void:
	if dedo == _dedo_dirige:
		_dedo_dirige = SEM_DEDO
		_direcao = 0
	elif dedo == _dedo_pulo:
		_dedo_pulo = SEM_DEDO
