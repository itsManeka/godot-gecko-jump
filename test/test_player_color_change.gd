extends GutTest

# f557 T9: Player com SpriteFrames por cor (modulate sempre WHITE), animacao color_change no pouso (D5: run/jump/fall e
# lose interrompem, idle espera o fim) e fantasma espelhando sprite_frames. O pouso e real (Platform parada sob o
# gecko); a fisica nao pode depender da animacao (C861: mesma cena com e sem color_change).
const PLAYER := "res://scenes/Player.tscn"
const PLATFORM := "res://scenes/Platform.tscn"
const PLAYER_SCRIPT := preload("res://scenes/Player.gd")

# Player cujo pouso nao toca color_change: controle da comparacao de fisica (C861)
class PlayerSemColorChange:
	extends "res://scenes/Player.gd"
	func _iniciar_color_change() -> void:
		pass

var _p: Node
var _pl: Node
var _pontos := 0
var _snap := {}
var _frame0 := 0

func before_each() -> void:
	Global.platforms = []
	Global.iniciado = true
	_pontos = 0
	_snap = {}

func after_each() -> void:
	Input.action_release("ui_right")
	Input.action_release("ui_left")
	Input.action_release("jump")
	Global.platforms = []
	Global.iniciado = false

func _frames_da_cor(cor_id: int) -> SpriteFrames:
	return load("res://ressources/gecko_%s.tres" % str(Enums.COLOR.find_key(cor_id)).to_lower()) as SpriteFrames

func _outra_cor(cor_id: int) -> int:
	var cores: Array = Enums.COLOR.values()
	return cores[0] if cores[0] != cor_id else cores[1]

func _ao_pontuar() -> void:
	_pontos += 1
	_snap = {
		"pos": _p.position,
		"vel": _p.velocity,
		"anim": _p.sprite.animation,
		"frame_fisico": Engine.get_physics_frames() - _frame0,
	}

# Plataforma parada em y=200 e gecko da mesma cor em y=140 (pousa sozinho); o add_point marca o pouso
func _montar(script: Script = null) -> void:
	_pontos = 0
	_snap = {}
	_pl = add_child_autofree(load(PLATFORM).instantiate())
	_pl.position = Vector2(180, 200)
	_pl.speed = 0.0
	_pl.color = Enums.COR_INICIAL
	var p: Node = load(PLAYER).instantiate()
	if script != null:
		p.set_script(script)
	_p = add_child_autofree(p)
	_p.position = Vector2(180, 140)
	var semente := RandomNumberGenerator.new()
	semente.seed = 7
	_p.rng = semente
	_p.add_point.connect(_ao_pontuar)
	_frame0 = Engine.get_physics_frames()
	await wait_physics_frames(1)
	_pl.player_color_changed(Enums.COR_INICIAL)

func _desmontar() -> void:
	Input.action_release("ui_right")
	Input.action_release("ui_left")
	Input.action_release("jump")
	if is_instance_valid(_p):
		_p.queue_free()
	if is_instance_valid(_pl):
		_pl.queue_free()
	await get_tree().process_frame
	Global.platforms = []
	Global.iniciado = true

func _esperar_pouso() -> void:
	for i in 180:
		if _pontos > 0:
			return
		await wait_physics_frames(1)
	fail_test("o gecko nao pousou (add_point nao veio)")

func _spawn_quieto(px: float) -> void:
	_p = add_child_autofree(load(PLAYER).instantiate())
	_p.set_physics_process(false)
	_p.set_process(false)
	_p.position = Vector2(px, 100.0)

# C856: set_color troca sprite_frames de Player e Ghost por cor (4 distintos), mantem animation/frame e deixa WHITE
func test_set_color_troca_sprite_frames_do_player_e_do_ghost_e_deixa_modulate_branco() -> void:
	_spawn_quieto(180.0)
	_p.sprite.animation = &"run"
	_p.sprite.frame = 1
	var caminhos := {}
	for cor_id: int in Enums.COLOR.values():
		_p.set_color(cor_id)
		var esperado := _frames_da_cor(cor_id)
		assert_eq(_p.sprite.sprite_frames, esperado, "cor %s: sprite_frames do Player" % cor_id)
		assert_eq(_p.ghost.sprite_frames, esperado, "cor %s: sprite_frames do Ghost" % cor_id)
		assert_eq(_p.sprite.animation, &"run", "cor %s: animation corrente mantida" % cor_id)
		assert_eq(_p.sprite.frame, 1, "cor %s: frame corrente mantido" % cor_id)
		assert_eq(_p.sprite.modulate, Color.WHITE, "cor %s: sprite.modulate WHITE" % cor_id)
		assert_eq(_p.ghost.modulate, Color.WHITE, "cor %s: ghost.modulate WHITE" % cor_id)
		caminhos[_p.sprite.sprite_frames.resource_path] = true
	assert_eq(caminhos.size(), 4, "as 4 cores usam 4 SpriteFrames distintos")

# C857: o pouso toca color_change no frame seguinte e animation_finished volta a idle
func test_pouso_toca_color_change_e_o_fim_volta_a_idle() -> void:
	await _montar()
	await _esperar_pouso()
	assert_eq(_pontos, 1, "o pouso pontuou 1x")
	assert_eq(_p.sprite.animation, &"color_change", "no frame seguinte ao pouso toca color_change")
	await wait_for_signal(_p.sprite.animation_finished, 2.0)
	await wait_physics_frames(1)
	assert_eq(_p.sprite.animation, &"idle", "ao fim da color_change volta a idle")

# C858: run, jump e fall interrompem color_change no tick seguinte (D5)
func test_run_jump_e_fall_interrompem_color_change() -> void:
	for caso in ["run", "jump", "fall"]:
		await _montar()
		await _esperar_pouso()
		assert_eq(_p.sprite.animation, &"color_change", "%s: precondicao, color_change ativa" % caso)
		if caso == "run":
			Input.action_press("ui_right")
		elif caso == "jump":
			Input.action_press("jump")
		else:
			_p.position.y = 20.0
			_p.velocity = Vector2.ZERO
		await wait_physics_frames(2)
		assert_eq(_p.sprite.animation, StringName(caso), "%s interrompeu a color_change" % caso)
		await _desmontar()

# C859: idle nao interrompe color_change (espera o fim; D5)
func test_idle_durante_color_change_nao_interrompe() -> void:
	await _montar()
	await _esperar_pouso()
	await wait_physics_frames(1)
	assert_eq(_p.sprite.animation, &"color_change", "apos 1 tick parado a color_change segue (idle espera)")
	assert_true(_p.sprite.is_playing(), "a color_change continua tocando")

# C860: lose_game toca lose mesmo com color_change ativa
func test_lose_game_interrompe_color_change() -> void:
	await _montar()
	await _esperar_pouso()
	assert_eq(_p.sprite.animation, &"color_change", "precondicao: color_change ativa")
	_p.lose_game()
	assert_eq(_p.sprite.animation, &"lose", "lose_game toca lose na hora")
	await wait_physics_frames(2)
	assert_eq(_p.sprite.animation, &"lose", "lose segue depois dos ticks")

func _rodar_pouso(script: Script) -> Dictionary:
	await _montar(script)
	var trilha: Array = []
	for i in 40:
		await wait_physics_frames(1)
		trilha.append([_p.position, _p.velocity])
	var r := {"pontos": _pontos, "snap": _snap, "trilha": trilha}
	await _desmontar()
	return r

# C861: position, velocity, pontos e o frame fisico do pouso iguais com e sem color_change
func test_fisica_do_pouso_nao_depende_da_color_change() -> void:
	await _rodar_pouso(null)  # aquecimento: a 1a instanciacao da cena no processo tem a fase de fisica diferente
	var com: Dictionary = await _rodar_pouso(null)
	var sem: Dictionary = await _rodar_pouso(PlayerSemColorChange)
	assert_eq(com["pontos"], 1, "com color_change: 1 ponto")
	assert_eq(sem["pontos"], 1, "sem color_change: 1 ponto")
	assert_eq(com["snap"]["anim"], &"color_change", "controle: o lado com toca color_change no pouso")
	assert_ne(sem["snap"]["anim"], &"color_change", "controle: o lado sem nao toca color_change")
	assert_eq(com["snap"]["pos"], sem["snap"]["pos"], "position no tick do pouso")
	assert_eq(com["snap"]["vel"], sem["snap"]["vel"], "velocity no tick do pouso")
	assert_eq(com["snap"]["frame_fisico"], sem["snap"]["frame_fisico"], "add_point no mesmo frame fisico")
	var divergentes := 0
	for i in 40:
		if com["trilha"][i] != sem["trilha"][i]:
			divergentes += 1
	assert_eq(divergentes, 0, "trilha de position/velocity identica com e sem color_change")

# C862: animation_finished tardio de color_change ja interrompida nao toca idle nem limpa a flag da color_change nova
func test_sinal_tardio_de_color_change_interrompida_nao_afeta_a_nova() -> void:
	await _montar()
	await _esperar_pouso()
	Input.action_press("ui_right")
	await wait_physics_frames(2)
	assert_eq(_p.sprite.animation, &"run", "precondicao: run interrompeu a 1a color_change")
	_p.sprite.animation_finished.emit()
	assert_eq(_p.sprite.animation, &"run", "sinal tardio com animation run nao troca a animacao")
	Input.action_release("ui_right")
	_p.change_color_random()
	assert_eq(_p.sprite.animation, &"color_change", "2o pouso com troca de cor toca color_change")
	await wait_physics_frames(1)
	assert_eq(_p.sprite.animation, &"color_change", "a flag da 2a color_change segue ativa: idle espera")

# C863: o reaparecimento (resgate) nao dispara color_change
func test_reaparecer_sobre_nao_dispara_color_change() -> void:
	await _montar()
	var outra := _outra_cor(_p.color)
	_p.reaparecer_sobre(_pl, outra)
	assert_eq(_p.color, outra, "controle: a cor foi assumida (houve troca de cor)")
	assert_ne(_p.sprite.animation, &"color_change", "reaparecer_sobre nao toca color_change")
	await wait_physics_frames(2)
	assert_ne(_p.sprite.animation, &"color_change", "nem nos ticks seguintes")

# C864: o fantasma nas bordas espelha sprite_frames, animation, frame, flip_h e modulate; nunca toca sozinho
func test_ghost_nas_bordas_espelha_o_sprite_real() -> void:
	_spawn_quieto(10.0)
	var frames_outra := _frames_da_cor(_outra_cor(_p.color))
	_p.sprite.sprite_frames = frames_outra
	_p.sprite.animation = &"color_change"
	_p.sprite.frame = 1
	_p.sprite.flip_h = true
	_p.sprite.modulate = Color(0.9, 0.8, 0.7)
	assert_ne(_p.ghost.sprite_frames, frames_outra, "precondicao: o ghost ainda tem outro sprite_frames")
	for x in [10.0, 350.0]:
		_p.position.x = x
		_p._process(0.0)
		assert_true(_p.ghost.visible, "x=%s: ghost visivel" % x)
		assert_eq(_p.ghost.sprite_frames, frames_outra, "x=%s: sprite_frames espelhado" % x)
		assert_eq(_p.ghost.animation, &"color_change", "x=%s: animation espelhada" % x)
		assert_eq(_p.ghost.frame, 1, "x=%s: frame espelhado" % x)
		assert_true(_p.ghost.flip_h, "x=%s: flip_h espelhado" % x)
		assert_eq(_p.ghost.modulate, _p.sprite.modulate, "x=%s: modulate espelhado" % x)
		assert_false(_p.ghost.is_playing(), "x=%s: o ghost nao toca sozinho" % x)

# C865: meia largura do fantasma 32 e fantasma em +-360 (HEAD de test_player_largura_visivel)
func test_ghost_half_width_32_e_fantasma_em_mais_ou_menos_360() -> void:
	assert_eq(PLAYER_SCRIPT.GHOST_HALF_WIDTH, 32.0, "GHOST_HALF_WIDTH continua 32.0")
	_spawn_quieto(31.9)
	_p._process(0.0)
	assert_true(_p.ghost.visible, "x=31.9 cruza a borda esquerda")
	assert_eq(_p.ghost.position.x, 360.0, "fantasma em +360")
	_p.position.x = 32.0
	_p._process(0.0)
	assert_false(_p.ghost.visible, "x=32 nao cruza")
	_p.position.x = 328.0
	_p._process(0.0)
	assert_false(_p.ghost.visible, "x=328 nao cruza")
	_p.position.x = 328.1
	_p._process(0.0)
	assert_true(_p.ghost.visible, "x=328.1 cruza a borda direita")
	assert_eq(_p.ghost.position.x, -360.0, "fantasma em -360")
