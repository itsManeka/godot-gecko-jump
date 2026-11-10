extends GutTest

# T1 (f412): regra de wrap do Player. wrap_x puro (C44), teleporte preserva velocity (C45) e
# sem partida/com end nao ha wrap (C46). Plataformas nao entram aqui (T3/T4).
const PLAYER := "res://scenes/Player.tscn"
const PLAYER_SCRIPT := preload("res://scenes/Player.gd")
const TICK := 1.0 / 60.0
var _p: Node

func before_each() -> void:
	Global.platforms = []
	Global.iniciado = true

func after_each() -> void:
	Input.action_release("ui_right")
	Input.action_release("ui_left")
	Global.platforms = []
	Global.iniciado = false

func _spawn(px: float, py: float) -> void:
	_p = add_child_autofree(load(PLAYER).instantiate())
	_p.position = Vector2(px, py)
	await wait_physics_frames(1)

# C44: limites estritos. x == width fica; x > width volta por width; x < 0 entra por width.
func test_wrap_x_limites_e_valores_exatos() -> void:
	assert_almost_eq(PLAYER_SCRIPT.wrap_x(180.5, 180.0), 0.5, 0.0001, "180.5 -> 0.5")
	assert_almost_eq(PLAYER_SCRIPT.wrap_x(-0.5, 180.0), 179.5, 0.0001, "-0.5 -> 179.5")
	assert_eq(PLAYER_SCRIPT.wrap_x(0.0, 180.0), 0.0, "0 fica (limite estrito)")
	assert_eq(PLAYER_SCRIPT.wrap_x(180.0, 180.0), 180.0, "180 fica (limite estrito)")
	assert_eq(PLAYER_SCRIPT.wrap_x(90.0, 180.0), 90.0, "meio da tela inalterado")

# C45: gecko caindo sem plataforma cruzando 180 com ui_right. Os ticks sao dirigidos aqui (engine
# nao processa o Player), entao cada leitura e exatamente um passo de fisica: antes do teleporte a
# queda avanca 1 GRAVITY por tick; no tick do teleporte o velocity.y segue a mesma queda (nao zera).
func test_teleporte_preserva_velocity_y() -> void:
	_p = add_child_autofree(load(PLAYER).instantiate())
	_p.set_physics_process(false)
	_p.position = Vector2(170.0, 100.0)
	await wait_physics_frames(1)
	Input.action_press("ui_right")
	var x_antes: float = _p.position.x
	var vy_antes: float = _p.velocity.y
	var teleportou := false
	var vy_teleporte: float = 0.0
	var vy_tick_anterior: float = 0.0
	for i in 60:
		_p._physics_process(TICK)
		var vy_agora: float = _p.velocity.y
		if not teleportou and _p.position.x < x_antes - 90.0:
			teleportou = true
			vy_teleporte = vy_agora
			vy_tick_anterior = vy_antes
		elif not teleportou:
			assert_eq(vy_agora - vy_antes, PLAYER_SCRIPT.GRAVITY, "queda avanca 1 GRAVITY por tick antes do teleporte")
		vy_antes = vy_agora
		x_antes = _p.position.x
	assert_true(teleportou, "gecko deve cruzar 180 e reaparecer perto de 0")
	assert_eq(vy_teleporte - vy_tick_anterior, PLAYER_SCRIPT.GRAVITY, "velocity.y no teleporte continua a queda (nao zerada)")

# C46: sem Global.iniciado, ou com end == true, o early return de _physics_process impede o wrap.
func test_sem_iniciado_ou_end_nao_faz_wrap() -> void:
	Global.iniciado = false
	await _spawn(200.0, 100.0)
	await wait_physics_frames(5)
	assert_eq(_p.position.x, 200.0, "sem partida iniciada, x=200 permanece")
	Global.iniciado = true
	_p.end = true
	Input.action_press("ui_right")
	await wait_physics_frames(5)
	assert_eq(_p.position.x, 200.0, "com end=true, x=200 permanece mesmo com input")

# T2 (f412): sprite fantasma "Ghost" (sem colisor). Player sem processo proprio: a sincronizacao e chamada
# direto (_process(0.0)), entao cada leitura e determinista.
func _spawn_quieto(px: float) -> void:
	_p = add_child_autofree(load(PLAYER).instantiate())
	_p.set_physics_process(false)
	_p.set_process(false)
	_p.position = Vector2(px, 100.0)

func _ghost() -> AnimatedSprite2D:
	return _p.get_node("Ghost") as AnimatedSprite2D

# C47: offset e visibilidade. x=10 -> fantasma em +180 (global 190); x=170 -> -180 (global -10); x=90 invisivel;
# bordas da meia largura (16 px): 16 nao cruza, 15.9 cruza; 164 nao cruza, 164.1 cruza.
func test_fantasma_offset_e_visibilidade_na_costura() -> void:
	_spawn_quieto(10.0)
	_p._process(0.0)
	var g := _ghost()
	assert_true(g.visible, "x=10 cruza a borda esquerda: fantasma visivel")
	assert_almost_eq(g.global_position.x, 190.0, 0.0001, "x=10 -> fantasma em x=190 (offset +180)")
	_p.position.x = 170.0
	_p._process(0.0)
	assert_true(g.visible, "x=170 cruza a borda direita: fantasma visivel")
	assert_almost_eq(g.global_position.x, -10.0, 0.0001, "x=170 -> fantasma em x=-10 (offset -180)")
	_p.position.x = 90.0
	_p._process(0.0)
	assert_false(g.visible, "x=90 longe das bordas: fantasma invisivel")
	for caso in [[16.0, false], [15.9, true], [164.0, false], [164.1, true]]:
		_p.position.x = caso[0]
		_p._process(0.0)
		assert_eq(g.visible, caso[1], "x=%s -> visivel=%s" % [caso[0], caso[1]])

# C48: espelha animation, frame, flip_h e modulate (inclusive apos set_color e na "lose"); nao avanca sozinho.
func test_fantasma_espelha_sprite_real() -> void:
	_spawn_quieto(10.0)
	var g := _ghost()
	assert_false(g.is_playing(), "fantasma nao toca: is_playing() == false")
	_p.sprite.animation = "run"
	_p.sprite.frame = 1
	_p.sprite.flip_h = true
	_p._process(0.0)
	assert_eq(g.animation, "run", "animacao espelhada")
	assert_eq(g.frame, 1, "frame espelhado")
	assert_true(g.flip_h, "flip_h espelhado")
	await wait_process_frames(10)
	assert_eq(g.frame, 1, "fantasma parado: nao avanca frames sozinho")
	var cores: Array = Enums.COLOR.values()
	var nova: int = cores[0] if cores[0] != Enums.COR_INICIAL else cores[1]
	var cor_antes := g.modulate
	_p.set_color(nova)
	_p._process(0.0)
	assert_eq(g.modulate, _p.sprite.modulate, "cor trocada por set_color espelhada")
	assert_ne(g.modulate, cor_antes, "a cor do fantasma mudou junto")
	_p.lose_game()
	_p._process(0.0)
	assert_eq(g.animation, "lose", "animacao lose espelhada")

# C49: Player invisivel (menu) esconde o fantasma mesmo com x na zona de costura.
func test_player_invisivel_esconde_fantasma() -> void:
	_spawn_quieto(10.0)
	_p._process(0.0)
	assert_true(_ghost().is_visible_in_tree(), "controle: Player visivel e x=10 -> fantasma visivel na arvore")
	_p.visible = false
	_p._process(0.0)
	assert_false(_ghost().is_visible_in_tree(), "Player invisivel: fantasma nao aparece na arvore")

# T3 (f412): wrap em fisica real com Platform.tscn (y=200, gecko pousado em y=180). Cada passo e um
# physics frame da engine; o teleporte e detectado por salto de x maior que metade da tela.
const PLATFORM := "res://scenes/Platform.tscn"
var _pl: Node

func _setup_plat(px: float, speed: float, gx: float, cor: int = Enums.COLOR.AMARELO) -> void:
	_pl = add_child_autofree(load(PLATFORM).instantiate())
	_pl.position = Vector2(px, 200)
	_pl.speed = speed
	_pl.color = cor
	_p = add_child_autofree(load(PLAYER).instantiate())
	_p.color = cor
	_p.position = Vector2(gx, 180)
	await wait_physics_frames(1)
	_pl.player_color_changed(cor)

# Roda n frames e devolve: fora (frames com x fora de [0,180]), teleportes, x e y logo apos o 1o
# teleporte, menor/maior x depois dele e y final.
func _trace(n: int, action: String = "") -> Dictionary:
	if action != "":
		Input.action_press(action)
	var r := {"fora": 0, "teleportes": 0, "x_tp": NAN, "y_tp": NAN, "min_pos": 1e9, "max_pos": -1e9, "y_fim": NAN}
	var x_ant: float = _p.position.x
	for i in n:
		await wait_physics_frames(1)
		var x: float = _p.position.x
		if x < 0.0 or x > 180.0:
			r["fora"] += 1
		if absf(x - x_ant) > 90.0:
			r["teleportes"] += 1
			if r["teleportes"] == 1:
				r["x_tp"] = x
				r["y_tp"] = _p.position.y
		if r["teleportes"] > 0:
			r["min_pos"] = minf(r["min_pos"], x)
			r["max_pos"] = maxf(r["max_pos"], x)
		x_ant = x
	r["y_fim"] = _p.position.y
	return r

# C50: ui_right segurado cruza 180 e reaparece perto de 0; x sempre em [0,180].
func test_wrap_direita_com_input() -> void:
	await _setup_plat(150.0, 0.0, 150.0)
	var r := await _trace(300, "ui_right")
	assert_eq(r["fora"], 0, "x nunca sai de [0,180]")
	assert_gt(r["teleportes"], 0, "gecko cruzou a borda direita")
	assert_lt(r["min_pos"], 20.0, "reaparece perto de 0")

# C51: ui_left segurado cruza 0 e reaparece perto de 180.
func test_wrap_esquerda_com_input() -> void:
	await _setup_plat(30.0, 0.0, 30.0)
	var r := await _trace(300, "ui_left")
	assert_eq(r["fora"], 0, "x nunca sai de [0,180]")
	assert_gt(r["teleportes"], 0, "gecko cruzou a borda esquerda")
	assert_gt(r["max_pos"], 160.0, "reaparece perto de 180")

# C52: sem input, plataforma arrasta o gecko para a direita; teleporta e cai.
func test_wrap_arrasto_plataforma_direita_sem_input() -> void:
	await _setup_plat(150.0, -60.0, 150.0)
	var r := await _trace(300)
	assert_eq(r["fora"], 0, "x nunca sai de [0,180]")
	assert_gt(r["teleportes"], 0, "arrasto cruzou a borda direita")
	assert_lt(r["x_tp"], 20.0, "reaparece perto de 0")
	assert_gt(r["y_fim"], r["y_tp"], "sem chao do outro lado, cai depois do teleporte")

# C53: sem input, plataforma arrasta o gecko para a esquerda; teleporta e cai.
func test_wrap_arrasto_plataforma_esquerda_sem_input() -> void:
	await _setup_plat(30.0, 60.0, 30.0)
	var r := await _trace(300)
	assert_eq(r["fora"], 0, "x nunca sai de [0,180]")
	assert_gt(r["teleportes"], 0, "arrasto cruzou a borda esquerda")
	assert_gt(r["x_tp"], 160.0, "reaparece perto de 180")
	assert_gt(r["y_fim"], r["y_tp"], "sem chao do outro lado, cai depois do teleporte")

# C54: controle, plataforma parada e sem input: x estavel em 90, sem teleporte.
func test_controle_plataforma_parada_sem_teleporte() -> void:
	await _setup_plat(90.0, 0.0, 90.0)
	var r := await _trace(120)
	assert_eq(r["teleportes"], 0, "nenhum teleporte espurio")
	assert_eq(r["fora"], 0, "x dentro de [0,180]")
	assert_almost_eq(_p.position.x, 90.0, 5.0, "x estavel perto de 90")
