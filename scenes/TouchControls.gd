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
# Com true, o lateral do pulo e so o pulso de TICKS_MINIMOS (sem o lateral sustentado ate o pouso do #44).
const PULO_NO_PRESSIONAR: bool = false
# D3: janela (ms) em que o jump segue pressionado depois do tap; 0 = so o minimo (tap no ar e perdido, como o teclado).
const BUFFER_PULO_MS: int = 0
# D4: false = so toque; mouse (real e emulado a partir do toque) e ignorado.
const ACEITAR_MOUSE: bool = false

# Acao pressionada pela camada fica ao menos 1 tick fisico completo do Player. O no pode rodar antes do Player na
# arvore, entao o 1o tick da camada pode preceder o do Player: soltar so no 2o garante o tick inteiro.
const TICKS_MINIMOS: int = 2

# Teto de seguranca do lateral do tap (ticks): tap que nunca decola (pulo descartado no ar) nao pode deixar a acao
# presa para sempre. ~120 ticks (2 s) = ~2,4x o voo do pulo (~50 ticks): o pouso normal solta muito antes.
const TICKS_TETO_LATERAL_TAP: int = 120

const ACAO_ESQUERDA: String = "ui_left"
const ACAO_DIREITA: String = "ui_right"
const ACAO_PULO: String = "jump"

var player: Node = null
var classificador: TouchClassifier = TouchClassifier.new()
# Relogio em ms injetavel (teste); invalido = Time.get_ticks_msec().
var relogio: Callable = Callable()
# > 0 fixa a largura visivel usada na classificacao; 0 = le do viewport a cada toque.
var largura_visivel_fixa: float = 0.0
var pulo_no_pressionar: bool = PULO_NO_PRESSIONAR
var buffer_pulo_ms: int = BUFFER_PULO_MS
var aceitar_mouse: bool = ACEITAR_MOUSE
# Zonas mortas do toque de jogo (botao de pausa, Pular do tutorial): ficam aqui e valem em qualquer esquema, inclusive
# o legado (propaga para o classificador) e o esquema do modo ativo.
var zonas_mortas: Array[Rect2] = []:
	set(valor):
		zonas_mortas = valor
		classificador.zonas_mortas = valor
		if _esquema != null:
			_esquema.zonas_mortas = valor
# Callable(modo: int) -> TouchScheme que substitui TouchSchemes.criar (teste); invalido = a fabrica de producao.
var fabrica_esquema: Callable = Callable()

# Esquema do modo ativo (contrato TouchScheme); null = esquema legado (tap/hold), provisorio ate a T9.
var _esquema: TouchScheme = null
var _modo_ativo: int = -1

# Acoes que a camada pressionou (so estas ela solta).
var _pressionadas: Dictionary = {}
var _pulso_acoes: Array = []
var _pulso_ticks: int = 0
var _jump_ate_ms: int = 0
var _dedo: int = -1
var _t_press_ms: int = 0
var _lado: int = TouchClassifier.Lado.NENHUM
var _andando: bool = false
# Lateral do tap sustentado ate o pouso: sai quando player.on_ground volta a true depois de ter decolado (flag
# `_lateral_tap_decolou`), no teto de seguranca ou em _soltar_tudo. `jump` NAO entra aqui (segue pulso).
var _lateral_tap: String = ""
var _lateral_tap_ticks: int = 0
var _lateral_tap_decolou: bool = false


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
	# Esquema legado: InputEventScreenDrag nao muda nada (o lado e decidido no pressionar).


func _physics_process(_delta: float) -> void:
	_sincronizar_modo()
	if not _em_curso():
		if _dedo != -1 or not _pressionadas.is_empty() or (_esquema != null and _esquema.ativo()):
			_cancelar_tudo()
		return
	if _esquema != null:
		_aplicar_intencao()
		_avancar_pulso()
		return
	if classificador.ativo() and not _andando and TouchClassifier.eh_hold(_agora() - _t_press_ms):
		_andando = true
		_soltar_lateral_tap()  # o hold assume o lateral: a posse do tap termina aqui
		_pressionar(_acao_do_lado(_lado))
	_avancar_pulso()
	_avancar_lateral_tap()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_cancelar_tudo()


func _exit_tree() -> void:
	if Global.touch_mode_changed.is_connected(_ao_trocar_modo):
		Global.touch_mode_changed.disconnect(_ao_trocar_modo)
	if _esquema != null:
		_esquema.cancelar_tudo()
	_soltar_tudo()  # saida da arvore


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
	if _esquema != null:
		_esquema.largura_visivel = classificador.largura_visivel
		_esquema.press(dedo, t, pos)
		_aplicar_intencao()
		return
	if not classificador.press(dedo, t, pos):
		return
	_dedo = dedo
	_t_press_ms = t
	_lado = TouchClassifier.lado_de(pos.x, classificador.largura_visivel)
	_andando = false
	if pulo_no_pressionar:
		_soltar_lateral_tap()
		_pulsar([_acao_do_lado(_lado), ACAO_PULO])


func _soltou(dedo: int) -> void:
	if _esquema != null:
		_esquema.release(dedo, _agora())
		_aplicar_intencao()
		return
	var r: Dictionary = classificador.release(dedo, _agora())
	if r["resultado"] == TouchClassifier.Resultado.IGNORADO:
		return
	var lado: int = r["lado"]
	if r["resultado"] == TouchClassifier.Resultado.TAP:
		if not pulo_no_pressionar:
			# Lateral sustentado ate o pouso; o pulo continua no pulso de TICKS_MINIMOS (sem repulo ao pousar).
			_sustentar_lateral_tap(lado)
			_pulsar([ACAO_PULO])
	elif r["resultado"] == TouchClassifier.Resultado.HOLD:
		_soltar_lateral_tap()  # o hold passa a ser o dono do lateral
		if _andando:
			_soltar(_acao_do_lado(lado))
		else:
			# Hold decidido no release sem tick no meio: ainda anda o minimo.
			_pulsar([_acao_do_lado(lado)])
	_dedo = -1
	_andando = false
	gesto_concluido.emit(r["resultado"], lado)


func _cancelar(dedo: int) -> void:
	if _esquema != null:
		_esquema.cancelar(dedo)
		_aplicar_intencao()
		return
	var r: Dictionary = classificador.cancelar(dedo)
	if r["resultado"] == TouchClassifier.Resultado.IGNORADO:
		return
	_soltar_tudo()  # cancelamento
	_dedo = -1
	_andando = false
	gesto_concluido.emit(r["resultado"], r["lado"])


# Cancela o gesto em curso e solta as acoes da camada (pausa: o release durante a pausa nao chega aqui).
func cancelar_tudo() -> void:
	_cancelar_tudo()


func _cancelar_tudo() -> void:
	if _esquema != null:
		_esquema.cancelar_tudo()
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


# Lateral do tap: pressiona no ato e o mantem ate o pouso. Novo tap no ar troca/estende o lado (Q2=b); o lado
# oposto e solto antes de assumir o novo.
func _sustentar_lateral_tap(lado: int) -> void:
	var acao: String = _acao_do_lado(lado)
	if _lateral_tap != "" and _lateral_tap != acao:
		_soltar(_lateral_tap)
	_pressionar(acao)
	_lateral_tap = acao
	_lateral_tap_ticks = 0
	_lateral_tap_decolou = false


# Solta o lateral do tap so depois de ter visto o Player sair do chao e voltar (on_ground false -> true), ou no teto.
func _avancar_lateral_tap() -> void:
	if _lateral_tap == "":
		return
	_lateral_tap_ticks += 1
	# player nulo ou sem on_ground (get -> null) cai no else: conta como decolado e so o teto solta o lateral.
	if player != null and player.get("on_ground") == true:
		if _lateral_tap_decolou:
			_soltar_lateral_tap()
			return
	else:
		_lateral_tap_decolou = true
	if _lateral_tap_ticks >= TICKS_TETO_LATERAL_TAP:
		_soltar_lateral_tap()


func _soltar_lateral_tap() -> void:
	if _lateral_tap != "":
		_soltar(_lateral_tap)
	_lateral_tap = ""
	_lateral_tap_ticks = 0
	_lateral_tap_decolou = false


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
	_soltar_lateral_tap()
	for acao in _pressionadas.keys():
		_soltar(acao)
	_pulso_acoes.clear()
	_pulso_ticks = 0
