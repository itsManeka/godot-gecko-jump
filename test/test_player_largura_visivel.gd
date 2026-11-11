extends GutTest

# O Player usa a largura jogavel fixa (PlayArea.LARGURA = 180) no wrap e no fantasma, qualquer que seja a largura
# do viewport (janela larga ganha barras laterais, nao area de jogo). O Player vive num SubViewport de largura
# conhecida (180 ou 240), sem janela real.
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

# C139: viewport de 240: o wrap continua em 180 (x=250 -> 70, x=200 -> 20, x=-10 -> 170), nunca por 240.
func test_wrap_com_viewport_de_240_continua_em_180() -> void:
	_spawn(240, 100.0)
	assert_almost_eq(_wrap_apos_tick(250.0), 70.0, 0.5, "x=250 volta por 180")
	assert_almost_eq(_wrap_apos_tick(200.0), 20.0, 0.5, "x=200 (>180) tambem volta por 180")
	assert_almost_eq(_wrap_apos_tick(-10.0), 170.0, 0.5, "x=-10 entra por 180")

# C79: largura 180 mantem o comportamento da f412.
func test_largura_180_mantem_wrap_da_f412() -> void:
	_spawn(180, 100.0)
	assert_almost_eq(_wrap_apos_tick(200.0), 20.0, 0.5, "x=200 volta por 180")
	assert_almost_eq(_wrap_apos_tick(170.0), 170.0, 0.5, "x=170 permanece")

# C140: viewport de 240: a borda e o offset do fantasma sao de 180, nao de 240.
func test_fantasma_com_viewport_de_240_usa_borda_de_180() -> void:
	_spawn(240, 10.0)
	_p._process(0.0)
	var g := _p.get_node("Ghost") as AnimatedSprite2D
	assert_true(g.visible, "x=10: fantasma visivel")
	assert_almost_eq(g.global_position.x, 190.0, 0.0001, "x=10 -> fantasma em 190 (offset +180)")
	_p.position.x = 170.0
	_p._process(0.0)
	assert_true(g.visible, "x=170 (>154): fantasma visivel")
	assert_almost_eq(g.global_position.x, -10.0, 0.0001, "x=170 -> fantasma em -10 (offset -180)")
	_p.position.x = 100.0
	_p._process(0.0)
	assert_false(g.visible, "x=100 longe das bordas de 180: fantasma invisivel")

# C141: mudar o viewport de 180 para 240 em runtime (size_changed) nao altera o wrap.
func test_mudanca_de_largura_do_viewport_em_runtime_nao_altera_o_wrap() -> void:
	_spawn(180, 100.0)
	_sv.size = Vector2i(240, 320)
	await wait_process_frames(2)
	assert_almost_eq(_wrap_apos_tick(200.0), 20.0, 0.5, "x=200 ainda volta por 180 apos size_changed")
