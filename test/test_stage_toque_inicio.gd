extends GutTest

# Toque inicia a partida (Stage real + TouchControls), 1 unica vez, sem virar tap de jogo e sem agir na derrota.
const STAGE_SCENE := "res://scenes/Stage.tscn"

var _inicios: int = 0


func before_each() -> void:
	Global.platforms = []
	Global.iniciado = false
	_inicios = 0


func after_each() -> void:
	for acao in ["jump", "ui_left", "ui_right"]:
		Input.action_release(acao)
	Global.platforms = []
	Global.iniciado = false


var _viu_jump: bool = false
var _viu_esquerda: bool = false


func _amostrar_acoes() -> void:
	_viu_jump = _viu_jump or Input.is_action_pressed("jump")
	_viu_esquerda = _viu_esquerda or Input.is_action_pressed("ui_left")


func _contar_inicio() -> void:
	_inicios += 1


func _novo_stage() -> Node:
	var stage: Node = add_child_autofree(load(STAGE_SCENE).instantiate())
	stage.partida_iniciada.connect(_contar_inicio)
	await wait_frames(2)
	return stage


func _toque(pressionado: bool, x: float = 45.0) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = 0
	ev.pressed = pressionado
	ev.position = Vector2(x, 100.0)
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
	await wait_frames(2)


func test_toque_no_menu_inicia_a_partida() -> void:
	var stage := await _novo_stage()
	assert_false(stage.started, "nasce no menu")
	await _toque(true)
	assert_true(stage.started, "toque de jogo no menu inicia")
	assert_true(Global.is_iniciado(), "Global marcado como iniciado")


func test_toque_sobre_o_play_inicia_uma_unica_vez() -> void:
	var stage := await _novo_stage()
	await _toque(true)
	stage._on_Play_button_down()  # button_down emulado do mesmo toque
	assert_eq(_inicios, 1, "inicio conta uma unica vez")


func test_play_button_down_duas_vezes_inicia_uma_vez() -> void:
	var stage := await _novo_stage()
	stage._on_Play_button_down()
	stage._on_Play_button_down()
	assert_eq(_inicios, 1, "guarda de started")


func test_toque_que_inicia_nao_vira_pulo() -> void:
	var stage := await _novo_stage()
	_viu_jump = false
	_viu_esquerda = false
	get_tree().physics_frame.connect(_amostrar_acoes)
	await _toque(true)
	await _toque(false)
	await wait_physics_frames(6)
	get_tree().physics_frame.disconnect(_amostrar_acoes)
	assert_true(stage.started, "partida iniciou")
	assert_false(_viu_jump, "o toque que inicia nao pressiona jump")
	assert_false(_viu_esquerda, "nem anda para o lado")


func test_toque_durante_a_derrota_nao_muda_nada() -> void:
	var stage := await _novo_stage()
	stage._on_Play_button_down()
	var player = stage.get_node("Node2D/Player")
	player.jumping = false
	stage._on_CheckPlayer_body_exited(player)
	assert_eq(stage.ultimo_estado["state"], "lost", "derrota publicada")
	await _toque(true)
	assert_true(stage.started, "started nao muda")
	assert_eq(_inicios, 1, "nenhum novo inicio")
	assert_eq(stage.ultimo_estado["state"], "lost", "estado segue lost")


func test_nova_stage_nasce_sem_iniciar_e_sem_acao_presa() -> void:
	var stage := await _novo_stage()
	await _toque(true)
	remove_child(stage)
	stage.free()
	Global.iniciado = false
	var nova := await _novo_stage()
	assert_false(nova.started, "nova Stage nasce com started false")
	assert_false(Input.is_action_pressed("jump"), "sem jump preso")
	assert_false(Input.is_action_pressed("ui_left"), "sem ui_left preso")
	assert_false(Input.is_action_pressed("ui_right"), "sem ui_right preso")
