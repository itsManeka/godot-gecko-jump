class_name Fundo
extends CanvasLayer

# Fundo de gameplay (f559 T5): CanvasLayer abaixo do jogo (layer < 0) criado pela Stage.
# - Ceu: 1 textura fixa no topo da tela (fator 0, sem offset, sem repeticao).
# - Camadas c0/c1/c2 (360xH, H lido da textura): tiles repetidos ceil(H_tela/H_tex)+1 com wrap na altura da propria
#   textura, fatores de FundoParallax.FATORES.
# O offset acumula o delta de ScrollLevel.position_scrolled (curva + avanco da camera) so com a partida iniciada, a
# arvore nao pausada e o scroll nao forcado a 0 (Zen); delta negativo ou zero nunca anda para tras.

const LAYER_FUNDO: int = -1
const LARGURA_TELA: float = 360.0

# Bioma ativo (a troca por estagio e da T6); indice em FundoBiomas
var bioma: int = 0
# Scroll de onde o delta e lido (injetado pela Stage; null = fundo parado)
var scroll_level: ScrollLevel = null
# Scroll acumulado valido (px): so cresce
var acumulado: float = 0.0

var _texturas: Array = []
var _ultimo_scroll: float = 0.0
var _ceu: Sprite2D = null
# Por camada (c0, c1, c2): os Sprite2D dos tiles
var _tiles: Array = [[], [], []]
var _altura_tela: float = 0.0


func _init() -> void:
	layer = LAYER_FUNDO


func _ready() -> void:
	if _texturas.is_empty():
		_texturas = FundoBiomas.texturas(bioma)
	if scroll_level != null:
		_ultimo_scroll = scroll_level.position_scrolled
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	reconstruir()


# Troca as texturas [ceu, c0, c1, c2] (teste ou bioma novo) e refaz os tiles, mantendo o offset
func definir_texturas(texturas: Array) -> void:
	_texturas = texturas
	if is_inside_tree():
		reconstruir()


func _process(_delta: float) -> void:
	atualizar()


# Le o delta do scroll e acumula quando a partida esta ativa; sempre registra o ultimo valor lido (o scroll que
# andou parado/pausado/no Zen e descartado, nao volta como pulo depois)
func atualizar() -> void:
	if scroll_level == null:
		return
	var atual: float = scroll_level.position_scrolled
	var delta: float = atual - _ultimo_scroll
	_ultimo_scroll = atual
	if delta <= 0.0:
		return
	if not Global.is_iniciado() or get_tree().paused or is_zero_approx(scroll_level.fator_forcado):
		return
	acumulado += delta
	atualizar_posicoes()


func _on_viewport_size_changed() -> void:
	reconstruir()


# Offset (px, em [0, H_tex)) da camada 0..2
func offset_camada(indice: int) -> float:
	var textura: Texture2D = _texturas[indice + 1]
	return FundoParallax.offset(acumulado, FundoParallax.FATORES[indice], float(textura.get_height()))


func ceu() -> Sprite2D:
	return _ceu


func tiles_da_camada(indice: int) -> Array:
	return _tiles[indice]


# Retangulos (coordenadas da tela) dos tiles da camada, para conferir a cobertura
func retangulos_camada(indice: int) -> Array[Rect2]:
	var retangulos: Array[Rect2] = []
	for tile: Sprite2D in _tiles[indice]:
		retangulos.append(Rect2(tile.position, tile.texture.get_size()))
	return retangulos


# Refaz ceu e tiles pela altura visivel atual e pelas texturas; o offset acumulado nao reinicia
func reconstruir() -> void:
	if _texturas.is_empty():
		return
	_altura_tela = VisibleArea.visible_size(get_viewport()).y
	if _ceu != null:
		remove_child(_ceu)
		_ceu.queue_free()
	_ceu = _novo_sprite(_texturas[FundoBiomas.CEU])
	for indice in range(_tiles.size()):
		for tile: Sprite2D in _tiles[indice]:
			remove_child(tile)
			tile.queue_free()
		var lista: Array = []
		var textura: Texture2D = _texturas[indice + 1]
		for k in range(FundoParallax.quantidade_tiles(_altura_tela, float(textura.get_height()))):
			lista.append(_novo_sprite(textura))
		_tiles[indice] = lista
	atualizar_posicoes()


# Posiciona o ceu (fixo no topo) e os tiles de cada camada pelo offset vigente
func atualizar_posicoes() -> void:
	if _ceu == null:
		return
	_ceu.position = Vector2.ZERO
	for indice in range(_tiles.size()):
		var textura: Texture2D = _texturas[indice + 1]
		var altura: float = float(textura.get_height())
		var offset: float = FundoParallax.offset(acumulado, FundoParallax.FATORES[indice], altura)
		var k: int = 0
		for tile: Sprite2D in _tiles[indice]:
			tile.position = Vector2(0.0, FundoParallax.y_do_tile(offset, altura, k))
			k += 1


func _novo_sprite(textura: Texture2D) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = textura
	sprite.centered = false
	add_child(sprite)
	return sprite
