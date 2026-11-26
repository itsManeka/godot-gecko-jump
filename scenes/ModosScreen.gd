class_name ModosScreen
extends CanvasLayer

# Tela Modos (carrossel, handoff-power-ups-e-modos): fundo escuro, titulo, imagem 128x128 do modo, setas, nome, descricao,
# indicador de N marcas e botao OK, num bloco de 458 px centrado na altura util. Montada por codigo; a Stage a instancia
# e injeta o layout (`aplicar_layout`). O modo exibido ja e o selecionado: OK so fecha (sinal `fechado` com o modo).
# Troca por seta ou por arrasto horizontal >= LIMIAR_ARRASTO iniciado na faixa do carrossel (sinal `modo_mudou`).
# Todo toque/clique com a tela aberta e consumido (nao vaza ao Play). So abre com o jogo nao iniciado.

# Emitido quando o modo exibido muda (nao emite no ciclo de lista de 1).
signal modo_mudou(modo: GameMode)
# Emitido por OK e pela acao `pause`, com o modo exibido.
signal fechado(modo: GameMode)

const COR_CONTORNO: Color = Color(0.0, 0.0, 0.0, 1.0)
const COR_FUNDO: Color = UiHelpers.COR_FUNDO_OVERLAY
const COR_BOTAO: Color = Color("#5b8a4a")
const COR_MOLDURA: Color = Color(1.0, 1.0, 1.0, 1.0)
const COR_MARCA: Color = Color(1.0, 1.0, 1.0, 1.0)
const CAMADA: int = 11

# Medidas em px logicos, relativas ao topo do bloco (handoff)
const LARGURA: float = 360.0
const ALTURA_BLOCO: float = 458.0
const TITULO_ALTURA: float = 60.0
const IMAGEM_X: float = 116.0
const IMAGEM_Y: float = 84.0
const IMAGEM_LADO: float = 128.0
const SETA_LADO: float = 48.0
const SETA_ESQ_X: float = 8.0
const SETA_DIR_X: float = 304.0
const SETA_Y: float = 124.0
const NOME_Y: float = 228.0
const NOME_ALTURA: float = 34.0
const DESC_X: float = 20.0
const DESC_Y: float = 270.0
const DESC_LARGURA: float = 320.0
const DESC_ALTURA: float = 68.0
const MARCA_Y: float = 362.0
const MARCA_ALTURA: float = 8.0
const MARCA_LARGURA: float = 8.0
const MARCA_ATUAL_LARGURA: float = 16.0
const MARCA_ESPACO: float = 8.0
const OK_X: float = 68.0
const OK_Y: float = 394.0
const OK_LARGURA: float = 224.0
const OK_ALTURA: float = 64.0
# Faixa do carrossel onde o arrasto vale (x 60-300, y 84-338) e deslocamento horizontal minimo que troca o modo
const FAIXA_X: float = 60.0
const FAIXA_Y: float = 84.0
const FAIXA_LARGURA: float = 240.0
const FAIXA_ALTURA: float = 254.0
const LIMIAR_ARRASTO: float = 32.0

const TEXTO_TITULO: String = "Modos"
const TEXTO_OK: String = "OK"

enum Alvo { FUNDO, SETA_ESQ, SETA_DIR, OK, FAIXA }

var _fundo: ColorRect
var _titulo: Label
var _imagem: Panel
var _seta_esq: Panel
var _seta_dir: Panel
var _ok: Panel
var _nome_lbl: Label
var _desc_lbl: Label
var _marcas_nos: Array[ColorRect] = []
var _rect_titulo: Rect2 = Rect2()
var _rect_imagem: Rect2 = Rect2()
var _rect_seta_esq: Rect2 = Rect2()
var _rect_seta_dir: Rect2 = Rect2()
var _rect_nome: Rect2 = Rect2()
var _rect_descricao: Rect2 = Rect2()
var _rect_ok: Rect2 = Rect2()
var _rect_faixa: Rect2 = Rect2()
var _marcas: Array[Rect2] = []
var _tamanho: Vector2 = Vector2(LARGURA, 640.0)
var _y0: float = 0.0
var _modos: Array[GameMode] = []
var _indice: int = 0
var _aberta: bool = false
# dedo -> {"alvo": Alvo, "x0": float, "trocou": bool}
var _toques: Dictionary = {}
var _pressionado: int = Alvo.FUNDO


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	aplicar_layout(Vector2(LARGURA, 640.0), Rect2(0.0, 0.0, LARGURA, 640.0))


func _ready() -> void:
	layer = CAMADA
	visible = false
	_fundo = ColorRect.new()
	_fundo.color = COR_FUNDO
	_fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fundo.focus_mode = Control.FOCUS_NONE
	add_child(_fundo)
	_titulo = UiHelpers.novo_label(TEXTO_TITULO, UiHelpers.TAMANHO_TITULO, 4, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(_titulo)
	_imagem = _novo_panel(_estilo_imagem())
	add_child(_imagem)
	_seta_esq = _novo_botao("<")
	_seta_dir = _novo_botao(">")
	_nome_lbl = UiHelpers.novo_label("", UiHelpers.TAMANHO_TEXTO, 2, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(_nome_lbl)
	_desc_lbl = UiHelpers.novo_label("", UiHelpers.TAMANHO_TEXTO, 2, HORIZONTAL_ALIGNMENT_CENTER)
	_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_lbl.clip_text = true
	add_child(_desc_lbl)
	_ok = _novo_botao(TEXTO_OK)
	_posicionar()
	_atualizar_visual()


func _input(event: InputEvent) -> void:
	# O OK pode recarregar a Stage e tirar este no da arvore: guarda o viewport antes de tratar o evento.
	var vp := get_viewport()
	if tratar_evento(event) and vp != null:
		vp.set_input_as_handled()


# Processa um evento; devolve true se foi consumido (tela aberta consome todo toque/clique).
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
		var botao := event as InputEventMouseButton
		if botao.device == InputEvent.DEVICE_ID_EMULATION or botao.button_index != MOUSE_BUTTON_LEFT:
			return false
		_tratar_ponteiro(UiHelpers.DEDO_MOUSE, botao.pressed, botao.position)
		return true
	if event is InputEventMouseMotion:
		var mov := event as InputEventMouseMotion
		if mov.device == InputEvent.DEVICE_ID_EMULATION or not _toques.has(UiHelpers.DEDO_MOUSE):
			return false
		_arrastar(UiHelpers.DEDO_MOUSE, mov.position)
		return true
	if event is InputEventKey:
		return _tratar_tecla(event as InputEventKey)
	return false


# Posiciona o bloco a partir do tamanho visivel e da safe area (coordenadas logicas); y0 arredondado ao pixel.
func aplicar_layout(visible_size: Vector2, safe: Rect2) -> void:
	_tamanho = visible_size
	var s_top := safe.position.y
	var s_bottom := visible_size.y - safe.end.y
	var util := visible_size.y - s_top - s_bottom
	_y0 = roundf(s_top + (util - ALTURA_BLOCO) / 2.0)
	_rect_titulo = Rect2(0.0, _y0, LARGURA, TITULO_ALTURA)
	_rect_imagem = Rect2(IMAGEM_X, _y0 + IMAGEM_Y, IMAGEM_LADO, IMAGEM_LADO)
	_rect_seta_esq = Rect2(SETA_ESQ_X, _y0 + SETA_Y, SETA_LADO, SETA_LADO)
	_rect_seta_dir = Rect2(SETA_DIR_X, _y0 + SETA_Y, SETA_LADO, SETA_LADO)
	_rect_nome = Rect2(0.0, _y0 + NOME_Y, LARGURA, NOME_ALTURA)
	_rect_descricao = Rect2(DESC_X, _y0 + DESC_Y, DESC_LARGURA, DESC_ALTURA)
	_rect_ok = Rect2(OK_X, _y0 + OK_Y, OK_LARGURA, OK_ALTURA)
	_rect_faixa = Rect2(FAIXA_X, _y0 + FAIXA_Y, FAIXA_LARGURA, FAIXA_ALTURA)
	_calcular_marcas()
	_posicionar()


func rect_titulo() -> Rect2:
	return _rect_titulo


func rect_imagem() -> Rect2:
	return _rect_imagem


func rect_seta_esq() -> Rect2:
	return _rect_seta_esq


func rect_seta_dir() -> Rect2:
	return _rect_seta_dir


func rect_nome() -> Rect2:
	return _rect_nome


func rect_descricao() -> Rect2:
	return _rect_descricao


func rect_ok() -> Rect2:
	return _rect_ok


# Faixa onde um arrasto horizontal troca o modo.
func rect_faixa_arrasto() -> Rect2:
	return _rect_faixa


# Retangulos das N marcas do indicador (a do modo exibido tem 16x8, as demais 8x8).
func rect_marcas() -> Array[Rect2]:
	return _marcas


func modo_exibido() -> GameMode:
	if _modos.is_empty():
		return GameModes.padrao()
	return _modos[_indice]


func esta_aberta() -> bool:
	return _aberta


# Abre com `atual` exibido; `modos` vazio = lista do registro (com o modo de teste so com a flag de debug).
# Recusada (false) com a partida iniciada.
func abrir(atual: GameMode, modos: Array[GameMode] = []) -> bool:
	if Global.is_iniciado():
		return false
	_modos = modos if not modos.is_empty() else GameModes.lista(Global.modos_teste_habilitado)
	_indice = _indice_de(atual)
	_aberta = true
	_toques.clear()
	_pressionado = Alvo.FUNDO
	_calcular_marcas()
	visible = true
	_posicionar()
	_atualizar_visual()
	return true


func fechar() -> void:
	_aberta = false
	_toques.clear()
	_pressionado = Alvo.FUNDO
	visible = false


func _indice_de(modo: GameMode) -> int:
	for i in _modos.size():
		if _modos[i].id == modo.id:
			return i
	return 0


func _trocar(passo: int) -> void:
	if _modos.is_empty():
		return
	var antes := modo_exibido()
	var depois := GameModes.proximo(antes, _modos) if passo > 0 else GameModes.anterior(antes, _modos)
	_indice = _indice_de(depois)
	_calcular_marcas()
	_posicionar()
	_atualizar_visual()
	if depois.id != antes.id:
		modo_mudou.emit(depois)


func _tratar_tecla(key: InputEventKey) -> bool:
	if key.echo:
		return false
	if key.is_action_pressed("ui_left"):
		_trocar(-1)
		return true
	if key.is_action_pressed("ui_right"):
		_trocar(1)
		return true
	if key.is_action_pressed("ui_accept") or key.is_action_pressed("pause"):
		fechado.emit(modo_exibido())
		return true
	return false


func _alvo_em(pos: Vector2) -> int:
	if _rect_ok.has_point(pos):
		return Alvo.OK
	if _rect_seta_esq.has_point(pos):
		return Alvo.SETA_ESQ
	if _rect_seta_dir.has_point(pos):
		return Alvo.SETA_DIR
	if _rect_faixa.has_point(pos):
		return Alvo.FAIXA
	return Alvo.FUNDO


func _tratar_ponteiro(dedo: int, pressionado: bool, pos: Vector2) -> void:
	if pressionado:
		var alvo := _alvo_em(pos)
		_toques[dedo] = {"alvo": alvo, "x0": pos.x, "trocou": false}
		_pressionado = alvo
		_atualizar_visual()
		return
	var toque: Dictionary = _toques.get(dedo, {})
	_toques.erase(dedo)
	_pressionado = Alvo.FUNDO
	_atualizar_visual()
	if toque.is_empty():
		return
	var alvo: int = toque["alvo"]
	if alvo == Alvo.FAIXA:
		_verificar_arrasto(toque, pos)
	elif alvo == Alvo.SETA_ESQ and _rect_seta_esq.has_point(pos):
		_trocar(-1)
	elif alvo == Alvo.SETA_DIR and _rect_seta_dir.has_point(pos):
		_trocar(1)
	elif alvo == Alvo.OK and _rect_ok.has_point(pos):
		fechado.emit(modo_exibido())


func _arrastar(dedo: int, pos: Vector2) -> void:
	var toque: Dictionary = _toques.get(dedo, {})
	if toque.is_empty() or int(toque["alvo"]) != Alvo.FAIXA:
		return
	_verificar_arrasto(toque, pos)


# Um gesto troca uma vez: deslocamento horizontal >= limiar; arrastar para a esquerda avanca, para a direita volta.
func _verificar_arrasto(toque: Dictionary, pos: Vector2) -> void:
	if bool(toque["trocou"]):
		return
	var dx := pos.x - float(toque["x0"])
	if absf(dx) < LIMIAR_ARRASTO:
		return
	toque["trocou"] = true
	_trocar(1 if dx < 0.0 else -1)


# Marcas centradas na largura: N = tamanho da lista, a atual 16x8 e as demais 8x8.
func _calcular_marcas() -> void:
	_marcas.clear()
	var n := _modos.size()
	if n == 0:
		return
	var total := MARCA_ATUAL_LARGURA + float(n - 1) * (MARCA_LARGURA + MARCA_ESPACO)
	var x := floorf((LARGURA - total) / 2.0)
	for i in n:
		var largura := MARCA_ATUAL_LARGURA if i == _indice else MARCA_LARGURA
		_marcas.append(Rect2(x, _y0 + MARCA_Y, largura, MARCA_ALTURA))
		x += largura + MARCA_ESPACO


func _posicionar() -> void:
	if _fundo == null:
		return
	_fundo.position = Vector2.ZERO
	_fundo.size = Vector2(LARGURA, _tamanho.y)
	_titulo.position = _rect_titulo.position
	_titulo.size = _rect_titulo.size
	_imagem.position = _rect_imagem.position
	_imagem.size = _rect_imagem.size
	_colocar_botao(_seta_esq, _rect_seta_esq)
	_colocar_botao(_seta_dir, _rect_seta_dir)
	_colocar_botao(_ok, _rect_ok)
	_nome_lbl.position = _rect_nome.position
	_nome_lbl.size = _rect_nome.size
	_desc_lbl.position = _rect_descricao.position
	_desc_lbl.size = _rect_descricao.size
	for no in _marcas_nos:
		no.queue_free()
	_marcas_nos.clear()
	for r in _marcas:
		var marca := ColorRect.new()
		marca.color = COR_MARCA
		marca.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marca.focus_mode = Control.FOCUS_NONE
		marca.position = r.position
		marca.size = r.size
		add_child(marca)
		_marcas_nos.append(marca)


func _atualizar_visual() -> void:
	if _nome_lbl == null:
		return
	var modo := modo_exibido()
	_nome_lbl.text = modo.nome
	_desc_lbl.text = modo.descricao
	_estilizar_botao(_seta_esq, _pressionado == Alvo.SETA_ESQ)
	_estilizar_botao(_seta_dir, _pressionado == Alvo.SETA_DIR)
	_estilizar_botao(_ok, _pressionado == Alvo.OK)


func _novo_botao(texto: String) -> Panel:
	var painel := _novo_panel(UiHelpers.estilo_opcoes(COR_BOTAO, 2, COR_CONTORNO, COR_BOTAO))
	add_child(painel)
	var rotulo := UiHelpers.novo_label(texto, UiHelpers.TAMANHO_TEXTO, 2, HORIZONTAL_ALIGNMENT_CENTER)
	painel.add_child(rotulo)
	return painel


func _colocar_botao(painel: Panel, r: Rect2) -> void:
	painel.position = r.position
	painel.size = r.size
	(painel.get_child(0) as Label).size = r.size


func _estilizar_botao(painel: Panel, pressionado: bool) -> void:
	painel.add_theme_stylebox_override(
		"panel", UiHelpers.estilo_opcoes(COR_BOTAO, 4 if pressionado else 2, COR_CONTORNO, COR_BOTAO)
	)
	(painel.get_child(0) as Label).position = Vector2(0.0, 2.0 if pressionado else 0.0)


# Placeholder da imagem do modo: moldura branca de 2 px sobre #5b8a4a (provisorio ate a f561: imagem de modo 128x128).
func _estilo_imagem() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = COR_BOTAO
	estilo.border_color = COR_MOLDURA
	estilo.set_border_width_all(2)
	return estilo


func _novo_panel(estilo: StyleBoxFlat) -> Panel:
	var p := Panel.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.focus_mode = Control.FOCUS_NONE
	p.add_theme_stylebox_override("panel", estilo)
	return p
