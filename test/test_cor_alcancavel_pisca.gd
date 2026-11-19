extends GutTest

# Alcancabilidade e comportamento com a mecanica das plataformas que piscam ligada (estagios lidos do .tres de producao,
# sementes declaradas aqui, cena real onde a fisica/o gerador importam).
#   C325/C328: simulacao COM TEMPO sobre linhas geradas pelo RunningPlatforms real (proporcao_piscantes forcada a 1.0, pior
#              caso). Relogio: cada PlatformBlink/PlatformColorCycle real e avancado por ao_processar na plataforma real. O
#              gecko pousa na linha g, sorteia a cor pela previsao (ReachableColors.coletar_cores_linha_acima com
#              dt_chegada = tempo_de_pulo e espera = Player.ESPERA_MAXIMA_S), espera um atraso (extremos 0 e espera - 1
#              frame, e sorteados), pula e so entao confere a linha de cima. A conferencia da janela e independente do
#              preditor: amostra o relogio frame a frame (visivel_em / cor_em) em vez de usar visivel_na_janela.
#              Simplificacao declarada: a linha movel e lida na posicao de nascimento (como test_cor_alcancavel_ciclo).
#   C326:      gerador real (_cor_movel) criando N plataformas moveis, cor do gecko mudando no meio; janela de K.
#   C327:      piso do .tres: duracao_visivel >= ESPERA_MAXIMA_S + aviso_pisca.
#   C329:      cena real (fisica), piscantes forcadas: espacamento e 1 saida do CheckGenerate por plataforma.
#   C330-C333: Platform/Stage reais: trava, pausa, pre-partida, recarga e modo sem derrota.

const PlayerFisica := preload("res://scenes/Player.gd")
const CURVA_PATH := "res://ressources/curva_dificuldade.tres"
const GERADOR_SCENE := "res://scenes/RunningPlatforms.tscn"
const PLATAFORMA_CENA := "res://scenes/Platform.tscn"
const STAGE_SCENE := "res://scenes/Stage.tscn"
const EPS_PROGRESSO := 0.001
# f517: 20261120 e 20261121 sairam daqui quando o rng do gerador passou a decidir tambem o tipo da linha e a cor das
# estaticas (o fluxo deslocou). Com elas, e com a 13, uma linha movel so de cicladoras visiveis cai no sorteio livre:
# lacuna da alcancabilidade registrada na issue #52 do repo, que as traz de volta ao corrigir.
const SEEDS := [20261122, 20261123, 20261124]
const LINHAS := 120
const LARGURA := 180.0
const ALTURA_TELA := 320.0
const Y_BASE := 10000.0
# Linhas ja criadas acima do pouso (a tela mostra varias): as piscantes envelhecem antes de o gecko chegar nelas.
const LINHAS_A_FRENTE := 8
# Ciclo de producao do E3 usado nos testes de cena (visivel 3,0 / invisivel 1,2 / aviso 0,6)
const VISIVEL := 3.0
const INVISIVEL := 1.2
const AVISO := 0.6
const PLATAFORMAS_POR_GERADOR := 40
# C329
const FRAMES_MEDIDA := 360
const FRAMES_PARA_SAIR := 150
const ALTURA_ENTRE_GERADORES := 25.0
const TICKS := 12

var _cor_original: Enums.COLOR


func before_each() -> void:
	PlatformModifiers.restaurar_padrao()
	_cor_original = Global.cor_gecko
	Global.tutorial_visto_espelho = true
	Global.platforms = []
	Global.iniciado = false
	Global.sem_derrota = false


func after_each() -> void:
	get_tree().paused = false
	PlatformModifiers.restaurar_padrao()
	Global.cor_gecko = _cor_original
	Global.platforms = []
	Global.iniciado = false
	Global.sem_derrota = false


# --- utilitarios -------------------------------------------------------------------------------------------------------


func _curva() -> DifficultyCurve:
	return load(CURVA_PATH) as DifficultyCurve


func _rng(semente: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	return rng


func _so_pisca() -> Array[StringName]:
	var ligadas: Array[StringName] = [PlatformModifiers.PLATAFORMAS_QUE_PISCAM]
	return ligadas


# Casos [rotulo, progresso, snapshot de producao] (inicio e fim de cada estagio e teto) em que a mecanica esta ligada.
func _casos_com_pisca() -> Array:
	var curva := _curva()
	var casos: Array = []
	for i in range(curva.estagios.size()):
		var p_ini: float = curva.estagios[i].progresso_inicio
		casos.append(["E%d inicio" % i, p_ini, curva.avaliar(p_ini * curva.pontos_plato, 0.0)])
		if i + 1 < curva.estagios.size():
			var p_fim: float = curva.estagios[i + 1].progresso_inicio - EPS_PROGRESSO
			casos.append(["E%d fim" % i, p_fim, curva.avaliar(p_fim * curva.pontos_plato, 0.0)])
	casos.append(["teto", 1.0, curva.avaliar(curva.pontos_plato, curva.segundos_plato)])
	var com_pisca: Array = []
	for caso in casos:
		var snap: DifficultySnapshot = caso[2]
		if snap.get_mecanicas().has(PlatformModifiers.PLATAFORMAS_QUE_PISCAM) and snap.get_proporcao_piscantes() > 0.0:
			com_pisca.append(caso)
	return com_pisca


# Curva de producao com proporcao_piscantes = 1.0 em todo estagio (pior caso de alcance). `so_pisca` troca as mecanicas
# dos estagios que piscam so por ela (isola a mecanica); sem ele valem as combinacoes de producao.
func _estado_forcado(progresso: float, so_pisca: bool) -> DifficultyState:
	var curva := _curva()
	var forcada := DifficultyCurve.new()
	forcada.pontos_plato = curva.pontos_plato
	forcada.segundos_plato = curva.segundos_plato
	var estagios: Array[DifficultyStage] = []
	for original in curva.estagios:
		var copia := original.duplicate() as DifficultyStage
		copia.proporcao_piscantes = 1.0
		if so_pisca and original.mecanicas.has(PlatformModifiers.PLATAFORMAS_QUE_PISCAM):
			copia.mecanicas = _so_pisca()
		estagios.append(copia)
	forcada.estagios = estagios
	var estado := DifficultyState.new(forcada)
	estado.progresso_inicial = progresso
	return estado


func _filhas_plataforma(gerador: Node) -> Array:
	var filhas: Array = []
	for filha in gerador.get_children():
		if filha is Platform and is_instance_valid(filha) and not filha.is_queued_for_deletion():
			filhas.append(filha)
	return filhas


func _y_da_linha(indice: int) -> float:
	return Y_BASE - InitialRows.ESPACAMENTO * indice


func _blink(fase: float) -> PlatformBlink:
	var blink := PlatformBlink.new()
	blink.iniciar(_rng(3), VISIVEL, INVISIVEL, AVISO)
	blink.definir_fase(fase)
	return blink


# Plataforma real com um PlatformBlink de fase fixa, fora da tela (nao colide com o gecko da Stage nem sai do notifier).
func _piscante_em(pai: Node, fase: float, cor: Enums.COLOR) -> Platform:
	var p: Platform = load(PLATAFORMA_CENA).instantiate()
	p.set_color(cor)
	var lista: Array = [_blink(fase)]
	p.definir_modificadores(lista, DifficultySnapshot.new())
	p.position = Vector2(500.0, 150.0)
	pai.add_child(p)
	return p


func _outra_cor(cor: int) -> Enums.COLOR:
	return ((cor + 1) % Enums.COLOR.size()) as Enums.COLOR


# --- C325 / C328: simulacao de alcance com tempo -------------------------------------------------------------------------


# Gerador real de uma linha (estatica ou movel), na altura da linha `indice`, com a cor do gecko vigente na criacao.
func _nova_linha(
	indice: int, cor_gecko: int, rng: RandomNumberGenerator, estado: DifficultyState, inicial: bool
) -> Dictionary:
	var tipo: int = Enums.PLATFORM_TYPE.STATIC
	if not inicial:
		tipo = PlatformTypePicker.resolve(
			Enums.PLATFORM_TYPE.RANDOM_ALL, rng, estado.snapshot().get_proporcao_estaticas()
		)
	var gerador: Node2D = load(GERADOR_SCENE).instantiate()
	gerador.platform_type = tipo
	gerador.garantir_cor_inicial = inicial
	gerador.dificuldade = estado
	gerador.rng = rng
	gerador.position = Vector2(0.0, _y_da_linha(indice))
	Global.cor_gecko = cor_gecko as Enums.COLOR
	add_child_autofree(gerador)
	return {"y": _y_da_linha(indice), "tipo": tipo, "plataformas": _filhas_plataforma(gerador)}


func _todas(linhas: Array) -> Array:
	var todas: Array = []
	for linha in linhas:
		todas.append_array(linha["plataformas"])
	return todas


func _visivel_x(p: Platform) -> bool:
	return p.position.x >= 0.0 and p.position.x <= LARGURA


# Avanca o relogio `segundos`: piscantes e cicladoras das linhas g..fim (travada nao anda: o modificador consulta a plataforma).
func _avancar(linhas: Array, g: int, segundos: float) -> void:
	var taxa: float = float(Engine.physics_ticks_per_second)
	var frames: int = roundi(segundos * taxa)
	for i in range(g, linhas.size()):
		for p in linhas[i]["plataformas"]:
			for m in p._modificadores:
				if m is PlatformBlink:
					m.ao_processar(p, segundos)
				elif m is PlatformColorCycle:
					for _f in frames:
						m.ao_processar(p, 1.0 / taxa)


# Conferencia independente do preditor: a plataforma tem a cor `cor` e fica visivel em TODO instante amostrado (1 frame)
# de [dt, dt + espera], inclusive o ultimo.
func _cobre_a_janela(p: Platform, cor: int, dt: float, espera: float) -> bool:
	var taxa: float = float(Engine.physics_ticks_per_second)
	var ciclo: PlatformColorCycle = p.obter_ciclo()
	var pisca: PlatformBlink = p.obter_pisca()
	var passos: int = ceili(espera * taxa)
	for k in range(passos + 1):
		var t: float = dt + minf(float(k) / taxa, espera)
		var cor_em_t: int = ciclo.cor_em(t) if ciclo != null else int(p.color)
		if cor_em_t != cor:
			return false
		if pisca != null and not pisca.visivel_em(t):
			return false
	return true


# Descricao da linha de chegada para a mensagem de falha: tipo, x, cor e o que cada plataforma tem (pisca/ciclo).
func _descrever(linha: Dictionary, dt: float, espera: float) -> String:
	var partes: Array = []
	for p in linha["plataformas"]:
		var etiqueta: String = "-"
		if p.obter_pisca() != null:
			etiqueta = "pisca(cobre=%s)" % p.obter_pisca().visivel_na_janela(dt, dt + espera)
		elif p.obter_ciclo() != null:
			etiqueta = "ciclo"
		partes.append("x=%.0f cor=%d %s" % [p.position.x, int(p.color), etiqueta])
	return "tipo=%d [%s]" % [linha["tipo"], "; ".join(partes)]


func _apoio_que_cobre(linha: Dictionary, cor: int, dt: float, espera: float) -> bool:
	for p in linha["plataformas"]:
		if _visivel_x(p) and _cobre_a_janela(p, cor, dt, espera):
			return true
	return false


# Devolve {linhas, eventos}. Evento = um pouso na linha g e a chegada na g+1 pela previsao.
func _simular(semente: int, estado: DifficultyState) -> Dictionary:
	seed(semente)
	var rng := _rng(semente)
	var snap: DifficultySnapshot = estado.snapshot()
	var taxa: float = float(Engine.physics_ticks_per_second)
	var tempo_pulo: float = ReachableColors.tempo_de_pulo(snap.get_scroll())
	var espera: float = PlayerFisica.ESPERA_MAXIMA_S
	var atraso_maximo: int = roundi(espera * taxa) - 1
	var cor: int = Enums.COR_INICIAL
	var linhas: Array = []
	for i in InitialRows.initial_row_ys(ALTURA_TELA).size():
		linhas.append(_nova_linha(i, cor, rng, estado, true))
	var eventos: Array = []
	var pouso: Platform = null
	for g in range(LINHAS - 1):
		var cor_antes: int = cor
		while linhas.size() <= g + LINHAS_A_FRENTE:
			linhas.append(_nova_linha(linhas.size(), cor_antes, rng, estado, false))
		var entradas: Array = ReachableColors.entradas_de_plataformas(_todas(linhas))
		var candidatas: Array = ReachableColors.coletar_cores_linha_acima(
			entradas, float(linhas[g]["y"]), LARGURA, tempo_pulo, espera
		)
		cor = ReachableColors.escolher_cor_gecko(candidatas, rng)
		Global.cor_gecko = cor as Enums.COLOR
		var cobre: bool = _apoio_que_cobre(linhas[g + 1], cor, tempo_pulo, espera)
		var diag: String = _descrever(linhas[g + 1], tempo_pulo, espera)
		var atraso: int = [0, atraso_maximo][g % 2] if g % 4 < 2 else rng.randi_range(0, atraso_maximo)
		# O gecko espera `atraso` frames em cima da plataforma (travando-a), pula e chega.
		_avancar(linhas, g, float(atraso) / taxa)
		if pouso != null:
			pouso.definir_travada(false)
		_avancar(linhas, g, tempo_pulo)
		pouso = null
		var piscantes_visiveis: int = 0
		for p in linhas[g + 1]["plataformas"]:
			if not _visivel_x(p):
				continue
			var pisca: PlatformBlink = p.obter_pisca()
			if pisca != null and pisca.esta_visivel():
				piscantes_visiveis += 1
			if pouso == null and int(p.color) == cor and (pisca == null or pisca.esta_visivel()):
				pouso = p
		if pouso != null:
			pouso.definir_travada(true)
		eventos.append(
			{
				"g": g,
				"diag": diag,
				"atraso": atraso,
				"nova": cor,
				"candidatas": candidatas,
				"fallback": candidatas.is_empty(),
				"cobre": cobre,
				"chegada_ok": pouso != null,
				"pouso_piscante": pouso != null and pouso.obter_pisca() != null,
				"piscantes_visiveis": piscantes_visiveis,
			}
		)
	return {"linhas": linhas, "eventos": eventos}


func _contar_modificadores(linhas: Array) -> Dictionary:
	var contagem := {"pisca": 0, "ciclo": 0, "seno": 0, "vai_e_vem": 0, "cai": 0}
	for p in _todas(linhas):
		for m in p._modificadores:
			if m is PlatformBlink:
				contagem["pisca"] += 1
			elif m is PlatformColorCycle:
				contagem["ciclo"] += 1
			elif m is PlatformSineMotion:
				contagem["seno"] += 1
			elif m is PlatformPingPongMotion:
				contagem["vai_e_vem"] += 1
			elif m is PlatformCrumble:
				contagem["cai"] += 1
	return contagem


# Roda a simulacao em todos os casos com a mecanica e confere alcance (sem fallback, janela coberta, chegada com apoio).
func _conferir_alcance(so_pisca: bool) -> Dictionary:
	var casos: Array = _casos_com_pisca()
	assert_gt(casos.size(), 0, "a curva de producao tem estagio com a mecanica que pisca")
	var totais := {"eventos": 0, "pouso_piscante": 0, "piscantes_visiveis": 0, "pisca": 0, "ciclo": 0, "seno": 0, "vai_e_vem": 0, "cai": 0}
	for caso in casos:
		var sem_candidata: Array = []
		var janela_descoberta: Array = []
		var sem_apoio: Array = []
		for semente in SEEDS:
			var sim: Dictionary = _simular(semente, _estado_forcado(caso[1], so_pisca))
			assert_eq(sim["eventos"].size(), LINHAS - 1, "%s: um pouso por linha" % caso[0])
			var contagem: Dictionary = _contar_modificadores(sim["linhas"])
			for chave in contagem:
				totais[chave] += contagem[chave]
			for e in sim["eventos"]:
				totais["eventos"] += 1
				totais["piscantes_visiveis"] += e["piscantes_visiveis"]
				if e["pouso_piscante"]:
					totais["pouso_piscante"] += 1
				var rotulo: String = "%s semente=%d pouso=%d cor=%d atraso=%d" % [caso[0], semente, e["g"], e["nova"], e["atraso"]]
				if e["fallback"]:
					sem_candidata.append(rotulo + " linha " + str(e["diag"]))
				if not e["cobre"]:
					janela_descoberta.append(rotulo)
				if not e["chegada_ok"]:
					sem_apoio.append(rotulo)
		assert_eq(
			sem_candidata.size(),
			0,
			"%s: nenhum pouso cai no sorteio livre (toda linha tem candidata visivel na janela): %s" % [caso[0], str(sem_candidata)]
		)
		assert_eq(janela_descoberta, [], "%s: a cor sorteada tem apoio visivel em toda a janela de chegada" % caso[0])
		assert_eq(sem_apoio, [], "%s: a cor sorteada tem plataforma solida na linha de cima na chegada" % caso[0])
	return totais


func test_c325_todo_pouso_tem_candidata_visivel_na_janela_com_todas_as_piscantes_forcadas() -> void:
	var totais: Dictionary = _conferir_alcance(true)
	assert_gt(totais["pisca"], 0, "a simulacao gera piscantes (proporcao forcada a 1.0)")
	assert_gt(totais["piscantes_visiveis"], 0, "ha piscante visivel na linha de chegada (o teste nao e vacuo)")
	assert_gt(totais["pouso_piscante"], 0, "o gecko pousa em piscante em algum pouso")


# C328: E3 de producao com que_caem, mudam_de_cor, seno e vai-e-vem ligados junto com a mecanica
func test_c328_alcance_segue_valido_com_as_demais_mecanicas_do_estagio_ligadas() -> void:
	var totais: Dictionary = _conferir_alcance(false)
	assert_gt(totais["pisca"], 0, "a simulacao gera piscantes")
	assert_gt(totais["ciclo"], 0, "as cicladoras de producao estao na simulacao")
	assert_gt(totais["seno"], 0, "ha oscilantes seno")
	assert_gt(totais["vai_e_vem"], 0, "ha oscilantes vai-e-vem")
	assert_gt(totais["cai"], 0, "ha plataformas que caem")
	assert_gt(totais["pouso_piscante"], 0, "o gecko pousa em piscante em algum pouso")


# --- C326: garantia K ---------------------------------------------------------------------------------------------------


func test_c326_toda_janela_de_k_moveis_tem_a_cor_do_gecko_com_a_mecanica_ligada() -> void:
	var falhas: Array = []
	var janelas: int = 0
	var piscantes: int = 0
	var casos: Array = _casos_com_pisca()
	assert_gt(casos.size(), 0, "a curva de producao tem estagio com a mecanica que pisca")
	for caso in casos:
		var snap: DifficultySnapshot = caso[2]
		var k: int = snap.get_k()
		for semente in SEEDS:
			var rng := _rng(semente)
			var gerador: Node2D = load(GERADOR_SCENE).instantiate()
			gerador.platform_type = Enums.PLATFORM_TYPE.MOVE_TO_LEFT
			gerador.dificuldade = _estado_forcado(caso[1], false)
			gerador.rng = rng
			gerador.position = Vector2(0, 100)
			var historico: Array = []
			gerador.child_entered_tree.connect(
				func(no: Node) -> void:
					if no is Platform:
						historico.append({"cor": int(no.color), "gecko": int(Global.cor_gecko), "pisca": no.obter_pisca() != null})
			)
			Global.set_iniciado(true)
			Global.cor_gecko = Enums.get_random_color(rng)
			add_child_autofree(gerador)
			for n in PLATAFORMAS_POR_GERADOR:
				if n % 3 == 0:
					Global.cor_gecko = Enums.get_random_color(rng)
				gerador.new_platform()
			for i in historico.size():
				janelas += 1
				if historico[i]["pisca"]:
					piscantes += 1
				var tem: bool = false
				for j in range(maxi(0, i - k + 1), i + 1):
					if historico[j]["cor"] == historico[i]["gecko"]:
						tem = true
				if not tem:
					falhas.append("%s semente %d: janela K=%d terminada na plataforma %d sem a cor do gecko" % [caso[0], semente, k, i])
	assert_gt(janelas, 0, "ha janelas de K para conferir")
	assert_gt(piscantes, 0, "ha piscantes entre as moveis (a mecanica esta ligada)")
	assert_eq(
		falhas.size(),
		0,
		"toda janela de K moveis consecutivas tem a cor do gecko vigente com a mecanica ligada: %s" % str(falhas.slice(0, 2))
	)


# --- C327: piso do .tres ------------------------------------------------------------------------------------------------


func test_c327_duracao_visivel_do_tres_cobre_a_espera_maxima_mais_o_aviso() -> void:
	var curva := _curva()
	var com_pisca: int = 0
	for i in range(curva.estagios.size()):
		var estagio: DifficultyStage = curva.estagios[i]
		if not estagio.mecanicas.has(PlatformModifiers.PLATAFORMAS_QUE_PISCAM):
			continue
		com_pisca += 1
		var espera: float = PlayerFisica.ESPERA_MAXIMA_S
		var piso: float = espera + estagio.aviso_pisca
		assert_gte(
			estagio.duracao_visivel,
			piso,
			(
				"piso do .tres violado (duracao_visivel menor que ESPERA_MAXIMA_S + aviso_pisca): reduza aviso_pisca para no maximo %.2f ou suba duracao_visivel para no minimo %.2f (estagio %d)"
				% [estagio.duracao_visivel - espera, piso, i]
			)
		)
	assert_gt(com_pisca, 0, "a curva de producao tem estagio com a mecanica que pisca")


# --- C329: espacamento e saida do CheckGenerate com piscantes forcadas -------------------------------------------------


# Estado so do estagio (progresso 0), com piscantes e oscilantes em 1.0: pior caso para o espacamento.
func _estado_so_do_estagio(estagio: DifficultyStage) -> DifficultyState:
	var copia := estagio.duplicate() as DifficultyStage
	copia.progresso_inicio = 0.0
	copia.proporcao_piscantes = 1.0
	copia.proporcao_oscilantes = 1.0
	var curva := DifficultyCurve.new()
	curva.estagios = [copia]
	return DifficultyState.new(curva)


func _iniciar_medida(indice: int, estagio: DifficultyStage, semente: int, tipo: Enums.PLATFORM_TYPE, linha: int) -> Dictionary:
	var gerador: Node2D = load(GERADOR_SCENE).instantiate()
	gerador.platform_type = tipo
	gerador.dificuldade = _estado_so_do_estagio(estagio)
	gerador.rng = _rng(semente)
	gerador.position = Vector2(0, 20.0 + ALTURA_ENTRE_GERADORES * linha)
	var spawn_x: float = 210.0 if tipo == Enums.PLATFORM_TYPE.MOVE_TO_LEFT else -30.0
	var registro := {
		"rotulo": "E%d semente %d %s" % [indice, semente, "esq" if tipo == Enums.PLATFORM_TYPE.MOVE_TO_LEFT else "dir"],
		"gerador": gerador,
		"largura": estagio.largura_plataforma,
		"min_gap": INF,
		"pior": "",
		"saidas": {},
		"nascimentos": {},
		"amostras": 0,
		"ocultas": 0,
	}
	gerador.child_entered_tree.connect(
		func(no: Node) -> void:
			if no is Platform and is_equal_approx(no.position.x, spawn_x):
				registro["nascimentos"][no.get_instance_id()] = Engine.get_physics_frames()
	)
	Global.set_iniciado(true)
	add_child_autofree(gerador)
	gerador.check_generate.area_exited.connect(
		func(area: Area2D) -> void:
			var dono: Node = area.get_parent()
			var id: int = dono.get_instance_id()
			registro["saidas"][id] = int(registro["saidas"].get(id, 0)) + 1
	)
	return registro


func _amostrar(execucoes: Array) -> void:
	for ex in execucoes:
		if ex["gerador"] == null or not is_instance_valid(ex["gerador"]):
			continue
		var ps: Array = _filhas_plataforma(ex["gerador"])
		ps.sort_custom(func(a: Platform, b: Platform) -> bool: return a.position.x < b.position.x)
		ex["amostras"] += 1
		for p in ps:
			if p._pisca_oculta:
				ex["ocultas"] += 1
		for j in range(ps.size() - 1):
			var gap: float = ps[j + 1].position.x - ps[j].position.x - float(ex["largura"])
			if gap < float(ex["min_gap"]):
				ex["min_gap"] = gap
				ex["pior"] = (
					"%s: speed %.1f, vizinhas em x %.1f e %.1f, largura %.1f"
					% [ex["rotulo"], absf(float(ex["gerador"].speed)), ps[j].position.x, ps[j + 1].position.x, ex["largura"]]
				)


func test_c329_invisibilidade_nao_muda_o_espacamento_nem_a_saida_do_check_generate() -> void:
	var curva := _curva()
	var execucoes: Array = []
	var linha: int = 0
	for i in range(curva.estagios.size()):
		var estagio: DifficultyStage = curva.estagios[i]
		if not estagio.mecanicas.has(PlatformModifiers.PLATAFORMAS_QUE_PISCAM):
			continue
		for semente in SEEDS:
			for tipo in [Enums.PLATFORM_TYPE.MOVE_TO_LEFT, Enums.PLATFORM_TYPE.MOVE_TO_RIGHT]:
				execucoes.append(_iniciar_medida(i, estagio, semente, tipo, linha))
				linha += 1
	assert_gte(execucoes.size(), 2 * SEEDS.size(), "ha estagio com a mecanica: 2 sentidos x sementes")
	var amostrador := func() -> void: _amostrar(execucoes)
	get_tree().physics_frame.connect(amostrador)
	await wait_physics_frames(FRAMES_MEDIDA)
	get_tree().physics_frame.disconnect(amostrador)
	var frame_fim: int = Engine.get_physics_frames()
	var falhas: Array = []
	var verificadas: int = 0
	var ocultas: int = 0
	for ex in execucoes:
		ocultas += int(ex["ocultas"])
		assert_gt(int(ex["amostras"]), FRAMES_MEDIDA / 2, "%s: a linha foi amostrada durante a simulacao" % ex["rotulo"])
		assert_gt(float(ex["min_gap"]), 0.0, "espacamento minimo borda a borda <= 0 px (%.2f): %s" % [float(ex["min_gap"]), ex["pior"]])
		for id in ex["saidas"]:
			if int(ex["saidas"][id]) != 1:
				falhas.append("%s: plataforma %d saiu %d vezes" % [ex["rotulo"], id, ex["saidas"][id]])
		for id in ex["nascimentos"]:
			var idade: int = frame_fim - int(ex["nascimentos"][id])
			if idade < FRAMES_PARA_SAIR:
				continue
			verificadas += 1
			if int(ex["saidas"].get(id, 0)) != 1:
				falhas.append("%s: plataforma nascida ha %d frames teve %d saidas (esperado 1)" % [ex["rotulo"], idade, int(ex["saidas"].get(id, 0))])
	assert_gt(ocultas, 0, "ha piscante invisivel durante a medida (o teste exercita a invisibilidade)")
	assert_gt(verificadas, 2 * SEEDS.size(), "ha plataformas nascidas o bastante para ja terem saido do CheckGenerate")
	assert_eq(falhas, [], "exatamente 1 saida de CheckGenerate por plataforma, visivel ou nao")


# --- C330: gecko em cima (D4: trava) ------------------------------------------------------------------------------------


func test_c330_plataforma_travada_nao_some_e_destravada_perde_a_colisao() -> void:
	Global.iniciado = true
	var cor: Enums.COLOR = Enums.COLOR.AMARELO
	var travada: Platform = _piscante_em(self, 2.0, cor)
	var controle: Platform = _piscante_em(self, 2.0, cor)
	var outra: Platform = load(PLATAFORMA_CENA).instantiate()
	outra.set_color(_outra_cor(cor))
	add_child_autofree(outra)
	autofree(travada)
	autofree(controle)
	# O gecko pousa na plataforma `travada` (mesma cor): Global trava essa e solta as demais
	Global.player_color_changed(cor, travada)
	assert_true(travada.esta_travada(), "o gecko esta em cima: plataforma travada")
	var sumiu: Array = []
	var controle_sumiu: bool = false
	for bloco in 15:
		await wait_physics_frames(10)
		if travada.modulate.a != 1.0 or travada.shape.disabled:
			sumiu.append("bloco %d: alfa %.2f desligada %s" % [bloco, travada.modulate.a, travada.shape.disabled])
		if controle.shape.disabled and controle.modulate.a < 1.0:
			controle_sumiu = true
	assert_eq(sumiu, [], "travada, a plataforma nao some nem perde a colisao durante 2,5 s (mais que o visivel restante)")
	assert_eq(travada.obter_pisca().get_fase(), 2.0, "o relogio da plataforma travada fica congelado")
	assert_true(controle_sumiu, "a plataforma igual sem o gecko em cima some no mesmo intervalo (o teste nao e vacuo)")
	# O gecko sai (pousa em outra de mesma cor): a plataforma destrava, volta a andar e perde a colisao ao ficar invisivel
	Global.player_color_changed(cor, outra)
	assert_false(travada.esta_travada(), "o gecko saiu: destravada")
	await wait_physics_frames(90)
	assert_false(travada.obter_pisca().esta_visivel(), "destravada, a fase avancou ate o invisivel")
	assert_true(travada.shape.disabled, "destravada e invisivel: o gecko perde a colisao")
	assert_almost_eq(travada.modulate.a, Platform.PISCA_ALFA_FANTASMA, 0.001, "destravada e invisivel: fantasma")


# --- C331 / C332: pausa, pre-partida e recarga (Stage real) --------------------------------------------------------------


func _novo_stage(iniciar: bool) -> Node:
	var stage: Node = add_child_autofree(load(STAGE_SCENE).instantiate())
	await wait_frames(2)
	if iniciar:
		stage._on_Play_button_down()
		await wait_frames(2)
	return stage


func test_c331_com_a_arvore_pausada_as_fases_nao_avancam() -> void:
	var stage := await _novo_stage(true)
	var p: Platform = _piscante_em(stage, 0.5, _outra_cor(Global.cor_gecko))
	await wait_physics_frames(6)
	var corrida: float = p.obter_pisca().get_fase()
	assert_gt(corrida, 0.5, "com a partida em curso o relogio avanca (o teste nao e vacuo)")
	assert_true(stage._pausar(), "a partida ativa pausa")
	assert_true(get_tree().paused, "arvore pausada")
	var congelada: float = p.obter_pisca().get_fase()
	await wait_physics_frames(TICKS)
	assert_eq(p.obter_pisca().get_fase(), congelada, "pausada: a fase da piscante nao avanca")
	stage._retomar()
	await wait_physics_frames(6)
	assert_gt(p.obter_pisca().get_fase(), congelada, "retomada: o relogio volta a correr a partir do mesmo ponto")


func test_c332_pre_partida_nao_muda_visibilidade_e_recarga_do_stage_zera_as_fases() -> void:
	var stage := await _novo_stage(false)
	assert_false(Global.is_iniciado(), "menu: partida nao iniciada")
	var cor: Enums.COLOR = _outra_cor(Global.cor_gecko)
	var visivel: Platform = _piscante_em(stage, 2.0, cor)
	var invisivel: Platform = _piscante_em(stage, 3.5, cor)
	assert_eq(visivel.modulate.a, 1.0, "nasce visivel")
	assert_almost_eq(invisivel.modulate.a, Platform.PISCA_ALFA_FANTASMA, 0.001, "nasce fantasma")
	await wait_physics_frames(30)
	assert_eq(visivel.obter_pisca().get_fase(), 2.0, "pre-partida: o relogio da visivel nao corre")
	assert_eq(invisivel.obter_pisca().get_fase(), 3.5, "pre-partida: o relogio da invisivel nao corre")
	assert_eq(visivel.modulate.a, 1.0, "pre-partida: a visivel segue visivel")
	assert_almost_eq(invisivel.modulate.a, Platform.PISCA_ALFA_FANTASMA, 0.001, "pre-partida: a invisivel segue fantasma")
	assert_true(invisivel.shape.disabled, "pre-partida: a invisivel segue sem colisao")
	stage._on_Play_button_down()
	await wait_physics_frames(20)
	assert_ne(visivel.obter_pisca().get_fase(), 2.0, "com a partida iniciada o relogio corre (o teste nao e vacuo)")
	assert_gt(stage.dificuldade._segundos, 0.0, "a partida acumulou tempo antes da recarga")
	# Recarga do Stage: cena nova, dificuldade e plataformas do zero (a velha sai de Global.platforms)
	stage.queue_free()
	await wait_frames(2)
	var novo := await _novo_stage(false)
	assert_false(Global.is_iniciado(), "Stage recarregado: partida nao iniciada")
	assert_eq(novo.dificuldade._segundos, 0.0, "recarga: o tempo da dificuldade volta a zero")
	var restantes: int = 0
	for p in Global.platforms:
		if is_instance_valid(p) and p.obter_pisca() != null:
			restantes += 1
	assert_eq(restantes, 0, "recarga: nenhuma piscante (nem fase) da partida anterior sobrevive")


# --- C333: modo sem derrota (D5: inerte) ----------------------------------------------------------------------------------


func test_c333_sem_derrota_todas_visiveis_e_solidas_com_proporcao_1() -> void:
	Global.sem_derrota = true
	Global.iniciado = true
	Global.cor_gecko = Enums.COR_INICIAL
	var geradas: Array = []
	for tipo in [Enums.PLATFORM_TYPE.STATIC, Enums.PLATFORM_TYPE.MOVE_TO_LEFT, Enums.PLATFORM_TYPE.MOVE_TO_RIGHT]:
		for semente in SEEDS:
			var gerador: Node2D = load(GERADOR_SCENE).instantiate()
			gerador.platform_type = tipo
			gerador.dificuldade = _estado_forcado(1.0, false)
			gerador.rng = _rng(semente)
			gerador.position = Vector2(0.0, 100.0)
			add_child_autofree(gerador)
			for n in PLATAFORMAS_POR_GERADOR:
				if tipo != Enums.PLATFORM_TYPE.STATIC:
					gerador.new_platform()
			geradas.append_array(_filhas_plataforma(gerador))
	assert_gt(geradas.size(), 20, "plataformas geradas com a proporcao forcada a 1.0")
	var piscantes: int = 0
	for p in geradas:
		if p.obter_pisca() != null:
			piscantes += 1
	assert_eq(piscantes, 0, "sem_derrota: o gerador nao sorteia nenhuma piscante")
	# Mesmo uma piscante forcada fica inerte: visivel e solida ao longo de 10 s, inclusive na fase invisivel
	var forcada: Platform = _piscante_em(self, 3.5, Enums.COR_INICIAL)
	autofree(forcada)
	forcada.player_color_changed(Enums.COR_INICIAL)
	var falhas: Array = []
	for passo in 600:
		forcada._physics_process(1.0 / 60.0)
		if forcada.modulate.a != 1.0 or forcada.shape.disabled or forcada.obter_pisca().get_fase() != 3.5:
			falhas.append("passo %d: alfa %.2f desligada %s fase %.2f" % [passo, forcada.modulate.a, forcada.shape.disabled, forcada.obter_pisca().get_fase()])
	assert_eq(falhas.slice(0, 3), [], "sem_derrota: a piscante forcada nunca some (relogio parado, solida)")
	for p in geradas:
		p.player_color_changed(Enums.COR_INICIAL)
		assert_false(p.shape.disabled, "sem_derrota: toda plataforma gerada e solida para o gecko da cor inicial")
		assert_eq(p.modulate.a, 1.0, "sem_derrota: toda plataforma gerada e visivel")
