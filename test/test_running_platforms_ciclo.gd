extends GutTest

# f466 T5: RunningPlatforms sorteia cicladoras (PlatformColorCycle por plataforma) pelo snapshot do nascimento.
# Curva propria do teste (nao le o .tres de producao): so o estagio 3 liga a mecanica; proporcao vem de cada teste.

const GERADOR_SCENE := "res://scenes/RunningPlatforms.tscn"
# Plataformas criadas na amostra da fracao e tolerancia absoluta declarada (3 desvios padrao de n = 300, p = 0,3)
const AMOSTRA_FRACAO := 300
const TOLERANCIA_FRACAO := 0.08

var _cor_original: Enums.COLOR


func before_each() -> void:
	PlatformModifiers.restaurar_padrao()
	_cor_original = Global.cor_gecko
	Global.platforms = []
	Global.iniciado = false
	Global.sem_derrota = false


func after_each() -> void:
	PlatformModifiers.restaurar_padrao()
	Global.cor_gecko = _cor_original
	Global.platforms = []
	Global.iniciado = false
	Global.sem_derrota = false


func _estagio(inicio: float, proporcao: float, mecanicas: Array[StringName]) -> DifficultyStage:
	var estagio := DifficultyStage.new()
	estagio.progresso_inicio = inicio
	estagio.proporcao_cicladoras = proporcao
	estagio.mecanicas = mecanicas
	return estagio


# 4 estagios: o ciclo so esta ligado (nome da mecanica) no 3; todos carregam a mesma proporcao
func _curva(proporcao: float) -> DifficultyCurve:
	var curva := DifficultyCurve.new()
	var vazio: Array[StringName] = []
	var ligadas: Array[StringName] = [PlatformModifiers.PLATAFORMAS_QUE_MUDAM_DE_COR]
	curva.estagios = [
		_estagio(0.0, proporcao, vazio),
		_estagio(0.2, proporcao, vazio),
		_estagio(0.5, proporcao, vazio),
		_estagio(0.8, proporcao, ligadas),
	]
	return curva


func _estado(proporcao: float, progresso: float) -> DifficultyState:
	var estado := DifficultyState.new(_curva(proporcao))
	estado.progresso_inicial = progresso
	return estado


func _rng(semente: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	return rng


func _gerador(tipo: Enums.PLATFORM_TYPE, estado: DifficultyState, inicial: bool = false) -> Node2D:
	var gerador: Node2D = load(GERADOR_SCENE).instantiate()
	gerador.platform_type = tipo
	gerador.garantir_cor_inicial = inicial
	gerador.dificuldade = estado
	gerador.rng = _rng(7)
	gerador.position = Vector2(0, 100)
	Global.set_iniciado(true)
	add_child_autofree(gerador)
	return gerador


func _plataformas(gerador: Node) -> Array:
	var filhas: Array = []
	for filha in gerador.get_children():
		if filha is Platform:
			filhas.append(filha)
	return filhas


func _com_ciclo(plataformas: Array) -> int:
	var total := 0
	for p in plataformas:
		if p.obter_ciclo() != null:
			total += 1
	return total


func test_c251_proporcao_1_todas_as_moveis_tem_ciclo_e_com_0_nenhuma() -> void:
	var todas := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, _estado(1.0, 1.0))
	todas.new_platform()
	var com: Array = _plataformas(todas)
	assert_gt(com.size(), 1, "linha nasce preenchida")
	assert_eq(_com_ciclo(com), com.size(), "proporcao 1.0: toda plataforma movel tem ciclo")

	var nenhuma := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, _estado(0.0, 1.0))
	nenhuma.new_platform()
	var sem: Array = _plataformas(nenhuma)
	assert_gt(sem.size(), 1, "linha nasce preenchida")
	assert_eq(_com_ciclo(sem), 0, "proporcao 0.0: nenhuma plataforma tem ciclo")


func test_c252_proporcao_0_3_a_fracao_observada_fica_dentro_da_tolerancia() -> void:
	var gerador := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, _estado(0.3, 1.0))
	for i in AMOSTRA_FRACAO:
		gerador.new_platform()
	var filhas: Array = _plataformas(gerador)
	assert_gte(filhas.size(), 200, "amostra com N >= 200")
	var fracao: float = float(_com_ciclo(filhas)) / float(filhas.size())
	assert_almost_eq(fracao, 0.3, TOLERANCIA_FRACAO, "fracao de cicladoras ~0.3 (tolerancia 0.08)")


func test_c253_estagios_sem_a_mecanica_e_gerador_inicial_nunca_recebem_ciclo() -> void:
	# E0..E2 com proporcao 1.0 mas sem o nome da mecanica na lista do estagio
	for progresso in [0.0, 0.2, 0.5]:
		var movel := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, _estado(1.0, progresso))
		movel.new_platform()
		assert_gt(_plataformas(movel).size(), 1, "linha nasce preenchida (progresso %s)" % progresso)
		assert_eq(_com_ciclo(_plataformas(movel)), 0, "estagio sem mecanica nunca tem ciclo (progresso %s)" % progresso)
		var estatico := _gerador(Enums.PLATFORM_TYPE.STATIC, _estado(1.0, progresso))
		assert_eq(_plataformas(estatico).size(), 3, "3 estaticas")
		assert_eq(_com_ciclo(_plataformas(estatico)), 0, "estatica sem mecanica nunca tem ciclo (progresso %s)" % progresso)

	# Estagio 3 com a mecanica e proporcao 1.0: a linha inicial (garantir_cor_inicial) continua sem ciclo
	var inicial := _gerador(Enums.PLATFORM_TYPE.STATIC, _estado(1.0, 1.0), true)
	assert_eq(_plataformas(inicial).size(), 3, "3 estaticas iniciais")
	assert_eq(_com_ciclo(_plataformas(inicial)), 0, "gerador inicial nunca recebe ciclo")

	# Controle: a estatica comum do mesmo estagio recebe (a mecanica vale para estaticas)
	var comum := _gerador(Enums.PLATFORM_TYPE.STATIC, _estado(1.0, 1.0), false)
	assert_eq(_com_ciclo(_plataformas(comum)), 3, "estatica comum com proporcao 1.0 tem ciclo")


func test_c254_cicladoras_da_mesma_linha_tem_instancias_e_sequencias_independentes() -> void:
	Global.cor_gecko = Enums.COLOR.AMARELO
	var gerador := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, _estado(1.0, 1.0))
	var filhas: Array = _plataformas(gerador)
	assert_gte(filhas.size(), 2, "linha com ao menos 2 plataformas")
	var a: PlatformColorCycle = filhas[0].obter_ciclo()
	var b: PlatformColorCycle = filhas[1].obter_ciclo()
	assert_not_null(a, "1a e cicladora")
	assert_not_null(b, "2a e cicladora")
	assert_ne(a, b, "instancias diferentes por plataforma")
	assert_true(a.get_sequencia() != b.get_sequencia(), "sequencias diferentes com o rng que as distingue")


func test_cicladora_tem_a_cor_do_gecko_dentro_do_alcance_mesmo_com_ela_so_depois() -> void:
	var gerador := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, _estado(1.0, 1.0))
	var periodo: float = gerador._snapshot_nascimento.get_periodo_ciclo()
	var entradas: int = int(ceil(gerador._alcance_s(periodo) / periodo))
	assert_lt(entradas, PlatformColorCycle.CORES_NA_SEQUENCIA - 1, "o alcance cobre so o comeco da sequencia")
	var achou := false
	for semente in range(1, 300):
		var sorteada := PlatformColorCycle.new()
		sorteada.iniciar(Enums.COLOR.AZUL, periodo, _rng(semente))
		var sequencia: Array = sorteada.get_sequencia()
		var cor_gecko: int = sequencia[entradas]
		if sequencia.slice(0, entradas).has(cor_gecko):
			continue
		achou = true
		Global.cor_gecko = cor_gecko as Enums.COLOR
		gerador._rng_ciclo = _rng(semente)
		var ciclo: PlatformColorCycle = gerador._novo_ciclo(Enums.COLOR.AZUL)
		assert_true(
			ciclo.get_sequencia().slice(0, entradas).has(cor_gecko),
			"semente %d: cor do gecko forcada dentro das %d primeiras entradas" % [semente, entradas]
		)
		break
	assert_true(achou, "ha semente cuja sequencia so tem a cor do gecko fora do alcance")


func test_c255_initial_xs_inalterado_e_sem_derrota_mantem_cor_inicial_com_ciclo() -> void:
	var spawn_x := 210.0
	var esperado: Array[float] = MovingRowFill.initial_xs(spawn_x, true, MovingRowFill.LARGURA_PADRAO, 60.0)
	var gerador := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, _estado(1.0, 1.0))
	var xs: Array = []
	for p in _plataformas(gerador):
		assert_not_null(p.obter_ciclo(), "ciclo ativo")
		if p.position.x < spawn_x:
			xs.append(p.position.x)
	xs.sort()
	var esperado_ordenado: Array = esperado.duplicate()
	esperado_ordenado.sort()
	assert_gt(esperado_ordenado.size(), 0, "baseline tem posicoes")
	assert_eq(xs, esperado_ordenado, "x das plataformas iguais ao baseline com ciclo ativo")

	Global.sem_derrota = true
	Global.cor_gecko = ((Enums.COR_INICIAL + 1) % Enums.COLOR.size()) as Enums.COLOR
	var sem_derrota := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, _estado(1.0, 1.0))
	var estatica := _gerador(Enums.PLATFORM_TYPE.STATIC, _estado(1.0, 1.0))
	var todas: Array = _plataformas(sem_derrota) + _plataformas(estatica)
	assert_gt(todas.size(), 3, "plataformas criadas")
	for p in todas:
		assert_not_null(p.obter_ciclo(), "sem_derrota: ciclo ativo")
		assert_eq(p.color, Enums.COR_INICIAL, "sem_derrota: cor inicial COR_INICIAL")
