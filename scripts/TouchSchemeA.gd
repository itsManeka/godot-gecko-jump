class_name TouchSchemeA
extends TouchScheme

# Modo A: arrastar + flick. Um dedo em qualquer lugar da tela (o 1o aceito; os demais sao ignorados).
# - Lateral: deslocamento horizontal relativo a uma ancora que acompanha o dedo. Passou da zona morta (px da
#   sensibilidade, TouchTuning.zona_morta_a) para um lado =
#   anda para ele e a ancora vai junto com o dedo (extremo do arrasto); o lado so inverte quando o dedo volta mais que
#   a zona morta contra a direcao, sem recuar ate o ponto de contato. Dedo que nunca saiu da zona morta = parado.
# - Pulo: flick para cima (dy >= dy minimo da sensibilidade, TouchTuning.flick_dy_min_a, dentro de FLICK_JANELA_MS) pede
#   1 pulo (evento). O lateral do instante
#   decide reto (zona morta) ou diagonal. Cada flick consome o historico e desarma o esquema: o proximo so vale depois
#   de o dedo parar ou recuar para baixo (TouchTuning.REARME_*), entao arrasto vertical continuo gera UM pulso.
# Enquanto IMPLEMENTADO for false a TouchControls usa o esquema legado neste modo.
const IMPLEMENTADO: bool = true

# Sensibilidade do modo A (TouchTuning.SENSIBILIDADE_*; a TouchControls injeta o valor do Global ao criar o esquema e
# ao mudar): quanto maior, menores os limiares. Valor invalido cai no padrao pela mesma funcao do store.
var sensibilidade: float = TouchTuning.SENSIBILIDADE_PADRAO:
	set(valor):
		sensibilidade = TouchTuning.sensibilidade_de_valor(valor)

const NENHUM: int = 0
const ESQUERDA: int = -1
const DIREITA: int = 1

var _dedo_principal: int = -1
var _ancora_x: float = 0.0
var _lado: int = NENHUM
# Amostras (x = t_ms, y = posicao y) dentro da janela do flick.
var _amostras: Array[Vector2] = []
var _pulo_pendente: bool = false
# Rearme: depois de um flick so aceita outro com o dedo parado ou recuado (TouchTuning.REARME_*).
var _armado: bool = true
var _y_topo: float = 0.0


func _ao_pressionar(dedo: int, t_ms: int, pos: Vector2) -> void:
	if _dedo_principal != -1:
		_dedos.erase(dedo)  # 2o dedo: ignorado
		return
	_dedo_principal = dedo
	_ancora_x = pos.x
	_lado = NENHUM
	_pulo_pendente = false
	_armado = true
	_y_topo = pos.y
	_amostras = [Vector2(float(t_ms), pos.y)]


func _ao_mover(dedo: int, pos: Vector2, t_ms: int) -> void:
	if dedo != _dedo_principal:
		return
	_atualizar_lado(pos.x)
	_detectar_flick(pos.y, t_ms)


func _atualizar_lado(x: float) -> void:
	var zona: float = TouchTuning.zona_morta_a(sensibilidade)
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


func _tentar_rearmar(y: float, t_ms: int) -> void:
	_y_topo = minf(_y_topo, y)
	if y - _y_topo >= TouchTuning.REARME_RECUO_PX:
		_armado = true
		_amostras = [Vector2(float(t_ms), y)]
		return
	var span: float = float(t_ms) - _amostras[0].x
	if span >= float(TouchTuning.REARME_PARADO_MS) and absf(_amostras[0].y - y) / span < TouchTuning.REARME_VELOCIDADE_PX_MS:
		_armado = true


func _detectar_flick(y: float, t_ms: int) -> void:
	_amostras.append(Vector2(float(t_ms), y))
	if not _armado:
		_tentar_rearmar(y, t_ms)
	var corte: float = float(t_ms - TouchTuning.FLICK_JANELA_MS)
	# Mantem a ultima amostra fora da janela como referencia: com eventos espacados (FPS baixo, issue #48) o dedo que
	# andou >= FLICK_DY_MIN_PX entre dois eventos seguidos ainda conta; gesto lento (muitos eventos) segue nao contando.
	# Por isso a janela efetiva e maior que FLICK_JANELA_MS: com eventos de 16 ms chega a ~166 ms (150 + 1 evento).
	while _amostras.size() > 1 and _amostras[1].x < corte:
		_amostras.pop_front()
	if not _armado:
		return
	var y_max: float = y
	for a in _amostras:
		y_max = maxf(y_max, a.y)
	if y_max - y >= TouchTuning.flick_dy_min_a(sensibilidade):
		_pulo_pendente = true
		_armado = false
		_y_topo = y
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
	_armado = true
	_y_topo = 0.0


func _intencao(_t_ms: int) -> Dictionary:
	var r: Dictionary = TouchScheme.intencao_neutra()
	if _dedo_principal == -1:
		return r
	r["esquerda"] = _lado == ESQUERDA
	r["direita"] = _lado == DIREITA
	r["pulo"] = _pulo_pendente
	_pulo_pendente = false
	return r
