extends GutTest

# O Player usa a largura jogavel fixa (PlayArea.LARGURA = 360) no wrap e no fantasma, qualquer que seja a largura
# do viewport (janela larga ganha barras laterais, nao area de jogo). O Player vive num SubViewport de largura
# conhecida (360 ou 480), sem janela real. Meia largura visual do gecko = 32 (frame 64x64 a escala 1).
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
	_sv.size = Vector2i(largura, 640)
	add_child_autofree(_sv)
	_p = load(PLAYER).instantiate()
	_sv.add_child(_p)
	_p.set_physics_process(false)
	_p.set_process(false)
	_p.position = Vector2(px, 200.0)

func _wrap_apos_tick(px: float) -> float:
	_p.position.x = px
	_p._physics_process(TICK)
	return _p.position.x

# C139: viewport de 480: o wrap continua em 360 (x=500 -> 140, x=400 -> 40, x=-10 -> 350), nunca por 480.
func test_wrap_com_viewport_de_480_continua_em_360() -> void:
	_spawn(480, 200.0)
	assert_almost_eq(_wrap_apos_tick(500.0), 140.0, 0.5, "x=500 volta por 360")
	assert_almost_eq(_wrap_apos_tick(400.0), 40.0, 0.5, "x=400 (>360) tambem volta por 360")
	assert_almost_eq(_wrap_apos_tick(-10.0), 350.0, 0.5, "x=-10 entra por 360")

# C79: largura 360 mantem o comportamento da f412.
func test_largura_360_mantem_wrap_da_f412() -> void:
	_spawn(360, 200.0)
	assert_almost_eq(_wrap_apos_tick(400.0), 40.0, 0.5, "x=400 volta por 360")
	assert_almost_eq(_wrap_apos_tick(340.0), 340.0, 0.5, "x=340 permanece")

# C140/C824: viewport de 480: a borda (GHOST_HALF_WIDTH = 32) e o offset do fantasma sao de 360, nao de 480.
func test_fantasma_com_viewport_de_480_usa_borda_de_360() -> void:
	_spawn(480, 20.0)
	assert_eq(_p.GHOST_HALF_WIDTH, 32.0, "meia largura visual do gecko: frame 64 a escala 1")
	_p._process(0.0)
	var g := _p.get_node("Ghost") as AnimatedSprite2D
	assert_true(g.visible, "x=20: fantasma visivel")
	assert_almost_eq(g.global_position.x, 380.0, 0.0001, "x=20 -> fantasma em 380 (offset +360)")
	_p.position.x = 340.0
	_p._process(0.0)
	assert_true(g.visible, "x=340 (>328): fantasma visivel")
	assert_almost_eq(g.global_position.x, -20.0, 0.0001, "x=340 -> fantasma em -20 (offset -360)")
	_p.position.x = 200.0
	_p._process(0.0)
	assert_false(g.visible, "x=200 longe das bordas de 360: fantasma invisivel")

# C141: mudar o viewport de 360 para 480 em runtime (size_changed) nao altera o wrap.
func test_mudanca_de_largura_do_viewport_em_runtime_nao_altera_o_wrap() -> void:
	_spawn(360, 200.0)
	_sv.size = Vector2i(480, 640)
	await wait_process_frames(2)
	assert_almost_eq(_wrap_apos_tick(400.0), 40.0, 0.5, "x=400 ainda volta por 360 apos size_changed")

# C824: constantes de movimento dobradas, sprites a 64x64 visuais, colisoes dobradas
func test_player_2x_constantes_sprites_e_colisoes() -> void:
	_spawn(360, 200.0)
	assert_eq(_p.SPEED, 160, "SPEED 2x")
	assert_eq(_p.GRAVITY, 20, "GRAVITY 2x")
	assert_eq(_p.JUMP_POWER, -500, "JUMP_POWER 2x")
	var quadro: Vector2 = _p.sprite.sprite_frames.get_frame_texture("idle", 0).get_size()
	assert_eq(quadro, Vector2(64, 64), "frame idle 0 nativo e 64x64")
	assert_eq(_p.sprite.scale, Vector2.ONE, "AnimatedSprite2D sem escala extra (scale ONE)")
	assert_eq(_p.ghost.scale, Vector2.ONE, "Ghost sem escala extra (scale ONE)")
	assert_eq(quadro * _p.sprite.scale, Vector2(64, 64), "AnimatedSprite2D exibe 64x64")
	assert_eq(quadro * _p.ghost.scale, Vector2(64, 64), "Ghost exibe 64x64")
	assert_almost_eq(_p.collision.shape.size.x, 20.55088, 0.001, "colisao do corpo: largura 2x")
	assert_almost_eq(_p.collision.shape.size.y, 57.0372, 0.001, "colisao do corpo: altura 2x")
	assert_almost_eq(_p.detector.shape.size.x, 19.92024, 0.001, "detector: largura 2x")
	assert_almost_eq(_p.detector.shape.size.y, 8.77116, 0.001, "detector: altura 2x")
