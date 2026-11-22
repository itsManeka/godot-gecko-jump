extends GutTest

# f527 T3: a Stage repassa GameModeRule.fator_scroll_forcado() ao ScrollLevel e ao Player.scroll_efetivo().
# Zen = 0.0 zera so a curva: o avanco da camera (gecko acima do limite) segue valendo (D6).

const STAGE := "res://scenes/Stage.tscn"
const ALTURA := 320
const EPS := 0.0001
var _sv: SubViewport
var _stage: Node
var _scroll: Node
var _p: Node


func before_each() -> void:
	Global.tutorial_visto_espelho = true
	Global.platforms = []
	Global.iniciado = false


func after_each() -> void:
	get_tree().paused = false
	if is_instance_valid(_p):
		_p.end = true
	Global.set_modo_jogo(GameModes.ID_CLASSICO)
	Global.platforms = []
	Global.iniciado = false


# Stage real em SubViewport 180x320 com a regra injetada antes do add_child; o Player fica sem fisica (so o scroll e medido)
func _spawn(regra: GameModeRule) -> void:
	_sv = SubViewport.new()
	_sv.size = Vector2i(180, ALTURA)
	add_child_autofree(_sv)
	_stage = load(STAGE).instantiate()
	_stage.regra = regra
	_sv.add_child(_stage)
	_scroll = _stage.get_node("ScrollLevel")
	_p = _stage.get_node("Node2D/Player")
	await wait_process_frames(1)
	_p.set_physics_process(false)


func _frame() -> void:
	await get_tree().physics_frame
	await get_tree().process_frame


# Partida iniciada, N ticks de fisica; devolve [delta y das plataformas, delta position_scrolled, scroll_efetivo]
func _rodar_ticks(n: int) -> Array:
	_stage._on_Play_button_down()
	var y0: float = _scroll.running_platforms.position.y
	var s0: float = _scroll.position_scrolled
	for i in range(n):
		await _frame()
	return [_scroll.running_platforms.position.y - y0, _scroll.position_scrolled - s0, _p.scroll_efetivo()]


# C717
func test_zen_partida_iniciada_nao_scrolla_e_classico_scrolla() -> void:
	await _spawn(ZenRule.new())
	var zen: Array = await _rodar_ticks(10)
	assert_almost_eq(float(zen[0]), 0.0, EPS, "C717: Zen, running_platforms.position.y igual ao inicio")
	assert_almost_eq(float(zen[1]), 0.0, EPS, "C717: Zen, position_scrolled igual ao inicio")
	assert_almost_eq(float(zen[2]), 0.0, EPS, "C717: Zen, Player.scroll_efetivo() == 0")

	_p.end = true
	_sv.queue_free()
	await wait_process_frames(1)
	Global.iniciado = false
	await _spawn(ClassicoRule.new())
	var classico: Array = await _rodar_ticks(10)
	assert_gt(float(classico[0]), 0.0, "C717: Classico no mesmo setup move as plataformas")
	assert_gt(float(classico[1]), 0.0, "C717: Classico no mesmo setup avanca position_scrolled")
	assert_gt(float(classico[2]), 0.0, "C717: Classico, Player.scroll_efetivo() > 0")


# C718
func test_troca_classico_zen_classico_no_menu_religa_e_desliga_o_fator_sem_reload() -> void:
	await _spawn(ClassicoRule.new())
	var curva: float = _p.scroll_efetivo()
	assert_gt(curva, 0.0, "C718: pre-condicao, Classico tem scroll > 0")

	_stage._fechar_modos(GameModes.de_id(GameModes.ID_ZEN))
	assert_eq(String(Global.get_modo_jogo()), String(GameModes.ID_ZEN), "C718: pre-condicao, o modo virou Zen")
	assert_almost_eq(_scroll.fator_forcado, 0.0, EPS, "C718: Zen zera o fator do ScrollLevel")
	assert_almost_eq(_p.scroll_efetivo(), 0.0, EPS, "C718: Zen zera o scroll_efetivo do Player")
	var zen: Array = await _rodar_ticks(5)
	assert_almost_eq(float(zen[1]), 0.0, EPS, "C718: Zen sem reload, position_scrolled parado")

	Global.iniciado = false
	_stage._fechar_modos(GameModes.de_id(GameModes.ID_CLASSICO))
	assert_almost_eq(_scroll.fator_forcado, 1.0, EPS, "C718: de volta ao Classico o fator e 1.0")
	var curva_agora: float = DifficultySnapshot.de(_stage.dificuldade).get_scroll()
	assert_gt(curva_agora, 0.0, "C718: pre-condicao, a curva vigente e positiva")
	assert_almost_eq(_p.scroll_efetivo(), curva_agora, EPS, "C718: de volta ao Classico o scroll volta ao valor da curva")


# C719
func test_zen_avancar_camera_com_gecko_acima_do_limite_sobe_o_mundo_e_cria_linha() -> void:
	await _spawn(ZenRule.new())
	_stage._on_Play_button_down()
	var limite: float = CameraFollow.limite_y(float(ALTURA))
	_p.global_position.y = limite - 160.0
	_p.velocity.y = 0.0
	var plataformas_antes: float = _scroll.running_platforms.position.y
	var linhas_antes: int = _scroll._rows_spawned

	for i in range(CameraFollow.DURACAO_FRAMES * 20):
		if CameraFollow.excesso(_p.global_position.y, limite) <= EPS:
			break
		await _frame()

	assert_almost_eq(_scroll._fator_scroll(), 0.0, EPS, "C719: pre-condicao, a curva esta zerada")
	assert_gt(_scroll.running_platforms.position.y - plataformas_antes, 100.0, "C719: Zen com scroll 0 ainda sobe o mundo")
	assert_gt(_scroll._rows_spawned, linhas_antes, "C719: o avanco da camera cria linha nova no Zen")


# C720
func test_zen_progressao_da_dificuldade_segue_por_pontos_sem_scroll() -> void:
	await _spawn(ZenRule.new())
	assert_eq(_stage.dificuldade.estagio(), 0, "C720: pre-condicao, estagio 0")
	_stage._on_Play_button_down()
	var total: int = int(_stage.CURVA_DIFICULDADE.pontos_plato) + 2
	for i in range(total):
		_stage.add_point()
	assert_gt(_stage.dificuldade.estagio(), 0, "C720: o estagio avanca com pontos no Zen")
	var y0: float = _scroll.running_platforms.position.y
	for i in range(5):
		await _frame()
	assert_almost_eq(_scroll.running_platforms.position.y - y0, 0.0, EPS, "C720: estagio alto e sem scroll no Zen")
