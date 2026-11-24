extends GutTest

const CURVA_PATH := "res://ressources/curva_dificuldade.tres"
const SEED_FIXA: int = 12345
const EPS: float = 0.0001
# Tolerancia da proporcao em 3000 sorteios: +-5 pontos percentuais (cerca de 5 desvios-padrao, nao depende do valor da implementacao)
const TOLERANCIA_PROPORCAO: float = 0.05

var _rng: RandomNumberGenerator


func before_each() -> void:
	PowerUps.limpar()
	_rng = RandomNumberGenerator.new()
	_rng.seed = SEED_FIXA


func after_each() -> void:
	PowerUps.restaurar_padrao()


func _snapshot(raridade: float, pesos: Dictionary) -> DifficultySnapshot:
	return DifficultySnapshot.new(
		DifficultyStage.SCROLL_PADRAO,
		DifficultyStage.SPEED_PADRAO,
		DifficultyStage.K_PADRAO,
		DifficultyStage.PROPORCAO_PADRAO,
		[],
		DifficultyStage.LARGURA_PLATAFORMA_PADRAO,
		DifficultyStage.ATRASO_DESMORONAR_PADRAO,
		DifficultyStage.PROPORCAO_CICLADORAS_PADRAO,
		DifficultyStage.PERIODO_CICLO_PADRAO,
		DifficultyStage.AMPLITUDE_MOVIMENTO_PADRAO,
		DifficultyStage.PERIODO_MOVIMENTO_PADRAO,
		DifficultyStage.PROPORCAO_OSCILANTES_PADRAO,
		DifficultyStage.PROPORCAO_VAI_E_VEM_PADRAO,
		DifficultyStage.VARIACAO_SPEED_LINHA_PADRAO,
		DifficultyStage.PROPORCAO_PISCANTES_PADRAO,
		DifficultyStage.DURACAO_VISIVEL_PADRAO,
		DifficultyStage.DURACAO_INVISIVEL_PADRAO,
		DifficultyStage.AVISO_PISCA_PADRAO,
		DifficultyStage.PROPORCAO_QUE_CAEM_PADRAO,
		raridade,
		pesos
	)


func test_raridade_zero_ou_negativa_devolve_vazio_e_nao_consome_o_rng() -> void:
	# C542: com tipos registrados e pesos validos, raridade <= 0 nao sorteia nem mexe no state.
	PowerUps.registrar(&"a", PowerUpDeTeste)
	var pesos := {&"a": 1.0}
	for raridade: float in [0.0, -0.5]:
		var antes: int = _rng.state
		var nome := PowerUpDraw.sortear(_rng, _snapshot(raridade, pesos))
		assert_eq(nome, &"", "raridade %s devolve vazio" % raridade)
		assert_eq(_rng.state, antes, "raridade %s nao consome o rng" % raridade)


func test_registro_vazio_com_raridade_1_devolve_vazio_sem_consumir() -> void:
	# C542: sem tipo registrado nao ha candidato, mesmo com peso na curva.
	var antes: int = _rng.state
	var nome := PowerUpDraw.sortear(_rng, _snapshot(1.0, {&"a": 1.0}))
	assert_eq(nome, &"", "registro vazio devolve vazio")
	assert_eq(_rng.state, antes, "registro vazio nao consome o rng")


func test_raridade_1_sempre_devolve_tipo_e_nunca_tipo_sem_peso_ou_nao_registrado() -> void:
	# C543: 200 sorteios; "sem_peso" esta registrado sem peso, "fantasma" tem peso mas nao esta registrado.
	PowerUps.registrar(&"a", PowerUpDeTeste)
	PowerUps.registrar(&"sem_peso", PowerUpDeTeste)
	var snapshot := _snapshot(1.0, {&"a": 1.0, &"fantasma": 5.0})
	var fora_do_esperado: int = 0
	for i in 200:
		if PowerUpDraw.sortear(_rng, snapshot) != &"a":
			fora_do_esperado += 1
	assert_eq(fora_do_esperado, 0, "todos os 200 sorteios devolvem o unico candidato valido")


func test_pesos_2_para_1_respeitam_a_proporcao_em_3000_sorteios() -> void:
	# C544: esperado 2/3 e 1/3 (dos pesos 2:1), nao lido da implementacao.
	PowerUps.registrar(&"a", PowerUpDeTeste)
	PowerUps.registrar(&"b", PowerUpDeTeste)
	var snapshot := _snapshot(1.0, {&"a": 2.0, &"b": 1.0})
	var contagem_a: int = 0
	var contagem_b: int = 0
	for i in 3000:
		var nome := PowerUpDraw.sortear(_rng, snapshot)
		if nome == &"a":
			contagem_a += 1
		elif nome == &"b":
			contagem_b += 1
	assert_eq(contagem_a + contagem_b, 3000, "todo sorteio devolve a ou b")
	assert_almost_eq(float(contagem_a) / 3000.0, 2.0 / 3.0, TOLERANCIA_PROPORCAO, "proporcao de a perto de 2/3")
	assert_almost_eq(float(contagem_b) / 3000.0, 1.0 / 3.0, TOLERANCIA_PROPORCAO, "proporcao de b perto de 1/3")


func test_estagio_sem_campos_novos_e_curva_de_producao_tem_raridade_e_pesos_aprovados() -> void:
	# C545: estagio sem os campos = 0.0 e pesos vazios; producao (D3) = 0.04 em todos os estagios; pesos da producao preenchidos (f522 T2).
	var curva := DifficultyCurve.new()
	curva.estagios = [DifficultyStage.new()]
	var vazio := curva.avaliar(0.0, 0.0)
	assert_almost_eq(vazio.get_raridade_power_up(), 0.0, EPS, "estagio sem campo = raridade 0.0")
	assert_true(vazio.get_pesos_power_ups().is_empty(), "estagio sem campo = pesos vazios")
	assert_almost_eq(DifficultySnapshot.new().get_raridade_power_up(), 0.0, EPS, "snapshot novo = 0.0")
	var producao: DifficultyCurve = load(CURVA_PATH)
	assert_eq(producao.estagios.size(), 4, "4 estagios na curva de producao")
	for estagio: DifficultyStage in producao.estagios:
		assert_almost_eq(estagio.raridade_power_up, 0.04, EPS, "raridade de producao = 0.04 (D3)")
		assert_false(estagio.pesos_power_ups.is_empty(), "pesos de producao preenchidos nos 4 estagios (f522 T2)")
	assert_almost_eq(producao.avaliar(0.0, 0.0).get_raridade_power_up(), 0.04, EPS, "snapshot da producao = 0.04")


# C632 [T2] [mutacao]: curva de producao com peso 1 de segunda_chance nos 4 estagios (ADR 0014:38:
# 1,6/1,6/0,8% por plataforma elegivel com raridade 0.04); peso 0 ou removido do estagio impede o tipo de
# sair (registrada no padrao, sem peso nunca e sorteada, os outros dois tipos seguem saindo).
func test_c632_peso_1_de_segunda_chance_nos_4_estagios_e_peso_0_ou_removido_impede_sair() -> void:
	var curva: DifficultyCurve = load(CURVA_PATH)
	assert_eq(curva.estagios.size(), 4, "curva de producao tem 4 estagios")
	for estagio: DifficultyStage in curva.estagios:
		var pesos: Dictionary = estagio.pesos_power_ups
		assert_almost_eq(float(pesos.get(&"camaleao", 0.0)), 2.0, EPS, "peso do camaleao = 2 no estagio")
		assert_almost_eq(float(pesos.get(&"desacelera", 0.0)), 2.0, EPS, "peso do desacelera = 2 no estagio")
		assert_almost_eq(float(pesos.get(&"segunda_chance", 0.0)), 1.0, EPS, "peso 1 de segunda_chance no estagio")
		assert_almost_eq(estagio.raridade_power_up, 0.04, EPS, "raridade de producao mantida em 0.04")
	PowerUps.restaurar_padrao()
	assert_true(PowerUps.nomes().has(&"segunda_chance"), "segunda_chance esta no registro de producao (3 tipos)")
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED_FIXA
	var removido := _snapshot(1.0, {&"camaleao": 2.0, &"desacelera": 2.0})
	var com_peso_zero := _snapshot(1.0, {&"camaleao": 2.0, &"desacelera": 2.0, &"segunda_chance": 0.0})
	var segunda_chance_sorteada: int = 0
	var outros_sorteados: int = 0
	for i in 300:
		if PowerUpDraw.sortear(rng, removido) == &"segunda_chance":
			segunda_chance_sorteada += 1
		if PowerUpDraw.sortear(rng, com_peso_zero) == &"segunda_chance":
			segunda_chance_sorteada += 1
		if PowerUpDraw.sortear(rng, com_peso_zero) != &"":
			outros_sorteados += 1
	assert_eq(segunda_chance_sorteada, 0, "segunda_chance com peso 0 ou removido do estagio nunca e sorteada")
	assert_gt(outros_sorteados, 0, "os outros tipos registrados seguem saindo (o sorteio nao ficou vazio)")


# C633 [T2] [mutacao]: N grande com seed fixa e os pesos do .tres de producao: proporcao ~40/40/20 com
# tolerancia explicita; segunda_chance sai com ~metade da frequencia de cada um dos outros. O esperado vem do
# ADR 0014:38 e dos pesos 2:2:1 do .tres de producao, nao da saida observada.
func test_c633_pesos_2_2_1_da_producao_ficam_pertos_de_40_40_20_com_seed_fixa() -> void:
	PowerUps.restaurar_padrao()
	var pesos_producao: Dictionary = load(CURVA_PATH).avaliar(0.0, 0.0).get_pesos_power_ups()
	var snapshot := _snapshot(1.0, pesos_producao)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED_FIXA
	var camaleao: int = 0
	var desacelera: int = 0
	var segunda_chance: int = 0
	for i in 3000:
		var nome := PowerUpDraw.sortear(rng, snapshot)
		if nome == &"camaleao":
			camaleao += 1
		elif nome == &"desacelera":
			desacelera += 1
		elif nome == &"segunda_chance":
			segunda_chance += 1
	assert_eq(camaleao + desacelera + segunda_chance, 3000, "raridade 1: todo sorteio devolve um dos 3 tipos de producao")
	assert_gt(camaleao, 0, "camaleao saiu (a divisao abaixo nao e por zero)")
	assert_gt(desacelera, 0, "desacelera saiu (a divisao abaixo nao e por zero)")
	assert_almost_eq(float(camaleao) / 3000.0, 0.4, TOLERANCIA_PROPORCAO, "camaleao ~40% (peso 2 de 5)")
	assert_almost_eq(float(desacelera) / 3000.0, 0.4, TOLERANCIA_PROPORCAO, "desacelera ~40% (peso 2 de 5)")
	assert_almost_eq(float(segunda_chance) / 3000.0, 0.2, TOLERANCIA_PROPORCAO, "segunda_chance ~20% (peso 1 de 5)")
	# Tolerancia da razao (~4,7 desvios-padrao em 3000 sorteios): mais larga que a das proporcoes porque a razao
	# de duas contagens binomiais tem mais ruido; segue reprovando quem rompe os pesos (ex.: peso 5 daria 0,2).
	assert_almost_eq(
		float(segunda_chance) / float(camaleao), 0.5, 0.1,
		"segunda_chance sai com ~metade da frequencia do camaleao"
	)
	assert_almost_eq(
		float(segunda_chance) / float(desacelera), 0.5, 0.1,
		"segunda_chance sai com ~metade da frequencia do desacelera"
	)
