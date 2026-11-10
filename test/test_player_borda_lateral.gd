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
