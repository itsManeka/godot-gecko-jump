extends GutTest

# f517 T2: RunningPlatforms sorteia so pelos rngs injetados. Com rng e rng_cor_movel injetados, dois geradores
# iguais produzem o mesmo tipo, x, mecanicas (cicladora/oscilante/piscante, speed) e cores das estaticas;
# variar Global.cor_gecko nao muda tipo/x/mecanicas/speed (so a cor das moveis, fluxo separado do rng_cor_movel);
# a linha garantir_cor_inicial e reproducivel com rng; rng_cor_movel null cai no rng; sem rng os fallbacks globais
# seguem funcionando.

const GERADOR_SCENE := "res://scenes/RunningPlatforms.tscn"
const SEMENTE := 7
const SEMENTE_COR_MOVEL := 1007

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


func _rng(semente: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	return rng


# Estagio com speed 80 + variacao 0.25 (speed sorteada no [60, 100]) e proporcoes intermediarias para o resumo
# nao ser trivial. O nome das mecanicas so entra no estagio "ligadas" (progresso 1.0 satura nele).
func _estagio(inicio: float, mecanicas: Array[StringName]) -> DifficultyStage:
	var estagio := DifficultyStage.new()
	estagio.progresso_inicio = inicio
	estagio.mecanicas = mecanicas
	estagio.speed_moveis = 80.0
	estagio.variacao_speed_linha = 0.25
	estagio.proporcao_cicladoras = 0.5
	estagio.proporcao_oscilantes = 0.5
	estagio.proporcao_piscantes = 0.5
	estagio.proporcao_estaticas = 0.5
	return estagio


func _estado() -> DifficultyState:
	var vazio: Array[StringName] = []
	var ligadas: Array[StringName] = [
		PlatformModifiers.PLATAFORMAS_QUE_MUDAM_DE_COR,
		PlatformModifiers.MOVIMENTO_SENO,
		PlatformModifiers.PLATAFORMAS_QUE_PISCAM,
		PlatformModifiers.SPEED_POR_LINHA,
	]
	var curva := DifficultyCurve.new()
	curva.estagios = [_estagio(0.0, vazio), _estagio(0.5, ligadas)]
	var estado := DifficultyState.new(curva)
	estado.progresso_inicial = 1.0
	return estado


func _gerador(
	tipo: Enums.PLATFORM_TYPE,
	estado: DifficultyState,
	rng: RandomNumberGenerator,
	rng_cor_movel: RandomNumberGenerator = null,
	inicial: bool = false
) -> Node2D:
	var gerador: Node2D = load(GERADOR_SCENE).instantiate()
	gerador.platform_type = tipo
	gerador.garantir_cor_inicial = inicial
	gerador.dificuldade = estado
	gerador.rng = rng
	gerador.rng_cor_movel = rng_cor_movel
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


func _cores(gerador: Node) -> Array:
	var cores: Array = []
	for p in _plataformas(gerador):
		cores.append(p.color)
	return cores


# Resumo comparavel da linha: tipo concreto, speed e, por plataforma, [x, cor, cicladora, oscilante, piscante].
func _resumo(gerador: Node) -> Array:
	var resumo: Array = [int(gerador.platform_type), gerador.speed]
	for p in _plataformas(gerador):
		var oscilante := false
		for m in p._modificadores:
			if m is PlatformSineMotion or m is PlatformPingPongMotion:
				oscilante = true
		resumo.append([p.position.x, p.color, p.obter_ciclo() != null, oscilante, p.obter_pisca() != null])
	return resumo


# Estrutura sem as cores: o que nao pode mudar ao variar Global.cor_gecko (tipo, speed, x, mecanicas).
func _estrutura(gerador: Node) -> Array:
	var resumo: Array = [int(gerador.platform_type), gerador.speed]
	for p in _plataformas(gerador):
		var oscilante := false
		for m in p._modificadores:
			if m is PlatformSineMotion or m is PlatformPingPongMotion:
				oscilante = true
		resumo.append([p.position.x, p.obter_ciclo() != null, oscilante, p.obter_pisca() != null])
	return resumo


func test_c480_mesmo_rng_e_rng_cor_movel_dois_geradores_iguais_mesmo_tipo_x_mecanicas_e_cor_das_estaticas() -> void:
	Global.cor_gecko = Enums.COLOR.AZUL
	var estado := _estado()
	# Tipo concreto resolve pelo rng (RANDOM_ALL com proporcao 0.5 cai no caminho rng.randf)
	var tipo_a := _gerador(Enums.PLATFORM_TYPE.RANDOM_ALL, estado, _rng(SEMENTE), _rng(SEMENTE_COR_MOVEL))
	var tipo_b := _gerador(Enums.PLATFORM_TYPE.RANDOM_ALL, estado, _rng(SEMENTE), _rng(SEMENTE_COR_MOVEL))
	assert_eq(tipo_a.platform_type, tipo_b.platform_type, "mesmo tipo concreto resolvido pelo rng")
	# Moveis: mesmo x, mecanicas (cicladora/oscilante/piscante) e speed
	var a := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, estado, _rng(SEMENTE), _rng(SEMENTE_COR_MOVEL))
	var b := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, estado, _rng(SEMENTE), _rng(SEMENTE_COR_MOVEL))
	assert_gt(_plataformas(a).size(), 1, "linha movel nasce preenchida")
	assert_eq(_resumo(a), _resumo(b), "mesmo tipo, x, mecanicas, speed e cores das moveis")
	# Estaticas comuns: mesma cor das estaticas (Enums.get_random_color(rng))
	var ca := _gerador(Enums.PLATFORM_TYPE.STATIC, estado, _rng(SEMENTE), _rng(SEMENTE_COR_MOVEL), false)
	var cb := _gerador(Enums.PLATFORM_TYPE.STATIC, estado, _rng(SEMENTE), _rng(SEMENTE_COR_MOVEL), false)
	assert_eq(_cores(ca), _cores(cb), "mesma cor das estaticas comuns")


func test_c481_variar_cor_gecko_nao_muda_tipo_x_mecanicas_nem_speed_so_a_cor_das_moveis() -> void:
	var estado := _estado()
	Global.cor_gecko = Enums.COLOR.AZUL
	var azul := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, estado, _rng(SEMENTE), _rng(SEMENTE_COR_MOVEL))
	# Muitas plataformas: o consumo do sorteio de cor so ocorre quando a cor do gecko esta na janela, e o sorteio pode
	# cair na cor do gecko ou nao; com poucas criadas o consumo nao diverge entre as duas cores.
	for i in 60:
		azul.new_platform()
	Global.cor_gecko = Enums.COLOR.VERMELHO
	var vermelho := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, estado, _rng(SEMENTE), _rng(SEMENTE_COR_MOVEL))
	for i in 60:
		vermelho.new_platform()
	assert_gt(_plataformas(azul).size(), 60, "linha movel nasce preenchida e gera as demais")
	assert_eq(
		_estrutura(azul),
		_estrutura(vermelho),
		"tipo, x, cicladora/oscilante/piscante e speed nao mudam com a cor do gecko"
	)


func test_c482_linha_garantir_cor_inicial_com_rng_cor_inicial_reproduzivel() -> void:
	var estado := _estado()
	var esperadas: Array = StaticPlatformColors.sortear(Enums.COR_INICIAL, _rng(SEMENTE))
	var a := _gerador(Enums.PLATFORM_TYPE.STATIC, estado, _rng(SEMENTE), _rng(SEMENTE_COR_MOVEL), true)
	var b := _gerador(Enums.PLATFORM_TYPE.STATIC, estado, _rng(SEMENTE), _rng(SEMENTE_COR_MOVEL), true)
	assert_eq(_cores(a).size(), 3, "3 estaticas iniciais")
	assert_eq(_cores(a), _cores(b), "dois geradores iniciais iguais: mesmas cores")
	assert_eq(_cores(a), esperadas, "cor inicial reproduzivel (StaticPlatformColors.sortear(..., rng))")


func test_c483_rng_cor_movel_null_cai_em_rng_sequencia_seedada_inalterada() -> void:
	Global.cor_gecko = Enums.COLOR.AZUL
	var estado := _estado()
	var a := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, estado, _rng(SEMENTE), null)
	var b := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT, estado, _rng(SEMENTE), null)
	assert_gt(_plataformas(a).size(), 1, "linha movel nasce preenchida")
	assert_eq(_cores(a), _cores(b), "rng_cor_movel null: a cor das moveis vem do rng (deterministico)")


func test_c484_sem_rng_gerador_instancia_e_gera_sem_erro() -> void:
	Global.cor_gecko = Enums.COLOR.AZUL
	var gerador: Node2D = load(GERADOR_SCENE).instantiate()
	gerador.platform_type = Enums.PLATFORM_TYPE.MOVE_TO_LEFT
	gerador.position = Vector2(0, 100)
	Global.set_iniciado(true)
	add_child_autofree(gerador)
	gerador.new_platform()
	assert_gt(_plataformas(gerador).size(), 1, "sem rng: linha nasce e gera plataformas sem erro")
