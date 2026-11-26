class_name TouchScheme
extends RefCounted

# Contrato de um esquema de toque (modos A, B e C da f493), sem cena e sem Input: tudo entra por parametro e a saida
# e a `intencao`. Quem traduz a intencao em acoes de input e a TouchControls (posse, pulso de 2 ticks, inercia fora
# de partida). Os esquemas sobrescrevem so os ganchos `_ao_*` e `_intencao`; a base cuida de zona morta, de quais
# dedos estao ativos (index desconhecido e ignorado) e do cancelamento.

# Largura visivel atual (a TouchControls atualiza antes de cada press) e zonas mortas (botao de pausa, Pular do tutorial).
var largura_visivel: float = 360.0
var zonas_mortas: Array[Rect2] = []

# Dedos aceitos e ainda na tela (index -> true).
var _dedos: Dictionary = {}


# {esquerda: bool, direita: bool, pulo: bool}. `esquerda`/`direita` sao nivel; `pulo` e EVENTO (true uma vez por
# pulso pedido; o esquema o consome ao devolver, nunca fica true enquanto o dedo segura).
static func intencao_neutra() -> Dictionary:
	return {"esquerda": false, "direita": false, "pulo": false}


func ativo() -> bool:
	return not _dedos.is_empty()


func tem_dedo(dedo: int) -> bool:
	return _dedos.has(dedo)


func em_zona_morta(pos: Vector2) -> bool:
	for zona in zonas_mortas:
		if zona.has_point(pos):
			return true
	return false


# true = dedo aceito. Zona morta e index ja ativo sao recusados sem tocar o estado do esquema.
func press(dedo: int, t_ms: int, pos: Vector2) -> bool:
	if _dedos.has(dedo) or em_zona_morta(pos):
		return false
	_dedos[dedo] = true
	_ao_pressionar(dedo, t_ms, pos)
	return true


# Dedo desconhecido (sem press previo, em zona morta ou ja solto) e ignorado.
func mover(dedo: int, pos: Vector2, t_ms: int) -> void:
	if not _dedos.has(dedo):
		return
	_ao_mover(dedo, pos, t_ms)


func release(dedo: int, t_ms: int) -> void:
	if not _dedos.has(dedo):
		return
	_dedos.erase(dedo)
	_ao_soltar(dedo, t_ms)


func cancelar(dedo: int) -> void:
	if not _dedos.has(dedo):
		return
	_dedos.erase(dedo)
	_ao_cancelar(dedo)


func cancelar_tudo() -> void:
	_dedos.clear()
	_ao_cancelar_tudo()


func intencao(t_ms: int) -> Dictionary:
	return _intencao(t_ms)


# Ganchos dos esquemas (no-op / neutro por padrao).
func _ao_pressionar(_dedo: int, _t_ms: int, _pos: Vector2) -> void:
	pass


func _ao_mover(_dedo: int, _pos: Vector2, _t_ms: int) -> void:
	pass


func _ao_soltar(_dedo: int, _t_ms: int) -> void:
	pass


func _ao_cancelar(_dedo: int) -> void:
	pass


# Zera o estado proprio do esquema (a base ja esvaziou `_dedos`).
func _ao_cancelar_tudo() -> void:
	pass


func _intencao(_t_ms: int) -> Dictionary:
	return intencao_neutra()
