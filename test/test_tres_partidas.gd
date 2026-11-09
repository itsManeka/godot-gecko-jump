extends GutTest

# Verificacao do #4 (leaked at exit, nao reproduzido): 3 partidas seguidas com pouso simulado e reinicio
# por troca de cena. Sem current_scene no GUT, o reinicio libera a Stage e instancia uma nova.
const STAGE_SCENE := "res://scenes/Stage.tscn"
const PARTIDAS := 3

var _stage: Node = null


func before_each() -> void:
	Global.platforms = []
	Global.iniciado = false


func after_each() -> void:
	_stage = null
	Global.platforms = []
	Global.iniciado = false


func _novo_stage() -> Node:
	var stage: Node = add_child_autofree(load(STAGE_SCENE).instantiate())
	await wait_frames(2)
	return stage


func _plataformas_validas() -> Array:
	var validas: Array = []
	for p in Global.platforms:
		if is_instance_valid(p):
			validas.append(p)
	return validas


# Pouso: mesmo caminho de Player.set_color (igual a _pousar de test_landing_restart.gd).
func _pousar(stage: Node, alvo: Platform, cor: int) -> void:
	var player = stage.get_node("Node2D/Player")
	player.actual_platform = alvo
	player.set_color(cor)
	Global.att_actual_platform(cor, alvo)


func test_tres_partidas_seguidas_sem_referencia_liberada_em_global_platforms() -> void:
	for partida in range(PARTIDAS):
		_stage = await _novo_stage()
		var plataformas := _plataformas_validas()
		assert_gt(plataformas.size(), 0, "partida %d: Stage deve registrar plataformas" % partida)

		var cor: int = Enums.COLOR.AMARELO if partida % 2 == 0 else Enums.COLOR.VERDE
		_pousar(_stage, plataformas[0], cor)
		await wait_frames(2)

		for p in Global.platforms:
			assert_true(is_instance_valid(p), "partida %d: Global.platforms sem referencia liberada apos o pouso" % partida)

		# Reinicio: libera a Stage (como a troca de cena) e segue para a proxima partida.
		remove_child(_stage)
		_stage.free()
		_stage = null
		await wait_frames(2)

		for p in Global.platforms:
			assert_true(is_instance_valid(p), "partida %d: Global.platforms sem referencia liberada ao fim da partida" % partida)
