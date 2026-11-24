extends GutTest

# f517 T5 (C490-C494): determinismo da geracao pelo caminho ScrollLevel. Resumo de cada linha capturado
# no nascimento (indice do y local, nunca a ordem de criacao): tipo concreto, x das plataformas, mecanicas
# (cicladora/oscilante/piscante), speed e cor das estaticas; cor das moveis fora (decisao (d) do ADR 0014).
# Scroll dirigido como test_scroll_level_dificuldade.gd (physics off, Global.iniciado, scroll manual) com
# curva que liga as mecanicas. Sem seed nenhuma linha tem rng (sorteio global como hoje); o caminho com
# randomize() ja e coberto por test_global_seed.gd.

const SCROLL := "res://scenes/ScrollLevel.tscn"
const SEMENTE_A := 4242
const SEMENTE_B := 977
# 12 passos de 125 px = 1500 px = 30 linhas de scroll alem das 9 iniciais do viewport 400 (39 no total)
const PASSO := 125.0
const PASSOS := 12
const LINHAS_SCROLL := 30
const ALTURA_400 := 400
const ALTURA_640 := 640

var _scroll: Node
var _cor_original: Enums.COLOR
var _sem_derrota_original: bool
# indice do y local -> resumo capturado no _ready de cada linha; [rng, rng_cor_movel] no mesmo instante
var _resumos: Dictionary = {}
var _rngs: Dictionary = {}


func before_each() -> void:
	_cor_original = Global.cor_gecko
	_sem_derrota_original = Global.sem_derrota
	Global.sem_derrota = false
	Global.platforms = []
	Global.iniciado = false
	_resumos = {}
	_rngs = {}


func after_each() -> void:
	Global.cor_gecko = _cor_original
	Global.sem_derrota = _sem_derrota_original
	Global.platforms = []
	Global.iniciado = false


# Montagem do test_scroll_level_seed_injecao.gd: quem injeta a seed instancia, seta `semente` ANTES do
# add_child (D1) e so entao entra na arvore. Escuta o container para capturar toda linha que nascer
# (5 do .tscn via _enter_tree, extras de _ready e as do scroll).
func _spawn(altura: int, semente = null) -> void:
	var sv := SubViewport.new()
	sv.size = Vector2i(180, altura)
	add_child_autofree(sv)
	_scroll = load(SCROLL).instantiate()
	if semente != null:
		_scroll.semente = semente
	_scroll.get_node("RunningPlatforms").child_entered_tree.connect(_ao_entrar_linha)
	sv.add_child(_scroll)
	_scroll.set_physics_process(false)
	await wait_process_frames(1)


# child_entered_tree dispara antes do _ready da linha: conecta o ready para capturar o resumo no
# nascimento, com tipo/x/mecanicas/speed/cores ja resolvidos pelo _ready dela (sem frame no meio).
func _ao_entrar_linha(linha: Node) -> void:
	linha.ready.connect(_capturar.bind(linha))


func _capturar(linha: Node) -> void:
	var indice: int = RowSeed.indice_do_y(linha.position.y)
	_resumos[indice] = _resumir(linha)
	_rngs[indice] = [linha.rng, linha.rng_cor_movel]


# Resumo comparavel da linha: cor das moveis fica fora (segue o gecko, decisao (d) do ADR 0014).
func _resumir(linha: Node) -> Dictionary:
	var estatica: bool = linha.platform_type == Enums.PLATFORM_TYPE.STATIC
	var plataformas: Array = []
	for filho in linha.get_children():
		if filho is Platform:
			plataformas.append(_resumir_plataforma(filho, estatica))
	return {
		"tipo": linha.platform_type,
		"speed": linha.speed,
		"plataformas": plataformas,
	}


func _resumir_plataforma(plataforma: Platform, linha_estatica: bool) -> Dictionary:
	var mecanicas: Array = []
	for modificador in plataforma._modificadores:
		if modificador is PlatformColorCycle:
			mecanicas.append("ciclo")
		elif modificador is PlatformSineMotion:
			mecanicas.append("seno")
		elif modificador is PlatformPingPongMotion:
			mecanicas.append("vai_e_vem")
		elif modificador is PlatformBlink:
			mecanicas.append("pisca")
	var resumo := {
		"x": plataforma.position.x,
		"mecanicas": mecanicas,
	}
	if linha_estatica:
		resumo["cor"] = plataforma.color
	return resumo


# Curva de 1 estagio com as mecanicas ligadas (cicladora, seno, vai-e-vem, piscante e speed por linha):
# progresso 0 mantem o estagio ativo do inicio ao fim do scroll, como o estagio unico de
# test_scroll_level_dificuldade.gd.
func _estado_com_mecanicas() -> DifficultyState:
	var estagio := DifficultyStage.new()
	estagio.scroll = 20.0
	estagio.speed_moveis = 100.0
	var mecanicas: Array[StringName] = [
		PlatformModifiers.PLATAFORMAS_QUE_MUDAM_DE_COR,
		PlatformModifiers.MOVIMENTO_SENO,
		PlatformModifiers.MOVIMENTO_VAI_E_VEM,
		PlatformModifiers.PLATAFORMAS_QUE_PISCAM,
		PlatformModifiers.SPEED_POR_LINHA,
	]
	estagio.mecanicas = mecanicas
	estagio.proporcao_cicladoras = 0.5
	estagio.proporcao_oscilantes = 0.5
	estagio.proporcao_vai_e_vem = 0.5
	estagio.proporcao_piscantes = 0.5
	estagio.variacao_speed_linha = 0.4
	var curva := DifficultyCurve.new()
	curva.estagios = [estagio] as Array[DifficultyStage]
	return DifficultyState.new(curva)


# Scroll manual do test_scroll_level_seed_injecao.gd: gatilho aritmetico das linhas pendentes.
func _scrollar_ate(valor: float) -> void:
	_scroll.position_scrolled = valor
	_scroll.running_platforms.position.y = valor
	_scroll._physics_process(0.0)
	await wait_process_frames(1)


# Uma geracao: spawn com a semente (ou sem), curva com mecanicas ligada depois do spawn (as linhas
# iniciais nascem no estagio 0, como na partida real) e scroll manual em PASSOS passos. Devolve
# {indice do y: resumo} do nascimento de cada linha (iniciais + scroll).
func _gerar(altura: int, semente = null) -> Dictionary:
	_resumos = {}
	_rngs = {}
	await _spawn(altura, semente)
	_scroll.dificuldade = _estado_com_mecanicas()
	Global.iniciado = true
	for i in PASSOS:
		await _scrollar_ate(PASSO * (i + 1))
	return _resumos.duplicate()


# Geracao com as linhas do scroll criadas na ordem INVERTIDA (indice 30 para o 1) por chamadas diretas
# de create_new_running_platform, com awaits de frames diferentes entre elas: o rng de cada linha vem
# do seu y, nao da ordem nem do frame em que nasceu.
func _gerar_ordem_invertida(altura: int, semente: int) -> Dictionary:
	_resumos = {}
	_rngs = {}
	await _spawn(altura, semente)
	_scroll.dificuldade = _estado_com_mecanicas()
	for n in range(LINHAS_SCROLL, 0, -1):
		_scroll.create_new_running_platform(InitialRows.Y_TOPO - InitialRows.ESPACAMENTO * n)
		await wait_process_frames(1 + (n % 3))
	return _resumos.duplicate()


# Indices de `base` que faltam em `outra` ou cujo resumo difere (lista vazia = geracoes iguais nos indices de base).
func _indices_divergentes(base: Dictionary, outra: Dictionary) -> Array:
	var divergentes: Array = []
	for indice in base:
		if not outra.has(indice) or base[indice] != outra[indice]:
			divergentes.append(indice)
	divergentes.sort()
	return divergentes


# Cor de gecko valida e diferente da vigente (so a cor das moveis e a sequencia da cicladora movel
# seguem o gecko; decisao (d) do ADR 0014, o resumo nao as compara).
func _cor_diferente_do_gecko() -> Enums.COLOR:
	var fonte := RandomNumberGenerator.new()
	fonte.seed = 31337
	var cor := Enums.get_random_color(fonte) as Enums.COLOR
	while cor == _cor_original:
		cor = Enums.get_random_color(fonte) as Enums.COLOR
	return cor


# C490: mesma seed, duas geracoes de >= 30 linhas (iniciais + scroll) -> resumos iguais
func test_mesma_seed_duas_geracoes_tem_resumos_iguais() -> void:
	var ger_a := await _gerar(ALTURA_400, SEMENTE_A)
	var ger_b := await _gerar(ALTURA_400, SEMENTE_A)
	assert_gt(ger_a.size(), 30, "uma geracao cobriu %s linhas (iniciais + scroll); o criterio pede 30 ou mais" % ger_a.size())
	assert_true(ger_a.has(0), "indice 0 (linha do topo do .tscn) deveria ser capturado")
	assert_true(ger_a.has(LINHAS_SCROLL), "indice %s (ultima linha do scroll) deveria ser capturado" % LINHAS_SCROLL)
	assert_eq(ger_b.size(), ger_a.size(), "mesma seed e mesma altura geram os mesmos indices")
	var com_mecanica := 0
	for indice in ger_a:
		for plataforma in ger_a[indice]["plataformas"]:
			if not plataforma["mecanicas"].is_empty():
				com_mecanica += 1
				break
	assert_gt(com_mecanica, 0, "a curva deveria ligar mecanicas em pelo menos uma linha")
	var divergentes := _indices_divergentes(ger_a, ger_b)
	assert_eq(divergentes.size(), 0, "mesma seed deveria reproduzir o resumo; primeiro indice divergente: %s" % [divergentes.front() if not divergentes.is_empty() else "nenhum"])


# C491: seeds diferentes -> resumos divergem
func test_seeds_diferentes_geram_resumos_divergentes() -> void:
	var ger_a := await _gerar(ALTURA_400, SEMENTE_A)
	var ger_b := await _gerar(ALTURA_400, SEMENTE_B)
	assert_eq(ger_b.size(), ger_a.size(), "mesma altura: mesmos indices nas duas seeds")
	var divergentes := 0
	for indice in ger_a:
		if ger_b.has(indice) and ger_a[indice] != ger_b[indice]:
			divergentes += 1
	assert_gt(divergentes, 0, "seeds diferentes deveriam divergir (divergiram em %s de %s linhas)" % [divergentes, ger_a.size()])


# C492: o resumo independe da ordem de criacao (scroll invertido por chamadas diretas, awaits de frames
# diferentes entre elas) e da cor do gecko entre geracoes
func test_resumo_independe_da_ordem_de_criacao_frames_e_cor_do_gecko() -> void:
	var ger_a := await _gerar(ALTURA_400, SEMENTE_A)
	Global.cor_gecko = _cor_diferente_do_gecko()
	var ger_b := await _gerar_ordem_invertida(ALTURA_400, SEMENTE_A)
	assert_eq(ger_b.size(), ger_a.size(), "a geracao invertida cobre os mesmos indices")
	var divergentes := _indices_divergentes(ger_a, ger_b)
	assert_eq(divergentes.size(), 0, "resumo deveria independer da ordem de criacao e da cor do gecko; primeiro indice divergente: %s" % [divergentes.front() if not divergentes.is_empty() else "nenhum"])


# C493: sem seed nenhuma linha tem rng (sorteio global como hoje); a igualdade entre duas partidas sem
# seed nao e criterio e o caminho com randomize() ja e coberto por test_global_seed.gd
func test_sem_seed_nenhuma_linha_tem_rng() -> void:
	await _gerar(ALTURA_400, null)
	assert_gt(_rngs.size(), 30, "capturas deveriam cobrir linhas iniciais e do scroll (cobriram %s)" % _rngs.size())
	for indice in _rngs:
		assert_null(_rngs[indice][0], "sem seed a linha %s nao deveria ter rng" % indice)
		assert_null(_rngs[indice][1], "sem seed a linha %s nao deveria ter rng_cor_movel" % indice)


# C494: mesma seed em viewports 400 e 640 (o 640 nasce mais linhas iniciais) -> mesmo resumo nos indices em comum
func test_mesma_seed_em_viewports_400_e_640_gera_mesmo_resumo_nos_indices_comuns() -> void:
	var ger_400 := await _gerar(ALTURA_400, SEMENTE_A)
	var ger_640 := await _gerar(ALTURA_640, SEMENTE_A)
	assert_gt(ger_640.size(), ger_400.size(), "viewport 640 nasce mais linhas iniciais que o 400")
	var divergentes := _indices_divergentes(ger_400, ger_640)
	assert_eq(divergentes.size(), 0, "mesma seed deveria gerar o mesmo resumo nas duas alturas; primeiro indice divergente: %s" % [divergentes.front() if not divergentes.is_empty() else "nenhum"])
