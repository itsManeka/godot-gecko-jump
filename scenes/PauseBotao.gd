class_name PauseBotao
extends CanvasLayer

# Botao de pausa por toque (handoff 7): 24x24 no canto superior esquerdo, glifo de duas barras.
# Montado por codigo; a Stage o instancia depois de touch_controls/touch_hint (ordem de `_input`), injeta `player`
# e o layout (`aplicar_layout`) e liga `pausar_pedido` ao PauseState. Visivel so em partida ativa (7.2): oculto,
# nao desabilitado. Fora da cadeia de foco. Aciona ao soltar com o dedo dentro do retangulo (7.3).

# Disparado ao soltar o dedo dentro do retangulo, com o botao visivel.
signal pausar_pedido

const COR_FUNDO: Color = Color("#5b8a4a")
const COR_BORDA: Color = Color(0.0, 0.0, 0.0, 1.0)
const COR_GLIFO: Color = Color(1.0, 1.0, 1.0, 1.0)
# Chave do mouse no estado de toque (dedos do toque sao indices pequenos, como em TouchControls.DEDO_MOUSE)
const DEDO_MOUSE: int = 1000

# Acima da dica de toque (layer 0) e do HUD (layer 1); abaixo do overlay de pausa (7.4).
const CAMADA: int = 2
const TAMANHO: float = 24.0
const OFFSET: float = 2.0
const RAIO: int = 4
const BORDA: int = 1
const BORDA_PRESSED: int = 2
const GLIFO_X: float = 7.0
const GLIFO_Y: float = 6.0
const BARRA_LARGURA: float = 3.0
const BARRA_ALTURA: float = 12.0
const GLIFO_LARGURA: float = 10.0

var player: Node = null

var _rect: Rect2 = Rect2(OFFSET, OFFSET, TAMANHO, TAMANHO)
var _desenho: Control
var _dedo: int = -1
var _pressed: bool = false


func _ready() -> void:
	layer = CAMADA
	visible = false
	_desenho = Control.new()
	_desenho.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desenho.focus_mode = Control.FOCUS_NONE
	_desenho.draw.connect(_desenhar)
	add_child(_desenho)
	_aplicar_rect()


func _process(_delta: float) -> void:
	atualizar_visibilidade()


func _input(event: InputEvent) -> void:
	tratar_evento(event)


# Posiciona o botao pela safe area (coordenadas logicas); chamavel de novo.
func aplicar_layout(_visible_size: Vector2, safe: Rect2) -> void:
	_rect = Rect2(safe.position.x + OFFSET, safe.position.y + OFFSET, TAMANHO, TAMANHO)
	if _desenho != null:
		_aplicar_rect()


# Retangulo do botao e da area de toque; e tambem a zona morta do toque de jogo (7.1, 7.3).
func rect_botao() -> Rect2:
	return _rect


# Predicado de partida ativa (7.2): iniciada e sem derrota.
func partida_ativa() -> bool:
	var fim: bool = player != null and bool(player.is_end())
	return PauseState.partida_ativa(Global.is_iniciado(), fim)


func atualizar_visibilidade() -> void:
	var ativa := partida_ativa()
	if not ativa:
		cancelar()
	visible = ativa


func esta_pressionado() -> bool:
	return _pressed


# Trata toque, arraste e clique de mouse esquerdo real (nao emulado). Retorna true se o evento pertence ao botao
# (e foi consumido). O mouse tem a mesma arbitragem do toque: pressionar dentro + soltar dentro pausa.
func tratar_evento(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		return _ponteiro(t.index, t.pressed, t.position)
	if event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index != _dedo:
			return false
		if not _rect.has_point(d.position):
			cancelar()
		_consumir()
		return true
	if event is InputEventMouseButton:
		var m := event as InputEventMouseButton
		if m.device == InputEvent.DEVICE_ID_EMULATION or m.button_index != MOUSE_BUTTON_LEFT:
			return false
		return _ponteiro(DEDO_MOUSE, m.pressed, m.position)
	return false


func _ponteiro(dedo: int, pressionado: bool, pos: Vector2) -> bool:
	if pressionado:
		if not visible or not _rect.has_point(pos):
			return false
		_dedo = dedo
		_definir_pressed(true)
		_consumir()
		return true
	if dedo != _dedo:
		return false
	var dentro := visible and _rect.has_point(pos)
	cancelar()
	_consumir()
	if dentro:
		pausar_pedido.emit()
	return true


# Cancela o toque em curso e zera o estado pressed (pausa com o dedo sobre o botao, saida do retangulo, predicado falso).
func cancelar() -> void:
	_dedo = -1
	_definir_pressed(false)


func _definir_pressed(valor: bool) -> void:
	if _pressed == valor:
		return
	_pressed = valor
	if _desenho != null:
		_desenho.queue_redraw()


func _consumir() -> void:
	if is_inside_tree():
		get_viewport().set_input_as_handled()


func _aplicar_rect() -> void:
	_desenho.position = _rect.position
	_desenho.size = _rect.size
	_desenho.queue_redraw()


func _desenhar() -> void:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = COR_FUNDO
	estilo.border_color = COR_BORDA
	estilo.set_border_width_all(BORDA_PRESSED if _pressed else BORDA)
	estilo.set_corner_radius_all(RAIO)
	_desenho.draw_style_box(estilo, Rect2(Vector2.ZERO, _rect.size))
	var deslocamento := 1.0 if _pressed else 0.0
	for x in [0.0, GLIFO_LARGURA - BARRA_LARGURA]:
		var barra := Rect2(GLIFO_X + x, GLIFO_Y + deslocamento, BARRA_LARGURA, BARRA_ALTURA)
		_desenho.draw_rect(barra.grow(1.0), COR_BORDA)
		_desenho.draw_rect(barra, COR_GLIFO)
