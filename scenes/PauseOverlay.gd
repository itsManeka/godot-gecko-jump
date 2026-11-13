class_name PauseOverlay
extends CanvasLayer

# Overlay de pausa (handoff 9): fundo preto a 60%, titulo "Pausado" e botoes Continuar/Opcoes num bloco de 118 px
# centrado na safe area. Montado por codigo; a Stage o instancia e injeta o layout (`aplicar_layout`).
# `process_mode = ALWAYS`: recebe entrada com a arvore pausada. Todo toque e consumido; toque no fundo nao retoma;
# cada botao aciona ao soltar com o dedo dentro do retangulo (9.3, 7.3). Esc/P (acao `pause`) = Continuar.

# Emitido por Continuar e pela acao `pause` com o overlay aberto.
signal retomar
# Emitido por Opcoes (a tela de Opcoes e de outra entrega).
signal opcoes

enum Botao { CONTINUAR, OPCOES }

const FONTE: Font = preload("res://fonts/alterebro-pixel-font.ttf")
const COR_TEXTO: Color = Color(1.0, 1.0, 1.0, 1.0)
const COR_CONTORNO: Color = Color(0.0, 0.0, 0.0, 1.0)
const COR_FUNDO: Color = Color(0.0, 0.0, 0.0, 0.6)
const COR_BOTAO: Color = Color("#5b8a4a")
# Chave do mouse no dicionario de toques (dedos do toque sao indices pequenos, como em TouchControls.DEDO_MOUSE)
const DEDO_MOUSE: int = 1000

# Medidas em px logicos (handoff 9.2)
const BLOCO_ALTURA: float = 118.0
const TITULO_ALTURA: float = 30.0
const TITULO_ESPACO: float = 16.0
const BOTAO_ALTURA: float = 32.0
const BOTAO_LARGURA: float = 112.0
const BOTAO_ESPACO: float = 8.0
const LARGURA: float = 180.0
const TAMANHO_TITULO: int = 36
const TAMANHO_CONTINUAR: int = 26
const TAMANHO_OPCOES: int = 20
const CONTORNO_TITULO: int = 2
const CONTORNO_BOTAO: int = 1
# Acima do botao de pausa (7.4)
const CAMADA: int = 10

const TEXTO_TITULO: String = "Pausado"
const TEXTOS: Array[String] = ["Continuar", "Opcoes"]

var _fundo: ColorRect
var _titulo: Label
var _paineis: Array[Panel] = []
var _rotulos: Array[Label] = []
var _molduras: Array[Panel] = []
var _rects: Array[Rect2] = [Rect2(), Rect2()]
var _foco: int = Botao.CONTINUAR
var _aberto: bool = false
# index do dedo -> botao em que o toque comecou (-1 = fundo)
var _toques: Dictionary = {}
var _pressionado: int = -1


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	layer = CAMADA
	visible = false
	_fundo = ColorRect.new()
	_fundo.color = COR_FUNDO
	_fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fundo.focus_mode = Control.FOCUS_NONE
	add_child(_fundo)
	_titulo = _novo_label(TEXTO_TITULO, TAMANHO_TITULO, CONTORNO_TITULO)
	add_child(_titulo)
	for b in [Botao.CONTINUAR, Botao.OPCOES]:
		var moldura := Panel.new()
		moldura.mouse_filter = Control.MOUSE_FILTER_IGNORE
		moldura.focus_mode = Control.FOCUS_NONE
		moldura.add_theme_stylebox_override("panel", _estilo(Color(0, 0, 0, 0), 2, COR_CONTORNO))
		add_child(moldura)
		_molduras.append(moldura)
		var painel := Panel.new()
		painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		painel.focus_mode = Control.FOCUS_NONE
		add_child(painel)
		_paineis.append(painel)
		var tamanho := TAMANHO_CONTINUAR if b == Botao.CONTINUAR else TAMANHO_OPCOES
		var rotulo := _novo_label(TEXTOS[b], tamanho, CONTORNO_BOTAO)
		painel.add_child(rotulo)
		_rotulos.append(rotulo)
	_atualizar_visual()


func _input(event: InputEvent) -> void:
	if tratar_evento(event):
		get_viewport().set_input_as_handled()


# Processa um evento de entrada; devolve true se foi consumido (overlay aberto consome todo toque).
func tratar_evento(event: InputEvent) -> bool:
	if not _aberto:
		return false
	if event is InputEventScreenTouch:
		_tratar_toque(event as InputEventScreenTouch)
		return true
	if event is InputEventScreenDrag:
		return true
	if event is InputEventMouseButton:
		return _tratar_mouse(event as InputEventMouseButton)
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventAction:
		return _tratar_acao(event)
	return false


# Posiciona fundo, titulo e botoes a partir do tamanho visivel e da safe area (coordenadas logicas).
func aplicar_layout(visible_size: Vector2, safe: Rect2) -> void:
	var s_top := safe.position.y
	var s_left := safe.position.x
	var s_bottom := visible_size.y - safe.end.y
	var s_right := visible_size.x - safe.end.x
	var util := visible_size.y - s_top - s_bottom
	var y0 := s_top + (util - BLOCO_ALTURA) / 2.0
	var x0 := s_left + (LARGURA - s_left - s_right - BOTAO_LARGURA) / 2.0
	var y_continuar := y0 + TITULO_ALTURA + TITULO_ESPACO
	var y_opcoes := y_continuar + BOTAO_ALTURA + BOTAO_ESPACO
	_rects[Botao.CONTINUAR] = Rect2(x0, y_continuar, BOTAO_LARGURA, BOTAO_ALTURA)
	_rects[Botao.OPCOES] = Rect2(x0, y_opcoes, BOTAO_LARGURA, BOTAO_ALTURA)
	if _fundo == null:
		return
	_fundo.position = Vector2.ZERO
	_fundo.size = Vector2(LARGURA, visible_size.y)
	_titulo.position = Vector2(0.0, y0)
	_titulo.size = Vector2(LARGURA, TITULO_ALTURA)
	for b in [Botao.CONTINUAR, Botao.OPCOES]:
		var r: Rect2 = _rects[b]
		_paineis[b].position = r.position
		_paineis[b].size = r.size
		_molduras[b].position = r.position - Vector2(1.0, 1.0)
		_molduras[b].size = r.size + Vector2(2.0, 2.0)
		_rotulos[b].size = r.size
	_atualizar_visual()


func rect_continuar() -> Rect2:
	return _rects[Botao.CONTINUAR]


func rect_opcoes() -> Rect2:
	return _rects[Botao.OPCOES]


# Botao com foco (enum Botao).
func foco_atual() -> int:
	return _foco


func esta_aberto() -> bool:
	return _aberto


func abrir(foco: int = Botao.CONTINUAR) -> void:
	_aberto = true
	_foco = foco
	_toques.clear()
	_pressionado = -1
	visible = true
	_atualizar_visual()


func fechar() -> void:
	_aberto = false
	_toques.clear()
	_pressionado = -1
	visible = false


func _tratar_acao(event: InputEvent) -> bool:
	if event is InputEventKey and (event as InputEventKey).echo:
		return false
	if event.is_action_pressed("pause"):
		retomar.emit()
		return true
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up"):
		_foco = (_foco + 1) % 2
		_atualizar_visual()
		return true
	if event.is_action_pressed("ui_accept"):
		_acionar(_foco)
		return true
	return false


func _tratar_toque(toque: InputEventScreenTouch) -> void:
	_tratar_ponteiro(toque.index, toque.pressed, toque.position)


# Clique de mouse esquerdo real (nao emulado a partir do toque) tem a mesma arbitragem do toque. Botao direito e
# mouse emulado nao sao do overlay: devolvem false (nao consumidos).
func _tratar_mouse(mouse: InputEventMouseButton) -> bool:
	if mouse.device == InputEvent.DEVICE_ID_EMULATION or mouse.button_index != MOUSE_BUTTON_LEFT:
		return false
	_tratar_ponteiro(DEDO_MOUSE, mouse.pressed, mouse.position)
	return true


func _tratar_ponteiro(dedo: int, pressionado: bool, pos: Vector2) -> void:
	if pressionado:
		var b := _botao_em(pos)
		_toques[dedo] = b
		_pressionado = b
		_atualizar_visual()
		return
	var inicio: int = _toques.get(dedo, -1)
	_toques.erase(dedo)
	_pressionado = -1
	_atualizar_visual()
	if inicio != -1 and (_rects[inicio] as Rect2).has_point(pos):
		_acionar(inicio)


func _botao_em(pos: Vector2) -> int:
	for b in [Botao.CONTINUAR, Botao.OPCOES]:
		if (_rects[b] as Rect2).has_point(pos):
			return b
	return -1


func _acionar(botao: int) -> void:
	if botao == Botao.CONTINUAR:
		retomar.emit()
	else:
		opcoes.emit()


func _atualizar_visual() -> void:
	if _paineis.is_empty():
		return
	for b in [Botao.CONTINUAR, Botao.OPCOES]:
		var pressed: bool = _pressionado == b
		_paineis[b].add_theme_stylebox_override("panel", _estilo(COR_BOTAO, 2 if pressed else 1, COR_CONTORNO))
		_molduras[b].visible = _foco == b
		_rotulos[b].text = ("> " if _foco == b else "") + TEXTOS[b]
		_rotulos[b].position = Vector2(0.0, 1.0 if pressed else 0.0)


func _estilo(fundo: Color, borda: int, cor_borda: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fundo
	s.set_border_width_all(borda)
	s.border_color = cor_borda
	s.set_corner_radius_all(4)
	return s


func _novo_label(texto: String, tamanho: int, contorno: int) -> Label:
	var l := Label.new()
	l.text = texto
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.focus_mode = Control.FOCUS_NONE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", FONTE)
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", COR_TEXTO)
	l.add_theme_color_override("font_outline_color", COR_CONTORNO)
	l.add_theme_constant_override("outline_size", contorno)
	return l
