extends GutTest

# f521 T7: alcancabilidade da cor do gecko com power-up ativo. Simulacao pura (sem cena) no padrao de
# test_cor_alcancavel_simulacao.gd: 200 linhas, seed fixa, linhas iniciais estaticas e depois linhas moveis geradas
# como o jogo (MovingRowFill.initial_xs + plataforma do spawn), pouso sorteando a cor entre as da linha de cima.
#
# Harness parametrizado: _simular(seed, power_ups) coleta a lista num PowerUpState real (temporizado + carga) e a cada
# plataforma movel consulta o temporizado ativo. Power-up que altera a cor da movel (Camaleao, f522) expoe o hook
# opcional `cor_movel(cor_gecko, anteriores, rng, k) -> int`; sem o hook vale a regra de producao. Efeito real novo entra
# so na lista de _casos_neutros/_hostil, sem reescrever o harness (ADR 0014, "Riscos aceitos").
#
# Regra de producao conferida (scripts/ReachableColors.gd no HEAD):
# - linhas 20-27 (cor_plataforma_movel): "se nenhuma das K-1 ultimas de `anteriores` tem a cor do gecko, forca a cor do
#   gecko; senao sorteia" (`k <= 1 or not _tem_cor_na_janela(cor_gecko, anteriores, k - 1)` -> cor_gecko);
# - linhas 168-173 (_tem_cor_na_janela): varre as ultimas `tamanho` entradas de `anteriores`;
# - linha 6-9: toda janela de K plataformas consecutivas (ordem de criacao) tem a cor do gecko vigente na criacao.
# O invariante medido e o do C136: para cada plataforma i do historico, ha alguma de [i-K+1, i] com a cor do gecko
# vigente quando a i foi criada.

const SEED := 20261110
const LINHAS := 200
const LARGURA := 180.0
const ALTURA_TELA := 320.0
const Y_BASE := 10000.0
# Mesmos valores de modelagem de test_cor_alcancavel_simulacao.gd
const POUSOS_COM_SPAWN := 4
# Duracao longa: o temporizado segue ativo na simulacao inteira (200 pousos x TICK_POR_POUSO << duracao)
const DURACAO_LONGA := 100000.0
const TICK_POR_POUSO := 0.5


# Temporizado neutro (sem hook de cor): nao altera nada alem do estado
class FakeTemporizado:
	extends PowerUp

	func _init() -> void:
		nome = &"temporizado_neutro"
		duracao = DURACAO_LONGA


# Carga neutra (duracao 0): guardada a parte pelo PowerUpState
class FakeCarga:
	extends PowerUp

	func _init() -> void:
		nome = &"carga_neutra"
		duracao = 0.0


# Hostil: toda plataforma movel nasce com cor diferente da do gecko, deixando-o fora de toda janela K
class PowerUpHostil:
	extends PowerUp

	func _init() -> void:
		nome = &"hostil"
		duracao = DURACAO_LONGA

	func cor_movel(cor_gecko: int, _anteriores: Array, _rng: RandomNumberGenerator, _k: int) -> int:
		for cor in Enums.COLOR.values():
			if cor != cor_gecko:
				return cor
		return cor_gecko


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


# Cor de uma plataforma movel: hook do temporizado ativo se ele tiver, senao a regra de producao
func _cor_movel(cor_gecko: int, anteriores: Array, rng: RandomNumberGenerator, estado: PowerUpState) -> int:
	var ativo: PowerUp = estado.ativo()
	if ativo != null and ativo.has_method(&"cor_movel"):
		return ativo.call(&"cor_movel", cor_gecko, anteriores, rng, DifficultyStage.K_PADRAO)
	return ReachableColors.cor_plataforma_movel(cor_gecko, anteriores, rng, DifficultyStage.K_PADRAO)


func _criar_movel(linha: Dictionary, cor_gecko: int, rng: RandomNumberGenerator, estado: PowerUpState) -> int:
	var anteriores: Array = []
	for h in linha["historico"]:
		anteriores.append(h["cor"])
	var cor: int = _cor_movel(cor_gecko, anteriores, rng, estado)
	linha["historico"].append({"cor": cor, "gecko": cor_gecko})
	return cor


func _gerar_linha_movel(y: float, cor_gecko: int, rng: RandomNumberGenerator, estado: PowerUpState) -> Dictionary:
	var para_esquerda: bool = rng.randi() % 2 == 0
	var spawn_x: float = LARGURA + MovingRowFill.SEMI_PLATAFORMA if para_esquerda else -MovingRowFill.SEMI_PLATAFORMA
	var linha: Dictionary = {"y": y, "tipo": "movel", "plataformas": [], "historico": []}
	for x in MovingRowFill.initial_xs(spawn_x, para_esquerda, LARGURA):
		linha["plataformas"].append({"x": x, "cor": _criar_movel(linha, cor_gecko, rng, estado)})
	_criar_movel(linha, cor_gecko, rng, estado)
	return linha


func _entradas(linhas: Array) -> Array:
	var entradas: Array = []
	for linha in linhas:
		for p in linha["plataformas"]:
			entradas.append({"y": linha["y"], "x": p["x"], "cor": p["cor"]})
	return entradas


func _cores_recontadas(linhas: Array, y: float) -> Array:
	var cores: Array = []
	for linha in linhas:
		if absf(float(linha["y"]) - y) > 1.0:
			continue
		for p in linha["plataformas"]:
			if _visivel(p["x"]):
				cores.append(p["cor"])
	return cores


# Devolve {linhas, eventos, ativo, carga}: o estado do PowerUpState ao fim prova que o power-up ficou ativo na rodada.
func _simular(seed_valor: int, power_ups: Array) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_valor
	var estado := PowerUpState.new()
	for p in power_ups:
		estado.coletar(p)
	var cor: int = Enums.COR_INICIAL
	var linhas: Array = []
	var iniciais: int = InitialRows.initial_row_ys(ALTURA_TELA).size()
	for i in iniciais:
		linhas.append(_gerar_linha_estatica(_y_da_linha(i), rng))
	var eventos: Array = []
	for g in range(LINHAS - 1):
		var cor_antes: int = cor
		while linhas.size() <= g + 1:
			linhas.append(_gerar_linha_movel(_y_da_linha(linhas.size()), cor_antes, rng, estado))
		var candidatas: Array = ReachableColors.coletar_cores_linha_acima(
			_entradas(linhas), float(linhas[g]["y"]), LARGURA
		)
		cor = ReachableColors.escolher_cor_gecko(candidatas, rng)
		eventos.append(
			{"g": g, "depois": cor, "acima": _cores_recontadas(linhas, float(linhas[g + 1]["y"]))}
		)
		estado.tick(TICK_POR_POUSO)
		# Linhas moveis vivas criam outra plataforma no spawn com a cor do gecko vigente (nova cor do pouso)
		for i in range(maxi(0, g + 2 - POUSOS_COM_SPAWN), g + 2):
			if linhas[i]["tipo"] == "movel":
				_criar_movel(linhas[i], cor, rng, estado)
	while linhas.size() < LINHAS:
		linhas.append(_gerar_linha_movel(_y_da_linha(linhas.size()), cor, rng, estado))
	return {"linhas": linhas, "eventos": eventos, "ativo": estado.ativo(), "carga": estado.carga()}


# Janelas de K sem a cor do gecko vigente (mesmo invariante do C136) e contagens de apoio
func _medir(sim: Dictionary) -> Dictionary:
	var janelas: int = 0
	var moveis: int = 0
	var com_spawn_posterior: int = 0
	var falhas_janela: Array = []
	for idx in sim["linhas"].size():
		var linha: Dictionary = sim["linhas"][idx]
		if linha["tipo"] != "movel":
			continue
		moveis += 1
		var hist: Array = linha["historico"]
		if hist.size() > linha["plataformas"].size() + 1:
			com_spawn_posterior += 1
		for i in hist.size():
			janelas += 1
			var tem: bool = false
			for j in range(maxi(0, i - DifficultyStage.K_PADRAO + 1), i + 1):
				if hist[j]["cor"] == hist[i]["gecko"]:
					tem = true
			if not tem:
				falhas_janela.append([idx, i])
	var falhas_cor: Array = []
	for e in sim["eventos"]:
		if e["acima"].is_empty() or not e["acima"].has(e["depois"]):
			falhas_cor.append(e["g"])
	return {
		"janelas": janelas,
		"moveis": moveis,
		"com_spawn_posterior": com_spawn_posterior,
		"falhas_janela": falhas_janela,
		"falhas_cor": falhas_cor,
	}


# Casos neutros: lista de power-ups + o que o PowerUpState deve mostrar ao fim. Efeito real da f522 entra aqui.
func _casos_neutros() -> Array:
	return [
		{"nome": "sem power-up", "lista": [], "ativo": false, "carga": 0},
		{"nome": "PowerUpDeTeste", "lista": [PowerUpDeTeste.new(PowerUpDeTeste.NOME_PADRAO, DURACAO_LONGA)], "ativo": true, "carga": 0},
		{"nome": "fake temporizado", "lista": [FakeTemporizado.new()], "ativo": true, "carga": 0},
		{"nome": "fake carga", "lista": [FakeCarga.new()], "ativo": false, "carga": 1},
		{
			"nome": "temporizado + carga",
			"lista": [PowerUpDeTeste.new(PowerUpDeTeste.NOME_PADRAO, DURACAO_LONGA), FakeCarga.new()],
			"ativo": true,
			"carga": 1,
		},
		# Efeito real da f522 entra aqui (comentario do topo reserva esta lista): o Camaleao so alarga a colisao e o
		# Desacelera so troca o relogio do scroll — nenhum dos dois tem hook cor_movel, a cor das plataformas novas
		# segue a regra de producao.
		{
			"nome": "camaleao real (f522)",
			"lista": [PowerUpCamaleao.new(_config_de_teste(DURACAO_LONGA, DURACAO_LONGA, PowerUpConfig.FATOR_PADRAO))],
			"ativo": true,
			"carga": 0,
		},
		{
			"nome": "desacelera real (f522)",
			"lista": [PowerUpDesacelera.new(_config_de_teste(DURACAO_LONGA, DURACAO_LONGA, PowerUpConfig.FATOR_PADRAO))],
			"ativo": true,
			"carga": 0,
		},
		{
			"nome": "camaleao substituido por desacelera na coleta (f522)",
			"lista": [
				PowerUpCamaleao.new(_config_de_teste(DURACAO_LONGA, DURACAO_LONGA, PowerUpConfig.FATOR_PADRAO)),
				PowerUpDesacelera.new(_config_de_teste(DURACAO_LONGA, DURACAO_LONGA, PowerUpConfig.FATOR_PADRAO)),
			],
			"ativo": true,
			"carga": 0,
		},
	]


func test_c569_power_ups_neutros_ativos_mantem_a_cor_do_gecko_na_janela_k() -> void:
	for caso in _casos_neutros():
		var sim: Dictionary = _simular(SEED, caso["lista"])
		var medida: Dictionary = _medir(sim)
		assert_eq(sim["linhas"].size(), LINHAS, "%s: a simulacao gera 200 linhas" % caso["nome"])
		assert_eq(sim["ativo"] != null, caso["ativo"], "%s: temporizado ativo ate o fim da simulacao" % caso["nome"])
		assert_eq(sim["carga"], caso["carga"], "%s: carga guardada" % caso["nome"])
		assert_gt(medida["moveis"], 0, "%s: ha linhas moveis" % caso["nome"])
		assert_gt(medida["janelas"], 0, "%s: ha janelas de K para conferir" % caso["nome"])
		assert_gt(medida["com_spawn_posterior"], 0, "%s: ha linha movel com spawn depois do preenchimento" % caso["nome"])
		assert_eq(
			medida["falhas_janela"].size(),
			0,
			"%s: toda janela de K moveis tem a cor do gecko vigente" % caso["nome"]
		)
		assert_eq(
			medida["falhas_cor"].size(), 0, "%s: a linha de cima de todo pouso tem a cor nova do gecko" % caso["nome"]
		)


func test_c568_contraprova_power_up_hostil_faz_o_harness_reprovar() -> void:
	var neutro: Dictionary = _medir(_simular(SEED, [FakeTemporizado.new()]))
	var sim_hostil: Dictionary = _simular(SEED, [PowerUpHostil.new()])
	var hostil: Dictionary = _medir(sim_hostil)
	assert_ne(sim_hostil["ativo"], null, "fixture: o hostil esta ativo na simulacao")
	assert_gt(hostil["janelas"], 0, "ha janelas medidas no hostil")
	assert_eq(neutro["falhas_janela"].size(), 0, "fake neutro: nenhuma janela de K sem a cor do gecko")
	assert_gt(hostil["falhas_janela"].size(), 0, "hostil: janelas de K sem a cor do gecko sao detectadas")


# --- f522 T7 (C619-C622): alcancabilidade e justica com os power-ups reais -----------------------------------------
# O harness original segue intacto (assinaturas de _simular/_medir e test_c569/test_c568 inalteradas): os cenarios de
# estagio rodam em _simular_no_estagio, que repete os mesmos passos com 3 acrescimos — (1) cada linha nasce do snapshot
# do estagio (PlatformTypePicker com a proporcao, MovingRowFill.initial_xs com a speed e K do snapshot, como
# test_cor_alcancavel_simulacao._gerar_linha_do_snapshot); (2) cada pouso avanca o relogio do power-up pelo tempo de
# pulo real do jogo com o scroll EFETIVO vigente (ReachableColors.tempo_de_pulo(scroll do estagio x fator do
# PowerUpState), os mesmos valores de Player.change_color_random e RunningPlatforms._alcance_s, f522 T4);
# (3) coletas_no_meio mapeia pouso -> PowerUp coletado no comeco daquele pouso (substituicao no meio da simulacao,
# C621). Cada evento registra o temporizado ativo (nome), cor_livre e fator vigentes naquele pouso. O Camaleao real
# so alarga a colisao (ignora_cor, sem hook cor_movel): a cor das plataformas novas segue a regra de producao; o
# Desacelera real so troca o relogio do scroll. A garantia da janela K e medida com o K do estagio que gerou a linha.

# Curva de producao (padrao de test_cor_alcancavel_simulacao): snapshot no inicio/fim de cada estagio e no teto.
const CURVA_PATH := "res://ressources/curva_dificuldade.tres"
const EPS_PROGRESSO := 0.001
# Pousos de efeito nas duracoes finitas: a duracao vem do tempo de pulo do estagio (meio da simulacao de 199 pousos);
# o meio pouso extra (+0.5) afasta o limite do ruido de float — a expiracao cai sempre no pouso POUSOS_DE_EFEITO + 1.
const POUSOS_DE_EFEITO := 12
# Pousos das substituicoes no meio da simulacao (C621): valor de modelagem, como POUSOS_COM_SPAWN.
const POUSO_TROCA_1 := 30
const POUSO_TROCA_2 := 90


# Config injetavel dos power-ups reais (producao carrega o Resource; o teste fixa duracao/fator sem tocar no .tres).
func _config_de_teste(duracao_camaleao: float, duracao_desacelera: float, fator: float) -> PowerUpConfig:
	var cfg := PowerUpConfig.new()
	cfg.duracao_camaleao_s = duracao_camaleao
	cfg.duracao_desacelera_s = duracao_desacelera
	cfg.fator_desacelera = fator
	return cfg


# Casos "E%d inicio"/"E%d fim" da curva de producao (4 estagios = 4 inicios + 3 fins), com o teto quando pedido.
func _casos_do_estagio(incluir_teto: bool) -> Array:
	var curva := load(CURVA_PATH) as DifficultyCurve
	var casos: Array = []
	for i in range(curva.estagios.size()):
		var p_ini: float = curva.estagios[i].progresso_inicio
		casos.append(["E%d inicio" % i, curva.avaliar(p_ini * curva.pontos_plato, 0.0)])
		if i + 1 < curva.estagios.size():
			var p_fim: float = curva.estagios[i + 1].progresso_inicio - EPS_PROGRESSO
			casos.append(["E%d fim" % i, curva.avaliar(p_fim * curva.pontos_plato, 0.0)])
	if incluir_teto:
		casos.append(["teto", curva.avaliar(curva.pontos_plato, curva.segundos_plato)])
	return casos


# Cor de uma movel do estagio: hook do temporizado ativo com o K do snapshot (como _cor_movel, com o K do estagio).
func _cor_movel_do_estagio(
	cor_gecko: int, anteriores: Array, rng: RandomNumberGenerator, estado: PowerUpState, k: int
) -> int:
	var ativo: PowerUp = estado.ativo()
	if ativo != null and ativo.has_method(&"cor_movel"):
		return ativo.call(&"cor_movel", cor_gecko, anteriores, rng, k)
	return ReachableColors.cor_plataforma_movel(cor_gecko, anteriores, rng, k)


func _criar_movel_do_estagio(
	linha: Dictionary, cor_gecko: int, rng: RandomNumberGenerator, snap: DifficultySnapshot, estado: PowerUpState
) -> int:
	var anteriores: Array = []
	for h in linha["historico"]:
		anteriores.append(h["cor"])
	var cor: int = _cor_movel_do_estagio(cor_gecko, anteriores, rng, estado, snap.get_k())
	linha["historico"].append({"cor": cor, "gecko": cor_gecko})
	return cor


# Linha do estagio (como test_cor_alcancavel_simulacao._gerar_linha_do_snapshot): tipo por PlatformTypePicker com a
# proporcao do snapshot; estatica com cores aleatorias; movel com initial_xs pela speed e historico consultando o
# temporizado ativo com o K do snapshot.
func _gerar_linha_do_estagio(
	y: float, cor_gecko: int, rng: RandomNumberGenerator, snap: DifficultySnapshot, estado: PowerUpState
) -> Dictionary:
	var tipo: int = PlatformTypePicker.resolve(Enums.PLATFORM_TYPE.RANDOM_ALL, rng, snap.get_proporcao_estaticas())
	if tipo == Enums.PLATFORM_TYPE.STATIC:
		var plataformas: Array = []
		for x in [30.0, 90.0, 150.0]:
			plataformas.append({"x": x, "cor": Enums.get_random_color(rng)})
		return {"y": y, "tipo": "estatica", "plataformas": plataformas, "historico": []}
	var para_esquerda: bool = tipo == Enums.PLATFORM_TYPE.MOVE_TO_LEFT
	var spawn_x: float = LARGURA + MovingRowFill.SEMI_PLATAFORMA if para_esquerda else -MovingRowFill.SEMI_PLATAFORMA
	var linha: Dictionary = {"y": y, "tipo": "movel", "plataformas": [], "historico": []}
	for x in MovingRowFill.initial_xs(spawn_x, para_esquerda, LARGURA, snap.get_speed_moveis()):
		linha["plataformas"].append({"x": x, "cor": _criar_movel_do_estagio(linha, cor_gecko, rng, snap, estado)})
	_criar_movel_do_estagio(linha, cor_gecko, rng, snap, estado)
	return linha


# Devolve {linhas, eventos, ativo, carga}: os mesmos passos de _simular, por estagio, com o relogio do power-up pelo
# tempo de pulo do scroll efetivo e as coletas de substituicao do meio da simulacao (descricao no cabecalho da secao).
func _simular_no_estagio(
	seed_valor: int, power_ups: Array, snap: DifficultySnapshot, coletas_no_meio: Dictionary = {}
) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_valor
	var estado := PowerUpState.new()
	for p in power_ups:
		estado.coletar(p)
	var cor: int = Enums.COR_INICIAL
	var linhas: Array = []
	var iniciais: int = InitialRows.initial_row_ys(ALTURA_TELA).size()
	for i in iniciais:
		linhas.append(_gerar_linha_estatica(_y_da_linha(i), rng))
	var eventos: Array = []
	for g in range(LINHAS - 1):
		if coletas_no_meio.has(g):
			estado.coletar(coletas_no_meio[g])
		var cor_antes: int = cor
		while linhas.size() <= g + 1:
			linhas.append(_gerar_linha_do_estagio(_y_da_linha(linhas.size()), cor_antes, rng, snap, estado))
		var candidatas: Array = ReachableColors.coletar_cores_linha_acima(
			_entradas(linhas), float(linhas[g]["y"]), LARGURA
		)
		cor = ReachableColors.escolher_cor_gecko(candidatas, rng)
		var ativo: PowerUp = estado.ativo()
		var nome_ativo: StringName = ativo.nome if ativo != null else &""
		eventos.append(
			{
				"g": g,
				"depois": cor,
				"acima": _cores_recontadas(linhas, float(linhas[g + 1]["y"])),
				"ativo_nome": nome_ativo,
				"cor_livre": estado.cor_livre(),
				"fator": estado.fator_scroll(),
			}
		)
		estado.tick(ReachableColors.tempo_de_pulo(snap.get_scroll() * estado.fator_scroll()))
		# Linhas moveis vivas criam outra plataforma no spawn com a cor do gecko vigente (nova cor do pouso)
		for i in range(maxi(0, g + 2 - POUSOS_COM_SPAWN), g + 2):
			if linhas[i]["tipo"] == "movel":
				_criar_movel_do_estagio(linhas[i], cor, rng, snap, estado)
	while linhas.size() < LINHAS:
		linhas.append(_gerar_linha_do_estagio(_y_da_linha(linhas.size()), cor, rng, snap, estado))
	return {"linhas": linhas, "eventos": eventos, "ativo": estado.ativo(), "carga": estado.carga()}


# _medir com o K do estagio que gerou a linha (o K_PADRAO de _medir so vale para a simulacao sem snapshot).
func _medir_com_k(sim: Dictionary, k: int) -> Dictionary:
	var janelas: int = 0
	var moveis: int = 0
	var estaticas: int = 0
	var com_spawn_posterior: int = 0
	var falhas_janela: Array = []
	for idx in sim["linhas"].size():
		var linha: Dictionary = sim["linhas"][idx]
		if linha["tipo"] == "estatica":
			estaticas += 1
			continue
		moveis += 1
		var hist: Array = linha["historico"]
		if hist.size() > linha["plataformas"].size() + 1:
			com_spawn_posterior += 1
		for i in hist.size():
			janelas += 1
			var tem: bool = false
			for j in range(maxi(0, i - k + 1), i + 1):
				if hist[j]["cor"] == hist[i]["gecko"]:
					tem = true
			if not tem:
				falhas_janela.append([idx, i])
	var falhas_cor: Array = []
	for e in sim["eventos"]:
		if e["acima"].is_empty() or not e["acima"].has(e["depois"]):
			falhas_cor.append(e["g"])
	return {
		"janelas": janelas,
		"moveis": moveis,
		"estaticas": estaticas,
		"com_spawn_posterior": com_spawn_posterior,
		"falhas_janela": falhas_janela,
		"falhas_cor": falhas_cor,
	}


# C619: com o Camaleao REAL ativo (so alarga a colisao, nao altera a cor de plataforma nova), a garantia da janela K
# do C136 vale nos estagios 0 a 3: nenhuma janela de K sem a cor do gecko e linha de cima de todo pouso com a cor nova.
func test_c619_camaleao_ativo_mantem_a_garantia_nos_estagios_0_a_3() -> void:
	var casos: Array = _casos_do_estagio(false)
	assert_eq(casos.size(), 7, "estagios 0 a 3: 4 inicios + 3 fins")
	var cfg := _config_de_teste(DURACAO_LONGA, DURACAO_LONGA, PowerUpConfig.FATOR_PADRAO)
	for caso in casos:
		var snap: DifficultySnapshot = caso[1]
		var sim: Dictionary = _simular_no_estagio(SEED, [PowerUpCamaleao.new(cfg)], snap)
		var medida: Dictionary = _medir_com_k(sim, snap.get_k())
		assert_eq(sim["linhas"].size(), LINHAS, "%s: a simulacao gera 200 linhas" % caso[0])
		assert_gt(medida["moveis"], 0, "%s: ha linhas moveis" % caso[0])
		assert_gt(medida["estaticas"], 0, "%s: ha linhas estaticas" % caso[0])
		assert_gt(medida["janelas"], 0, "%s: ha janelas de K=%d para conferir" % [caso[0], snap.get_k()])
		assert_gt(medida["com_spawn_posterior"], 0, "%s: ha linha movel com spawn depois do preenchimento" % caso[0])
		var pousos_sem_cor_livre: int = 0
		for e in sim["eventos"]:
			if not e["cor_livre"]:
				pousos_sem_cor_livre += 1
		assert_eq(pousos_sem_cor_livre, 0, "%s: o Camaleao real esta ativo (cor livre) em todo pouso" % caso[0])
		assert_eq(
			sim["ativo"] != null and sim["ativo"].nome == &"camaleao",
			true,
			"%s: o Camaleao real segue ativo no fim da simulacao" % caso[0]
		)
		assert_eq(
			medida["falhas_janela"].size(),
			0,
			"%s: nenhuma janela de K=%d sem a cor do gecko" % [caso[0], snap.get_k()]
		)
		assert_eq(medida["falhas_cor"].size(), 0, "%s: a linha de cima de todo pouso tem a cor nova do gecko" % caso[0])


# C620: idem com o Desacelera REAL ativo usando o scroll efetivo (inclusive no teto). O relogio por pouso e o tempo de
# pulo pelo scroll do estagio x fator do Resource: (a) com duracao longa o efeito vigore a simulacao inteira;
# (b) com duracao finita derivada do tempo de pulo do scroll EFETIVO, a expiracao cai no pouso exato derivado — prova
# que o relogio seguiu o fator, nao o scroll cheio. Se a garantia quebrar, ajustar a regra e documentar (ADR 0014):
# o assert nao se relaxa.
func test_c620_desacelera_ativo_usa_o_scroll_efetivo_nos_estagios_e_no_teto() -> void:
	var casos: Array = _casos_do_estagio(true)
	assert_eq(casos.size(), 8, "4 estagios: 4 inicios + 3 fins + teto")
	var fator: float = PowerUpConfig.FATOR_PADRAO
	var cfg_longo := _config_de_teste(DURACAO_LONGA, DURACAO_LONGA, fator)
	for caso in casos:
		var snap: DifficultySnapshot = caso[1]
		var sim: Dictionary = _simular_no_estagio(SEED, [PowerUpDesacelera.new(cfg_longo)], snap)
		var medida: Dictionary = _medir_com_k(sim, snap.get_k())
		var pousos_com_fator_errado: int = 0
		for e in sim["eventos"]:
			if absf(float(e["fator"]) - fator) > 0.0001:
				pousos_com_fator_errado += 1
		assert_eq(
			pousos_com_fator_errado,
			0,
			"%s: o fator vigente em todo pouso e o do Resource (%.2f), o scroll efetivo" % [caso[0], fator]
		)
		assert_eq(
			sim["ativo"] != null and sim["ativo"].nome == &"desacelera",
			true,
			"%s: o Desacelera real segue ativo no fim da simulacao" % caso[0]
		)
		assert_gt(medida["janelas"], 0, "%s: ha janelas de K=%d para conferir" % [caso[0], snap.get_k()])
		assert_eq(
			medida["falhas_janela"].size(),
			0,
			"%s: nenhuma janela de K=%d sem a cor do gecko com o scroll efetivo" % [caso[0], snap.get_k()]
		)
		assert_eq(
			medida["falhas_cor"].size(), 0, "%s: a linha de cima de todo pouso tem a cor nova do gecko" % caso[0]
		)
		var dt: float = ReachableColors.tempo_de_pulo(snap.get_scroll() * fator)
		var cfg_finito := _config_de_teste(DURACAO_LONGA, dt * (POUSOS_DE_EFEITO + 0.5), fator)
		var sim_finita: Dictionary = _simular_no_estagio(SEED, [PowerUpDesacelera.new(cfg_finito)], snap)
		var medida_finita: Dictionary = _medir_com_k(sim_finita, snap.get_k())
		assert_eq(
			sim_finita["eventos"][POUSOS_DE_EFEITO]["ativo_nome"],
			&"desacelera",
			"%s: o ultimo pouso coberto pela duracao tem o Desacelera ativo" % caso[0]
		)
		assert_eq(
			sim_finita["eventos"][POUSOS_DE_EFEITO + 1]["ativo_nome"],
			&"",
			"%s: expira no pouso seguinte, pelo relogio do tempo de pulo com o scroll efetivo" % caso[0]
		)
		assert_eq(
			sim_finita["eventos"][POUSOS_DE_EFEITO + 1]["fator"],
			1.0,
			"%s: sem temporizado o fator vigente volta a 1.0" % caso[0]
		)
		assert_eq(
			medida_finita["falhas_janela"].size(),
			0,
			"%s: nenhuma janela de K=%d sem a cor do gecko antes/depois da expiracao" % [caso[0], snap.get_k()]
		)
		assert_eq(
			medida_finita["falhas_cor"].size(),
			0,
			"%s: a linha de cima de todo pouso tem a cor nova antes/depois da expiracao" % caso[0]
		)


# C621: os dois alternando com substituicao no meio da simulacao (coleta no comeco do pouso indicado) mantem a
# garantia; a contraprova hostil substituida no meio continua reprovando. A assinatura do harness original nao muda:
# _simular(seed, power_ups) segue intacta e test_c569/test_c568 rodam sem edicao.
func test_c621_camaleao_e_desacelera_alternando_mantem_a_garantia() -> void:
	var casos: Array = _casos_do_estagio(true)
	assert_eq(casos.size(), 8, "4 estagios + teto")
	var cfg := _config_de_teste(DURACAO_LONGA, DURACAO_LONGA, PowerUpConfig.FATOR_PADRAO)
	for caso in casos:
		var snap: DifficultySnapshot = caso[1]
		var sim: Dictionary = _simular_no_estagio(
			SEED,
			[PowerUpCamaleao.new(cfg)],
			snap,
			{POUSO_TROCA_1: PowerUpDesacelera.new(cfg), POUSO_TROCA_2: PowerUpCamaleao.new(cfg)}
		)
		var medida: Dictionary = _medir_com_k(sim, snap.get_k())
		var sequencia_errada: int = 0
		for e in sim["eventos"]:
			var esperado: StringName = &"camaleao"
			if e["g"] >= POUSO_TROCA_1 and e["g"] < POUSO_TROCA_2:
				esperado = &"desacelera"
			if e["ativo_nome"] != esperado:
				sequencia_errada += 1
		assert_eq(
			sequencia_errada,
			0,
			"%s: camaleao, desacelera e camaleao vigem nas faixas de pousos das substituicoes" % caso[0]
		)
		assert_eq(
			sim["ativo"] != null and sim["ativo"].nome == &"camaleao",
			true,
			"%s: a 2a substituicao deixou o camaleao ativo" % caso[0]
		)
		assert_gt(medida["janelas"], 0, "%s: ha janelas de K=%d para conferir" % [caso[0], snap.get_k()])
		assert_eq(
			medida["falhas_janela"].size(),
			0,
			"%s: nenhuma janela de K=%d sem a cor do gecko com os dois alternando" % [caso[0], snap.get_k()]
		)
		assert_eq(
			medida["falhas_cor"].size(),
			0,
			"%s: a linha de cima de todo pouso tem a cor nova com os dois alternando" % caso[0]
		)
		var sim_reversa: Dictionary = _simular_no_estagio(
			SEED, [PowerUpDesacelera.new(cfg)], snap, {POUSO_TROCA_1: PowerUpCamaleao.new(cfg)}
		)
		var medida_reversa: Dictionary = _medir_com_k(sim_reversa, snap.get_k())
		var reversa_errada: int = 0
		for e in sim_reversa["eventos"]:
			var esperado_reverso: StringName = &"desacelera" if e["g"] < POUSO_TROCA_1 else &"camaleao"
			if e["ativo_nome"] != esperado_reverso:
				reversa_errada += 1
		assert_eq(
			reversa_errada,
			0,
			"%s: desacelera e camaleao vigem nas faixas de pousos da substituicao contraria" % caso[0]
		)
		assert_eq(
			medida_reversa["falhas_janela"].size(),
			0,
			"%s: nenhuma janela de K=%d sem a cor do gecko na substituicao contraria" % [caso[0], snap.get_k()]
		)
		assert_eq(
			medida_reversa["falhas_cor"].size(),
			0,
			"%s: a linha de cima de todo pouso tem a cor nova na substituicao contraria" % caso[0]
		)
	# Contraprova: o hostil substituido no meio da simulacao continua reprovando (janelas de K sem a cor do gecko).
	var caso_hostil: Array = casos[1]
	var sim_hostil: Dictionary = _simular_no_estagio(
		SEED, [PowerUpCamaleao.new(cfg)], caso_hostil[1], {POUSO_TROCA_1: PowerUpHostil.new()}
	)
	var medida_hostil: Dictionary = _medir_com_k(sim_hostil, caso_hostil[1].get_k())
	assert_eq(
		sim_hostil["eventos"][POUSO_TROCA_1]["ativo_nome"],
		&"hostil",
		"o hostil substitui o camaleao no meio da simulacao"
	)
	assert_eq(
		sim_hostil["ativo"] != null and sim_hostil["ativo"].nome == &"hostil",
		true,
		"o hostil segue ativo no fim da simulacao"
	)
	assert_gt(medida_hostil["janelas"], 0, "ha janelas medidas no hostil substituido no meio")
	assert_gt(
		medida_hostil["falhas_janela"].size(),
		0,
		"hostil substituido no meio: janelas de K sem a cor do gecko sao detectadas"
	)


# C622: apos expirar o Camaleao a regra de cor volta na simulacao: cor_livre (o que torna pouso em cor diferente
# valido) desliga no pouso exato derivado do relogio e nunca reacende; a garantia vale antes, durante e depois.
func test_c622_apos_expirar_o_camaleao_a_regra_de_cor_volta_na_simulacao() -> void:
	var caso: Array = _casos_do_estagio(false)[0]
	var snap: DifficultySnapshot = caso[1]
	var dt: float = ReachableColors.tempo_de_pulo(snap.get_scroll())
	var cfg := _config_de_teste(dt * (POUSOS_DE_EFEITO + 0.5), DURACAO_LONGA, PowerUpConfig.FATOR_PADRAO)
	var sim: Dictionary = _simular_no_estagio(SEED, [PowerUpCamaleao.new(cfg)], snap)
	var medida: Dictionary = _medir_com_k(sim, snap.get_k())
	assert_eq(sim["eventos"][0]["cor_livre"], true, "cor livre com o Camaleao ativo: pouso em cor diferente e valido")
	assert_eq(
		sim["eventos"][POUSOS_DE_EFEITO]["cor_livre"],
		true,
		"o ultimo pouso coberto pela duracao ainda tem cor livre"
	)
	var expira: int = POUSOS_DE_EFEITO + 1
	assert_eq(
		sim["eventos"][expira]["ativo_nome"], &"", "o Camaleao expira no pouso seguinte ao ultimo coberto"
	)
	assert_eq(
		sim["eventos"][expira]["cor_livre"],
		false,
		"a regra de cor volta no pouso da expiracao (sem cor livre)"
	)
	var pousos_cor_livre_apos: int = 0
	for g in range(expira, sim["eventos"].size()):
		if sim["eventos"][g]["cor_livre"]:
			pousos_cor_livre_apos += 1
	assert_eq(
		pousos_cor_livre_apos,
		0,
		"nenhum pouso apos a expiracao aceita pouso em cor diferente (a regra de cor voltou)"
	)
	assert_eq(sim["ativo"], null, "sem temporizado ativo ao fim da simulacao")
	assert_gt(medida["janelas"], 0, "ha janelas de K=%d para conferir" % snap.get_k())
	assert_eq(
		medida["falhas_janela"].size(),
		0,
		"nenhuma janela de K=%d sem a cor do gecko antes/depois da expiracao" % snap.get_k()
	)
	assert_eq(
		medida["falhas_cor"].size(),
		0,
		"a linha de cima de todo pouso tem a cor nova antes/depois da expiracao"
	)
