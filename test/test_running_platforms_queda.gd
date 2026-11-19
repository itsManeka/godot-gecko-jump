extends GutTest

# f518 T3: RunningPlatforms sorteia por plataforma quem cai (proporcao_que_caem do snapshot do nascimento).
# Curva propria do teste (nao le o .tres de producao); o sorteio usa rng dedicado (SEMENTE_CAI), nunca o do layout.

const GERADOR_SCENE := "res://scenes/RunningPlatforms.tscn"
const N := 200

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


func _estagio(inicio: float, fracao: float, mecanicas: Array[StringName], extras: bool) -> DifficultyStage:
	var estagio := DifficultyStage.new()
	estagio.progresso_inicio = inicio
	estagio.mecanicas = mecanicas
	estagio.proporcao_que_caem = fracao
	if extras:
		estagio.proporcao_cicladoras = 0.5
		estagio.proporcao_oscilantes = 0.5
		estagio.proporcao_vai_e_vem = 0.5
		estagio.proporcao_piscantes = 0.5
	return estagio


# Estado saturado no ultimo estagio; fracao < 0 = nao define o campo (default do estagio)
func _estado(fracao: float, mecanicas: Array[StringName], extras: bool = false) -> DifficultyState:
	var curva := DifficultyCurve.new()
	var a := _estagio(0.0, fracao, mecanicas, extras)
	var b := _estagio(0.5, fracao, mecanicas, extras)
	if fracao < 0.0:
		a = DifficultyStage.new()
		a.mecanicas = mecanicas
		b = DifficultyStage.new()
		b.progresso_inicio = 0.5
		b.mecanicas = mecanicas
		if extras:
			for s in [a, b]:
				s.proporcao_cicladoras = 0.5
				s.proporcao_oscilantes = 0.5
				s.proporcao_vai_e_vem = 0.5
				s.proporcao_piscantes = 0.5
	curva.estagios = [a, b]
	var estado := DifficultyState.new(curva)
	estado.progresso_inicial = 1.0
	return estado


func _caem() -> Array[StringName]:
	return [PlatformModifiers.PLATAFORMAS_QUE_CAEM]


func _todas() -> Array[StringName]:
	return [
		PlatformModifiers.PLATAFORMAS_QUE_CAEM,
		PlatformModifiers.MOVIMENTO_SENO,
		PlatformModifiers.MOVIMENTO_VAI_E_VEM,
		PlatformModifiers.PLATAFORMAS_QUE_MUDAM_DE_COR,
		PlatformModifiers.PLATAFORMAS_QUE_PISCAM,
	]


func _gerador(
	estado: DifficultyState,
	semente: int = 7,
	tipo: Enums.PLATFORM_TYPE = Enums.PLATFORM_TYPE.MOVE_TO_LEFT,
	inicial: bool = false,
	com_rng: bool = true
) -> Node2D:
	var gerador: Node2D = load(GERADOR_SCENE).instantiate()
	gerador.platform_type = tipo
	gerador.garantir_cor_inicial = inicial
	gerador.dificuldade = estado
	if com_rng:
		var rng := RandomNumberGenerator.new()
		rng.seed = semente
		gerador.rng = rng
	gerador.position = Vector2(0, 100)
	Global.set_iniciado(true)
	add_child_autofree(gerador)
	return gerador


# Gerador movel com pelo menos N plataformas criadas
func _gerar(estado: DifficultyState, semente: int = 7, com_rng: bool = true) -> Node2D:
	var gerador := _gerador(estado, semente, Enums.PLATFORM_TYPE.MOVE_TO_LEFT, false, com_rng)
	while _plataformas(gerador).size() < N:
		gerador.new_platform()
	return gerador


func _plataformas(gerador: Node) -> Array:
	var filhas: Array = []
	for filha in gerador.get_children():
		if filha is Platform:
			filhas.append(filha)
	return filhas


func _tem(plataforma: Platform, classe: Script) -> bool:
	for modificador in plataforma._modificadores:
		if is_instance_of(modificador, classe):
			return true
	return false


func _quantas_caem(plataformas: Array) -> int:
	var n := 0
	for p in plataformas:
		if _tem(p, PlatformCrumble):
			n += 1
	return n


# Quem cai, na ordem de criacao (1 = cai)
func _quem_cai(plataformas: Array) -> Array:
	var r: Array = []
	for p in plataformas:
		r.append(1 if _tem(p, PlatformCrumble) else 0)
	return r


# Assinatura de layout: x, cor e mecanicas que nao sao a queda
func _assinatura(plataformas: Array) -> Array:
	var r: Array = []
	for p in plataformas:
		var nomes: Array = []
		for m in p._modificadores:
			if not (m is PlatformCrumble):
				nomes.append(String(m.get_script().get_global_name()))
		r.append("%s|%s|%s" % [p.position.x, p.color, ",".join(nomes)])
	return r


func _divergencias(a: Array, b: Array) -> int:
	var d: int = absi(a.size() - b.size())
	for i in mini(a.size(), b.size()):
		if a[i] != b[i]:
			d += 1
	return d


func test_c523_fracao_0_nenhuma_plataforma_cai() -> void:
	var gerador := _gerar(_estado(0.0, _caem()))
	var ps := _plataformas(gerador)
	assert_gte(ps.size(), N, "gerou N plataformas")
	assert_eq(_quantas_caem(ps), 0, "fracao 0.0: nenhuma plataforma com PlatformCrumble")


func test_c524_fracao_1_todas_caem_e_layout_igual_ao_sem_o_campo() -> void:
	var com := _gerar(_estado(1.0, _caem(), true))
	var sem := _gerar(_estado(-1.0, _caem(), true))
	var ps := _plataformas(com)
	assert_eq(_quantas_caem(ps), ps.size(), "fracao 1.0: todas as plataformas caem")
	assert_eq(_quantas_caem(_plataformas(sem)), _plataformas(sem).size(), "sem o campo (padrao 1.0): todas caem")
	assert_eq(
		_divergencias(_assinatura(ps), _assinatura(_plataformas(sem))), 0, "x/cor/mecanicas iguais a geracao sem o campo"
	)


func test_c525_fracao_meia_cerca_de_metade_e_reprodutivel_com_a_mesma_seed() -> void:
	var a := _plataformas(_gerar(_estado(0.5, _caem())))
	var b := _plataformas(_gerar(_estado(0.5, _caem())))
	var n: int = _quantas_caem(a)
	assert_between(n, int(a.size() * 0.4), int(a.size() * 0.6), "fracao 0.5: entre 40% e 60% caem")
	assert_eq(_divergencias(_quem_cai(a), _quem_cai(b)), 0, "mesma seed: mesma lista de quem cai")


func test_c526_mudar_a_fracao_so_altera_quem_cai() -> void:
	var base := _plataformas(_gerar(_estado(0.0, _todas(), true)))
	var meia := _plataformas(_gerar(_estado(0.5, _todas(), true)))
	var toda := _plataformas(_gerar(_estado(1.0, _todas(), true)))
	var ass_base := _assinatura(base)
	assert_eq(_divergencias(ass_base, _assinatura(meia)), 0, "0.0 x 0.5: layout/mecanicas iguais, so a queda muda")
	assert_eq(_divergencias(ass_base, _assinatura(toda)), 0, "0.0 x 1.0: layout/mecanicas iguais, so a queda muda")
	assert_gt(_quantas_caem(meia), 0, "0.5 sorteia quem cai")


func test_c527_linha_inicial_nunca_cai_mesmo_com_fracao_1() -> void:
	var inicial := _gerador(_estado(1.0, _caem()), 7, Enums.PLATFORM_TYPE.STATIC, true)
	var iniciais := _plataformas(inicial)
	assert_eq(iniciais.size(), 3, "3 estaticas na linha inicial")
	assert_eq(_quantas_caem(iniciais), 0, "linha inicial: nenhuma PlatformCrumble")
	var comum := _gerador(_estado(1.0, _caem()), 7, Enums.PLATFORM_TYPE.STATIC, false)
	assert_eq(_quantas_caem(_plataformas(comum)), 3, "controle: estatica comum cai com 1.0")


func test_c528_sem_derrota_nenhuma_cai_com_fracao_1() -> void:
	Global.sem_derrota = true
	var gerador := _gerar(_estado(1.0, _caem()))
	assert_eq(_quantas_caem(_plataformas(gerador)), 0, "sem_derrota: nenhuma PlatformCrumble")


func test_c529_mecanica_desligada_nenhuma_cai_com_fracao_1() -> void:
	var vazio: Array[StringName] = []
	var gerador := _gerar(_estado(1.0, vazio))
	assert_eq(_quantas_caem(_plataformas(gerador)), 0, "mecanica desligada: nenhuma PlatformCrumble")


func test_c530_crumble_fora_da_lista_compartilhada_e_com_instancia_propria() -> void:
	var gerador := _gerar(_estado(0.5, _caem()))
	var ps := _plataformas(gerador)
	var compartilhada: Array = gerador._modificadores
	var tem_crumble_compartilhado := false
	for m in compartilhada:
		if m is PlatformCrumble:
			tem_crumble_compartilhado = true
	assert_false(tem_crumble_compartilhado, "lista compartilhada sem PlatformCrumble")
	var instancias: Array = []
	var repetidas := 0
	for p in ps:
		for m in p._modificadores:
			if m is PlatformCrumble:
				for outra in instancias:
					if is_same(outra, m):
						repetidas += 1
				instancias.append(m)
	assert_gt(instancias.size(), 1, "mais de uma plataforma cai")
	assert_lt(instancias.size(), ps.size(), "nem todas caem com 0.5")
	assert_eq(repetidas, 0, "cada plataforma que cai tem instancia propria de PlatformCrumble")


func test_c531_fracoes_extremas_nao_consomem_o_rng_da_queda_e_a_meia_consome() -> void:
	var zero := _gerar(_estado(0.0, _caem()))
	var um := _gerar(_estado(1.0, _caem()))
	assert_null(zero._rng_queda, "fracao 0.0 nao cria nem consome o rng da queda")
	assert_null(um._rng_queda, "fracao 1.0 nao cria nem consome o rng da queda")
	var meia := _gerar(_estado(0.5, _caem()))
	assert_not_null(meia._rng_queda, "fracao 0.5 sorteia pelo rng da queda")
	var intacto := RandomNumberGenerator.new()
	intacto.seed = meia.rng.seed ^ meia.SEMENTE_CAI
	assert_ne(meia._rng_queda.state, intacto.state, "fracao 0.5 consumiu o rng da queda")


func test_c532_plataforma_com_outra_mecanica_tambem_cai() -> void:
	var gerador := _gerar(_estado(1.0, _todas(), true))
	var combinadas := 0
	for p in _plataformas(gerador):
		if _tem(p, PlatformCrumble) and (_tem(p, PlatformColorCycle) or _tem(p, PlatformBlink) or _tem(p, PlatformSineMotion)):
			combinadas += 1
	assert_gt(combinadas, 0, "ha plataforma com PlatformCrumble e outra mecanica de plataforma")
	assert_eq(_quantas_caem(_plataformas(gerador)), _plataformas(gerador).size(), "fracao 1.0: todas caem")


func test_c533_sem_rng_injetado_o_sorteio_nao_falha() -> void:
	var todas := _gerar(_estado(1.0, _caem()), 7, false)
	assert_eq(_quantas_caem(_plataformas(todas)), _plataformas(todas).size(), "sem rng, fracao 1.0 cobre todas")
	var meia := _gerar(_estado(0.5, _caem()), 7, false)
	assert_not_null(meia._rng_queda, "sem rng, a fracao 0.5 sorteia pelo rng proprio")
	assert_gte(_plataformas(meia).size(), N, "gerou N plataformas sem rng injetado")
