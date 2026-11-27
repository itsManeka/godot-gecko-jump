class_name Nevoa
extends CanvasLayer

# Nevoa reativa na base (f559 T8): CanvasLayer layer 0 criado pela Stage ANTES do level_up_frame (mesma camada, abaixo
# dele na ordem da arvore) e acima do jogo e do fundo; so desenho, todo Control com mouse_filter IGNORE (o toque passa).
# Duas faixas 360x64 deslizam em loop horizontal (+16 e -10 px/s), ancoradas em y = H. Altura e opacidade vem de
# NevoaRegra (menu x zona segura x aproximacao pelo y do gecko). Oculta (visible = false) no Zen e sob Global.sem_derrota;
# o modo e lido de Global (nunca da regra injetada na Stage) e reavaliado em _ready e por `reavaliar()`.

const LAYER_NEVOA: int = 0
const LARGURA_TELA: float = 360.0
const ALTURA_TEXTURA: float = 64.0
const TEXTURAS: Array[Texture2D] = [
	preload("res://assets/fundo/nevoa-a.png"),
	preload("res://assets/fundo/nevoa-b.png"),
]
# Velocidade de deslize de cada faixa (px/s); sinais opostos
const VELOCIDADES: Array[float] = [16.0, -10.0]

# Gecko lido para o y (injetado pela Stage; null = zona segura)
var jogador: Node2D = null

var _faixas: Array[Control] = []
var _imagens: Array[TextureRect] = []
# Deslocamento de cada faixa em [0, 360): o wrap na largura da textura e o que fecha o loop sem costura
var _deslocamentos: Array[float] = [0.0, 0.0]
var _altura: float = NevoaRegra.ALTURA_MENU
var _opacidade: float = NevoaRegra.OPACIDADE_MENU
var _perigo: float = 0.0


func _init() -> void:
	layer = LAYER_NEVOA
	for textura: Texture2D in TEXTURAS:
		var faixa := Control.new()
		faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		faixa.clip_contents = true
		var imagem := TextureRect.new()
		imagem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		imagem.texture = textura
		imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		imagem.stretch_mode = TextureRect.STRETCH_TILE
		imagem.size = Vector2(2.0 * LARGURA_TELA, ALTURA_TEXTURA)
		faixa.add_child(imagem)
		add_child(faixa)
		_faixas.append(faixa)
		_imagens.append(imagem)


func _ready() -> void:
	reavaliar()
	atualizar()


func _process(delta: float) -> void:
	if not visible:
		return
	atualizar()
	avancar(delta)


# Oculta no Zen e sob sem_derrota (onde nao ha derrota pela base); visivel nos demais. Modo lido de Global.
func reavaliar() -> void:
	visible = not (Global.get_modo_jogo() == GameModes.ID_ZEN or Global.sem_derrota)


# Recalcula altura, opacidade e perigo pelo estado vigente e posiciona as faixas na base
func atualizar() -> void:
	var altura_tela: float = VisibleArea.visible_size(get_viewport()).y
	var em_partida: bool = Global.is_iniciado()
	var y: float = jogador.global_position.y if is_instance_valid(jogador) else 0.0
	_altura = NevoaRegra.altura(em_partida, y, altura_tela)
	_opacidade = NevoaRegra.opacidade(em_partida, y, altura_tela)
	_perigo = NevoaRegra.perigo(y, altura_tela) if em_partida else 0.0
	for i in range(_faixas.size()):
		var faixa: Control = _faixas[i]
		faixa.position = Vector2(0.0, altura_tela - _altura)
		faixa.size = Vector2(LARGURA_TELA, _altura)
		faixa.modulate.a = _opacidade
	_posicionar_imagens()


# Desliza as faixas em `delta` s; 1.4x com perigo > 0.5. Negativo nunca anda para tras.
func avancar(delta: float) -> void:
	var passo: float = maxf(delta, 0.0) * NevoaRegra.fator_velocidade(_perigo)
	for i in range(_deslocamentos.size()):
		_deslocamentos[i] = fposmod(_deslocamentos[i] + VELOCIDADES[i] * passo, LARGURA_TELA)
	_posicionar_imagens()


# Faixa e imagem de 2 larguras: o wrap em [0, 360) mantem a tela sempre coberta, sem costura
func _posicionar_imagens() -> void:
	for i in range(_imagens.size()):
		_imagens[i].position = Vector2(_deslocamentos[i] - LARGURA_TELA, 0.0)


func faixas() -> Array[Control]:
	return _faixas


# Deslocamento horizontal (px, em [0, 360)) da faixa 0 ou 1
func deslocamento(indice: int) -> float:
	return _deslocamentos[indice]


func altura_atual() -> float:
	return _altura


func opacidade_atual() -> float:
	return _opacidade


func perigo_atual() -> float:
	return _perigo
