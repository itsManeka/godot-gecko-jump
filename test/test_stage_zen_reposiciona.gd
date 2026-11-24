extends GutTest

# f527 T4: no Zen a queda reposiciona o gecko na ultima plataforma pisada (a do ultimo ponto), sem derrota, sem
# ponto e sem carga; a cor assumida e a da plataforma-alvo (D4); sem pisada ou com a ultima liberada vale a escolha
# da Segunda chance (D3). Cenarios C721-C729 do 05-test-plan. Molde de setup: test_stage_segunda_chance.gd (Stage
# sem ScrollLevel, layout 180x320, queda pelo handler da linha de derrota).

const STAGE_SCENE := "res://scenes/Stage.tscn"
const PLATFORM_SCENE := "res://scenes/Platform.tscn"
const VISIVEL := Vector2(180.0, 320.0)
const SAFE := Rect2(0.0, 0.0, 180.0, 320.0)
const QUEDA := Vector2(20.0, 360.0)

var _stage: Node = null
var _p: Node = null
var _plataformas_original: Array = []
var _iniciado_original := false
var _tutorial_espelho_original := false
var _cor_original: Enums.COLOR
var _keeper_original: ScoreKeeper


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
	PowerUps.restaurar_padrao()


func after_each() -> void:
	if is_instance_valid(_p):
		_p.end = true
	get_tree().paused = false
	Global.platforms = _plataformas_original
	Global.iniciado = _iniciado_original
	Global.tutorial_visto_espelho = _tutorial_espelho_original
	Global.cor_gecko = _cor_original
	Global.pontuacao = _keeper_original
	PowerUps.restaurar_padrao()
	_stage = null
	_p = null


func _novo_stage(regra: GameModeRule) -> Node:
	_stage = load(STAGE_SCENE).instantiate()
	_stage.regra = regra
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
	_stage._on_Play_button_down()
	return _stage


# Plataforma estatica com um teto desmoronado na linha de cima (so cobre o predicado de saida da candidata)
func _plataforma(cor: Enums.COLOR, x: float, y: float) -> Platform:
	var plat: Platform = _solta(cor, x, y)
	var teto: Platform = _solta(cor, x, y - InitialRows.ESPACAMENTO)
	teto.desmoronada = true
	return plat


func _solta(cor: Enums.COLOR, x: float, y: float) -> Platform:
	var plat: Platform = load(PLATFORM_SCENE).instantiate()
	plat.set_color(cor)
	add_child_autofree(plat)
	plat.global_position = Vector2(x, y)
	return plat


func _outra_cor(de: Enums.COLOR) -> Enums.COLOR:
	return Enums.COLOR.AZUL if de != Enums.COLOR.AZUL else Enums.COLOR.VERDE


# Pouso pelo caminho do sinal do Player: o ponto guarda a plataforma pisada
func _pisar(plat: Platform) -> void:
	_p.actual_platform = plat
	_p.add_point.emit()


func _cair(ponto: Vector2 = QUEDA) -> void:
	_p.global_position = ponto
	_stage._on_CheckPlayer_body_exited(_p)


func _fisica(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _no_topo(plat: Platform) -> void:
	assert_eq(_p.global_position.x, plat.global_position.x, "x da plataforma-alvo")
	assert_almost_eq(_p.global_position.y, _p._y_no_topo(plat), 0.01, "y no topo da plataforma-alvo")
	assert_eq(_p.velocity, Vector2.ZERO, "velocity zerada")


# C721
func test_C721_zen_queda_reposiciona_no_topo_da_ultima_plataforma() -> void:
	await _novo_stage(ZenRule.new())
	var plat := _plataforma(Global.cor_gecko, 90.0, 120.0)
	_pisar(plat)
	_p.velocity = Vector2(30.0, 200.0)
	_cair()
	assert_false(_p.is_end(), "C721: o gecko nao encerrou")
	assert_eq(_stage.ultimo_estado["state"], GameState.STATE_PLAYING, "C721: a partida segue playing")
	assert_eq(_p.actual_platform, plat, "C721: o gecko esta na plataforma pisada")
	_no_topo(plat)


# C722
func test_C722_zen_reposicionar_nao_pontua_nem_grava_recorde() -> void:
	await _novo_stage(ZenRule.new())
	var plat := _plataforma(Global.cor_gecko, 90.0, 120.0)
	_pisar(plat)
	_pisar(plat)
	var pontos: int = _stage.points
	var recorde: int = Global.get_best_score()
	assert_gt(pontos, 0, "fixture: ha pontos antes da queda")
	_cair()
	assert_eq(_stage.points, pontos, "C722: points identico apos a queda (sem ponto pelo reposicionamento)")
	assert_eq(Global.get_best_score(), recorde, "C722: o recorde do Zen nao mudou")
	await _fisica(3)
	assert_eq(_stage.points, pontos, "C722: points segue identico depois de frames de fisica")


# C723
func test_C723_zen_reposiciona_na_ultima_pisada_nao_na_mais_proxima() -> void:
	await _novo_stage(ZenRule.new())
	var a := _plataforma(Global.cor_gecko, 40.0, 200.0)
	var b := _plataforma(Global.cor_gecko, 140.0, 100.0)
	_pisar(a)
	_pisar(b)
	_cair()
	assert_eq(_p.actual_platform, b, "C723: reposiciona na ultima pisada (B), nao em A (a mais proxima da queda)")
	_no_topo(b)


# C724
func test_C724_zen_queda_sem_pouso_cai_no_fallback_da_segunda_chance() -> void:
	await _novo_stage(ZenRule.new())
	var plat := _plataforma(_outra_cor(Global.cor_gecko), 90.0, 120.0)
	var esperada: Dictionary = SegundaChanceAlvo.escolher(
		ReachableColors.entradas_de_plataformas(Global.platforms),
		QUEDA,
		int(Global.cor_gecko),
		VISIVEL.x,
		VISIVEL.y,
		_p.scroll_efetivo()
	)
	assert_eq(esperada["entrada"]["plataforma"], plat, "fixture: o predicado escolhe a plataforma")
	_cair()
	assert_false(_p.is_end(), "C724: a partida segue")
	assert_eq(_p.actual_platform, plat, "C724: o gecko foi para a escolhida por SegundaChanceAlvo")
	assert_eq(_p.color, plat.color, "C724: o gecko assumiu a cor dela")
	_no_topo(plat)


# C725
func test_C725_zen_ultima_plataforma_liberada_cai_no_fallback() -> void:
	await _novo_stage(ZenRule.new())
	var velha := _plataforma(Global.cor_gecko, 40.0, 200.0)
	var viva := _plataforma(Global.cor_gecko, 140.0, 120.0)
	_pisar(velha)
	velha.free()
	_cair()
	assert_false(_p.is_end(), "C725: sem crash e sem derrota")
	assert_eq(_p.actual_platform, viva, "C725: caiu na plataforma viva escolhida pelo fallback")
	_no_topo(viva)


# C726
func test_C726_zen_duas_quedas_seguidas_reposicionam_as_duas_vezes() -> void:
	await _novo_stage(ZenRule.new())
	var plat := _plataforma(Global.cor_gecko, 90.0, 120.0)
	_pisar(plat)
	_cair()
	_no_topo(plat)
	_cair(Vector2(60.0, 380.0))
	assert_eq(_stage.ultimo_estado["state"], GameState.STATE_PLAYING, "C726: playing apos a 2a queda")
	assert_false(_p.is_end(), "C726: o gecko segue vivo")
	_no_topo(plat)


# C727
func test_C727_zen_gecko_assume_a_cor_da_plataforma_alvo_e_fica_sobre_ela() -> void:
	await _novo_stage(ZenRule.new())
	var cor_alvo: Enums.COLOR = _outra_cor(_p.color)
	var plat := _plataforma(cor_alvo, 90.0, 120.0)
	_pisar(plat)
	var cor_antes: int = int(_p.color)
	assert_ne(cor_antes, int(cor_alvo), "fixture: o gecko tem cor diferente da plataforma")
	_cair()
	assert_eq(int(_p.color), int(cor_alvo), "C727: o gecko reaparece com a cor da plataforma-alvo")
	_p.set_physics_process(true)
	await _fisica(3)
	assert_true(_p.is_on_floor(), "C727: o gecko nao atravessou a plataforma")
	assert_eq(_p.actual_platform, plat, "C727: segue sobre a plataforma-alvo")
	assert_almost_eq(_p.global_position.y, _p._y_no_topo(plat), 1.5, "C727: y no topo depois de 1 passo de fisica")


# C728
func test_C728_zen_queda_com_gecko_pulando_segue_ignorada() -> void:
	await _novo_stage(ZenRule.new())
	var plat := _plataforma(Global.cor_gecko, 90.0, 120.0)
	_pisar(plat)
	_p.jumping = true
	_cair()
	assert_eq(_p.global_position, QUEDA, "C728: pulando, o gecko nao foi reposicionado")
	assert_false(_p.is_end(), "C728: nem encerrado")


# Correcao 2 (06-review Aviso #1): sem ultima plataforma valida e sem candidata da Segunda chance, o gecko reaparece
# sobre a plataforma existente mais proxima (qualquer cor) em vez de seguir caindo com a partida presa.
func test_zen_sem_candidata_visivel_reaparece_na_plataforma_mais_proxima() -> void:
	await _novo_stage(ZenRule.new())
	var longe := _solta(_outra_cor(Global.cor_gecko), 150.0, 100.0)
	var perto := _solta(_outra_cor(Global.cor_gecko), 30.0, 300.0)
	var escolha: Dictionary = SegundaChanceAlvo.escolher(
		ReachableColors.entradas_de_plataformas(Global.platforms),
		QUEDA,
		int(Global.cor_gecko),
		VISIVEL.x,
		VISIVEL.y,
		_p.scroll_efetivo()
	)
	assert_eq(int(escolha["indice"]), -1, "fixture: o predicado da Segunda chance nao acha candidata")
	_cair()
	assert_false(_p.is_end(), "ramo sem candidata: a partida segue")
	assert_eq(_stage.ultimo_estado["state"], GameState.STATE_PLAYING, "ramo sem candidata: playing")
	assert_eq(_p.actual_platform, perto, "ramo sem candidata: reaparece na mais proxima da queda, nao em %s" % longe.name)
	assert_eq(int(_p.color), int(perto.color), "ramo sem candidata: assume a cor dela")
	_no_topo(perto)


func test_zen_sem_nenhuma_plataforma_nao_encerra_nem_quebra() -> void:
	await _novo_stage(ZenRule.new())
	_cair()
	assert_false(_p.is_end(), "sem plataforma alguma: sem derrota")
	assert_eq(_p.global_position, QUEDA, "sem plataforma alguma: nada a fazer, o gecko nao foi movido")


# C729
func test_C729_classico_puro_e_tempo_seguem_encerrando_na_queda() -> void:
	var regras: Array = [ClassicoRule.new(), PuroRule.new(), TempoRule.new()]
	for regra in regras:
		await _novo_stage(regra)
		var plat := _plataforma(Global.cor_gecko, 90.0, 120.0)
		_pisar(plat)
		_cair()
		assert_true(_p.is_end(), "C729: %s encerra na queda" % regra.get_script().resource_path)
		assert_eq(_stage.ultimo_estado["state"], GameState.STATE_LOST, "C729: derrota no modo")
		_stage.queue_free()
		await _fisica(2)
		Global.iniciado = false
