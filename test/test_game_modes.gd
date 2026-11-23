extends GutTest

# Registro de modos (GameModes): Classico sempre presente, primeiro e padrao; Puro e Tempo logo depois; resolucao por
# id (C567/C568/C674), instancias reusadas (C675), ciclo do carrossel (C569/C676) e regras Puro/Tempo (C677/C678).
# f528 T4: o Diario entra depois do Zen (C757-C760, C766); lista e ciclo 4-5 viram 5-6. A flag de debug e
# ligada/restaurada em before_each/after_each.

const EPSILON: float = 0.001

var _flag_antes: bool = false
var _tempo_forcado_antes: float = 0.0


func before_each() -> void:
	_flag_antes = Global.modos_teste_habilitado
	_tempo_forcado_antes = Global.tempo_inicial_s
	Global.modos_teste_habilitado = false
	Global.tempo_inicial_s = 0.0


func after_each() -> void:
	Global.modos_teste_habilitado = _flag_antes
	Global.tempo_inicial_s = _tempo_forcado_antes


func _ids(modos: Array[GameMode]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for modo in modos:
		ids.append(modo.id)
	return ids


# Registro: Classico primeiro e padrao; Puro e Tempo em seguida; teste so com incluir_teste, por ultimo.
func test_registro_tem_classico_primeiro_e_padrao() -> void:
	var modos := GameModes.lista()
	assert_eq(
		_ids(modos),
		[&"classico", &"puro", &"tempo", &"zen", &"diario"] as Array[StringName],
		"lista sem teste: Classico, Puro, Tempo, Zen, Diario"
	)
	assert_eq(GameModes.padrao().id, &"classico", "padrao() devolve o Classico")
	var com_teste := GameModes.lista(true)
	assert_eq(
		_ids(com_teste),
		[&"classico", &"puro", &"tempo", &"zen", &"diario", &"teste"] as Array[StringName],
		"incluir_teste acrescenta o modo de teste por ultimo"
	)


func test_c710_lista_tem_5_modos_em_release_e_6_com_teste_por_ultimo() -> void:
	var release := GameModes.lista()
	assert_eq(release.size(), 5, "C710: lista() tem 5 modos")
	assert_eq(
		_ids(release),
		[&"classico", &"puro", &"tempo", &"zen", &"diario"] as Array[StringName],
		"C710: ordem classico, puro, tempo, zen, diario"
	)
	var com_teste := GameModes.lista(true)
	assert_eq(com_teste.size(), 6, "C710: lista(true) tem 6 modos")
	assert_eq(com_teste[5].id, &"teste", "C710: teste por ultimo")
	assert_eq(com_teste[4].id, GameModes.ID_DIARIO, "C710: Diario logo antes do teste")
	assert_eq(com_teste[3].id, GameModes.ID_ZEN, "C710: Zen logo antes do Diario")


# f528 T4 (C757): lista() em release = Classico, Puro, Tempo, Zen, Diario (5, ordem exata).
func test_c757_lista_release_tem_5_modos_com_diario_por_ultimo() -> void:
	var modos := GameModes.lista()
	assert_eq(modos.size(), 5, "C757: lista() tem 5 modos")
	assert_eq(
		_ids(modos),
		[&"classico", &"puro", &"tempo", &"zen", &"diario"] as Array[StringName],
		"C757: ordem exata classico, puro, tempo, zen, diario"
	)
	assert_eq(modos[4].id, GameModes.ID_DIARIO, "C757: o Diario e o 5o (ultimo em release)")


# f528 T4 (C758): lista(true) = 6 modos, o teste por ultimo (depois do Diario).
func test_c758_lista_com_teste_tem_6_modos_e_teste_por_ultimo() -> void:
	var com_teste := GameModes.lista(true)
	assert_eq(com_teste.size(), 6, "C758: lista(true) tem 6 modos")
	assert_eq(
		_ids(com_teste),
		[&"classico", &"puro", &"tempo", &"zen", &"diario", &"teste"] as Array[StringName],
		"C758: ordem exata com o Diario antes do teste"
	)
	assert_eq(com_teste[5].id, &"teste", "C758: teste por ultimo")
	assert_eq(com_teste[4].id, GameModes.ID_DIARIO, "C758: Diario logo antes do teste")


func test_c711_de_id_reconhece_zen_e_nunca_devolve_zen_para_id_invalido() -> void:
	assert_eq(GameModes.de_id("zen").id, &"zen", "C711: de_id(String zen) devolve o Zen")
	assert_eq(GameModes.de_id(&"zen").id, &"zen", "C711: de_id(StringName zen) devolve o Zen")
	assert_eq(GameModes.de_id("zen").rotulo, "Zen", "C711: rotulo curto do Zen")
	assert_same(GameModes.de_id(&"zen"), GameModes.zen(), "C711: de_id devolve a instancia reusada")
	assert_eq(GameModes.de_id("").id, &"classico", "C711: id vazio devolve o Classico")
	assert_eq(GameModes.de_id(null).id, &"classico", "C711: id nulo devolve o Classico")
	assert_eq(GameModes.de_id("ZEN").id, &"classico", "C711: caixa errada nao captura o Zen")
	assert_eq(GameModes.de_id("zen2").id, &"classico", "C711: id desconhecido devolve o Classico")


# f528 T4 (C759): de_id reconhece o Diario por String e StringName; desconhecido/vazio/nulo -> Classico.
func test_c759_de_id_reconhece_diario_e_invalidos_devolvem_classico() -> void:
	assert_eq(GameModes.de_id("diario").id, &"diario", "C759: de_id(String diario) devolve o Diario")
	assert_eq(GameModes.de_id(&"diario").id, &"diario", "C759: de_id(StringName diario) devolve o Diario")
	assert_eq(GameModes.de_id("diario").rotulo, "Diario", "C759: rotulo curto do Diario")
	assert_eq(GameModes.de_id("diario").nome, "Desafio diario", "C759: nome do Diario")
	assert_same(GameModes.de_id(&"diario"), GameModes.diario(), "C759: de_id devolve a instancia reusada")
	assert_eq(GameModes.de_id("").id, &"classico", "C759: id vazio devolve o Classico")
	assert_eq(GameModes.de_id(null).id, &"classico", "C759: id nulo devolve o Classico")
	assert_eq(GameModes.de_id("xyz").id, &"classico", "C759: id desconhecido devolve o Classico")
	assert_eq(GameModes.de_id("DIARIO").id, &"classico", "C759: caixa errada nao captura o Diario")


func test_zen_regra_reune_os_hooks_do_modo() -> void:
	var regra: GameModeRule = GameModes.zen().regra
	assert_false(regra.ao_cair({}), "Zen nao encerra ao cair")
	assert_true(regra.reposiciona_ao_cair(), "Zen reposiciona ao cair")
	assert_eq(regra.fator_scroll_forcado(), 0.0, "Zen para o scroll forcado")
	assert_false(regra.grava_recorde(), "Zen nao grava recorde")
	assert_false(regra.mostra_recorde(), "Zen nao mostra recorde")
	assert_false(regra.power_ups_habilitados(), "Zen sem power-ups")
	assert_false(regra.fim_por_regra({PartidaCtx.TEMPO: 1000.0}), "Zen nunca termina por regra")


func test_c567_de_id_nulo_devolve_classico_sem_erro_de_tipo() -> void:
	var modo: GameMode = GameModes.de_id(null)
	assert_eq(modo.id, &"classico", "C567: de_id(null) devolve o Classico sem erro de tipo")


func test_de_id_reconhece_puro_e_tempo() -> void:
	assert_eq(GameModes.de_id(&"puro").id, &"puro", "de_id(&puro) devolve o Puro")
	assert_eq(GameModes.de_id("tempo").id, &"tempo", "de_id(tempo) devolve o Tempo")
	assert_eq(GameModes.de_id("puro").rotulo, "Puro", "rotulo curto do Puro")
	assert_eq(GameModes.de_id("tempo").rotulo, "Tempo", "rotulo curto do Tempo")
	assert_eq(GameModes.de_id("tempo").nome, "Contra o tempo", "nome do Tempo")


func test_c674_de_id_invalido_ou_desconhecido_devolve_classico() -> void:
	assert_eq(GameModes.de_id("").id, &"classico", "C674: id vazio devolve o Classico")
	assert_eq(GameModes.de_id(&"").id, &"classico", "C674: StringName vazio devolve o Classico")
	assert_eq(GameModes.de_id("xyz").id, &"classico", "C674: id desconhecido devolve o Classico")
	assert_eq(GameModes.de_id(7).id, &"classico", "C674: id de tipo invalido (int) devolve o Classico")
	assert_eq(GameModes.de_id(true).id, &"classico", "C674: id de tipo invalido (bool) devolve o Classico")
	assert_eq(GameModes.de_id({"id": "puro"}).id, &"classico", "C674: id de tipo invalido (Dictionary) devolve o Classico")
	assert_eq(GameModes.de_id(null).id, &"classico", "C674: id nulo devolve o Classico")
	assert_eq(GameModes.de_id(&"classico").id, &"classico", "C674: id StringName classico devolve o Classico")
	assert_eq(GameModes.de_id("PURO").id, &"classico", "C674: id com caixa errada nao captura o Puro")


func test_c568_de_id_teste_respeita_a_flag_de_debug() -> void:
	assert_eq(GameModes.de_id("teste").id, &"classico", "C568: sem a flag, de_id teste devolve o Classico")
	Global.modos_teste_habilitado = true
	assert_eq(GameModes.de_id("teste").id, &"teste", "C568: com a flag, de_id teste devolve o modo de teste")


func test_c675_instancias_reusadas_de_modo_e_de_regra() -> void:
	var primeira := GameModes.lista(true)
	var segunda := GameModes.lista(true)
	for i in primeira.size():
		assert_same(primeira[i], segunda[i], "C675: lista devolve a mesma instancia de modo (%s)" % primeira[i].id)
		assert_same(primeira[i].regra, segunda[i].regra, "C675: mesma instancia de regra (%s)" % primeira[i].id)
	Global.modos_teste_habilitado = true
	assert_same(GameModes.de_id(&"tempo"), primeira[2], "C675: de_id(&tempo) e a instancia da lista")
	assert_same(GameModes.de_id(&"tempo").regra, primeira[2].regra, "C675: regra de de_id e a da lista")
	assert_same(GameModes.de_id("puro"), primeira[1], "C675: de_id(puro) e a instancia da lista")
	assert_same(GameModes.de_id("zen"), primeira[3], "C675: de_id(zen) e a instancia da lista")
	assert_same(GameModes.de_id("diario"), primeira[4], "C675: de_id(diario) e a instancia da lista")
	assert_same(GameModes.de_id("teste"), primeira[5], "C675: de_id(teste) e a instancia da lista")
	assert_same(GameModes.padrao(), primeira[0], "C675: padrao() e o Classico da lista")
	assert_same(GameModes.de_id("xyz"), primeira[0], "C675: fallback e a instancia do Classico")


# f528 T4 (C766): ID_DIARIO constante estavel &"diario"; diario() devolve a mesma instancia em 2 chamadas.
func test_c766_id_diario_constante_e_diario_reusa_instancia() -> void:
	assert_eq(GameModes.ID_DIARIO, &"diario", "C766: ID_DIARIO e a constante &\"diario\"")
	assert_eq(typeof(GameModes.ID_DIARIO), typeof(&"diario"), "C766: ID_DIARIO e StringName, nunca derivada de entrada")
	assert_same(GameModes.diario(), GameModes.diario(), "C766: diario() devolve a mesma instancia em 2 chamadas")
	assert_same(GameModes.diario().regra, GameModes.diario().regra, "C766: a regra do Diario tambem e reusada")
	assert_same(GameModes.de_id(GameModes.ID_DIARIO), GameModes.diario(), "C766: de_id(ID_DIARIO) devolve a instancia reusada")


func _campos(regra: GameModeRule) -> Dictionary:
	var campos: Dictionary = {}
	for prop in regra.get_property_list():
		if int(prop["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			campos[prop["name"]] = regra.get(prop["name"])
	return campos


func test_c675_regra_do_tempo_sem_estado_apos_partida_simulada() -> void:
	var regra: GameModeRule = GameModes.de_id(&"tempo").regra
	var antes := _campos(regra)
	Global.tempo_inicial_s = 5.0
	for t: float in [0.0, 1.0, 4.9, 5.0, 9.0]:
		regra.fim_por_regra({PartidaCtx.TEMPO: t, PartidaCtx.PONTOS: 3, PartidaCtx.INICIADO: true})
		regra.ao_cair({})
		regra.pontuar(1)
	assert_eq(_campos(regra), antes, "C675: nenhum campo da regra mudou depois da partida simulada")
	assert_eq(_campos(regra).size(), 0, "C675: a regra nao declara estado proprio")
	assert_false(
		regra.fim_por_regra({PartidaCtx.TEMPO: 0.0}), "C675: partida seguinte comeca sem o fim da anterior"
	)


func test_c569_ciclo_voltam_nas_listas_com_e_sem_teste() -> void:
	var quatro := GameModes.lista(true)
	assert_eq(GameModes.proximo(quatro[quatro.size() - 1], quatro).id, &"classico","C569: proximo do ultimo volta ao primeiro")
	assert_eq(GameModes.anterior(quatro[0], quatro).id, &"teste", "C569: anterior do primeiro vai ao ultimo")
	var um: Array[GameMode] = [GameModes.padrao()]
	assert_eq(GameModes.proximo(um[0], um).id, &"classico", "C569: lista de 1 cicla proximo para si mesmo, sem erro")
	assert_eq(GameModes.anterior(um[0], um).id, &"classico", "C569: lista de 1 cicla anterior para si mesmo, sem erro")


func test_c712_ciclo_fecha_com_diario_depois_do_zen() -> void:
	var release := GameModes.lista()
	assert_eq(GameModes.proximo(GameModes.zen(), release).id, &"diario", "C712: zen -> diario em release")
	assert_eq(GameModes.anterior(GameModes.diario(), release).id, &"zen", "C712: diario <- zen em release")
	assert_eq(GameModes.proximo(GameModes.diario(), release).id, &"classico", "C712: diario -> classico em release")
	assert_eq(GameModes.anterior(GameModes.classico(), release).id, &"diario", "C712: classico <- diario em release")
	assert_eq(GameModes.proximo(GameModes.tempo(), release).id, &"zen", "C712: tempo -> zen")
	var com_teste := GameModes.lista(true)
	assert_eq(GameModes.proximo(GameModes.zen(), com_teste).id, &"diario", "C712: zen -> diario com o teste")
	assert_eq(GameModes.proximo(GameModes.diario(), com_teste).id, &"teste", "C712: diario -> teste com o teste")
	assert_eq(GameModes.proximo(com_teste[5], com_teste).id, &"classico", "C712: teste -> classico com o teste")
	assert_eq(GameModes.anterior(com_teste[5], com_teste).id, &"diario", "C712: teste <- diario")
	assert_eq(GameModes.anterior(GameModes.classico(), com_teste).id, &"teste", "C712: classico <- teste")


func test_c676_ciclo_fecha_o_anel_de_5_e_de_6_entradas() -> void:
	for incluir_teste: bool in [false, true]:
		var modos := GameModes.lista(incluir_teste)
		assert_eq(modos.size(), 6 if incluir_teste else 5, "C676: tamanho da lista (teste=%s)" % incluir_teste)
		var atual := modos[0]
		for i in modos.size():
			assert_eq(atual.id, modos[i].id, "C676: proximo percorre na ordem (teste=%s, passo %d)" % [incluir_teste, i])
			atual = GameModes.proximo(atual, modos)
		assert_eq(atual.id, modos[0].id, "C676: proximo fecha o anel (teste=%s)" % incluir_teste)
		var volta := modos[modos.size() - 1]
		for i in modos.size():
			volta = GameModes.anterior(volta, modos)
		assert_eq(volta.id, modos[modos.size() - 1].id, "C676: anterior fecha o anel (teste=%s)" % incluir_teste)
		assert_eq(
			GameModes.anterior(modos[0], modos).id,
			modos[modos.size() - 1].id,
			"C676: anterior do primeiro e o ultimo (teste=%s)" % incluir_teste
		)


# f528 T4 (C760): o ciclo proximo/anterior fecha com 5 modos (release) e com 6 (com o teste).
func test_c760_ciclo_proximo_e_anterior_fecha_com_5_e_com_6_modos() -> void:
	for incluir_teste: bool in [false, true]:
		var modos := GameModes.lista(incluir_teste)
		assert_eq(modos.size(), 6 if incluir_teste else 5, "C760: tamanho da lista (teste=%s)" % incluir_teste)
		assert_eq(
			GameModes.proximo(GameModes.diario(), modos).id,
			(&"teste" if incluir_teste else &"classico"),
			"C760: proximo do Diario (teste=%s)" % incluir_teste
		)
		assert_eq(
			GameModes.anterior(GameModes.diario(), modos).id,
			&"zen",
			"C760: anterior do Diario e o Zen (teste=%s)" % incluir_teste
		)
		var atual := modos[0]
		for i in modos.size():
			assert_eq(atual.id, modos[i].id, "C760: proximo percorre na ordem (teste=%s, passo %d)" % [incluir_teste, i])
			atual = GameModes.proximo(atual, modos)
		assert_eq(atual.id, modos[0].id, "C760: proximo fecha o anel (teste=%s)" % incluir_teste)
		var volta := modos[modos.size() - 1]
		for i in modos.size():
			volta = GameModes.anterior(volta, modos)
		assert_eq(volta.id, modos[modos.size() - 1].id, "C760: anterior fecha o anel (teste=%s)" % incluir_teste)
		assert_eq(
			GameModes.anterior(modos[0], modos).id,
			modos[modos.size() - 1].id,
			"C760: anterior do primeiro e o ultimo (teste=%s)" % incluir_teste
		)


func test_c677_tempo_fim_por_regra_no_limite() -> void:
	var regra: GameModeRule = GameModes.de_id(&"tempo").regra
	Global.tempo_inicial_s = 7.5
	var limite: float = Global.limite_tempo_s()
	assert_eq(limite, 7.5, "C677: o limite vem do leitor de duracao (seam de debug ativo)")
	assert_false(regra.fim_por_regra({PartidaCtx.TEMPO: limite - EPSILON}), "C677: abaixo do limite nao termina")
	assert_true(regra.fim_por_regra({PartidaCtx.TEMPO: limite}), "C677: no limite termina")
	assert_true(regra.fim_por_regra({PartidaCtx.TEMPO: limite + 1.0}), "C677: acima do limite termina")
	assert_true(regra.fim_por_regra({PartidaCtx.TEMPO: 8}), "C677: tempo inteiro acima do limite termina")
	Global.tempo_inicial_s = 20.0
	assert_false(regra.fim_por_regra({PartidaCtx.TEMPO: 10.0}), "C677: o limite novo vale na chamada seguinte")


func test_c677_tempo_sem_chave_ou_tipo_errado_nao_termina() -> void:
	var regra: GameModeRule = GameModes.de_id(&"tempo").regra
	Global.tempo_inicial_s = 1.0
	assert_false(regra.fim_por_regra({}), "C677: ctx sem a chave de tempo nao termina")
	assert_false(regra.fim_por_regra({PartidaCtx.TEMPO: "999"}), "C677: tempo String nao termina")
	assert_false(regra.fim_por_regra({PartidaCtx.TEMPO: null}), "C677: tempo nulo nao termina")
	assert_false(regra.fim_por_regra({PartidaCtx.TEMPO: [999.0]}), "C677: tempo Array nao termina")
	assert_false(regra.fim_por_regra({PartidaCtx.PONTOS: 99}), "C677: so pontos no ctx nao termina")


func test_c678_puro_so_difere_nos_power_ups() -> void:
	var puro: GameModeRule = GameModes.de_id(&"puro").regra
	var classico: GameModeRule = GameModes.de_id(&"classico").regra
	for t: float in [0.0, 59.0, 60.0, 1000.0]:
		assert_false(puro.fim_por_regra({PartidaCtx.TEMPO: t}), "C678: Puro nunca termina por regra (t=%s)" % t)
	assert_true(puro.grava_recorde(), "C678: Puro grava recorde")
	assert_true(puro.ao_cair({}), "C678: Puro encerra ao cair")
	assert_eq(puro.pontuar(1), 1, "C678: Puro pontua direto")
	assert_false(puro.power_ups_habilitados(), "C678: Puro desabilita power-ups")
	assert_true(classico.power_ups_habilitados(), "Classico habilita power-ups")
	assert_true(GameModes.de_id(&"tempo").regra.power_ups_habilitados(), "Tempo habilita power-ups")
	assert_true(GameModes.de_id(&"tempo").regra.grava_recorde(), "Tempo grava recorde")
	assert_true(GameModes.de_id(&"tempo").regra.ao_cair({}), "Tempo encerra ao cair")


func test_chaves_do_ctx_da_stage_sao_as_constantes_de_partida_ctx() -> void:
	var stage: Node = add_child_autofree(load("res://scenes/Stage.tscn").instantiate())
	await wait_physics_frames(2)
	var ctx: Dictionary = stage._ctx_partida()
	assert_true(ctx.has(PartidaCtx.PONTOS), "ctx tem a chave de pontos de PartidaCtx")
	assert_true(ctx.has(PartidaCtx.INICIADO), "ctx tem a chave de iniciado de PartidaCtx")
	assert_eq(stage.CTX_PONTOS, PartidaCtx.PONTOS, "Stage cita a constante de pontos")
	assert_eq(stage.CTX_INICIADO, PartidaCtx.INICIADO, "Stage cita a constante de iniciado")
	assert_eq(stage.CTX_TEMPO, PartidaCtx.TEMPO, "Stage cita a constante de tempo")
