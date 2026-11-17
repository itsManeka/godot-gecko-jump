class_name TouchSchemeA
extends TouchScheme

# Modo A: arrastar + flick. Um dedo em qualquer lugar da tela (o 1o aceito; os demais sao ignorados).
# - Lateral: deslocamento horizontal relativo a uma ancora que acompanha o dedo. Passou de ZONA_MORTA_PX para um lado =
#   anda para ele e a ancora vai junto com o dedo (extremo do arrasto); o lado so inverte quando o dedo volta mais que
#   ZONA_MORTA_PX contra a direcao, sem recuar ate o ponto de contato. Dedo que nunca saiu da zona morta = parado.
# - Pulo: flick para cima (dy >= FLICK_DY_MIN_PX dentro de FLICK_JANELA_MS) pede 1 pulo (evento). O lateral do instante
#   decide reto (zona morta) ou diagonal. Cada flick consome o historico: o proximo exige novo deslocamento.
# Enquanto IMPLEMENTADO for false a TouchControls usa o esquema legado neste modo.
const IMPLEMENTADO: bool = true

const NENHUM: int = 0
const ESQUERDA: int = -1
const DIREITA: int = 1

var _dedo_principal: int = -1
var _ancora_x: float = 0.0
var _lado: int = NENHUM
# Amostras (x = t_ms, y = posicao y) dentro da janela do flick.
var _amostras: Array[Vector2] = []
var _pulo_pendente: bool = false


func _ao_pressionar(dedo: int, t_ms: int, pos: Vector2) -> void:
	if _dedo_principal != -1:
		_dedos.erase(dedo)  # 2o dedo: ignorado
		return
	_dedo_principal = dedo
	_ancora_x = pos.x
	_lado = NENHUM
	_pulo_pendente = false
	_amostras = [Vector2(float(t_ms), pos.y)]


func _ao_mover(dedo: int, pos: Vector2, t_ms: int) -> void:
	if dedo != _dedo_principal:
		return
	_atualizar_lado(pos.x)
	_detectar_flick(pos.y, t_ms)


func _atualizar_lado(x: float) -> void:
	var zona: float = TouchTuning.ZONA_MORTA_PX
	var dx: float = x - _ancora_x
	if _lado == DIREITA:
		if dx > 0.0:
			_ancora_x = x
		elif dx < -zona:
			_lado = ESQUERDA
			_ancora_x = x
	elif _lado == ESQUERDA:
		if dx < 0.0:
			_ancora_x = x
		elif dx > zona:
			_lado = DIREITA
			_ancora_x = x
	elif dx > zona:
		_lado = DIREITA
		_ancora_x = x
	elif dx < -zona:
		_lado = ESQUERDA
		_ancora_x = x


func _detectar_flick(y: float, t_ms: int) -> void:
	_amostras.append(Vector2(float(t_ms), y))
	var corte: float = float(t_ms - TouchTuning.FLICK_JANELA_MS)
	while _amostras.size() > 1 and _amostras[0].x < corte:
		_amostras.pop_front()
	var y_max: float = y
	for a in _amostras:
		y_max = maxf(y_max, a.y)
	if y_max - y >= TouchTuning.FLICK_DY_MIN_PX:
		_pulo_pendente = true
		_amostras = [Vector2(float(t_ms), y)]


func _ao_soltar(dedo: int, _t_ms: int) -> void:
	if dedo == _dedo_principal:
		_zerar()


func _ao_cancelar(dedo: int) -> void:
	if dedo == _dedo_principal:
		_zerar()


func _ao_cancelar_tudo() -> void:
	_zerar()


func _zerar() -> void:
	_dedo_principal = -1
	_lado = NENHUM
	_ancora_x = 0.0
	_amostras = []
	_pulo_pendente = false


func _intencao(_t_ms: int) -> Dictionary:
	var r: Dictionary = TouchScheme.intencao_neutra()
	if _dedo_principal == -1:
		return r
	r["esquerda"] = _lado == ESQUERDA
	r["direita"] = _lado == DIREITA
	r["pulo"] = _pulo_pendente
	_pulo_pendente = false
	return r
