extends GutTest

# T5 (f410): Player usa a largura visivel (VisibleArea) no wrap e no fantasma. O Player vive num SubViewport
# de largura conhecida (180 ou 240), sem janela real.
const PLAYER := "res://scenes/Player.tscn"
const TICK := 1.0 / 60.0
var _sv: SubViewport
var _p: Node

func before_each() -> void:
	Global.platforms = []
	Global.iniciado = true

func after_each() -> void:
	Global.platforms = []
	Global.iniciado = false

func _spawn(largura: int, px: float) -> void:
	_sv = SubViewport.new()
	_sv.size = Vector2i(largura, 320)
	add_child_autofree(_sv)
	_p = load(PLAYER).instantiate()
	_sv.add_child(_p)
	_p.set_physics_process(false)
	_p.set_process(false)
	_p.position = Vector2(px, 100.0)

func _wrap_apos_tick(px: float) -> float:
	_p.position.x = px
	_p._physics_process(TICK)
	return _p.position.x

# C77: largura 240: x=250 volta por 240 (-> ~10); x=200 (>180, <240) NAO faz wrap.
func test_wrap_usa_largura_240() -> void:
	_spawn(240, 100.0)
	assert_eq(_p.screen_width, 240.0, "screen_width lida do viewport de 240")
	assert_almost_eq(_wrap_apos_tick(250.0), 10.0, 0.5, "x=250 volta por 240")
	assert_almost_eq(_wrap_apos_tick(200.0), 200.0, 0.5, "x=200 (>180, <240) nao faz wrap")
	assert_almost_eq(_wrap_apos_tick(-10.0), 230.0, 0.5, "x=-10 entra por 240")

# C79: largura 180 mantem o comportamento da f412.
func test_largura_180_mantem_wrap_da_f412() -> void:
	_spawn(180, 100.0)
	assert_eq(_p.screen_width, 180.0, "screen_width = 180")
	assert_almost_eq(_wrap_apos_tick(200.0), 20.0, 0.5, "x=200 volta por 180")
	assert_almost_eq(_wrap_apos_tick(170.0), 170.0, 0.5, "x=170 permanece")

# C78: fantasma na borda de 240, nao de 180.
func test_fantasma_na_borda_de_240() -> void:
	_spawn(240, 10.0)
	_p._process(0.0)
	var g := _p.get_node("Ghost") as AnimatedSprite2D
	assert_true(g.visible, "x=10: fantasma visivel")
	assert_almost_eq(g.global_position.x, 250.0, 0.0001, "x=10 -> fantasma em 250 (offset +240)")
	_p.position.x = 230.0
	_p._process(0.0)
	assert_true(g.visible, "x=230 (>224): fantasma visivel")
	assert_almost_eq(g.global_position.x, -10.0, 0.0001, "x=230 -> fantasma em -10 (offset -240)")
	_p.position.x = 200.0
	_p._process(0.0)
	assert_false(g.visible, "x=200 longe da borda de 240: fantasma invisivel")

# C80: mudar a largura em runtime (size_changed) atualiza screen_width.
func test_mudanca_de_largura_em_runtime_atualiza_screen_width() -> void:
	_spawn(180, 100.0)
	assert_eq(_p.screen_width, 180.0, "comeca em 180")
	_sv.size = Vector2i(240, 320)
	await wait_process_frames(2)
	assert_eq(_p.screen_width, 240.0, "size_changed relê a largura")
