extends GutTest

# f530 T4: a Stage calcula e publica o campo `alvo` da ponte (alvo.alinhado / alvo.dx) na `ultimo_estado`, a
# partir da arvore real (Global.platforms + a plataforma de apoio do gecko), com a MESMA janela de chegada do
# sorteio de cor (tempo_de_pulo(scroll_efetivo) + ESPERA_MAXIMA_S do Player), e republica 1x por mudanca do
# campo sem mover o gecko (a movel da linha de cima andou), nunca por frame sem mudanca. Molde de montagem de
# test_camera_follow_stage.gd (Stage real com arvore, ticks de fisica pela propria Stage) com o ScrollLevel
# removido (padrao de test_stage_segunda_chance.gd): Global.platforms so tem as plataformas do teste,
# posicionadas a mao, para a linha de cima do apoio ser deterministica. O limiar de alinhamento vem das
# constantes + regua do shape do Player (padrao de test_reachable_colors_alvo.gd), nunca do codigo sob teste.
# A cicladora do C809 entra por um stand-in Node2D em Global.platforms respondendo obter_ciclo() com o
# modificador REAL PlatformColorCycle: a instalacao do ciclo numa Platform e do gerador de linhas; o contrato
# que a Stage consome (entradas_de_plataformas -> obter_ciclo -> filtro de janela) roda por inteiro.

const STAGE_SCENE := "res://scenes/Stage.tscn"
const PLATFORM_SCENE := "res://scenes/Platform.tscn"
const PlayerFisica := preload("res://scenes/Player.gd")
const VISIVEL := Vector2(180.0, 320.0)
const SAFE := Rect2(0.0, 0.0, 180.0, 320.0)
const TICK := 1.0 / 60.0
const SEED := 20261123
# Linha do apoio: a linha de cima fica a InitialRows.ESPACAMENTO acima (a mesma tolerancia do coletor)
const Y_APOIO := 240.0

var _stage: Node = null
var _p: Node = null
var _meia_corpo := 0.0
var _plataformas_original: Array = []
var _iniciado_original := false
var _tutorial_espelho_original := false
var _cor_original: Enums.COLOR
var _keeper_original: ScoreKeeper


# Stand-in de cicladora: o minimo que entradas_de_plataformas le de uma plataforma (posicao, cor e o ciclo),
# entregando o modificador real PlatformColorCycle pelo mesmo contrato de obter_ciclo.
class CicladoraStandIn:
	extends Node2D
	var color: int = Enums.COR_INICIAL
	var ciclo: PlatformColorCycle = null

	func obter_ciclo() -> PlatformColorCycle:
		return ciclo


func before_all() -> void:
	_meia_corpo = _medir_meia_corpo()


func before_each() -> void:
	_plataformas_original = Global.platforms
	_iniciado_original = Global.iniciado
	_tutorial_espelho_original = Global.tutorial_visto_espelho
	_cor_original = Global.cor_gecko
	Global.tutorial_visto_espelho = true
	Global.platforms = []
	Global.iniciado = false
	_keeper_original = Global.pontuacao
	Global.pontuacao = ScoreKeeper.new()


func after_each() -> void:
	if is_instance_valid(_p):
		_p.end = true
	get_tree().paused = false
	Global.platforms = _plataformas_original
	Global.iniciado = _iniciado_original
	Global.tutorial_visto_espelho = _tutorial_espelho_original
	Global.cor_gecko = _cor_original
	Global.pontuacao = _keeper_original
	_stage = null
	_p = null


# Regua independente da producao (padrao de test_reachable_colors_alvo.gd): meia-largura do corpo do gecko
# lida do shape de colisao da cena do Player.
func _medir_meia_corpo() -> float:
	var player: Node = load("res://scenes/Player.tscn").instantiate()
	var forma: RectangleShape2D = (
		player.get_node("CollisionShape2D") as CollisionShape2D
	).shape as RectangleShape2D
	var meia: float = forma.size.x / 2.0
	player.free()
	return meia


# Limiar de alinhamento do pouso reto: meia-largura do apoio + meia-largura do corpo, das constantes e da regua.
func _limiar() -> float:
	return float(MovingRowFill.SEMI_PLATAFORMA) + _meia_corpo


# Stage real sem ScrollLevel (as plataformas sao as do teste: sem o gerador de linhas a linha de cima do apoio
# e deterministica), layout 180x320 e partida iniciada pelo caminho do Play. Player parado: so o campo `alvo`
# e a posicao movem o estado publicado.
func _novo_stage(alvo_ativo: bool = true) -> Node:
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
	# o GUT roda em headless (a ponte nao publica); liga o calculo do campo como no web debug
	if alvo_ativo:
		_stage._alvo_ativo = true
	_stage._on_Play_button_down()
	return _stage


func _plataforma(cor: Enums.COLOR, x: float, y: float) -> Platform:
	var plat: Platform = load(PLATFORM_SCENE).instantiate()
	plat.set_color(cor)
	add_child_autofree(plat)
	plat.global_position = Vector2(x, y)
	return plat


func _y_linha_de_cima() -> float:
	return Y_APOIO - InitialRows.ESPACAMENTO


# Gecko no chao sobre o apoio (no x dado): actual_platform apontando e o corpo no topo do shape dele.
func _no_chao(apoio: Platform, x: float) -> void:
	_p.actual_platform = apoio
	_p.global_position = Vector2(x, _p._y_no_topo(apoio))
	_p.velocity = Vector2.ZERO


func _tick(n: int = 1) -> void:
	for i in n:
		_stage._physics_process(TICK)


func _alvo_publicado() -> Dictionary:
	return _stage.ultimo_estado["alvo"] as Dictionary


# C805: no chao sobre a plataforma de apoio com alvo da cor alinhado -> alinhado true; desalinhado alem do
# limiar -> false com o dx do sinal do lado do alvo; sem alvo da cor -> false/0.
func test_C805_no_chao_publica_alinhado_desalinhado_e_sem_alvo() -> void:
	_stage = await _novo_stage()
	var cor: Enums.COLOR = Global.cor_gecko
	var outra: Enums.COLOR = Enums.COLOR.AZUL if cor != Enums.COLOR.AZUL else Enums.COLOR.VERDE
	var apoio := _plataforma(cor, 90.0, Y_APOIO)
	var alvo := _plataforma(cor, 90.0, _y_linha_de_cima())
	_no_chao(apoio, 90.0)
	_tick()
	assert_eq(_alvo_publicado()["alinhado"], true, "C805: no chao com alvo da cor em cima do gecko: alinhado true")
	assert_eq(_alvo_publicado()["dx"], 0, "C805: alinhado em cima: dx 0")
	# desalinhado alem do limiar: false e o dx com o sinal do lado (alvo a direita = positivo)
	_no_chao(apoio, 90.0 - _limiar() - 10.0)
	_tick()
	assert_eq(_alvo_publicado()["alinhado"], false, "C805: desalinhado alem do limiar: false")
	assert_eq(
		int(_alvo_publicado()["dx"]), int(roundi(_limiar() + 10.0)), "C805: alvo a direita: dx positivo"
	)
	# espelhado: alvo a esquerda do gecko
	_no_chao(apoio, 90.0 + _limiar() + 10.0)
	_tick()
	assert_eq(_alvo_publicado()["alinhado"], false, "C805: espelhado tambem desalinhado")
	assert_eq(
		int(_alvo_publicado()["dx"]), -int(roundi(_limiar() + 10.0)), "C805: alvo a esquerda: dx negativo"
	)
	# sem alvo: a unica da linha de cima passa a ser de outra cor
	alvo.set_color(outra)
	_no_chao(apoio, 90.0)
	_tick()
	assert_eq(_alvo_publicado()["alinhado"], false, "C805: sem alvo da cor na linha de cima: false")
	assert_eq(_alvo_publicado()["dx"], 0, "C805: sem alvo: dx 0")


# Correcao f530: em release/headless/desktop (sem web debug) a Stage nao varre as plataformas: com o alvo alinhado
# montado na arvore, o campo publicado fica no padrao e nenhum tick republica por causa dele.
func test_headless_nao_calcula_alvo_e_publica_o_padrao() -> void:
	_stage = await _novo_stage(false)
	assert_false(
		_stage._alvo_ativo,
		"o GUT roda em headless: o calculo do alvo nasce desligado (o mesmo decisor de GameState.publish)"
	)
	var cor: Enums.COLOR = Global.cor_gecko
	var apoio := _plataforma(cor, 90.0, Y_APOIO)
	_plataforma(cor, 90.0, _y_linha_de_cima())
	_no_chao(apoio, 90.0)
	_tick()
	assert_eq(
		_stage._alvo_atual(GameState.STATE_PLAYING),
		{"alinhado": false, "dx": 0},
		"sem web debug o alvo nao e calculado mesmo alinhado na arvore"
	)
	assert_eq(_alvo_publicado(), {"alinhado": false, "dx": 0}, "o campo publicado fica no padrao")
	var publicado: Dictionary = _stage.ultimo_estado
	_tick(20)
	assert_same(_stage.ultimo_estado, publicado, "nenhum tick republica por causa do alvo")
	_stage._alvo_ativo = true
	assert_eq(
		_stage._alvo_atual(GameState.STATE_PLAYING)["alinhado"], true, "controle: ligado, o mesmo cenario alinha"
	)


# C806: gecko no ar (sem plataforma de apoio) ou state != playing: alinhado false e dx 0 mesmo com o alvo
# alinhado montado na arvore.
func test_C806_no_ar_e_fora_de_playing_publicam_false_zero_com_alvo_na_arvore() -> void:
	_stage = await _novo_stage()
	var cor: Enums.COLOR = Global.cor_gecko
	var apoio := _plataforma(cor, 90.0, Y_APOIO)
	_plataforma(cor, 90.0, _y_linha_de_cima())
	_no_chao(apoio, 90.0)
	_tick()
	assert_eq(_alvo_publicado()["alinhado"], true, "fixture: no chao o alvo alinhado publica true")
	# no ar: o pulo derruba o actual_platform -> false/0 sem olhar a arvore
	_p.actual_platform = null
	_tick()
	assert_eq(_alvo_publicado()["alinhado"], false, "C806: no ar: alinhado false")
	assert_eq(_alvo_publicado()["dx"], 0, "C806: no ar: dx 0")
	# fora de playing: a queda publica lost com o alvo montado e o gecko de volta no chao
	_no_chao(apoio, 90.0)
	_tick()
	assert_eq(_alvo_publicado()["alinhado"], true, "fixture: de volta ao chao o alvo volta a alinhar")
	_stage._on_CheckPlayer_body_exited(_p)
	assert_eq(_stage.ultimo_estado["state"], GameState.STATE_LOST, "fixture: a queda encerrou a partida")
	assert_eq(_alvo_publicado()["alinhado"], false, "C806: state != playing: alinhado false")
	assert_eq(_alvo_publicado()["dx"], 0, "C806: state != playing: dx 0")


# C807: o campo muda sem mover o gecko (a movel da linha de cima andou): republica 1x; sem mudanca em frames
# seguintes, nada publica (o gatilho nunca e por frame).
func test_C807_republica_por_mudanca_do_alvo_sem_mover_o_gecko_e_nada_por_frame() -> void:
	_stage = await _novo_stage()
	var cor: Enums.COLOR = Global.cor_gecko
	var apoio := _plataforma(cor, 90.0, Y_APOIO)
	var movel := _plataforma(cor, 150.0, _y_linha_de_cima())
	movel.set_speed(80)
	_no_chao(apoio, 90.0)
	_tick()
	var publicado: Dictionary = _stage.ultimo_estado
	var dx_antes: int = int(_alvo_publicado()["dx"])
	var pos_publicada: Vector2i = _stage._posicao_publicada
	# estabilizado: nenhum novo dicionario em 20 ticks
	_tick(20)
	assert_same(_stage.ultimo_estado, publicado, "C807: sem mudanca do campo, nenhum tick republica")
	# a movel andou sem tocar o gecko: o dx previsto muda e a Stage republica 1x
	movel.global_position.x += 3.0
	_tick()
	assert_not_same(_stage.ultimo_estado, publicado, "C807: mudanca do alvo sem mover o gecko republica")
	assert_eq(int(_alvo_publicado()["dx"]), dx_antes + 3, "C807: o dx publicado acompanhou a movel")
	assert_eq(
		_stage._posicao_publicada, pos_publicada, "C807: player.x/y publicados inalterados (o gecko nao andou)"
	)
	# estabilizou de novo: nada por frame
	var apos_mudanca: Dictionary = _stage.ultimo_estado
	_tick(20)
	assert_same(_stage.ultimo_estado, apos_mudanca, "C807: sem nova mudanca, nenhum tick republica")


# C808: os demais campos do ultimo_estado nao mudam com o campo alvo: fora da chave "alvo" o dicionario
# publicado e o mesmo entre duas publicacoes que so divergem no alvo.
func test_C808_alvo_nao_altera_os_demais_campos_do_ultimo_estado() -> void:
	_stage = await _novo_stage()
	var cor: Enums.COLOR = Global.cor_gecko
	var apoio := _plataforma(cor, 90.0, Y_APOIO)
	_no_chao(apoio, 90.0)
	_tick()
	# sem alvo na linha de cima: o campo sai no padrao
	var sem_alvo: Dictionary = _stage.ultimo_estado.duplicate()
	sem_alvo.erase("alvo")
	assert_eq(_alvo_publicado(), {"alinhado": false, "dx": 0}, "fixture: sem alvo, o campo publicado e o padrao")
	# o alvo entra na linha de cima: so a chave alvo diverge entre as publicacoes
	_plataforma(cor, 90.0, _y_linha_de_cima())
	_tick()
	var com_alvo: Dictionary = _stage.ultimo_estado.duplicate()
	com_alvo.erase("alvo")
	assert_eq(_alvo_publicado()["alinhado"], true, "fixture: com o alvo montado, alinhado true")
	assert_eq(com_alvo, sem_alvo, "C808: fora da chave alvo o dicionario publicado e o mesmo")
	assert_eq(
		(_stage.ultimo_estado["player"] as Dictionary)["x"],
		int(roundi(_p.global_position.x)),
		"C808: player.x segue o par arredondado do gecko"
	)
	assert_eq(
		(_stage.ultimo_estado["player"] as Dictionary)["y"],
		int(roundi(_p.global_position.y)),
		"C808: player.y segue o par arredondado do gecko"
	)


# C809: a janela de chegada do campo e a do sorteio de cor (tempo_de_pulo(scroll_efetivo) + ESPERA_MAXIMA_S):
# com scroll alto, a cicladora da cor que troca DENTRO da janela longa fica de fora — uma foto do instante
# (dt 0) a teria contado. O controle (troca depois do fim da janela) prova que a cicladora entra no calculo.
func test_C809_com_scroll_alto_cicladora_que_troca_na_janela_de_chegada_fica_de_fora() -> void:
	_stage = await _novo_stage()
	var cor: Enums.COLOR = Global.cor_gecko
	var apoio := _plataforma(cor, 90.0, Y_APOIO)
	_no_chao(apoio, 90.0)
	# scroll alto: o ultimo estagio da curva de producao
	_stage.dificuldade.progresso_inicial = 1.0
	_tick()
	var base := DifficultyState.new(_stage.CURVA_DIFICULDADE)
	var scroll_base: float = DifficultySnapshot.de(base).get_scroll()
	var dt: float = ReachableColors.tempo_de_pulo(_p.scroll_efetivo())
	assert_gt(_p.scroll_efetivo(), scroll_base, "fixture: scroll do ultimo estagio acima do estagio 0")
	assert_gt(_p.scroll_efetivo(), 0.0, "fixture: scroll vigente positivo")
	assert_lt(dt, ReachableColors.tempo_de_pulo(0.0), "fixture: o scroll adianta a chegada (dt < dt sem scroll)")
	# cicladora da cor em cima do gecko, trocando dentro de [dt, dt + ESPERA_MAXIMA_S]
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var troca_na_janela := PlatformColorCycle.new()
	troca_na_janela.iniciar(int(cor), PlayerFisica.ESPERA_MAXIMA_S + dt / 2.0, rng)
	assert_ne(
		troca_na_janela.cor_em(dt),
		troca_na_janela.cor_em(dt + PlayerFisica.ESPERA_MAXIMA_S),
		"fixture: a cicladora troca de cor dentro da janela de chegada"
	)
	var na_janela: Node2D = add_child_autofree(CicladoraStandIn.new())
	na_janela.color = int(cor)
	na_janela.ciclo = troca_na_janela
	na_janela.global_position = Vector2(90.0, _y_linha_de_cima())
	Global.platforms.append(na_janela)
	_stage._republicar_estado()
	assert_eq(
		_alvo_publicado()["alinhado"],
		false,
		"C809: cicladora que troca na janela de chegada e excluida (a janela longa vale, nao a foto do instante)"
	)
	assert_eq(_alvo_publicado()["dx"], 0, "C809: sem elegivel na janela: dx 0")
	# controle: a MESMA cor com a troca alem do fim da janela cobre [dt, dt + espera] e e elegivel
	var troca_depois := PlatformColorCycle.new()
	troca_depois.iniciar(int(cor), dt + PlayerFisica.ESPERA_MAXIMA_S + 2.0, rng)
	var fora_da_janela: Node2D = add_child_autofree(CicladoraStandIn.new())
	fora_da_janela.color = int(cor)
	fora_da_janela.ciclo = troca_depois
	fora_da_janela.global_position = Vector2(92.0, _y_linha_de_cima())
	Global.platforms.append(fora_da_janela)
	_stage._republicar_estado()
	assert_eq(_alvo_publicado()["alinhado"], true, "C809: o controle prova que as cicladoras entram no calculo")
	assert_eq(int(_alvo_publicado()["dx"]), 2, "C809: elegivel a 2 px: o dx da mais proxima elegivel")
