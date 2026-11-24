extends GutTest

# f524 T6: frases do ADR para Puro e Contra o tempo (C701-C706). Stage real com a regra do modo vindo de Global; o
# nivel (ScrollLevel) recebe uma dificuldade com raridade de power-up fixa para provar o gancho, e as linhas sao
# criadas e lidas sem passar frame (deterministico). Recordes isolados pelo pre-run do GUT; o cenario do recorde
# isolado (C704) usa stores num diretorio de user:// proprio, nunca o user://best_score.cfg real.
const STAGE_SCENE := "res://scenes/Stage.tscn"
const PLATFORM_SCENE := "res://scenes/Platform.tscn"
const VISIVEL := Vector2(180.0, 320.0)
const SAFE := Rect2(0.0, 0.0, 180.0, 320.0)
const SEMENTE := 20260
const LINHAS_CRIADAS := 6
const DELTA := 0.25
const LIMITE_CURTO := 2.0
const TICKS_ATE_O_LIMITE := 8
const X_QUEDA := 20.0
const Y_QUEDA := 360.0
const DIR_RECORDES := "user://t6_modos"

var _stage: Node = null
var _p: Node = null
var _modo_original: StringName = GameModes.ID_CLASSICO
var _tempo_original: float = 0.0
var _plataformas_original: Array = []
var _cor_original: Enums.COLOR = Enums.COLOR.AZUL
var _tutorial_original: bool = false
var _sem_derrota_original: bool = false


func before_each() -> void:
	_modo_original = Global.get_modo_jogo()
	_tempo_original = Global.tempo_inicial_s
	_plataformas_original = Global.platforms
	_cor_original = Global.cor_gecko
	_tutorial_original = Global.tutorial_visto_espelho
	_sem_derrota_original = Global.sem_derrota
	Global.tutorial_visto_espelho = true
	Global.sem_derrota = false
	Global.platforms = []
	Global.iniciado = false
	Global.cor_gecko = Enums.COLOR.AZUL
	PowerUps.restaurar_padrao()


func after_each() -> void:
	if is_instance_valid(_p):
		_p.end = true
	get_tree().paused = false
	Global.platforms = _plataformas_original
	Global.iniciado = false
	Global.cor_gecko = _cor_original
	Global.tempo_inicial_s = _tempo_original
	Global.tutorial_visto_espelho = _tutorial_original
	Global.sem_derrota = _sem_derrota_original
	Global.set_modo_jogo(_modo_original, false)
	PowerUps.restaurar_padrao()
	_limpar_recordes()
	_stage = null
	_p = null


func _limpar_recordes() -> void:
	var dir := DirAccess.open(DIR_RECORDES)
	if dir == null:
		return
	for arquivo in dir.get_files():
		dir.remove(arquivo)
	DirAccess.remove_absolute(DIR_RECORDES)


func _estado(raridade: float) -> DifficultyState:
	var estagio := DifficultyStage.new()
	estagio.progresso_inicio = 0.0
	estagio.speed_moveis = 80.0
	estagio.proporcao_estaticas = 0.5
	estagio.raridade_power_up = raridade
	estagio.pesos_power_ups = {&"camaleao": 1.0, &"desacelera": 1.0}
	var curva := DifficultyCurve.new()
	curva.estagios = [estagio]
	return DifficultyState.new(curva)


# Stage real no modo `modo_id`, com a seed fixa e (com `com_linhas`) 6 linhas de fluxo criadas pela dificuldade de
# raridade fixa; espera 3 frames de fisica (iguais nos dois modos comparados).
func _nivel_do_modo(modo_id: StringName, raridade: float, com_linhas: bool = true) -> Node:
	Global.iniciado = false
	Global.set_modo_jogo(modo_id, false)
	Global.platforms = []
	Global.cor_gecko = Enums.COLOR.AZUL
	var stage: Node = load(STAGE_SCENE).instantiate()
	stage.semente_partida = SEMENTE
	add_child_autofree(stage)
	stage.apply_layout(VISIVEL, SAFE)
	var nivel: ScrollLevel = stage.get_node("ScrollLevel") as ScrollLevel
	nivel.dificuldade = _estado(raridade)
	if com_linhas:
		for k in LINHAS_CRIADAS:
			nivel.create_new_running_platform(InitialRows.Y_TOPO - InitialRows.ESPACAMENTO * (k + 1))
	_stage = stage
	_p = stage.get_node("Node2D/Player")
	_p.set_physics_process(false)
	# A criacao das linhas de fluxo termina em frames de fisica (o gerador nasce adiado)
	await wait_physics_frames(3)
	return stage


func _liberar(stage: Node) -> void:
	_p.end = true
	stage.queue_free()
	await wait_physics_frames(2)
	Global.platforms = []
	Global.iniciado = false


func _plataformas(linha: Node) -> Array:
	var filhas: Array = []
	for filha in linha.get_children():
		if filha is Platform:
			filhas.append(filha)
	return filhas


func _tem_icone(plataforma) -> bool:
	return plataforma.tipo_power_up != &"" and is_instance_valid(plataforma.icone_power_up)


func _contar_icones(stage: Node) -> int:
	var nivel: ScrollLevel = stage.get_node("ScrollLevel") as ScrollLevel
	var total: int = 0
	for linha in nivel.running_platforms.get_children():
		for p in _plataformas(linha):
			if _tem_icone(p):
				total += 1
	return total


func _contar_plataformas(stage: Node) -> int:
	var nivel: ScrollLevel = stage.get_node("ScrollLevel") as ScrollLevel
	var total: int = 0
	for linha in nivel.running_platforms.get_children():
		total += _plataformas(linha).size()
	return total


func _layout(stage: Node) -> Array[String]:
	var nivel: ScrollLevel = stage.get_node("ScrollLevel") as ScrollLevel
	var saida: Array[String] = []
	for linha in nivel.running_platforms.get_children():
		var partes := PackedStringArray()
		for p in _plataformas(linha):
			# x so das linhas estaticas: o das moveis anda com os frames de fisica
			var x: float = p.position.x if linha.platform_type == Enums.PLATFORM_TYPE.STATIC else 0.0
			partes.append("%.1f:%d" % [x, p.color])
		saida.append("%d|%s" % [int(linha.platform_type), ",".join(partes)])
	return saida


func _divergentes(atual: Array[String], esperado: Array[String]) -> Array[int]:
	var indices: Array[int] = []
	for i in maxi(atual.size(), esperado.size()):
		if i >= atual.size() or i >= esperado.size() or atual[i] != esperado[i]:
			indices.append(i)
	return indices


func _pontos_apos(stage: Node, pousos: int) -> int:
	for i in pousos:
		stage.add_point()
	return stage.points


# --- Stage do Tempo com ticks manuais (sem ScrollLevel), como em test_stage_tempo.gd ---
func _stage_tempo_manual() -> Node:
	Global.tempo_inicial_s = LIMITE_CURTO
	Global.iniciado = false
	Global.set_modo_jogo(GameModes.ID_TEMPO, false)
	Global.keeper_do_modo(GameModes.ID_TEMPO).load_best(0)
	_stage = load(STAGE_SCENE).instantiate()
	var scroll: Node = _stage.get_node("ScrollLevel")
	_stage.remove_child(scroll)
	scroll.free()
	add_child_autofree(_stage)
	await wait_frames(2)
	_stage.apply_layout(VISIVEL, SAFE)
	Global.platforms = []
	_p = _stage.get_node("Node2D/Player")
	_p.set_physics_process(false)
	_p.jumping = false
	_stage.set_physics_process(false)
	return _stage


func _tick(n: int, delta: float = DELTA) -> void:
	for i in n:
		_stage._physics_process(delta)


func _perdeu() -> bool:
	return _stage.ultimo_estado.get("state", "") == GameState.STATE_LOST


func _cair() -> void:
	_p.global_position = Vector2(X_QUEDA, Y_QUEDA)
	_stage._on_CheckPlayer_body_exited(_p)


func test_c701_puro_com_raridade_1_nenhuma_plataforma_com_icone_e_coleta_forcada_ignorada() -> void:
	var stage := await _nivel_do_modo(GameModes.ID_PURO, 1.0)
	assert_gt(_contar_plataformas(stage), 10, "fixture: a partida gerou plataformas")
	assert_false(stage.power_ups_habilitados, "Puro: a Stage leu false da regra")
	assert_eq((stage.get_node("ScrollLevel") as ScrollLevel).power_ups_habilitados, false, "false chegou ao ScrollLevel")
	assert_eq(_contar_icones(stage), 0, "Puro com raridade 1: nenhuma plataforma nasce com icone")
	stage._coletar_power_up(&"camaleao")
	assert_null(stage.power_up_estado.ativo(), "coleta forcada ignorada: power-up nao ativa no Puro")
	stage._coletar_power_up(&"segunda_chance")
	assert_eq(stage.power_up_estado.carga(), 0, "coleta forcada de carga tambem ignorada no Puro")


func test_c702_classico_com_raridade_1_gera_icones_e_o_puro_na_mesma_seed_nao() -> void:
	var classico := await _nivel_do_modo(GameModes.ID_CLASSICO, 1.0)
	var no_classico: int = _contar_icones(classico)
	var total_classico: int = _contar_plataformas(classico)
	assert_gt(no_classico, 10, "Classico, raridade 1: icones nascem (gancho e do modo, nao global)")
	classico.set_physics_process(false)
	classico._coletar_power_up(&"camaleao")
	assert_not_null(classico.power_up_estado.ativo(), "Classico: a coleta ativa o power-up")
	await _liberar(classico)
	var puro := await _nivel_do_modo(GameModes.ID_PURO, 1.0)
	assert_eq(_contar_plataformas(puro), total_classico, "mesma seed: mesma quantidade de plataformas nos dois modos")
	assert_eq(_contar_icones(puro), 0, "Puro, mesma seed e raridade 1: nenhum icone (nao herda o gancho do Classico)")


func test_c715_zen_com_raridade_1_nenhum_icone_e_o_classico_na_mesma_seed_gera() -> void:
	var zen := await _nivel_do_modo(GameModes.ID_ZEN, 1.0)
	assert_gt(_contar_plataformas(zen), 10, "fixture: a partida do Zen gerou plataformas")
	assert_false(zen.power_ups_habilitados, "Zen: a Stage leu false da regra")
	assert_eq((zen.get_node("ScrollLevel") as ScrollLevel).power_ups_habilitados, false, "false chegou ao ScrollLevel")
	assert_eq(_contar_icones(zen), 0, "Zen com raridade 1: nenhuma plataforma elegivel nasce com icone")
	await _liberar(zen)
	var classico := await _nivel_do_modo(GameModes.ID_CLASSICO, 1.0)
	assert_gt(_contar_icones(classico), 0, "mesmo setup no Classico gera ao menos um icone (o teste nao e vacuo)")


func test_c703_puro_e_classico_mesma_seed_raridade_0_layout_e_pontuacao_identicos() -> void:
	var classico := await _nivel_do_modo(GameModes.ID_CLASSICO, 0.0)
	var layout_classico: Array[String] = _layout(classico)
	var pontos_classico: int = _pontos_apos(classico, 5)
	await _liberar(classico)
	var puro := await _nivel_do_modo(GameModes.ID_PURO, 0.0)
	var layout_puro: Array[String] = _layout(puro)
	var pontos_puro: int = _pontos_apos(puro, 5)
	assert_gt(layout_puro.size(), 8, "fixture: linhas iniciais e de fluxo geradas")
	assert_eq(layout_puro.size(), layout_classico.size(), "mesma quantidade de linhas")
	assert_eq(
		_divergentes(layout_puro, layout_classico).size(),
		0,
		"layout do Puro divergiu do Classico nas linhas %s" % [_divergentes(layout_puro, layout_classico)]
	)
	assert_eq(pontos_classico, 4, "Classico: 5 pousos = 4 pontos (o 1o nao conta)")
	assert_eq(pontos_puro, pontos_classico, "Puro pontua igual ao Classico para a mesma sequencia de pousos")


func test_c704_recorde_isolado_entre_os_tres_modos_reais() -> void:
	DirAccess.make_dir_recursive_absolute(DIR_RECORDES)
	var caminho := DIR_RECORDES + "/best_score.cfg"
	BestScoreStore.new(caminho).save_best(7)
	var classico := BestScoreStore.para_modo(GameModes.classico().id, caminho)
	var puro := BestScoreStore.para_modo(GameModes.puro().id, caminho)
	var tempo := BestScoreStore.para_modo(GameModes.tempo().id, caminho)
	assert_eq(classico.load_best(), 7, "Best do Classico = best_score.cfg")
	assert_eq(puro.load_best(), 0, "Best do Puro = 0")
	assert_eq(tempo.load_best(), 0, "Best do Tempo = 0")
	puro.save_best(11)
	assert_eq(BestScoreStore.para_modo(GameModes.puro().id, caminho).load_best(), 11, "Puro guarda o proprio recorde")
	assert_eq(BestScoreStore.para_modo(GameModes.classico().id, caminho).load_best(), 7, "gravar no Puro nao altera o Classico")
	assert_eq(BestScoreStore.para_modo(GameModes.tempo().id, caminho).load_best(), 0, "gravar no Puro nao altera o Tempo")
	BestScoreStore.para_modo(GameModes.tempo().id, caminho).save_best(3)
	assert_eq(BestScoreStore.para_modo(GameModes.classico().id, caminho).load_best(), 7, "gravar no Tempo nao altera o Classico")
	assert_eq(BestScoreStore.para_modo(GameModes.puro().id, caminho).load_best(), 11, "gravar no Tempo nao altera o Puro")
	BestScoreStore.new(caminho).save_best(9)
	assert_eq(BestScoreStore.para_modo(GameModes.puro().id, caminho).load_best(), 11, "gravar no Classico nao altera o Puro")
	assert_eq(BestScoreStore.para_modo(GameModes.tempo().id, caminho).load_best(), 3, "gravar no Classico nao altera o Tempo")


func test_c705_tempo_termina_no_que_vier_antes_e_grava_o_recorde_uma_unica_vez() -> void:
	# Caso A: o relogio zera antes de qualquer queda
	await _stage_tempo_manual()
	var keeper := Global.keeper_do_modo(GameModes.ID_TEMPO)
	var gravacoes: Array[int] = [0]
	var contar := func(_valor: int) -> void: gravacoes[0] += 1
	keeper.best_changed.connect(contar)
	_stage.points = 5
	Global.iniciado = true
	_tick(TICKS_ATE_O_LIMITE)
	assert_true(_perdeu(), "caso A: o relogio zerou antes da queda: lost por tempo")
	assert_eq(_stage.tempo_partida, LIMITE_CURTO, "caso A: terminou no limite do relogio")
	_cair()
	_tick(4)
	assert_eq(keeper.best, 5, "caso A: recorde do Tempo gravado")
	assert_eq(gravacoes[0], 1, "caso A: recorde gravado uma unica vez")
	keeper.best_changed.disconnect(contar)
	_p.end = true
	Global.iniciado = false
	# Caso B: a queda vem antes do relogio
	await _stage_tempo_manual()
	keeper = Global.keeper_do_modo(GameModes.ID_TEMPO)
	gravacoes[0] = 0
	keeper.best_changed.connect(contar)
	_stage.points = 5
	Global.iniciado = true
	_tick(4)
	assert_false(_perdeu(), "caso B: antes da queda a partida segue")
	_cair()
	assert_true(_perdeu(), "caso B: a queda antes do relogio perde")
	assert_eq(_stage.tempo_partida, 4 * DELTA, "caso B: terminou por queda, com o relogio ainda abaixo do limite")
	_tick(TICKS_ATE_O_LIMITE)
	assert_eq(_stage.tempo_partida, 4 * DELTA, "caso B: o relogio parou na derrota")
	assert_eq(keeper.best, 5, "caso B: recorde do Tempo gravado")
	assert_eq(gravacoes[0], 1, "caso B: recorde gravado uma unica vez")
	keeper.best_changed.disconnect(contar)


func test_c706_tempo_com_power_ups_gera_icones_e_a_coleta_ativa_sem_afetar_o_relogio() -> void:
	Global.tempo_inicial_s = 1000.0
	var stage := await _nivel_do_modo(GameModes.ID_TEMPO, 1.0)
	var nivel: ScrollLevel = stage.get_node("ScrollLevel") as ScrollLevel
	assert_true(stage.power_ups_habilitados, "Tempo: a Stage leu true da regra")
	assert_true(nivel.power_ups_habilitados, "true chegou ao ScrollLevel")
	assert_gt(_contar_icones(stage), 10, "Tempo com raridade 1: icones nascem")
	stage.set_physics_process(false)
	nivel.set_physics_process(false)
	_p.set_physics_process(false)
	_stage = stage
	Global.iniciado = true
	stage._coletar_power_up(&"desacelera")
	assert_not_null(stage.power_up_estado.ativo(), "a coleta ativa o power-up no Tempo")
	_tick(TICKS_ATE_O_LIMITE)
	assert_not_null(stage.power_up_estado.ativo(), "Desacelera segue ativo ao fim dos ticks")
	assert_eq(stage.tempo_partida, TICKS_ATE_O_LIMITE * DELTA, "Desacelera nao afeta o relogio do Tempo")
