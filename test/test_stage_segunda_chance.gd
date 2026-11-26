extends GutTest

# f526 T5: consumo da carga da Segunda chance na linha de derrota da Stage. Cenarios C655-C665 do
# 05-test-plan. A queda entra pelo handler da linha (chamada direta, padrao de test_stage_estado.gd)
# e, onde o cenario pede os frames seguintes reais, por fisica de verdade (C660/C662). A Stage nasce
# sem ScrollLevel (as plataformas de candidatura sao as do teste) com layout fixo 360x640: a faixa de
# derrota fica em y [640, 680] e a candidatura e deterministica. Teardown (C665): _p.end = true no
# after_each — liberar a Stage dispara body_exited (padrao do C554) e o handler sai cedo.

const STAGE_SCENE := "res://scenes/Stage.tscn"
const PLATFORM_SCENE := "res://scenes/Platform.tscn"
const RegraDeTeste := preload("res://test/support/RegraDeTeste.gd")
const VISIVEL := Vector2(360.0, 640.0)
const SAFE := Rect2(0.0, 0.0, 360.0, 640.0)
# Coluna livre de plataformas: a queda real cruza a faixa sem pousar em nada
const X_QUEDA := 40.0
# Ponto da queda forcada (chamada direta do handler): abaixo da faixa de derrota
const Y_QUEDA := 720.0

var _stage: Node = null
var _p: Node = null
var _plataformas_original: Array = []
var _iniciado_original := false
var _tutorial_espelho_original := false
var _sem_derrota_original := false
var _cor_original: Enums.COLOR
var _cor_livre_original := false
var _keeper_original: ScoreKeeper


func before_each() -> void:
	_plataformas_original = Global.platforms
	_iniciado_original = Global.iniciado
	_tutorial_espelho_original = Global.tutorial_visto_espelho
	_sem_derrota_original = Global.sem_derrota
	_cor_original = Global.cor_gecko
	_cor_livre_original = Global.cor_livre
	Global.tutorial_visto_espelho = true
	Global.platforms = []
	Global.iniciado = false
	Global.cor_livre = false
	# Keeper limpo (sem store): o recorde observado e so desta rodada (padrao test_stage_regra_modo)
	_keeper_original = Global.pontuacao
	Global.pontuacao = ScoreKeeper.new()
	# Registro de producao restaurado: resolver(&"segunda_chance") nao herda fake de suite vizinha
	PowerUps.restaurar_padrao()


func after_each() -> void:
	# C665: liberar a Stage dispara body_exited; com carga guardada o resgate nao roda porque o gecko
	# ja encerrou (_p.end) e o handler sai cedo com o corpo fora da arvore
	if is_instance_valid(_p):
		_p.end = true
	get_tree().paused = false
	Global.platforms = _plataformas_original
	Global.iniciado = _iniciado_original
	Global.tutorial_visto_espelho = _tutorial_espelho_original
	Global.sem_derrota = _sem_derrota_original
	Global.cor_gecko = _cor_original
	Global.cor_livre = _cor_livre_original
	Global.pontuacao = _keeper_original
	PowerUps.restaurar_padrao()
	_stage = null
	_p = null


# Stage sem ScrollLevel (sem linhas auto-geradas: as candidatas sao as do teste), regra injetavel e
# gancho de power-ups desligavel antes do add_child (padrao test_stage_regra_modo) e layout fixo
# 360x640. Player parado (fisica desligada, nao pulando): so C660/C662 religam a fisica.
func _novo_stage(regra: GameModeRule = null, power_ups_ligados: bool = true) -> Node:
	_stage = load(STAGE_SCENE).instantiate()
	if regra != null:
		_stage.regra = regra
	if not power_ups_ligados:
		_stage.set("power_ups_habilitados", false)
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
	return _stage


# Partida iniciada pelo caminho oficial do Play (padrao test_power_up_stage.gd)
func _iniciar_partida() -> void:
	_stage.call("_on_Play_button_down")


# Estado de power-up da Stage
func _estado() -> PowerUpState:
	return _stage.get("power_up_estado") as PowerUpState


# Coleta pelo caminho oficial do pouso (o registro de producao resolve segunda_chance, T1)
func _coletar_carga() -> void:
	_stage.call("_coletar_power_up", &"segunda_chance")


# Plataforma estatica e plana de candidatura: cor e posicao do teste, sem piscar/ciclo/desmoronar
func _plataforma(cor: Enums.COLOR, x: float, y: float) -> Platform:
	var plat: Platform = _plataforma_solta(cor, x, y)
	# Teto: a candidata precisa da propria cor na linha de cima (predicado de saida, Q6 c). Marcada desmoronada
	# para nunca ser candidata nem colidir; so cobre a linha de cima da candidata do teste.
	var teto: Platform = _plataforma_solta(cor, x, y - InitialRows.ESPACAMENTO)
	teto.desmoronada = true
	return plat


func _plataforma_solta(cor: Enums.COLOR, x: float, y: float) -> Platform:
	var plat: Platform = load(PLATFORM_SCENE).instantiate()
	plat.set_color(cor)
	add_child_autofree(plat)
	plat.global_position = Vector2(x, y)
	return plat


# Cor diferente da dada (AZUL ou VERDE, a que nao for igual)
func _outra_cor(de: Enums.COLOR) -> Enums.COLOR:
	return Enums.COLOR.AZUL if de != Enums.COLOR.AZUL else Enums.COLOR.VERDE


# N frames de fisica crus pelo sinal da SceneTree: disparam mesmo com a arvore pausada (padrao C553)
func _fisica(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


# Espelho do predicado de T3 com as mesmas entradas que a Stage usa (C656: a posicao esperada vem do
# predicado, nunca recalculada aqui a mao)
func _alvo_esperado(ponto: Vector2) -> Dictionary:
	return SegundaChanceAlvo.escolher(
		ReachableColors.entradas_de_plataformas(Global.platforms),
		ponto,
		int(Global.cor_gecko),
		VISIVEL.x,
		VISIVEL.y,
		_p.scroll_efetivo()
	)


# C655: carga 1 + gecko alem da linha: a partida segue em curso — playing, carga 0, gecko vivo, sem
# som de derrota e sem animacao de derrota
func test_C655_carga_1_queda_mantem_playing_sem_derrota() -> void:
	_stage = await _novo_stage()
	var plat := _plataforma(Global.cor_gecko, 180.0, 120.0)
	_iniciar_partida()
	_coletar_carga()
	assert_eq(_estado().carga(), 1, "fixture: carga guardada")
	_p.global_position = Vector2(X_QUEDA, Y_QUEDA)
	_stage._on_CheckPlayer_body_exited(_p)
	assert_eq(_stage.ultimo_estado["state"], GameState.STATE_PLAYING, "C655: segue playing")
	assert_eq(_estado().carga(), 0, "C655: a carga foi consumida")
	assert_false(_p.is_end(), "C655: o gecko nao encerrou")
	assert_false(_stage.loseaudio.playing, "C655: o som de derrota nao toca")
	assert_ne(_stage.animation.current_animation, "lose_animation", "C655: sem animacao de derrota")
	assert_eq(_p.actual_platform, plat, "C655: o gecko foi para a plataforma de resgate")


# C656: o gecko termina na plataforma escolhida pelo predicado de T3 — da cor dele mesmo com uma de
# outra cor mais perto (posicao esperada espelhada do predicado); no fallback, a de qualquer cor com a
# cor assumida
func test_C656_reaparece_na_plataforma_do_predicado_de_t3() -> void:
	_stage = await _novo_stage()
	_iniciar_partida()
	_coletar_carga()
	var cor_do_gecko: Enums.COLOR = Global.cor_gecko
	# Da cor dele, mais longe; de outra cor, mais perto: a preferencia e pela cor
	var da_cor := _plataforma(cor_do_gecko, 180.0, 120.0)
	var outra := _plataforma(_outra_cor(cor_do_gecko), 180.0, 240.0)
	_p.global_position = Vector2(X_QUEDA, Y_QUEDA)
	var esperada: Dictionary = _alvo_esperado(_p.global_position)
	assert_true(int(esperada["indice"]) >= 0, "fixture: ha candidata")
	assert_eq(esperada["entrada"]["plataforma"], da_cor, "fixture: T3 prefere a da cor do gecko")
	_stage._on_CheckPlayer_body_exited(_p)
	var alvo: Platform = esperada["entrada"]["plataforma"]
	assert_eq(_p.actual_platform, alvo, "C656: o gecko esta na plataforma escolhida por T3")
	assert_eq(_p.global_position.x, alvo.global_position.x, "C656: x da plataforma escolhida")
	assert_almost_eq(_p.global_position.y, _p._y_no_topo(alvo), 0.01, "C656: y no topo da plataforma escolhida")
	assert_ne(_p.actual_platform, outra, "C656: a mais proxima de outra cor foi ignorada")
	_p.end = true
	# Fallback: nenhuma da cor do gecko — a mais proxima de qualquer cor, com a cor assumida
	_stage = await _novo_stage()
	_iniciar_partida()
	_coletar_carga()
	var de_outra := _plataforma(_outra_cor(Global.cor_gecko), 220.0, 180.0)
	_p.global_position = Vector2(X_QUEDA, Y_QUEDA)
	var esperada_2: Dictionary = _alvo_esperado(_p.global_position)
	assert_true(bool(esperada_2["fallback"]), "fixture: sem candidata da cor, T3 devolve fallback")
	_stage._on_CheckPlayer_body_exited(_p)
	assert_eq(_p.actual_platform, de_outra, "C656: fallback termina na mais proxima de qualquer cor")
	assert_eq(_p.color, de_outra.color, "C656: no fallback o gecko assume a cor da plataforma")


# C657: sem carga a derrota padrao e inalterada — state lost e Global.set_score(points) gravando o
# recorde como hoje
func test_C657_sem_carga_derrota_padrao_inalterada() -> void:
	_stage = await _novo_stage()
	_plataforma(Global.cor_gecko, 180.0, 120.0)
	_iniciar_partida()
	_stage.points = 5
	assert_eq(_estado().carga(), 0, "fixture: partida sem carga guardada")
	_p.global_position = Vector2(X_QUEDA, Y_QUEDA)
	_stage._on_CheckPlayer_body_exited(_p)
	assert_eq(_stage.ultimo_estado["state"], GameState.STATE_LOST, "C657: sem carga a partida encerra")
	assert_true(_p.is_end(), "C657: o gecko encerrou")
	assert_eq(Global.get_best_score(), 5, "C657: Global.set_score gravou o recorde como hoje")


# C658: a regra do modo manda primeiro — ao_cair false (regra de teste): a carga nao se gasta e a
# partida nao encerra
func test_C658_regra_ao_cair_false_nao_gasta_carga_nem_encerra() -> void:
	var regra := RegraDeTeste.new()
	regra.cair_encerra = false
	regra.power_ups = true
	_stage = await _novo_stage(regra)
	_plataforma(Global.cor_gecko, 180.0, 120.0)
	_iniciar_partida()
	_coletar_carga()
	assert_eq(_estado().carga(), 1, "fixture: carga guardada")
	_p.global_position = Vector2(X_QUEDA, Y_QUEDA)
	_stage._on_CheckPlayer_body_exited(_p)
	assert_eq(_estado().carga(), 1, "C658: ao_cair false nao gastou a carga")
	assert_false(_p.is_end(), "C658: a partida nao encerrou")
	assert_eq(_p.global_position, Vector2(X_QUEDA, Y_QUEDA), "C658: o gecko nao foi reposicionado")
	assert_ne(_stage.ultimo_estado["state"], GameState.STATE_LOST, "C658: nada publicado como lost")


# C659: carga 1 sem candidata visivel (Q3): derrota padrao e a carga continua guardada
func test_C659_sem_candidata_visivel_derrota_e_carga_fica() -> void:
	_stage = await _novo_stage()
	_iniciar_partida()
	_coletar_carga()
	assert_eq(_estado().carga(), 1, "fixture: carga guardada")
	# Plataforma existe, mas abaixo da borda visivel: nenhuma candidata
	_plataforma(Global.cor_gecko, 180.0, 800.0)
	_p.global_position = Vector2(X_QUEDA, Y_QUEDA)
	_stage._on_CheckPlayer_body_exited(_p)
	assert_eq(_stage.ultimo_estado["state"], GameState.STATE_LOST, "C659: sem candidata vale a derrota padrao")
	assert_eq(_estado().carga(), 1, "C659: a carga nao foi gasta (Q3)")
	assert_true(_p.is_end(), "C659: o gecko encerrou")


# C660: reentrada — queda real por fisica: a 1a salva; os frames seguintes ao reaparecimento nao
# disparam body_exited de novo; a 2a queda real, sem carga, encerra
func test_C660_reentrada_duas_quedas_reais_1a_salva_2a_perde() -> void:
	_stage = await _novo_stage()
	var plat := _plataforma(Global.cor_gecko, 180.0, 120.0)
	_iniciar_partida()
	_coletar_carga()
	_p.set_physics_process(true)
	_p.global_position = Vector2(X_QUEDA, 560.0)
	_p.velocity = Vector2.ZERO
	await wait_until(func() -> bool: return _estado().carga() == 0, 3.0)
	assert_eq(_estado().carga(), 0, "C660: a 1a queda real consumiu a carga (salvou)")
	assert_eq(_stage.ultimo_estado["state"], GameState.STATE_PLAYING, "C660: 1a queda: segue playing")
	assert_false(_p.is_end(), "C660: 1a queda: gecko vivo")
	await _fisica(30)
	assert_eq(
		_stage.ultimo_estado["state"], GameState.STATE_PLAYING, "C660: sem body_exited extra apos o resgate"
	)
	assert_eq(_estado().carga(), 0, "C660: carga segue 0 (nenhum consumo em dobro)")
	assert_true(_p.is_on_floor(), "C660: o gecko ficou na plataforma de resgate")
	assert_eq(_p.actual_platform, plat, "C660: plataforma de resgate")
	_p.global_position = Vector2(X_QUEDA, 560.0)
	_p.velocity = Vector2.ZERO
	await wait_until(
		func() -> bool: return _stage.ultimo_estado["state"] == GameState.STATE_LOST, 3.0
	)
	assert_eq(_stage.ultimo_estado["state"], GameState.STATE_LOST, "C660: a 2a queda real encerra")
	assert_true(_p.is_end(), "C660: 2a queda: gecko encerrado")


# C661: coletar Segunda chance de novo apos gastar volta a guardar 1; partida nova (reload) nasce com
# carga 0
func test_C661_coletar_de_novo_recarrega_e_reload_nasce_zerado() -> void:
	_stage = await _novo_stage()
	_plataforma(Global.cor_gecko, 180.0, 120.0)
	_iniciar_partida()
	_coletar_carga()
	_p.global_position = Vector2(X_QUEDA, Y_QUEDA)
	_stage._on_CheckPlayer_body_exited(_p)
	assert_eq(_estado().carga(), 0, "fixture: a carga foi gasta no resgate")
	_coletar_carga()
	assert_eq(_estado().carga(), 1, "C661: coletar de novo volta a guardar 1")
	# Partida nova: a Stage seguinte nasce com estado zerado (a carga nunca vive em Global)
	_p.end = true
	var area: Area2D = _stage.get_node("CheckPlayer") as Area2D
	var chamada := Callable(_stage, "_on_CheckPlayer_body_exited")
	if area.body_exited.is_connected(chamada):
		area.body_exited.disconnect(chamada)
	_stage.queue_free()
	await _fisica(3)
	_stage = await _novo_stage()
	assert_eq(_estado().carga(), 0, "C661: partida nova nasce com carga 0")


# f526 (06-review Aviso 3): reload da Stage com carga guardada na anterior. A Stage nova nasce com um
# PowerUpState proprio e sem carga (a carga vive no estado da partida, nunca compartilhada entre Stages).
func test_reload_da_stage_nasce_com_carga_zerada_e_estado_proprio() -> void:
	_stage = await _novo_stage()
	_iniciar_partida()
	_coletar_carga()
	var anterior: PowerUpState = _estado()
	assert_eq(anterior.carga(), 1, "fixture: a Stage anterior guarda 1 carga")
	# Reload: a anterior sai de cena (o resgate nao roda: gecko encerrado e body_exited desligado, como no C661)
	_p.end = true
	var area: Area2D = _stage.get_node("CheckPlayer") as Area2D
	var chamada := Callable(_stage, "_on_CheckPlayer_body_exited")
	if area.body_exited.is_connected(chamada):
		area.body_exited.disconnect(chamada)
	_stage.queue_free()
	await _fisica(3)
	_stage = await _novo_stage()
	assert_eq(_estado().carga(), 0, "reload: a Stage nova nasce com carga 0")
	assert_ne(_estado(), anterior, "reload: a Stage nova tem o proprio PowerUpState")
	assert_eq(anterior.carga(), 1, "reload: a carga da Stage anterior nao vazou para ela nem foi consumida")


# C662: pausa — nenhuma fisica roda pausada: a queda pendente nao consumiu a carga nem reposicionou;
# retomada, a queda completa e o resgate acontece
func test_C662_pausa_nao_consome_carga_nem_reposiciona() -> void:
	_stage = await _novo_stage()
	_plataforma(Global.cor_gecko, 180.0, 120.0)
	_iniciar_partida()
	_coletar_carga()
	_p.set_physics_process(true)
	_p.global_position = Vector2(X_QUEDA, 560.0)
	_p.velocity = Vector2.ZERO
	var ponto_pendente: Vector2 = _p.global_position
	assert_true(_stage._pausar(), "fixture: arvore pausada pelo caminho de producao")
	await _fisica(30)
	assert_eq(_p.global_position, ponto_pendente, "C662: pausado o gecko nao caiu (nada reposicionado)")
	assert_eq(_estado().carga(), 1, "C662: pausado a carga nao foi consumida")
	assert_eq(_stage.ultimo_estado["state"], GameState.STATE_PLAYING, "C662: pausado segue playing")
	_stage._retomar()
	await wait_until(func() -> bool: return _estado().carga() == 0, 3.0)
	assert_eq(_estado().carga(), 0, "C662: retomada, a queda completou e o resgate consumiu a carga")
	assert_eq(_stage.ultimo_estado["state"], GameState.STATE_PLAYING, "C662: retomada o resgate seguiu playing")


# C663: power_ups_habilitados = false — a coleta e ignorada (carga nunca existe) e a queda encerra
func test_C663_power_ups_desligados_coleta_ignorada_queda_encerra() -> void:
	_stage = await _novo_stage(null, false)
	_plataforma(Global.cor_gecko, 180.0, 120.0)
	_iniciar_partida()
	_coletar_carga()
	assert_eq(_estado().carga(), 0, "C663: coleta ignorada com o gancho desligado")
	_p.global_position = Vector2(X_QUEDA, Y_QUEDA)
	_stage._on_CheckPlayer_body_exited(_p)
	assert_eq(_stage.ultimo_estado["state"], GameState.STATE_LOST, "C663: sem carga a queda encerra")
	assert_true(_p.is_end(), "C663: o gecko encerrou (a carga nunca existiu)")


# C664: ponte — powerup.carga vai a 0 no mesmo frame do consumo (ultimo_estado, sem esperar fisica)
# e volta a 1 ao coletar de novo
func test_C664_ponte_carga_0_no_mesmo_frame_e_1_ao_coletar_de_novo() -> void:
	_stage = await _novo_stage()
	_plataforma(Global.cor_gecko, 180.0, 120.0)
	_iniciar_partida()
	_coletar_carga()
	await _fisica(2)
	assert_eq(
		int(_stage.ultimo_estado["powerup"]["carga"]), 1, "fixture: a ponte publicou a carga guardada"
	)
	_p.global_position = Vector2(X_QUEDA, Y_QUEDA)
	_stage._on_CheckPlayer_body_exited(_p)
	assert_eq(
		int(_stage.ultimo_estado["powerup"]["carga"]), 0, "C664: carga 0 no mesmo frame do consumo"
	)
	assert_eq(_stage.ultimo_estado["state"], GameState.STATE_PLAYING, "C664: a ponte segue playing")
	_coletar_carga()
	await _fisica(2)
	assert_eq(
		int(_stage.ultimo_estado["powerup"]["carga"]), 1, "C664: coletar de novo devolve 1 na ponte"
	)


# C665: teardown — liberar a Stage com carga guardada nao salva nem gera erro: com o sinal conectado o
# handler sai cedo (gecko encerrado no after_each, corpo fora da arvore)
func test_C665_liberar_stage_com_carga_guardada_nao_salva() -> void:
	_stage = await _novo_stage()
	_plataforma(Global.cor_gecko, 180.0, 120.0)
	_iniciar_partida()
	_coletar_carga()
	# Pior caso: gecko no meio da faixa de derrota na hora da liberacao
	_p.global_position = Vector2(X_QUEDA, 660.0)
	var estado_da_stage: PowerUpState = _estado()
	assert_eq(estado_da_stage.carga(), 1, "fixture: carga guardada na liberacao")
	_p.end = true
	_stage.queue_free()
	await _fisica(3)
	assert_eq(
		estado_da_stage.carga(), 1, "C665: a liberacao nao consumiu a carga (nenhum resgate fantasma)"
	)
