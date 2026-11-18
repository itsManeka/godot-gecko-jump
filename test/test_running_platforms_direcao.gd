extends GutTest

# f452: o nome do enum casa com o sentido real do movimento. MOVE_TO_LEFT anda para a esquerda (x diminui, nasce a
# direita); MOVE_TO_RIGHT anda para a direita (x aumenta, nasce a esquerda). Mede position.x apos N ticks de fisica.

const GERADOR_SCENE := "res://scenes/RunningPlatforms.tscn"
const SPAWN_DIREITA := 210.0
const SPAWN_ESQUERDA := -30.0
const TICKS := 20


func before_each() -> void:
	Global.platforms = []
	Global.iniciado = false


func after_each() -> void:
	Global.platforms = []
	Global.iniciado = false


func _criar_gerador(tipo: Enums.PLATFORM_TYPE) -> Node2D:
	var gerador: Node2D = load(GERADOR_SCENE).instantiate()
	gerador.platform_type = tipo
	gerador.position = Vector2(0, 100)
	Global.set_iniciado(true)
	return gerador


func _plataformas(gerador: Node) -> Array:
	var filhas: Array = []
	for filha in gerador.get_children():
		if filha is Platform and is_instance_valid(filha) and not filha.is_queued_for_deletion():
			filhas.append(filha)
	return filhas


# Plataforma do ponto de nascimento (a unica com esse x no 1o frame)
func _do_nascimento(gerador: Node, spawn_x: float) -> Platform:
	for p in _plataformas(gerador):
		if is_equal_approx(p.position.x, spawn_x):
			return p
	return null


func test_gerador_move_to_left_plataforma_anda_para_a_esquerda() -> void:
	var gerador := _criar_gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT)
	add_child_autofree(gerador)
	var p := _do_nascimento(gerador, SPAWN_DIREITA)
	assert_not_null(p, "MOVE_TO_LEFT deve ter plataforma no ponto de nascimento")
	var x0: float = p.position.x

	await wait_physics_frames(TICKS)

	assert_lt(p.position.x - x0, 0.0, "MOVE_TO_LEFT: position.x deve diminuir ao longo dos ticks")


func test_gerador_move_to_right_plataforma_anda_para_a_direita() -> void:
	var gerador := _criar_gerador(Enums.PLATFORM_TYPE.MOVE_TO_RIGHT)
	add_child_autofree(gerador)
	var p := _do_nascimento(gerador, SPAWN_ESQUERDA)
	assert_not_null(p, "MOVE_TO_RIGHT deve ter plataforma no ponto de nascimento")
	var x0: float = p.position.x

	await wait_physics_frames(TICKS)

	assert_gt(p.position.x - x0, 0.0, "MOVE_TO_RIGHT: position.x deve aumentar ao longo dos ticks")


func test_move_to_left_nasce_a_direita() -> void:
	var gerador := _criar_gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT)
	add_child_autofree(gerador)

	assert_almost_eq(gerador.check_generate.position.x, SPAWN_DIREITA, 0.001, "MOVE_TO_LEFT: ponto de nascimento a direita")
	assert_not_null(_do_nascimento(gerador, SPAWN_DIREITA), "MOVE_TO_LEFT: primeira plataforma aparece em x=210")


func test_move_to_right_nasce_a_esquerda() -> void:
	var gerador := _criar_gerador(Enums.PLATFORM_TYPE.MOVE_TO_RIGHT)
	add_child_autofree(gerador)

	assert_almost_eq(gerador.check_generate.position.x, SPAWN_ESQUERDA, 0.001, "MOVE_TO_RIGHT: ponto de nascimento a esquerda")
	assert_not_null(_do_nascimento(gerador, SPAWN_ESQUERDA), "MOVE_TO_RIGHT: primeira plataforma aparece em x=-30")
