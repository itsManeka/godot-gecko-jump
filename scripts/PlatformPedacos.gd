extends Node2D

class_name PlatformPedacos

# Um pedaco do burst de desmoronamento da plataforma: sprite do atlas (celula 8x6), cai por DURACAO_S com gravidade
# GRAVIDADE px/s2 e some sozinho. Sem colisao (Node2D puro, sem cena). `emitir` cria o burst inteiro (6-8 pedacos) no
# pai da plataforma; o sorteio vem do rng injetado (semente do teste), nunca do global.
const DURACAO_S := 0.35
const GRAVIDADE := 440.0
const MIN_PEDACOS := 6
const MAX_PEDACOS := 8
const CELULA := Vector2i(8, 6)
# Fragmentos de cobertura por cor no atlas (linha 1), na ordem verde, amarelo, azul, vermelho: 2 por cor
const FRAGMENTOS_POR_COR := 2
const PEDACOS_DE_TERRA := 8
const VX_MAX := 50.0
const SPAWN_Y_MAX := 6.0

var _x0 := 0.0
var _y0 := 0.0
var _vx := 0.0
var _celula := Vector2i.ZERO
var _t := 0.0


# Ordem da cor no atlas (linha 1): verde, amarelo, azul, vermelho
static func _ordem_da_cor(cor: int) -> int:
	match cor:
		Enums.COLOR.VERDE:
			return 0
		Enums.COLOR.AZUL:
			return 2
		Enums.COLOR.VERMELHO:
			return 3
		_:
			return 1


# Especificacao do burst (puro, deterministico por rng): lista de {offset: Vector2, vx: float, celula: Vector2i}
static func gerar(rng: RandomNumberGenerator, largura: float, cor: int) -> Array:
	var especificacoes: Array = []
	var total := rng.randi_range(MIN_PEDACOS, MAX_PEDACOS)
	var base_cor := _ordem_da_cor(cor) * FRAGMENTOS_POR_COR
	for i in total:
		var offset := Vector2(rng.randf_range(-largura / 2.0, largura / 2.0), rng.randf_range(-SPAWN_Y_MAX, SPAWN_Y_MAX))
		var vx := rng.randf_range(-VX_MAX, VX_MAX)
		var celula := Vector2i(rng.randi_range(0, PEDACOS_DE_TERRA - 1), 0)
		if i < FRAGMENTOS_POR_COR:
			celula = Vector2i(base_cor + i, 1)
		especificacoes.append({"offset": offset, "vx": vx, "celula": celula})
	return especificacoes


# Cria os pedacos como filhos de `pai`, a partir de `centro` (posicao global da plataforma)
static func emitir(pai: Node, centro: Vector2, largura: float, cor: int, rng: RandomNumberGenerator) -> Array:
	var criados: Array = []
	for especificacao in gerar(rng, largura, cor):
		var pedaco := PlatformPedacos.new()
		pedaco._vx = especificacao["vx"]
		pedaco._celula = especificacao["celula"]
		pai.add_child(pedaco)
		pedaco.global_position = centro + especificacao["offset"]
		pedaco._x0 = pedaco.position.x
		pedaco._y0 = pedaco.position.y
		criados.append(pedaco)
	return criados


func _draw() -> void:
	var regiao := Rect2(Vector2(_celula.x * CELULA.x, _celula.y * CELULA.y), Vector2(CELULA))
	draw_texture_rect_region(PlatformVisuais.PEDACOS, Rect2(-Vector2(CELULA) / 2.0, Vector2(CELULA)), regiao)


func _process(delta: float) -> void:
	avancar(delta)


# Passo da queda: x linear, y por 0.5 * g * t^2; ao fim da duracao sai do pai e se libera
func avancar(delta: float) -> void:
	_t += delta
	position = Vector2(_x0 + _vx * _t, _y0 + 0.5 * GRAVIDADE * _t * _t)
	modulate.a = clampf((DURACAO_S - _t) / (DURACAO_S * 0.5), 0.0, 1.0)
	if _t >= DURACAO_S:
		var pai := get_parent()
		if pai != null:
			pai.remove_child(self)
		queue_free()
