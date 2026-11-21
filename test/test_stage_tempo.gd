extends GutTest

# f524 T3: relogio da partida na Stage e fim por relogio zerado (modo Contra o tempo). Cenarios C686-C694.
# O relogio e testado por ticks manuais de `_physics_process(delta)` com delta binario exato (0,25: 8 ticks = 2 s sem erro
# de ponto flutuante); so o cenario da pausa (C689) usa a fisica real da arvore. Limite curto pelo seam
# `Global.tempo_inicial_s` (2 s); o `.tres` de producao nunca e tocado. Recordes isolados pelo pre-run do GUT (sem user:// real).
const STAGE_SCENE := "res://scenes/Stage.tscn"
const PLATFORM_SCENE := "res://scenes/Platform.tscn"
const VISIVEL := Vector2(180.0, 320.0)
const SAFE := Rect2(0.0, 0.0, 180.0, 320.0)
const DELTA := 0.25
const LIMITE_CURTO := 2.0
const TICKS_ATE_O_LIMITE := 8
const X_QUEDA := 20.0
const Y_QUEDA := 360.0

var _stage: Node = null
var _p: Node = null
var _modo_original: StringName = GameModes.ID_CLASSICO
var _tempo_original: float = 0.0
var _plataformas_original: Array = []
var _iniciado_original: bool = false
var _tutorial_original: bool = false
var _sem_derrota_original: bool = false


func before_each() -> void:
	_modo_original = Global.get_modo_jogo()
	_tempo_original = Global.tempo_inicial_s
	_plataformas_original = Global.platforms
	_iniciado_original = Global.iniciado
	_tutorial_original = Global.tutorial_visto_espelho
	_sem_derrota_original = Global.sem_derrota
	Global.tutorial_visto_espelho = true
	Global.sem_derrota = false
	Global.platforms = []
	Global.iniciado = false
	Global.tempo_inicial_s = LIMITE_CURTO
	PowerUps.restaurar_padrao()
	Global.set_modo_jogo(GameModes.ID_TEMPO, false)
	Global.keeper_do_modo(GameModes.ID_TEMPO).load_best(0)


func after_each() -> void:
	if is_instance_valid(_p):
		_p.end = true
	get_tree().paused = false
	Global.platforms = _plataformas_original
	Global.iniciado = false
	Global.tempo_inicial_s = _tempo_original
	Global.tutorial_visto_espelho = _tutorial_original
	Global.sem_derrota = _sem_derrota_original
	Global.set_modo_jogo(_modo_original, false)
	PowerUps.restaurar_padrao()
	_stage = null
	_p = null


# Stage real (sem ScrollLevel: as plataformas sao as do teste) no modo atual de Global, layout fixo 180x320. Com
# `manual`, a fisica propria da Stage e do Player fica desligada: quem avanca o relogio e o teste (`_tick`).
func _novo_stage(manual: bool = true) -> Node:
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
	if manual:
		_stage.set_physics_process(false)
	return _stage


# Partida iniciada direto no estado global (o relogio so olha Global.is_iniciado)
func _iniciar() -> void:
	Global.iniciado = true


func _tick(n: int, delta: float = DELTA) -> void:
	for i in n:
		_stage._physics_process(delta)


func _fisica(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _perdeu() -> bool:
	return _stage.ultimo_estado.get("state", "") == GameState.STATE_LOST


func _plataforma(cor: Enums.COLOR, x: float, y: float) -> Platform:
	var plat: Platform = _plataforma_solta(cor, x, y)
	# Teto desmoronado: so cobre a linha de cima da candidata (padrao de test_stage_segunda_chance.gd)
	var teto: Platform = _plataforma_solta(cor, x, y - InitialRows.ESPACAMENTO)
	teto.desmoronada = true
	return plat


func _plataforma_solta(cor: Enums.COLOR, x: float, y: float) -> Platform:
	var plat: Platform = load(PLATFORM_SCENE).instantiate()
	plat.set_color(cor)
	add_child_autofree(plat)
	plat.global_position = Vector2(x, y)
	return plat


func _estado() -> PowerUpState:
	return _stage.power_up_estado


# Partida do Tempo que acaba pelo relogio com `pontos` na Stage (recorde do modo gravado ao encerrar)
func _partida_ate_o_fim(pontos: int) -> void:
	await _novo_stage()
	_stage.points = pontos
	_iniciar()
	_tick(TICKS_ATE_O_LIMITE)
	_p.end = true


func test_c686_relogio_nao_corre_antes_de_iniciar_nem_com_o_menu_aberto() -> void:
	await _novo_stage()
	_tick(40)
	assert_eq(_stage.tempo_partida, 0.0, "partida nao iniciada: o relogio fica em 0 apos 10 s de fisica")
	assert_false(_perdeu(), "partida nao iniciada nunca perde por tempo")
	_stage._abrir_opcoes_do_menu()
	assert_true(_stage.options_screen.esta_aberta(), "fixture: menu (Opcoes) aberto sobre a Stage")
	_tick(40)
	assert_eq(_stage.tempo_partida, 0.0, "menu aberto sobre a Stage: o relogio segue em 0")
	assert_false(_perdeu(), "menu aberto nunca perde por tempo")
	_iniciar()
	_tick(1)
	assert_eq(_stage.tempo_partida, DELTA, "iniciada: o relogio passa a correr")


func test_c687_ao_chegar_no_limite_perde_no_mesmo_tick_e_grava_so_o_recorde_do_tempo() -> void:
	var classico := Global.keeper_do_modo(GameModes.ID_CLASSICO)
	classico.load_best(4)
	classico.set_score(2)
	var puro := Global.keeper_do_modo(GameModes.ID_PURO)
	puro.load_best(6)
	puro.set_score(3)
	await _novo_stage()
	_stage.points = 5
	_iniciar()
	_tick(TICKS_ATE_O_LIMITE - 1)
	assert_false(_perdeu(), "um tick antes do limite a partida segue")
	assert_false(_p.is_end(), "um tick antes do limite o gecko segue vivo")
	_tick(1)
	assert_eq(_stage.tempo_partida, LIMITE_CURTO, "o relogio chegou ao limite")
	assert_true(_perdeu(), "no tick em que o relogio chega ao limite o estado e lost")
	assert_true(_p.is_end(), "o gecko encerrou no mesmo tick")
	assert_eq(Global.keeper_do_modo(GameModes.ID_TEMPO).best, 5, "o recorde do Tempo guarda os pontos")
	assert_eq(classico.best, 4, "recorde do Classico inalterado")
	assert_eq(classico.last, 2, "ultimo do Classico inalterado")
	assert_eq(puro.best, 6, "recorde do Puro inalterado")
	assert_eq(puro.last, 3, "ultimo do Puro inalterado")


func test_c688_desacelera_ativo_nao_desacelera_o_relogio() -> void:
	Global.tempo_inicial_s = 1000.0
	await _novo_stage()
	_iniciar()
	_estado().coletar(PowerUps.resolver(&"desacelera"))
	assert_not_null(_estado().ativo(), "fixture: Desacelera ativo")
	_tick(TICKS_ATE_O_LIMITE)
	assert_not_null(_estado().ativo(), "fixture: Desacelera ainda ativo ao fim dos ticks")
	assert_eq(_stage.tempo_partida, TICKS_ATE_O_LIMITE * DELTA, "relogio avanca K*delta, igual ao sem power-up")


func test_c689_pausa_congela_o_relogio_e_despausar_retoma_do_mesmo_valor() -> void:
	Global.tempo_inicial_s = 1000.0
	await _novo_stage(false)
	_stage._on_Play_button_down()
	await _fisica(5)
	var antes: float = _stage.tempo_partida
	assert_gt(antes, 0.0, "fixture: o relogio corre com a partida iniciada")
	get_tree().paused = true
	await _fisica(5)
	assert_eq(_stage.tempo_partida, antes, "pausado: o relogio nao avanca")
	get_tree().paused = false
	await _fisica(5)
	assert_gt(_stage.tempo_partida, antes, "despausado: o relogio retoma de onde parou")
	assert_lt(_stage.tempo_partida, antes + 1.0, "despausado: sem salto")


func test_c690_partida_nova_zera_o_relogio() -> void:
	await _partida_ate_o_fim(0)
	assert_true(_perdeu(), "fixture: a 1a partida terminou por relogio")
	assert_eq(_stage.tempo_partida, LIMITE_CURTO, "fixture: a 1a partida acumulou o limite")
	_stage.queue_free()
	await wait_frames(2)
	Global.iniciado = false
	await _novo_stage()
	assert_eq(_stage.tempo_partida, 0.0, "Stage nova nasce com o relogio em 0")
	_iniciar()
	_tick(4)
	assert_eq(_stage.tempo_partida, 4 * DELTA, "2a partida conta so os proprios segundos")
	assert_false(_perdeu(), "2a partida nao herda a derrota da 1a")


func test_c691_queda_antes_do_limite_perde_e_para_o_relogio_e_classico_nunca_perde_por_tempo() -> void:
	await _novo_stage()
	_iniciar()
	_tick(4)
	_p.global_position = Vector2(X_QUEDA, Y_QUEDA)
	_stage._on_CheckPlayer_body_exited(_p)
	assert_true(_perdeu(), "queda antes do limite com 0 cargas: derrota padrao lost")
	assert_true(_p.is_end(), "o gecko encerrou")
	_tick(TICKS_ATE_O_LIMITE)
	assert_eq(_stage.tempo_partida, 4 * DELTA, "relogio parado depois de lost")
	# (g) Classico: 70 s de fisica iniciada nunca perdem por tempo, mesmo com o limite curto do seam
	_p.end = true
	Global.iniciado = false
	Global.set_modo_jogo(GameModes.ID_CLASSICO, false)
	await _novo_stage()
	_iniciar()
	_tick(280)
	assert_false(_perdeu(), "Classico: mais de 60 s iniciada nunca perde por tempo")
	assert_false(_p.is_end(), "Classico: o gecko segue vivo")


func test_c692_segunda_chance_no_tempo_reaparece_sem_reiniciar_o_relogio() -> void:
	Global.tempo_inicial_s = 1000.0
	await _novo_stage()
	var plat := _plataforma(Global.cor_gecko, 90.0, 60.0)
	_iniciar()
	_stage._coletar_power_up(&"segunda_chance")
	assert_eq(_estado().carga(), 1, "fixture: carga guardada")
	_tick(4)
	_p.global_position = Vector2(X_QUEDA, Y_QUEDA)
	_stage._on_CheckPlayer_body_exited(_p)
	assert_false(_perdeu(), "com 1 carga a queda reaparece: sem lost")
	assert_eq(_stage.ultimo_estado["state"], GameState.STATE_PLAYING, "a partida segue playing")
	assert_eq(_estado().carga(), 0, "a carga foi consumida")
	assert_eq(_p.actual_platform, plat, "o gecko reapareceu na plataforma de resgate")
	assert_eq(_stage.tempo_partida, 4 * DELTA, "o relogio nao reinicia nem recua")
	_tick(4)
	assert_eq(_stage.tempo_partida, 8 * DELTA, "o relogio segue contando depois do resgate")
	# Sem carga a queda encerra
	_p.global_position = Vector2(X_QUEDA, Y_QUEDA)
	_p.reaparecer_sobre(plat, int(Global.cor_gecko))
	_p.global_position = Vector2(X_QUEDA, Y_QUEDA)
	_stage._on_CheckPlayer_body_exited(_p)
	assert_true(_perdeu(), "sem carga a queda encerra")


func test_c693_relogio_zerado_nao_consome_a_segunda_chance() -> void:
	await _novo_stage()
	_plataforma(Global.cor_gecko, 90.0, 60.0)
	_iniciar()
	_stage._coletar_power_up(&"segunda_chance")
	assert_eq(_estado().carga(), 1, "fixture: carga guardada")
	_p.global_position = Vector2(X_QUEDA, Y_QUEDA)
	_tick(TICKS_ATE_O_LIMITE)
	assert_true(_perdeu(), "o relogio zerado encerra mesmo com a carga armada")
	assert_true(_p.is_end(), "o gecko encerrou")
	assert_eq(_estado().carga(), 1, "a carga nao foi consumida: so a queda a consome")


func test_c694_recorde_do_tempo_so_substitui_por_partida_melhor() -> void:
	var keeper := Global.keeper_do_modo(GameModes.ID_TEMPO)
	keeper.load_best(5)
	await _partida_ate_o_fim(3)
	assert_eq(keeper.best, 5, "partida pior nao grava por cima")
	Global.iniciado = false
	await _partida_ate_o_fim(5)
	assert_eq(keeper.best, 5, "partida igual mantem o recorde")
	Global.iniciado = false
	await _partida_ate_o_fim(8)
	assert_eq(keeper.best, 8, "partida melhor substitui o recorde")
