extends GutTest

# f467 T5: RunningPlatforms sorteia oscilantes (PlatformSineMotion / PlatformPingPongMotion por plataforma) pelo snapshot
# do nascimento. Curva propria do teste (nao le o .tres de producao): 1 estagio, mecanicas e proporcoes de cada teste.

const GERADOR_SCENE := "res://scenes/RunningPlatforms.tscn"
# Plataformas criadas na amostra da fracao e tolerancia absoluta declarada (n >= 200, p = 0,4: 3 desvios = 0,10)
const AMOSTRA_FRACAO := 300
const TOLERANCIA_FRACAO := 0.1

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


func _estado(osc: float, vai_e_vem: float, mecanicas: Array[StringName]) -> DifficultyState:
	var estagio := DifficultyStage.new()
	estagio.progresso_inicio = 0.0
	estagio.proporcao_oscilantes = osc
	estagio.proporcao_vai_e_vem = vai_e_vem
	estagio.proporcao_cicladoras = 1.0
	estagio.mecanicas = mecanicas
	var curva := DifficultyCurve.new()
	curva.estagios = [estagio]
	return DifficultyState.new(curva)


func _ambas() -> Array[StringName]:
	return [PlatformModifiers.MOVIMENTO_SENO, PlatformModifiers.MOVIMENTO_VAI_E_VEM]


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


func _movimento(plataforma: Platform) -> PlatformModifier:
	for modificador in plataforma._modificadores:
		if modificador is PlatformSineMotion or modificador is PlatformPingPongMotion:
			return modificador
	return null


func _com_movimento(plataformas: Array) -> int:
	var total := 0
	for p in plataformas:
		if _movimento(p) != null:
			total += 1
	return total


func _com_seno(plataformas: Array) -> int:
	var total := 0
	for p in plataformas:
		if _movimento(p) is PlatformSineMotion:
			total += 1
	return total


func _com_vai_e_vem(plataformas: Array) -> int:
	var total := 0
	for p in plataformas:
		if _movimento(p) is PlatformPingPongMotion:
			total += 1
	return total


func test_c281_proporcao_1_toda_movel_oscila_e_com_0_nenhuma() -> void:
	var todas := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, _estado(1.0, 0.5, _ambas()))
	todas.new_platform()
	var com: Array = _plataformas(todas)
	assert_gt(com.size(), 1, "linha nasce preenchida")
	assert_eq(_com_movimento(com), com.size(), "proporcao 1.0: toda plataforma movel tem seno ou vai-e-vem")

	var nenhuma := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, _estado(0.0, 0.5, _ambas()))
	nenhuma.new_platform()
	var sem: Array = _plataformas(nenhuma)
	assert_gt(sem.size(), 1, "linha nasce preenchida")
	assert_eq(_com_movimento(sem), 0, "proporcao 0.0: nenhuma plataforma oscila")


func test_c282_proporcao_0_4_a_fracao_observada_fica_dentro_da_tolerancia() -> void:
	var gerador := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, _estado(0.4, 0.5, _ambas()))
	for i in AMOSTRA_FRACAO:
		gerador.new_platform()
	var filhas: Array = _plataformas(gerador)
	assert_gte(filhas.size(), 200, "amostra com N >= 200")
	var fracao: float = float(_com_movimento(filhas)) / float(filhas.size())
	assert_almost_eq(fracao, 0.4, TOLERANCIA_FRACAO, "fracao de oscilantes ~0.4 (tolerancia 0.1)")


func test_c283_estatica_e_linha_inicial_nunca_recebem_movimento_com_proporcao_1() -> void:
	var estatico := _gerador(Enums.PLATFORM_TYPE.STATIC, _estado(1.0, 0.5, _ambas()))
	assert_eq(_plataformas(estatico).size(), 3, "3 estaticas")
	assert_eq(_com_movimento(_plataformas(estatico)), 0, "estatica nunca oscila")

	var inicial := _gerador(Enums.PLATFORM_TYPE.STATIC, _estado(1.0, 0.5, _ambas()), true)
	assert_eq(_plataformas(inicial).size(), 3, "3 estaticas iniciais")
	assert_eq(_com_movimento(_plataformas(inicial)), 0, "linha inicial nunca oscila")

	# Controle: a movel do mesmo estagio oscila
	var movel := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, _estado(1.0, 0.5, _ambas()))
	assert_gt(_com_movimento(_plataformas(movel)), 0, "movel do mesmo estagio oscila")


func test_c284_estagio_sem_os_nomes_nunca_tem_oscilante_mesmo_com_proporcao() -> void:
	var vazio: Array[StringName] = []
	var gerador := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, _estado(1.0, 0.5, vazio))
	gerador.new_platform()
	assert_gt(_plataformas(gerador).size(), 1, "linha nasce preenchida")
	assert_eq(_com_movimento(_plataformas(gerador)), 0, "sem a mecanica no estagio, nenhuma oscila")


func test_c285_proporcao_vai_e_vem_decide_o_tipo_e_os_nomes_sao_separados() -> void:
	var seno := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, _estado(1.0, 0.0, _ambas()))
	seno.new_platform()
	var a: Array = _plataformas(seno)
	assert_eq(_com_seno(a), a.size(), "vai_e_vem 0.0: todas sao seno")
	assert_eq(_com_vai_e_vem(a), 0, "vai_e_vem 0.0: nenhuma vai-e-vem")

	var vai := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, _estado(1.0, 1.0, _ambas()))
	vai.new_platform()
	var b: Array = _plataformas(vai)
	assert_eq(_com_vai_e_vem(b), b.size(), "vai_e_vem 1.0: todas sao vai-e-vem")
	assert_eq(_com_seno(b), 0, "vai_e_vem 1.0: nenhuma seno")

	# So o seno ligado: proporcao_vai_e_vem 1.0 nao gera vai-e-vem
	var so_seno: Array[StringName] = [PlatformModifiers.MOVIMENTO_SENO]
	var c := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, _estado(1.0, 1.0, so_seno))
	var pc: Array = _plataformas(c)
	assert_eq(_com_seno(pc), pc.size(), "so movimento_seno ligado: todas seno")
	assert_eq(_com_vai_e_vem(pc), 0, "so movimento_seno ligado: nenhuma vai-e-vem")

	# So o vai-e-vem ligado: proporcao_vai_e_vem 0.0 nao gera seno
	var so_vai: Array[StringName] = [PlatformModifiers.MOVIMENTO_VAI_E_VEM]
	var d := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, _estado(1.0, 0.0, so_vai))
	var pd: Array = _plataformas(d)
	assert_eq(_com_vai_e_vem(pd), pd.size(), "so movimento_vai_e_vem ligado: todas vai-e-vem")
	assert_eq(_com_seno(pd), 0, "so movimento_vai_e_vem ligado: nenhuma seno")


func test_c286_oscilantes_da_mesma_linha_tem_instancias_e_fases_independentes() -> void:
	var gerador := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, _estado(1.0, 0.0, _ambas()))
	var filhas: Array = _plataformas(gerador)
	assert_gte(filhas.size(), 2, "linha com ao menos 2 plataformas")
	var a: PlatformSineMotion = _movimento(filhas[0])
	var b: PlatformSineMotion = _movimento(filhas[1])
	assert_not_null(a, "1a oscila")
	assert_not_null(b, "2a oscila")
	assert_ne(a, b, "instancias diferentes por plataforma")
	assert_ne(a.get_fase(), b.get_fase(), "fases diferentes na mesma linha")
	assert_false(is_same(filhas[0]._modificadores, filhas[1]._modificadores), "listas diferentes por plataforma")
	assert_false(gerador._modificadores.has(a), "oscilante nunca entra na lista compartilhada da linha")


func test_c287_empilhada_com_ciclo_queda_e_menor_sem_erro_e_sem_perder_os_outros() -> void:
	var todas: Array[StringName] = [
		PlatformModifiers.PLATAFORMAS_MENORES,
		PlatformModifiers.PLATAFORMAS_QUE_CAEM,
		PlatformModifiers.PLATAFORMAS_QUE_MUDAM_DE_COR,
		PlatformModifiers.MOVIMENTO_SENO,
	]
	var gerador := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, _estado(1.0, 0.0, todas))
	var filhas: Array = _plataformas(gerador)
	assert_gt(filhas.size(), 1, "linha nasce preenchida")
	for p in filhas:
		var tipos: Array = []
		for modificador in p._modificadores:
			tipos.append(modificador.get_script())
		assert_true(tipos.has(PlatformNarrower), "mantem PlatformNarrower")
		assert_true(tipos.has(PlatformCrumble), "mantem PlatformCrumble")
		assert_true(tipos.has(PlatformColorCycle), "mantem PlatformColorCycle")
		assert_true(tipos.has(PlatformSineMotion), "tem PlatformSineMotion")
		assert_not_null(p.obter_ciclo(), "ciclo de cor acessivel")
	await wait_physics_frames(3)
	for p in filhas:
		assert_true(is_instance_valid(p), "plataforma segue viva depois dos frames")
		assert_true(p._modificadores.size() >= 4, "lista segue completa")
