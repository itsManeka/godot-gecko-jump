extends GutTest

# T2 de f489-camera-acompanha-gecko-no-alto-46: Stage real (SubViewport) com o avanco da camera do topo aplicado
# depois do Player. Limite e excesso vem de CameraFollow (01 T1), nunca copiados da implementacao.

const STAGE := "res://scenes/Stage.tscn"
const ALTURA := 320
const PASSO := 1.0 / 60.0
# excesso(100, 128) do criterio de aceite do 01 (T1): gecko 28 px acima do limite com altura 320
const EXCESSO_01 := 28.0
var _sv: SubViewport
var _stage: Node
var _scroll: Node
var _p: Node


func before_each() -> void:
	Global.tutorial_visto_espelho = true
	Global.platforms = []
	Global.iniciado = false


func after_each() -> void:
	if is_instance_valid(_p):
		_p.end = true
	Global.platforms = []
	Global.iniciado = false


# y do limite de topo para a altura do SubViewport (fracao lida de CameraFollow, nao literal no teste)
func _limite(altura: int = ALTURA) -> float:
	return CameraFollow.limite_y(float(altura))


# Stage real em SubViewport 180x320. Com `com_curva` false o scroll da curva fica desligado (valor exato do excesso);
# com `com_curva` true vale o scroll do estagio 0 (20 px/s). Player e Stage seguem com physics ligado: a ordem de
# processamento (Player antes da Stage) e parte do que se verifica.
func _spawn(com_curva: bool = false, altura: int = ALTURA) -> void:
	_sv = SubViewport.new()
	_sv.size = Vector2i(180, altura)
	add_child_autofree(_sv)
	_stage = load(STAGE).instantiate()
	_sv.add_child(_stage)
	_scroll = _stage.get_node("ScrollLevel")
	_p = _stage.get_node("Node2D/Player")
	_scroll.dificuldade = null
	if not com_curva:
		_scroll.set_physics_process(false)
	await wait_process_frames(1)


# C432: gecko 28 px acima do limite volta ao limite no mesmo physics frame e o mundo avanca o mesmo excesso
func test_c432_gecko_acima_do_limite_volta_ao_limite_em_1_frame() -> void:
	await _spawn()
	_stage._on_Play_button_down()
	_p.global_position.y = _limite() - EXCESSO_01
	_p.velocity.y = 0.0
	var plataformas_antes: float = _scroll.running_platforms.position.y
	var scrolled_antes: float = _scroll.position_scrolled

	await wait_physics_frames(1)

	var delta_plataformas: float = _scroll.running_platforms.position.y - plataformas_antes
	var delta_scrolled: float = _scroll.position_scrolled - scrolled_antes
	assert_almost_eq(_p.global_position.y, _limite(), 0.0001, "C432: o gecko volta ao limite no mesmo physics frame")
	assert_almost_eq(delta_plataformas, delta_scrolled, 0.0001, "C432: plataformas e position_scrolled avancam juntos")
	assert_almost_eq(delta_plataformas, EXCESSO_01, 0.5, "C432: o avanco e o excesso do gecko (curva de scroll desligada)")


# C433: cenario do repro (y global -35,4, acima do topo): apos 1 frame o gecko esta no limite, nunca em y negativo
func test_c433_gecko_acima_do_topo_y_negativo_nao_fica_acima_da_tela() -> void:
	await _spawn()
	_stage._on_Play_button_down()
	_p.global_position.y = -35.4
	_p.velocity.y = 0.0

	await wait_physics_frames(1)

	assert_gte(_p.global_position.y, 0.0, "C433: o gecko nunca sai pelo topo (y >= 0)")
	assert_almost_eq(_p.global_position.y, _limite(), 0.0001, "C433: o gecko para no limite de topo")


# C434: com a curva de dificuldade (scroll > 0) o avanco e curva + excesso, nunca menor que a curva
func test_c434_avanco_soma_curva_e_excesso_nunca_menor_que_a_curva() -> void:
	await _spawn(true)
	_scroll.dificuldade = _stage.dificuldade
	_stage._on_Play_button_down()
	_p.global_position.y = _limite() - EXCESSO_01
	_p.velocity.y = 0.0
	var plataformas_antes: float = _scroll.running_platforms.position.y
	var curva: float = DifficultySnapshot.de(_stage.dificuldade).get_scroll() * PASSO
	assert_gt(curva, 0.0, "C434: pre-condicao de dificuldade real com scroll positivo")

	await wait_physics_frames(1)

	var delta: float = _scroll.running_platforms.position.y - plataformas_antes
	assert_almost_eq(delta, curva + EXCESSO_01, 0.5, "C434: o avanco do frame e a soma da curva com o excesso")
	assert_gte(delta, curva, "C434: o avanco nunca e menor que a curva de dificuldade")
	assert_almost_eq(_p.global_position.y, _limite(), 0.0001, "C434: o gecko tambem chega ao limite no frame")


# C435: menu (partida nao iniciada) com o gecko acima do limite: gecko e plataformas nao se movem
func test_c435_menu_com_gecko_acima_do_limite_nao_move_nada() -> void:
	await _spawn()
	assert_false(Global.is_iniciado(), "C435: pre-condicao de menu (partida nao iniciada)")
	_p.global_position.y = _limite() - EXCESSO_01
	_p.velocity.y = 0.0
	var gecko_antes: float = _p.global_position.y
	var plataformas_antes: float = _scroll.running_platforms.position.y
	var scrolled_antes: float = _scroll.position_scrolled

	await wait_physics_frames(1)

	assert_almost_eq(_p.global_position.y, gecko_antes, 0.0001, "C435: no menu o gecko nao e deslocado")
	assert_almost_eq(_scroll.running_platforms.position.y, plataformas_antes, 0.0001, "C435: no menu as plataformas nao se movem")
	assert_almost_eq(_scroll.position_scrolled, scrolled_antes, 0.0001, "C435: no menu position_scrolled nao avanca")


# C437: gecko abaixo do limite: o avanco do frame e so a curva (20 px/s no estagio 0), sem excesso
func test_c437_gecko_abaixo_do_limite_avanca_so_a_curva() -> void:
	await _spawn(true)
	_stage._on_Play_button_down()
	_p.global_position.y = _limite() + 30.0
	_p.velocity.y = 0.0
	var plataformas_antes: float = _scroll.running_platforms.position.y

	await wait_physics_frames(1)

	var delta: float = _scroll.running_platforms.position.y - plataformas_antes
	assert_almost_eq(delta, 20.0 * PASSO, 0.05, "C437: abaixo do limite so a curva de 20 px/s move o mundo")


# Gecko 28 px acima do limite numa Stage de `altura` px: apos 1 physics frame ele volta ao limite dessa altura
func _gecko_acima_volta_ao_limite(altura: int, rotulo: String) -> void:
	await _spawn(false, altura)
	_stage._on_Play_button_down()
	_p.global_position.y = _limite(altura) - EXCESSO_01
	_p.velocity.y = 0.0

	await wait_physics_frames(1)

	assert_almost_eq(_p.global_position.y, _limite(altura), 0.0001, "%s: gecko acima do limite volta a ele" % rotulo)


# C438: altura 320, limite 128
func test_c438_altura_320_gecko_acima_do_limite_volta_a_128() -> void:
	await _gecko_acima_volta_ao_limite(320, "C438")
	assert_almost_eq(_p.global_position.y, 128.0, 0.0001, "C438: limite da altura 320 e 128")


# C439: altura 400, limite 160
func test_c439_altura_400_gecko_acima_do_limite_volta_a_160() -> void:
	await _gecko_acima_volta_ao_limite(400, "C439")
	assert_almost_eq(_p.global_position.y, 160.0, 0.0001, "C439: limite da altura 400 e 160")


# C440: altura 462, limite 184.8
func test_c440_altura_462_gecko_acima_do_limite_volta_a_184_8() -> void:
	await _gecko_acima_volta_ao_limite(462, "C440")
	assert_almost_eq(_p.global_position.y, 184.8, 0.0001, "C440: limite da altura 462 e 184.8")


# C441: excesso de 160 px num frame (> ESPACAMENTO): as linhas novas nascem sem buraco, a ESPACAMENTO uma da outra
func test_c441_avanco_grande_cria_linhas_sem_buraco() -> void:
	await _spawn()
	_stage._on_Play_button_down()
	var antes: Array = _scroll.running_platforms.get_children()
	_p.global_position.y = _limite() - 160.0
	_p.velocity.y = 0.0

	await wait_physics_frames(2)

	var ys: Array = []
	for filho in _scroll.running_platforms.get_children():
		if not antes.has(filho):
			ys.append(filho.position.y)
	ys.sort()
	var esperadas: int = int(floor((160.0 + 0.0001) / InitialRows.ESPACAMENTO))
	assert_eq(ys.size(), esperadas, "C441: uma linha nova por ESPACAMENTO de excesso")
	for i in range(1, ys.size()):
		assert_almost_eq(ys[i] - ys[i - 1], InitialRows.ESPACAMENTO, 0.0001, "C441: linhas consecutivas sem buraco")
