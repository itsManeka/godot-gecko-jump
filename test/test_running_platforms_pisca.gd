extends GutTest

# f468 T4: RunningPlatforms sorteia plataformas que piscam (PlatformBlink por plataforma) pelo snapshot do nascimento,
# com ancora, rng dedicado e exclusoes. Curva propria do teste: so o estagio 1 liga a mecanica.

const GERADOR_SCENE := "res://scenes/RunningPlatforms.tscn"
const SEMENTES := [1, 7, 42, 99, 12345]
const NOVAS_NA_LINHA := 40

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


func _estagio(inicio: float, mecanicas: Array[StringName], piscantes: float, cicladoras: float) -> DifficultyStage:
	var estagio := DifficultyStage.new()
	estagio.progresso_inicio = inicio
	estagio.mecanicas = mecanicas
	estagio.proporcao_piscantes = piscantes
	estagio.proporcao_cicladoras = cicladoras
	estagio.proporcao_oscilantes = 1.0
	estagio.duracao_visivel = 3.0
	estagio.duracao_invisivel = 1.2
	estagio.aviso_pisca = 0.6
	return estagio


# Estagio 0 sem mecanicas; estagio 1 com `ligadas`. Ambos com as mesmas proporcoes
func _estado(ligadas: Array[StringName], piscantes: float, cicladoras: float, progresso: float) -> DifficultyState:
	var vazio: Array[StringName] = []
	var curva := DifficultyCurve.new()
	curva.estagios = [_estagio(0.0, vazio, piscantes, cicladoras), _estagio(0.5, ligadas, piscantes, cicladoras)]
	var estado := DifficultyState.new(curva)
	estado.progresso_inicial = progresso
	return estado


func _so_pisca() -> Array[StringName]:
	var ligadas: Array[StringName] = [PlatformModifiers.PLATAFORMAS_QUE_PISCAM]
	return ligadas


func _rng(semente: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	return rng


func _gerador(
	tipo: Enums.PLATFORM_TYPE, estado: DifficultyState, semente: int = 7, inicial: bool = false
) -> Node2D:
	var gerador: Node2D = load(GERADOR_SCENE).instantiate()
	gerador.platform_type = tipo
	gerador.garantir_cor_inicial = inicial
	gerador.dificuldade = estado
	gerador.rng = _rng(semente)
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


func _movel_com_amostra(estado: DifficultyState, semente: int) -> Array:
	var gerador := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, estado, semente)
	for i in NOVAS_NA_LINHA:
		gerador.new_platform()
	return _plataformas(gerador)


func _piscantes(plataformas: Array) -> int:
	var total := 0
	for p in plataformas:
		if p.obter_pisca() != null:
			total += 1
	return total


func test_c312_proporcao_0_nenhuma_piscante_e_rng_dedicado_nao_consumido() -> void:
	var gerador := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, _estado(_so_pisca(), 0.0, 0.0, 1.0))
	for i in NOVAS_NA_LINHA:
		gerador.new_platform()
	assert_gt(_plataformas(gerador).size(), 1, "linha criada")
	assert_eq(_piscantes(_plataformas(gerador)), 0, "proporcao 0: nenhuma piscante")
	assert_null(gerador._rng_pisca, "rng dedicado nunca criado nem consumido com proporcao 0")


func test_c313_estaticas_proporcao_1_ao_menos_1_de_3_nao_pisca() -> void:
	for semente in SEMENTES:
		for i in 10:
			var gerador := _gerador(Enums.PLATFORM_TYPE.STATIC, _estado(_so_pisca(), 1.0, 0.0, 1.0), semente + i)
			var filhas := _plataformas(gerador)
			assert_eq(filhas.size(), 3, "3 estaticas")
			assert_lt(_piscantes(filhas), 3, "semente %d+%d: >= 1 estatica sem piscar" % [semente, i])
	var controle := _gerador(Enums.PLATFORM_TYPE.STATIC, _estado(_so_pisca(), 1.0, 0.0, 1.0))
	assert_gt(_piscantes(_plataformas(controle)), 0, "controle: com proporcao 1.0 ha piscantes")


func test_c314_moveis_proporcao_1_nunca_2_piscantes_consecutivas() -> void:
	for semente in SEMENTES:
		var filhas := _movel_com_amostra(_estado(_so_pisca(), 1.0, 0.0, 1.0), semente)
		assert_gt(_piscantes(filhas), 0, "semente %d: controle, ha piscantes" % semente)
		var anterior := false
		for p in filhas:
			var pisca: bool = p.obter_pisca() != null
			assert_false(anterior and pisca, "semente %d: 2 piscantes consecutivas" % semente)
			anterior = pisca


func test_c315_linha_inicial_nunca_tem_piscante() -> void:
	for semente in SEMENTES:
		var gerador := _gerador(Enums.PLATFORM_TYPE.STATIC, _estado(_so_pisca(), 1.0, 0.0, 1.0), semente, true)
		assert_eq(_plataformas(gerador).size(), 3, "3 estaticas iniciais")
		assert_eq(_piscantes(_plataformas(gerador)), 0, "linha inicial sem piscante (semente %d)" % semente)


func test_c316_cicladora_e_piscante_nunca_na_mesma_plataforma() -> void:
	var ligadas: Array[StringName] = [PlatformModifiers.PLATAFORMAS_QUE_MUDAM_DE_COR, PlatformModifiers.PLATAFORMAS_QUE_PISCAM]
	for semente in SEMENTES:
		var filhas := _movel_com_amostra(_estado(ligadas, 1.0, 1.0, 1.0), semente)
		for p in filhas:
			assert_false(p.obter_ciclo() != null and p.obter_pisca() != null, "semente %d: ciclo e pisca juntos" % semente)
	# Com a cicladora em 0 as piscantes aparecem (a exclusao e pela cicladora, nao pela mecanica sumir)
	var sem_ciclo := _movel_com_amostra(_estado(ligadas, 1.0, 0.0, 1.0), 7)
	assert_gt(_piscantes(sem_ciclo), 0, "controle: sem cicladoras ha piscantes")


func test_movel_piscante_antes_de_cicladora_vira_inerte_nenhuma_ativa_antes_de_cicladora() -> void:
	var ligadas: Array[StringName] = [PlatformModifiers.PLATAFORMAS_QUE_MUDAM_DE_COR, PlatformModifiers.PLATAFORMAS_QUE_PISCAM]
	var neutralizadas := 0
	for semente in SEMENTES:
		var filhas := _movel_com_amostra(_estado(ligadas, 1.0, 0.7, 1.0), semente)
		for i in range(filhas.size() - 1):
			var atual: Platform = filhas[i]
			var proxima: Platform = filhas[i + 1]
			var pisca: PlatformBlink = atual.obter_pisca()
			if pisca == null or proxima.obter_ciclo() == null:
				continue
			neutralizadas += 0 if pisca.esta_ativo() else 1
			assert_false(pisca.esta_ativo(), "semente %d: piscante ativa antes de cicladora (indice %d)" % [semente, i])
	assert_gt(neutralizadas, 0, "controle: ha piscante neutralizada antes de cicladora")


func test_c317_mesma_semente_mesmas_piscantes_e_fases() -> void:
	var a := _movel_com_amostra(_estado(_so_pisca(), 0.5, 0.0, 1.0), 42)
	var b := _movel_com_amostra(_estado(_so_pisca(), 0.5, 0.0, 1.0), 42)
	var assinatura_a: Array = []
	var assinatura_b: Array = []
	for p in a:
		assinatura_a.append(p.obter_pisca().get_fase() if p.obter_pisca() != null else -1.0)
	for p in b:
		assinatura_b.append(p.obter_pisca().get_fase() if p.obter_pisca() != null else -1.0)
	assert_eq(assinatura_a.size(), assinatura_b.size(), "mesmo numero de plataformas")
	assert_true(assinatura_a.any(func(f): return f >= 0.0), "ha piscantes")
	assert_eq(assinatura_a, assinatura_b, "mesmas piscantes com as mesmas fases")


func _assinatura_sem_pisca(plataformas: Array) -> Array:
	var assinatura: Array = []
	for p in plataformas:
		var ciclo: PlatformColorCycle = p.obter_ciclo()
		var seno: PlatformSineMotion = null
		for m in p._modificadores:
			if m is PlatformSineMotion:
				seno = m
		assinatura.append(
			[p.color, ciclo.get_sequencia() if ciclo != null else null, seno.get_fase() if seno != null else null]
		)
	return assinatura


func test_c318_mecanica_ligada_nao_desloca_cores_ciclo_nem_oscilacao() -> void:
	Global.cor_gecko = Enums.COLOR.AZUL
	var base: Array[StringName] = [
		PlatformModifiers.PLATAFORMAS_QUE_MUDAM_DE_COR,
		PlatformModifiers.MOVIMENTO_SENO,
	]
	var com: Array[StringName] = base.duplicate()
	com.append(PlatformModifiers.PLATAFORMAS_QUE_PISCAM)
	for semente in SEMENTES:
		var sem_mecanica := _movel_com_amostra(_estado(base, 1.0, 0.5, 1.0), semente)
		var com_mecanica := _movel_com_amostra(_estado(com, 1.0, 0.5, 1.0), semente)
		assert_eq(_piscantes(sem_mecanica), 0, "controle: sem o nome nao ha piscante")
		assert_gt(_piscantes(com_mecanica), 0, "com o nome ha piscantes (semente %d)" % semente)
		assert_true(
			_assinatura_sem_pisca(com_mecanica) == _assinatura_sem_pisca(sem_mecanica),
			"semente %d: cores/ciclo/oscilacao identicos com e sem a mecanica" % semente
		)


func test_c319_sem_derrota_nenhuma_piscante() -> void:
	Global.sem_derrota = true
	var movel := _movel_com_amostra(_estado(_so_pisca(), 1.0, 0.0, 1.0), 7)
	var estatica := _gerador(Enums.PLATFORM_TYPE.STATIC, _estado(_so_pisca(), 1.0, 0.0, 1.0))
	assert_gt(movel.size(), 1, "plataformas moveis criadas")
	assert_eq(_piscantes(movel), 0, "sem_derrota: nenhuma movel piscante")
	assert_eq(_piscantes(_plataformas(estatica)), 0, "sem_derrota: nenhuma estatica piscante")


func test_c320_estagio_sem_a_mecanica_nenhuma_piscante() -> void:
	var vazio: Array[StringName] = []
	for progresso in [0.0, 1.0]:
		var movel := _movel_com_amostra(_estado(vazio, 1.0, 0.0, progresso), 7)
		var estatica := _gerador(Enums.PLATFORM_TYPE.STATIC, _estado(vazio, 1.0, 0.0, progresso))
		assert_gt(movel.size(), 1, "plataformas criadas")
		assert_eq(_piscantes(movel), 0, "sem o nome da mecanica nenhuma movel pisca (progresso %s)" % progresso)
		assert_eq(_piscantes(_plataformas(estatica)), 0, "sem o nome nenhuma estatica pisca (progresso %s)" % progresso)
