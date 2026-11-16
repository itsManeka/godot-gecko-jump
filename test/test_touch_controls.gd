extends GutTest

# Camada de entrada de toque (TouchControls): toque -> ui_left/ui_right/jump, lido pelo Player por polling.
# Relogio injetado (_t, ms) para o limiar tap x hold. Ticks fisicos dirigidos aqui (o motor pode rodar varios
# por frame): em cada tick a camada roda ANTES do Player (pior ordem) e a amostra guarda o menor/maior velocity.
const PLAYER := "res://scenes/Player.tscn"
const PLAYER_SCRIPT := preload("res://scenes/Player.gd")
const CONTROLS := preload("res://scenes/TouchControls.gd")
const TICK := 1.0 / 60.0
const ESQ := 20.0
const DIR := 160.0
const ACOES := ["ui_left", "ui_right", "jump"]
var _p: Node
var _c: Node
var _t: int = 0
# move_and_slide usa o delta fisico do motor, nao o argumento de _physics_process: fixa em 1/60 para o voo medido
# bater com TICK (outra suite pode deixar Engine.time_scale/physics_ticks_per_second alterados).
var _fisica_ticks: int = 60
var _escala_tempo: float = 1.0


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


# move_and_slide usa o delta fisico (1/60) so quando roda dentro de um quadro fisico; fora dele usa o delta do
# quadro de render, que varia com a carga da suite. Retomar apos o sinal physics_frame faz o laco de ticks que segue
# (sincrono, sem outro await) rodar dentro do quadro fisico: o deslocamento deixa de depender da ordem da suite.
func _entrar_no_quadro_fisico() -> void:
	await wait_physics_frames(1)


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


# Deslocamento de x com o wrap horizontal do Player (Player.gd:126): o salto de uma borda a outra nao conta como
# deslocamento gigante.
func _delta_x(antes: float, depois: float) -> float:
	var d := depois - antes
	if d > PlayArea.LARGURA / 2.0:
		d -= PlayArea.LARGURA
	elif d < -PlayArea.LARGURA / 2.0:
		d += PlayArea.LARGURA
	return d


# Roda o voo INTEIRO (o pulo real: v0 = 250 px/s, gravidade 10/tick => ~50 ticks, Player.gd:8-9) e para quando o
# Player volta a altura de partida descendo. O pouso e simulado pelo chamador (`_p.on_ground = true`) e lido no
# tick seguinte da camada. Devolve {vxs, dx, ticks, impulsos, lado}.
func _medir_voo(max_ticks: int = 70) -> Dictionary:
	var r := {"vxs": [], "dx": 0.0, "ticks": 0, "impulsos": 0, "lado": 0}
	var y0: float = _p.position.y
	for i in max_ticks:
		var x_antes: float = _p.position.x
		_tick()
		r["vxs"].append(_p.velocity.x)
		r["dx"] += _delta_x(x_antes, _p.position.x)
		r["ticks"] = i + 1
		if _p.velocity.y <= PLAYER_SCRIPT.JUMP_POWER + PLAYER_SCRIPT.GRAVITY:
			r["impulsos"] += 1
		if i > 0 and _p.velocity.y >= 0.0 and _p.position.y >= y0:
			break
	return r


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
	_tick()  # decolou (on_ground false)
	_p.on_ground = true  # pouso simulado
	_tick()
	assert_true(_nenhuma_pressionada(), "depois do pouso a camada solta")


func test_c154_fim_de_toque_e_cancelamento_soltam_as_tres() -> void:
	_spawn()
	_tap(ESQ)
	_tick()  # impulso
	_tick()  # decolou (on_ground false)
	_p.on_ground = true  # pouso simulado
	_tick()
	assert_true(_nenhuma_pressionada(), "fim do tap (no pouso) solta ui_left/ui_right/jump")
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
	_medir_voo()
	_p.on_ground = true  # pouso simulado
	_tick()
	assert_true(Input.is_action_pressed("jump"), "jump do teste continua apos o pouso do tap")
	assert_false(Input.is_action_pressed("ui_left"), "o lateral do tap foi solto no pouso")
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
	assert_true(_nenhuma_pressionada(), "tap no ar solta o lateral no pouso")
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


# T1/T2 (issue #44): o lateral do tap sustenta o voo inteiro e `jump` continua pulso (Player pula por nivel, entao
# jump preso ate o pouso geraria um repulo automatico).
func test_c354_jump_nao_fica_preso_e_nao_repula_no_pouso() -> void:
	_spawn()
	_tap(ESQ)
	var voo: Dictionary = _medir_voo()
	assert_gt(voo["ticks"], 40, "voo inteiro medido (~50 ticks), nao 4")
	assert_eq(voo["impulsos"], 1, "so 1 impulso no voo inteiro")
	assert_false(Input.is_action_pressed("jump"), "apos TICKS_MINIMOS do tap, jump esta solto no voo")
	assert_true(Input.is_action_pressed("ui_left"), "pre-condicao: lateral ainda sustentado ao pousar")
	_p.on_ground = true
	_tick()
	if _p.velocity.y <= PLAYER_SCRIPT.JUMP_POWER + PLAYER_SCRIPT.GRAVITY:
		voo["impulsos"] += 1
	assert_eq(voo["impulsos"], 1, "pouso com o lateral sustentado nao repula (jump nao ficou preso)")


func test_c355_tap_direita_mantem_velocity_x_no_voo_inteiro() -> void:
	_spawn()
	await _entrar_no_quadro_fisico()
	_p.position = Vector2(60.0, 100.0)  # longe das bordas: sem wrap para confundir o sinal
	_tap(DIR)
	var voo: Dictionary = _medir_voo()
	assert_gt(voo["ticks"], 40, "voo inteiro medido (~50 ticks)")
	for i in voo["vxs"].size():
		assert_eq(voo["vxs"][i], float(PLAYER_SCRIPT.SPEED), "tick %d do voo: velocity.x == +SPEED" % i)
	var tempo_voo: float = voo["ticks"] * TICK
	var minimo: float = 0.8 * PLAYER_SCRIPT.SPEED * tempo_voo
	assert_gte(voo["dx"], minimo, "deslocamento direito >= 0,8 x (SPEED x tempo de voo) (%.1f px)" % minimo)
	assert_gt(voo["dx"], 0.0, "deslocamento positivo")


func test_c356_tap_esquerda_mantem_velocity_x_no_voo_inteiro() -> void:
	_spawn()
	await _entrar_no_quadro_fisico()
	_p.position = Vector2(120.0, 100.0)  # longe das bordas: sem wrap para confundir o sinal
	_tap(ESQ)
	var voo: Dictionary = _medir_voo()
	assert_gt(voo["ticks"], 40, "voo inteiro medido (~50 ticks)")
	for i in voo["vxs"].size():
		assert_eq(voo["vxs"][i], -float(PLAYER_SCRIPT.SPEED), "tick %d do voo: velocity.x == -SPEED" % i)
	var tempo_voo: float = voo["ticks"] * TICK
	var minimo: float = 0.8 * PLAYER_SCRIPT.SPEED * tempo_voo
	assert_lte(voo["dx"], -minimo, "deslocamento esquerdo <= -0,8 x (SPEED x tempo de voo) (%.1f px)" % minimo)
	assert_lt(voo["dx"], 0.0, "deslocamento negativo")


func test_c357_pouso_solta_o_lateral_e_zera_velocity_x() -> void:
	_spawn()
	_tap(ESQ)
	var voo: Dictionary = _medir_voo()
	assert_gt(voo["ticks"], 40, "pre-condicao: voou o voo inteiro")
	assert_true(Input.is_action_pressed("ui_left"), "pre-condicao: lateral ainda sustentado no fim do voo")
	_p.on_ground = true
	_tick()
	assert_true(_nenhuma_pressionada(), "no pouso nenhuma das tres acoes fica pressionada")
	assert_eq(_p.velocity.x, 0.0, "tick seguinte ao pouso: velocity.x == 0 (sem lateral residual)")


# Player.gd:108-112 recalcula on_ground por is_on_floor(): no 1o/2o tick do pulo ainda pode vir true. So conta pouso
# depois de ter visto on_ground == false (flag decolou).
func test_c358_pouso_lido_cedo_demais_nao_solta_o_lateral() -> void:
	_spawn()
	_tap(DIR)
	for i in 2:
		_tick()
		_p.on_ground = true  # cenario: Player ainda reporta on_ground true nos primeiros ticks
		assert_true(Input.is_action_pressed("ui_right"), "tick %d: lateral nao solta antes de ver on_ground == false" % i)
	_p.on_ground = false
	_tick()
	assert_true(Input.is_action_pressed("ui_right"), "decolou: lateral segue sustentado no voo")
	_p.on_ground = true
	_tick()
	assert_false(Input.is_action_pressed("ui_right"), "so depois de ver on_ground == false o pouso solta o lateral")


# Tap que nunca decola (pulo descartado, on_ground fica true): o teto de seguranca solta o lateral em
# TICKS_TETO_LATERAL_TAP e nao antes. O valor esperado vem da regra (~120 ticks = 2 s), nao da implementacao.
const TICKS_TETO_ESPERADO: int = 120


func test_c359_teto_de_seguranca_solta_o_lateral_que_nunca_decola() -> void:
	_spawn()
	_tap(ESQ)
	var teto: int = TICKS_TETO_ESPERADO
	var soltou_antes: bool = false
	for i in teto - 1:
		_tick()
		_p.on_ground = true  # nunca decola
		soltou_antes = soltou_antes or not Input.is_action_pressed("ui_left")
	assert_false(soltou_antes, "nao solta antes do teto (%d ticks)" % teto)
	assert_true(Input.is_action_pressed("ui_left"), "no tick %d o lateral segue" % (teto - 1))
	_tick()
	_p.on_ground = true
	assert_false(Input.is_action_pressed("ui_left"), "no teto (%d ticks) o lateral e solto" % teto)
