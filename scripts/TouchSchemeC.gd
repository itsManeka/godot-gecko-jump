class_name TouchSchemeC
extends TouchScheme

# Modo C: metades + 2o toque. Segurar uma metade anda para o lado dela no press (sem atraso). Um 2o toque em qualquer
# ponto pede 1 pulso de pulo na direcao do dedo que anda. Dois toques em metades opostas com intervalo menor que
# TouchTuning.JANELA_SIMULTANEO_MS (o 1o ainda sem "hold previo") valem como simultaneos: cancela o lateral e pula
# reto. Depois disso o lateral so volta com um novo press (Q4): soltar um dos dois dedos nao reativa o outro.
# A direcao e o lado do dedo, decididos no press (metade: x < largura/2 = esquerda; x == metade = direita, como
# TouchClassifier.lado_de).

const IMPLEMENTADO: bool = true
const MAX_DEDOS: int = 2

# dedo -> lado (-1 esquerda, 1 direita) dos dedos aceitos pelo esquema (no maximo MAX_DEDOS).
var _lados: Dictionary = {}
# Dedo que dirige o lateral (-1 = nenhum) e o instante do seu press.
var _caminhante: int = -1
var _t_caminhante_ms: int = 0
var _lateral: int = 0
var _pulo_pendente: bool = false


func _lado_de(pos: Vector2) -> int:
	return -1 if pos.x < largura_visivel / 2.0 else 1


func _ao_pressionar(dedo: int, t_ms: int, pos: Vector2) -> void:
	if _lados.size() >= MAX_DEDOS:
		_dedos.erase(dedo)  # 3o dedo: ignorado
		return
	var lado: int = _lado_de(pos)
	if _lados.is_empty() or _caminhante == -1:
		# 1o toque (ou novo press com os dedos restantes mudos): anda para o lado dele.
		_lados[dedo] = lado
		_caminhante = dedo
		_t_caminhante_ms = t_ms
		_lateral = lado
		return
	# 2o toque com um dedo andando: pulso de pulo.
	var oposto: bool = lado != _lados[_caminhante]
	var simultaneo: bool = oposto and (t_ms - _t_caminhante_ms) < TouchTuning.JANELA_SIMULTANEO_MS
	_lados[dedo] = lado
	if simultaneo:
		_caminhante = -1
		_lateral = 0
	_pulo_pendente = true


func _ao_soltar(dedo: int, _t_ms: int) -> void:
	_esquecer(dedo)


func _ao_cancelar(dedo: int) -> void:
	_esquecer(dedo)


func _esquecer(dedo: int) -> void:
	_lados.erase(dedo)
	if dedo == _caminhante:
		_caminhante = -1
		_lateral = 0


func _ao_cancelar_tudo() -> void:
	_lados.clear()
	_caminhante = -1
	_lateral = 0
	_pulo_pendente = false


func _intencao(_t_ms: int) -> Dictionary:
	var r: Dictionary = TouchScheme.intencao_neutra()
	r["esquerda"] = _lateral < 0
	r["direita"] = _lateral > 0
	r["pulo"] = _pulo_pendente
	_pulo_pendente = false
	return r
