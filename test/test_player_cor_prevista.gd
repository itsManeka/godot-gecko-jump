extends GutTest

# Pouso com a cor prevista: o Player recebe a dificuldade da Stage e sorteia a nova cor entre as que a linha de cima
# tera na janela de chegada (pulo + espera maxima), nao so entre as do instante do pouso.
const PLAYER := "res://scenes/Player.tscn"
const PLATAFORMA := "res://scenes/Platform.tscn"
const STAGE_SCENE := "res://scenes/Stage.tscn"
const SEMENTES := 60
const Y_BAIXO := 200.0
const Y_CIMA := Y_BAIXO - InitialRows.ESPACAMENTO

var _sv: SubViewport
var _p: Node
var _sem_derrota_original: bool


func before_each() -> void:
	_sem_derrota_original = Global.sem_derrota
	Global.platforms = []
	Global.iniciado = false
	Global.tutorial_visto_espelho = true
	_sv = SubViewport.new()
	_sv.size = Vector2i(180, 320)
	add_child_autofree(_sv)
	_p = load(PLAYER).instantiate()
	_sv.add_child(_p)
	_p.set_physics_process(false)
	_p.set_process(false)


func after_each() -> void:
	Global.sem_derrota = _sem_derrota_original
	Global.platforms = []
	Global.iniciado = false


func _plataforma(y: float, x: float, cor: int) -> Platform:
	var pl: Platform = load(PLATAFORMA).instantiate()
	_sv.add_child(pl)
	pl.set_physics_process(false)
	pl.position = Vector2(x, y)
	pl.set_color(cor)
	return pl


func _rng(semente: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	return rng


# Cicladora na linha de cima: cor atual = sequencia[0]; a fase avanca para a troca (sequencia[0] -> [1]) cair em
# `troca_em` s a partir de agora. Devolve o ciclo (cores em get_sequencia()).
func _cicladora_na_linha_de_cima(periodo: float, troca_em: float) -> PlatformColorCycle:
	var ciclo := PlatformColorCycle.new()
	ciclo.iniciar(Enums.COLOR.AMARELO, periodo, _rng(11))
	var pl: Platform = load(PLATAFORMA).instantiate()
	pl.definir_modificadores([ciclo], DifficultySnapshot.new())
	_sv.add_child(pl)
	pl.set_physics_process(false)
	pl.position = Vector2(40.0, Y_CIMA)
	pl.set_color(ciclo.cor_atual())
	ciclo.ao_processar(pl, periodo - troca_em)
	return ciclo


func _pousar(alvo: Platform, semente: int) -> int:
	_p.actual_platform = alvo
	_p.rng = _rng(semente)
	_p.change_color_random()
	return _p.color


func test_cor_sorteada_no_pouso_e_a_da_janela_de_chegada_e_nao_a_do_instante_do_pouso() -> void:
	_p.dificuldade = DifficultyState.new()
	var dt: float = ReachableColors.tempo_de_pulo(DifficultySnapshot.de(_p.dificuldade).get_scroll())
	var base := _plataforma(Y_BAIXO, 90.0, Enums.COLOR.AZUL)
	# Troca X -> Y em dt/2 (antes da chegada); a proxima so em 1,5 dt + 1: a janela [dt, dt + espera] e toda da cor Y
	var ciclo := _cicladora_na_linha_de_cima(dt + 1.0, dt / 2.0)
	var cor_agora: int = ciclo.cor_atual()
	var cor_na_chegada: int = ciclo.cor_em(dt)
	assert_ne(cor_agora, cor_na_chegada, "fixture: a cor muda antes da chegada")
	assert_eq(ciclo.cor_em(dt + _p.ESPERA_MAXIMA_S), cor_na_chegada, "fixture: a janela inteira e da cor de chegada")
	for semente in range(1, SEMENTES + 1):
		assert_eq(_pousar(base, semente), cor_na_chegada, "so a cor da chegada e candidata, nunca a do pouso")


func test_player_isolado_sem_dificuldade_usa_dt_zero_e_cor_do_instante() -> void:
	assert_null(_p.dificuldade, "Player isolado nasce sem dificuldade")
	var base := _plataforma(Y_BAIXO, 90.0, Enums.COLOR.AZUL)
	var ciclo := _cicladora_na_linha_de_cima(4.0, 1.0)
	for semente in range(1, SEMENTES + 1):
		assert_eq(_pousar(base, semente), ciclo.cor_atual(), "dt 0: vale a cor do instante do pouso, como antes")


func test_sem_derrota_segue_com_a_cor_inicial_mesmo_com_dificuldade() -> void:
	Global.sem_derrota = true
	_p.dificuldade = DifficultyState.new()
	var base := _plataforma(Y_BAIXO, 90.0, Enums.COLOR.AZUL)
	_cicladora_na_linha_de_cima(4.0, 1.0)
	for semente in range(1, 10):
		assert_eq(_pousar(base, semente), Enums.COR_INICIAL, "sem_derrota: set_color(COR_INICIAL), sem sorteio")


func test_stage_injeta_no_player_a_mesma_dificuldade_do_scroll_level() -> void:
	var stage: Node = add_child_autofree(load(STAGE_SCENE).instantiate())
	assert_not_null(stage.dificuldade, "a Stage cria a dificuldade")
	assert_same(stage.player.dificuldade, stage.dificuldade, "o Player le a mesma instancia que o ScrollLevel")
	assert_same(stage.get_node("ScrollLevel").dificuldade, stage.dificuldade, "o ScrollLevel segue com a mesma")
	var scroll_inicial: float = DifficultySnapshot.de(stage.player.dificuldade).get_scroll()
	stage.dificuldade.progresso_inicial = 1.0
	var scroll_vigente: float = DifficultySnapshot.de(stage.player.dificuldade).get_scroll()
	assert_ne(scroll_vigente, scroll_inicial, "o scroll vigente (e o dt_chegada) acompanha a dificuldade da partida")
