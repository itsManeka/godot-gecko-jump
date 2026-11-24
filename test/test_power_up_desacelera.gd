extends GutTest

# f522 T4: Desacelera — regra, registro e scroll. Cenarios do 05-test-plan:
# C607 scroll por frame = scroll do estagio x fator em cada estagio; C608 expirou, volta ao do estagio no
# frame seguinte ao consumo do ultimo; C609 position_scrolled e o gatilho de linhas acompanham o reduzido;
# C610 fator do Resource (injetado) altera proporcionalmente; C611 previsao de cor usa o scroll efetivo nos
# dois consumos (Player.scroll_efetivo e RunningPlatforms._alcance_s); C612 avancar_camera e o tempo da
# dificuldade nao desaceleram; C613 pausa congela o contador (registro de producao: test_power_up_state.gd).

const SCROLL_SCENE := "res://scenes/ScrollLevel.tscn"
const STAGE_SCENE := "res://scenes/Stage.tscn"
const PASSO := 1.0 / 60.0

var _iniciado_original := false
var _power_up_inicial_original := ""
var _tutorial_espelho_original := false
var _sem_derrota_original := false


func before_each() -> void:
	_iniciado_original = Global.iniciado
	_power_up_inicial_original = Global.power_up_inicial
	_tutorial_espelho_original = Global.tutorial_visto_espelho
	_sem_derrota_original = Global.sem_derrota
	Global.tutorial_visto_espelho = true
	Global.sem_derrota = true
	Global.iniciado = true


func after_each() -> void:
	get_tree().paused = false
	# ScrollLevel.create_new_running_platform entra na arvore por call_deferred; o laco manual de
	# _physics_process nao passa por frame, entao as linhas pendentes ficariam orfas quando o autofree
	# liberasse o ScrollLevel (vazamento no exit). Deixa o deferred rodar com o ScrollLevel ainda vivo.
	await wait_process_frames(2)
	Global.iniciado = _iniciado_original
	Global.power_up_inicial = _power_up_inicial_original
	Global.tutorial_visto_espelho = _tutorial_espelho_original
	Global.sem_derrota = _sem_derrota_original
	PowerUps.restaurar_padrao()


func _config(duracao: float, fator: float) -> PowerUpConfig:
	var config := PowerUpConfig.new()
	config.duracao_desacelera_s = duracao
	config.fator_desacelera = fator
	return config


# Pontos que levam a dificuldade de producao a cada estagio 0..3 (varredura: nao assume o limiar de cada um)
func _dificuldade_no_estagio(estagio: int) -> DifficultyState:
	var curva: DifficultyCurve = load("res://ressources/curva_dificuldade.tres")
	var estado := DifficultyState.new(curva)
	for pontos in 5000:
		estado.set_pontos(pontos)
		if estado.estagio() >= estagio:
			break
	return estado


# ScrollLevel isolado com dificuldade e estado de power-up injetados, antes do add_child (sem icones)
func _scroll(dificuldade: DifficultyState, estado: PowerUpState) -> ScrollLevel:
	var sl: ScrollLevel = load(SCROLL_SCENE).instantiate()
	sl.dificuldade = dificuldade
	sl.power_up_estado = estado
	sl.power_ups_habilitados = false
	add_child_autofree(sl)
	return sl


func _estado_com(config: PowerUpConfig) -> PowerUpState:
	var estado := PowerUpState.new()
	estado.coletar(PowerUpDesacelera.new(config))
	return estado


# Deslocamento de position_scrolled em 1 frame de _physics_process
func _deslocamento(sl: ScrollLevel, delta: float) -> float:
	var antes: float = sl.position_scrolled
	sl._physics_process(delta)
	return sl.position_scrolled - antes


# C607: em cada estagio 0 a 3, o deslocamento por frame e o scroll do estagio x fator do Resource
func test_deslocamento_e_scroll_do_estagio_vezes_o_fator_em_cada_estagio() -> void:
	var config := _config(100.0, PowerUpConfig.FATOR_PADRAO)
	for estagio in 4:
		var dificuldade := _dificuldade_no_estagio(estagio)
		assert_eq(dificuldade.estagio(), estagio, "fixture: dificuldade no estagio %d" % estagio)
		var scroll_do_estagio: float = DifficultySnapshot.de(dificuldade).get_scroll()
		var sl := _scroll(dificuldade, _estado_com(config))
		var esperado: float = scroll_do_estagio * config.fator_desacelera_vigente() * PASSO
		assert_almost_eq(_deslocamento(sl, PASSO), esperado, 0.0001, "estagio %d: scroll x fator" % estagio)


# C608: ao expirar volta ao scroll do estagio no frame seguinte ao consumo do ultimo frame do efeito
# (o tick vem depois do ScrollLevel: o frame em que o contador zera ainda e desacelerado)
func test_ao_expirar_volta_ao_scroll_do_estagio_no_frame_seguinte() -> void:
	var config := _config(0.5, PowerUpConfig.FATOR_PADRAO)
	var dificuldade := _dificuldade_no_estagio(0)
	var estado := _estado_com(config)
	var sl := _scroll(dificuldade, estado)
	var cheio: float = DifficultySnapshot.de(dificuldade).get_scroll() * 0.25
	var reduzido: float = cheio * config.fator_desacelera_vigente()
	# 2 frames de 0,25 s consomem a duracao inteira de 0,5 s
	assert_almost_eq(_deslocamento(sl, 0.25), reduzido, 0.0001, "frame 1 desacelerado")
	estado.tick(0.25)
	assert_almost_eq(_deslocamento(sl, 0.25), reduzido, 0.0001, "frame 2 (ultimo do efeito) desacelerado")
	estado.tick(0.25)
	assert_null(estado.ativo(), "fixture: expirou ao consumir a duracao")
	assert_almost_eq(_deslocamento(sl, 0.25), cheio, 0.0001, "frame seguinte: scroll do estagio")


# C609: position_scrolled e o gatilho de linhas acompanham o reduzido (menos deslocamento, linha nasce depois)
func test_position_scrolled_e_gatilho_de_linhas_acompanham_o_scroll_reduzido() -> void:
	var dificuldade := _dificuldade_no_estagio(0)
	var lento := _scroll(dificuldade, _estado_com(_config(1000.0, PowerUpConfig.FATOR_PADRAO)))
	var normal := _scroll(dificuldade, null)
	for i in 600:
		lento._physics_process(PASSO)
		normal._physics_process(PASSO)
	assert_gt(normal._rows_spawned, 0, "fixture: o scroll cheio gerou linhas")
	assert_almost_eq(lento.position_scrolled, normal.position_scrolled * PowerUpConfig.FATOR_PADRAO, 0.01, "scroll reduzido")
	assert_lt(lento._rows_spawned, normal._rows_spawned, "menos deslocamento: menos linhas nasceram")
	var esperadas: int = floori((lento.position_scrolled + ScrollLevel.EPSILON) / InitialRows.ESPACAMENTO)
	assert_eq(lento._rows_spawned, esperadas, "gatilho aritmetico segue o position_scrolled reduzido")


# C610: fator alterado no Resource (injetado) altera o deslocamento proporcionalmente
func test_fator_do_resource_altera_o_deslocamento_proporcionalmente() -> void:
	var dificuldade := _dificuldade_no_estagio(1)
	var scroll_do_estagio: float = DifficultySnapshot.de(dificuldade).get_scroll()
	var sl := _scroll(dificuldade, _estado_com(_config(100.0, 0.25)))
	assert_almost_eq(_deslocamento(sl, PASSO), scroll_do_estagio * 0.25 * PASSO, 0.0001, "fator 0,25 do Resource")


# C611 (consumo 1): a previsao de cor do Player usa o scroll efetivo (estagio x fator)
func test_player_previsao_de_cor_usa_scroll_efetivo() -> void:
	var dificuldade := _dificuldade_no_estagio(2)
	var cheio: float = DifficultySnapshot.de(dificuldade).get_scroll()
	var player = autofree(load("res://scenes/Player.gd").new())
	player.dificuldade = dificuldade
	assert_almost_eq(player.scroll_efetivo(), cheio, 0.0001, "sem power-up: scroll cheio")
	player.power_up_estado = _estado_com(_config(100.0, 0.5))
	assert_almost_eq(player.scroll_efetivo(), cheio * 0.5, 0.0001, "com Desacelera: scroll x fator")
	assert_ne(ReachableColors.tempo_de_pulo(player.scroll_efetivo()), ReachableColors.tempo_de_pulo(cheio), "o tempo de pulo muda")


# C611 (consumo 2): o alcance da cicladora na RunningPlatforms usa o scroll efetivo
func test_running_platforms_alcance_usa_scroll_efetivo() -> void:
	var dificuldade := _dificuldade_no_estagio(2)
	var cheio: float = DifficultySnapshot.de(dificuldade).get_scroll()
	var linha = autofree(load("res://scenes/RunningPlatforms.gd").new())
	linha.set("_snapshot_nascimento", DifficultySnapshot.de(dificuldade))
	var periodo := 0.01
	var alcance_cheio: float = linha._alcance_s(periodo)
	assert_almost_eq(alcance_cheio, maxf(ReachableColors.tempo_de_pulo(cheio), periodo) + periodo, 0.0001, "sem power-up")
	linha.power_up_estado = _estado_com(_config(100.0, 0.5))
	var esperado: float = maxf(ReachableColors.tempo_de_pulo(cheio * 0.5), periodo) + periodo
	assert_almost_eq(linha._alcance_s(periodo), esperado, 0.0001, "com Desacelera: tempo de pulo do scroll efetivo")
	assert_ne(linha._alcance_s(periodo), alcance_cheio, "o alcance difere do cheio")


# C612: avancar_camera e o tempo da dificuldade nao desaceleram com o power-up ativo
func test_avancar_camera_e_tempo_da_dificuldade_nao_desaceleram() -> void:
	var com := _scroll(_dificuldade_no_estagio(0), _estado_com(_config(100.0, 0.5)))
	var sem := _scroll(_dificuldade_no_estagio(0), null)
	var gecko_com := Node2D.new()
	var gecko_sem := Node2D.new()
	add_child_autofree(gecko_com)
	add_child_autofree(gecko_sem)
	gecko_com.global_position = Vector2(90, -100)
	gecko_sem.global_position = Vector2(90, -100)
	var antes_com: float = com.position_scrolled
	var antes_sem: float = sem.position_scrolled
	com.avancar_camera(gecko_com, 100.0)
	sem.avancar_camera(gecko_sem, 100.0)
	var avanco_sem: float = sem.position_scrolled - antes_sem
	assert_gt(avanco_sem, 0.0, "fixture: o gecko acima do limite avanca a camera")
	assert_almost_eq(com.position_scrolled - antes_com, avanco_sem, 0.0001, "avancar_camera inalterado com Desacelera")
	# tempo da dificuldade: mesmo tick, mesmo scroll de estagio com e sem o power-up
	var d_com := _dificuldade_no_estagio(0)
	var d_sem := _dificuldade_no_estagio(0)
	var estado := _estado_com(_config(100.0, 0.5))
	d_com.tick(10.0)
	estado.tick(10.0)
	d_sem.tick(10.0)
	assert_eq(
		DifficultySnapshot.de(d_com).get_scroll(), DifficultySnapshot.de(d_sem).get_scroll(), "tempo da dificuldade nao desacelera"
	)


# C613: pausa (tree.paused) congela o contador do Desacelera; o tempo de jogo (tick) o expira
func test_pausa_congela_e_o_tempo_de_jogo_expira() -> void:
	Global.iniciado = false
	Global.power_up_inicial = "desacelera"
	var stage: Node = add_child_autofree(load(STAGE_SCENE).instantiate())
	await wait_frames(2)
	stage.call("_on_Play_button_down")
	var estado: PowerUpState = stage.get("power_up_estado")
	assert_ne(estado.ativo(), null, "desacelera ativo ao iniciar a partida")
	var duracao: float = PowerUpConfig.carregar().duracao_desacelera_vigente()
	get_tree().paused = true
	var antes: float = estado.restante()
	for i in int(duracao * 60.0) + 30:
		await get_tree().physics_frame
	assert_eq(estado.restante(), antes, "pausado: contador congelado")
	assert_ne(estado.ativo(), null, "tempo de relogio nao expira o Desacelera")
	get_tree().paused = false
	for i in int(duracao * 60.0) + 30:
		await get_tree().physics_frame
	assert_null(estado.ativo(), "a duracao em tempo de jogo (tick) expira o Desacelera")
	var area: Area2D = stage.get_node_or_null("CheckPlayer") as Area2D
	if area != null:
		var chamada := Callable(stage, "_on_CheckPlayer_body_exited")
		if area.body_exited.is_connected(chamada):
			area.body_exited.disconnect(chamada)
