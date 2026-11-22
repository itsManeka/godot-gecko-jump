extends GutTest

# f527 T5 (D1): no Zen o menu nao mostra Last, Best nem a faixa; a ponte publica best 0 e modo "zen".

const STAGE := "res://scenes/Stage.tscn"
var _sv: SubViewport
var _stage: Node


func before_each() -> void:
	Global.tutorial_visto_espelho = true
	Global.platforms = []
	Global.iniciado = false


func after_each() -> void:
	get_tree().paused = false
	Global.set_modo_jogo(GameModes.ID_CLASSICO)
	Global.platforms = []
	Global.iniciado = false


func _spawn(regra: GameModeRule) -> void:
	_sv = SubViewport.new()
	_sv.size = Vector2i(180, 320)
	add_child_autofree(_sv)
	_stage = load(STAGE).instantiate()
	_stage.regra = regra
	_sv.add_child(_stage)
	await wait_process_frames(1)


func _visiveis() -> Array:
	return [_stage.bestscore.visible, _stage.lastscore.visible, _stage.faixaplacar.visible]


# C730
func test_menu_zen_oculta_last_best_e_faixa_e_os_outros_modos_mostram() -> void:
	Global.set_modo_jogo(GameModes.ID_ZEN)
	await _spawn(ZenRule.new())
	assert_false(_stage.bestscore.visible, "C730: Zen oculta Best")
	assert_false(_stage.lastscore.visible, "C730: Zen oculta Last")
	assert_false(_stage.faixaplacar.visible, "C730: Zen oculta a faixa")
	for id in [GameModes.ID_CLASSICO, GameModes.ID_PURO, GameModes.ID_TEMPO]:
		_stage._fechar_modos(GameModes.de_id(id))
		assert_eq(_visiveis(), [true, true, true], "C730: %s mostra Best, Last e faixa" % String(id))


# C731
func test_ciclo_zen_classico_restaura_as_tres_visibilidades_sem_reload() -> void:
	await _spawn(ClassicoRule.new())
	assert_eq(_visiveis(), [true, true, true], "C731: pre-condicao, Classico mostra as tres")
	_stage._fechar_modos(GameModes.de_id(GameModes.ID_ZEN))
	assert_eq(_visiveis(), [false, false, false], "C731: Zen oculta as tres")
	_stage._fechar_modos(GameModes.de_id(GameModes.ID_CLASSICO))
	assert_eq(_visiveis(), [true, true, true], "C731: de volta ao Classico as tres voltam sem reload")


# C732
func test_ponte_no_zen_publica_modo_zen_e_best_zero() -> void:
	Global.set_modo_jogo(GameModes.ID_ZEN)
	await _spawn(ZenRule.new())
	assert_eq(String(_stage.ultimo_estado.get("modo", "")), "zen", "C732: modo da ponte e zen")
	assert_eq(int(_stage.ultimo_estado.get("best", -1)), 0, "C732: best da ponte e 0 no Zen")


# C733
func test_botao_modo_zen_cabe_em_112_px_e_mostra_zen() -> void:
	var botao := ModoBotao.new()
	add_child_autofree(botao)
	botao.definir_modo(GameModes.de_id(GameModes.ID_ZEN))
	assert_eq(botao.texto(), "Modo: Zen", "C733: texto do botao")
	botao.focar(true)
	var largura: float = ModoBotao.FONTE.get_string_size(
		botao.texto(), HORIZONTAL_ALIGNMENT_LEFT, -1, ModoBotao.TAMANHO_TEXTO
	).x
	assert_lt(largura + 2.0 * ModoBotao.CONTORNO_TEXTO, ModoBotao.LARGURA, "C733: com foco cabe em 112 px")
