extends GutTest

# Simulacao COM TEMPO da cor alcancavel com plataformas que mudam de cor (estagios da curva com a mecanica ligada).
# Relogio em physics frames: cada cicladora e uma PlatformColorCycle real, avancada por ao_processar(delta = 1 tick)
# numa plataforma falsa (FakaPlataforma). O gecko pousa na linha g, sorteia a cor pela previsao
# (ReachableColors.coletar_cores_linha_acima com dt_chegada = tempo_de_pulo e espera = Player.ESPERA_MAXIMA_S), espera um
# atraso (extremos 0 e espera - 1 frame, e sorteados), pula, e so entao confere a cor REAL da linha de cima no frame de chegada.
# Tolerancia declarada: o atraso maximo e espera - 1 frame (a borda exata da janela depende da soma de floats do relogio).
# A geracao das linhas segue o gerador (cor_plataforma_movel com a janela K, sequencia da cicladora forcada com a cor do
# gecko, proporcao_cicladoras do snapshot). As linhas iniciais (estaticas) nunca recebem ciclo.

const PlayerFisica := preload("res://scenes/Player.gd")
const CURVA_PATH := "res://ressources/curva_dificuldade.tres"
const EPS_PROGRESSO := 0.001
const SEEDS := [20261110, 20261111, 20261112]
const LINHAS := 120
const LARGURA := 180.0
const ALTURA_TELA := 320.0
const Y_BASE := 10000.0
# Pousos depois do nascimento em que uma linha movel ainda cria plataformas no spawn (valor de modelagem, como no
# test_cor_alcancavel_simulacao).
const POUSOS_COM_SPAWN := 4
# Linhas ja criadas acima do pouso (a tela mostra varias): a cicladora envelhece antes de o gecko chegar nela.
const LINHAS_A_FRENTE := 8
# Idade maxima (frames) com que uma cicladora nasce: espalha a fase do ciclo (periodo de 3 s = 180 frames) entre elas.
const IDADE_MAXIMA_FRAMES := 540


# Plataforma falsa: so registra a cor e a trava (o ciclo chama trocar_cor/esta_travada). Sem arvore, sem colisao.
class FakaPlataforma:
	extends Platform
	var travada_fake: bool = false
	var trocas: int = 0

	func esta_travada() -> bool:
		return travada_fake

	func trocar_cor(nova: int) -> void:
		color = nova as Enums.COLOR
		trocas += 1


func _y_da_linha(indice: int) -> float:
	return Y_BASE - InitialRows.ESPACAMENTO * indice


func _visivel(x: float) -> bool:
	return x >= 0.0 and x <= LARGURA


func _casos_com_ciclo() -> Array:
	var curva := load(CURVA_PATH) as DifficultyCurve
	var casos: Array = []
	for i in range(curva.estagios.size()):
		var p_ini: float = curva.estagios[i].progresso_inicio
		casos.append(["E%d inicio" % i, curva.avaliar(p_ini * curva.pontos_plato, 0.0)])
		if i + 1 < curva.estagios.size():
			var p_fim: float = curva.estagios[i + 1].progresso_inicio - EPS_PROGRESSO
			casos.append(["E%d fim" % i, curva.avaliar(p_fim * curva.pontos_plato, 0.0)])
	casos.append(["teto", curva.avaliar(curva.pontos_plato, curva.segundos_plato)])
	var com_ciclo: Array = []
	for caso in casos:
		var snap: DifficultySnapshot = caso[1]
		if snap.get_mecanicas().has(PlatformModifiers.PLATAFORMAS_QUE_MUDAM_DE_COR) and snap.get_proporcao_cicladoras() > 0.0:
			com_ciclo.append(caso)
	return com_ciclo


func _atrasos() -> Array:
	var maximo: int = roundi(PlayerFisica.ESPERA_MAXIMA_S * float(Engine.physics_ticks_per_second)) - 1
	return [0, maximo]


# `idade_frames`: tempo que a cicladora ja viveu na tela antes de o gecko poder alcanca-la (fase variada entre cicladoras).
func _plataforma(x: float, cor: int, ciclo: PlatformColorCycle, idade_frames: int = 0) -> Dictionary:
	var fake: FakaPlataforma = null
	if ciclo != null:
		fake = FakaPlataforma.new()
		fake.color = cor as Enums.COLOR
		autofree(fake)
		var delta: float = 1.0 / float(Engine.physics_ticks_per_second)
		for _f in idade_frames:
			ciclo.ao_processar(fake, delta)
	return {"x": x, "cor_base": cor, "ciclo": ciclo, "fake": fake}


func _cor_atual(p: Dictionary) -> int:
	if p["fake"] != null:
		return int((p["fake"] as FakaPlataforma).color)
	return int(p["cor_base"])


# Como RunningPlatforms._novo_ciclo: sequencia sorteada a partir da cor e forcada a ter a cor do gecko.
func _sorteia_ciclo(cor: int, cor_gecko: int, rng: RandomNumberGenerator, snap: DifficultySnapshot) -> PlatformColorCycle:
	if rng.randf() >= snap.get_proporcao_cicladoras():
		return null
	var periodo: float = snap.get_periodo_ciclo()
	var ciclo := PlatformColorCycle.new()
	ciclo.iniciar(cor, periodo, rng)
	ciclo.definir_sequencia(ReachableColors.forcar_cor_cicladora(ciclo.get_sequencia(), cor_gecko, periodo))
	return ciclo


func _idade_sorteada(ciclo: PlatformColorCycle, rng: RandomNumberGenerator) -> int:
	if ciclo == null:
		return 0
	return rng.randi_range(0, IDADE_MAXIMA_FRAMES)


func _criar_movel(
	linha: Dictionary, x: float, cor_gecko: int, rng: RandomNumberGenerator, snap: DifficultySnapshot, viva: bool
) -> void:
	var anteriores: Array = []
	for h in linha["historico"]:
		anteriores.append(h["cor"])
	var cor: int = ReachableColors.cor_plataforma_movel(cor_gecko, anteriores, rng, snap.get_k())
	var ciclo: PlatformColorCycle = _sorteia_ciclo(cor, cor_gecko, rng, snap)
	linha["historico"].append({"cor": cor, "gecko": cor_gecko, "ciclo": ciclo})
	if viva:
		linha["plataformas"].append(_plataforma(x, cor, ciclo, _idade_sorteada(ciclo, rng)))


func _linha_inicial(y: float, rng: RandomNumberGenerator) -> Dictionary:
	var cores: Array = StaticPlatformColors.sortear(Enums.COR_INICIAL, rng)
	var plataformas: Array = []
	var xs: Array = [30.0, 90.0, 150.0]
	for i in xs.size():
		plataformas.append(_plataforma(xs[i], cores[i], null))
	return {"y": y, "tipo": "estatica", "plataformas": plataformas, "historico": []}


func _nova_linha(y: float, cor_gecko: int, rng: RandomNumberGenerator, snap: DifficultySnapshot) -> Dictionary:
	var tipo: int = PlatformTypePicker.resolve(Enums.PLATFORM_TYPE.RANDOM_ALL, rng, snap.get_proporcao_estaticas())
	if tipo == Enums.PLATFORM_TYPE.STATIC:
		var plataformas: Array = []
		for x in [30.0, 90.0, 150.0]:
			var cor: int = Enums.get_random_color(rng)
			var ciclo: PlatformColorCycle = _sorteia_ciclo(cor, cor_gecko, rng, snap)
			plataformas.append(_plataforma(x, cor, ciclo, _idade_sorteada(ciclo, rng)))
		return {"y": y, "tipo": "estatica", "plataformas": plataformas, "historico": []}
	var para_esquerda: bool = tipo == Enums.PLATFORM_TYPE.MOVE_TO_LEFT
	var spawn_x: float = LARGURA + MovingRowFill.SEMI_PLATAFORMA if para_esquerda else -MovingRowFill.SEMI_PLATAFORMA
	var linha: Dictionary = {"y": y, "tipo": "movel", "plataformas": [], "historico": [], "spawn_x": spawn_x}
	for x in MovingRowFill.initial_xs(spawn_x, para_esquerda, LARGURA, snap.get_speed_moveis()):
		_criar_movel(linha, x, cor_gecko, rng, snap, true)
	_criar_movel(linha, spawn_x, cor_gecko, rng, snap, false)
	return linha


# Avanca o relogio `frames` physics frames: toda cicladora das linhas g..fim anda 1 tick por frame (travada nao anda).
func _avancar(linhas: Array, g: int, frames: int) -> void:
	var delta: float = 1.0 / float(Engine.physics_ticks_per_second)
	for _f in frames:
		for i in range(g, linhas.size()):
			for p in linhas[i]["plataformas"]:
				var ciclo: PlatformColorCycle = p["ciclo"]
				if ciclo != null:
					ciclo.ao_processar(p["fake"], delta)


func _entradas(linhas: Array) -> Array:
	var entradas: Array = []
	for linha in linhas:
		for p in linha["plataformas"]:
			var e: Dictionary = {"y": linha["y"], "x": p["x"], "cor": _cor_atual(p)}
			if p["ciclo"] != null:
				e["ciclo"] = p["ciclo"]
			entradas.append(e)
	return entradas


func _cores_visiveis_atuais(linha: Dictionary) -> Array:
	var cores: Array = []
	for p in linha["plataformas"]:
		if _visivel(p["x"]):
			cores.append(_cor_atual(p))
	return cores


func _tem_ciclo_visivel(linha: Dictionary) -> bool:
	for p in linha["plataformas"]:
		if p["ciclo"] != null and _visivel(p["x"]):
			return true
	return false


# Cicladoras visiveis da linha cuja cor nos extremos da janela [dt, dt + espera] difere (nao cobrem a janela).
func _cicladoras_que_mudam(linha: Dictionary, dt: float, espera: float) -> int:
	var total: int = 0
	for p in linha["plataformas"]:
		var ciclo: PlatformColorCycle = p["ciclo"]
		if ciclo != null and _visivel(p["x"]) and ciclo.cor_em(dt) != ciclo.cor_em(dt + espera):
			total += 1
	return total


# Devolve {linhas, eventos, ciclos, trocas}. Evento = um pouso na linha g e a chegada na g+1 pela previsao.
func _simular(seed_valor: int, snap: DifficultySnapshot) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_valor
	var taxa: float = float(Engine.physics_ticks_per_second)
	var tempo_pulo: float = ReachableColors.tempo_de_pulo(snap.get_scroll())
	var frames_pulo: int = roundi(tempo_pulo * taxa)
	var espera: float = PlayerFisica.ESPERA_MAXIMA_S
	var atrasos: Array = _atrasos()
	var cor: int = Enums.COR_INICIAL
	var linhas: Array = []
	for i in InitialRows.initial_row_ys(ALTURA_TELA).size():
		linhas.append(_linha_inicial(_y_da_linha(i), rng))
	var eventos: Array = []
	var pouso: FakaPlataforma = null
	for g in range(LINHAS - 1):
		var cor_antes: int = cor
		while linhas.size() <= g + LINHAS_A_FRENTE:
			linhas.append(_nova_linha(_y_da_linha(linhas.size()), cor_antes, rng, snap))
		var candidatas: Array = ReachableColors.coletar_cores_linha_acima(
			_entradas(linhas), float(linhas[g]["y"]), LARGURA, tempo_pulo, espera
		)
		var mudam_na_janela: int = _cicladoras_que_mudam(linhas[g + 1], tempo_pulo, espera)
		cor = ReachableColors.escolher_cor_gecko(candidatas, rng)
		# O gecko espera `atraso` frames em cima da plataforma (travando a cicladora dela), pula e chega.
		# Extremos (0 e espera - 1 frame) alternados com atrasos sorteados: a fase das cicladoras varia entre pousos.
		var atraso: int = atrasos[g % 2] if g % 4 < 2 else rng.randi_range(0, atrasos[1])
		_avancar(linhas, g, atraso)
		if pouso != null:
			pouso.travada_fake = false
		_avancar(linhas, g, frames_pulo)
		var cores_chegada: Array = _cores_visiveis_atuais(linhas[g + 1])
		pouso = null
		for p in linhas[g + 1]["plataformas"]:
			if _visivel(p["x"]) and _cor_atual(p) == cor:
				pouso = p["fake"]
				break
		if pouso != null:
			pouso.travada_fake = true
		eventos.append(
			{
				"g": g,
				"antes": cor_antes,
				"nova": cor,
				"atraso": atraso,
				"candidatas": candidatas,
				"fallback": candidatas.is_empty(),
				"cores_chegada": cores_chegada,
				"chegada_ok": cores_chegada.has(cor),
				"ciclo_acima": _tem_ciclo_visivel(linhas[g + 1]),
				"mudam_na_janela": mudam_na_janela,
			}
		)
		for i in range(maxi(0, g + 2 - POUSOS_COM_SPAWN), g + 2):
			if linhas[i]["tipo"] == "movel":
				_criar_movel(linhas[i], float(linhas[i]["spawn_x"]), cor, rng, snap, false)
	var ciclos: int = 0
	var trocas: int = 0
	for linha in linhas:
		for p in linha["plataformas"]:
			if p["ciclo"] != null:
				ciclos += 1
				trocas += (p["fake"] as FakaPlataforma).trocas
	return {"linhas": linhas, "eventos": eventos, "ciclos": ciclos, "trocas": trocas}


func test_c261_janela_de_k_moveis_e_cor_no_instante_do_pulo_em_estagio_com_ciclo() -> void:
	var casos: Array = _casos_com_ciclo()
	assert_gt(casos.size(), 0, "a curva de producao tem estagio com a mecanica de ciclo")
	var ciclos: int = 0
	var trocas: int = 0
	for caso in casos:
		var snap: DifficultySnapshot = caso[1]
		var k: int = snap.get_k()
		var janelas: int = 0
		var falhas_janela: Array = []
		var falhas_instante: Array = []
		for seed_valor in SEEDS:
			var sim: Dictionary = _simular(seed_valor, snap)
			ciclos += sim["ciclos"]
			trocas += sim["trocas"]
			for idx in sim["linhas"].size():
				var linha: Dictionary = sim["linhas"][idx]
				if linha["tipo"] != "movel":
					continue
				var hist: Array = linha["historico"]
				for i in hist.size():
					janelas += 1
					var tem: bool = false
					for j in range(maxi(0, i - k + 1), i + 1):
						var ciclo: PlatformColorCycle = hist[j]["ciclo"]
						# A cicladora conta pela cor inicial (janela do gerador) ou por ter a cor do gecko na sequencia.
						if hist[j]["cor"] == hist[i]["gecko"] or (ciclo != null and ciclo.get_sequencia().has(hist[i]["gecko"])):
							tem = true
					if not tem:
						falhas_janela.append("%s K=%d seed=%d linha=%d plataforma=%d cor=%d" % [caso[0], k, seed_valor, idx, i, hist[i]["gecko"]])
			for e in sim["eventos"]:
				if not e["chegada_ok"]:
					falhas_instante.append("%s K=%d seed=%d pouso=%d cor=%d atraso=%d" % [caso[0], k, seed_valor, e["g"], e["nova"], e["atraso"]])
		assert_gt(janelas, 0, "%s: ha janelas de K=%d moveis para conferir" % [caso[0], k])
		assert_eq(falhas_janela, [], "%s: toda janela de K=%d moveis tem a cor do gecko" % [caso[0], k])
		assert_eq(falhas_instante, [], "%s: a cor sorteada existe na linha de cima no frame de chegada" % caso[0])
	assert_gt(ciclos, 0, "a simulacao gera cicladoras")
	assert_gt(trocas, 0, "cicladoras trocam de cor durante a simulacao (o teste nao e vacuo)")


func test_c262_todo_pouso_tem_candidata_alcancavel_na_janela_de_chegada() -> void:
	var casos: Array = _casos_com_ciclo()
	assert_gt(casos.size(), 0, "a curva de producao tem estagio com a mecanica de ciclo")
	var com_ciclo_acima: int = 0
	var mudaram: int = 0
	var atrasos_vistos: Dictionary = {}
	var cores_validas: Array = Enums.COLOR.values()
	for caso in casos:
		var snap: DifficultySnapshot = caso[1]
		var k: int = snap.get_k()
		var sem_candidata: Array = []
		var candidata_invalida: Array = []
		var sem_alcance: Array = []
		var contagem_errada: Array = []
		for seed_valor in SEEDS:
			var sim: Dictionary = _simular(seed_valor, snap)
			assert_eq(sim["eventos"].size(), LINHAS - 1, "%s: um pouso por linha" % caso[0])
			for e in sim["eventos"]:
				atrasos_vistos[e["atraso"]] = true
				if e["ciclo_acima"]:
					com_ciclo_acima += 1
				if e["fallback"]:
					sem_candidata.append("%s K=%d seed=%d pouso=%d" % [caso[0], k, seed_valor, e["g"]])
				for c in e["candidatas"]:
					if not cores_validas.has(c):
						candidata_invalida.append("%s K=%d seed=%d pouso=%d cor=%d" % [caso[0], k, seed_valor, e["g"], c])
				mudaram += e["mudam_na_janela"]
				if e["candidatas"].size() != e["cores_chegada"].size() - e["mudam_na_janela"]:
					contagem_errada.append("%s K=%d seed=%d pouso=%d" % [caso[0], k, seed_valor, e["g"]])
				if not e["cores_chegada"].has(e["nova"]):
					sem_alcance.append("%s K=%d seed=%d pouso=%d cor=%d atraso=%d" % [caso[0], k, seed_valor, e["g"], e["nova"], e["atraso"]])
		assert_eq(sem_candidata, [], "%s: nenhum pouso cai no sorteio livre (linha sempre com candidata)" % caso[0])
		assert_eq(candidata_invalida, [], "%s: toda candidata e uma cor valida" % caso[0])
		assert_eq(contagem_errada, [], "%s: cicladora que muda na janela [dt, dt + espera] nao e candidata" % caso[0])
		assert_eq(sem_alcance, [], "%s: a cor escolhida esta na linha de cima na chegada, com ou sem espera" % caso[0])
	assert_gt(com_ciclo_acima, 0, "ha pouso com cicladora na linha de cima")
	assert_gt(mudaram, 0, "ha cicladora que muda dentro da janela de chegada (o teste exercita a exclusao)")
	for atraso in _atrasos():
		assert_true(atrasos_vistos.has(atraso), "o atraso extremo de %d frames foi simulado" % atraso)


# C264: a cicladora do pouso fica travada (gecko em cima) e o relogio dela para; as demais linhas seguem a previsao.
func test_c264_cicladora_travada_nao_quebra_a_previsao_das_demais_linhas() -> void:
	var snap := DifficultySnapshot.new()
	var periodo: float = 3.0
	var taxa: float = float(Engine.physics_ticks_per_second)
	var tempo_pulo: float = ReachableColors.tempo_de_pulo(snap.get_scroll())
	var frames_pulo: int = roundi(tempo_pulo * taxa)
	var mundos: Array = []
	for travar in [true, false]:
		var rng := RandomNumberGenerator.new()
		rng.seed = 20261120
		var ciclo_pouso := PlatformColorCycle.new()
		ciclo_pouso.iniciar(Enums.COLOR.AMARELO, periodo, rng)
		var linha_pouso: Dictionary = {"y": _y_da_linha(0), "plataformas": [_plataforma(90.0, Enums.COLOR.AMARELO, ciclo_pouso)]}
		var acima: Array = []
		for x in [30.0, 90.0, 150.0]:
			var ciclo := PlatformColorCycle.new()
			ciclo.iniciar(Enums.COR_INICIAL, periodo, rng)
			acima.append(_plataforma(x, Enums.COR_INICIAL, ciclo))
		var linha_acima: Dictionary = {"y": _y_da_linha(1), "plataformas": acima}
		(linha_pouso["plataformas"][0]["fake"] as FakaPlataforma).travada_fake = travar
		mundos.append([linha_pouso, linha_acima])
	# As linhas envelhecem 2,8 s antes do pouso: a troca (em 3 s) cai dentro da janela de chegada (tempo_pulo ~0,3 s).
	for mundo in mundos:
		_avancar(mundo, 0, roundi(2.8 * taxa))
	var previstas: Array = []
	for mundo in mundos:
		previstas.append(
			ReachableColors.coletar_cores_linha_acima(_entradas(mundo), float(mundo[0]["y"]), LARGURA, tempo_pulo, 0.0)
		)
	assert_eq(previstas[0], previstas[1], "a trava da linha do pouso nao muda a previsao da linha de cima")
	for mundo in mundos:
		_avancar(mundo, 0, frames_pulo)
	var cores_travado: Array = _cores_visiveis_atuais(mundos[0][1])
	assert_eq(cores_travado, _cores_visiveis_atuais(mundos[1][1]), "a linha de cima anda igual com e sem trava na linha do pouso")
	for cor in previstas[0]:
		assert_true(cores_travado.has(cor), "a cor prevista %d existe na linha de cima na chegada" % cor)
	assert_gt(previstas[0].size(), 0, "a previsao tem candidata (nao e vacua)")
	var fake_travada: FakaPlataforma = mundos[0][0]["plataformas"][0]["fake"]
	var fake_livre: FakaPlataforma = mundos[1][0]["plataformas"][0]["fake"]
	assert_eq(fake_travada.trocas, 0, "travada,a cicladora do pouso nao troca de cor")
	assert_gt(fake_livre.trocas, 0, "sem trava, a mesma cicladora troca no mesmo intervalo")
	# Destravada, retoma de onde parou e volta a trocar.
	fake_travada.travada_fake = false
	_avancar(mundos[0], 0, roundi((periodo + 0.2) * taxa))
	assert_gt(fake_travada.trocas, 0, "destravada, a cicladora retoma o ciclo")
