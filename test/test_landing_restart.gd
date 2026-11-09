extends GutTest

# Cena: pouso -> reinicio -> pouso. Reproduz o bug #3 (Global.platforms guarda plataformas liberadas
# apos o reinicio e Global.player_color_changed quebra em Global.gd:27).
# Pendente ate a F4 (f402-gecko-bugs-base): a F4 remove a constante abaixo e o ramo de pending.
const PENDENTE_ATE_F4 := true
const STAGE_SCENE := "res://scenes/Stage.tscn"

var _stage: Node = null


func before_each() -> void:
	Global.platforms = []
	Global.iniciado = false


func after_each() -> void:
	if is_instance_valid(_stage):
		_stage.free()
	_stage = null
	Global.platforms = []
	Global.iniciado = false


func _novo_stage() -> Node:
	var stage: Node = load(STAGE_SCENE).instantiate()
	add_child(stage)
	await wait_frames(2)
	return stage


func _plataformas_validas() -> Array:
	var validas: Array = []
	for p in Global.platforms:
		if is_instance_valid(p):
			validas.append(p)
	return validas


# Pouso: o jogador esta em `alvo` e troca de cor (mesmo caminho de Player.set_color).
func _pousar(stage: Node, alvo: Platform, cor: int) -> void:
	var player = stage.get_node("Node2D/Player")
	player.actual_platform = alvo
	player.set_color(cor)
	Global.att_actual_platform(cor, alvo)


func test_pouso_reinicio_pouso_mantem_colisao_por_cor_e_plataformas_validas() -> void:
	if PENDENTE_ATE_F4:
		pending("issue #3 (Global.platforms guarda plataformas liberadas apos reiniciar) - pendente ate a F4 / f402-gecko-bugs-base")
		return

	# 1o pouso
	_stage = await _novo_stage()
	var primeiras := _plataformas_validas()
	assert_gt(primeiras.size(), 0, "1a Stage deve registrar plataformas")
	_pousar(_stage, primeiras[0], Enums.COLOR.AMARELO)

	# Reinicio: Stage._on_animation_end troca de cena; sem current_scene no GUT, libera e instancia nova Stage.
	_stage.free()
	_stage = await _novo_stage()

	# Fixture: 2+ cores de plataforma distintas na nova Stage
	var atuais := _plataformas_validas()
	assert_gt(atuais.size(), 1, "2a Stage deve ter 2+ plataformas validas")
	var i := 0
	for p in atuais:
		p.set_color(Enums.COLOR.AMARELO if i % 2 == 0 else Enums.COLOR.VERDE)
		i += 1

	# 2o pouso (com o bug #3, Global.gd:27 acessa plataforma liberada)
	_pousar(_stage, atuais[0], Enums.COLOR.AMARELO)

	# C24: colisao por cor
	var player_color: int = _stage.get_node("Node2D/Player").color
	var desabilitadas := 0
	var habilitadas := 0
	for p in _plataformas_validas():
		var esperado: bool = player_color != p.color
		assert_eq(p.shape.disabled, esperado, "shape.disabled == (player_color != platform.color)")
		if p.shape.disabled:
			desabilitadas += 1
		else:
			habilitadas += 1
	assert_gt(desabilitadas, 0, "fixture deve ter plataforma de cor diferente do jogador")
	assert_gt(habilitadas, 0, "fixture deve ter plataforma da cor do jogador")

	# C25: sem referencias liberadas em Global.platforms
	for p in Global.platforms:
		assert_true(is_instance_valid(p), "Global.platforms sem referencia liberada apos o reinicio")
