class_name PauseOverlay
extends CanvasLayer

# Overlay de pausa (handoff 9): fundo preto a 60%, titulo "Pausado" e botoes Continuar/Opcoes num bloco de 118 px
# centrado na safe area; f527 T6 (D5): com a regra do modo permitindo saida o bloco cresce para 158 px e ganha o
# terceiro botao `Sair` (mesmo estilo 112x32 e espaco de 8 px). Montado por codigo; a Stage o instancia e injeta o
# layout (`aplicar_layout`).
# `process_mode = ALWAYS`: recebe entrada com a arvore pausada. Todo toque e consumido; toque no fundo nao retoma;
# cada botao aciona ao soltar com o dedo dentro do retangulo (9.3, 7.3). Esc/P (acao `pause`) = Continuar.

# Emitido por Continuar e pela acao `pause` com o overlay aberto.
signal retomar
# Emitido por Opcoes (a tela de Opcoes e de outra entrega).
signal opcoes
# Emitido por Sair (f527 T6): despausa e volta ao menu; so com `permite_sair`, o predicado da regra injetado
# pela Stage (`regra.permite_sair_pela_pausa()`).
signal sair

enum Botao { CONTINUAR, OPCOES, SAIR }

const COR_CONTORNO: Color = Color(0.0, 0.0, 0.0, 1.0)
const COR_FUNDO: Color = UiHelpers.COR_FUNDO_OVERLAY
const COR_BOTAO: Color = Color("#5b8a4a")

# Medidas em px logicos (handoff 9.2); f527 T6 (D5): com Sair o bloco cresce de 118 para 158 px
const BLOCO_ALTURA: float = 118.0
const BLOCO_ALTURA_COM_SAIR: float = 158.0
const TITULO_ALTURA: float = 30.0
const TITULO_ESPACO: float = 16.0
const BOTAO_ALTURA: float = 32.0
const BOTAO_LARGURA: float = 112.0
const BOTAO_ESPACO: float = 8.0
const LARGURA: float = 180.0
const TAMANHO_TITULO: int = UiHelpers.TAMANHO_TITULO
const TAMANHO_CONTINUAR: int = UiHelpers.TAMANHO_TEXTO
const TAMANHO_OPCOES: int = UiHelpers.TAMANHO_TEXTO
const CONTORNO_TITULO: int = 2
const CONTORNO_BOTAO: int = 1
# Acima do botao de pausa (7.4)
const CAMADA: int = 10

const TEXTO_TITULO: String = "Pausado"
const TEXTOS: Array[String] = ["Continuar", "Opcoes", "Sair"]

var _fundo: ColorRect
var _titulo: Label
var _paineis: Array[Panel] = []
var _rotulos: Array[Label] = []
var _molduras: Array[Panel] = []
var _rects: Array[Rect2] = [Rect2(), Rect2(), Rect2()]
# f527 T6: Sair visivel so quando a regra do modo permite (a Stage injeta ao abrir o overlay); o mesmo flag
# arbitra a acao: botao oculto nao recebe foco, toque nem clique.
var permite_sair: bool = false
# Ultimo layout recebido: refeito quando `permite_sair` muda sem resize (o bloco muda de altura)
var _tamanho_layout: Vector2 = Vector2.ZERO
var _safe_layout: Rect2 = Rect2()
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
	_titulo = UiHelpers.novo_label(TEXTO_TITULO, TAMANHO_TITULO, CONTORNO_TITULO)
	add_child(_titulo)
	for b in [Botao.CONTINUAR, Botao.OPCOES, Botao.SAIR]:
		var moldura := Panel.new()
		moldura.mouse_filter = Control.MOUSE_FILTER_IGNORE
		moldura.focus_mode = Control.FOCUS_NONE
		moldura.add_theme_stylebox_override("panel", UiHelpers.estilo(Color(0, 0, 0, 0), 2, COR_CONTORNO, UiHelpers.RAIO_BOTAO))
		add_child(moldura)
		_molduras.append(moldura)
		var painel := Panel.new()
		painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		painel.focus_mode = Control.FOCUS_NONE
		add_child(painel)
		_paineis.append(painel)
		var tamanho := TAMANHO_CONTINUAR if b == Botao.CONTINUAR else TAMANHO_OPCOES
		var rotulo := UiHelpers.novo_label(TEXTOS[b], tamanho, CONTORNO_BOTAO)
		painel.add_child(rotulo)
		_rotulos.append(rotulo)
	_atualizar_visual()


func _input(event: InputEvent) -> void:
	# Viewport capturado antes: Sair pode recarregar a cena e tirar o overlay da arvore (get_viewport() viraria null)
	var vp := get_viewport()
	if tratar_evento(event) and vp != null:
		vp.set_input_as_handled()


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
	_tamanho_layout = visible_size
	_safe_layout = safe
	var altura := _altura_bloco()
	var s_top := safe.position.y
	var s_left := safe.position.x
	var s_bottom := visible_size.y - safe.end.y
	var s_right := visible_size.x - safe.end.x
	var util := visible_size.y - s_top - s_bottom
	var y0 := s_top + (util - altura) / 2.0
	var x0 := s_left + (LARGURA - s_left - s_right - BOTAO_LARGURA) / 2.0
	var y_continuar := y0 + TITULO_ALTURA + TITULO_ESPACO
	var y_opcoes := y_continuar + BOTAO_ALTURA + BOTAO_ESPACO
	var y_sair := y_opcoes + BOTAO_ALTURA + BOTAO_ESPACO
	_rects[Botao.CONTINUAR] = Rect2(x0, y_continuar, BOTAO_LARGURA, BOTAO_ALTURA)
	_rects[Botao.OPCOES] = Rect2(x0, y_opcoes, BOTAO_LARGURA, BOTAO_ALTURA)
	_rects[Botao.SAIR] = Rect2(x0, y_sair, BOTAO_LARGURA, BOTAO_ALTURA) if permite_sair else Rect2()
	if _fundo == null:
		return
	_fundo.position = Vector2.ZERO
	_fundo.size = Vector2(LARGURA, visible_size.y)
	_titulo.position = Vector2(0.0, y0)
	_titulo.size = Vector2(LARGURA, TITULO_ALTURA)
	for b in [Botao.CONTINUAR, Botao.OPCOES, Botao.SAIR]:
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


# Retangulo do botao Sair (f527 T6; vazio quando a regra do modo nao permite: botao oculto)
func rect_sair() -> Rect2:
	return _rects[Botao.SAIR]


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


# f527 T6 (D5): Sair visivel so quando a regra do modo permite (a Stage injeta `regra.permite_sair_pela_pausa()`).
# Reaplica o ultimo layout: com Sair o bloco cresce de 118 para 158 px e o conjunto fica centrado igual.
func definir_permite_sair(valor: bool) -> void:
	permite_sair = valor
	if _fundo != null and _tamanho_layout != Vector2.ZERO:
		aplicar_layout(_tamanho_layout, _safe_layout)
	_atualizar_visual()


func _tratar_acao(event: InputEvent) -> bool:
	if event is InputEventKey and (event as InputEventKey).echo:
		return false
	if event.is_action_pressed("pause"):
		retomar.emit()
		return true
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up"):
		_foco = (_foco + 1) % _total_botoes()
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
	_tratar_ponteiro(UiHelpers.DEDO_MOUSE, mouse.pressed, mouse.position)
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
	for b in [Botao.CONTINUAR, Botao.OPCOES, Botao.SAIR]:
		if b == Botao.SAIR and not permite_sair:
			continue
		if (_rects[b] as Rect2).has_point(pos):
			return b
	return -1


# O mesmo predicado da visibilidade arbitra a acao: Sair oculto (`permite_sair` false) nunca aciona.
func _acionar(botao: int) -> void:
	if botao == Botao.CONTINUAR:
		retomar.emit()
	elif botao == Botao.OPCOES:
		opcoes.emit()
	elif botao == Botao.SAIR and permite_sair:
		sair.emit()


func _atualizar_visual() -> void:
	if _paineis.is_empty():
		return
	for b in [Botao.CONTINUAR, Botao.OPCOES, Botao.SAIR]:
		var visivel: bool = permite_sair or b != Botao.SAIR
		_paineis[b].visible = visivel
		_rotulos[b].visible = visivel
		if not visivel:
			_molduras[b].visible = false
			continue
		var pressed: bool = _pressionado == b
		_paineis[b].add_theme_stylebox_override("panel", UiHelpers.estilo(COR_BOTAO, 2 if pressed else 1, COR_CONTORNO, UiHelpers.RAIO_BOTAO))
		_molduras[b].visible = _foco == b
		_rotulos[b].text = ("> " if _foco == b else "") + TEXTOS[b]
		_rotulos[b].position = Vector2(0.0, 1.0 if pressed else 0.0)


# Altura do bloco (handoff 9.2): 118 com Continuar/Opcoes; 158 com o Sair (f527 T6, D5)
func _altura_bloco() -> float:
	return BLOCO_ALTURA_COM_SAIR if permite_sair else BLOCO_ALTURA


# Botoes que recebem foco, toque e clique (2; 3 com Sair permitido pela regra do modo)
func _total_botoes() -> int:
	return 3 if permite_sair else 2
