extends GutTest

# f465 T5: RunningPlatforms resolve os modificadores do snapshot no nascimento e entrega a cada plataforma criada.
# Curva propria do teste (nao le o .tres de producao): estagio 3 liga as duas mecanicas com largura 44.

const GERADOR_SCENE := "res://scenes/RunningPlatforms.tscn"
const LARGURA_ESTAGIO_3 := 44.0
const LARGURA_PADRAO := 60.0

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


func _estagio(inicio: float, largura: float, mecanicas: Array[StringName]) -> DifficultyStage:
	var estagio := DifficultyStage.new()
	estagio.progresso_inicio = inicio
	estagio.largura_plataforma = largura
	estagio.mecanicas = mecanicas
	return estagio


# Curva de 4 estagios: 0 sem mecanicas (60) ... 3 com as duas mecanicas (44)
func _curva() -> DifficultyCurve:
	var curva := DifficultyCurve.new()
	var vazio: Array[StringName] = []
	var ligadas: Array[StringName] = [PlatformModifiers.PLATAFORMAS_MENORES, PlatformModifiers.PLATAFORMAS_QUE_CAEM]
	curva.estagios = [
		_estagio(0.0, LARGURA_PADRAO, vazio),
		_estagio(0.2, LARGURA_PADRAO, vazio),
		_estagio(0.5, LARGURA_PADRAO, vazio),
		_estagio(0.8, LARGURA_ESTAGIO_3, ligadas),
	]
	return curva


# progresso_inicial 1.0 satura no ultimo estagio (sem interpolacao); 0.0 fica no estagio 0
func _estado(estagio_3: bool) -> DifficultyState:
	var estado := DifficultyState.new(_curva())
	estado.progresso_inicial = 1.0 if estagio_3 else 0.0
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


func _largura(plataforma: Platform) -> float:
	return (plataforma.shape.shape as RectangleShape2D).size.x


func _tem(plataforma: Platform, classe: Script) -> bool:
	for modificador in plataforma._modificadores:
		if is_instance_of(modificador, classe):
			return true
	return false


func test_estagio_3_cria_plataformas_de_44_com_crumble_e_estagio_0_de_60_sem_modificadores() -> void:
	var gerador := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, _estado(true))
	gerador.new_platform()
	var estreitas := _plataformas(gerador)
	assert_gt(estreitas.size(), 1, "linha nasce preenchida")
	for p in estreitas:
		assert_eq(_largura(p), LARGURA_ESTAGIO_3, "estagio 3: largura 44")
		assert_true(_tem(p, PlatformCrumble), "estagio 3: PlatformCrumble")
		assert_true(_tem(p, PlatformNarrower), "estagio 3: PlatformNarrower")

	# Forma da cena sem modificador (o 60 nominal e 59.47 no .tscn)
	var base: Platform = autofree(load("res://scenes/Platform.tscn").instantiate())
	var largura_cena: float = (base.get_node("CollisionShape2D").shape as RectangleShape2D).size.x
	assert_almost_eq(largura_cena, LARGURA_PADRAO, 1.0, "forma da cena ~60")

	var normal := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, _estado(false))
	normal.new_platform()
	assert_gt(_plataformas(normal).size(), 1, "linha nasce preenchida")
	for p in _plataformas(normal):
		assert_eq(_largura(p), largura_cena, "estagio 0: largura da cena (60 nominal), sem set_largura")
		assert_eq(p._modificadores.size(), 0, "estagio 0: lista vazia")


func test_linha_estatica_do_gerador_inicial_recebe_narrower_e_nunca_crumble() -> void:
	var inicial := _gerador(Enums.PLATFORM_TYPE.STATIC, _estado(true), true)
	var iniciais := _plataformas(inicial)
	assert_eq(iniciais.size(), 3, "3 estaticas")
	for p in iniciais:
		assert_true(_tem(p, PlatformNarrower), "inicial: PlatformNarrower")
		assert_false(_tem(p, PlatformCrumble), "inicial: nunca PlatformCrumble")
		assert_eq(_largura(p), LARGURA_ESTAGIO_3, "inicial: largura 44")

	var comum := _gerador(Enums.PLATFORM_TYPE.STATIC, _estado(true), false)
	for p in _plataformas(comum):
		assert_true(_tem(p, PlatformCrumble), "estatica comum: PlatformCrumble")


func test_largura_nao_altera_espacamento_nem_distancia_de_saida() -> void:
	assert_eq(MovingRowFill.DISTANCIA_SAIDA, 60.2995, "DISTANCIA_SAIDA igual ao baseline")
	var spawn_x := 210.0
	var esperado: Array[float] = MovingRowFill.initial_xs(spawn_x, true, MovingRowFill.LARGURA_PADRAO, 60.0)
	assert_gt(esperado.size(), 0, "baseline tem posicoes")

	var gerador := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, _estado(true))
	var xs: Array = []
	for p in _plataformas(gerador):
		if p.position.x < spawn_x:
			xs.append(p.position.x)
	xs.sort()
	var esperado_ordenado: Array = esperado.duplicate()
	esperado_ordenado.sort()
	assert_eq(xs, esperado_ordenado, "estagio 3: x das plataformas iguais ao baseline")
	var normal := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, _estado(false))
	var xs_normal: Array = []
	for p in _plataformas(normal):
		if p.position.x < spawn_x:
			xs_normal.append(p.position.x)
	xs_normal.sort()
	assert_eq(xs, xs_normal, "estagio 3 e estagio 0 geram os mesmos x")
	for p in _plataformas(gerador):
		assert_eq(_largura(p), LARGURA_ESTAGIO_3, "largura 44 sem mexer nos x")
