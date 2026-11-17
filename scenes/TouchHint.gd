class_name TouchHint
extends CanvasLayer

# Dica visual das zonas de toque (handoff 8): linha divisoria tracejada em x = 90 e, na base, um bloco por lado
# com seta, "pula" e texto de segurar. So desenho: nenhum no recebe entrada (mouse_filter IGNORE, sem foco).
# Montada por codigo; a Stage a instancia e injeta `player` e o layout (`aplicar_layout`).
# Visivel so em partida em curso, na 1a partida, em dispositivo de toque; some com fade-out no 1o toque de jogo.

# Disparado quando o fade-out termina e a dica fica oculta.
signal ocultada

const FONTE: Font = preload("res://fonts/alterebro-pixel-font.ttf")
const FONT_SIZE: int = UiHelpers.TAMANHO_TEXTO
const COR: Color = Color(1.0, 1.0, 1.0, 1.0)
const COR_CONTORNO: Color = Color(0.0, 0.0, 0.0, 1.0)
const COR_LINHA: Color = Color(1.0, 1.0, 1.0, 0.6)
# Faixa atras dos textos de cada bloco (legibilidade sobre as plataformas): mesma cor da faixa do placar
const COR_FAIXA: Color = UiHelpers.COR_FUNDO_OVERLAY
const OUTLINE_SIZE: int = 1

# Textos por modo de toque (issue #47). Cada bloco tem 2 linhas e precisa caber em 76 px (lateral) / 166 px (centro).
# A: sem zonas, um bloco central; B e C: linha em x = 90 e um bloco por lado.
const TEXTOS_A: Array[String] = ["arraste: anda", "flick: pula"]
const TEXTOS_B_ESQ: Array[String] = ["anda", "segura aqui"]
const TEXTOS_B_DIR: Array[String] = ["pula", "toque aqui"]
const TEXTOS_C_ESQ: Array[String] = ["anda", "2o dedo pula"]
const TEXTOS_C_DIR: Array[String] = ["anda", "2o dedo pula"]

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

enum Lado { ESQUERDA, DIREITA, CENTRO }

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
var _bloco_centro: Control
var _modo: int = TouchMode.padrao()
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
	_bloco_centro = _montar_bloco(Lado.CENTRO)
	_raiz.add_child(_bloco_esq)
	_raiz.add_child(_bloco_dir)
	_raiz.add_child(_bloco_centro)
	_modo = Global.get_touch_mode()
	_aplicar_modo()
	Global.touch_mode_changed.connect(_ao_trocar_modo)


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
	_posicionar_bloco(_bloco_centro, Rect2(esq_x, y0, dir_fim - esq_x, BLOCO_ALTURA))


# Textos (2 linhas) do bloco do lado dado no modo dado; vazio quando o modo nao tem esse bloco (A so tem o centro).
static func textos_bloco(modo: int, lado: int) -> Array[String]:
	match modo:
		TouchMode.Modo.A:
			return TEXTOS_A if lado == Lado.CENTRO else ([] as Array[String])
		TouchMode.Modo.B:
			if lado == Lado.ESQUERDA:
				return TEXTOS_B_ESQ
			return TEXTOS_B_DIR if lado == Lado.DIREITA else ([] as Array[String])
		_:
			if lado == Lado.ESQUERDA:
				return TEXTOS_C_ESQ
			return TEXTOS_C_DIR if lado == Lado.DIREITA else ([] as Array[String])


# Modo de toque exibido agora.
func modo_exibido() -> int:
	return _modo


# Retangulo do bloco do lado dado (coordenadas logicas).
func rect_bloco(lado: int) -> Rect2:
	var bloco := _bloco_de(lado)
	return Rect2(bloco.position, bloco.size)


# Textos hoje nas 2 linhas do bloco do lado dado.
func textos_atuais(lado: int) -> Array[String]:
	var out: Array[String] = []
	for filho in _bloco_de(lado).get_children():
		if filho is Label:
			out.append((filho as Label).text)
	return out


# O bloco do lado dado esta desenhado (A so desenha o centro; B e C so os laterais).
func bloco_visivel(lado: int) -> bool:
	return _bloco_de(lado).visible


# Retangulo da linha divisoria (largura 1; x = 90); vazio no modo A (sem zonas).
func rect_linha() -> Rect2:
	return _linha_rect if _modo != TouchMode.Modo.A else Rect2()


func esta_mostrando() -> bool:
	return _mostrando


func _bloco_de(lado: int) -> Control:
	if lado == Lado.ESQUERDA:
		return _bloco_esq
	return _bloco_dir if lado == Lado.DIREITA else _bloco_centro


# Troca o modo: reescreve textos/zonas e rearma a dica (Q8) para ser mostrada de novo na partida em curso.
func _ao_trocar_modo(modo: int) -> void:
	if modo == _modo:
		return
	_modo = modo
	_aplicar_modo()
	Global.dica_toque_mostrada = false


func _aplicar_modo() -> void:
	var com_zonas := _modo != TouchMode.Modo.A
	_linha.visible = com_zonas
	_bloco_esq.visible = com_zonas
	_bloco_dir.visible = com_zonas
	_bloco_centro.visible = not com_zonas
	for lado in [Lado.ESQUERDA, Lado.DIREITA, Lado.CENTRO]:
		var textos := textos_bloco(_modo, lado)
		if textos.is_empty():
			continue
		var i := 0
		for filho in _bloco_de(lado).get_children():
			if filho is Label:
				(filho as Label).text = textos[i]
				i += 1


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
	var faixa := ColorRect.new()
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	faixa.focus_mode = Control.FOCUS_NONE
	faixa.color = COR_FAIXA
	bloco.add_child(faixa)
	if lado != Lado.CENTRO:
		var seta := _novo_controle()
		seta.size = Vector2(SETA, SETA)
		seta.draw.connect(_desenhar_seta.bind(seta, lado))
		bloco.add_child(seta)
	bloco.add_child(_novo_label("", SETA + SETA_ESPACO))
	bloco.add_child(_novo_label("", SETA + SETA_ESPACO + TEXTO_ALTURA))
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
		if filho is ColorRect:
			filho.position = Vector2(0.0, SETA + SETA_ESPACO)
			filho.size = Vector2(r.size.x, TEXTO_ALTURA * 2.0)
		elif filho is Label:
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
