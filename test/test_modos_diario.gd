extends GutTest

# f528 T4: DiarioRule, hooks novos de GameModeRule e o Diario no seletor. Frases do ADR 0014 provadas com o
# mesmo padrao de test_modos_puro_tempo.gd: raridade 1.0 + seed fixa na Stage com a regra do Diario -> nenhuma
# plataforma elegivel nasce com icone (C763); defaults neutros dos hooks novos nos 4 modos existentes (C764);
# derrota simulada nao escreve em best_score_* (C765). Indicador do seletor e largura do rotulo do botao (C762).
# Recordes isolados pelo pre-run do GUT; nada toca user:// real.
const STAGE_SCENE := "res://scenes/Stage.tscn"
const VISIVEL := Vector2(360.0, 640.0)
const SAFE := Rect2(0.0, 0.0, 360.0, 640.0)
const SEMENTE := 20261
const LINHAS_CRIADAS := 6
const X_QUEDA := 40.0
const Y_QUEDA := 720.0

var _stage: Node = null
var _p: Node = null
var _modo_original: StringName = GameModes.ID_CLASSICO
var _plataformas_original: Array = []
var _cor_original: Enums.COLOR = Enums.COLOR.AZUL
var _tutorial_original: bool = false
var _sem_derrota_original: bool = false


func before_each() -> void:
	_modo_original = Global.get_modo_jogo()
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
	Global.tutorial_visto_espelho = _tutorial_original
	Global.sem_derrota = _sem_derrota_original
	Global.set_modo_jogo(_modo_original, false)
	PowerUps.restaurar_padrao()
	_stage = null
	_p = null


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


# Stage real no modo pedido, com a seed fixa e 6 linhas de fluxo criadas pela dificuldade de raridade fixa
# (mesmo arranjo de _nivel_do_modo de test_modos_puro_tempo.gd; espera 3 frames de fisica).
func _nivel_do_modo(modo_id: StringName, raridade: float) -> Node:
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
	for k in LINHAS_CRIADAS:
		nivel.create_new_running_platform(InitialRows.Y_TOPO - InitialRows.ESPACAMENTO * (k + 1))
	_stage = stage
	_p = stage.get_node("Node2D/Player")
	_p.set_physics_process(false)
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


func _cair() -> void:
	# Mesma limpeza de _stage_tempo_manual (test_modos_puro_tempo.gd): sem pulo em curso a linha de derrota
	# encerra a partida; com `jumping` inicial do Player a guarda de _on_CheckPlayer_body_exited retorna antes.
	_p.jumping = false
	_p.global_position = Vector2(X_QUEDA, Y_QUEDA)
	_stage._on_CheckPlayer_body_exited(_p)


# C762: indicador do seletor com os modos reais — 5 marcas em release (6 com o teste), a atual (Diario) 16x8 —
# e o rotulo "Modo: Diario" cabe nos 224 px do botao do menu (mesma medida de largura dos rotulos existentes).
func test_c762_indicador_5_marcas_e_rotulo_do_botao_diario_cabe_em_224px() -> void:
	var tela := ModosScreen.new()
	add_child_autofree(tela)
	for incluir_teste: bool in [false, true]:
		var modos := GameModes.lista(incluir_teste)
		var indice_diario: int = modos.find(GameModes.diario())
		assert_eq(indice_diario, 4, "C762: o Diario e o 5o modo (teste=%s)" % incluir_teste)
		tela.aplicar_layout(VISIVEL, SAFE)
		assert_true(tela.abrir(GameModes.diario(), modos), "C762: abrir no Diario devolve true (teste=%s)" % incluir_teste)
		var marcas := tela.rect_marcas()
		assert_eq(marcas.size(), 6 if incluir_teste else 5, "C762: marcas = modos da lista (teste=%s)" % incluir_teste)
		for i in marcas.size():
			var esperado := Vector2(16.0, 8.0) if i == indice_diario else Vector2(8.0, 8.0)
			assert_eq(marcas[i].size, esperado, "C762: marca %d (teste=%s)" % [i, incluir_teste])
		tela.fechar()
	var botao := ModoBotao.new()
	add_child_autofree(botao)
	botao.definir_modo(GameModes.diario())
	assert_eq(botao.texto(), "Modo: Diario", "C762: rotulo do botao com o Diario")
	var largura_diario: float = ModoBotao.FONTE.get_string_size(
		botao.texto(), HORIZONTAL_ALIGNMENT_LEFT, -1, ModoBotao.TAMANHO_TEXTO
	).x
	assert_gt(largura_diario, 0.0, "C762: a fonte mediu o rotulo do Diario")
	assert_true(
		largura_diario <= ModoBotao.LARGURA,
		"C762: 'Modo: Diario' (%.1f px) cabe nos %.1f px do botao" % [largura_diario, ModoBotao.LARGURA]
	)
	for modo in GameModes.lista():
		var largura: float = ModoBotao.FONTE.get_string_size(
			"Modo: " + modo.rotulo, HORIZONTAL_ALIGNMENT_LEFT, -1, ModoBotao.TAMANHO_TEXTO
		).x
		assert_true(
			largura <= ModoBotao.LARGURA,
			"C762: 'Modo: %s' (%.1f px) cabe nos 224 px (mesmo teste de largura dos rotulos existentes)" % [modo.rotulo, largura]
		)


# C763: frase do ADR 0014 "Puro, Zen e Desafio diario: nenhum icone nasce com qualquer raridade" — provada
# com raridade 1.0 e seed fixa na Stage com a regra do Diario; o Classico no mesmo arranjo gera icones.
func test_c763_diario_com_raridade_1_nenhuma_plataforma_com_icone() -> void:
	var diario := await _nivel_do_modo(GameModes.ID_DIARIO, 1.0)
	assert_gt(_contar_plataformas(diario), 10, "fixture: a partida do Diario gerou plataformas")
	assert_false(GameModes.diario().regra.power_ups_habilitados(), "DiarioRule.power_ups_habilitados() == false")
	assert_false(diario.power_ups_habilitados, "Diario: a Stage leu false da regra")
	assert_eq((diario.get_node("ScrollLevel") as ScrollLevel).power_ups_habilitados, false, "false chegou ao ScrollLevel")
	assert_eq(_contar_icones(diario), 0, "C763: raridade 1.0 no Diario: nenhuma plataforma elegivel nasce com icone")
	await _liberar(diario)
	var classico := await _nivel_do_modo(GameModes.ID_CLASSICO, 1.0)
	assert_gt(_contar_icones(classico), 0, "mesmo arranjo no Classico gera ao menos um icone (o teste nao e vacuo)")


# C764: hooks novos com default neutro — nenhum modo existente muda (pode_iniciar true, usa_seed_do_dia
# false); so o Diario difere (usa a seed do dia; o pode_iniciar consultando a tentativa e ligado em T6).
func test_c764_hooks_novos_defaults_neutros_so_o_diario_usa_seed_do_dia() -> void:
	var ctx := {PartidaCtx.PONTOS: 3, PartidaCtx.INICIADO: true, PartidaCtx.TEMPO: 1.0}
	for id in [GameModes.ID_CLASSICO, GameModes.ID_PURO, GameModes.ID_TEMPO, GameModes.ID_ZEN]:
		var regra: GameModeRule = GameModes.de_id(id).regra
		assert_true(regra.pode_iniciar(ctx), "C764: %s pode iniciar (default neutro)" % id)
		assert_false(regra.usa_seed_do_dia(), "C764: %s nao usa a seed do dia (default neutro)" % id)
	assert_true(GameModes.diario().regra.usa_seed_do_dia(), "C764: so o Diario usa a seed do dia")


# C765: DiarioRule.grava_recorde == false — derrota simulada nao escreve em best_score_*: o best do Diario
# segue 0, nenhum user://best_score_diario.cfg nasce e o recorde pre-gravado do Classico fica intacto.
func test_c765_diario_derrota_nao_grava_recorde_nos_best_score() -> void:
	assert_false(
		GameModes.diario().regra.grava_recorde(),
		"DiarioRule.grava_recorde() == false (o resultado do dia vive no DesafioDiarioStore, T6)"
	)
	Global.set_modo_jogo(GameModes.ID_CLASSICO, false)
	Global.set_score(5)
	assert_eq(Global.get_best_score(), 5, "fixture: recorde do Classico pre-gravado")
	var diario := await _nivel_do_modo(GameModes.ID_DIARIO, 1.0)
	diario.points = 7
	_cair()
	assert_eq(diario.ultimo_estado.get("state", ""), GameState.STATE_LOST, "fixture: a queda encerrou a partida")
	assert_eq(Global.get_best_score(), 0, "C765: o best do Diario segue 0 apos a derrota")
	assert_eq(Global.keeper_do_modo(GameModes.ID_DIARIO).best, 0, "C765: o keeper do Diario nao recebeu os pontos")
	assert_eq(Global.keeper_do_modo(GameModes.ID_CLASSICO).best, 5, "C765: o recorde do Classico ficou intacto")
	assert_false(FileAccess.file_exists("user://best_score_diario.cfg"), "C765: nenhum user://best_score_diario.cfg nasce")
	assert_null(Global.store_do_modo(GameModes.ID_DIARIO), "C765: o Diario nao ganha store de best_score (isolado pelo pre-run)")
