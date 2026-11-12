class_name TouchControls
extends Node

# Camada de entrada de toque de um polegar: traduz toques em ui_left/ui_right/jump sem tocar a fisica do Player
# (que le Input por polling). Tap (< limiar) = pulo diagonal para o lado tocado; hold = anda para o lado enquanto
# o dedo esta na tela. Classificacao (limiar, lado, multitoque) em TouchClassifier.
# Inerte fora de partida em curso (Global.is_iniciado() e Player vivo). Quem instancia define `player`.

# Disparado ao fim de cada gesto aceito: resultado = TouchClassifier.Resultado, lado = TouchClassifier.Lado.
signal gesto_concluido(resultado: int, lado: int)

# Decisoes do G1, cada uma em UM simbolo (a troca e de uma linha).
# D1b: false = pulo ao soltar (tap); true = pulo ao pressionar (e anda se passar do limiar).
const PULO_NO_PRESSIONAR: bool = false
# D3: janela (ms) em que o jump segue pressionado depois do tap; 0 = so o minimo (tap no ar e perdido, como o teclado).
const BUFFER_PULO_MS: int = 0
# D4: false = so toque; mouse (real e emulado a partir do toque) e ignorado.
const ACEITAR_MOUSE: bool = false

# Acao pressionada pela camada fica ao menos 1 tick fisico completo do Player. O no pode rodar antes do Player na
# arvore, entao o 1o tick da camada pode preceder o do Player: soltar so no 2o garante o tick inteiro.
const TICKS_MINIMOS: int = 2

const ACAO_ESQUERDA: String = "ui_left"
const ACAO_DIREITA: String = "ui_right"
const ACAO_PULO: String = "jump"
const DEDO_MOUSE: int = 1000

var player: Node = null
var classificador: TouchClassifier = TouchClassifier.new()
# Relogio em ms injetavel (teste); invalido = Time.get_ticks_msec().
var relogio: Callable = Callable()
# > 0 fixa a largura visivel usada na classificacao; 0 = le do viewport a cada toque.
var largura_visivel_fixa: float = 0.0
var pulo_no_pressionar: bool = PULO_NO_PRESSIONAR
var buffer_pulo_ms: int = BUFFER_PULO_MS
var aceitar_mouse: bool = ACEITAR_MOUSE

# Acoes que a camada pressionou (so estas ela solta).
var _pressionadas: Dictionary = {}
var _pulso_acoes: Array = []
var _pulso_ticks: int = 0
var _jump_ate_ms: int = 0
var _dedo: int = -1
var _t_press_ms: int = 0
var _lado: int = TouchClassifier.Lado.NENHUM
var _andando: bool = false


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
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
			_pressionou(DEDO_MOUSE, mouse.position)
		else:
			_soltou(DEDO_MOUSE)
	# InputEventScreenDrag nao muda nada: o lado e decidido no pressionar.


func _physics_process(_delta: float) -> void:
	if not _em_curso():
		if _dedo != -1 or not _pressionadas.is_empty():
			_cancelar_tudo()
		return
	if classificador.ativo() and not _andando and TouchClassifier.eh_hold(_agora() - _t_press_ms):
		_andando = true
		_pressionar(_acao_do_lado(_lado))
	_avancar_pulso()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_cancelar_tudo()


func _exit_tree() -> void:
	_soltar_tudo()  # saida da arvore


func _em_curso() -> bool:
	return Global.is_iniciado() and (player == null or not player.is_end())


func _agora() -> int:
	if relogio.is_valid():
		return int(relogio.call())
	return Time.get_ticks_msec()


func _acao_do_lado(lado: int) -> String:
	return ACAO_ESQUERDA if lado == TouchClassifier.Lado.ESQUERDA else ACAO_DIREITA


func _pressionou(dedo: int, pos: Vector2) -> void:
	if not _em_curso():
		return
	if largura_visivel_fixa > 0.0:
		classificador.largura_visivel = largura_visivel_fixa
	else:
		classificador.largura_visivel = get_viewport().get_visible_rect().size.x
	var t: int = _agora()
	if not classificador.press(dedo, t, pos):
		return
	_dedo = dedo
	_t_press_ms = t
	_lado = TouchClassifier.lado_de(pos.x, classificador.largura_visivel)
	_andando = false
	if pulo_no_pressionar:
		_pulsar([_acao_do_lado(_lado), ACAO_PULO])


func _soltou(dedo: int) -> void:
	var r: Dictionary = classificador.release(dedo, _agora())
	if r["resultado"] == TouchClassifier.Resultado.IGNORADO:
		return
	var lado: int = r["lado"]
	if r["resultado"] == TouchClassifier.Resultado.TAP:
		if not pulo_no_pressionar:
			_pulsar([_acao_do_lado(lado), ACAO_PULO])
	elif r["resultado"] == TouchClassifier.Resultado.HOLD:
		if _andando:
			_soltar(_acao_do_lado(lado))
		else:
			# Hold decidido no release sem tick no meio: ainda anda o minimo.
			_pulsar([_acao_do_lado(lado)])
	_dedo = -1
	_andando = false
	gesto_concluido.emit(r["resultado"], lado)


func _cancelar(dedo: int) -> void:
	var r: Dictionary = classificador.cancelar(dedo)
	if r["resultado"] == TouchClassifier.Resultado.IGNORADO:
		return
	_soltar_tudo()  # cancelamento
	_dedo = -1
	_andando = false
	gesto_concluido.emit(r["resultado"], r["lado"])


func _cancelar_tudo() -> void:
	if _dedo != -1:
		_cancelar(_dedo)
	_soltar_tudo()
	_dedo = -1
	_andando = false


func _pulsar(acoes: Array) -> void:
	for a in acoes:
		_pressionar(a)
		if not _pulso_acoes.has(a):
			_pulso_acoes.append(a)
		if a == ACAO_PULO:
			_jump_ate_ms = _agora() + buffer_pulo_ms
	_pulso_ticks = TICKS_MINIMOS


func _avancar_pulso() -> void:
	if _pulso_acoes.is_empty():
		return
	if _pulso_ticks > 0:
		_pulso_ticks -= 1
	if _pulso_ticks > 0:
		return
	for a in _pulso_acoes.duplicate():
		if a == ACAO_PULO and _agora() < _jump_ate_ms:
			continue
		if a != ACAO_PULO and _andando and a == _acao_do_lado(_lado):
			# O hold assumiu esta acao: nao solta no fim do pulso.
			_pulso_acoes.erase(a)
			continue
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
