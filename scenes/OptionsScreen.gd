class_name OptionsScreen
extends CanvasLayer

# Tela de Opcoes (handoff 10): fundo preto a 60%, titulo "Opcoes", sliders Music e SFX e botao Voltar, num bloco
# centrado na safe area. Montada por codigo; a Stage a instancia e injeta o layout (`aplicar_layout`).
# `process_mode = ALWAYS`: recebe entrada com a arvore pausada. Todo toque/clique e consumido (fundo nao faz nada).
# O toque pertence ao slider desde o pressionar na area e se mantem fora dela, com x limitado (eixo vertical ignorado).
# Voltar aciona ao soltar com o dedo dentro do retangulo. Esc/P (acao `pause`) = Voltar, nunca retoma a partida.
# Layout por lista de itens (TIPOS/ESPACO_ANTES): acrescentar um item (ex.: botao "Ver tutorial") e inserir nas
# duas listas, em ITEM_* e em TEXTOS; as contas de y seguem a lista.

# Emitido por Voltar e pela acao `pause` com a tela aberta.
signal voltar

enum Item { MUSIC, SFX, VOLTAR }
enum Tipo { SLIDER, BOTAO }

const FONTE: Font = preload("res://fonts/alterebro-pixel-font.ttf")
const COR_TEXTO: Color = Color(1.0, 1.0, 1.0, 1.0)
const COR_CONTORNO: Color = Color(0.0, 0.0, 0.0, 1.0)
const COR_FUNDO: Color = Color(0.0, 0.0, 0.0, 0.6)
const COR_BOTAO: Color = Color("#5b8a4a")
const COR_PREENCHIMENTO: Color = Color("#5b8a4a")
const COR_TRILHA: Color = Color(0.0, 0.0, 0.0, 1.0)
const COR_MOLDURA_TRILHA: Color = Color(1.0, 1.0, 1.0, 0.6)
const COR_CURSOR: Color = Color(1.0, 1.0, 1.0, 1.0)
# Chave do mouse no dicionario de toques (dedos do toque sao indices pequenos)
const DEDO_MOUSE: int = 1000
# Acima do overlay de pausa (PauseOverlay.CAMADA = 10)
const CAMADA: int = 11

# Itens na ordem de foco e de cima para baixo; espaco acima de cada item (handoff 10.2)
const TIPOS: Array[int] = [Tipo.SLIDER, Tipo.SLIDER, Tipo.BOTAO]
const ESPACO_ANTES: Array[float] = [12.0, 8.0, 12.0]
const NOMES: Array[String] = ["Music", "SFX", "Voltar"]

# Medidas em px logicos (handoff 10.2)
const LARGURA: float = 180.0
const TITULO_ALTURA: float = 30.0
const ROTULO_ALTURA: float = 17.0
const ROTULO_ESPACO: float = 2.0
const AREA_X: float = 8.0
const AREA_LARGURA: float = 164.0
const AREA_ALTURA: float = 24.0
const SLIDER_ALTURA: float = 43.0
const TRILHA_ALTURA: float = 6.0
const BOTAO_X: float = 34.0
const BOTAO_LARGURA: float = 112.0
const BOTAO_ALTURA: float = 32.0
const CURSOR_NORMAL: Vector2 = Vector2(12.0, 16.0)
const CURSOR_ARRASTANDO: Vector2 = Vector2(14.0, 20.0)
const TAMANHO_TITULO: int = 36
const TAMANHO_TEXTO: int = 20
const CONTORNO_TITULO: int = 2
const CONTORNO_TEXTO: int = 1

const TEXTO_TITULO: String = "Opcoes"

var _fundo: ColorRect
var _titulo: Label
var _molduras: Array[Panel] = []
var _nomes: Array[Label] = []
var _valores_lbl: Array[Label] = []
var _trilhas_moldura: Array[Panel] = []
var _trilhas: Array[Panel] = []
var _preenchimentos: Array[ColorRect] = []
var _cursores: Array[Panel] = []
var _botao_painel: Panel
var _botao_rotulo: Label
# Area de toque do slider ou retangulo do botao, por item
var _rects: Array[Rect2] = []
# Valor 0-100 por item (so os sliders usam)
var _valores: Array[int] = [100, 100, 0]
var _foco: int = Item.MUSIC
var _aberta: bool = false
# index do dedo -> item em que o toque comecou (-1 = fundo)
var _toques: Dictionary = {}
var _pressionado: int = -1
# Valor aplicado no bus durante o arrasto e ainda nao gravado no cfg (grava ao soltar ou ao fechar)
var _pendente: bool = false


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in TIPOS.size():
		_rects.append(Rect2())


func _ready() -> void:
	layer = CAMADA
	visible = false
	_fundo = ColorRect.new()
	_fundo.color = COR_FUNDO
	_fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fundo.focus_mode = Control.FOCUS_NONE
	add_child(_fundo)
	_titulo = _novo_label(TEXTO_TITULO, TAMANHO_TITULO, CONTORNO_TITULO, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(_titulo)
	for i in TIPOS.size():
		var moldura := _novo_panel(_estilo(Color(0, 0, 0, 0), 2, COR_CONTORNO))
		add_child(moldura)
		_molduras.append(moldura)
		if TIPOS[i] == Tipo.SLIDER:
			var nome := _novo_label(NOMES[i], TAMANHO_TEXTO, CONTORNO_TEXTO, HORIZONTAL_ALIGNMENT_LEFT)
			add_child(nome)
			_nomes.append(nome)
			var valor := _novo_label("", TAMANHO_TEXTO, CONTORNO_TEXTO, HORIZONTAL_ALIGNMENT_RIGHT)
			add_child(valor)
			_valores_lbl.append(valor)
			var tm := _novo_panel(_estilo(COR_MOLDURA_TRILHA, 0, COR_CONTORNO))
			add_child(tm)
			_trilhas_moldura.append(tm)
			var trilha := _novo_panel(_estilo(COR_TRILHA, 0, COR_CONTORNO))
			add_child(trilha)
			_trilhas.append(trilha)
			var fill := ColorRect.new()
			fill.color = COR_PREENCHIMENTO
			fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fill.focus_mode = Control.FOCUS_NONE
			add_child(fill)
			_preenchimentos.append(fill)
			var cursor := _novo_panel(_estilo(COR_CURSOR, 1, COR_CONTORNO))
			add_child(cursor)
			_cursores.append(cursor)
		else:
			_botao_painel = _novo_panel(_estilo(COR_BOTAO, 1, COR_CONTORNO))
			add_child(_botao_painel)
			_botao_rotulo = _novo_label(NOMES[i], TAMANHO_TEXTO, CONTORNO_TEXTO, HORIZONTAL_ALIGNMENT_CENTER)
			_botao_painel.add_child(_botao_rotulo)
	_atualizar_visual()


func _input(event: InputEvent) -> void:
	if tratar_evento(event):
		get_viewport().set_input_as_handled()


# Processa um evento de entrada; devolve true se foi consumido (tela aberta consome todo toque).
func tratar_evento(event: InputEvent) -> bool:
	if not _aberta:
		return false
	if event is InputEventScreenTouch:
		var toque := event as InputEventScreenTouch
		_tratar_ponteiro(toque.index, toque.pressed, toque.position)
		return true
	if event is InputEventScreenDrag:
		var arrasto := event as InputEventScreenDrag
		_arrastar(arrasto.index, arrasto.position)
		return true
	if event is InputEventMouseButton:
		return _tratar_mouse(event as InputEventMouseButton)
	if event is InputEventMouseMotion:
		return _tratar_movimento(event as InputEventMouseMotion)
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventAction:
		return _tratar_acao(event)
	return false


# Posiciona fundo, titulo, sliders e botao a partir do tamanho visivel e da safe area (coordenadas logicas).
func aplicar_layout(visible_size: Vector2, safe: Rect2) -> void:
	var s_top := safe.position.y
	var s_bottom := visible_size.y - safe.end.y
	var util := visible_size.y - s_top - s_bottom
	var y0 := s_top + (util - _altura_bloco()) / 2.0
	var y := y0 + TITULO_ALTURA
	var topo_rotulos: Array[float] = []
	for i in TIPOS.size():
		y += ESPACO_ANTES[i]
		if TIPOS[i] == Tipo.SLIDER:
			topo_rotulos.append(y)
			_rects[i] = Rect2(AREA_X, y + ROTULO_ALTURA + ROTULO_ESPACO, AREA_LARGURA, AREA_ALTURA)
			y += SLIDER_ALTURA
		else:
			_rects[i] = Rect2(BOTAO_X, y, BOTAO_LARGURA, BOTAO_ALTURA)
			y += BOTAO_ALTURA
	if _fundo == null:
		return
	_fundo.position = Vector2.ZERO
	_fundo.size = Vector2(LARGURA, visible_size.y)
	_titulo.position = Vector2(0.0, y0)
	_titulo.size = Vector2(LARGURA, TITULO_ALTURA)
	var s := 0
	for i in TIPOS.size():
		var r: Rect2 = _rects[i]
		_molduras[i].position = r.position - Vector2(1.0, 1.0)
		_molduras[i].size = r.size + Vector2(2.0, 2.0)
		if TIPOS[i] == Tipo.SLIDER:
			var linha := Rect2(SliderMath.X_MIN, topo_rotulos[s], SliderMath.LARGURA_TRILHA, ROTULO_ALTURA)
			_nomes[s].position = linha.position
			_nomes[s].size = linha.size
			_valores_lbl[s].position = linha.position
			_valores_lbl[s].size = linha.size
			var cy := r.position.y + r.size.y / 2.0
			_trilhas_moldura[s].position = Vector2(SliderMath.X_MIN - 1.0, cy - TRILHA_ALTURA / 2.0 - 1.0)
			_trilhas_moldura[s].size = Vector2(SliderMath.LARGURA_TRILHA + 2.0, TRILHA_ALTURA + 2.0)
			_trilhas[s].position = Vector2(SliderMath.X_MIN, cy - TRILHA_ALTURA / 2.0)
			_trilhas[s].size = Vector2(SliderMath.LARGURA_TRILHA, TRILHA_ALTURA)
			s += 1
		else:
			_botao_painel.position = r.position
			_botao_painel.size = r.size
			_botao_rotulo.size = r.size
	_atualizar_visual()


# Retangulo da area de toque do slider (0 = Music, 1 = SFX).
func rect_slider(canal: int) -> Rect2:
	return _rects[canal]


func rect_music() -> Rect2:
	return _rects[Item.MUSIC]


func rect_sfx() -> Rect2:
	return _rects[Item.SFX]


func rect_voltar() -> Rect2:
	return _rects[Item.VOLTAR]


# Item com foco (enum Item).
func foco_atual() -> int:
	return _foco


# Valor 0-100 exibido no slider (0 = Music, 1 = SFX).
func valor_slider(canal: int) -> int:
	return _valores[canal]


func esta_aberta() -> bool:
	return _aberta


func abrir() -> void:
	_aberta = true
	_foco = Item.MUSIC
	_toques.clear()
	_pressionado = -1
	_pendente = false
	_valores[Item.MUSIC] = roundi(Global.get_volume_music() * SliderMath.VALOR_MAX)
	_valores[Item.SFX] = roundi(Global.get_volume_sfx() * SliderMath.VALOR_MAX)
	visible = true
	_atualizar_visual()


func fechar() -> void:
	_persistir_pendente()
	_aberta = false
	_toques.clear()
	_pressionado = -1
	visible = false


func _altura_bloco() -> float:
	var h := TITULO_ALTURA
	for i in TIPOS.size():
		h += ESPACO_ANTES[i]
		h += SLIDER_ALTURA if TIPOS[i] == Tipo.SLIDER else BOTAO_ALTURA
	return h


func _tratar_acao(event: InputEvent) -> bool:
	var key := event as InputEventKey
	var repetido := key != null and key.echo
	if TIPOS[_foco] == Tipo.SLIDER:
		if event.is_action_pressed("ui_left", true):
			_definir_valor(_foco, SliderMath.passo(_valores[_foco], -1), true)
			return true
		if event.is_action_pressed("ui_right", true):
			_definir_valor(_foco, SliderMath.passo(_valores[_foco], 1), true)
			return true
	if repetido:
		return false
	if event.is_action_pressed("pause"):
		voltar.emit()
		return true
	if event.is_action_pressed("ui_down"):
		_foco = (_foco + 1) % TIPOS.size()
		_atualizar_visual()
		return true
	if event.is_action_pressed("ui_up"):
		_foco = (_foco + TIPOS.size() - 1) % TIPOS.size()
		_atualizar_visual()
		return true
	if event.is_action_pressed("ui_accept"):
		if TIPOS[_foco] == Tipo.BOTAO:
			voltar.emit()
		return true
	return false


# Clique de mouse esquerdo real (nao emulado a partir do toque) tem a mesma arbitragem do toque. Botao direito e
# mouse emulado nao sao da tela: devolvem false (nao consumidos).
func _tratar_mouse(mouse: InputEventMouseButton) -> bool:
	if mouse.device == InputEvent.DEVICE_ID_EMULATION or mouse.button_index != MOUSE_BUTTON_LEFT:
		return false
	_tratar_ponteiro(DEDO_MOUSE, mouse.pressed, mouse.position)
	return true


# Arrasto com o botao esquerdo apertado: so conta se o clique comecou na tela (mouse emulado nao e da tela).
func _tratar_movimento(mov: InputEventMouseMotion) -> bool:
	if mov.device == InputEvent.DEVICE_ID_EMULATION or not _toques.has(DEDO_MOUSE):
		return false
	_arrastar(DEDO_MOUSE, mov.position)
	return true


func _tratar_ponteiro(dedo: int, pressionado: bool, pos: Vector2) -> void:
	if pressionado:
		var item := _item_em(pos)
		_toques[dedo] = item
		if item != -1 and TIPOS[item] == Tipo.SLIDER:
			_definir_valor(item, SliderMath.valor_de_x(pos.x), false)
		else:
			_pressionado = item
		_atualizar_visual()
		return
	var inicio: int = _toques.get(dedo, -1)
	_toques.erase(dedo)
	_pressionado = -1
	if inicio != -1 and TIPOS[inicio] == Tipo.SLIDER:
		_persistir_pendente()
	_atualizar_visual()
	if inicio != -1 and TIPOS[inicio] == Tipo.BOTAO and (_rects[inicio] as Rect2).has_point(pos):
		voltar.emit()


# Arrasto de um dedo que comecou num slider: so o eixo horizontal conta, x limitado pela conta do valor.
func _arrastar(dedo: int, pos: Vector2) -> void:
	var item: int = _toques.get(dedo, -1)
	if item != -1 and TIPOS[item] == Tipo.SLIDER:
		_definir_valor(item, SliderMath.valor_de_x(pos.x), false)


func _item_em(pos: Vector2) -> int:
	for i in TIPOS.size():
		if (_rects[i] as Rect2).has_point(pos):
			return i
	return -1


# Muda o valor do slider e aplica no bus pelo Global; grava no cfg so com `persistir` (teclado). No arrasto fica
# pendente e grava ao soltar ou ao fechar. Sem mudanca nao faz nada.
func _definir_valor(item: int, valor: int, persistir: bool) -> void:
	if valor == _valores[item]:
		return
	_valores[item] = valor
	var linear := float(valor) / SliderMath.VALOR_MAX
	if item == Item.MUSIC:
		Global.set_volume_music(linear, persistir)
	else:
		Global.set_volume_sfx(linear, persistir)
	if not persistir:
		_pendente = true
	_atualizar_visual()


# Grava os volumes se algum valor foi aplicado sem gravar.
func _persistir_pendente() -> void:
	if not _pendente:
		return
	_pendente = false
	Global.salvar_volumes()


func _atualizar_visual() -> void:
	if _molduras.is_empty():
		return
	var s := 0
	for i in TIPOS.size():
		_molduras[i].visible = _foco == i
		var r: Rect2 = _rects[i]
		if TIPOS[i] == Tipo.SLIDER:
			var arrastando := _toques.values().has(i)
			_nomes[s].text = ("> " if _foco == i else "") + NOMES[i]
			_valores_lbl[s].text = SliderMath.rotulo(_valores[i])
			var cx := SliderMath.x_do_valor(_valores[i])
			var cy := r.position.y + r.size.y / 2.0
			var tam := CURSOR_ARRASTANDO if arrastando else CURSOR_NORMAL
			_cursores[s].add_theme_stylebox_override("panel", _estilo(COR_CURSOR, 2 if arrastando else 1, COR_CONTORNO))
			_cursores[s].size = tam
			_cursores[s].position = Vector2(cx - tam.x / 2.0, cy - tam.y / 2.0)
			_preenchimentos[s].position = Vector2(SliderMath.X_MIN, cy - TRILHA_ALTURA / 2.0)
			_preenchimentos[s].size = Vector2(cx - SliderMath.X_MIN, TRILHA_ALTURA)
			s += 1
		else:
			var pressed: bool = _pressionado == i
			_botao_painel.add_theme_stylebox_override("panel", _estilo(COR_BOTAO, 2 if pressed else 1, COR_CONTORNO))
			_botao_rotulo.text = ("> " if _foco == i else "") + NOMES[i]
			_botao_rotulo.position = Vector2(0.0, 1.0 if pressed else 0.0)


func _novo_panel(estilo: StyleBoxFlat) -> Panel:
	var p := Panel.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.focus_mode = Control.FOCUS_NONE
	p.add_theme_stylebox_override("panel", estilo)
	return p


func _estilo(fundo: Color, borda: int, cor_borda: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fundo
	s.set_border_width_all(borda)
	s.border_color = cor_borda
	s.set_corner_radius_all(4 if borda > 0 and fundo == COR_BOTAO else 0)
	return s


func _novo_label(texto: String, tamanho: int, contorno: int, alinhamento: HorizontalAlignment) -> Label:
	var l := Label.new()
	l.text = texto
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.focus_mode = Control.FOCUS_NONE
	l.horizontal_alignment = alinhamento
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", FONTE)
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", COR_TEXTO)
	l.add_theme_color_override("font_outline_color", COR_CONTORNO)
	l.add_theme_constant_override("outline_size", contorno)
	return l
