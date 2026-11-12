extends GutTest

# Camada de entrada de toque (TouchControls): toque -> ui_left/ui_right/jump, lido pelo Player por polling.
# Relogio injetado (_t, ms) para o limiar tap x hold. Ticks fisicos dirigidos aqui (o motor pode rodar varios
# por frame): em cada tick a camada roda ANTES do Player (pior ordem) e a amostra guarda o menor/maior velocity.
const PLAYER := "res://scenes/Player.tscn"
const CONTROLS := preload("res://scenes/TouchControls.gd")
const TICK := 1.0 / 60.0
const ESQ := 20.0
const DIR := 160.0
const ACOES := ["ui_left", "ui_right", "jump"]
var _p: Node
var _c: Node
var _t: int = 0


func before_each() -> void:
	Global.platforms = []
	Global.iniciado = true
	_t = 0


func after_each() -> void:
	for a in ACOES:
		Input.action_release(a)
	Global.platforms = []
	Global.iniciado = false


func _spawn(buffer: int = -1) -> void:
	_c = CONTROLS.new()
	_c.relogio = func() -> int: return _t
	_c.largura_visivel_fixa = 180.0
	if buffer >= 0:
		_c.buffer_pulo_ms = buffer
	_p = load(PLAYER).instantiate()
	_c.player = _p
	_c.set_physics_process(false)
	_p.set_physics_process(false)
	add_child_autofree(_c)
	add_child_autofree(_p)
	_p.position = Vector2(90.0, 100.0)


# 1 tick fisico: camada, depois Player.
func _tick() -> void:
	_c._physics_process(TICK)
	_p._physics_process(TICK)


func _limpar() -> void:
	if is_instance_valid(_c):
		_c.free()
	if is_instance_valid(_p):
		_p.free()
	for a in ACOES:
		Input.action_release(a)


func _toque(x: float, pressed: bool, idx: int = 0, cancelado: bool = false) -> void:
	var e := InputEventScreenTouch.new()
	e.index = idx
	e.position = Vector2(x, 200.0)
	e.pressed = pressed
	e.canceled = cancelado
	_c._input(e)


func _mouse(x: float, pressed: bool, device: int) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.position = Vector2(x, 200.0)
	e.pressed = pressed
	e.device = device
	_c._input(e)


# Amostra velocity do Player apos cada um de n ticks: {min_x, max_x, min_y}.
func _amostra(n: int) -> Dictionary:
	var r := {"min_x": 0.0, "max_x": 0.0, "min_y": 0.0}
	for i in n:
		_tick()
		r["min_x"] = minf(r["min_x"], _p.velocity.x)
		r["max_x"] = maxf(r["max_x"], _p.velocity.x)
		r["min_y"] = minf(r["min_y"], _p.velocity.y)
	return r


func _tap(x: float) -> void:
	_p.on_ground = true
	_toque(x, true)
	_toque(x, false)


func _nenhuma_pressionada() -> bool:
	for a in ACOES:
		if Input.is_action_pressed(a):
			return false
	return true


func test_c151_tap_em_cada_metade_pula_para_o_lado_tocado() -> void:
	_spawn()
	_tap(ESQ)
	var e: Dictionary = _amostra(4)
	assert_lt(e["min_x"], 0.0, "tap na esquerda anda para a esquerda")
	assert_eq(e["max_x"], 0.0, "tap na esquerda nao vai para a direita")
	assert_lt(e["min_y"], 0.0, "tap na esquerda pula")
	_limpar()
	_t = 0
	_spawn()
	_tap(DIR)
	var d: Dictionary = _amostra(4)
	assert_gt(d["max_x"], 0.0, "tap na direita anda para a direita")
	assert_eq(d["min_x"], 0.0, "tap na direita nao vai para a esquerda")
	assert_lt(d["min_y"], 0.0, "tap na direita pula")


func test_c152_hold_anda_sem_pular_e_pulo_no_pressionar_pula() -> void:
	_spawn()
	_p.on_ground = true
	_toque(ESQ, true)
	_t = 250
	var h: Dictionary = _amostra(4)
	assert_lt(h["min_x"], 0.0, "hold alem do limiar anda para o lado")
	assert_gte(h["min_y"], 0.0, "hold (pulo ao soltar) nao pula")
	_limpar()
	_t = 0
	_spawn()
	_c.pulo_no_pressionar = true
	_p.on_ground = true
	_toque(ESQ, true)
	var p: Dictionary = _amostra(4)
	assert_lt(p["min_y"], 0.0, "com PULO_NO_PRESSIONAR o pulo sai no pressionar")
	assert_lt(p["min_x"], 0.0, "o pulo sai diagonal para o lado")


func test_c153_acao_fica_pressionada_ao_menos_um_physics_frame() -> void:
	_spawn()
	_tap(ESQ)
	assert_true(Input.is_action_pressed("ui_left"), "pressionada ao fim do tap")
	_tick()
	assert_true(Input.is_action_pressed("ui_left"), "ainda pressionada apos o 1o tick")
	assert_lt(_p.velocity.x, 0.0, "tap de duracao minima ainda move o Player")
	_amostra(4)
	assert_true(_nenhuma_pressionada(), "depois dos ticks a camada solta")


func test_c154_fim_de_toque_e_cancelamento_soltam_as_tres() -> void:
	_spawn()
	_tap(ESQ)
	_amostra(4)
	assert_true(_nenhuma_pressionada(), "fim do tap solta ui_left/ui_right/jump")
	_c.pulo_no_pressionar = true
	_toque(DIR, true)
	assert_true(Input.is_action_pressed("ui_right") and Input.is_action_pressed("jump"), "pressionou")
	_toque(DIR, false, 0, true)
	assert_false(Input.is_action_pressed("ui_left"), "cancelar solta ui_left")
	assert_false(Input.is_action_pressed("ui_right"), "cancelar solta ui_right")
	assert_false(Input.is_action_pressed("jump"), "cancelar solta jump")
	_toque(ESQ, true)
	_t = 250
	_amostra(3)
	assert_true(Input.is_action_pressed("ui_left"), "hold anda")
	_toque(ESQ, false)
	assert_true(_nenhuma_pressionada(), "fim do hold solta as tres")


func test_c155_exit_tree_solta_as_tres() -> void:
	_spawn()
	_c.pulo_no_pressionar = true
	_toque(ESQ, true)
	assert_true(Input.is_action_pressed("jump") and Input.is_action_pressed("ui_left"), "acoes presas")
	remove_child(_c)
	assert_true(_nenhuma_pressionada(), "sair da arvore solta ui_left/ui_right/jump")
	add_child(_c)


func test_c156_fora_de_partida_nao_pressiona() -> void:
	_spawn()
	Global.iniciado = false
	_p.on_ground = true
	_toque(ESQ, true)
	_toque(ESQ, false)
	_c.pulo_no_pressionar = true
	_toque(DIR, true)
	assert_true(_nenhuma_pressionada(), "started == false: nenhuma acao pressionada")
	_amostra(3)
	assert_true(_nenhuma_pressionada(), "segue sem acao")


func test_c157_camada_so_solta_o_que_pressionou() -> void:
	_spawn()
	Input.action_press("jump")
	_tap(ESQ)
	_amostra(4)
	assert_true(Input.is_action_pressed("jump"), "jump do teste continua apos o tap")
	_c.pulo_no_pressionar = true
	_toque(DIR, true)
	_toque(DIR, false, 0, true)
	assert_true(Input.is_action_pressed("jump"), "jump do teste continua apos o cancelamento")
	assert_false(Input.is_action_pressed("ui_right"), "a que a camada pressionou foi solta")


func test_c158_mouse_nao_aciona_nem_dobra_o_toque() -> void:
	_spawn()
	var gestos: Array = []
	_c.gesto_concluido.connect(func(resultado: int, _lado: int) -> void: gestos.append(resultado))
	_mouse(ESQ, true, 0)
	assert_true(_nenhuma_pressionada(), "mouse real nao aciona")
	_mouse(ESQ, false, 0)
	assert_eq(gestos.size(), 0, "mouse real nao gera gesto")
	_tap(ESQ)
	_mouse(ESQ, true, InputEvent.DEVICE_ID_EMULATION)
	_mouse(ESQ, false, InputEvent.DEVICE_ID_EMULATION)
	assert_eq(gestos.size(), 1, "toque + mouse emulado = 1 so tap")


func test_c159_tap_no_ar_segue_buffer() -> void:
	_spawn()
	_p.on_ground = false
	_toque(ESQ, true)
	_toque(ESQ, false)
	_amostra(4)
	_p.on_ground = true
	var sem: Dictionary = _amostra(3)
	assert_gte(sem["min_y"], 0.0, "BUFFER_PULO_MS = 0: tap no ar nao pula no pouso")
	_limpar()
	_t = 0
	_spawn(500)
	_p.on_ground = false
	_toque(ESQ, true)
	_toque(ESQ, false)
	_amostra(4)
	_p.on_ground = true
	var com: Dictionary = _amostra(3)
	assert_lt(com["min_y"], 0.0, "com buffer > 0 e pouso na janela, pula")


func test_c160_teclado_intacto_sem_toque() -> void:
	_spawn()
	_p.on_ground = true
	Input.action_press("ui_left")
	Input.action_press("jump")
	var e: Dictionary = _amostra(3)
	assert_lt(e["min_x"], 0.0, "ui_left direto move para a esquerda")
	assert_lt(e["min_y"], 0.0, "jump direto pula")
	assert_true(Input.is_action_pressed("ui_left"), "a camada inerte nao solta o teclado")


func test_c161_derrota_nao_pressiona() -> void:
	_spawn()
	_p.end = true
	_toque(ESQ, true)
	_toque(ESQ, false)
	assert_true(_nenhuma_pressionada(), "Player.is_end(): toque nao pressiona")
	_p.end = false
	_c.pulo_no_pressionar = true
	_toque(DIR, true)
	assert_true(Input.is_action_pressed("ui_right"), "controle: com o Player vivo pressiona")
	_p.end = true
	_tick()
	assert_true(_nenhuma_pressionada(), "derrota no meio do toque solta tudo")
