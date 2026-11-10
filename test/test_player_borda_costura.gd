extends GutTest

# T4 (f412): interacoes da costura lateral. Pouso so pela posicao real (C55), fantasma sem colisao (C56),
# plataformas sem wrap (C57), CheckPlayer sem derrota falsa (C58), derrota por queda preservada (C59) e
# gecko arrastado ate cair (C60). Tudo em fisica real, determinista por wait_physics_frames.
const PLAYER := "res://scenes/Player.tscn"
const PLATFORM := "res://scenes/Platform.tscn"
const STAGE := "res://scenes/Stage.tscn"
const PLAYER_SCRIPT := preload("res://scenes/Player.gd")
# Faixa de derrota: topo na altura visivel (320), espessura 20 (y 320..340). O corpo do gecko tem 28,5 de altura
# (meia 14,3): em y = altura + 16 ele fica dentro da faixa e fora de qualquer faixa deslocada para cima (<= 320).
const VISIBLE_H := 320.0
const CHECK_Y := VISIBLE_H + 16.0
var _p: Node
var _pl: Node
var _stage: Node

func before_each() -> void:
	Global.platforms = []
	Global.iniciado = true

func after_each() -> void:
	# A liberacao do Stage no teardown dispara body_exited; end evita o handler tocar audio fora da arvore,
	# mesmo quando um assert falhou antes do fim do teste.
	if is_instance_valid(_p):
		_p.end = true
	Input.action_release("ui_right")
	Input.action_release("ui_left")
	Global.platforms = []
	Global.iniciado = false

# Roda n physics frames; can_change_color fica falso para o pouso nao trocar a cor (e desligar a plataforma).
func _step(n: int) -> void:
	for i in n:
		_p.can_change_color = false
		await wait_physics_frames(1)

func _spawn_player(px: float, py: float, cor: int) -> void:
	_p = add_child_autofree(load(PLAYER).instantiate())
	_p.color = cor
	_p.position = Vector2(px, py)

func _spawn_platform(px: float, py: float, speed: float, cor: int) -> void:
	_pl = add_child_autofree(load(PLATFORM).instantiate())
	_pl.position = Vector2(px, py)
	_pl.speed = speed
	_pl.color = cor

# Stage real sem o ScrollLevel (as plataformas geradas atrapalhariam). O Player do Stage fica com a fisica
# desligada ate o chamador liberar; o Play e o caminho real de inicio de partida.
func _spawn_stage() -> void:
	_stage = add_child_autofree(load(STAGE).instantiate())
	var scroll: Node = _stage.get_node("ScrollLevel")
	_stage.remove_child(scroll)
	scroll.free()
	_stage.apply_layout(Vector2(180.0, VISIBLE_H), Rect2(0.0, 0.0, 180.0, VISIBLE_H))
	_p = _stage.get_node("Node2D/Player")
	_p.set_physics_process(false)
	_stage._on_Play_button_down()
	Global.platforms = []

# Coloca o Player do Stage dentro da CheckPlayer (2 frames sem fisica registram a entrada na Area2D).
func _place_in_check(px: float, py: float) -> void:
	_p.position = Vector2(px, py)
	_p.velocity = Vector2.ZERO
	await wait_physics_frames(2)
	assert_true(_stage.get_node("CheckPlayer").overlaps_body(_p), "gecko posicionado dentro da CheckPlayer")

# C55: pouso so pela posicao real. Fantasma visivel em x=-2; plataforma so sob o fantasma nao segura o gecko.
func test_pouso_so_pela_posicao_real() -> void:
	var cor := Enums.COLOR.AMARELO
	_spawn_platform(0.0, 200.0, 0.0, cor)
	_spawn_player(178.0, 150.0, cor)
	await wait_physics_frames(1)
	_pl.player_color_changed(cor)
	_p._process(0.0)
	assert_true(_p.get_node("Ghost").visible, "x=178: fantasma visivel do outro lado")
	await _step(40)
	assert_false(_p.is_on_floor(), "plataforma so sob o fantasma (x=0) nao segura o gecko")
	assert_gt(_p.position.y, 260.0, "gecko segue caindo")
	assert_almost_eq(_p.position.x, 178.0, 0.5, "posicao real nao muda")

func test_pouso_na_plataforma_sob_a_posicao_real() -> void:
	var cor := Enums.COLOR.AMARELO
	_spawn_platform(178.0, 200.0, 0.0, cor)
	_spawn_player(178.0, 150.0, cor)
	await wait_physics_frames(1)
	_pl.player_color_changed(cor)
	await _step(40)
	assert_true(_p.is_on_floor(), "plataforma sob x=178 segura o gecko")
	assert_lt(_p.position.y, 200.0, "gecko ficou acima da plataforma")

# C56: Ghost e descendentes sem colisao; fantasma sobre plataforma da mesma cor nao pontua nem pousa.
func test_fantasma_sem_colisao_nem_pontuacao() -> void:
	var cor := Enums.COLOR.AMARELO
	_spawn_platform(0.0, 200.0, 0.0, cor)
	_spawn_player(178.0, 150.0, cor)
	await wait_physics_frames(1)
	_pl.player_color_changed(cor)
	var ghost: Node = _p.get_node("Ghost")
	var nos: Array = [ghost]
	nos.append_array(ghost.find_children("*", "", true, false))
	for n in nos:
		assert_false(n is CollisionObject2D, "Ghost e descendentes nao podem ser CollisionObject2D")
		assert_false(n is CollisionShape2D, "Ghost e descendentes nao podem ser CollisionShape2D")
	watch_signals(_p)
	await _step(40)
	assert_signal_not_emitted(_p, "add_point", "fantasma sobre plataforma de mesma cor nao pontua")
	assert_null(_p.actual_platform, "DetectorPlataforma nao entrou em contato por causa do fantasma")

# C57: plataforma nao tem wrap, segue a trajetoria alem de x=180.
func test_plataforma_nao_faz_wrap() -> void:
	_spawn_platform(170.0, 200.0, -60.0, Enums.COLOR.AMARELO)
	await wait_physics_frames(1)
	var x_ant: float = _pl.position.x
	for i in 40:
		await wait_physics_frames(1)
		assert_true(_pl.position.x >= x_ant - 0.001, "plataforma nunca volta (sem teleporte)")
		x_ant = _pl.position.x
	assert_gt(_pl.position.x, 190.0, "plataforma passou de x=180 e segue para a direita")

# C58: o teleporte da costura nao tira o corpo da CheckPlayer (sem derrota falsa), nos dois lados.
func test_checkplayer_sem_derrota_falsa_na_costura_direita() -> void:
	_spawn_stage()
	var check: Area2D = _stage.get_node("CheckPlayer")
	watch_signals(check)
	await _place_in_check(180.9, CHECK_Y)
	Input.action_press("ui_right")
	_p.set_physics_process(true)
	await wait_physics_frames(1)
	assert_lt(_p.position.x, 10.0, "gecko teleportou para perto de x=0")
	assert_signal_not_emitted(check, "body_exited", "teleporte nao sai da CheckPlayer")
	assert_false(_p.is_end(), "sem derrota falsa na costura direita")

func test_checkplayer_sem_derrota_falsa_na_costura_esquerda() -> void:
	_spawn_stage()
	var check: Area2D = _stage.get_node("CheckPlayer")
	watch_signals(check)
	await _place_in_check(0.9, CHECK_Y)
	Input.action_press("ui_left")
	_p.set_physics_process(true)
	await wait_physics_frames(1)
	assert_gt(_p.position.x, 170.0, "gecko teleportou para perto de x=180")
	assert_signal_not_emitted(check, "body_exited", "teleporte nao sai da CheckPlayer")
	assert_false(_p.is_end(), "sem derrota falsa na costura esquerda")

# C59: contraprova, sair por baixo (y > 340) fora de pulo continua perdendo.
func test_checkplayer_derrota_por_queda_preservada() -> void:
	_spawn_stage()
	var check: Area2D = _stage.get_node("CheckPlayer")
	watch_signals(check)
	await _place_in_check(90.0, CHECK_Y)
	assert_false(_p.is_end(), "dentro da CheckPlayer ainda nao perdeu")
	_p.set_physics_process(true)
	await _step(30)
	assert_signal_emitted(check, "body_exited", "a derrota vem da saida da CheckPlayer")
	assert_true(_p.is_end(), "saiu por baixo sem pular: partida perdida")
	assert_eq(_p.sprite.animation, "lose", "animacao de derrota tocada")

# C60: arrastado sem input pela plataforma ate teleportar, cair e perder pela CheckPlayer.
func test_arrasto_sem_input_termina_em_game_over() -> void:
	_spawn_stage()
	var cor := Enums.COLOR.AMARELO
	_p.color = cor
	_spawn_platform(150.0, 200.0, -60.0, cor)
	_p.position = Vector2(150.0, 180.0)
	await wait_physics_frames(1)
	_pl.player_color_changed(cor)
	_p.set_physics_process(true)
	var fora := 0
	var teleportou := false
	var x_ant: float = _p.position.x
	for i in 400:
		_p.can_change_color = false
		await wait_physics_frames(1)
		if _p.position.x < 0.0 or _p.position.x > 180.0:
			fora += 1
		if absf(_p.position.x - x_ant) > 90.0:
			teleportou = true
		x_ant = _p.position.x
		if _p.is_end():
			break
	assert_eq(fora, 0, "x nunca sai de [0,180]")
	assert_true(teleportou, "arrasto levou o gecko a costura (teleporte)")
	assert_true(_p.is_end(), "gecko caiu e a CheckPlayer encerrou a partida")
