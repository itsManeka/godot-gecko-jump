extends GutTest

# f411 T3: Stage real (ScrollLevel incluso) em SubViewport 180x320/400/462.
# (i) cor inicial na linha do gecko, (ii) fluxo sem duplicata nem faixa vazia, (iii) espacamento igual nas 3 alturas,
# e o orcamento de tempo da queda em 462 (roteiro de smoke).
# Os asserts ficam no corpo de cada teste (mensagem literal); os helpers so devolvem dados.
const STAGE := "res://scenes/Stage.tscn"
const PASSO := 1.0 / 60.0
const ALTURAS := [320, 400, 462]
var _sv: SubViewport
var _stage: Node
var _scroll: Node
var _p: Node


func before_each() -> void:
	Global.platforms = []
	Global.iniciado = false


func after_each() -> void:
	if is_instance_valid(_p):
		_p.end = true
	Global.platforms = []
	Global.iniciado = false


# Stage dentro de um SubViewport de altura dada; fisica do gecko e do scroll desligadas (testes dirigem o scroll a mao).
func _spawn(altura: int, fisica_ligada: bool = false) -> void:
	_sv = SubViewport.new()
	_sv.size = Vector2i(180, altura)
	add_child_autofree(_sv)
	_stage = load(STAGE).instantiate()
	_sv.add_child(_stage)
	_scroll = _stage.get_node("ScrollLevel")
	_p = _stage.get_node("Node2D/Player")
	if not fisica_ligada:
		_scroll.set_physics_process(false)
		_p.set_physics_process(false)
	await wait_process_frames(1)


func _liberar() -> void:
	if is_instance_valid(_p):
		_p.end = true
	_sv.queue_free()
	await wait_process_frames(2)


func _linhas() -> Array:
	var out: Array = []
	for c in _scroll.running_platforms.get_children():
		if not c.is_queued_for_deletion():
			out.append(c)
	return out


func _y_global(linha: Node) -> float:
	return linha.position.y + _scroll.running_platforms.position.y


func _ys_vivos() -> Array:
	var ys: Array = []
	for c in _linhas():
		ys.append(_y_global(c))
	ys.sort()
	return ys


func _gaps(ys: Array) -> Array:
	var out: Array = []
	for i in range(1, ys.size()):
		out.append(ys[i] - ys[i - 1])
	return out


# Dados dos geradores com garantir_cor_inicial: y, quantidade de estaticas e se alguma tem Enums.COR_INICIAL.
func _info_flag() -> Dictionary:
	var info := {"ys": [], "estaticas": [], "com_cor": []}
	for g in _linhas():
		if g.garantir_cor_inicial:
			var n := 0
			var com_cor := false
			for filho in g.get_children():
				if filho is Platform:
					n += 1
					if filho.color == Enums.COR_INICIAL:
						com_cor = true
			info["ys"].append(_y_global(g))
			info["estaticas"].append(n)
			info["com_cor"].append(com_cor)
	return info


# Scroll simulado: chama _physics_process do ScrollLevel a mao ate position_scrolled >= ate. Devolve o y global de cada
# linha nova logo que nasce (no frame em que o add_child adiado aconteceu) e os y vivos ordenados no fim.
func _simular_scroll(ate: float) -> Dictionary:
	Global.iniciado = true
	var novos_ys: Array = []
	var conhecidas: Array = _linhas()
	while _scroll.position_scrolled < ate:
		_scroll._physics_process(PASSO)
		await wait_process_frames(1)
		for c in _linhas():
			if not conhecidas.has(c):
				conhecidas.append(c)
				novos_ys.append(_y_global(c))
	return {"novos": novos_ys, "vivos": _ys_vivos()}


# C93
func test_cor_inicial_na_linha_do_gecko_em_180x320() -> void:
	await _spawn(320)
	var info := _info_flag()
	assert_eq(info["ys"].count(190.0), 1, "C93 180x320: exatamente 1 gerador garantir_cor_inicial, em y=190")
	assert_eq(info["estaticas"], [3], "C93 180x320: o gerador garantido tem 3 estaticas")
	assert_eq(info["com_cor"], [true], "C93 180x320: o gerador garantido tem uma estatica com Enums.COR_INICIAL")


# C94
func test_cor_inicial_na_linha_do_gecko_em_180x400() -> void:
	await _spawn(400)
	var info := _info_flag()
	assert_eq(info["ys"].count(190.0), 1, "C94 180x400: exatamente 1 gerador garantir_cor_inicial, em y=190")
	assert_eq(info["estaticas"], [3], "C94 180x400: o gerador garantido tem 3 estaticas")
	assert_eq(info["com_cor"], [true], "C94 180x400: o gerador garantido tem uma estatica com Enums.COR_INICIAL")


# C95
func test_cor_inicial_na_linha_do_gecko_em_180x462() -> void:
	await _spawn(462)
	var info := _info_flag()
	assert_eq(info["ys"].count(190.0), 1, "C95 180x462: exatamente 1 gerador garantir_cor_inicial, em y=190")
	assert_eq(info["estaticas"], [3], "C95 180x462: o gerador garantido tem 3 estaticas")
	assert_eq(info["com_cor"], [true], "C95 180x462: o gerador garantido tem uma estatica com Enums.COR_INICIAL")


# C96
func test_fluxo_sem_duplicata_nem_faixa_vazia_em_320() -> void:
	await _spawn(320)
	var r := await _simular_scroll(150.0)
	var novos: Array = r["novos"]
	var vivos: Array = r["vivos"]
	var gaps := _gaps(vivos)
	assert_eq(novos.size(), 3, "C96 180x320: 150 px de scroll geram exatamente 3 linhas novas")
	for y in novos:
		assert_almost_eq(y, -10.0, 0.001, "C96 180x320: a linha nova nasce em y=-10")
	assert_gte(vivos.size(), 7, "C96 180x320: ao menos 7 linhas vivas apos o scroll")
	for g in gaps:
		assert_almost_eq(g, 50.0, 0.5, "C96 180x320: y vivos consecutivos diferem de 50")
	assert_gte(gaps.min(), 49.5, "C96 180x320: nenhum par de linhas a menos de 50 px")


# C97
func test_fluxo_sem_duplicata_nem_faixa_vazia_em_400() -> void:
	await _spawn(400)
	var r := await _simular_scroll(150.0)
	var novos: Array = r["novos"]
	var vivos: Array = r["vivos"]
	var gaps := _gaps(vivos)
	assert_eq(novos.size(), 3, "C97 180x400: 150 px de scroll geram exatamente 3 linhas novas")
	for y in novos:
		assert_almost_eq(y, -10.0, 0.001, "C97 180x400: a linha nova nasce em y=-10")
	assert_gte(vivos.size(), 9, "C97 180x400: ao menos 9 linhas vivas apos o scroll")
	for g in gaps:
		assert_almost_eq(g, 50.0, 0.5, "C97 180x400: y vivos consecutivos diferem de 50")
	assert_gte(gaps.min(), 49.5, "C97 180x400: nenhum par de linhas a menos de 50 px")


# C98
func test_fluxo_sem_duplicata_nem_faixa_vazia_em_462() -> void:
	await _spawn(462)
	var r := await _simular_scroll(150.0)
	var novos: Array = r["novos"]
	var vivos: Array = r["vivos"]
	var gaps := _gaps(vivos)
	assert_eq(novos.size(), 3, "C98 180x462: 150 px de scroll geram exatamente 3 linhas novas")
	for y in novos:
		assert_almost_eq(y, -10.0, 0.001, "C98 180x462: a linha nova nasce em y=-10")
	assert_gte(vivos.size(), 10, "C98 180x462: ao menos 10 linhas vivas apos o scroll")
	for g in gaps:
		assert_almost_eq(g, 50.0, 0.5, "C98 180x462: y vivos consecutivos diferem de 50")
	assert_gte(gaps.min(), 49.5, "C98 180x462: nenhum par de linhas a menos de 50 px")


# C99
func test_espacamento_igual_nas_3_alturas() -> void:
	var iniciais: Array = []
	var apos_scroll: Array = []
	for altura in ALTURAS:
		await _spawn(altura)
		iniciais.append(_gaps(_ys_vivos()))
		var r := await _simular_scroll(150.0)
		apos_scroll.append(_gaps(r["vivos"]))
		await _liberar()
	var min_ini: int = mini(iniciais[0].size(), mini(iniciais[1].size(), iniciais[2].size()))
	var min_scroll: int = mini(apos_scroll[0].size(), mini(apos_scroll[1].size(), apos_scroll[2].size()))
	assert_gte(min_ini, 6, "C99: ao menos 6 diferencas consecutivas iniciais em todas as alturas")
	assert_gte(min_scroll, 6, "C99: ao menos 6 diferencas consecutivas apos o scroll em todas as alturas")
	for i in min_ini:
		assert_almost_eq(iniciais[0][i], 50.0, 0.001, "C99: diferenca inicial de 320 igual a 50")
		assert_almost_eq(iniciais[1][i], iniciais[0][i], 0.001, "C99: diferenca inicial de 400 igual a de 320")
		assert_almost_eq(iniciais[2][i], iniciais[0][i], 0.001, "C99: diferenca inicial de 462 igual a de 320")
	for i in min_scroll:
		assert_almost_eq(apos_scroll[1][i], apos_scroll[0][i], 0.001, "C99: diferenca apos scroll de 400 igual a de 320")
		assert_almost_eq(apos_scroll[2][i], apos_scroll[0][i], 0.001, "C99: diferenca apos scroll de 462 igual a de 320")


# C100: limite superior do orcamento de tempo da queda (roteiro de smoke), nao igualdade.
func test_queda_em_180x462_termina_em_900_frames_fisicos() -> void:
	await _spawn(462, true)
	_stage._on_Play_button_down()
	var frames := 0
	var y_final := 0.0
	while frames < 900:
		_p.can_change_color = false
		await wait_physics_frames(1)
		frames += 1
		if _p.is_end():
			y_final = _p.position.y
			break
	_stage.get_node("AnimationPlayer").stop()
	assert_true(_p.is_end(), "C100: o gecko parado deveria perder em ate 900 frames fisicos")
	assert_gte(y_final, 462.0, "C100: a derrota ocorre na borda inferior real (y >= 462)")
