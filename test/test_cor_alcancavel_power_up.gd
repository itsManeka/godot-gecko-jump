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
