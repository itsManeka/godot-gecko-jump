class_name TouchHint
extends CanvasLayer

# Dica visual das zonas de toque (handoff 8): linha divisoria tracejada em x = 90 e, na base, um bloco por lado
# com seta, "pula" e texto de segurar. So desenho: nenhum no recebe entrada (mouse_filter IGNORE, sem foco).
# Montada por codigo; a Stage a instancia e injeta `player` e o layout (`aplicar_layout`).
# Visivel so em partida em curso, na 1a partida, em dispositivo de toque; some com fade-out no 1o toque de jogo.

# Disparado quando o fade-out termina e a dica fica oculta.
signal ocultada

const FONTE: Font = preload("res://fonts/alterebro-pixel-font.ttf")
const FONT_SIZE: int = 20
const COR: Color = Color(1.0, 1.0, 1.0, 1.0)
const COR_CONTORNO: Color = Color(0.0, 0.0, 0.0, 1.0)
const COR_LINHA: Color = Color(1.0, 1.0, 1.0, 0.6)
const OUTLINE_SIZE: int = 1

# Textos (handoff 8.2). D6: "segura: anda" cabe em 76 px? se nao, vira "segura" (so este simbolo muda).
const TEXTO_PULA: String = "pula"
const TEXTO_SEGURA: String = "segura: anda"

# Medidas em px logicos (handoff 8.2)
const DIVISAO_X: float = 90.0
const LINHA_TOPO: float = 32.0
const TRACO: float = 2.0
const BLOCO_ALTURA: float = 60.0
const BLOCO_MARGEM_BASE: float = 40.0
const ESQ_X_MIN: float = 7.0
const ESQ_X_FIM: float = 83.0
const DIR_X_INI: float = 97.0
const DIR_X_MAX: float = 173.0
const MARGEM_SAFE: float = 2.0
const SETA: float = 24.0
const SETA_ESPACO: float = 2.0
const TEXTO_ALTURA: float = 17.0
# Abaixo do HUD (CanvasLayer da Stage, layer 1)
const CAMADA: int = 0
# Fade-out ao 1o toque de jogo: proposta provisoria (handoff 8.4)
const FADE_S: float = 0.3

enum Lado { ESQUERDA, DIREITA }

var player: Node = null
# Callable() -> bool que substitui DisplayServer.is_touchscreen_available() (teste).
var touchscreen_disponivel: Callable = Callable()
# Card do tutorial (injetado pela Stage): com ele aberto nenhum toque inicia o fade (handoff 8.4/12.1); o 1o toque
# de jogo depois do fechamento inicia.
var tutorial_card: TutorialCard = null

var _raiz: Control
var _linha: Control
var _bloco_esq: Control
var _bloco_dir: Control
var _linha_rect: Rect2 = Rect2()
var _mostrando: bool = false
var _fade: Tween = null


func _ready() -> void:
	layer = CAMADA
	visible = false
	_raiz = _novo_controle()
	add_child(_raiz)
	_linha = _novo_controle()
	_linha.draw.connect(_desenhar_linha)
	_raiz.add_child(_linha)
	_bloco_esq = _montar_bloco(Lado.ESQUERDA)
	_bloco_dir = _montar_bloco(Lado.DIREITA)
	_raiz.add_child(_bloco_esq)
	_raiz.add_child(_bloco_dir)


func _process(_delta: float) -> void:
	if _fade != null and _fade.is_valid():
		return
	if _mostrando:
		if not _em_curso():
			_ocultar()
	elif _deve_mostrar():
		_mostrar()


func _input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch) or not (event as InputEventScreenTouch).pressed:
		return
	# Qualquer toque prova dispositivo de toque; so o toque com a partida em curso conta como toque de jogo.
	Global.toque_detectado = true
	if tutorial_card != null and tutorial_card.esta_aberto():
		return
	if _mostrando and _em_curso() and (_fade == null or not _fade.is_valid()):
		_iniciar_fade()


# Largura (px) de um texto na fonte e tamanho da dica.
static func largura_texto(texto: String) -> float:
	return FONTE.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x


# Posiciona linha e blocos a partir do tamanho visivel e da safe area (coordenadas logicas); chamavel de novo.
func aplicar_layout(visible_size: Vector2, safe: Rect2) -> void:
	var s_top := safe.position.y
	var s_left := safe.position.x
	var s_right := visible_size.x - safe.end.x
	var base := minf(visible_size.y, safe.end.y)
	var y0 := base - BLOCO_MARGEM_BASE - BLOCO_ALTURA
	_raiz.position = Vector2.ZERO
	_raiz.size = visible_size
	_linha_rect = Rect2(DIVISAO_X, s_top + LINHA_TOPO, 1.0, base - (s_top + LINHA_TOPO))
	_linha.position = Vector2.ZERO
	_linha.size = visible_size
	_linha.queue_redraw()
	var esq_x := maxf(ESQ_X_MIN, s_left + MARGEM_SAFE)
	_posicionar_bloco(_bloco_esq, Rect2(esq_x, y0, ESQ_X_FIM - esq_x, BLOCO_ALTURA))
	var dir_fim := minf(DIR_X_MAX, visible_size.x - s_right - MARGEM_SAFE)
	_posicionar_bloco(_bloco_dir, Rect2(DIR_X_INI, y0, dir_fim - DIR_X_INI, BLOCO_ALTURA))


# Retangulo do bloco do lado dado (coordenadas logicas).
func rect_bloco(lado: int) -> Rect2:
	var bloco := _bloco_esq if lado == Lado.ESQUERDA else _bloco_dir
	return Rect2(bloco.position, bloco.size)


# Retangulo da linha divisoria (largura 1; x = 90).
func rect_linha() -> Rect2:
	return _linha_rect


func esta_mostrando() -> bool:
	return _mostrando


func _tem_touchscreen() -> bool:
	if touchscreen_disponivel.is_valid():
		return bool(touchscreen_disponivel.call())
	return DisplayServer.is_touchscreen_available()


func _em_curso() -> bool:
	return Global.is_iniciado() and (player == null or not player.is_end())


func _deve_mostrar() -> bool:
	if Global.dica_toque_mostrada or not _em_curso():
		return false
	return Global.toque_detectado or _tem_touchscreen()


func _mostrar() -> void:
	_mostrando = true
	_raiz.modulate.a = 1.0
	visible = true
	Global.toque_detectado = true
	Global.dica_toque_mostrada = true


func _ocultar() -> void:
	_mostrando = false
	visible = false
	ocultada.emit()


func _iniciar_fade() -> void:
	_fade = create_tween()
	_fade.tween_property(_raiz, "modulate:a", 0.0, FADE_S)
	_fade.tween_callback(_ocultar)


func _novo_controle() -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.focus_mode = Control.FOCUS_NONE
	return c


func _montar_bloco(lado: int) -> Control:
	var bloco := _novo_controle()
	var seta := _novo_controle()
	seta.size = Vector2(SETA, SETA)
	seta.draw.connect(_desenhar_seta.bind(seta, lado))
	bloco.add_child(seta)
	bloco.add_child(_novo_label(TEXTO_PULA, SETA + SETA_ESPACO))
	bloco.add_child(_novo_label(TEXTO_SEGURA, SETA + SETA_ESPACO + TEXTO_ALTURA))
	return bloco


func _novo_label(texto: String, y: float) -> Label:
	var l := UiHelpers.novo_label(texto, FONT_SIZE, OUTLINE_SIZE)
	l.position = Vector2(0.0, y)
	l.size = Vector2(0.0, TEXTO_ALTURA)
	l.set_meta("y", y)
	return l


func _posicionar_bloco(bloco: Control, r: Rect2) -> void:
	bloco.position = r.position
	bloco.size = r.size
	for filho in bloco.get_children():
		if filho is Label:
			filho.position = Vector2(0.0, filho.get_meta("y"))
			filho.size = Vector2(r.size.x, TEXTO_ALTURA)
		else:
			filho.position = Vector2((r.size.x - SETA) / 2.0, 0.0)


func _desenhar_seta(seta: Control, lado: int) -> void:
	var pontos := PackedVector2Array([Vector2(16.0, 4.0), Vector2(8.0, 12.0), Vector2(16.0, 20.0)])
	if lado == Lado.DIREITA:
		pontos = PackedVector2Array([Vector2(8.0, 4.0), Vector2(16.0, 12.0), Vector2(8.0, 20.0)])
	seta.draw_polyline(pontos, COR_CONTORNO, 5.0)
	seta.draw_polyline(pontos, COR, 3.0)


func _desenhar_linha() -> void:
	var y := _linha_rect.position.y
	var fim := _linha_rect.end.y
	while y < fim:
		_linha.draw_rect(Rect2(_linha_rect.position.x, y, 1.0, minf(TRACO, fim - y)), COR_LINHA)
		y += TRACO * 2.0
