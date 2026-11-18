extends GutTest

# f517 T4 (C488-C489): Stage repassa `semente_partida` ao ScrollLevel em _enter_tree. O chamador seta a
# semente ANTES do add_child; ao entrar na arvore o ScrollLevel ja a tem (antes do _ready de qualquer filho,
# onde as linhas do .tscn leem o rng). Sem semente, o membro do ScrollLevel fica null e o Global nao e tocado.
# Montagem do modelo de test_stage_dificuldade.gd (load(STAGE_SCENE).instantiate() + add_child_autofree).
const STAGE_SCENE := "res://scenes/Stage.tscn"
const SEMENTE := 4242


func before_each() -> void:
	Global.tutorial_visto_espelho = true
	Global.set_iniciado(false)


func after_each() -> void:
	Global.set_iniciado(false)


# C488: a semente setada antes do add_child chega ao ScrollLevel ja no primeiro frame (_enter_tree)
func test_semente_partida_chega_ao_scroll_level_ao_entrar_na_arvore() -> void:
	var stage: Node = load(STAGE_SCENE).instantiate()
	stage.semente_partida = SEMENTE
	add_child_autofree(stage)
	var scroll_level: ScrollLevel = stage.get_node("ScrollLevel") as ScrollLevel
	assert_not_null(scroll_level, "a Stage deveria ter o ScrollLevel filho")
	assert_eq(scroll_level.semente, SEMENTE, "ScrollLevel.semente deveria ser a semente da Stage ja ao entrar na arvore")
	# So passa com o repasse em Stage._enter_tree: o ScrollLevel injeta o rng nas linhas do .tscn no proprio
	# _enter_tree (roda logo depois do da Stage, antes de qualquer _ready). Com a semente setada so em _ready, a
	# injecao seria no-op: as do .tscn e as extras de ScrollLevel._ready (que rodam antes do _ready da Stage)
	# ficariam com rng null. Por isso todos os filhos, nao so a contagem do .tscn (as extras entram no _ready).
	var linhas: Array = scroll_level.get_node("RunningPlatforms").get_children()
	assert_gt(linhas.size(), 4, "o ScrollLevel deveria ter as 5 linhas do .tscn (mais as extras do _ready)")
	for linha in linhas:
		assert_not_null(linha.rng, "rng da linha %s deveria existir apos o add_child (injetado com a semente de _enter_tree)" % linha.name)


# C489: sem setar semente_partida, o ScrollLevel fica com semente null; Global nao e tocado pela Stage
func test_sem_semente_partida_scroll_level_fica_null_e_global_intacto() -> void:
	var stage: Node = load(STAGE_SCENE).instantiate()
	add_child_autofree(stage)
	var scroll_level: ScrollLevel = stage.get_node("ScrollLevel") as ScrollLevel
	assert_null(scroll_level.semente, "sem semente_partida o ScrollLevel nao deveria ter semente")
	assert_false(Global.is_iniciado(), "a Stage nao deveria ligar Global ao montar a partida sem semente")
