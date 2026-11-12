extends GutTest

# f458 T5: ScrollLevel le o scroll do snapshot da dificuldade a cada frame e repassa o estado as linhas novas.
const SCROLL := "res://scenes/ScrollLevel.tscn"
const DELTA := 0.1
var _scroll: Node


func before_each() -> void:
	Global.platforms = []
	Global.iniciado = false


func after_each() -> void:
	Global.platforms = []
	Global.iniciado = false


func _spawn() -> void:
	var sv := SubViewport.new()
	sv.size = Vector2i(180, 400)
	add_child_autofree(sv)
	_scroll = load(SCROLL).instantiate()
	sv.add_child(_scroll)
	_scroll.set_physics_process(false)
	await wait_process_frames(1)


# Curva de 2 estagios: scroll 20 em progresso 0 e 60 em progresso 1 (100 pontos); speed_moveis 100 no 0
func _estado(scroll_fim: float = 60.0) -> DifficultyState:
	var a := DifficultyStage.new()
	a.scroll = 20.0
	a.speed_moveis = 100.0
	var b := DifficultyStage.new()
	b.progresso_inicio = 1.0
	b.scroll = scroll_fim
	b.speed_moveis = 100.0
	var curva := DifficultyCurve.new()
	curva.estagios = [a, b] as Array[DifficultyStage]
	curva.pontos_plato = 100.0
	return DifficultyState.new(curva)


# C174
func test_scroll_avanca_snapshot_vezes_delta_lido_a_cada_frame() -> void:
	await _spawn()
	var estado := _estado()
	_scroll.dificuldade = estado
	Global.iniciado = true
	var y0: float = _scroll.running_platforms.position.y
	estado.set_pontos(50)  # progresso 0.5 -> scroll 40
	_scroll._physics_process(DELTA)
	assert_almost_eq(_scroll.running_platforms.position.y - y0, 40.0 * DELTA, 0.0001, "frame 1: scroll 40 * delta")
	estado.set_pontos(100)  # scroll muda entre frames -> 60
	var y1: float = _scroll.running_platforms.position.y
	_scroll._physics_process(DELTA)
	assert_almost_eq(_scroll.running_platforms.position.y - y1, 60.0 * DELTA, 0.0001, "frame 2: scroll 60 * delta")


# C175
func test_estagio_0_avanca_20_por_delta_e_linhas_iniciais_intactas() -> void:
	await _spawn()
	assert_eq(_scroll.running_platforms.get_child_count(), 9, "altura 400: 9 linhas iniciais")
	Global.iniciado = true
	var y0: float = _scroll.running_platforms.position.y
	_scroll._physics_process(DELTA)
	assert_almost_eq(_scroll.running_platforms.position.y - y0, 20.0 * DELTA, 0.0001, "sem estado: 20 * delta")
	_scroll.dificuldade = _estado()
	var y1: float = _scroll.running_platforms.position.y
	_scroll._physics_process(DELTA)
	assert_almost_eq(_scroll.running_platforms.position.y - y1, 20.0 * DELTA, 0.0001, "estado no estagio 0: 20 * delta")


# C176
func test_linhas_do_tscn_no_estagio_0_e_novas_recebem_estado_antes_do_add_child() -> void:
	await _spawn()
	var estado := _estado()
	var antigas: Array = _scroll.running_platforms.get_children()
	_scroll.dificuldade = estado
	_scroll.create_new_running_platform(-60.0)
	await wait_process_frames(2)
	var novas: Array = []
	for c in _scroll.running_platforms.get_children():
		if not antigas.has(c):
			novas.append(c)
	assert_eq(novas.size(), 1, "uma linha nova")
	assert_same(novas[0].dificuldade, estado, "linha nova recebe o estado")
	assert_almost_eq(absf(novas[0].speed), 100.0, 0.0001, "speed lida do snapshot no _ready: estado injetado antes do add_child")
	for c in antigas:
		assert_null(c.dificuldade, "linha anterior a injecao nao tem estado")
		assert_almost_eq(absf(c.speed), 60.0, 0.0001, "linha anterior a injecao nasceu no estagio 0")
