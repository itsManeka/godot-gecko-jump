extends GutTest

# f414 T4: linhas moveis garantem a cor do gecko (Global.cor_gecko) em toda janela de K (DifficultyStage.K_PADRAO) plataformas
# consecutivas criadas pelo mesmo gerador. Linhas iniciais estaticas seguem com a garantia de COR_INICIAL (F4/E1).

const GERADOR_SCENE := "res://scenes/RunningPlatforms.tscn"
const SEMENTES := 50
const NOVAS_PLATAFORMAS := 30

var _cor_original: Enums.COLOR


func before_each() -> void:
	_cor_original = Global.cor_gecko
	Global.platforms = []
	Global.iniciado = false


func after_each() -> void:
	Global.cor_gecko = _cor_original
	Global.platforms = []
	Global.iniciado = false


func _rng(semente: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	return rng


# Gerador movel na arvore: o _ready faz preencher_linha; o chamador acrescenta new_platform.
func _gerador_movel(rng: RandomNumberGenerator) -> Node2D:
	var gerador: Node2D = load(GERADOR_SCENE).instantiate()
	gerador.platform_type = Enums.PLATFORM_TYPE.MOVE_TO_LEFT
	gerador.rng = rng
	gerador.position = Vector2(0, 100)
	Global.set_iniciado(true)
	add_child_autofree(gerador)
	return gerador


# Gerador fora da arvore (sem _ready, sem timer): so o ponto de criacao _criar_plataforma.
func _gerador_solto(rng: RandomNumberGenerator) -> Node2D:
	var gerador: Node2D = autofree(load(GERADOR_SCENE).instantiate())
	gerador.rng = rng
	return gerador


# Cores das plataformas na ordem de criacao (ordem dos filhos)
func _cores(gerador: Node) -> Array:
	var cores: Array = []
	for filho in gerador.get_children():
		if filho is Platform:
			cores.append(filho.color)
	return cores


# Quantas janelas de K consecutivas ficaram sem a cor
func _janelas_sem_a_cor(cores: Array, cor: int) -> int:
	var sem_cor := 0
	var k: int = DifficultyStage.K_PADRAO
	for inicio in range(0, cores.size() - k + 1):
		var tem := false
		for i in range(inicio, inicio + k):
			if cores[i] == cor:
				tem = true
		if not tem:
			sem_cor += 1
	return sem_cor


func _outra_cor(excluida: int) -> Enums.COLOR:
	return Enums.COLOR.VERMELHO if excluida != Enums.COLOR.VERMELHO else Enums.COLOR.AZUL


func test_janela_de_k_plataformas_moveis_sempre_tem_a_cor_do_gecko() -> void:
	var cor_gecko: Enums.COLOR = Enums.COLOR.AZUL
	Global.cor_gecko = cor_gecko
	var janelas_sem_cor := 0
	var total := 0
	for semente in SEMENTES:
		var gerador := _gerador_movel(_rng(semente))
		for i in NOVAS_PLATAFORMAS:
			gerador.new_platform()
		var cores := _cores(gerador)
		total += cores.size()
		janelas_sem_cor += _janelas_sem_a_cor(cores, cor_gecko)
	assert_gt(total, SEMENTES * NOVAS_PLATAFORMAS, "preencher_linha e new_platform criaram plataformas no mesmo gerador")
	assert_eq(janelas_sem_cor, 0, "toda janela de K plataformas moveis consecutivas tem a cor do gecko")


func test_cor_vem_de_global_e_acompanha_a_mudanca() -> void:
	var cor_x: Enums.COLOR = Enums.COLOR.AZUL
	var cor_y: Enums.COLOR = Enums.COLOR.VERMELHO
	var sem_x := 0
	var sem_y := 0
	for semente in SEMENTES:
		Global.cor_gecko = cor_x
		var gerador_x := _gerador_movel(_rng(semente))
		for i in NOVAS_PLATAFORMAS:
			gerador_x.new_platform()
		sem_x += _janelas_sem_a_cor(_cores(gerador_x), cor_x)
		Global.cor_gecko = cor_y
		var gerador_y := _gerador_movel(_rng(semente))
		for i in NOVAS_PLATAFORMAS:
			gerador_y.new_platform()
		sem_y += _janelas_sem_a_cor(_cores(gerador_y), cor_y)
	assert_eq(sem_x, 0, "com Global.cor_gecko = X a janela garante X")
	assert_eq(sem_y, 0, "com Global.cor_gecko = Y a janela passa a garantir Y")


func test_historico_e_por_gerador_e_nao_compartilhado() -> void:
	Global.cor_gecko = Enums.COLOR.AZUL
	var b_sem_a_cor := 0
	for semente in SEMENTES:
		var gerador_a := _gerador_solto(_rng(semente))
		var gerador_b := _gerador_solto(_rng(semente + 1000))
		gerador_a._criar_plataforma(0.0)
		gerador_b._criar_plataforma(0.0)
		var cores_b := _cores(gerador_b)
		if cores_b.size() != 1 or cores_b[0] != Enums.COLOR.AZUL:
			b_sem_a_cor += 1
	assert_eq(b_sem_a_cor, 0, "1a plataforma do gerador B e forcada na cor do gecko mesmo com A ja tendo criado uma")


func test_linhas_iniciais_estaticas_seguem_com_a_cor_inicial() -> void:
	Global.cor_gecko = _outra_cor(Enums.COR_INICIAL)
	var sem_cor_inicial := 0
	for i in SEMENTES:
		var gerador: Node2D = load(GERADOR_SCENE).instantiate()
		gerador.platform_type = Enums.PLATFORM_TYPE.STATIC
		gerador.garantir_cor_inicial = true
		add_child_autofree(gerador)
		var cores := _cores(gerador)
		assert_eq(cores.size(), 3, "gerador estatico inicial cria 3 plataformas")
		if not cores.has(Enums.COR_INICIAL):
			sem_cor_inicial += 1
	assert_eq(sem_cor_inicial, 0, "estatica inicial tem COR_INICIAL em ao menos 1 plataforma, nao a cor de Global")
