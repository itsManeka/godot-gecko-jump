extends GutTest

# Regressao do issue #22: gerador de plataformas moveis (MOVE_TO_RIGHT) parava na 1a plataforma apos a conversao
# 3to4. Causa: AreaCheck de Platform.tscn com collision_layer = 0, entao o CheckGenerate do gerador nunca dispara
# area_exited e _on_CheckGenerate_area_exited nao reinicia o timer.

const GERADOR_SCENE := "res://scenes/RunningPlatforms.tscn"
# A 3a plataforma nasce em ~2,9 s; a espera tem folga para maquina carregada.
const TEMPO_SPAWN := 4.0
const MINIMO_PLATAFORMAS := 3


func before_each() -> void:
	Global.platforms = []
	Global.iniciado = false


func after_each() -> void:
	Global.platforms = []
	Global.iniciado = false


func _plataformas_filhas(gerador: Node) -> Array:
	var filhas: Array = []
	for filha in gerador.get_children():
		if filha is Platform and is_instance_valid(filha) and not filha.is_queued_for_deletion():
			filhas.append(filha)
	return filhas


func test_gerador_movel_gera_varias_plataformas_em_3_segundos() -> void:
	var gerador: Node2D = load(GERADOR_SCENE).instantiate()
	gerador.platform_type = Enums.PLATFORM_TYPE.MOVE_TO_LEFT
	gerador.position = Vector2(0, 100)
	Global.set_iniciado(true)
	add_child_autofree(gerador)

	await wait_seconds(TEMPO_SPAWN)

	var vivas := _plataformas_filhas(gerador).size()
	assert_gte(vivas, MINIMO_PLATAFORMAS, "gerador movel deve ter 3+ plataformas vivas (AreaCheck detectado pelo CheckGenerate)")
