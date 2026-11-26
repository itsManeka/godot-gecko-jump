extends GutTest

# f517 T3 (C485-C487): ScrollLevel guarda a seed da partida (membro `semente`, setado antes de entrar
# na arvore) e injeta em cada linha os rngs do seu indice (RowSeed, canais layout/cor_movel) ANTES do
# add_child/_ready dela — as 5 do .tscn via _enter_tree (D1), as extras de _ready e as de
# create_new_running_platform. Sem semente nenhuma linha recebe rng (sorteio global como hoje).
# O determinismo ponta a ponta entre geracoes e do test_scroll_level_seed.gd (T5).
const SCROLL := "res://scenes/ScrollLevel.tscn"
const SEMENTE := 4242
const N_SORTEIOS := 8

var _scroll: Node
# [linha, rng, rng_cor_movel] no instante do _ready de cada linha do .tscn: a injecao tem de ja ter
# acontecido nesse momento (o _enter_tree do ScrollLevel roda antes do _ready de qualquer filho)
var _capturados_no_ready: Array = []


func before_each() -> void:
	Global.platforms = []
	Global.iniciado = false
	_capturados_no_ready = []


func after_each() -> void:
	Global.platforms = []
	Global.iniciado = false


# Montagem do modelo de test_scroll_level_linhas_iniciais.gd (SubViewport + instantiate + add_child),
# com o contrato D1: quem injeta a seed instancia, seta `semente` e so entao adiciona a arvore.
# Scroll desligado: as linhas do scroll nascem pelo gatilho manual do _scrollar_ate.
func _spawn(altura: int, semente = null) -> void:
	var sv := SubViewport.new()
	sv.size = Vector2i(360, altura)
	add_child_autofree(sv)
	_scroll = load(SCROLL).instantiate()
	if semente != null:
		_scroll.semente = semente
	_escutar_ready_das_linhas_do_tscn()
	sv.add_child(_scroll)
	_scroll.set_physics_process(false)
	await wait_process_frames(1)


# Captura rng/rng_cor_movel no instante do _ready das 5 linhas do .tscn: o sinal e conectado antes do
# add_child, entao dispara dentro do add_child, antes de o _spawn esperar frames
func _escutar_ready_das_linhas_do_tscn() -> void:
	for linha in _scroll.get_node("RunningPlatforms").get_children():
		linha.ready.connect(_capturar_no_ready.bind(linha))


func _capturar_no_ready(linha: Node) -> void:
	_capturados_no_ready.append([linha, linha.rng, linha.rng_cor_movel])


func _linhas() -> Array:
	var out: Array = []
	for c in _scroll.running_platforms.get_children():
		if not c.is_queued_for_deletion():
			out.append(c)
	return out


# Scroll manual dirigido como o test_scroll_level_linhas_iniciais.gd (C90): exige Global.iniciado
func _scrollar_ate(valor: float) -> void:
	_scroll.position_scrolled = valor
	_scroll.running_platforms.position.y = valor
	_scroll._physics_process(0.0)
	await wait_process_frames(1)


# Espiao no RowSeed: sequencia fresca de randi() da (semente, indice)
func _sequencia(rng: RandomNumberGenerator, n: int) -> Array:
	var out: Array = []
	for i in n:
		out.append(rng.randi())
	return out


# C485: sem `semente`, `rng` e `rng_cor_movel` null nas linhas do .tscn, extras de _ready e do scroll
func test_sem_semente_nenhuma_linha_recebe_rng() -> void:
	await _spawn(800, null)
	Global.iniciado = true
	await _scrollar_ate(240.0)
	var linhas := _linhas()
	assert_gt(linhas.size(), 9, "altura 800 + scroll de 240 deveria ter linhas alem das 9 iniciais")
	for linha in linhas:
		assert_null(linha.rng, "sem semente a linha %s nao deveria receber rng" % linha.name)
		assert_null(linha.rng_cor_movel, "sem semente a linha %s nao deveria receber rng_cor_movel" % linha.name)


# C486: com `semente`, toda linha (5 do .tscn via _enter_tree, extras de _ready, create_new_running_platform)
# tem rng e rng_cor_movel nao-null ANTES do _ready, distintos por indice (seed do RowSeed do seu y local)
func test_com_semente_toda_linha_tem_rng_e_rng_cor_movel_antes_do_ready() -> void:
	await _spawn(800, SEMENTE)
	Global.iniciado = true
	await _scrollar_ate(240.0)
	assert_eq(_capturados_no_ready.size(), 5, "as 5 linhas do .tscn deveriam ter passado pelo _ready")
	for captura in _capturados_no_ready:
		assert_not_null(captura[1], "rng deveria existir antes do _ready da linha do .tscn (%s)" % captura[0].name)
		assert_not_null(captura[2], "rng_cor_movel deveria existir antes do _ready da linha do .tscn (%s)" % captura[0].name)
	var linhas := _linhas()
	assert_gt(linhas.size(), 9, "altura 800 + scroll de 240 deveria ter linhas alem das 9 iniciais")
	for linha in linhas:
		var indice: int = RowSeed.indice_do_y(linha.position.y)
		assert_not_null(linha.rng, "com semente a linha %s deveria ter rng" % linha.name)
		assert_not_null(linha.rng_cor_movel, "com semente a linha %s deveria ter rng_cor_movel" % linha.name)
		assert_eq(
			(linha.rng.seed if linha.rng != null else null),
			RowSeed.rng_layout(SEMENTE, indice).seed,
			"rng da linha %s (indice %s) deveria ser o canal layout do RowSeed" % [linha.name, indice]
		)
		assert_eq(
			(linha.rng_cor_movel.seed if linha.rng_cor_movel != null else null),
			RowSeed.rng_cor_movel(SEMENTE, indice).seed,
			"rng_cor_movel da linha %s (indice %s) deveria ser o canal cor_movel do RowSeed" % [linha.name, indice]
		)
	# distintos por indice: y distintos -> indices distintos, nenhuma dupla com a mesma seed
	for i in linhas.size():
		for j in range(i + 1, linhas.size()):
			assert_ne(
				(linhas[i].rng.seed if linhas[i].rng != null else null),
				(linhas[j].rng.seed if linhas[j].rng != null else null),
				"duas linhas receberam a mesma seed de layout: indices distintos deveriam divergir"
			)
			assert_ne(
				(linhas[i].rng_cor_movel.seed if linhas[i].rng_cor_movel != null else null),
				(linhas[j].rng_cor_movel.seed if linhas[j].rng_cor_movel != null else null),
				"duas linhas receberam a mesma seed de cor_movel: indices distintos deveriam divergir"
			)


# C487: wiring — duas linhas com y local distintos carregam rngs de sequencias distintas (espiao no
# RowSeed), e o ramo NAN de create_new_running_platform usa o indice do y local arredondado
func test_duas_linhas_com_y_distintos_tem_rngs_distintos_e_ramo_nan_arredonda_indice() -> void:
	await _spawn(640, SEMENTE)
	var por_indice := {}
	for linha in _linhas():
		por_indice[RowSeed.indice_do_y(linha.position.y)] = linha
	var topo = por_indice[0]
	var segunda = por_indice[-1]
	assert_ne(topo.rng.seed, segunda.rng.seed, "linhas de y -20 e 80 (indices 0 e -1) deveriam ter rngs distintos")
	assert_eq(topo.rng.seed, RowSeed.rng_layout(SEMENTE, 0).seed, "linha y -20 deveria carregar o rng do canal layout do indice 0")
	assert_eq(segunda.rng.seed, RowSeed.rng_layout(SEMENTE, -1).seed, "linha y 80 deveria carregar o rng do canal layout do indice -1")
	assert_ne(
		_sequencia(RowSeed.rng_layout(SEMENTE, 0), N_SORTEIOS),
		_sequencia(RowSeed.rng_layout(SEMENTE, -1), N_SORTEIOS),
		"indices 0 e -1 do canal layout deveriam gerar sequencias distintas"
	)
	assert_ne(
		_sequencia(RowSeed.rng_cor_movel(SEMENTE, 0), N_SORTEIOS),
		_sequencia(RowSeed.rng_cor_movel(SEMENTE, -1), N_SORTEIOS),
		"indices 0 e -1 do canal cor_movel deveriam gerar sequencias distintas"
	)
	# ramo NAN: sem argumento a linha nasce em y local Y_TOPO - position_scrolled; com 250 px de
	# scroll, y local -270 (global -20, dentro do viewport) e indice roundi(250/100) = 3 — 2.5
	# arredonda para 3 (away from zero); truncar daria 2 e outra seed
	Global.iniciado = true
	await _scrollar_ate(250.0)
	var antes := _linhas()
	_scroll.create_new_running_platform()
	await wait_process_frames(1)
	var novas: Array = []
	for c in _linhas():
		if not antes.has(c):
			novas.append(c)
	assert_eq(novas.size(), 1, "create_new_running_platform sem argumento deveria criar exatamente 1 linha")
	if novas.size() == 1:
		assert_almost_eq(novas[0].position.y, -270.0, 0.001, "ramo NAN: y local deveria ser Y_TOPO - position_scrolled (-270)")
		assert_not_null(novas[0].rng, "linha do ramo NAN deveria receber rng")
		assert_not_null(novas[0].rng_cor_movel, "linha do ramo NAN deveria receber rng_cor_movel")
		assert_eq(
			novas[0].rng.seed,
			RowSeed.rng_layout(SEMENTE, 3).seed,
			"ramo NAN com 250 px de scroll deveria usar o indice arredondado 3, nao o truncado 2"
		)
		assert_eq(
			(novas[0].rng_cor_movel.seed if novas[0].rng_cor_movel != null else null),
			RowSeed.rng_cor_movel(SEMENTE, 3).seed,
			"ramo NAN: rng_cor_movel deveria usar o indice arredondado 3"
		)
