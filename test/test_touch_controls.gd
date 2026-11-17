extends GutTest

# Camada de entrada de toque (TouchControls): intencao do esquema -> ui_left/ui_right/jump, lido pelo Player por
# polling. A regra de cada modo (A, B, C) e provada em test_touch_scheme_{a,b,c}.gd e test_touch_controls_modos.gd; aqui
# a camada e provada com um esquema falso (metade esquerda = esquerda, direita = direita, pulo a cada press), para a
# posse das acoes, o pulso de TICKS_MINIMOS, a inercia fora de partida e as zonas mortas nao dependerem de um modo.
# Ticks fisicos dirigidos aqui: em cada tick a camada roda ANTES do Player (pior ordem).
const PLAYER := "res://scenes/Player.tscn"
const CONTROLS := preload("res://scenes/TouchControls.gd")
const TICK := 1.0 / 60.0
const ESQ := 20.0
const DIR := 160.0
const ACOES := ["ui_left", "ui_right", "jump"]
var _p: Node
var _c: Node
var _esq: FakeEsquema
var _t: int = 0
# move_and_slide usa o delta fisico do motor, nao o argumento de _physics_process: fixa em 1/60 para a amostra bater
# com TICK (outra suite pode deixar Engine.time_scale/physics_ticks_per_second alterados).
var _fisica_ticks: int = 60
var _escala_tempo: float = 1.0


# Esquema falso: o dedo na metade esquerda/direita liga o nivel do lado; todo press pede 1 pulo (evento).
class FakeEsquema:
	extends TouchScheme
	var esq: bool = false
	var dir: bool = false
	var pulo_pendente: bool = false

	func _ao_pressionar(_dedo: int, _t_ms: int, pos: Vector2) -> void:
		esq = pos.x < largura_visivel / 2.0
		dir = not esq
		pulo_pendente = true

	func _ao_soltar(_dedo: int, _t_ms: int) -> void:
		esq = false
		dir = false

	func _ao_cancelar(_dedo: int) -> void:
		esq = false
		dir = false

	func _ao_cancelar_tudo() -> void:
		esq = false
		dir = false
		pulo_pendente = false

	func _intencao(_t_ms: int) -> Dictionary:
		var pulo: bool = pulo_pendente
		pulo_pendente = false
		return {"esquerda": esq, "direita": dir, "pulo": pulo}


func before_each() -> void:
	_fisica_ticks = Engine.physics_ticks_per_second
	_escala_tempo = Engine.time_scale
	Engine.physics_ticks_per_second = 60
	Engine.time_scale = 1.0
	Global.platforms = []
	Global.iniciado = true
	_t = 0


func after_each() -> void:
	for a in ACOES:
		Input.action_release(a)
	Global.platforms = []
	Global.iniciado = false
	Engine.physics_ticks_per_second = _fisica_ticks
	Engine.time_scale = _escala_tempo


func _criar_fake(_modo: int) -> TouchScheme:
	_esq = FakeEsquema.new()
	return _esq


func _spawn() -> void:
	_c = CONTROLS.new()
	_c.relogio = func() -> int: return _t
	_c.largura_visivel_fixa = 180.0
	_c.fabrica_esquema = _criar_fake
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


func _nenhuma_pressionada() -> bool:
	for a in ACOES:
		if Input.is_action_pressed(a):
			return false
	return true


func test_c151_dedo_em_cada_metade_move_o_player_para_o_lado_com_pulo() -> void:
	_spawn()
	_p.on_ground = true
	_toque(ESQ, true)
	var e: Dictionary = _amostra(4)
	assert_lt(e["min_x"], 0.0, "intencao esquerda anda para a esquerda")
	assert_eq(e["max_x"], 0.0, "intencao esquerda nao vai para a direita")
	assert_lt(e["min_y"], 0.0, "o pulo da intencao pula")
	_toque(ESQ, false)
	_c.free()
	_p.free()
	_t = 0
	_spawn()
	_p.on_ground = true
	_toque(DIR, true)
	var d: Dictionary = _amostra(4)
	assert_gt(d["max_x"], 0.0, "intencao direita anda para a direita")
	assert_eq(d["min_x"], 0.0, "intencao direita nao vai para a esquerda")
	assert_lt(d["min_y"], 0.0, "o pulo da intencao pula")


func test_c153_pulo_fica_pressionado_ao_menos_um_physics_frame_e_solta_no_pulso() -> void:
	_spawn()
	_p.on_ground = true
	_toque(ESQ, true)
	assert_true(Input.is_action_pressed("jump"), "pressionada no press")
	_tick()
	assert_true(Input.is_action_pressed("jump"), "ainda pressionada apos o 1o tick (TICKS_MINIMOS = 2)")
	assert_lt(_p.velocity.y, 0.0, "o tick do Player viu o jump pressionado")
	_tick()
	assert_false(Input.is_action_pressed("jump"), "o pulso termina no 2o tick: nunca fica preso")
	assert_true(Input.is_action_pressed("ui_left"), "o lateral e nivel: segue com o dedo na tela")


func test_c154_soltar_e_cancelar_o_dedo_soltam_o_lateral_e_o_pulso_termina() -> void:
	_spawn()
	_toque(ESQ, true)
	assert_true(Input.is_action_pressed("ui_left"), "pre-condicao: lateral pressionado")
	_toque(ESQ, false)
	assert_false(Input.is_action_pressed("ui_left"), "soltar o dedo solta o lateral")
	_tick()
	_tick()
	assert_true(_nenhuma_pressionada(), "depois do pulso nenhuma das tres fica pressionada")
	_toque(DIR, true)
	assert_true(Input.is_action_pressed("ui_right"), "pressionou")
	_toque(DIR, false, 0, true)
	assert_false(Input.is_action_pressed("ui_right"), "cancelar solta ui_right")
	_tick()
	_tick()
	assert_true(_nenhuma_pressionada(), "depois do cancelamento e do pulso nenhuma acao fica presa")


func test_c155_exit_tree_solta_as_tres() -> void:
	_spawn()
	_toque(ESQ, true)
	assert_true(Input.is_action_pressed("jump") and Input.is_action_pressed("ui_left"), "acoes presas")
	remove_child(_c)
	assert_true(_nenhuma_pressionada(), "sair da arvore solta ui_left/ui_right/jump")
	add_child(_c)


func test_c156_fora_de_partida_nao_pressiona_e_nao_ativa_gesto() -> void:
	_spawn()
	Global.iniciado = false
	_p.on_ground = true
	_toque(ESQ, true)
	_toque(ESQ, false)
	_toque(DIR, true)
	assert_true(_nenhuma_pressionada(), "started == false: nenhuma acao pressionada")
	assert_false(_c.gesto_ativo(), "fora de partida o toque nao vira gesto")
	_amostra(3)
	assert_true(_nenhuma_pressionada(), "segue sem acao")


func test_c157_camada_so_solta_o_que_pressionou() -> void:
	_spawn()
	Input.action_press("jump")  # acao do teclado/teste, fora da camada
	_toque(DIR, true)
	assert_false(_esq.pulo_pendente, "pre-condicao: o pulo do press foi consumido")
	assert_true(Input.is_action_pressed("ui_right"), "o lateral da camada foi pressionado")
	_toque(DIR, false, 0, true)
	_tick()
	_tick()
	assert_true(Input.is_action_pressed("jump"), "jump do teste continua apos o pulso e o cancelamento")
	assert_false(Input.is_action_pressed("ui_right"), "a que a camada pressionou foi solta")


func test_c158_mouse_real_nao_aciona_e_mouse_emulado_nao_dobra_o_toque() -> void:
	_spawn()
	_mouse(ESQ, true, 0)
	assert_true(_nenhuma_pressionada(), "mouse real nao aciona (ACEITAR_MOUSE = false)")
	assert_false(_c.gesto_ativo(), "mouse real nao gera gesto")
	_mouse(ESQ, false, 0)
	_c.aceitar_mouse = true
	_toque(ESQ, true)
	_mouse(DIR, true, InputEvent.DEVICE_ID_EMULATION)
	_mouse(DIR, false, InputEvent.DEVICE_ID_EMULATION)
	assert_true(Input.is_action_pressed("ui_left"), "o dedo segue ativo: o mouse emulado nao o soltou")
	assert_false(Input.is_action_pressed("ui_right"), "mouse emulado a partir do toque e ignorado")
	_toque(ESQ, false)
	_mouse(DIR, true, 0)
	assert_true(Input.is_action_pressed("ui_right"), "com aceitar_mouse o mouse real aciona")
	_mouse(DIR, false, 0)
	assert_false(Input.is_action_pressed("ui_right"), "soltar o mouse solta o lateral")


func test_c160_teclado_intacto_sem_toque() -> void:
	_spawn()
	_p.on_ground = true
	Input.action_press("ui_left")
	Input.action_press("jump")
	var e: Dictionary = _amostra(3)
	assert_lt(e["min_x"], 0.0, "ui_left direto move para a esquerda")
	assert_lt(e["min_y"], 0.0, "jump direto pula")
	assert_true(Input.is_action_pressed("ui_left"), "a camada inerte nao solta o teclado")


func test_c161_derrota_nao_pressiona_e_solta_o_que_estava_preso() -> void:
	_spawn()
	_p.end = true
	_toque(ESQ, true)
	_toque(ESQ, false)
	assert_true(_nenhuma_pressionada(), "Player.is_end(): toque nao pressiona")
	_p.end = false
	_toque(DIR, true)
	assert_true(Input.is_action_pressed("ui_right"), "controle: com o Player vivo pressiona")
	_p.end = true
	_tick()
	assert_true(_nenhuma_pressionada(), "derrota no meio do toque solta tudo")
	assert_false(_c.gesto_ativo(), "derrota cancela o gesto em curso")
	for i in 3:
		_tick()
		assert_true(_nenhuma_pressionada(), "tick %d apos a derrota: sem acao residual" % i)


func test_c363_cancelar_tudo_solta_lateral_e_jump_sem_residual() -> void:
	_spawn()
	_toque(ESQ, true)
	assert_true(Input.is_action_pressed("ui_left"), "pre-condicao: lateral pressionado")
	assert_true(Input.is_action_pressed("jump"), "pre-condicao: jump no pulso")
	_c.cancelar_tudo()
	assert_true(_nenhuma_pressionada(), "cancelar_tudo solta lateral e jump")
	assert_false(_c.gesto_ativo(), "cancelar_tudo encerra o gesto")
	for i in 5:
		_tick()
		assert_true(_nenhuma_pressionada(), "tick %d apos o resume: sem acao residual" % i)
	assert_eq(_p.velocity.x, 0.0, "sem movimento residual apos o resume")


func test_c365_teclado_ja_pressionado_nao_e_assumido_nem_soltado() -> void:
	_spawn()
	Input.action_press("ui_right")  # teclado externo, fora da camada
	_toque(DIR, true)
	assert_true(Input.is_action_pressed("ui_right"), "a camada nao assume a acao do teclado")
	_toque(DIR, false)
	_tick()
	_tick()
	assert_true(Input.is_action_pressed("ui_right"), "soltar o dedo nao solta a acao do teclado")
	_c._soltar_tudo()
	assert_true(Input.is_action_pressed("ui_right"), "ui_right continua apos _soltar_tudo (nao e da camada)")


func test_zona_morta_ignora_o_dedo_e_lista_vazia_aceita_o_mesmo_ponto() -> void:
	_spawn()
	var mortas: Array[Rect2] = [Rect2(0.0, 150.0, 60.0, 100.0)]
	_c.zonas_mortas = mortas
	_toque(ESQ, true)
	assert_true(_nenhuma_pressionada(), "toque em zona morta nao vira acao")
	assert_false(_c.gesto_ativo(), "toque em zona morta nao ativa dedo")
	_toque(ESQ, false)
	_toque(DIR, true)
	assert_true(Input.is_action_pressed("ui_right"), "fora da zona morta o toque e de jogo")
	_toque(DIR, false)
	_tick()
	_tick()
	var vazia: Array[Rect2] = []
	_c.zonas_mortas = vazia  # com o esquema ja criado: a troca propaga
	_toque(ESQ, true)
	assert_true(Input.is_action_pressed("ui_left"), "lista vazia aceita o mesmo ponto")
	assert_true(_c.gesto_ativo(), "o dedo vale como gesto")
