class_name TouchControls
extends Node

# Camada de entrada de toque: traduz toques em ui_left/ui_right/jump sem tocar a fisica do Player (que le Input por
# polling). A regra de cada gesto vive no esquema do modo ativo (TouchScheme; modos A, B e C); aqui ficam so a posse
# das acoes (`_pressionadas`), o pulso de TICKS_MINIMOS e a inercia fora de partida.
# Inerte fora de partida em curso (Global.is_iniciado() e Player vivo). Quem instancia define `player`.

# D4: false = so toque; mouse (real e emulado a partir do toque) e ignorado.
const ACEITAR_MOUSE: bool = false

# Acao pressionada pela camada fica ao menos 1 tick fisico completo do Player. O no pode rodar antes do Player na
# arvore, entao o 1o tick da camada pode preceder o do Player: soltar so no 2o garante o tick inteiro.
const TICKS_MINIMOS: int = 2

const ACAO_ESQUERDA: String = "ui_left"
const ACAO_DIREITA: String = "ui_right"
const ACAO_PULO: String = "jump"

var player: Node = null
# Relogio em ms injetavel (teste); invalido = Time.get_ticks_msec().
var relogio: Callable = Callable()
# > 0 fixa a largura visivel usada pelo esquema; 0 = le do viewport a cada toque.
var largura_visivel_fixa: float = 0.0
var aceitar_mouse: bool = ACEITAR_MOUSE
# Zonas mortas do toque de jogo (botao de pausa, Pular do tutorial): valem em qualquer esquema (propaga ao ativo).
var zonas_mortas: Array[Rect2] = []:
	set(valor):
		zonas_mortas = valor
		if _esquema != null:
			_esquema.zonas_mortas = valor
# Callable(modo: int) -> TouchScheme que substitui TouchSchemes.criar (teste); invalido = a fabrica de producao.
var fabrica_esquema: Callable = Callable()

# Esquema do modo ativo (contrato TouchScheme); null = modo sem esquema, camada inerte.
var _esquema: TouchScheme = null
var _modo_ativo: int = -1

# Acoes que a camada pressionou (so estas ela solta).
var _pressionadas: Dictionary = {}
var _pulso_acoes: Array = []
var _pulso_ticks: int = 0


func _enter_tree() -> void:
	if not Global.touch_mode_changed.is_connected(_ao_trocar_modo):
		Global.touch_mode_changed.connect(_ao_trocar_modo)


func _input(event: InputEvent) -> void:
	_sincronizar_modo()
	if event is InputEventScreenDrag:
		var arrasto := event as InputEventScreenDrag
		_arrastou(arrasto.index, arrasto.position)
	elif event is InputEventScreenTouch:
		var toque := event as InputEventScreenTouch
		if toque.canceled:
			_cancelar(toque.index)
		elif toque.pressed:
			_pressionou(toque.index, toque.position)
		else:
			_soltou(toque.index)
	elif event is InputEventMouseButton and aceitar_mouse:
		var mouse := event as InputEventMouseButton
		if mouse.device == InputEvent.DEVICE_ID_EMULATION or mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse.pressed:
			_pressionou(UiHelpers.DEDO_MOUSE, mouse.position)
		else:
			_soltou(UiHelpers.DEDO_MOUSE)


func _physics_process(_delta: float) -> void:
	_sincronizar_modo()
	if not _em_curso():
		if not _pressionadas.is_empty() or gesto_ativo():
			_cancelar_tudo()
		return
	if _esquema != null:
		_aplicar_intencao()
	_avancar_pulso()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_cancelar_tudo()


func _exit_tree() -> void:
	if Global.touch_mode_changed.is_connected(_ao_trocar_modo):
		Global.touch_mode_changed.disconnect(_ao_trocar_modo)
	if _esquema != null:
		_esquema.cancelar_tudo()
	_soltar_tudo()  # saida da arvore


# true = ha dedo de jogo aceito e ainda na tela (o toque em zona morta nunca conta).
func gesto_ativo() -> bool:
	return _esquema != null and _esquema.ativo()


func _ao_trocar_modo(_modo: int) -> void:
	_sincronizar_modo()


# Segue o modo de Global: ao trocar, cancela o gesto (solta as acoes da camada) e recria o esquema do novo modo.
func _sincronizar_modo() -> void:
	var modo: int = Global.get_touch_mode()
	if modo == _modo_ativo:
		return
	_modo_ativo = modo
	_cancelar_tudo()  # troca de modo: solta o que o esquema anterior pressionou
	_esquema = fabrica_esquema.call(modo) if fabrica_esquema.is_valid() else TouchSchemes.criar(modo)
	if _esquema != null:
		_esquema.zonas_mortas = zonas_mortas


# Traduz a intencao do esquema em acoes: esquerda/direita seguem o nivel; `pulo` e evento e vira o pulso de
# TICKS_MINIMOS (nao repula enquanto o dedo segura). A posse (`_pressionadas`) e do `_pressionar`/`_soltar`.
func _aplicar_intencao() -> void:
	if _esquema == null:
		return
	var intencao: Dictionary = _esquema.intencao(_agora())
	_seguir_nivel(ACAO_ESQUERDA, bool(intencao.get("esquerda", false)))
	_seguir_nivel(ACAO_DIREITA, bool(intencao.get("direita", false)))
	if bool(intencao.get("pulo", false)):
		_pulsar([ACAO_PULO])


func _seguir_nivel(acao: String, ativa: bool) -> void:
	if ativa:
		_pressionar(acao)
	else:
		_soltar(acao)


func _arrastou(dedo: int, pos: Vector2) -> void:
	if _esquema == null or not _em_curso():
		return
	_esquema.mover(dedo, pos, _agora())
	_aplicar_intencao()


func _em_curso() -> bool:
	return Global.is_iniciado() and (player == null or not player.is_end())


func _agora() -> int:
	if relogio.is_valid():
		return int(relogio.call())
	return Time.get_ticks_msec()


func _pressionou(dedo: int, pos: Vector2) -> void:
	if _esquema == null or not _em_curso():
		return
	if largura_visivel_fixa > 0.0:
		_esquema.largura_visivel = largura_visivel_fixa
	else:
		_esquema.largura_visivel = get_viewport().get_visible_rect().size.x
	_esquema.press(dedo, _agora(), pos)
	_aplicar_intencao()


func _soltou(dedo: int) -> void:
	if _esquema == null:
		return
	_esquema.release(dedo, _agora())
	_aplicar_intencao()


func _cancelar(dedo: int) -> void:
	if _esquema == null:
		return
	_esquema.cancelar(dedo)
	_aplicar_intencao()


# Cancela o gesto em curso e solta as acoes da camada (pausa: o release durante a pausa nao chega aqui).
func cancelar_tudo() -> void:
	_cancelar_tudo()


func _cancelar_tudo() -> void:
	if _esquema != null:
		_esquema.cancelar_tudo()
	_soltar_tudo()


func _pulsar(acoes: Array) -> void:
	for a in acoes:
		_pressionar(a)
		if not _pulso_acoes.has(a):
			_pulso_acoes.append(a)
	_pulso_ticks = TICKS_MINIMOS


func _avancar_pulso() -> void:
	if _pulso_acoes.is_empty():
		return
	if _pulso_ticks > 0:
		_pulso_ticks -= 1
	if _pulso_ticks > 0:
		return
	for a in _pulso_acoes.duplicate():
		_soltar(a)
		_pulso_acoes.erase(a)


func _pressionar(acao: String) -> void:
	if _pressionadas.has(acao):
		return
	# Acao ja pressionada por outro (teclado, teste): nao assume a posse, entao nunca a solta.
	if Input.is_action_pressed(acao):
		return
	Input.action_press(acao)
	_pressionadas[acao] = true


func _soltar(acao: String) -> void:
	if not _pressionadas.has(acao):
		return
	Input.action_release(acao)
	_pressionadas.erase(acao)


func _soltar_tudo() -> void:
	for acao in _pressionadas.keys():
		_soltar(acao)
	_pulso_acoes.clear()
	_pulso_ticks = 0
