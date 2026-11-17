extends GutTest

# T4 (f493): esquema A (arrastar + flick) dirigindo o Player real por ticks via TouchControls. Valores esperados vem
# da regra do 01 (Q5: zona morta 6 px, flick dy >= 24 px em 150 ms, pulso de 2 ticks) e de Player.SPEED, nunca da saida.
# Relogio injetado (_t, ms); cada evento recebe o tempo explicito.

const PLAYER := "res://scenes/Player.tscn"
const PLAYER_SCRIPT := preload("res://scenes/Player.gd")
const CONTROLS := preload("res://scenes/TouchControls.gd")
const TICK := 1.0 / 60.0
const ACOES := ["ui_left", "ui_right", "jump"]
const X0 := 90.0
const Y0 := 200.0
const TICKS_VOO := 20

var _p: Node
var _c: Node
var _t: int = 0
var _modo_anterior: int = TouchMode.Modo.A
var _fisica_ticks: int = 60
var _escala_tempo: float = 1.0


func before_each() -> void:
	_fisica_ticks = Engine.physics_ticks_per_second
	_escala_tempo = Engine.time_scale
	Engine.physics_ticks_per_second = 60
	Engine.time_scale = 1.0
	_modo_anterior = Global.get_touch_mode()
	Global.platforms = []
	Global.iniciado = true
	_t = 0


func after_each() -> void:
	for a in ACOES:
		Input.action_release(a)
	Global.platforms = []
	Global.iniciado = false
	Global.set_touch_mode(_modo_anterior, false)
	Engine.physics_ticks_per_second = _fisica_ticks
	Engine.time_scale = _escala_tempo


func _spawn() -> void:
	Global.set_touch_mode(TouchMode.Modo.A, false)
	_c = CONTROLS.new()
	_c.relogio = func() -> int: return _t
	_c.largura_visivel_fixa = 180.0
	_c.fabrica_esquema = func(_m: int) -> TouchScheme: return TouchSchemeA.new()
	_p = load(PLAYER).instantiate()
	_c.player = _p
	_c.set_physics_process(false)
	_p.set_physics_process(false)
	add_child_autofree(_c)
	add_child_autofree(_p)
	_p.position = Vector2(90.0, 100.0)
	_p.on_ground = true
	_c._sincronizar_modo()


# move_and_slide usa o delta fisico so dentro de um quadro fisico: retomar apos o sinal fixa o laco de ticks nele.
func _entrar_no_quadro_fisico() -> void:
	await wait_physics_frames(1)


func _tick() -> void:
	_c._physics_process(TICK)
	_p._physics_process(TICK)


func _ticks(n: int) -> void:
	for i in n:
		_tick()


func _toque(x: float, y: float, pressed: bool, idx: int = 0, cancelado: bool = false) -> void:
	var e := InputEventScreenTouch.new()
	e.index = idx
	e.position = Vector2(x, y)
	e.pressed = pressed
	e.canceled = cancelado
	_c._input(e)


func _arrasto(x: float, y: float, t_ms: int, idx: int = 0) -> void:
	_t = t_ms
	var e := InputEventScreenDrag.new()
	e.index = idx
	e.position = Vector2(x, y)
	_c._input(e)


# Voo medido: amostra velocity.x de cada tick e conta os ticks com o impulso do pulo.
func _voo(n: int) -> Dictionary:
	var r := {"vxs": [], "impulsos": 0}
	for i in n:
		_tick()
		r["vxs"].append(_p.velocity.x)
		if _p.velocity.y <= PLAYER_SCRIPT.JUMP_POWER + PLAYER_SCRIPT.GRAVITY:
			r["impulsos"] += 1
	return r


func _nenhuma_pressionada() -> bool:
	for a in ACOES:
		if Input.is_action_pressed(a):
			return false
	return true


func test_c384_dedo_parado_dentro_da_zona_morta_sem_lateral_e_sem_pulo() -> void:
	await _entrar_no_quadro_fisico()
	_spawn()
	_toque(X0, Y0, true)
	var pulou: bool = false
	for deslocamento in [0.0, 3.0, -4.0, 5.0, -5.0]:
		_arrasto(X0 + deslocamento, Y0, _t + 10)
		_tick()
		pulou = pulou or Input.is_action_pressed("jump")
		assert_eq(_p.velocity.x, 0.0, "dedo a %+.0f px do contato (< 6): sem lateral" % deslocamento)
		assert_false(Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"), "dedo a %+.0f px: nenhuma acao lateral" % deslocamento)
	_ticks(5)
	assert_false(pulou, "dedo parado nao pede pulo")
	assert_eq(_p.velocity.x, 0.0, "tap seco (Q3): sem lateral depois de varios ticks")
	_toque(X0, Y0, false)
	_ticks(3)
	assert_eq(_p.velocity.x, 0.0, "tap seco solto: nada mudou")
	assert_true(_nenhuma_pressionada(), "tap seco: nenhuma acao")


func test_c385_arrasto_a_direita_anda_a_direita() -> void:
	await _entrar_no_quadro_fisico()
	_spawn()
	_toque(X0, Y0, true)
	_arrasto(X0 + 20.0, Y0, 10)
	_ticks(3)
	assert_gt(_p.velocity.x, 0.0, "arrasto de 20 px (> 6) a direita: velocity.x > 0")
	assert_eq(_p.velocity.x, float(PLAYER_SCRIPT.SPEED), "anda na velocidade do teclado (Player.SPEED)")


func test_c386_arrasto_a_esquerda_anda_a_esquerda() -> void:
	await _entrar_no_quadro_fisico()
	_spawn()
	_toque(X0, Y0, true)
	_arrasto(X0 - 20.0, Y0, 10)
	_ticks(3)
	assert_lt(_p.velocity.x, 0.0, "arrasto de 20 px (> 6) a esquerda: velocity.x < 0")
	assert_eq(_p.velocity.x, -float(PLAYER_SCRIPT.SPEED), "anda na velocidade do teclado (Player.SPEED)")


func test_c387_ancora_acompanha_o_dedo_e_a_volta_inverte_o_lado_sem_passar_pelo_inicio() -> void:
	await _entrar_no_quadro_fisico()
	_spawn()
	_toque(X0, Y0, true)
	_arrasto(X0 + 20.0, Y0, 10)
	_arrasto(X0 + 40.0, Y0, 20)
	_ticks(2)
	assert_gt(_p.velocity.x, 0.0, "pre-condicao: 40 px a direita anda a direita")
	_arrasto(X0 + 32.0, Y0, 30)
	_ticks(2)
	assert_lt(_p.velocity.x, 0.0, "voltar 8 px (> 6) inverte para a esquerda, com o dedo ainda 32 px a direita do contato")
	assert_gt(X0 + 32.0, X0, "o dedo nao passou pelo ponto inicial")


func test_c388_flick_com_dedo_na_zona_morta_pula_reto() -> void:
	await _entrar_no_quadro_fisico()
	_spawn()
	_toque(X0, Y0, true)
	_arrasto(X0, Y0 - 30.0, 100)  # dy = 30 >= 24 em 100 ms <= 150
	var voo: Dictionary = _voo(TICKS_VOO)
	assert_gt(voo["impulsos"], 0, "o flick pediu o pulo")
	for i in voo["vxs"].size():
		assert_eq(voo["vxs"][i], 0.0, "tick %d do voo: velocity.x == 0 (reto)" % i)


func test_c389_flick_com_dedo_deslocado_pula_na_diagonal_do_lado_do_dedo() -> void:
	await _entrar_no_quadro_fisico()
	_spawn()
	_toque(X0, Y0, true)
	_arrasto(X0 + 20.0, Y0, 10)
	_arrasto(X0 + 20.0, Y0 - 30.0, 100)
	var direita: Dictionary = _voo(TICKS_VOO)
	assert_gt(direita["impulsos"], 0, "flick a direita pediu o pulo")
	for i in direita["vxs"].size():
		assert_eq(direita["vxs"][i], float(PLAYER_SCRIPT.SPEED), "direita, tick %d: velocity.x == +SPEED" % i)
	_toque(X0, Y0, false)
	_limpar_voo()
	_t = 1000
	_toque(X0, Y0, true)
	_arrasto(X0 - 20.0, Y0, 1010)
	_arrasto(X0 - 20.0, Y0 - 30.0, 1100)
	var esquerda: Dictionary = _voo(TICKS_VOO)
	assert_gt(esquerda["impulsos"], 0, "flick a esquerda pediu o pulo")
	for i in esquerda["vxs"].size():
		assert_eq(esquerda["vxs"][i], -float(PLAYER_SCRIPT.SPEED), "esquerda, tick %d: velocity.x == -SPEED" % i)


# Pouso simulado entre dois gestos do mesmo teste: volta ao chao e solta as acoes.
func _limpar_voo() -> void:
	_p.position = Vector2(90.0, 100.0)
	_p.velocity = Vector2.ZERO
	_p.on_ground = true
	_ticks(3)
	_p.position = Vector2(90.0, 100.0)
	_p.velocity = Vector2.ZERO
	_p.on_ground = true


func test_c390_arrasto_vertical_lento_nao_pula() -> void:
	await _entrar_no_quadro_fisico()
	_spawn()
	_toque(X0, Y0, true)
	_arrasto(X0, Y0 - 20.0, 100)  # dy = 20 < 24 mesmo dentro da janela
	var curto: Dictionary = _voo(5)
	assert_eq(curto["impulsos"], 0, "dy < 24 px nao pula")
	assert_false(Input.is_action_pressed("jump"), "dy < 24 px: jump livre")
	_toque(X0, Y0, false)
	_toque(X0, Y0, true)
	var y: float = Y0
	var t: int = 1000
	_t = t
	for i in 8:  # dy total 32 >= 24, mas 4 px a cada 100 ms: nunca 24 px dentro de 150 ms
		y -= 4.0
		t += 100
		_arrasto(X0, y, t)
	var lento: Dictionary = _voo(5)
	assert_eq(lento["impulsos"], 0, "dy >= 24 px em > 150 ms nao pula")
	assert_false(Input.is_action_pressed("jump"), "arrasto lento: jump livre")


func test_c391_segundo_flick_repula_so_apos_novo_pulso() -> void:
	await _entrar_no_quadro_fisico()
	_spawn()
	_toque(X0, Y0, true)
	_arrasto(X0, Y0 - 30.0, 100)
	assert_true(Input.is_action_pressed("jump"), "1o flick: pulso de jump")
	_ticks(2)
	_ticks(1)
	assert_false(Input.is_action_pressed("jump"), "jump solto entre os dois flicks (nao fica preso)")
	_arrasto(X0, Y0 - 60.0, 200)  # novo dy = 30 em 100 ms
	assert_true(Input.is_action_pressed("jump"), "2o flick no mesmo toque: novo pulso")
	_ticks(3)
	assert_false(Input.is_action_pressed("jump"), "e o 2o pulso tambem solta")


func test_c392_correcao_de_direcao_no_ar_muda_velocity_x() -> void:
	await _entrar_no_quadro_fisico()
	_spawn()
	_toque(X0, Y0, true)
	_arrasto(X0 + 20.0, Y0, 10)
	_arrasto(X0 + 20.0, Y0 - 30.0, 100)
	_ticks(8)
	assert_lt(_p.velocity.y, 0.0, "pre-condicao: no ar, subindo")
	assert_eq(_p.velocity.x, float(PLAYER_SCRIPT.SPEED), "pre-condicao: diagonal a direita")
	_arrasto(X0 + 8.0, Y0 - 30.0, 200)  # volta 12 px (> 6) para a esquerda
	_ticks(2)
	assert_eq(_p.velocity.x, -float(PLAYER_SCRIPT.SPEED), "arrastar para o lado oposto no voo inverte velocity.x")


func test_c393_soltar_o_dedo_ou_canceled_para_o_lateral_e_solta_jump() -> void:
	await _entrar_no_quadro_fisico()
	_spawn()
	_toque(X0, Y0, true)
	_arrasto(X0 + 20.0, Y0, 10)
	_arrasto(X0 + 20.0, Y0 - 30.0, 100)
	assert_true(Input.is_action_pressed("ui_right"), "pre-condicao (soltar): lateral ativo")
	assert_true(Input.is_action_pressed("jump"), "pre-condicao (soltar): jump no pulso")
	_toque(X0 + 20.0, Y0 - 30.0, false)
	assert_false(Input.is_action_pressed("ui_right"), "soltar o dedo solta o lateral na hora")
	_ticks(2)  # o pulso de jump dura TICKS_MINIMOS (2) e termina sozinho
	assert_false(Input.is_action_pressed("jump"), "soltar o dedo: jump solto ao fim do pulso, sem repulso")
	_ticks(3)
	assert_true(_nenhuma_pressionada(), "sem residual depois de soltar")
	_t = 1000
	_toque(X0, Y0, true)
	_arrasto(X0 - 20.0, Y0, 1010)
	_arrasto(X0 - 20.0, Y0 - 30.0, 1100)
	assert_true(Input.is_action_pressed("ui_left"), "pre-condicao (canceled): lateral ativo")
	assert_true(Input.is_action_pressed("jump"), "pre-condicao (canceled): jump no pulso")
	_toque(X0 - 20.0, Y0 - 30.0, false, 0, true)
	assert_false(Input.is_action_pressed("ui_left"), "canceled solta o lateral na hora")
	_ticks(2)
	assert_false(Input.is_action_pressed("jump"), "canceled: jump solto ao fim do pulso, sem repulso")
	_ticks(3)
	assert_true(_nenhuma_pressionada(), "sem residual depois do canceled")
