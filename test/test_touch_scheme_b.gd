extends GutTest

# T5 (f493): esquema B (dois polegares) pela TouchControls real em modo B, com o Player por ticks (camada antes do
# Player, pior ordem). Esperado vem da regra do 01 (zona morta 6 px, metade esquerda dirige, metade direita pula no
# press, x == metade = direita), nunca da saida da implementacao.

const PLAYER := "res://scenes/Player.tscn"
const CONTROLS := preload("res://scenes/TouchControls.gd")
const TICK := 1.0 / 60.0
const ACOES := ["ui_left", "ui_right", "jump"]
const ESQ := 20.0
const DIR := 160.0
const METADE := 90.0

var _p: Node
var _c: Node
var _t: int = 0
var _modo_anterior: int = TouchMode.Modo.C
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
	Global.set_touch_mode(TouchMode.Modo.B, false)
	_t = 0
	_c = CONTROLS.new()
	_c.relogio = func() -> int: return _t
	_c.largura_visivel_fixa = 180.0
	_p = load(PLAYER).instantiate()
	_c.player = _p
	_c.set_physics_process(false)
	_p.set_physics_process(false)
	add_child_autofree(_c)
	add_child_autofree(_p)
	_p.position = Vector2(90.0, 100.0)
	_p.on_ground = true


func after_each() -> void:
	for a in ACOES:
		Input.action_release(a)
	Global.platforms = []
	Global.iniciado = false
	Global.set_touch_mode(_modo_anterior, false)
	Engine.physics_ticks_per_second = _fisica_ticks
	Engine.time_scale = _escala_tempo


func _tick() -> void:
	_c._physics_process(TICK)
	_p._physics_process(TICK)


func _toque(x: float, pressed: bool, idx: int, y: float = 200.0) -> void:
	var e := InputEventScreenTouch.new()
	e.index = idx
	e.position = Vector2(x, y)
	e.pressed = pressed
	_c._input(e)


func _arrasto(x: float, idx: int, y: float = 200.0) -> void:
	var e := InputEventScreenDrag.new()
	e.index = idx
	e.position = Vector2(x, y)
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


func test_c394_so_o_dedo_esquerdo_deslocado_anda_sem_pular() -> void:
	_toque(ESQ, true, 0)
	_arrasto(ESQ + 20.0, 0)
	var r := _amostra(10)
	assert_gt(r["max_x"], 0.0, "dedo esquerdo deslocado a direita anda para a direita")
	assert_eq(r["min_y"], 0.0, "sem dedo na metade direita nao ha pulo")
	assert_false(Input.is_action_pressed("jump"), "jump nunca pressionado")


func test_c395_so_o_dedo_direito_pula_reto_sem_limiar_de_tempo() -> void:
	_toque(DIR, true, 0)  # relogio parado: nenhum ms decorrido
	assert_true(Input.is_action_pressed("jump"), "o press ja pede o pulso, sem esperar tempo")
	var r := _amostra(10)
	assert_lt(r["min_y"], 0.0, "o Player decolou")
	assert_eq(r["min_x"], 0.0, "pulo reto: sem lateral para a esquerda")
	assert_eq(r["max_x"], 0.0, "pulo reto: sem lateral para a direita")


func test_c396_os_dois_dedos_dao_diagonal_e_o_esquerdo_corrige_no_ar() -> void:
	_toque(ESQ, true, 0)
	_arrasto(ESQ + 20.0, 0)
	_toque(DIR, true, 1)
	var r := _amostra(6)
	assert_lt(r["min_y"], 0.0, "decolou")
	assert_gt(r["max_x"], 0.0, "diagonal para o lado do dedo esquerdo (direita)")
	assert_eq(r["min_x"], 0.0, "sem lateral oposto")
	_p.on_ground = false
	_arrasto(ESQ, 0)  # volta 20 px a partir da ancora que seguiu o dedo
	_tick()
	_tick()
	assert_lt(_p.velocity.x, 0.0, "trocar so o esquerdo no ar corrige a direcao")


func test_c397_soltar_o_direito_nao_para_o_lateral_e_soltar_o_esquerdo_para() -> void:
	_toque(ESQ, true, 0)
	_arrasto(ESQ + 20.0, 0)
	_toque(DIR, true, 1)
	_amostra(4)
	_p.on_ground = false
	_toque(DIR, false, 1)
	_amostra(4)
	assert_true(Input.is_action_pressed("ui_right"), "soltar o direito mantem ui_right")
	assert_gt(_p.velocity.x, 0.0, "o lateral segue no ar")
	_toque(ESQ + 20.0, false, 0)
	_tick()
	_tick()
	assert_false(Input.is_action_pressed("ui_right"), "soltar o esquerdo solta ui_right")
	assert_eq(_p.velocity.x, 0.0, "o lateral para")


func test_c398_terceiro_dedo_e_ignorado_e_a_vaga_livre_volta_a_valer() -> void:
	_toque(ESQ, true, 0)
	_toque(DIR, true, 1)
	for i in 3:
		_tick()
	assert_false(Input.is_action_pressed("jump"), "pre-condicao: pulso do 1o press acabou")
	_toque(DIR + 10.0, true, 2)
	assert_false(Input.is_action_pressed("jump"), "3o dedo na metade direita nao pula")
	_toque(ESQ + 5.0, true, 3)
	_arrasto(ESQ + 50.0, 3)
	_tick()
	assert_false(Input.is_action_pressed("ui_right"), "3o dedo na metade esquerda nao dirige")
	_toque(DIR + 10.0, false, 2)
	_toque(DIR, false, 1)
	_toque(DIR, true, 4)
	assert_true(Input.is_action_pressed("jump"), "com a vaga livre o proximo press volta a valer")


func test_c399_lado_decidido_no_press_e_fixo_e_metade_exata_conta_como_direita() -> void:
	_toque(METADE - 10.0, true, 0)
	_arrasto(METADE + 20.0, 0)  # cruza a metade: continua dirigindo
	_tick()
	assert_true(Input.is_action_pressed("ui_right"), "dedo que nasceu a esquerda segue dirigindo alem de x = 90")
	assert_false(Input.is_action_pressed("jump"), "cruzar a metade nao pula")
	_toque(METADE + 20.0, false, 0)
	_tick()
	_tick()
	for a in ACOES:
		Input.action_release(a)
	_toque(METADE, true, 1)  # x == largura/2 e direita: pulso de pulo, nao dirige
	assert_true(Input.is_action_pressed("jump"), "press com x == 90 conta como direita (pula)")
	_arrasto(ESQ, 1)  # dedo da direita nunca dirige, mesmo arrastado para a esquerda
	_tick()
	assert_false(Input.is_action_pressed("ui_left"), "dedo que nasceu a direita nao dirige")


func test_c400_zona_morta_e_relativa_ao_ponto_de_contato() -> void:
	_toque(60.0, true, 0)
	_arrasto(66.0, 0)  # 6 px do contato: dentro da zona morta
	_tick()
	assert_false(Input.is_action_pressed("ui_right"), "6 px nao sai da zona morta")
	assert_false(Input.is_action_pressed("ui_left"), "6 px nao sai da zona morta (esquerda)")
	_arrasto(67.0, 0)  # 7 px do contato
	_tick()
	assert_true(Input.is_action_pressed("ui_right"), "7 px do contato anda para a direita")
