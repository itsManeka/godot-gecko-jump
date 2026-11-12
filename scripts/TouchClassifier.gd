class_name TouchClassifier
extends RefCounted

# Classificador puro de toque x segurar (sem cena, sem Input). Tudo entra por parametro.
# Decisoes do G1: limiar de 200 ms (D1) e pulo ao soltar (D1b): o tap so e decidido no release.
# Lado = metade da largura visivel; x == metade pertence a DIREITA (handoff 8.1).
# Multitoque: so o primeiro dedo vale enquanto estiver ativo; os demais sao ignorados e nao alteram o primeiro.

enum Resultado { IGNORADO, CANCELADO, TAP, HOLD }
enum Lado { NENHUM, ESQUERDA, DIREITA }

# Unica definicao do limiar (ms) entre tap e hold.
const LIMIAR_MS: int = 200
# Duracao == LIMIAR_MS cai em hold (true) ou em tap (false).
const hold_no_limiar_inclusivo: bool = true

var largura_visivel: float = 180.0
var zonas_mortas: Array[Rect2] = []

var _dedo_ativo: int = -1
var _t_press_ms: int = 0
var _pos_press: Vector2 = Vector2.ZERO


func _init(largura: float = 180.0, mortas: Array[Rect2] = []) -> void:
	largura_visivel = largura
	zonas_mortas = mortas


static func lado_de(x: float, largura: float) -> Lado:
	return Lado.ESQUERDA if x < largura / 2.0 else Lado.DIREITA


static func eh_hold(duracao_ms: int) -> bool:
	if hold_no_limiar_inclusivo:
		return duracao_ms >= LIMIAR_MS
	return duracao_ms > LIMIAR_MS


func ativo() -> bool:
	return _dedo_ativo != -1


# Retorna true se o toque foi aceito como o dedo ativo; false = ignorado (zona morta ou outro dedo ja ativo).
func press(dedo: int, t_ms: int, pos: Vector2) -> bool:
	if _dedo_ativo != -1:
		return false
	for zona in zonas_mortas:
		if zona.has_point(pos):
			return false
	_dedo_ativo = dedo
	_t_press_ms = t_ms
	_pos_press = pos
	return true


# Retorna {"resultado": Resultado, "lado": Lado}. Release de dedo que nao e o ativo = IGNORADO.
func release(dedo: int, t_ms: int) -> Dictionary:
	if dedo != _dedo_ativo:
		return {"resultado": Resultado.IGNORADO, "lado": Lado.NENHUM}
	var lado: Lado = lado_de(_pos_press.x, largura_visivel)
	var resultado: Resultado = Resultado.HOLD if eh_hold(t_ms - _t_press_ms) else Resultado.TAP
	_dedo_ativo = -1
	return {"resultado": resultado, "lado": lado}


# Press sem release (toque cancelado pelo sistema): nem tap nem hold.
func cancelar(dedo: int) -> Dictionary:
	if dedo != _dedo_ativo:
		return {"resultado": Resultado.IGNORADO, "lado": Lado.NENHUM}
	var lado: Lado = lado_de(_pos_press.x, largura_visivel)
	_dedo_ativo = -1
	return {"resultado": Resultado.CANCELADO, "lado": lado}
