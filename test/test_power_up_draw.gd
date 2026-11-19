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
	# C545: estagio sem os campos = 0.0 e pesos vazios; producao (D3) = 0.04 em todos os estagios, pesos vazios.
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
		assert_true(estagio.pesos_power_ups.is_empty(), "pesos de producao vazios (D3)")
	assert_almost_eq(producao.avaliar(0.0, 0.0).get_raridade_power_up(), 0.04, EPS, "snapshot da producao = 0.04")
