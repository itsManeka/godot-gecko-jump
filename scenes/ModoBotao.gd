class_name ModoBotao
extends CanvasLayer

# Botao "Modo: <rotulo curto>" do menu (handoff-power-ups-e-modos.md:133): 112x24 acima do Play, so com o jogo nao
# iniciado. Mesmo padrao do OpcoesBotao: montado por codigo, a Stage o instancia como filho, injeta o layout
# (`aplicar_layout`) e liga `acionado` a tela de modos. Aciona ao soltar com o dedo dentro do retangulo. Teclado/joypad:
# `ui_up` leva o foco do Play ate aqui (marcador `>` + moldura), `ui_accept` aciona, `ui_down` devolve o foco ao Play.
# A Stage controla a visibilidade e o modo exibido (`definir_modo`).

# Disparado ao soltar o dedo dentro do retangulo, ou por `ui_accept` com o foco no botao.
signal acionado

const FONTE: Font = preload("res://fonts/alterebro-pixel-font.ttf")
const COR_TEXTO: Color = Color(1.0, 1.0, 1.0, 1.0)
const COR_CONTORNO: Color = Color(0.0, 0.0, 0.0, 1.0)
const COR_FUNDO: Color = Color("#5b8a4a")
# Mesma camada do HUD da Stage
const CAMADA: int = 1

# Medidas em px logicos de 180x320 (handoff-power-ups-e-modos.md:133)
const LARGURA: float = 112.0
const ALTURA: float = 24.0
const TOPO: float = 113.0
const LARGURA_TELA: float = 180.0
const TAMANHO_TEXTO: int = UiHelpers.TAMANHO_TEXTO
const CONTORNO_TEXTO: int = 1
const RAIO: int = 4
const PREFIXO: String = "Modo: "

var _rect: Rect2 = Rect2((LARGURA_TELA - LARGURA) / 2.0, TOPO, LARGURA, ALTURA)
var _modo: GameMode = GameModes.padrao()
var _moldura: Panel
var _painel: Panel
var _rotulo: Label
var _dedo: int = -1
var _pressed: bool = false
var _foco: bool = false
# Injetado pela Stage: true quando outro botao do menu (Opcoes) tem o foco. O Modo vem depois do Opcoes na arvore e
# recebe o `_input` antes dele; sem isso tomaria o `ui_up` que devolve o foco do Opcoes ao Play.
var foco_alheio: Callable = Callable()


func _ready() -> void:
	layer = CAMADA
	_moldura = Panel.new()
	_moldura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_moldura.focus_mode = Control.FOCUS_NONE
	_moldura.add_theme_stylebox_override("panel", UiHelpers.estilo(Color(0, 0, 0, 0), 2, COR_CONTORNO, 0))
	add_child(_moldura)
	_painel = Panel.new()
	_painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_painel.focus_mode = Control.FOCUS_NONE
	add_child(_painel)
	_rotulo = Label.new()
	_rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rotulo.focus_mode = Control.FOCUS_NONE
	_rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_rotulo.add_theme_font_override("font", FONTE)
	_rotulo.add_theme_font_size_override("font_size", TAMANHO_TEXTO)
	_rotulo.add_theme_color_override("font_color", COR_TEXTO)
	_rotulo.add_theme_color_override("font_outline_color", COR_CONTORNO)
	_rotulo.add_theme_constant_override("outline_size", CONTORNO_TEXTO)
	_painel.add_child(_rotulo)
	_aplicar_rect()


func _input(event: InputEvent) -> void:
	if tratar_evento(event):
		get_viewport().set_input_as_handled()


# Posiciona o botao: x centrado na largura visivel, y de 180x320 deslocado por safe.position.y.
func aplicar_layout(visible_size: Vector2, safe: Rect2) -> void:
	_rect = Rect2((visible_size.x - LARGURA) / 2.0, safe.position.y + TOPO, LARGURA, ALTURA)
	if _painel != null:
		_aplicar_rect()


# Retangulo do botao e da area de toque.
func rect_botao() -> Rect2:
	return _rect


func tem_foco() -> bool:
	return _foco


# Texto exibido (`Modo: <rotulo curto>`, com o marcador `> ` quando o foco esta no botao).
func texto() -> String:
	return _rotulo.text


func esta_pressionado() -> bool:
	return _pressed


# Modo exibido no rotulo; nulo volta ao padrao.
func definir_modo(modo: GameMode) -> void:
	_modo = modo if modo != null else GameModes.padrao()
	_atualizar_visual()


# Define o foco do teclado/joypad no botao.
func focar(valor: bool) -> void:
	_foco = valor
	_atualizar_visual()


# Tira o botao de cena do menu: oculta e zera foco e toque em curso.
func ocultar() -> void:
	cancelar()
	_foco = false
	visible = false
	_atualizar_visual()


func mostrar() -> void:
	visible = true


# Processa um evento; devolve true se pertence ao botao (consumido). Oculto ignora tudo.
func tratar_evento(event: InputEvent) -> bool:
	if not visible:
		return false
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		return _ponteiro(t.index, t.pressed, t.position)
	if event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index != _dedo:
			return false
		if not _rect.has_point(d.position):
			cancelar()
		return true
	if event is InputEventMouseButton:
		var m := event as InputEventMouseButton
		if m.device == InputEvent.DEVICE_ID_EMULATION or m.button_index != MOUSE_BUTTON_LEFT:
			return false
		return _ponteiro(UiHelpers.DEDO_MOUSE, m.pressed, m.position)
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventAction:
		return _tratar_acao(event)
	return false


# Cancela o toque em curso (saida do retangulo, tela aberta, partida iniciada).
func cancelar() -> void:
	_dedo = -1
	if _pressed:
		_pressed = false
		_atualizar_visual()


func _tratar_acao(event: InputEvent) -> bool:
	if event is InputEventKey and (event as InputEventKey).echo:
		return false
	if not _foco:
		var alheio: bool = foco_alheio.is_valid() and bool(foco_alheio.call())
		if event.is_action_pressed("ui_up") and not alheio:
			focar(true)
			return true
		return false
	# Espaco e `jump` e `ui_accept` ao mesmo tempo: com foco no botao ele inicia a partida (Stage), nao abre a tela.
	if event.is_action("jump"):
		return false
	if event.is_action_pressed("ui_accept"):
		acionado.emit()
		return true
	if event.is_action_pressed("ui_down"):
		focar(false)
		return true
	return false


func _ponteiro(dedo: int, pressionado: bool, pos: Vector2) -> bool:
	if pressionado:
		if not _rect.has_point(pos):
			return false
		_dedo = dedo
		_pressed = true
		_atualizar_visual()
		return true
	if dedo != _dedo:
		return false
	var dentro := _rect.has_point(pos)
	cancelar()
	if dentro:
		acionado.emit()
	return true


func _aplicar_rect() -> void:
	_painel.position = _rect.position
	_painel.size = _rect.size
	_moldura.position = _rect.position - Vector2(1.0, 1.0)
	_moldura.size = _rect.size + Vector2(2.0, 2.0)
	_rotulo.size = _rect.size
	_atualizar_visual()


func _atualizar_visual() -> void:
	if _painel == null:
		return
	_painel.add_theme_stylebox_override("panel", UiHelpers.estilo(COR_FUNDO, 2 if _pressed else 1, COR_CONTORNO, RAIO))
	_moldura.visible = _foco
	_rotulo.text = ("> " if _foco else "") + PREFIXO + _modo.rotulo
	_rotulo.position = Vector2(0.0, 1.0 if _pressed else 0.0)
