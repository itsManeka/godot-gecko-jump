extends GutTest

# f522 T8: acumulo e aparecimento com os power-ups REAIS de producao (camaleao, desacelera e segunda_chance no
# registro padrao de PowerUps, duracao/fator de ressources/power_ups.tres, raridade/pesos da curva). Cenarios
# C623-C627 do 05-test-plan da f522; f526 T2 atualiza o conjunto de producao para 3 tipos com pesos 2:2:1
# (C634/C635 do plano da f526). O registro de producao e restaurado no after_each de cada teste (fixture do plano).

const NIVEL_SCENE := "res://scenes/ScrollLevel.tscn"
const CURVA_PATH := "res://ressources/curva_dificuldade.tres"
const SEMENTE := 20260
const LINHAS_CRIADAS := 6
const EPS: float = 0.0001
const SORTEIOS_2_2 := 3000
# Tolerancia explicita (C627): em 3000 sorteios 2:2 o desvio-padrao da fracao e ~0.0091; 0.05 cobre ~5 desvios.
const TOLERANCIA_50_50: float = 0.05
const SORTEIOS_PRODUCAO := 5000
# Tolerancia explicita (C627): raridade de producao 0.04 gera ~200 tipos em 5000 sorteios; desvio ~0.035, 0.2 ~ 5 desvios.
const TOLERANCIA_PRODUCAO: float = 0.2
# Tipo registrado so neste teste, sem peso em nenhum estagio: provar que peso 0 nunca e sorteado (C627).
const TIPO_FANTASMA: StringName = &"fantasma_sem_peso"


# Camaleao real instrumentado (nome, duracao do Resource e ignora_cor herdados de PowerUpCamaleao): os hooks do
# contrato sao neutros, sobrescreve-los nao muda o efeito. Prova que recoletar o mesmo tipo NAO reativa (C624).
class _CamaleaoContado extends PowerUpCamaleao:
	var ativacoes: int = 0
	var encerramentos: int = 0


	func ao_ativar() -> void:
		ativacoes += 1


	func ao_encerrar() -> void:
		encerramentos += 1


var _cor_original: Enums.COLOR
var _config: PowerUpConfig


func before_each() -> void:
	PowerUps.restaurar_padrao()
	_cor_original = Global.cor_gecko
	Global.cor_gecko = Enums.COLOR.AZUL
	Global.platforms = []
	Global.iniciado = false
	Global.sem_derrota = false
	_config = PowerUpConfig.carregar()


func after_each() -> void:
	PowerUps.restaurar_padrao()
	Global.cor_gecko = _cor_original
	Global.platforms = []
	Global.iniciado = false
	Global.sem_derrota = false


# Estagio de teste com a raridade dada e os pesos 2:2:1 de producao (f526 T2) para os 3 tipos reais
func _estagio(raridade: float) -> DifficultyStage:
	var estagio := DifficultyStage.new()
	estagio.raridade_power_up = raridade
	estagio.pesos_power_ups = {&"camaleao": 2.0, &"desacelera": 2.0, &"segunda_chance": 1.0}
	return estagio


func _curva(raridade: float) -> DifficultyCurve:
	var curva := DifficultyCurve.new()
	curva.estagios = [_estagio(raridade)]
	return curva


func _estado(raridade: float) -> DifficultyState:
	var estado := DifficultyState.new(_curva(raridade))
	estado.progresso_inicial = 0.0
	return estado


# Nivel com a seed fixa; `estado_nas_iniciais` injeta a dificuldade nas linhas do .tscn (raridade nelas) para
# provar que so a flag de elegibilidade, e nao a raridade, protege a linha inicial (C626).
func _nivel(raridade: float, estado_nas_iniciais: bool = false) -> ScrollLevel:
	var nivel: ScrollLevel = load(NIVEL_SCENE).instantiate()
	var estado := _estado(raridade)
	nivel.semente = SEMENTE
	nivel.dificuldade = estado
	if estado_nas_iniciais:
		for linha in nivel.get_node("RunningPlatforms").get_children():
			linha.dificuldade = estado
	Global.set_iniciado(false)
	add_child_autofree(nivel)
	for k in LINHAS_CRIADAS:
		nivel.create_new_running_platform(InitialRows.Y_TOPO - InitialRows.ESPACAMENTO * (k + 1))
	await wait_physics_frames(3)
	return nivel


func _plataformas(linha: Node) -> Array:
	var filhas: Array = []
	for filha in linha.get_children():
		if filha is Platform:
			filhas.append(filha)
	return filhas


func _tem_icone(plataforma) -> bool:
	return plataforma.tipo_power_up != &"" and is_instance_valid(plataforma.icone_power_up)


# C623 [T8] [mutacao]: registro de producao — coletar Desacelera com Camaleao ativo deixa so Desacelera ativo com
# duracao cheia, Camaleao encerrado (cor_livre() falso, fator_scroll() vigente do Resource).
func test_c623_desacelera_com_camaleao_ativo_deixa_sozinho_o_desacelera() -> void:
	var estado := PowerUpState.new()
	var camaleao := PowerUps.resolver(&"camaleao")
	var desacelera := PowerUps.resolver(&"desacelera")
	assert_eq(camaleao.nome, &"camaleao", "resolver devolve o camaleao de producao")
	assert_eq(desacelera.nome, &"desacelera", "resolver devolve o desacelera de producao")
	estado.coletar(camaleao)
	assert_true(estado.cor_livre(), "camaleao ativo: cor livre")
	assert_almost_eq(estado.fator_scroll(), 1.0, EPS, "camaleao nao altera o scroll")
	estado.tick(2.0)
	estado.coletar(desacelera)
	assert_eq(estado.ativo(), desacelera, "so o desacelera fica ativo")
	assert_false(estado.cor_livre(), "camaleao encerrado: cor livre falsa na substituicao")
	assert_almost_eq(estado.fator_scroll(), _config.fator_desacelera_vigente(), EPS, "fator vigente do desacelera")
	assert_almost_eq(estado.restante(), _config.duracao_desacelera_vigente(), EPS, "desacelera com duracao cheia")


# C624 [T8] [mutacao]: coletar Camaleao com Camaleao ativo reinicia a duracao sem reativar (ao_ativar nao
# rechamado; o ativo original permanece e a nova instancia nao e ativada nem a original encerrada).
func test_c624_recoletar_camaleao_reinicia_duracao_sem_reativar() -> void:
	var duracao: float = _config.duracao_camaleao_vigente()
	var estado := PowerUpState.new()
	var primeiro := _CamaleaoContado.new()
	var segundo := _CamaleaoContado.new()
	estado.coletar(primeiro)
	assert_eq(primeiro.ativacoes, 1, "primeira coleta ativa o camaleao 1x")
	estado.tick(2.0)
	assert_almost_eq(estado.restante(), duracao - 2.0, EPS, "tempo parcial consumido antes de recoletar")
	estado.coletar(segundo)
	assert_eq(estado.ativo(), primeiro, "o ativo original permanece: nao houve reativacao")
	assert_almost_eq(estado.restante(), duracao, EPS, "duracao reiniciada cheia")
	assert_eq(primeiro.ativacoes, 1, "ao_ativar do original NAO e rechamado")
	assert_eq(primeiro.encerramentos, 0, "ao_encerrar do original NAO roda ao recoletar o mesmo tipo")
	assert_eq(segundo.ativacoes, 0, "a nova instancia NAO e ativada")
	assert_eq(segundo.encerramentos, 0, "a nova instancia NAO e encerrada")
	assert_true(estado.cor_livre(), "efeito do camaleao segue vigente apos recoletar")


# C625 [T8] [mutacao] + C634 [T2/f526]: raridade 0: nenhum icone em N linhas; raridade 1: toda plataforma elegivel
# tem icone e o tipo sorteado pertence ao registro de producao (camaleao, desacelera ou segunda_chance; seed fixa,
# pesos 2:2:1 de producao).
func test_c625_raridade_0_nenhum_icone_raridade_1_todo_elegivel_com_tipo_real() -> void:
	var nivel_zero: ScrollLevel = await _nivel(0.0)
	var plataformas_zero: int = 0
	var com_icone_zero: int = 0
	for linha in nivel_zero.running_platforms.get_children():
		for p in _plataformas(linha):
			plataformas_zero += 1
			if _tem_icone(p):
				com_icone_zero += 1
	assert_gt(plataformas_zero, 10, "raridade 0: o nivel gerou plataformas em N linhas")
	assert_eq(com_icone_zero, 0, "raridade 0: nenhum icone nasce")
	nivel_zero.queue_free()
	await wait_physics_frames(2)
	Global.platforms = []

	var nivel_um: ScrollLevel = await _nivel(1.0)
	var linhas: Array = nivel_um.running_platforms.get_children()
	var iniciais: int = linhas.size() - LINHAS_CRIADAS
	var elegiveis: int = 0
	var sem_icone: int = 0
	var tipos_fora: Array[String] = []
	for i in linhas.size():
		if i < iniciais:
			continue
		for p in _plataformas(linhas[i]):
			elegiveis += 1
			if not _tem_icone(p):
				sem_icone += 1
			elif p.tipo_power_up != &"camaleao" and p.tipo_power_up != &"desacelera" and p.tipo_power_up != &"segunda_chance":
				tipos_fora.append(String(p.tipo_power_up))
	assert_gt(elegiveis, 10, "raridade 1: ha plataformas elegiveis nas linhas de fluxo")
	assert_eq(sem_icone, 0, "raridade 1: toda plataforma elegivel tem icone")
	assert_eq(tipos_fora.size(), 0, "todo icone sorteado pertence ao registro de producao (camaleao, desacelera ou segunda_chance)")


# C626 [T8] [mutacao] + C634 [T2/f526]: linha inicial nunca tem icone, nem com raridade 1 (o estado com raridade 1
# e injetado nas linhas do .tscn: so a flag de elegibilidade as protege).
func test_c626_linha_inicial_nunca_tem_icone_nem_com_raridade_1() -> void:
	var nivel: ScrollLevel = await _nivel(1.0, true)
	var linhas: Array = nivel.running_platforms.get_children()
	var iniciais: int = linhas.size() - LINHAS_CRIADAS
	assert_gte(iniciais, 5, "as 5 linhas do .tscn (mais as extras) existem antes das criadas")
	var icone_na_inicial: int = 0
	for i in mini(iniciais, linhas.size()):
		assert_false(linhas[i].power_ups_elegivel, "linha inicial %d nunca e elegivel" % i)
		for p in _plataformas(linhas[i]):
			if _tem_icone(p):
				icone_na_inicial += 1
	assert_eq(icone_na_inicial, 0, "linha inicial nunca tem icone, nem com raridade 1")


# C627 [T8/f522] + C635 [T2/f526]: pesos 2:2 dao distribuicao proxima de 50/50 em N sorteios com seed fixa
# (tolerancia explicita, mecanismo sintetico); com o .tres de producao (3 pesos 2:2:1, f526 T2) todo tipo sorteado
# pertence ao conjunto registrado de producao, a fracao segue os pesos (tipo com peso 0 nunca e sorteado) e a
# segunda_chance fica com a metade da frequencia de cada um dos outros.
func test_c627_pesos_2_2_50_50_e_tres_de_producao_respeita_os_pesos() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEMENTE
	var estagio_2_2 := DifficultyStage.new()
	estagio_2_2.raridade_power_up = 1.0
	estagio_2_2.pesos_power_ups = {&"camaleao": 2.0, &"desacelera": 2.0}
	var curva_2_2 := DifficultyCurve.new()
	curva_2_2.estagios = [estagio_2_2]
	var snapshot_2_2: DifficultySnapshot = curva_2_2.avaliar(0.0, 0.0)
	var camaleao: int = 0
	var desacelera: int = 0
	for i in SORTEIOS_2_2:
		var nome := PowerUpDraw.sortear(rng, snapshot_2_2)
		if nome == &"camaleao":
			camaleao += 1
		elif nome == &"desacelera":
			desacelera += 1
	assert_eq(camaleao + desacelera, SORTEIOS_2_2, "raridade 1: todo sorteio devolve um dos tipos reais")
	assert_almost_eq(float(camaleao) / float(SORTEIOS_2_2), 0.5, TOLERANCIA_50_50, "pesos 2:2 dao ~50/50 de camaleao")
	assert_almost_eq(float(desacelera) / float(SORTEIOS_2_2), 0.5, TOLERANCIA_50_50, "pesos 2:2 dao ~50/50 de desacelera")

	PowerUps.registrar(TIPO_FANTASMA, PowerUpDeTeste)
	rng.seed = SEMENTE + 1
	var producao: DifficultyCurve = load(CURVA_PATH)
	var snapshot_producao: DifficultySnapshot = producao.avaliar(0.0, 0.0)
	var pesos: Dictionary = snapshot_producao.get_pesos_power_ups()
	var peso_camaleao: float = float(pesos.get(&"camaleao", 0.0))
	var peso_desacelera: float = float(pesos.get(&"desacelera", 0.0))
	var peso_segunda_chance: float = float(pesos.get(&"segunda_chance", 0.0))
	assert_gt(peso_camaleao, 0.0, "curva de producao da peso ao camaleao")
	assert_gt(peso_desacelera, 0.0, "curva de producao da peso ao desacelera")
	assert_gt(peso_segunda_chance, 0.0, "curva de producao da peso a segunda_chance (f526 T2)")
	var total_pesos: float = peso_camaleao + peso_desacelera + peso_segunda_chance
	var fracao_camaleao: float = peso_camaleao / total_pesos
	var fracao_segunda_chance: float = peso_segunda_chance / total_pesos
	var tipos_sorteados: int = 0
	camaleao = 0
	desacelera = 0
	var segunda_chance: int = 0
	var fantasma: int = 0
	for i in SORTEIOS_PRODUCAO:
		var nome := PowerUpDraw.sortear(rng, snapshot_producao)
		if nome == &"":
			continue
		tipos_sorteados += 1
		if nome == &"camaleao":
			camaleao += 1
		elif nome == &"desacelera":
			desacelera += 1
		elif nome == &"segunda_chance":
			segunda_chance += 1
		elif nome == TIPO_FANTASMA:
			fantasma += 1
	assert_gt(tipos_sorteados, 100, "a raridade de producao (0.04) gerou tipos suficientes para conferir os pesos")
	assert_eq(fantasma, 0, "tipo registrado com peso 0 nunca e sorteado")
	assert_eq(
		camaleao + desacelera + segunda_chance, tipos_sorteados,
		"todo tipo sorteado da producao pertence ao conjunto registrado (camaleao, desacelera ou segunda_chance)"
	)
	assert_almost_eq(
		float(camaleao) / float(tipos_sorteados), fracao_camaleao, TOLERANCIA_PRODUCAO,
		"o tipo sorteado segue a fracao dos pesos do .tres de producao"
	)
	assert_almost_eq(
		float(segunda_chance) / float(tipos_sorteados), fracao_segunda_chance, TOLERANCIA_PRODUCAO,
		"segunda_chance segue a fracao do peso 1 (metade da frequencia de cada um dos outros)"
	)
