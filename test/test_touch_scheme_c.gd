extends GutTest

# T6 (f493): esquema C (metades + 2o toque) sobre TouchControls e Player reais, em ticks fisicos dirigidos.
# Viewport logico 180 px: metade em x = 90 (x == 90 e direita). Dedos em x fixo (y = 200): ESQ = 40, DIR = 140.
# Relogio injetado (_t, ms); a camada roda ANTES do Player em cada tick (pior ordem). Valores esperados vem da regra do
# 01 (Q4/Q5: janela de 80 ms, `<` janela = simultaneo), nunca da saida da implementacao.

const PLAYER := "res://scenes/Player.tscn"
const CONTROLS := preload("res://scenes/TouchControls.gd")
const TICK := 1.0 / 60.0
const ESQ := 40.0
const ESQ2 := 30.0
const DIR := 140.0
const DIR2 := 150.0
const ACOES := ["ui_left", "ui_right", "jump"]
const JANELA_MS: int = 80

var _p: Node
var _c: Node
var _t: int = 0
var _fisica_ticks: int = 60
var _escala_tempo: float = 1.0
var _modo_anterior: int = TouchMode.Modo.C


func before_each() -> void:
	_fisica_ticks = Engine.physics_ticks_per_second
	_escala_tempo = Engine.time_scale
	Engine.physics_ticks_per_second = 60
	Engine.time_scale = 1.0
	_modo_anterior = Global.get_touch_mode()
	Global.set_touch_mode(TouchMode.Modo.C, false)
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


func _tick() -> void:
	_c._physics_process(TICK)
	_p._physics_process(TICK)


func _toque(x: float, pressed: bool, idx: int, y: float = 200.0) -> void:
	var e := InputEventScreenTouch.new()
	e.index = idx
	e.position = Vector2(x, y)
	e.pressed = pressed
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


# Dois press em metades opostas: o 1o em x1, o 2o em x2 depois de `intervalo` ms. Devolve a amostra dos ticks seguintes.
func _dois_toques(x1: float, x2: float, intervalo: int) -> Dictionary:
	_toque(x1, true, 0)
	_t += intervalo
	_toque(x2, true, 1)
	return _amostra(6)


func test_c401_segurar_a_metade_anda_no_press_e_nao_pula() -> void:
	for x in [ESQ, DIR]:
		_spawn()
		var rotulo := "dedo em x=%s" % x
		_toque(x, true, 0)
		var a: Dictionary = _amostra(2)
		if x < 90.0:
			assert_lt(a["min_x"], 0.0, "%s: anda a esquerda em ate 2 ticks, sem atraso" % rotulo)
		else:
			assert_gt(a["max_x"], 0.0, "%s: anda a direita em ate 2 ticks, sem atraso" % rotulo)
		var b: Dictionary = _amostra(10)
		assert_eq(minf(a["min_y"], b["min_y"]), 0.0, "%s: segurar uma metade nao pula" % rotulo)
		assert_false(Input.is_action_pressed("jump"), "%s: jump nao e acionado" % rotulo)
		_c.free()
		_p.free()
		for ac in ACOES:
			Input.action_release(ac)


func test_c402_segundo_toque_em_qualquer_ponto_pula_na_direcao_do_hold() -> void:
	# Hold esquerdo: 2o toque na mesma metade, depois outro com hold direito e 2o toque na metade oposta.
	var casos: Array = [[ESQ, ESQ2, -1], [ESQ, DIR2, -1], [DIR, DIR2, 1], [DIR, ESQ2, 1]]
	for caso in casos:
		_spawn()
		var rotulo := "hold x=%s, 2o toque x=%s" % [caso[0], caso[1]]
		_toque(caso[0], true, 0)
		_amostra(1)
		_t += 200  # 200 ms de hold previo: nao e simultaneo
		_p.on_ground = true
		_toque(caso[1], true, 1)
		var a: Dictionary = _amostra(6)
		assert_lt(a["min_y"], 0.0, "%s: o 2o toque pula" % rotulo)
		if caso[2] < 0:
			assert_lt(a["min_x"], 0.0, "%s: velocity.x < 0 (diagonal para a esquerda)" % rotulo)
		else:
			assert_gt(a["max_x"], 0.0, "%s: velocity.x > 0 (diagonal para a direita)" % rotulo)
		_c.free()
		_p.free()
		for ac in ACOES:
			Input.action_release(ac)


func test_c403_duas_metades_opostas_dentro_da_janela_pulam_reto() -> void:
	for par in [[ESQ, DIR], [DIR, ESQ]]:
		_spawn()
		var rotulo := "1o x=%s, 2o x=%s, 40 ms" % [par[0], par[1]]
		var a: Dictionary = _dois_toques(par[0], par[1], 40)
		assert_lt(a["min_y"], 0.0, "%s: pula" % rotulo)
		assert_eq(a["min_x"], 0.0, "%s: sem lateral a esquerda no voo" % rotulo)
		assert_eq(a["max_x"], 0.0, "%s: sem lateral a direita no voo" % rotulo)
		assert_false(Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"), "%s: lateral do 1o cancelado" % rotulo)
		_c.free()
		_p.free()
		for ac in ACOES:
			Input.action_release(ac)


func test_c404_as_mesmas_metades_depois_da_janela_dao_hold_e_salto_na_direcao_do_primeiro() -> void:
	_spawn()
	var a: Dictionary = _dois_toques(ESQ, DIR, 200)
	assert_lt(a["min_y"], 0.0, "esquerda depois direita, 200 ms: pula")
	assert_lt(a["min_x"], 0.0, "esquerda depois direita, 200 ms: salta para a esquerda (direcao do 1o)")
	assert_eq(a["max_x"], 0.0, "esquerda depois direita, 200 ms: nao vai para a direita")
	_c.free()
	_p.free()
	for ac in ACOES:
		Input.action_release(ac)
	_spawn()
	var b: Dictionary = _dois_toques(DIR, ESQ, 200)
	assert_lt(b["min_y"], 0.0, "direita depois esquerda, 200 ms: pula")
	assert_gt(b["max_x"], 0.0, "direita depois esquerda, 200 ms: salta para a direita (direcao do 1o)")
	assert_eq(b["min_x"], 0.0, "direita depois esquerda, 200 ms: nao vai para a esquerda")


func test_c405_fronteira_da_janela_79_simultaneo_80_e_81_nao() -> void:
	_spawn()
	var a: Dictionary = _dois_toques(ESQ, DIR, JANELA_MS - 1)
	assert_lt(a["min_y"], 0.0, "79 ms: pula")
	assert_eq(a["min_x"], 0.0, "79 ms (< janela): simultaneo, pulo reto")
	_c.free()
	_p.free()
	for ac in ACOES:
		Input.action_release(ac)
	for intervalo in [JANELA_MS, JANELA_MS + 1]:
		_t = 0
		_spawn()
		var b: Dictionary = _dois_toques(ESQ, DIR, intervalo)
		assert_lt(b["min_y"], 0.0, "%d ms: pula" % intervalo)
		assert_lt(b["min_x"], 0.0, "%d ms (>= janela): nao e simultaneo, salta na direcao do 1o" % intervalo)
		_c.free()
		_p.free()
		for ac in ACOES:
			Input.action_release(ac)


func test_c406_soltar_o_hold_para_o_lateral_e_soltar_um_dedo_nao_reativa_o_outro() -> void:
	# Hold + salto: soltar o dedo que anda, no ar, para o lateral (o 2o dedo, apoiado, nao assume).
	_spawn()
	_toque(ESQ, true, 0)
	_amostra(1)
	_t += 200
	_toque(DIR, true, 1)
	_amostra(3)
	assert_true(Input.is_action_pressed("ui_left"), "pre-condicao: o hold segue andando")
	_toque(ESQ, false, 0)
	assert_false(Input.is_action_pressed("ui_left"), "soltar o hold solta ui_left")
	var a: Dictionary = _amostra(8)
	assert_eq(a["min_x"], 0.0, "soltar o hold no ar para o lateral")
	assert_false(Input.is_action_pressed("ui_right"), "o dedo que ficou nao passa a andar")
	_c.free()
	_p.free()
	for ac in ACOES:
		Input.action_release(ac)
	# Pulo reto: soltar um dos dois dedos nao faz o outro andar ate novo press (Q4).
	_t = 0
	_spawn()
	_dois_toques(ESQ, DIR, 40)
	_toque(ESQ, false, 0)
	var b: Dictionary = _amostra(8)
	assert_eq(b["min_x"], 0.0, "soltar o 1o dedo: o 2o nao anda a esquerda")
	assert_eq(b["max_x"], 0.0, "soltar o 1o dedo: o 2o nao anda a direita (ate novo press)")
	assert_false(Input.is_action_pressed("ui_right"), "soltar o 1o dedo: ui_right segue solto")
	_toque(ESQ2, true, 2)
	assert_true(Input.is_action_pressed("ui_left"), "novo press volta a andar")


func test_corr_c_terceiro_dedo_recusado_nao_fica_ativo() -> void:
	var esquema := TouchSchemeC.new()
	esquema.press(0, 0, Vector2(ESQ, 200.0))
	esquema.press(1, 200, Vector2(DIR, 200.0))
	esquema.press(2, 300, Vector2(ESQ2, 200.0))
	esquema.release(0, 400)
	esquema.release(1, 410)
	assert_false(esquema.tem_dedo(2), "o 3o dedo recusado pelo modo C nao fica registrado")
	assert_false(esquema.ativo(), "soltar os 2 dedos aceitos deixa o esquema inativo")


func test_c407_segundo_toque_em_zona_morta_nao_pula() -> void:
	_spawn()
	var mortas: Array[Rect2] = [Rect2(0.0, 0.0, 40.0, 40.0)]
	_c.zonas_mortas = mortas
	_toque(DIR, true, 0)
	_amostra(1)
	_t += 200
	_p.on_ground = true
	_toque(10.0, true, 1, 10.0)
	var a: Dictionary = _amostra(6)
	assert_eq(a["min_y"], 0.0, "2o toque na zona morta (pausa) nao pula")
	assert_true(Input.is_action_pressed("ui_right"), "o hold segue andando")
	# Controle: o mesmo 2o toque fora da zona pula.
	_p.on_ground = true
	_toque(ESQ2, true, 2, 200.0)
	var b: Dictionary = _amostra(6)
	assert_lt(b["min_y"], 0.0, "controle: fora da zona morta o 2o toque pula")
