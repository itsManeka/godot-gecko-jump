extends GutTest

# Simulacao pura (sem cena) da regra de cor alcancavel: 200 linhas, seed fixa.
# Linhas iniciais estaticas (StaticPlatformColors) e depois linhas moveis (ReachableColors.cor_plataforma_movel).
# A cada pouso o gecko sorteia a cor entre as da linha de cima (coleta + escolher_cor_gecko).

const SEED := 20261110
const LINHAS := 200
const LARGURA := 180.0
const ALTURA_TELA := 320.0
const Y_BASE := 10000.0
# Linhas sem nenhuma plataforma visivel (fallback D1) na seed fixa: nao entram na asseveracao de C131.
const LINHAS_SEM_VISIVEL_ESPERADAS := 31


func _visivel(x: float) -> bool:
	return x >= 0.0 and x <= LARGURA


func _gerar_linha_movel(y: float, cor_gecko: int, rng: RandomNumberGenerator) -> Dictionary:
	var para_esquerda: bool = rng.randi() % 2 == 0
	var spawn_x: float = LARGURA + MovingRowFill.SEMI_PLATAFORMA if para_esquerda else -MovingRowFill.SEMI_PLATAFORMA
	var xs: Array = [spawn_x]
	xs.append_array(MovingRowFill.initial_xs(spawn_x, para_esquerda, LARGURA))
	var anteriores: Array = []
	var plataformas: Array = []
	for x in xs:
		var cor: int = ReachableColors.cor_plataforma_movel(cor_gecko, anteriores, rng)
		anteriores.append(cor)
		plataformas.append({"x": x, "cor": cor})
	return {"y": y, "tipo": "movel", "plataformas": plataformas}


# Linha toda fora da tela (fallback D1 no pouso anterior).
func _gerar_linha_fora(y: float, rng: RandomNumberGenerator) -> Dictionary:
	var plataformas: Array = [
		{"x": -60.0, "cor": Enums.get_random_color(rng)},
		{"x": LARGURA + 60.0, "cor": Enums.get_random_color(rng)},
	]
	return {"y": y, "tipo": "fora", "plataformas": plataformas}


func _gerar_linha_estatica(y: float, rng: RandomNumberGenerator) -> Dictionary:
	var cores: Array = StaticPlatformColors.sortear(Enums.COR_INICIAL, rng)
	var xs: Array = [30.0, 90.0, 150.0]
	var plataformas: Array = []
	for i in xs.size():
		plataformas.append({"x": xs[i], "cor": cores[i]})
	return {"y": y, "tipo": "estatica", "plataformas": plataformas}


func _cores_visiveis(linha: Dictionary) -> Array:
	var cores: Array = []
	for p in linha["plataformas"]:
		if _visivel(p["x"]):
			cores.append(p["cor"])
	return cores


func _entradas(linhas: Array) -> Array:
	var entradas: Array = []
	for linha in linhas:
		for p in linha["plataformas"]:
			entradas.append({"y": linha["y"], "x": p["x"], "cor": p["cor"]})
	return entradas


# Devolve {linhas, eventos, cores}. Evento = um pouso na linha g: cor antes/depois e as cores visiveis da linha g+1.
func _simular(seed_valor: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_valor
	var cor: int = Enums.COR_INICIAL
	var linhas: Array = []
	var iniciais: int = InitialRows.initial_row_ys(ALTURA_TELA).size()
	for i in iniciais:
		linhas.append(_gerar_linha_estatica(Y_BASE - InitialRows.ESPACAMENTO * i, rng))
	var eventos: Array = []
	var cores: Array = [cor]
	for g in range(LINHAS - 1):
		var cor_antes: int = cor
		while linhas.size() <= g + 1:
			var y: float = Y_BASE - InitialRows.ESPACAMENTO * linhas.size()
			if rng.randi() % 8 == 0:
				linhas.append(_gerar_linha_fora(y, rng))
			else:
				linhas.append(_gerar_linha_movel(y, cor_antes, rng))
		var candidatas: Array = ReachableColors.coletar_cores_linha_acima(
			_entradas(linhas), float(linhas[g]["y"]), LARGURA
		)
		cor = ReachableColors.escolher_cor_gecko(candidatas, rng)
		cores.append(cor)
		eventos.append(
			{
				"g": g,
				"antes": cor_antes,
				"depois": cor,
				"acima": _cores_visiveis(linhas[g + 1]),
				"tipo_acima": linhas[g + 1]["tipo"],
			}
		)
	while linhas.size() < LINHAS:
		linhas.append(_gerar_linha_movel(Y_BASE - InitialRows.ESPACAMENTO * linhas.size(), cor, rng))
	return {"linhas": linhas, "eventos": eventos, "cores": cores}


func test_c131_toda_linha_com_visivel_tem_a_cor_vigente() -> void:
	var sim: Dictionary = _simular(SEED)
	assert_eq(sim["linhas"].size(), LINHAS, "a simulacao gera 200 linhas")
	var sem_visivel: int = 0
	var falhas: Array = []
	var verificadas: int = 0
	for e in sim["eventos"]:
		if e["acima"].is_empty():
			sem_visivel += 1
			continue
		verificadas += 1
		if not e["acima"].has(e["depois"]):
			falhas.append(e["g"])
	assert_eq(sem_visivel, LINHAS_SEM_VISIVEL_ESPERADAS, "contagem de linhas sem plataforma visivel (fallback) e fixa na seed")
	assert_gt(verificadas, 150, "a maior parte das linhas entra na asseveracao")
	assert_eq(falhas.size(), 0, "toda linha de cima com plataforma visivel tem a cor vigente do gecko")


func test_c132_linha_apos_pouso_com_cor_nova_contem_a_cor_nova() -> void:
	var sim: Dictionary = _simular(SEED)
	var trocas: int = 0
	var falhas: Array = []
	for e in sim["eventos"]:
		if e["antes"] == e["depois"] or e["acima"].is_empty():
			continue
		trocas += 1
		if not e["acima"].has(e["depois"]):
			falhas.append(e["g"])
	assert_gt(trocas, 0, "houve pousos em que a cor mudou")
	assert_eq(falhas.size(), 0, "apos trocar de cor a linha de cima ainda contem a cor nova")


func test_c133_inicio_da_partida_cor_inicial_nas_linhas_iniciais() -> void:
	var sim: Dictionary = _simular(SEED)
	assert_eq(sim["cores"][0], Enums.COR_INICIAL, "a partida comeca com a cor inicial")
	var iniciais: int = InitialRows.initial_row_ys(ALTURA_TELA).size()
	assert_gt(iniciais, 0, "ha linhas iniciais")
	var sem_cor_inicial: Array = []
	for i in iniciais:
		var linha: Dictionary = sim["linhas"][i]
		if linha["tipo"] != "estatica" or not _cores_visiveis(linha).has(Enums.COR_INICIAL):
			sem_cor_inicial.append(i)
	assert_eq(sem_cor_inicial, [], "toda linha inicial e estatica e tem a cor inicial")


func test_c134_mesma_seed_mesma_sequencia() -> void:
	var a: Dictionary = _simular(SEED)
	var b: Dictionary = _simular(SEED)
	var outra: Dictionary = _simular(SEED + 1)
	assert_eq(a["cores"].size(), LINHAS, "uma cor por linha")
	assert_eq(a["cores"], b["cores"], "mesma seed gera a mesma sequencia de cores")
	assert_eq(a["linhas"], b["linhas"], "mesma seed gera as mesmas linhas")
	assert_ne(a["cores"], outra["cores"], "seed diferente gera outra sequencia")


func test_c135_mistura_estaticas_e_moveis_atendidas_pela_coleta() -> void:
	var sim: Dictionary = _simular(SEED)
	var estaticas: int = 0
	var moveis: int = 0
	for linha in sim["linhas"]:
		if linha["tipo"] == "estatica":
			estaticas += 1
		elif linha["tipo"] == "movel":
			moveis += 1
	assert_gt(estaticas, 0, "ha linha estatica na seed")
	assert_gt(moveis, 0, "ha linha movel na seed")
	var pousos_em_estatica: int = 0
	var falhas: Array = []
	for e in sim["eventos"]:
		if e["tipo_acima"] != "estatica":
			continue
		pousos_em_estatica += 1
		if not e["acima"].has(e["depois"]):
			falhas.append(e["g"])
	assert_gt(pousos_em_estatica, 0, "ha pouso com linha estatica acima")
	assert_eq(falhas.size(), 0, "linha estatica de cima tem a cor vigente so pela coleta do pouso")
