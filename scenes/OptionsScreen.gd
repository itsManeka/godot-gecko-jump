class_name OptionsScreen
extends CanvasLayer

# Tela de Opcoes (handoff 10): fundo preto a 60%, titulo "Opcoes", sliders Music e SFX e botao Voltar, num bloco
# centrado na safe area. Montada por codigo; a Stage a instancia e injeta o layout (`aplicar_layout`).
# `process_mode = ALWAYS`: recebe entrada com a arvore pausada. Todo toque/clique e consumido (fundo nao faz nada).
# O toque pertence ao slider desde o pressionar na area e se mantem fora dela, com x limitado (eixo vertical ignorado).
# Voltar aciona ao soltar com o dedo dentro do retangulo. Esc/P (acao `pause`) = Voltar, nunca retoma a partida.
# Layout por lista de itens (TIPOS/ESPACO_ANTES): acrescentar um item e inserir nas listas TIPOS/ESPACO_ANTES/NOMES,
# no enum Item e em _valores; as contas de y seguem a lista visivel. Sliders: Music, SFX e Sensibilidade (este so no
# modo A (Flick), decisao 2a do G1: em B (Joy invisivel) o bloco volta a 520 px (622 com ele) e a ordem de foco pula o item). Botoes: Toque (alterna o modo
# Flick <-> Joy invisivel pelo Global), Ver tutorial (sinal `ver_tutorial`) e Voltar.

# Emitido por Voltar e pela acao `pause` com a tela aberta.
signal voltar
# Emitido por Ver tutorial (toque solto dentro ou `ui_accept` com o foco nele).
signal ver_tutorial

enum Item { MUSIC, SFX, SENSIBILIDADE, TOQUE, VER_TUTORIAL, VOLTAR }
enum Tipo { SLIDER, BOTAO }

const COR_CONTORNO: Color = Color(0.0, 0.0, 0.0, 1.0)
const COR_FUNDO: Color = UiHelpers.COR_FUNDO_OVERLAY
const COR_BOTAO: Color = Color("#5b8a4a")
const COR_PREENCHIMENTO: Color = Color("#5b8a4a")
const COR_TRILHA: Color = Color(0.0, 0.0, 0.0, 1.0)
const COR_MOLDURA_TRILHA: Color = Color(1.0, 1.0, 1.0, 0.6)
const COR_CURSOR: Color = Color(1.0, 1.0, 1.0, 1.0)
# Acima do overlay de pausa (PauseOverlay.CAMADA = 10)
const CAMADA: int = 11

# Itens na ordem de foco e de cima para baixo; espaco acima de cada item (handoff 10.2)
const TIPOS: Array[int] = [Tipo.SLIDER, Tipo.SLIDER, Tipo.SLIDER, Tipo.BOTAO, Tipo.BOTAO, Tipo.BOTAO]
const ESPACO_ANTES: Array[float] = [24.0, 16.0, 16.0, 24.0, 16.0, 16.0]
const NOMES: Array[String] = ["Music", "SFX", "Sensibilidade", "Toque", "Ver tutorial", "Voltar"]

# Medidas em px logicos de 360x640 (2x do handoff 10.2)
const LARGURA: float = 360.0
const TITULO_ALTURA: float = 60.0
const ROTULO_ALTURA: float = 34.0
const ROTULO_ESPACO: float = 4.0
const AREA_X: float = 16.0
const AREA_LARGURA: float = 328.0
const AREA_ALTURA: float = 48.0
const SLIDER_ALTURA: float = 86.0
const TRILHA_ALTURA: float = 12.0
const BOTAO_X: float = 68.0
const BOTAO_LARGURA: float = 224.0
const BOTAO_ALTURA: float = 64.0
const CURSOR_NORMAL: Vector2 = Vector2(24.0, 32.0)
const CURSOR_ARRASTANDO: Vector2 = Vector2(28.0, 40.0)
const TAMANHO_TITULO: int = UiHelpers.TAMANHO_TITULO
const TAMANHO_TEXTO: int = UiHelpers.TAMANHO_TEXTO
const CONTORNO_TITULO: int = 4
const CONTORNO_TEXTO: int = 2

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
# Painel e rotulo por item (null nos sliders)
var _botao_paineis: Array[Panel] = []
var _botao_rotulos: Array[Label] = []
# Area de toque do slider ou retangulo do botao, por item
var _rects: Array[Rect2] = []
# Valor 0-100 por item (so os sliders usam; Sensibilidade = posicao na faixa de TouchTuning)
var _valores: Array[int] = [100, 100, 50, 0, 0, 0]
var _foco: int = Item.MUSIC
var _aberta: bool = false
# Ultimo layout aplicado: a troca de modo recalcula as alturas (o item de Sensibilidade aparece/some).
var _tamanho: Vector2 = Vector2.ZERO
var _safe: Rect2 = Rect2()
var _layout_aplicado: bool = false
# Retangulo do bloco inteiro (titulo + itens) do ultimo layout; base do teste de safe area.
var _bloco: Rect2 = Rect2()
# index do dedo -> item em que o toque comecou (-1 = fundo)
var _toques: Dictionary = {}
var _pressionado: int = -1
# Valores aplicados no bus/Global durante o arrasto e ainda nao gravados no cfg (gravam ao soltar, ao fechar ou na saida
# do app). Uma flag por grupo: arrastar um volume so grava os volumes; arrastar a Sensibilidade so grava a sensibilidade.
# Sem estado por dedo: no multitoque, os volumes pendentes gravam juntos (`salvar_volumes` grava os dois).
var _pendente_volumes: bool = false
var _pendente_sensibilidade: bool = false


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
	_titulo = UiHelpers.novo_label(TEXTO_TITULO, TAMANHO_TITULO, CONTORNO_TITULO, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(_titulo)
	for i in TIPOS.size():
		var moldura := _novo_panel(UiHelpers.estilo_opcoes(Color(0, 0, 0, 0), 4, COR_CONTORNO, COR_BOTAO))
		add_child(moldura)
		_molduras.append(moldura)
		_botao_paineis.append(null)
		_botao_rotulos.append(null)
		if TIPOS[i] == Tipo.SLIDER:
			var nome := UiHelpers.novo_label(NOMES[i], TAMANHO_TEXTO, CONTORNO_TEXTO, HORIZONTAL_ALIGNMENT_LEFT)
			add_child(nome)
			_nomes.append(nome)
			var valor := UiHelpers.novo_label("", TAMANHO_TEXTO, CONTORNO_TEXTO, HORIZONTAL_ALIGNMENT_RIGHT)
			add_child(valor)
			_valores_lbl.append(valor)
			var tm := _novo_panel(UiHelpers.estilo_opcoes(COR_MOLDURA_TRILHA, 0, COR_CONTORNO, COR_BOTAO))
			add_child(tm)
			_trilhas_moldura.append(tm)
			var trilha := _novo_panel(UiHelpers.estilo_opcoes(COR_TRILHA, 0, COR_CONTORNO, COR_BOTAO))
			add_child(trilha)
			_trilhas.append(trilha)
			var fill := ColorRect.new()
			fill.color = COR_PREENCHIMENTO
			fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fill.focus_mode = Control.FOCUS_NONE
			add_child(fill)
			_preenchimentos.append(fill)
			var cursor := _novo_panel(UiHelpers.estilo_opcoes(COR_CURSOR, 2, COR_CONTORNO, COR_BOTAO))
			add_child(cursor)
			_cursores.append(cursor)
		else:
			var painel := _novo_panel(UiHelpers.estilo_opcoes(COR_BOTAO, 2, COR_CONTORNO, COR_BOTAO))
			add_child(painel)
			var rotulo := UiHelpers.novo_label(NOMES[i], TAMANHO_TEXTO, CONTORNO_TEXTO, HORIZONTAL_ALIGNMENT_CENTER)
			painel.add_child(rotulo)
			_botao_paineis[i] = painel
			_botao_rotulos[i] = rotulo
	_atualizar_visual()


# Saida do app com o gesto em andamento (janela fechada, app em segundo plano, foco perdido, cena destruida):
# grava o que o arrasto aplicou no bus. Sem pendencia nao faz nada.
func _notification(what: int) -> void:
	if (
		what == NOTIFICATION_WM_CLOSE_REQUEST
		or what == NOTIFICATION_APPLICATION_PAUSED
		or what == NOTIFICATION_APPLICATION_FOCUS_OUT
		or what == NOTIFICATION_EXIT_TREE
	):
		_persistir_pendente()


# Troca de modo por qualquer caminho (seletor da tela ou `?toque=`): mostra/oculta a Sensibilidade na hora.
# Mesmo padrao de `TouchControls.gd`: conecta ao entrar na arvore e solta o sinal do autoload ao sair.
func _enter_tree() -> void:
	if not Global.touch_mode_changed.is_connected(_modo_mudou):
		Global.touch_mode_changed.connect(_modo_mudou)


func _exit_tree() -> void:
	if Global.touch_mode_changed.is_connected(_modo_mudou):
		Global.touch_mode_changed.disconnect(_modo_mudou)


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
	_tamanho = visible_size
	_safe = safe
	_layout_aplicado = true
	var s_top := safe.position.y
	var s_bottom := visible_size.y - safe.end.y
	var util := visible_size.y - s_top - s_bottom
	var altura := _altura_bloco()
	var y0 := s_top + (util - altura) / 2.0
	_bloco = Rect2(0.0, y0, LARGURA, altura)
	var y := y0 + TITULO_ALTURA
	var topo_rotulos: Array[float] = []
	for i in TIPOS.size():
		# Item escondido nao ocupa linha nem espaco: o bloco dos 5 itens do B termina nos mesmos 520 px de antes.
		if not _visivel(i):
			_rects[i] = Rect2()
			continue
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
		_molduras[i].position = r.position - Vector2(2.0, 2.0)
		_molduras[i].size = r.size + Vector2(4.0, 4.0)
		if TIPOS[i] == Tipo.SLIDER:
			# O indice s acompanha os sliders (inclusive o escondido); so o visivel tem topo para posicionar.
			if _visivel(i):
				var linha := Rect2(SliderMath.X_MIN, topo_rotulos[s], SliderMath.LARGURA_TRILHA, ROTULO_ALTURA)
				_nomes[s].position = linha.position
				_nomes[s].size = linha.size
				_valores_lbl[s].position = linha.position
				_valores_lbl[s].size = linha.size
				var cy := r.position.y + r.size.y / 2.0
				_trilhas_moldura[s].position = Vector2(SliderMath.X_MIN - 2.0, cy - TRILHA_ALTURA / 2.0 - 2.0)
				_trilhas_moldura[s].size = Vector2(SliderMath.LARGURA_TRILHA + 4.0, TRILHA_ALTURA + 4.0)
				_trilhas[s].position = Vector2(SliderMath.X_MIN, cy - TRILHA_ALTURA / 2.0)
				_trilhas[s].size = Vector2(SliderMath.LARGURA_TRILHA, TRILHA_ALTURA)
			s += 1
		else:
			_botao_paineis[i].position = r.position
			_botao_paineis[i].size = r.size
			_botao_rotulos[i].size = r.size
	_atualizar_visual()


# Retangulo da area de toque do slider (0 = Music, 1 = SFX, 2 = Sensibilidade).
func rect_slider(canal: int) -> Rect2:
	return _rects[canal]


func rect_music() -> Rect2:
	return _rects[Item.MUSIC]


func rect_sfx() -> Rect2:
	return _rects[Item.SFX]


# Area de toque do slider de Sensibilidade (vazia com o modo Joy invisivel (B) ativo: o item nao aparece).
func rect_sensibilidade() -> Rect2:
	return _rects[Item.SENSIBILIDADE]


# Retangulo do bloco inteiro (titulo + itens visiveis) do ultimo layout.
func rect_bloco() -> Rect2:
	return _bloco


func rect_toque() -> Rect2:
	return _rects[Item.TOQUE]


# Texto do seletor de modo de toque sem o marcador de foco ("Toque: Flick").
func texto_toque() -> String:
	return _texto_item(Item.TOQUE)


func rect_ver_tutorial() -> Rect2:
	return _rects[Item.VER_TUTORIAL]


func rect_voltar() -> Rect2:
	return _rects[Item.VOLTAR]


# Item com foco (enum Item).
func foco_atual() -> int:
	return _foco


# Item desenhado agora (o slider de Sensibilidade so no modo Flick (A)).
func item_visivel(item: int) -> bool:
	if _nomes.is_empty():
		return _visivel(item)
	if TIPOS[item] == Tipo.SLIDER:
		return _nomes[_indice_slider(item)].visible
	return _botao_paineis[item].visible


# Valor 0-100 exibido no slider (0 = Music, 1 = SFX, 2 = Sensibilidade).
func valor_slider(canal: int) -> int:
	return _valores[canal]


func esta_aberta() -> bool:
	return _aberta


func abrir(foco: int = Item.MUSIC) -> void:
	_aberta = true
	_foco = foco if _visivel(foco) else _proximo_foco(foco, 1)
	_toques.clear()
	_pressionado = -1
	_pendente_volumes = false
	_pendente_sensibilidade = false
	_valores[Item.MUSIC] = roundi(Global.get_volume_music() * SliderMath.VALOR_MAX)
	_valores[Item.SFX] = roundi(Global.get_volume_sfx() * SliderMath.VALOR_MAX)
	_valores[Item.SENSIBILIDADE] = valor_da_sensibilidade(Global.get_touch_sensibilidade())
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
		if not _visivel(i):
			continue
		h += ESPACO_ANTES[i]
		h += SLIDER_ALTURA if TIPOS[i] == Tipo.SLIDER else BOTAO_ALTURA
	return h


# Item aparece na tela: o slider de Sensibilidade so com o modo Flick (A) ativo (decisao 2a do G1). Em Joy invisivel (B) o bloco volta a
# 520 px e a ordem de foco passa de SFX direto a Toque.
func _visivel(item: int) -> bool:
	return item != Item.SENSIBILIDADE or Global.get_touch_mode() == TouchMode.Modo.A


# Indice do slider do item nas listas de nos (ordem dos sliders em TIPOS, escondido inclusive).
func _indice_slider(item: int) -> int:
	var s := 0
	for i in item:
		if TIPOS[i] == Tipo.SLIDER:
			s += 1
	return s


# Proximo item visivel a partir do atual, no passo +1 (ui_down) ou -1 (ui_up).
func _proximo_foco(atual: int, passo: int) -> int:
	var i := atual
	for _n in TIPOS.size():
		i = (i + passo + TIPOS.size()) % TIPOS.size()
		if _visivel(i):
			return i
	return atual


# Foco preso num item escondido (trocar para B com foco em Sensibilidade): volta ao vizinho visivel de cima.
func _normalizar_foco() -> void:
	if _visivel(_foco):
		return
	_foco = _proximo_foco(_foco, -1)


# Troca de modo de toque (seletor da tela ou de fora): reaproveita o ultimo layout com a lista visivel nova.
func _modo_mudou(_modo: int) -> void:
	_normalizar_foco()
	if _layout_aplicado:
		aplicar_layout(_tamanho, _safe)
	else:
		_atualizar_visual()


# Valor 0-100 do slider de Sensibilidade -> multiplicador de TouchTuning. Geometrico: o padrao 1,0x fica no meio da
# trilha (0,5x * 2x = 1,0x * 1,0x) e cada passo anda a mesma razao de px nos dois sentidos.
static func sensibilidade_do_valor(valor: int) -> float:
	var t := float(clampi(valor, 0, SliderMath.VALOR_MAX)) / float(SliderMath.VALOR_MAX)
	return TouchTuning.sensibilidade_de_valor(
		TouchTuning.SENSIBILIDADE_MIN * pow(TouchTuning.SENSIBILIDADE_MAX / TouchTuning.SENSIBILIDADE_MIN, t)
	)


# Inverso do mapeamento: sensibilidade salva -> posicao 0-100 do slider (valor invalido cai no padrao).
static func valor_da_sensibilidade(sensibilidade: float) -> int:
	var s := TouchTuning.sensibilidade_de_valor(sensibilidade)
	var razao := TouchTuning.SENSIBILIDADE_MAX / TouchTuning.SENSIBILIDADE_MIN
	var t := log(s / TouchTuning.SENSIBILIDADE_MIN) / log(razao)
	return clampi(roundi(t * float(SliderMath.VALOR_MAX)), 0, SliderMath.VALOR_MAX)


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
		_foco = _proximo_foco(_foco, 1)
		_atualizar_visual()
		return true
	if event.is_action_pressed("ui_up"):
		_foco = _proximo_foco(_foco, -1)
		_atualizar_visual()
		return true
	if event.is_action_pressed("ui_accept"):
		if TIPOS[_foco] == Tipo.BOTAO:
			_acionar(_foco)
		return true
	return false


# Clique de mouse esquerdo real (nao emulado a partir do toque) tem a mesma arbitragem do toque. Botao direito e
# mouse emulado nao sao da tela: devolvem false (nao consumidos).
func _tratar_mouse(mouse: InputEventMouseButton) -> bool:
	if mouse.device == InputEvent.DEVICE_ID_EMULATION or mouse.button_index != MOUSE_BUTTON_LEFT:
		return false
	_tratar_ponteiro(UiHelpers.DEDO_MOUSE, mouse.pressed, mouse.position)
	return true


# Arrasto com o botao esquerdo apertado: so conta se o clique comecou na tela (mouse emulado nao e da tela).
func _tratar_movimento(mov: InputEventMouseMotion) -> bool:
	if mov.device == InputEvent.DEVICE_ID_EMULATION or not _toques.has(UiHelpers.DEDO_MOUSE):
		return false
	_arrastar(UiHelpers.DEDO_MOUSE, mov.position)
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
		_acionar(inicio)


func _acionar(item: int) -> void:
	if item == Item.VER_TUTORIAL:
		ver_tutorial.emit()
	elif item == Item.TOQUE:
		_alternar_modo_toque()
	else:
		voltar.emit()


# Alterna Flick <-> Joy invisivel (A <-> B): o Global grava no store e avisa (TouchControls cancela o gesto, TouchHint rearma a dica e o sinal
# `touch_mode_changed` refaz o layout daqui, mostrando/ocultando a Sensibilidade).
func _alternar_modo_toque() -> void:
	var proximo := (int(Global.get_touch_mode()) + 1) % TouchMode.NOMES.size()
	Global.set_touch_mode(proximo)


func _texto_item(item: int) -> String:
	if item == Item.TOQUE:
		return "%s: %s" % [NOMES[item], TouchMode.nome(Global.get_touch_mode())]
	return NOMES[item]


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


# Muda o valor do slider e aplica no Global (bus nos volumes, valor do A na sensibilidade); grava no cfg so com
# `persistir` (teclado). No arrasto fica pendente e grava ao soltar ou ao fechar. Sem mudanca nao faz nada.
func _definir_valor(item: int, valor: int, persistir: bool) -> void:
	if valor == _valores[item]:
		return
	_valores[item] = valor
	if item == Item.SENSIBILIDADE:
		Global.set_touch_sensibilidade(sensibilidade_do_valor(valor), persistir)
	elif item == Item.MUSIC:
		Global.set_volume_music(float(valor) / SliderMath.VALOR_MAX, persistir)
	else:
		Global.set_volume_sfx(float(valor) / SliderMath.VALOR_MAX, persistir)
	if not persistir:
		if item == Item.SENSIBILIDADE:
			_pendente_sensibilidade = true
		else:
			_pendente_volumes = true
	_atualizar_visual()


# Grava so o que ficou pendente no arrasto: os volumes (se algum mudou) e/ou a sensibilidade (se ela mudou).
func _persistir_pendente() -> void:
	if _pendente_volumes:
		_pendente_volumes = false
		Global.salvar_volumes()
	if _pendente_sensibilidade:
		_pendente_sensibilidade = false
		Global.salvar_sensibilidade()


func _atualizar_visual() -> void:
	if _molduras.is_empty():
		return
	var s := 0
	for i in TIPOS.size():
		var vis := _visivel(i)
		_molduras[i].visible = vis and _foco == i
		var r: Rect2 = _rects[i]
		if TIPOS[i] == Tipo.SLIDER:
			var arrastando := _toques.values().has(i)
			_nomes[s].visible = vis
			_valores_lbl[s].visible = vis
			_trilhas_moldura[s].visible = vis
			_trilhas[s].visible = vis
			_preenchimentos[s].visible = vis
			_cursores[s].visible = vis
			_nomes[s].text = ("> " if _foco == i else "") + NOMES[i]
			_valores_lbl[s].text = SliderMath.rotulo(_valores[i])
			var cx := SliderMath.x_do_valor(_valores[i])
			var cy := r.position.y + r.size.y / 2.0
			var tam := CURSOR_ARRASTANDO if arrastando else CURSOR_NORMAL
			_cursores[s].add_theme_stylebox_override("panel", UiHelpers.estilo_opcoes(COR_CURSOR, 4 if arrastando else 2, COR_CONTORNO, COR_BOTAO))
			_cursores[s].size = tam
			_cursores[s].position = Vector2(cx - tam.x / 2.0, cy - tam.y / 2.0)
			_preenchimentos[s].position = Vector2(SliderMath.X_MIN, cy - TRILHA_ALTURA / 2.0)
			_preenchimentos[s].size = Vector2(cx - SliderMath.X_MIN, TRILHA_ALTURA)
			s += 1
		else:
			var pressed: bool = _pressionado == i
			_botao_paineis[i].visible = vis
			_botao_paineis[i].add_theme_stylebox_override("panel", UiHelpers.estilo_opcoes(COR_BOTAO, 4 if pressed else 2, COR_CONTORNO, COR_BOTAO))
			_botao_rotulos[i].text = ("> " if _foco == i else "") + _texto_item(i)
			_botao_rotulos[i].position = Vector2(0.0, 2.0 if pressed else 0.0)


func _novo_panel(estilo: StyleBoxFlat) -> Panel:
	var p := Panel.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.focus_mode = Control.FOCUS_NONE
	p.add_theme_stylebox_override("panel", estilo)
	return p
