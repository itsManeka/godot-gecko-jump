extends GutTest

# f559 T8: nevoa reativa na base (Nevoa + NevoaRegra). Valores esperados calculados a mao para H = 640:
# zona segura ate y = 464 (H - 176); aproximacao de 464 a 608 (H - 32), p = (y - 464) / 144.
const STAGE := "res://scenes/Stage.tscn"
const ALTURA := 640.0
const EPS := 0.0001
var _sv: SubViewport
var _stage: Node
var _nevoa: Nevoa
var _jogador: Node2D


func before_each() -> void:
	Global.tutorial_visto_espelho = true
	Global.platforms = []
	Global.iniciado = false
	Global.sem_derrota = false


func after_each() -> void:
	get_tree().paused = false
	Global.sem_derrota = false
	Global.set_modo_jogo(GameModes.ID_CLASSICO)
	Global.platforms = []
	Global.iniciado = false


# Nevoa avulsa num SubViewport 360x640, com o gecko falso em y; o _process fica desligado (os testes dirigem a mao)
func _spawn_nevoa(y: float, iniciada: bool) -> void:
	_sv = SubViewport.new()
	_sv.size = Vector2i(360, int(ALTURA))
	add_child_autofree(_sv)
	_jogador = Node2D.new()
	_jogador.position = Vector2(180.0, y)
	_sv.add_child(_jogador)
	_nevoa = Nevoa.new()
	_nevoa.jogador = _jogador
	_sv.add_child(_nevoa)
	_nevoa.set_process(false)
	Global.iniciado = iniciada
	await wait_process_frames(1)
	_nevoa.atualizar()


func _spawn_stage(regra: GameModeRule) -> void:
	_sv = SubViewport.new()
	_sv.size = Vector2i(360, int(ALTURA))
	add_child_autofree(_sv)
	_stage = load(STAGE).instantiate()
	_stage.regra = regra
	_sv.add_child(_stage)
	await wait_process_frames(1)


func _controles(no: Node) -> Array[Control]:
	var achados: Array[Control] = []
	for filho in no.get_children():
		if filho is Control:
			achados.append(filho)
		achados.append_array(_controles(filho))
	return achados


# C916
func test_regra_pura_valores_de_borda_dos_tres_regimes() -> void:
	assert_almost_eq(NevoaRegra.altura(false, 600.0, ALTURA), 28.0, EPS, "C916: menu altura 28")
	assert_almost_eq(NevoaRegra.opacidade(false, 600.0, ALTURA), 0.35, EPS, "C916: menu opacidade 0.35")
	assert_almost_eq(NevoaRegra.altura(true, 400.0, ALTURA), 32.0, EPS, "C916: zona segura altura 32")
	assert_almost_eq(NevoaRegra.opacidade(true, 400.0, ALTURA), 0.45, EPS, "C916: zona segura opacidade 0.45")
	assert_almost_eq(NevoaRegra.altura(true, 464.0, ALTURA), 32.0, EPS, "C916: p=0 (y=H-176) altura 32")
	assert_almost_eq(NevoaRegra.opacidade(true, 464.0, ALTURA), 0.45, EPS, "C916: p=0 opacidade 0.45")
	assert_almost_eq(NevoaRegra.altura(true, 536.0, ALTURA), 48.0, EPS, "C916: p=0.5 altura 48")
	assert_almost_eq(NevoaRegra.opacidade(true, 536.0, ALTURA), 0.65, EPS, "C916: p=0.5 opacidade 0.65")
	assert_almost_eq(NevoaRegra.altura(true, 608.0, ALTURA), 64.0, EPS, "C916: p=1 (y=H-32) altura 64")
	assert_almost_eq(NevoaRegra.opacidade(true, 608.0, ALTURA), 0.85, EPS, "C916: p=1 opacidade 0.85")
	assert_almost_eq(NevoaRegra.altura(true, 900.0, ALTURA), 64.0, EPS, "C916: y abaixo da faixa clampa em 64")
	assert_almost_eq(NevoaRegra.opacidade(true, 900.0, ALTURA), 0.85, EPS, "C916: y abaixo da faixa clampa em 0.85")
	assert_almost_eq(NevoaRegra.altura(true, -50.0, ALTURA), 32.0, EPS, "C916: y acima da faixa clampa em 32")
	assert_almost_eq(NevoaRegra.perigo(1000.0, 800.0), 1.0, EPS, "C916: perigo usa a altura visivel recebida (H=800)")
	assert_almost_eq(NevoaRegra.perigo(696.0, 800.0), 0.5, EPS, "C916: H=800, y=696 = p 0.5")


# C917
func test_oculta_no_zen_e_com_sem_derrota_e_reavalia_ao_trocar_de_modo() -> void:
	# Modo lido de Global, nao da regra injetada: regra Classico com Global em Zen continua oculta
	Global.set_modo_jogo(GameModes.ID_ZEN)
	await _spawn_stage(ClassicoRule.new())
	assert_false(_stage.nevoa.visible, "C917: Zen em Global oculta a nevoa no _ready")
	_stage._fechar_modos(GameModes.de_id(GameModes.ID_CLASSICO))
	assert_true(_stage.nevoa.visible, "C917: _fechar_modos para Classico mostra a nevoa")
	_stage._fechar_modos(GameModes.de_id(GameModes.ID_ZEN))
	assert_false(_stage.nevoa.visible, "C917: _fechar_modos para Zen oculta a nevoa")
	Global.set_modo_jogo(GameModes.ID_PURO)
	_stage._mostrar_menu(true)
	assert_true(_stage.nevoa.visible, "C917: _mostrar_menu(true) reavalia com o modo de Global (Puro mostra)")
	Global.set_modo_jogo(GameModes.ID_ZEN)
	_stage._mostrar_menu(true)
	assert_false(_stage.nevoa.visible, "C917: _mostrar_menu(true) reavalia com o modo de Global (Zen oculta)")
	for id in [GameModes.ID_CLASSICO, GameModes.ID_PURO, GameModes.ID_TEMPO]:
		_stage._fechar_modos(GameModes.de_id(id))
		assert_true(_stage.nevoa.visible, "C917: %s mostra a nevoa" % String(id))
	Global.sem_derrota = true
	_stage._fechar_modos(GameModes.de_id(GameModes.ID_CLASSICO))
	assert_false(_stage.nevoa.visible, "C917: sem_derrota oculta a nevoa mesmo no Classico")


# C918
func test_todo_control_da_nevoa_ignora_o_mouse() -> void:
	await _spawn_nevoa(400.0, true)
	var controles: Array[Control] = _controles(_nevoa)
	assert_gt(controles.size(), 0, "C918: a nevoa tem Controls")
	var ruins: Array = []
	for controle in controles:
		if controle.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			ruins.append(String(controle.name))
	assert_eq(ruins.size(), 0, "C918: Controls que nao ignoram o mouse: %s" % str(ruins))


# C919
func test_nevoa_entre_fundo_e_moldura_e_desliza_rapido_so_com_perigo_acima_de_meio() -> void:
	await _spawn_stage(ClassicoRule.new())
	var filhos: Array[Node] = _stage.get_children()
	var i_fundo: int = filhos.find(_stage.fundo)
	var i_nevoa: int = filhos.find(_stage.nevoa)
	var i_moldura: int = filhos.find(_stage.level_up_frame)
	assert_true(i_fundo < i_nevoa, "C919: nevoa depois do fundo na arvore")
	assert_true(i_nevoa < i_moldura, "C919: nevoa antes da moldura de subida de estagio")
	assert_gt(_stage.nevoa.layer, _stage.fundo.layer, "C919: nevoa acima do fundo")
	assert_lt(_stage.nevoa.layer, _stage.get_node("CanvasLayer").layer, "C919: nevoa abaixo do HUD")
	# p = 0.5 exato (y = 536) nao e rapido: 1 s a 16 px/s
	await _spawn_nevoa(536.0, true)
	_nevoa.avancar(1.0)
	assert_almost_eq(_nevoa.deslocamento(0), 16.0, EPS, "C919: p=0.5 desliza a 16 px/s (sem x1.4)")
	# y = 537 -> p > 0.5: x1.4
	_jogador.position.y = 537.0
	_nevoa.atualizar()
	_nevoa.avancar(1.0)
	assert_almost_eq(_nevoa.deslocamento(0), 16.0 + 22.4, EPS, "C919: p>0.5 desliza a 16 x 1.4 px/s")
	assert_almost_eq(_nevoa.deslocamento(1), 350.0 - 14.0, EPS, "C919: a 2a faixa vai no sentido oposto, tambem x1.4")


# C920
func test_faixas_deslizam_em_loop_sem_costura() -> void:
	await _spawn_nevoa(400.0, true)
	assert_almost_eq(_nevoa.deslocamento(0), 0.0, EPS, "C920: comeca em 0")
	for k in range(45):
		_nevoa.avancar(0.5)
	assert_almost_eq(_nevoa.deslocamento(0), 0.0, EPS, "C920: apos 360/16 s o offset volta ao inicio")
	var anterior: float = _nevoa.deslocamento(0)
	var salto_max: float = 0.0
	for k in range(100):
		_nevoa.avancar(0.25)
		var passo: float = fposmod(_nevoa.deslocamento(0) - anterior, 360.0)
		salto_max = maxf(salto_max, absf(passo - 4.0))
		anterior = _nevoa.deslocamento(0)
	assert_almost_eq(salto_max, 0.0, EPS, "C920: cada passo de 0.25 s anda 4 px, inclusive na virada (sem salto)")
	for imagem in _controles(_nevoa):
		if imagem is TextureRect:
			assert_true(imagem.position.x <= 0.0 and imagem.position.x > -360.0 - EPS, "C920: imagem cobre a tela")


func test_nevoa_do_menu_usa_altura_e_opacidade_discretas_ancoradas_na_base() -> void:
	await _spawn_nevoa(600.0, false)
	assert_almost_eq(_nevoa.altura_atual(), 28.0, EPS, "menu: altura 28 mesmo com o gecko perto da base")
	assert_almost_eq(_nevoa.opacidade_atual(), 0.35, EPS, "menu: opacidade 0.35")
	var faixa: Control = _nevoa.faixas()[0]
	assert_almost_eq(faixa.position.y + faixa.size.y, ALTURA, EPS, "a faixa termina em y = H")
