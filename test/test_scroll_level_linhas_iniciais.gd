extends GutTest

# f411 T2: ScrollLevel gera as linhas iniciais pela altura visivel e o fluxo por gatilho aritmetico.
const SCROLL := "res://scenes/ScrollLevel.tscn"
var _scroll: Node


func before_each() -> void:
	Global.platforms = []
	Global.iniciado = false


func after_each() -> void:
	Global.platforms = []
	Global.iniciado = false


func _spawn(altura: int, scroll_ligado: bool = true) -> void:
	var sv := SubViewport.new()
	sv.size = Vector2i(180, altura)
	add_child_autofree(sv)
	_scroll = load(SCROLL).instantiate()
	sv.add_child(_scroll)
	if not scroll_ligado:
		_scroll.set_physics_process(false)
	await wait_process_frames(1)


func _linhas() -> Array:
	var out: Array = []
	for c in _scroll.running_platforms.get_children():
		if not c.is_queued_for_deletion():
			out.append(c)
	return out


func _ys_globais() -> Array[float]:
	var ys: Array[float] = []
	for c in _linhas():
		ys.append(c.position.y + _scroll.running_platforms.position.y)
	ys.sort()
	return ys


func _checa_altura(altura: int, esperado: int) -> void:
	await _spawn(altura, false)
	var ys := _ys_globais()
	var ys_regra := InitialRows.initial_row_ys(float(altura))
	assert_eq(_linhas().size(), esperado, "altura %d: esperado %d linhas filhas de running_platforms" % [altura, esperado])
	assert_eq(ys.size(), ys_regra.size(), "altura %d: contagem difere de initial_row_ys" % altura)
	for i in mini(ys.size(), ys_regra.size()):
		assert_almost_eq(ys[i], ys_regra[i], 0.001, "altura %d: y da linha %d fora de initial_row_ys" % [altura, i])


# C86
func test_linhas_iniciais_em_320() -> void:
	await _checa_altura(320, 7)


# C87
func test_linhas_iniciais_em_400() -> void:
	await _checa_altura(400, 9)


# C88
func test_linhas_iniciais_em_462() -> void:
	await _checa_altura(462, 10)


# C89
func test_sem_linha_duplicada_em_3s_de_scroll_em_400() -> void:
	await _spawn(400)
	Global.iniciado = true
	var menor := 1000.0
	for f in 190:
		await wait_physics_frames(1)
		var ys := _ys_globais()
		for i in range(1, ys.size()):
			menor = minf(menor, ys[i] - ys[i - 1])
	assert_gte(_scroll.position_scrolled, 50.0, "scroll de 3 s deveria passar de 50 px (position_scrolled=%s)" % _scroll.position_scrolled)
	assert_gte(menor, 49.5, "linhas duplicadas: menor distancia vertical entre linhas = %s (< 49.5)" % menor)


func _novos(antes: Array) -> Array[float]:
	var ys: Array[float] = []
	for c in _linhas():
		if not antes.has(c):
			ys.append(c.position.y + _scroll.running_platforms.position.y)
	ys.sort()
	ys.reverse()
	return ys


func _scrollar_ate(valor: float) -> void:
	_scroll.position_scrolled = valor
	_scroll.running_platforms.position.y = valor
	_scroll._physics_process(0.0)
	await wait_process_frames(1)


# C90
func test_gatilho_aritmetico_49_9_50_e_salto_de_120() -> void:
	await _spawn(400, false)
	Global.iniciado = true
	var antes := _linhas()
	await _scrollar_ate(49.9)
	assert_eq(_novos(antes).size(), 0, "position_scrolled 49.9 nao deveria gerar linha nova")
	await _scrollar_ate(50.0)
	var novos := _novos(antes)
	assert_eq(novos.size(), 1, "position_scrolled 50 deveria gerar exatamente 1 linha nova")
	if novos.size() == 1:
		assert_almost_eq(novos[0], -10.0, 0.001, "a linha nova em 50 deveria estar em y=-10")
	# salto de frame: de um scroll novo direto para 120 px
	_scroll.queue_free()
	await wait_process_frames(1)
	await _spawn(400, false)
	Global.iniciado = true
	var antes2 := _linhas()
	await _scrollar_ate(120.0)
	var novos2 := _novos(antes2)
	assert_eq(novos2.size(), 2, "salto de 120 px deveria gerar 2 linhas")
	if novos2.size() == 2:
		assert_almost_eq(novos2[0], -10.0, 0.001, "1a linha do salto em y=-10")
		assert_almost_eq(novos2[1], -60.0, 0.001, "2a linha do salto em y=-60 (-10 - 50*k)")


# C91
func test_nomes_e_flag_das_linhas() -> void:
	await _spawn(462, false)
	var com_flag := 0
	for c in _linhas():
		var y: float = c.position.y
		if y > 190.0:
			assert_eq(String(c.name), "Linha_%d" % int(y), "linha nova em y=%s deveria se chamar Linha_%d" % [y, int(y)])
			assert_false(c.garantir_cor_inicial, "linha nova em y=%s nao pode ter garantir_cor_inicial" % y)
			assert_eq(c.get_parent(), _scroll.running_platforms, "linha nova filha de running_platforms")
		if c.garantir_cor_inicial:
			com_flag += 1
			assert_almost_eq(y, 190.0, 0.001, "garantir_cor_inicial deve ficar em y=190")
			assert_eq(String(c.name), "RunningPlatforms", "no do .tscn em y=190 mantem o nome RunningPlatforms")
	assert_eq(com_flag, 1, "exatamente 1 linha com garantir_cor_inicial")
	var chamadas_rp := 0
	for c in _linhas():
		if String(c.name) == "RunningPlatforms":
			chamadas_rp += 1
	assert_eq(chamadas_rp, 1, "so o no do .tscn se chama RunningPlatforms")


# C92
func test_check_area_removida() -> void:
	await _spawn(400, false)
	assert_null(_scroll.get_node_or_null("CheckArea"), "CheckArea nao deveria existir")
	assert_false(_scroll.has_method("_on_CheckArea_area_exited"), "_on_CheckArea_area_exited nao deveria existir")
