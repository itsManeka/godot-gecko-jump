class_name TutorialCard
extends CanvasLayer

# Card do tutorial da 1a partida (handoff 12): fundo preto a 60%, titulo, botao Pular, regra de cor, amostras
# "igual"/"diferente", legenda das 4 cores e a linha de controle. Montado por codigo; a Stage o instancia, injeta o
# layout (`aplicar_layout`) e abre com `abrir(variante, modo)`.
# Modo PARTIDA: nao modal; so o botao Pular recebe toque (aciona ao soltar dentro, 7.3); o resto atravessa
# (`tratar_evento` devolve false) e o botao nao entra na cadeia de foco. Quem fecha o card e a Stage (`fechar`).
# Modo REABERTURA (12.5): modal, consome todo toque; o botao vira "Voltar", com foco inicial (`>`); `ui_accept` aciona
# e Esc/P (acao `pause`) tambem. process_mode ALWAYS: recebe entrada com a arvore pausada.

# Emitido ao soltar o dedo dentro do botao no modo PARTIDA.
signal pular
# Emitido quando o fade termina e o card fica oculto.
signal fechado
# Emitido por Voltar, `ui_accept` e acao `pause` no modo REABERTURA.
signal voltar

enum Variante { TOQUE, TECLADO }
enum Modo { PARTIDA, REABERTURA }

const COR_CONTORNO: Color = Color(0.0, 0.0, 0.0, 1.0)
const COR_FUNDO: Color = Color(0.0, 0.0, 0.0, 0.6)
const COR_BOTAO: Color = Color("#5b8a4a")
const COR_SEM_FUNDO: Color = Color(0.0, 0.0, 0.0, 0.0)
# Entre a dica (0) e o botao de pausa (2) na partida; acima de Opcoes (11) na reabertura
const CAMADA_PARTIDA: int = 1
const CAMADA_REABERTURA: int = 12
# Fade-out ao fechar: proposta provisoria (handoff 12.1)
const FADE_S: float = 0.3

# Medidas em px logicos (handoff 12.2/12.3); `y` sem o `s_top`
const FUNDO: Rect2 = Rect2(8.0, 38.0, 164.0, 172.0)
const BOTAO: Rect2 = Rect2(108.0, 44.0, 56.0, 24.0)
const TITULO: Rect2 = Rect2(16.0, 44.0, 90.0, 24.0)
const LARGURA_CONTEUDO: float = 148.0
const CONTEUDO_X: float = 16.0
const LINHA_ALTURA: float = 17.0
const REGRA_Y: float = 72.0
const AMOSTRAS_Y: float = 110.0
const LEGENDA_Y: float = 149.0
const CONTROLE_Y: float = 187.0
const CELULA_LARGURA: float = 74.0
const CELULAS_X: Array[float] = [16.0, 90.0]
const TAMANHO_TEXTO: int = 20
const CONTORNO_TEXTO: int = 1

const TEXTO_TITULO: String = "Como jogar"
const TEXTO_PULAR: String = "Pular"
const TEXTO_VOLTAR: String = "Voltar"
const TEXTO_REGRA: Array[String] = ["Pise na cor dele.", "Pouso troca a cor."]
const TEXTO_CONTROLE_TOQUE: String = "Toque nas metades"
const TEXTO_CONTROLE_TECLADO: String = "Setas e espaco"
const NOMES_LEGENDA: Array[String] = ["amarelo", "verde", "azul", "vermelho"]
const CORES_LEGENDA: Array[int] = [Enums.COLOR.AMARELO, Enums.COLOR.VERDE, Enums.COLOR.AZUL, Enums.COLOR.VERMELHO]

var _raiz: Control
var _fundo: ColorRect
var _botao_painel: Panel
var _botao_rotulo: Label
var _moldura: Panel
var _controle: Label
var _variante: int = Variante.TOQUE
var _modo: int = Modo.PARTIDA
var _s_top: float = 0.0
var _aberto: bool = false
# index do dedo que comecou o toque dentro do botao
var _toques: Dictionary = {}
var _pressionado: bool = false
var _fade: Tween = null


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	layer = CAMADA_PARTIDA
	visible = false
	_raiz = Control.new()
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.focus_mode = Control.FOCUS_NONE
	add_child(_raiz)
	_fundo = ColorRect.new()
	_fundo.name = "Fundo"
	_fundo.color = COR_FUNDO
	_fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fundo.focus_mode = Control.FOCUS_NONE
	_fundo.position = FUNDO.position
	_fundo.size = FUNDO.size
	_raiz.add_child(_fundo)
	_texto("Titulo", TEXTO_TITULO, TITULO, HORIZONTAL_ALIGNMENT_LEFT)
	_montar_botao()
	for i in TEXTO_REGRA.size():
		_texto(
			"Regra%d" % i,
			TEXTO_REGRA[i],
			Rect2(CONTEUDO_X, REGRA_Y + LINHA_ALTURA * i, LARGURA_CONTEUDO, LINHA_ALTURA),
			HORIZONTAL_ALIGNMENT_LEFT
		)
	_montar_amostra(0, "=", "igual", Enums.COLOR.AMARELO)
	_montar_amostra(1, "X", "diferente", Enums.COLOR.AZUL)
	for i in NOMES_LEGENDA.size():
		_montar_legenda(i)
	_controle = _texto(
		"Controle", "", Rect2(CONTEUDO_X, CONTROLE_Y, LARGURA_CONTEUDO, LINHA_ALTURA), HORIZONTAL_ALIGNMENT_LEFT
	)
	_atualizar_textos()
	_atualizar_botao()


func _input(event: InputEvent) -> void:
	if tratar_evento(event):
		get_viewport().set_input_as_handled()


# Largura (px) de um texto na fonte e tamanho do card.
static func largura_texto(texto: String) -> float:
	return UiHelpers.FONTE.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANHO_TEXTO).x


# Processa um evento; devolve true se foi consumido. Partida: so o toque que comeca no botao (e o que se segue dele);
# reabertura: todo toque e as acoes de Voltar.
func tratar_evento(event: InputEvent) -> bool:
	if not _aberto:
		return false
	# Partida com a arvore pausada: o overlay de pausa e quem recebe o toque
	if _modo == Modo.PARTIDA and is_inside_tree() and get_tree().paused:
		return false
	if event is InputEventScreenTouch:
		var toque := event as InputEventScreenTouch
		return _tratar_ponteiro(toque.index, toque.pressed, toque.position)
	if event is InputEventScreenDrag:
		var arrasto := event as InputEventScreenDrag
		return _arrastar(arrasto.index, arrasto.position)
	if event is InputEventMouseButton:
		var clique := event as InputEventMouseButton
		if clique.device == InputEvent.DEVICE_ID_EMULATION or clique.button_index != MOUSE_BUTTON_LEFT:
			return false
		return _tratar_ponteiro(UiHelpers.DEDO_MOUSE, clique.pressed, clique.position)
	if event is InputEventMouseMotion:
		var mov := event as InputEventMouseMotion
		if mov.device == InputEvent.DEVICE_ID_EMULATION:
			return false
		return _arrastar(UiHelpers.DEDO_MOUSE, mov.position)
	if _modo == Modo.REABERTURA and (event is InputEventKey or event is InputEventJoypadButton or event is InputEventAction):
		return _tratar_acao(event)
	return false


# Posiciona o card a partir do tamanho visivel e da safe area (coordenadas logicas); so `s_top` desloca o card.
func aplicar_layout(_visible_size: Vector2, safe: Rect2) -> void:
	_s_top = safe.position.y
	if _raiz != null:
		_raiz.position = Vector2(0.0, _s_top)


# Abre o card na variante (toque x teclado) e no modo dados; a reabertura sobe de camada e ganha o foco em Voltar.
func abrir(variante: int, modo: int = Modo.PARTIDA) -> void:
	_cancelar_fade()
	_variante = variante
	_modo = modo
	_aberto = true
	_toques.clear()
	_pressionado = false
	layer = CAMADA_REABERTURA if modo == Modo.REABERTURA else CAMADA_PARTIDA
	if _raiz != null:
		_raiz.modulate.a = 1.0
	visible = true
	_atualizar_textos()
	_atualizar_botao()


# Fecha com fade de 0.3 s e emite `fechado` ao terminar; `imediato` oculta no mesmo frame.
func fechar(imediato: bool = false) -> void:
	if not _aberto:
		return
	_aberto = false
	_toques.clear()
	_pressionado = false
	_atualizar_botao()
	if imediato or not is_inside_tree() or _raiz == null:
		_ocultar()
		return
	_cancelar_fade()
	_fade = create_tween()
	_fade.tween_property(_raiz, "modulate:a", 0.0, FADE_S)
	_fade.tween_callback(_ocultar)


# Retangulo do botao Pular/Voltar (coordenadas logicas, com `s_top`).
func rect_pular() -> Rect2:
	return Rect2(BOTAO.position + Vector2(0.0, _s_top), BOTAO.size)


# Retangulo do fundo do card (coordenadas logicas, com `s_top`).
func rect_fundo() -> Rect2:
	return Rect2(FUNDO.position + Vector2(0.0, _s_top), FUNDO.size)


func esta_aberto() -> bool:
	return _aberto


# Variante em uso (enum Variante).
func variante() -> int:
	return _variante


# Modo em uso (enum Modo).
func modo() -> int:
	return _modo


func _cancelar_fade() -> void:
	if _fade != null and _fade.is_valid():
		_fade.kill()
	_fade = null


func _ocultar() -> void:
	_fade = null
	visible = false
	fechado.emit()


func _tratar_ponteiro(dedo: int, pressionado: bool, pos: Vector2) -> bool:
	var modal := _modo == Modo.REABERTURA
	var dentro := rect_pular().has_point(pos)
	if pressionado:
		if dentro:
			_toques[dedo] = true
			_pressionado = true
			_atualizar_botao()
			return true
		return modal
	var comecou := _toques.has(dedo)
	_toques.erase(dedo)
	_pressionado = not _toques.is_empty()
	_atualizar_botao()
	if comecou and dentro:
		_acionar()
	return comecou or modal


# Dedo que comecou no botao e saiu dele solta o visual de pressionado; o toque so aciona ao soltar dentro.
func _arrastar(dedo: int, pos: Vector2) -> bool:
	if not _toques.has(dedo):
		return false
	var dentro := rect_pular().has_point(pos)
	if dentro != _pressionado:
		_pressionado = dentro
		_atualizar_botao()
	return true


func _tratar_acao(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key != null and key.echo:
		return false
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_accept"):
		voltar.emit()
		return true
	return false


func _acionar() -> void:
	if _modo == Modo.REABERTURA:
		voltar.emit()
	else:
		pular.emit()


func _atualizar_textos() -> void:
	if _controle == null:
		return
	_controle.text = TEXTO_CONTROLE_TECLADO if _variante == Variante.TECLADO else TEXTO_CONTROLE_TOQUE


func _atualizar_botao() -> void:
	if _botao_painel == null:
		return
	var reabertura := _modo == Modo.REABERTURA
	_moldura.visible = reabertura
	_botao_painel.add_theme_stylebox_override(
		"panel", UiHelpers.estilo_opcoes(COR_BOTAO, 2 if _pressionado else 1, COR_CONTORNO, COR_BOTAO)
	)
	_botao_rotulo.text = ("> " + TEXTO_VOLTAR) if reabertura else TEXTO_PULAR
	_botao_rotulo.position = Vector2(0.0, 1.0 if _pressionado else 0.0)


func _montar_botao() -> void:
	_moldura = _novo_panel("Moldura", UiHelpers.estilo(COR_SEM_FUNDO, 2, COR_CONTORNO, 0))
	_moldura.position = BOTAO.position - Vector2(1.0, 1.0)
	_moldura.size = BOTAO.size + Vector2(2.0, 2.0)
	_raiz.add_child(_moldura)
	_botao_painel = _novo_panel("Pular", UiHelpers.estilo_opcoes(COR_BOTAO, 1, COR_CONTORNO, COR_BOTAO))
	_botao_painel.position = BOTAO.position
	_botao_painel.size = BOTAO.size
	_raiz.add_child(_botao_painel)
	_botao_rotulo = UiHelpers.novo_label(TEXTO_PULAR, TAMANHO_TEXTO, CONTORNO_TEXTO, HORIZONTAL_ALIGNMENT_CENTER)
	_botao_rotulo.size = BOTAO.size
	_botao_painel.add_child(_botao_rotulo)


# Celula de amostra 74x35: gecko 12x16, marca (10 de largura), plataforma 32x8 e rotulo (handoff 12.3).
func _montar_amostra(i: int, marca: String, rotulo: String, cor_plataforma: int) -> void:
	var cx: float = CELULAS_X[i]
	var gecko := _novo_panel("Amostra%dGecko" % i, UiHelpers.estilo(Enums.get_cor(Enums.COLOR.AMARELO), 1, COR_CONTORNO, 0))
	gecko.position = Vector2(cx, AMOSTRAS_Y + 1.0)
	gecko.size = Vector2(12.0, 16.0)
	_raiz.add_child(gecko)
	_texto("Amostra%dMarca" % i, marca, Rect2(cx + 16.0, AMOSTRAS_Y, 10.0, 18.0), HORIZONTAL_ALIGNMENT_CENTER)
	var plataforma := _novo_panel("Amostra%dPlataforma" % i, UiHelpers.estilo(Enums.get_cor(cor_plataforma), 1, COR_CONTORNO, 0))
	plataforma.position = Vector2(cx + 30.0, AMOSTRAS_Y + 9.0)
	plataforma.size = Vector2(32.0, 8.0)
	_raiz.add_child(plataforma)
	_texto(
		"Amostra%dRotulo" % i,
		rotulo,
		Rect2(cx, AMOSTRAS_Y + 18.0, CELULA_LARGURA, LINHA_ALTURA),
		HORIZONTAL_ALIGNMENT_LEFT
	)


# Legenda 2 colunas x 2 linhas: quadrado 12x12 com contorno de 1 px e o nome por escrito em x = 16 da celula.
func _montar_legenda(i: int) -> void:
	var cx: float = CELULAS_X[i % 2]
	var cy: float = LEGENDA_Y + LINHA_ALTURA * floori(i / 2.0)
	var quadro := _novo_panel("Legenda%dQuadro" % i, UiHelpers.estilo(Enums.get_cor(CORES_LEGENDA[i]), 1, COR_CONTORNO, 0))
	quadro.position = Vector2(cx, cy + 2.0)
	quadro.size = Vector2(12.0, 12.0)
	_raiz.add_child(quadro)
	_texto("Legenda%dNome" % i, NOMES_LEGENDA[i], Rect2(cx + 16.0, cy, CELULA_LARGURA - 16.0, LINHA_ALTURA), HORIZONTAL_ALIGNMENT_LEFT)


func _texto(nome: String, texto: String, r: Rect2, alinhamento: HorizontalAlignment) -> Label:
	var l := UiHelpers.novo_label(texto, TAMANHO_TEXTO, CONTORNO_TEXTO, alinhamento)
	l.name = nome
	# Sem clip o Label cresce ate o minimo da fonte e a caixa passa da medida do handoff
	l.clip_text = true
	l.position = r.position
	l.size = r.size
	_raiz.add_child(l)
	return l


func _novo_panel(nome: String, estilo: StyleBoxFlat) -> Panel:
	var p := Panel.new()
	p.name = nome
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.focus_mode = Control.FOCUS_NONE
	p.add_theme_stylebox_override("panel", estilo)
	return p
