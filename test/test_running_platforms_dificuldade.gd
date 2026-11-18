extends GutTest

# f458 T9: RunningPlatforms le speed, K e proporcao do estado de dificuldade injetado (`dificuldade`). Speed e proporcao
# no nascimento da linha; K relido a cada plataforma criada. Sem estado injetado = estagio 0 (60, K 3, 1/3).

const GERADOR_SCENE := "res://scenes/RunningPlatforms.tscn"


# Estado com valores fixos e mutaveis pelo teste (o snapshot e devolvido novo a cada chamada)
class EstadoFixo:
	extends DifficultyState

	var speed: float = DifficultyStage.SPEED_PADRAO
	var k: int = DifficultyStage.K_PADRAO
	var proporcao: float = DifficultyStage.PROPORCAO_PADRAO

	func snapshot() -> DifficultySnapshot:
		return DifficultySnapshot.new(DifficultyStage.SCROLL_PADRAO, speed, k, proporcao)


var _cor_original: Enums.COLOR


func before_each() -> void:
	_cor_original = Global.cor_gecko
	Global.platforms = []
	Global.iniciado = false


func after_each() -> void:
	Global.cor_gecko = _cor_original
	Global.platforms = []
	Global.iniciado = false


func _estado(speed: float, k: int, proporcao: float) -> EstadoFixo:
	var estado := EstadoFixo.new()
	estado.speed = speed
	estado.k = k
	estado.proporcao = proporcao
	return estado


func _rng(semente: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	return rng


# Gerador na arvore (o _ready preenche a linha). Estado injetado antes do add_child, como faz o ScrollLevel.
func _gerador(tipo: Enums.PLATFORM_TYPE, estado: DifficultyState) -> Node2D:
	var gerador: Node2D = load(GERADOR_SCENE).instantiate()
	gerador.platform_type = tipo
	gerador.dificuldade = estado
	gerador.rng = _rng(7)
	gerador.position = Vector2(0, 100)
	Global.set_iniciado(true)
	add_child_autofree(gerador)
	return gerador


# Gerador fora da arvore: so o ponto de criacao _criar_plataforma
func _gerador_solto(estado: DifficultyState, semente: int) -> Node2D:
	var gerador: Node2D = autofree(load(GERADOR_SCENE).instantiate())
	gerador.dificuldade = estado
	gerador.rng = _rng(semente)
	return gerador


func _plataformas(gerador: Node) -> Array:
	var filhas: Array = []
	for filha in gerador.get_children():
		if filha is Platform:
			filhas.append(filha)
	return filhas


func test_linha_nascida_em_speed_v_anda_a_v_e_nao_muda_quando_o_snapshot_muda() -> void:
	var estado := _estado(90.0, 3, DifficultyStage.PROPORCAO_PADRAO)
	var gerador := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, estado)
	assert_gt(_plataformas(gerador).size(), 1, "linha nasce preenchida")
	for p in _plataformas(gerador):
		assert_eq(p.speed, 90.0, "plataforma da linha anda a speed do snapshot do nascimento")

	estado.speed = 30.0
	gerador.new_platform()

	for p in _plataformas(gerador):
		assert_eq(p.speed, 90.0, "snapshot mudou depois: a linha continua a 90")


func test_linha_para_a_direita_usa_speed_do_snapshot_com_sinal_invertido() -> void:
	var gerador := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_RIGHT, _estado(90.0, 3, DifficultyStage.PROPORCAO_PADRAO))
	for p in _plataformas(gerador):
		assert_eq(p.speed, -90.0, "MOVE_TO_RIGHT: speed negativa com modulo do snapshot")


func test_linhas_com_speeds_diferentes_coexistem_cada_uma_com_a_sua() -> void:
	var estado := _estado(90.0, 3, DifficultyStage.PROPORCAO_PADRAO)
	var rapida := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, estado)
	estado.speed = 40.0
	var lenta := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, estado)

	for p in _plataformas(rapida):
		assert_eq(p.speed, 90.0, "linha rapida segue a 90")
	for p in _plataformas(lenta):
		assert_eq(p.speed, 40.0, "linha lenta nasce a 40")


func test_k_relido_a_cada_plataforma_criada_muda_cor_e_descarta_excedente() -> void:
	var estado := _estado(60.0, 6, DifficultyStage.PROPORCAO_PADRAO)
	Global.cor_gecko = Enums.COLOR.AZUL
	var gerador := _gerador_solto(estado, 11)
	for i in 20:
		gerador._criar_plataforma(0.0)
	assert_eq(gerador._cores_criadas.size(), 5, "K 6: historico guarda K-1 = 5")

	estado.k = 1
	gerador._criar_plataforma(0.0)

	var ultima: Platform = _plataformas(gerador).back()
	assert_eq(ultima.color, int(Enums.COLOR.AZUL), "K 1: a plataforma seguinte usa o K novo (cor do gecko)")
	assert_eq(gerador._cores_criadas.size(), 0, "K 1: historico descarta o excedente (K-1 = 0)")


func test_proporcao_zero_do_snapshot_nao_gera_linha_estatica() -> void:
	var estado := _estado(60.0, 3, 0.0)
	for i in 40:
		var gerador := _gerador(Enums.PLATFORM_TYPE.RANDOM_ALL, estado)
		assert_ne(gerador.platform_type, Enums.PLATFORM_TYPE.STATIC, "proporcao 0 nunca resolve STATIC")


func test_sem_dificuldade_injetado_usa_o_estagio_zero() -> void:
	var gerador := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, null)
	for p in _plataformas(gerador):
		assert_eq(p.speed, 60.0, "sem estado: speed 60")
	var snap: DifficultySnapshot = gerador._snapshot()
	assert_eq(snap.get_k(), 3, "sem estado: K 3")
	assert_almost_eq(snap.get_proporcao_estaticas(), 1.0 / 3.0, 0.0001, "sem estado: proporcao 1/3")

	Global.cor_gecko = Enums.COLOR.AZUL
	var solto := _gerador_solto(null, 5)
	for i in 10:
		solto._criar_plataforma(0.0)
	assert_eq(solto._cores_criadas.size(), 2, "sem estado: historico K-1 = 2")
