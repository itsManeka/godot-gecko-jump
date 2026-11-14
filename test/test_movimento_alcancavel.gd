extends GutTest

# f467 T7: espacamento, saidas do CheckGenerate e alcancabilidade com as mecanicas de movimento (oscilacao seno/vai-e-vem
# e speed por linha) ligadas. Estagios lidos do .tres de producao (nada hardcodado); sementes declaradas aqui.
#   C290/C291: cena real (RunningPlatforms + Platform + CheckGenerate, fisica de verdade), 1 gerador por (estagio, semente,
#              sentido), empilhados em y distintos (nao se enxergam pela layer do CheckGenerate). Pior caso de
#              espacamento: proporcao_oscilantes forcada a 1.0 (toda vizinha oscila, cada uma com a propria fase).
#   C292:      gerador real (_cor_movel) criando N plataformas, cor do gecko mudando no meio; janela de K.
#   C293:      simulacao pura com a amplitude maxima aplicada ao x (borda do filtro [0, 180]).
#   C294:      modelo fisico do pulo (padrao de test_difficulty_alcance_fisico.gd) com a speed do pior caso.

const CURVA_PATH := "res://ressources/curva_dificuldade.tres"
const GERADOR_SCENE := "res://scenes/RunningPlatforms.tscn"
const PLAYER_SCRIPT := "res://scenes/Player.gd"
const SEMENTES := [20261110, 20261111, 20261112]
const FRAMES_MEDIDA := 360
# Nascida ha menos que isto ainda pode nao ter saido do CheckGenerate (slowest: speed 61 -> ~60 ticks + oscilacao)
const FRAMES_PARA_SAIR := 150
const ALTURA_ENTRE_GERADORES := 25.0
const PLATAFORMAS_POR_GERADOR := 40
const EPS_PROGRESSO := 0.001
const LARGURA_JOGAVEL := 180.0
const MARGEM_VERTICAL := 5.0
const LINHAS_SIMULADAS := 120

var _cor_original: Enums.COLOR
var _cache_medida: Array = []


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


func _curva() -> DifficultyCurve:
	return load(CURVA_PATH) as DifficultyCurve


func _rng(semente: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	return rng


func _oscila(mecanicas: Array[StringName]) -> bool:
	return mecanicas.has(PlatformModifiers.MOVIMENTO_SENO) or mecanicas.has(PlatformModifiers.MOVIMENTO_VAI_E_VEM)


func _tem_mecanica_nova(mecanicas: Array[StringName]) -> bool:
	return _oscila(mecanicas) or mecanicas.has(PlatformModifiers.SPEED_POR_LINHA)


# Estados do estagio de producao, mas com a proporcao de oscilantes em 1.0 (pior caso de espacamento entre vizinhas).
func _estado_so_do_estagio(estagio: DifficultyStage) -> DifficultyState:
	var copia := estagio.duplicate() as DifficultyStage
	copia.progresso_inicio = 0.0
	copia.proporcao_oscilantes = 1.0
	var curva := DifficultyCurve.new()
	curva.estagios = [copia]
	return DifficultyState.new(curva)


# Casos [rotulo, progresso, snapshot]: inicio e fim de cada estagio e o teto, lidos da curva de producao.
func _casos() -> Array:
	var curva := _curva()
	var casos: Array = []
	for i in range(curva.estagios.size()):
		var p_ini: float = curva.estagios[i].progresso_inicio
		casos.append(["E%d inicio" % i, p_ini, curva.avaliar(p_ini * curva.pontos_plato, 0.0)])
		if i + 1 < curva.estagios.size():
			var p_fim: float = curva.estagios[i + 1].progresso_inicio - EPS_PROGRESSO
			casos.append(["E%d fim" % i, p_fim, curva.avaliar(p_fim * curva.pontos_plato, 0.0)])
	casos.append(["teto", 1.0, curva.avaliar(curva.pontos_plato, curva.segundos_plato)])
	return casos


func _plataformas(gerador: Node) -> Array:
	var filhas: Array = []
	for filha in gerador.get_children():
		if filha is Platform and is_instance_valid(filha) and not filha.is_queued_for_deletion():
			filhas.append(filha)
	return filhas


func _fase_de(plataforma: Platform) -> float:
	for modificador in plataforma._modificadores:
		if modificador is PlatformSineMotion or modificador is PlatformPingPongMotion:
			return modificador.get_fase()
	return -1.0


# --- C290 / C291: cena real ----------------------------------------------------------------------------------------


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
		# Depois da medida o registro perde o no (e o gerador e liberado no fim do teste): nada a amostrar
		if ex["gerador"] == null or not is_instance_valid(ex["gerador"]):
			continue
		var ps: Array = _plataformas(ex["gerador"])
		ps.sort_custom(func(a: Platform, b: Platform) -> bool: return a.position.x < b.position.x)
		ex["amostras"] += 1
		for j in range(ps.size() - 1):
			var gap: float = ps[j + 1].position.x - ps[j].position.x - float(ex["largura"])
			if gap < float(ex["min_gap"]):
				ex["min_gap"] = gap
				ex["pior"] = (
					"%s: speed %.1f, fase %.2f e %.2f, vizinhas em x %.1f e %.1f, largura %.1f"
					% [ex["rotulo"], absf(float(ex["gerador"].speed)), _fase_de(ps[j]), _fase_de(ps[j + 1]),
						ps[j].position.x, ps[j + 1].position.x, ex["largura"]]
				)


# Roda 1x todos os geradores (estagios com oscilacao x sementes x sentidos) e devolve os registros sem referencia a no.
func _medir() -> Array:
	if not _cache_medida.is_empty():
		return _cache_medida
	var curva := _curva()
	var execucoes: Array = []
	var linha := 0
	for i in range(curva.estagios.size()):
		var estagio: DifficultyStage = curva.estagios[i]
		if not _oscila(estagio.mecanicas):
			continue
		for semente in SEMENTES:
			for tipo in [Enums.PLATFORM_TYPE.MOVE_TO_LEFT, Enums.PLATFORM_TYPE.MOVE_TO_RIGHT]:
				execucoes.append(_iniciar_medida(i, estagio, semente, tipo, linha))
				linha += 1
	var amostrador := func() -> void: _amostrar(execucoes)
	get_tree().physics_frame.connect(amostrador)
	var inicio: int = Engine.get_physics_frames()
	await wait_physics_frames(FRAMES_MEDIDA)
	get_tree().physics_frame.disconnect(amostrador)
	for ex in execucoes:
		ex["speed_final"] = absf(float(ex["gerador"].speed))
		ex["frame_fim"] = Engine.get_physics_frames()
		ex["frame_inicio"] = inicio
		ex["gerador"] = null
	_cache_medida = execucoes
	return _cache_medida


func test_c290_espacamento_borda_a_borda_entre_vizinhas_oscilantes_fica_acima_de_zero() -> void:
	var execucoes: Array = await _medir()
	assert_gte(execucoes.size(), 2 * SEMENTES.size(), "ha estagio com oscilacao na curva: 2 sentidos x sementes por estagio")
	for ex in execucoes:
		assert_gt(int(ex["amostras"]), FRAMES_MEDIDA / 2, "%s: a linha foi amostrada durante a simulacao" % ex["rotulo"])
		assert_gt(
			float(ex["min_gap"]),
			0.0,
			"espacamento minimo borda a borda <= 0 px (%.2f): %s" % [float(ex["min_gap"]), ex["pior"]]
		)


func test_c291_cada_plataforma_gera_exatamente_uma_saida_do_check_generate() -> void:
	var execucoes: Array = await _medir()
	var falhas: Array = []
	var verificadas := 0
	for ex in execucoes:
		for id in ex["saidas"]:
			if int(ex["saidas"][id]) != 1:
				falhas.append("%s: plataforma %d saiu %d vezes (speed %.1f)" % [ex["rotulo"], id, ex["saidas"][id], ex["speed_final"]])
		for id in ex["nascimentos"]:
			var idade: int = int(ex["frame_fim"]) - int(ex["nascimentos"][id])
			if idade < FRAMES_PARA_SAIR:
				continue
			verificadas += 1
			if int(ex["saidas"].get(id, 0)) != 1:
				falhas.append(
					"%s: plataforma nascida ha %d frames teve %d saidas (esperado 1; speed %.1f)"
					% [ex["rotulo"], idade, int(ex["saidas"].get(id, 0)), ex["speed_final"]]
				)
	assert_gt(verificadas, 2 * SEMENTES.size(), "ha plataformas nascidas o bastante para ja terem saido do CheckGenerate")
	assert_eq(falhas, [], "exatamente 1 saida de CheckGenerate por plataforma (2 = inversao, 0 = nunca saiu)")


# --- C292: garantia K com a mecanica ligada ------------------------------------------------------------------------


func test_c292_toda_janela_de_k_moveis_tem_a_cor_do_gecko_com_a_mecanica_ligada() -> void:
	var falhas: Array = []
	var casos_com_mecanica := 0
	var janelas := 0
	var curva := _curva()
	for caso in _casos():
		var snap: DifficultySnapshot = caso[2]
		if not _tem_mecanica_nova(snap.get_mecanicas()):
			continue
		casos_com_mecanica += 1
		var k: int = snap.get_k()
		for semente in SEMENTES:
			var rng := _rng(semente)
			var estado := DifficultyState.new(curva)
			estado.progresso_inicial = caso[1]
			var gerador: Node2D = load(GERADOR_SCENE).instantiate()
			gerador.platform_type = Enums.PLATFORM_TYPE.MOVE_TO_LEFT
			gerador.dificuldade = estado
			gerador.rng = rng
			gerador.position = Vector2(0, 100)
			var historico: Array = []
			gerador.child_entered_tree.connect(
				func(no: Node) -> void:
					if no is Platform:
						historico.append({"cor": int(no.color), "gecko": int(Global.cor_gecko), "plataforma": no})
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
				var tem := false
				for j in range(maxi(0, i - k + 1), i + 1):
					if historico[j]["cor"] == historico[i]["gecko"]:
						tem = true
				if not tem:
					falhas.append(
						"%s semente %d: janela K=%d terminada na plataforma %d sem a cor do gecko (speed %.1f, fase %.2f)"
						% [caso[0], semente, k, i, absf(float(gerador.speed)), _fase_de(historico[i]["plataforma"])]
					)
	assert_gt(casos_com_mecanica, 0, "a curva de producao tem estagio com mecanica de movimento ou speed por linha")
	assert_gt(janelas, 0, "ha janelas de K para conferir")
	assert_true(falhas.is_empty(), "toda janela de K moveis consecutivas tem a cor do gecko vigente: %s" % str(falhas.slice(0, 3)))


# --- C293: borda do filtro x em [0, 180] na amplitude maxima -------------------------------------------------------


func test_c293_candidata_na_borda_do_filtro_com_amplitude_maxima_mantem_a_garantia() -> void:
	var casos_oscilantes := 0
	var na_borda := 0
	var falhas: Array = []
	for caso in _casos():
		var snap: DifficultySnapshot = caso[2]
		if not _oscila(snap.get_mecanicas()):
			continue
		casos_oscilantes += 1
		var amplitude: float = snap.get_amplitude_movimento()
		assert_gt(amplitude, 0.0, "%s: amplitude maxima do estagio lida do .tres" % caso[0])
		var k: int = snap.get_k()
		for semente in SEMENTES:
			var rng := _rng(semente)
			var cor: int = Enums.COR_INICIAL
			for linha in LINHAS_SIMULADAS:
				var para_esquerda: bool = rng.randi() % 2 == 0
				var spawn_x: float = LARGURA_JOGAVEL + MovingRowFill.SEMI_PLATAFORMA if para_esquerda else -MovingRowFill.SEMI_PLATAFORMA
				var historico: Array = []
				var entradas: Array = []
				var xs: Array = MovingRowFill.initial_xs(spawn_x, para_esquerda, LARGURA_JOGAVEL, snap.get_speed_moveis())
				# A linha anda ate o pouso: fase do espacamento sorteada, entao ha plataforma na borda do filtro
				var avanco: float = rng.randf() * MovingRowFill.espacamento(snap.get_speed_moveis())
				for x_nascimento in xs:
					var x: float = float(x_nascimento) + (-avanco if para_esquerda else avanco)
					var anteriores: Array = []
					for h in historico:
						anteriores.append(h)
					var cor_plataforma: int = ReachableColors.cor_plataforma_movel(cor, anteriores, rng, k)
					historico.append(cor_plataforma)
					# Amplitude maxima: o deslocamento extra da oscilante chega a +-A; sinal sorteado por plataforma
					var desloc: float = amplitude if rng.randi() % 2 == 0 else -amplitude
					var x_efetivo: float = float(x) + desloc
					if (float(x) >= 0.0 and float(x) <= LARGURA_JOGAVEL) != (x_efetivo >= 0.0 and x_efetivo <= LARGURA_JOGAVEL):
						na_borda += 1
					entradas.append({"y": 0.0 - InitialRows.ESPACAMENTO, "x": x_efetivo, "cor": cor_plataforma})
				historico.append(ReachableColors.cor_plataforma_movel(cor, historico.duplicate(), rng, k))
				for i in historico.size():
					# Todas nasceram com o mesmo gecko vigente (cor): toda janela de K tem a cor dele
					if not historico.slice(maxi(0, i - k + 1), i + 1).has(cor):
						falhas.append("%s semente %d linha %d: janela K=%d na plataforma %d sem a cor do gecko" % [caso[0], semente, linha, k, i])
				var candidatas: Array = ReachableColors.coletar_cores_linha_acima(entradas, 0.0, LARGURA_JOGAVEL)
				var visiveis: Array = []
				for e in entradas:
					if e["x"] >= 0.0 and e["x"] <= LARGURA_JOGAVEL:
						visiveis.append(e["cor"])
				if candidatas.is_empty():
					falhas.append("%s semente %d linha %d: nenhuma candidata no filtro com amplitude %.1f" % [caso[0], semente, linha, amplitude])
					continue
				var antes: int = cor
				cor = ReachableColors.escolher_cor_gecko(candidatas, rng)
				var a: Array = candidatas.duplicate()
				var b: Array = visiveis.duplicate()
				a.sort()
				b.sort()
				if a != b or not visiveis.has(cor):
					falhas.append(
						"%s semente %d linha %d K=%d: candidatas %s != visiveis %s (cor %d -> %d)" % [caso[0], semente, linha, k, str(a), str(b), antes, cor]
					)
	assert_gt(casos_oscilantes, 0, "a curva de producao tem caso com oscilacao")
	assert_gt(na_borda, 0, "a simulacao exercita plataforma que entra/sai do filtro por +-amplitude")
	assert_eq(falhas, [], "com a amplitude maxima aplicada ao x, ha candidata e ela bate com a recontagem independente")


# --- C294: alcance fisico no pior caso de speed por linha ----------------------------------------------------------


func _player_const(nome: String) -> float:
	return float((load(PLAYER_SCRIPT) as GDScript).get_script_constant_map()[nome])


func _taxa() -> float:
	return float(ProjectSettings.get_setting("physics/common/physics_ticks_per_second"))


# Tempo de voo (s): frames ate o gecko, na descida, alcancar o nivel da linha-alvo (ESPACAMENTO acima, descendo `scroll`).
func _tempo_de_voo(scroll: float) -> float:
	var vy := _player_const("JUMP_POWER")
	var g := _player_const("GRAVITY")
	var taxa := _taxa()
	var y := 0.0
	var apice_passou := false
	for n in range(1, 2000):
		vy += g
		y += -vy / taxa
		if vy >= 0.0:
			apice_passou = true
		var alvo := InitialRows.ESPACAMENTO - scroll * float(n) / taxa
		if apice_passou and y <= alvo:
			return float(n) / taxa
	return -1.0


func _largura_efetiva(snap: DifficultySnapshot) -> float:
	if snap.get_mecanicas().has(PlatformModifiers.PLATAFORMAS_MENORES):
		return snap.get_largura_plataforma()
	return MovingRowFill.SEMI_PLATAFORMA * 2.0


func test_c294_alcance_fisico_com_a_speed_do_pior_caso_da_variacao_por_linha() -> void:
	var casos_com_variacao := 0
	var falhas: Array = []
	for caso in _casos():
		var snap: DifficultySnapshot = caso[2]
		if not snap.get_mecanicas().has(PlatformModifiers.SPEED_POR_LINHA):
			continue
		casos_com_variacao += 1
		var variacao: float = snap.get_variacao_speed_linha()
		var pior_speed: float = snap.get_speed_moveis() * (1.0 + variacao)
		var largura: float = _largura_efetiva(snap)
		var esp: float = MovingRowFill.espacamento(pior_speed)
		var t_voo: float = _tempo_de_voo(snap.get_scroll())
		assert_gt(t_voo, 0.0, "%s: o gecko alcanca a linha-alvo na descida" % caso[0])
		var folga_a: float = t_voo - (esp - largura) / pior_speed
		var folga_b: float = _player_const("SPEED") * t_voo + largura - esp
		if folga_a < 0.0 or folga_b < 0.0:
			falhas.append(
				"%s: speed pior caso %.1f (base %.1f x (1+%.2f)), largura %.1f, espacamento %.1f, folga do tempo sem plataforma %.3f s, folga de cobertura %.1f px; decisao do dono: reduzir variacao_speed_linha ou so para baixo (Q7)"
				% [caso[0], pior_speed, snap.get_speed_moveis(), variacao, largura, esp, folga_a, folga_b]
			)
	assert_gt(casos_com_variacao, 0, "a curva de producao tem caso com speed_por_linha")
	assert_true(falhas.is_empty(), "a speed do pior caso (base x (1+variacao)) segue alcancavel: %s" % str(falhas.slice(0, 2)))
