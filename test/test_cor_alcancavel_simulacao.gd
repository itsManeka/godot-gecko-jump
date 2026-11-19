extends GutTest

# Simulacao pura (sem cena) da regra de cor alcancavel: 200 linhas, seed fixa.
# Linhas iniciais estaticas (StaticPlatformColors) e depois linhas moveis geradas como o jogo
# (RunningPlatforms.preencher_linha: MovingRowFill.initial_xs + plataforma do spawn; cores por
# ReachableColors.cor_plataforma_movel com a cor do gecko vigente no instante de cada criacao e historico por linha).
# Apos cada pouso, as linhas vivas criam mais uma plataforma no spawn (new_platform) com a cor do gecko daquele instante.
# A cada pouso o gecko sorteia a cor entre as da linha de cima (coleta + escolher_cor_gecko).

const SEED := 20261110
const LINHAS := 200
const LARGURA := 180.0
const ALTURA_TELA := 320.0
const Y_BASE := 10000.0
# Quantos pousos depois do nascimento uma linha movel ainda cria plataformas no spawn. Valor de modelagem (nao medido no
# jogo); os x criados nao andam depois de criados. C131/C135 medem a regra do pouso; so o C136 mede a janela K das moveis.
const POUSOS_COM_SPAWN := 4
# Deslocamento da seed do rng dedicado que sorteia quem cai (nao mexe na sequencia do rng principal).
const SEED_CAI_OFFSET := 7919
# Fracao forcada em copia da curva: os testes de mistura nao dependem do valor de producao do .tres.
const FRACAO_MISTURA := 0.5


func _visivel(x: float) -> bool:
	return x >= 0.0 and x <= LARGURA


func _y_da_linha(indice: int) -> float:
	return Y_BASE - InitialRows.ESPACAMENTO * indice


func _gerar_linha_estatica(y: float, rng: RandomNumberGenerator) -> Dictionary:
	var cores: Array = StaticPlatformColors.sortear(Enums.COR_INICIAL, rng)
	var xs: Array = [30.0, 90.0, 150.0]
	var plataformas: Array = []
	for i in xs.size():
		plataformas.append({"x": xs[i], "cor": cores[i]})
	return {"y": y, "tipo": "estatica", "plataformas": plataformas, "historico": []}


# Cria 1 plataforma do historico da linha movel com a cor do gecko vigente agora; devolve a cor.
func _criar_movel(
	linha: Dictionary, cor_gecko: int, rng: RandomNumberGenerator, k: int = DifficultyStage.K_PADRAO
) -> int:
	var anteriores: Array = []
	for h in linha["historico"]:
		anteriores.append(h["cor"])
	var cor: int = ReachableColors.cor_plataforma_movel(cor_gecko, anteriores, rng, k)
	linha["historico"].append({"cor": cor, "gecko": cor_gecko})
	return cor


# Como RunningPlatforms.preencher_linha: x pre-colocados (do mais proximo do spawn ao mais distante) e depois o spawn.
func _gerar_linha_movel(y: float, cor_gecko: int, rng: RandomNumberGenerator) -> Dictionary:
	var para_esquerda: bool = rng.randi() % 2 == 0
	var spawn_x: float = LARGURA + MovingRowFill.SEMI_PLATAFORMA if para_esquerda else -MovingRowFill.SEMI_PLATAFORMA
	var linha: Dictionary = {"y": y, "tipo": "movel", "plataformas": [], "historico": []}
	for x in MovingRowFill.initial_xs(spawn_x, para_esquerda, LARGURA):
		linha["plataformas"].append({"x": x, "cor": _criar_movel(linha, cor_gecko, rng)})
	_criar_movel(linha, cor_gecko, rng)
	return linha


# Linha nova de uma partida num estagio: o tipo sai de PlatformTypePicker com a proporcao do snapshot; estatica tem cores
# aleatorias (como o gerador, sem a garantia da cor inicial); movel usa initial_xs com a speed e o K do snapshot.
# Guarda {xs, spawn_x} da movel para conferir o espacamento.
func _gerar_linha_do_snapshot(
	y: float, cor_gecko: int, rng: RandomNumberGenerator, snap: DifficultySnapshot
) -> Dictionary:
	var tipo: int = PlatformTypePicker.resolve(Enums.PLATFORM_TYPE.RANDOM_ALL, rng, snap.get_proporcao_estaticas())
	if tipo == Enums.PLATFORM_TYPE.STATIC:
		var plataformas: Array = []
		for x in [30.0, 90.0, 150.0]:
			plataformas.append({"x": x, "cor": Enums.get_random_color(rng)})
		return {"y": y, "tipo": "estatica", "plataformas": plataformas, "historico": []}
	var para_esquerda: bool = tipo == Enums.PLATFORM_TYPE.MOVE_TO_LEFT
	var spawn_x: float = LARGURA + MovingRowFill.SEMI_PLATAFORMA if para_esquerda else -MovingRowFill.SEMI_PLATAFORMA
	var xs: Array = MovingRowFill.initial_xs(spawn_x, para_esquerda, LARGURA, snap.get_speed_moveis())
	var linha: Dictionary = {
		"y": y, "tipo": "movel", "plataformas": [], "historico": [], "xs": xs, "spawn_x": spawn_x
	}
	for x in xs:
		linha["plataformas"].append({"x": x, "cor": _criar_movel(linha, cor_gecko, rng, snap.get_k())})
	_criar_movel(linha, cor_gecko, rng, snap.get_k())
	return linha


func _nova_linha(y: float, cor_gecko: int, rng: RandomNumberGenerator, snap: DifficultySnapshot) -> Dictionary:
	if snap == null:
		return _gerar_linha_movel(y, cor_gecko, rng)
	return _gerar_linha_do_snapshot(y, cor_gecko, rng, snap)


# Recontagem independente da escolha: varre as plataformas geradas de TODAS as linhas e guarda as visiveis da linha em y.
func _cores_recontadas(linhas: Array, y: float) -> Array:
	var cores: Array = []
	for linha in linhas:
		if absf(float(linha["y"]) - y) > 1.0:
			continue
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


func _total_plataformas(linhas: Array) -> int:
	var total: int = 0
	for linha in linhas:
		total += linha["plataformas"].size()
	return total


# Modelo (nao exercita RunningPlatforms; o sorteio real fica coberto nos testes do gerador): sorteia por plataforma
# quem cai, com rng dedicado (a sequencia do rng principal nao muda). Fracao >= 1 ou <= 0 nao consome rng.
func _sorteia_cai(fracao: float, rng_cai: RandomNumberGenerator) -> bool:
	if fracao >= 1.0:
		return true
	if fracao <= 0.0:
		return false
	return rng_cai.randf() < fracao


# Marca "cai" em cada plataforma da linha (o campo viaja no dicionario, junto de x/cor).
func _marcar_quem_cai(linha: Dictionary, snap: DifficultySnapshot, rng_cai: RandomNumberGenerator) -> void:
	var fracao: float = DifficultyStage.PROPORCAO_QUE_CAEM_PADRAO if snap == null else snap.get_proporcao_que_caem()
	for p in linha["plataformas"]:
		p["cai"] = _sorteia_cai(fracao, rng_cai)


# Copia do snapshot com a fracao forcada (o snapshot nao tem setters; nao le o valor de producao do .tres).
func _com_fracao(snap: DifficultySnapshot, fracao: float) -> DifficultySnapshot:
	return DifficultySnapshot.new(
		snap.get_scroll(),
		snap.get_speed_moveis(),
		snap.get_k(),
		snap.get_proporcao_estaticas(),
		snap.get_mecanicas(),
		snap.get_largura_plataforma(),
		snap.get_atraso_desmoronar(),
		snap.get_proporcao_cicladoras(),
		snap.get_periodo_ciclo(),
		snap.get_amplitude_movimento(),
		snap.get_periodo_movimento(),
		snap.get_proporcao_oscilantes(),
		snap.get_proporcao_vai_e_vem(),
		snap.get_variacao_speed_linha(),
		snap.get_proporcao_piscantes(),
		snap.get_duracao_visivel(),
		snap.get_duracao_invisivel(),
		snap.get_aviso_pisca(),
		fracao
	)


# Indice da 1a plataforma visivel da cor do pouso (a que o gecko pisou); -1 se nao ha.
func _indice_da_plataforma_do_pouso(linha: Dictionary, cor_pouso: int) -> int:
	for i in linha["plataformas"].size():
		var p: Dictionary = linha["plataformas"][i]
		if p["cor"] == cor_pouso and _visivel(p["x"]):
			return i
	return -1


# Remove a plataforma pisada so se ela foi marcada como "cai"; devolve se removeu.
func _remover_plataforma_do_pouso(linha: Dictionary, cor_pouso: int) -> bool:
	var i: int = _indice_da_plataforma_do_pouso(linha, cor_pouso)
	if i < 0 or not linha["plataformas"][i]["cai"]:
		return false
	linha["plataformas"].remove_at(i)
	return true


# Devolve {linhas, eventos, cores}. Evento = um pouso na linha g: cor antes/depois, a coleta usada na escolha e as
# cores visiveis da linha g+1 recontadas das plataformas geradas.
func _simular(seed_valor: int, snap: DifficultySnapshot = null, desmoronar: bool = false) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_valor
	var k: int = DifficultyStage.K_PADRAO if snap == null else snap.get_k()
	var cor: int = Enums.COR_INICIAL
	var rng_cai := RandomNumberGenerator.new()
	rng_cai.seed = seed_valor + SEED_CAI_OFFSET
	var linhas: Array = []
	var iniciais: int = InitialRows.initial_row_ys(ALTURA_TELA).size()
	for i in iniciais:
		linhas.append(_gerar_linha_estatica(_y_da_linha(i), rng))
		_marcar_quem_cai(linhas[i], snap, rng_cai)
	var eventos: Array = []
	var cores: Array = [cor]
	for g in range(LINHAS - 1):
		var cor_antes: int = cor
		while linhas.size() <= g + 1:
			linhas.append(_nova_linha(_y_da_linha(linhas.size()), cor_antes, rng, snap))
			_marcar_quem_cai(linhas[linhas.size() - 1], snap, rng_cai)
		var candidatas: Array = ReachableColors.coletar_cores_linha_acima(
			_entradas(linhas), float(linhas[g]["y"]), LARGURA
		)
		cor = ReachableColors.escolher_cor_gecko(candidatas, rng)
		cores.append(cor)
		var evento: Dictionary = {
			"g": g,
			"antes": cor_antes,
			"depois": cor,
			"candidatas": candidatas,
			"acima": _cores_recontadas(linhas, float(linhas[g + 1]["y"])),
			"tipo_acima": linhas[g + 1]["tipo"],
		}
		if desmoronar:
			# Plataforma do pouso (cor antes do pouso) desmorona depois da coleta; so ela sai da linha g.
			var total_antes: int = _total_plataformas(linhas)
			var indice_pisada: int = _indice_da_plataforma_do_pouso(linhas[g], cor_antes)
			evento["pisada_cai"] = indice_pisada >= 0 and linhas[g]["plataformas"][indice_pisada]["cai"]
			evento["pisada_nao_cai"] = indice_pisada >= 0 and not evento["pisada_cai"]
			var removida: bool = _remover_plataforma_do_pouso(linhas[g], cor_antes)
			evento["removida"] = removida
			evento["removidas_total"] = total_antes - _total_plataformas(linhas)
			evento["acima_pos"] = _cores_recontadas(linhas, float(linhas[g + 1]["y"]))
		eventos.append(evento)
		# Linhas moveis vivas criam outra plataforma no spawn com a cor do gecko vigente (nova cor do pouso).
		for i in range(maxi(0, g + 2 - POUSOS_COM_SPAWN), g + 2):
			if linhas[i]["tipo"] == "movel":
				_criar_movel(linhas[i], cor, rng, k)
	while linhas.size() < LINHAS:
		linhas.append(_nova_linha(_y_da_linha(linhas.size()), cor, rng, snap))
	return {"linhas": linhas, "eventos": eventos, "cores": cores}


func test_c131_toda_linha_com_visivel_tem_a_cor_vigente() -> void:
	var sim: Dictionary = _simular(SEED)
	assert_eq(sim["linhas"].size(), LINHAS, "a simulacao gera 200 linhas")
	var sem_visivel: int = 0
	var falhas: Array = []
	var coleta_divergente: Array = []
	var verificadas: int = 0
	for e in sim["eventos"]:
		if e["acima"].is_empty():
			sem_visivel += 1
			continue
		verificadas += 1
		var coletadas: Array = e["candidatas"].duplicate()
		var recontadas: Array = e["acima"].duplicate()
		coletadas.sort()
		recontadas.sort()
		if coletadas != recontadas:
			coleta_divergente.append(e["g"])
		if not e["acima"].has(e["depois"]):
			falhas.append(e["g"])
	# No modelo do jogo toda linha (estatica ou movel) nasce com plataforma visivel; o fallback D1 (nenhuma visivel)
	# nao ocorre aqui e tem teste proprio de ReachableColors.
	assert_eq(sem_visivel, 0, "nenhuma linha do modelo do jogo nasce sem plataforma visivel")
	assert_eq(verificadas, LINHAS - 1, "todo pouso entra na asseveracao")
	assert_eq(coleta_divergente, [], "a coleta do pouso bate com a recontagem independente das plataformas geradas")
	assert_eq(falhas.size(), 0, "toda linha de cima com plataforma visivel tem a cor vigente do gecko")


func test_c132_linha_apos_pouso_com_cor_nova_contem_a_cor_nova() -> void:
	var sim: Dictionary = _simular(SEED)
	var trocas: int = 0
	var falhas: Array = []
	for e in sim["eventos"]:
		if e["antes"] == e["depois"]:
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
		if linha["tipo"] != "estatica" or not _cores_recontadas(sim["linhas"], linha["y"]).has(Enums.COR_INICIAL):
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


func test_c136_janela_de_k_moveis_tem_a_cor_vigente_no_spawn() -> void:
	var sim: Dictionary = _simular(SEED)
	var janelas: int = 0
	var linhas_com_spawn_posterior: int = 0
	var linhas_com_gecko_variado: int = 0
	var falhas: Array = []
	for idx in sim["linhas"].size():
		var linha: Dictionary = sim["linhas"][idx]
		if linha["tipo"] != "movel":
			continue
		var hist: Array = linha["historico"]
		if hist.size() > linha["plataformas"].size() + 1:
			linhas_com_spawn_posterior += 1
		var geckos: Dictionary = {}
		for i in hist.size():
			geckos[hist[i]["gecko"]] = true
			janelas += 1
			var tem: bool = false
			for j in range(maxi(0, i - DifficultyStage.K_PADRAO + 1), i + 1):
				if hist[j]["cor"] == hist[i]["gecko"]:
					tem = true
			if not tem:
				falhas.append("linha %d plataforma %d" % [idx, i])
		if geckos.size() > 1:
			linhas_com_gecko_variado += 1
	assert_gt(janelas, 0, "ha janelas de moveis para conferir")
	assert_gt(linhas_com_spawn_posterior, 0, "ha linha movel com spawn depois do preenchimento inicial")
	assert_gt(linhas_com_gecko_variado, 0, "a cor do gecko vigente muda entre os spawns de uma mesma linha")
	assert_eq(falhas.size(), 0, "toda janela de K moveis consecutivas tem a cor do gecko vigente no spawn")


# --- f458 T10: alcancabilidade por estagio e no teto --------------------------------------------------------------
# Snapshots lidos do .tres de producao (inicio e fim de cada estagio e teto). A simulacao usa o codigo real
# (PlatformTypePicker com a proporcao, MovingRowFill.initial_xs com a speed, ReachableColors com o K do snapshot).
# Limites aprovados do teto (04-plan, proposta de teto): decisao de projeto, nao copia do .tres. Reduzir o teto no
# .tres continua passando; subir alem destes exige decidir aqui.
const CURVA_PATH := "res://ressources/curva_dificuldade.tres"
const EPS_PROGRESSO := 0.001
const SEEDS_ESTAGIO := [20261110, 20261111, 20261112]
const K_LIMITE := 6
const SPEED_LIMITE := 100.0


func _casos() -> Array:
	var curva := load(CURVA_PATH) as DifficultyCurve
	var casos: Array = []
	for i in range(curva.estagios.size()):
		var p_ini: float = curva.estagios[i].progresso_inicio
		casos.append(["E%d inicio" % i, curva.avaliar(p_ini * curva.pontos_plato, 0.0)])
		if i + 1 < curva.estagios.size():
			var p_fim: float = curva.estagios[i + 1].progresso_inicio - EPS_PROGRESSO
			casos.append(["E%d fim" % i, curva.avaliar(p_fim * curva.pontos_plato, 0.0)])
	casos.append(["teto", curva.avaliar(curva.pontos_plato, curva.segundos_plato)])
	return casos


func test_c177_estagios_e_teto_nenhuma_janela_de_k_sem_a_cor_do_gecko() -> void:
	var casos: Array = _casos()
	assert_eq(casos.size(), 8, "4 estagios: 3 inicios + 3 fins + inicio do teto + teto")
	for caso in casos:
		var snap: DifficultySnapshot = caso[1]
		var k: int = snap.get_k()
		var esp: float = MovingRowFill.espacamento(snap.get_speed_moveis())
		var janelas: int = 0
		var moveis: int = 0
		var estaticas: int = 0
		var falhas_janela: Array = []
		var falhas_espacamento: Array = []
		var falhas_cor: Array = []
		for seed_valor in SEEDS_ESTAGIO:
			var sim: Dictionary = _simular(seed_valor, snap)
			for e in sim["eventos"]:
				if e["acima"].is_empty() or not e["acima"].has(e["depois"]):
					falhas_cor.append([seed_valor, e["g"]])
			for idx in sim["linhas"].size():
				var linha: Dictionary = sim["linhas"][idx]
				if linha["tipo"] == "estatica":
					estaticas += 1
					continue
				moveis += 1
				var ant: float = linha["spawn_x"]
				for x in linha["xs"]:
					if absf(absf(float(x) - ant) - esp) > 0.001:
						falhas_espacamento.append([seed_valor, idx])
					ant = x
				var hist: Array = linha["historico"]
				for i in hist.size():
					janelas += 1
					var tem: bool = false
					for j in range(maxi(0, i - k + 1), i + 1):
						if hist[j]["cor"] == hist[i]["gecko"]:
							tem = true
					if not tem:
						falhas_janela.append([seed_valor, idx, i])
		assert_gt(moveis, 0, "%s: ha linhas moveis na simulacao" % caso[0])
		assert_gt(estaticas, 0, "%s: ha linhas estaticas (proporcao %.2f)" % [caso[0], snap.get_proporcao_estaticas()])
		assert_gt(janelas, 0, "%s: ha janelas de K=%d para conferir" % [caso[0], k])
		assert_eq(falhas_janela.size(), 0, "%s: toda janela de K=%d moveis tem a cor do gecko vigente" % [caso[0], k])
		assert_eq(falhas_espacamento.size(), 0, "%s: x pre-colocados espacados por espacamento(speed)" % caso[0])
		assert_eq(falhas_cor.size(), 0, "%s: a linha de cima de todo pouso tem a cor nova do gecko" % caso[0])


func test_cor_alcancavel_simulacao_desmoronamento_so_do_pouso_em_estagios_e_teto() -> void:
	PlatformModifiers.restaurar_padrao()
	var casos: Array = _casos()
	assert_eq(casos.size(), 8, "4 estagios: 3 inicios + 3 fins + inicio do teto + teto")
	var com_desmoronamento: int = 0
	for caso in casos:
		if not caso[1].get_mecanicas().has(PlatformModifiers.PLATAFORMAS_QUE_CAEM):
			continue
		# Fracao 1.0 forcada: todas caem, como antes da fracao (C536).
		var snap: DifficultySnapshot = _com_fracao(caso[1], 1.0)
		com_desmoronamento += 1
		var removidas: int = 0
		var pisadas_que_nao_caem: int = 0
		var falhas_cor: Array = []
		var falhas_so_pouso: Array = []
		for seed_valor in SEEDS_ESTAGIO:
			var sim: Dictionary = _simular(seed_valor, snap, true)
			for e in sim["eventos"]:
				if e["removida"]:
					removidas += 1
				if e["pisada_nao_cai"]:
					pisadas_que_nao_caem += 1
				if e["removidas_total"] > 1:
					falhas_so_pouso.append([seed_valor, e["g"]])
				if not e["acima_pos"].has(e["depois"]):
					falhas_cor.append([seed_valor, e["g"]])
		assert_gt(removidas, 0, "%s: ha plataforma de pouso desmoronando" % caso[0])
		assert_eq(pisadas_que_nao_caem, 0, "%s: com fracao 1.0 toda plataforma pisada cai" % caso[0])
		assert_eq(falhas_so_pouso.size(), 0, "%s: so a plataforma do pouso desmorona" % caso[0])
		assert_eq(falhas_cor.size(), 0, "%s: a linha de cima mantem a cor nova do gecko apos o desmoronamento" % caso[0])
	assert_gt(com_desmoronamento, 0, "a curva de producao tem caso com plataformas_que_caem")


func test_c534_mistura_tem_pouso_em_plataforma_que_cai_e_em_que_nao_cai() -> void:
	var com_mecanica: int = 0
	for caso in _casos():
		if not caso[1].get_mecanicas().has(PlatformModifiers.PLATAFORMAS_QUE_CAEM):
			continue
		com_mecanica += 1
		var snap: DifficultySnapshot = _com_fracao(caso[1], FRACAO_MISTURA)
		var removidas: int = 0
		var pisadas_que_nao_caem: int = 0
		for seed_valor in SEEDS_ESTAGIO:
			for e in _simular(seed_valor, snap, true)["eventos"]:
				if e["removida"]:
					removidas += 1
				if e["pisada_nao_cai"]:
					pisadas_que_nao_caem += 1
		assert_gt(removidas, 0, "%s: ha pouso em plataforma que cai (removida)" % caso[0])
		assert_gt(pisadas_que_nao_caem, 0, "%s: ha pouso em plataforma que nao cai (nao removida)" % caso[0])
	assert_gt(com_mecanica, 0, "a curva de producao tem caso com plataformas_que_caem")


func test_c535_mistura_so_a_do_pouso_desmorona_e_a_que_nao_cai_nunca_remove() -> void:
	var com_mecanica: int = 0
	for caso in _casos():
		if not caso[1].get_mecanicas().has(PlatformModifiers.PLATAFORMAS_QUE_CAEM):
			continue
		com_mecanica += 1
		var snap: DifficultySnapshot = _com_fracao(caso[1], FRACAO_MISTURA)
		var pisadas_que_nao_caem: int = 0
		var falhas_so_pouso: Array = []
		var falhas_nao_cai: Array = []
		var falhas_cor: Array = []
		for seed_valor in SEEDS_ESTAGIO:
			for e in _simular(seed_valor, snap, true)["eventos"]:
				if e["removidas_total"] > 1:
					falhas_so_pouso.append([seed_valor, e["g"]])
				if e["pisada_nao_cai"]:
					pisadas_que_nao_caem += 1
					if e["removidas_total"] != 0 or e["removida"]:
						falhas_nao_cai.append([seed_valor, e["g"]])
				if not e["acima_pos"].has(e["depois"]):
					falhas_cor.append([seed_valor, e["g"]])
		assert_gt(pisadas_que_nao_caem, 0, "%s: ha pouso em plataforma que nao cai" % caso[0])
		assert_eq(falhas_so_pouso.size(), 0, "%s: so a plataforma do pouso desmorona" % caso[0])
		assert_eq(falhas_nao_cai.size(), 0, "%s: pouso em plataforma que nao cai nao remove nada" % caso[0])
		assert_eq(falhas_cor.size(), 0, "%s: a linha de cima mantem a cor nova do gecko na mistura" % caso[0])
	assert_gt(com_mecanica, 0, "a curva de producao tem caso com plataformas_que_caem")


func test_c178_k_e_speed_dentro_do_limite_aprovado_em_todo_estagio_e_no_teto() -> void:
	var casos: Array = _casos()
	assert_eq(casos.size(), 8, "4 estagios: 3 inicios + 3 fins + inicio do teto + teto")
	for caso in casos:
		var snap: DifficultySnapshot = caso[1]
		assert_gte(snap.get_k(), DifficultyCurve.K_MINIMO, "%s: K %d >= minimo" % [caso[0], snap.get_k()])
		assert_lte(snap.get_k(), K_LIMITE, "%s: K %d <= limite aprovado %d" % [caso[0], snap.get_k(), K_LIMITE])
		assert_gt(snap.get_speed_moveis(), 0.0, "%s: speed positiva" % caso[0])
		assert_lte(
			snap.get_speed_moveis(),
			SPEED_LIMITE,
			"%s: speed %.1f <= limite aprovado %.0f" % [caso[0], snap.get_speed_moveis(), SPEED_LIMITE]
		)
