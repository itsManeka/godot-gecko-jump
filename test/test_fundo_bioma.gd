extends GutTest

# f559 T6: bioma do fundo por estagio com crossfade e sorteio no Zen. Tempo determinista (avancar_crossfade com delta
# fixo, sem Tween); o sinal estagio_mudou do DifficultyState real e emitido a mao; o sorteio do Zen usa um
# RandomNumberGenerator injetado cuja seed e achada pela propria engine (valores esperados escritos a mao).
const STAGE := "res://scenes/Stage.tscn"
const LARGURA := 360
const EPS := 0.001
var _sv: SubViewport
var _stage: Node
var _p: Node


func before_each() -> void:
	Global.tutorial_visto_espelho = true
	Global.platforms = []
	Global.iniciado = false
	Global.progresso_inicial = 0.0


func after_each() -> void:
	get_tree().paused = false
	if is_instance_valid(_p):
		_p.end = true
	Global.set_modo_jogo(GameModes.ID_CLASSICO)
	Global.platforms = []
	Global.iniciado = false
	Global.progresso_inicial = 0.0


# Stage real em SubViewport 360x640; fisica desligada (os testes dirigem o fundo a mao)
func _spawn_stage(regra: GameModeRule, rng: RandomNumberGenerator = null) -> void:
	_sv = SubViewport.new()
	_sv.size = Vector2i(LARGURA, 640)
	add_child_autofree(_sv)
	_stage = load(STAGE).instantiate()
	_stage.regra = regra
	_stage.fundo_rng = rng
	_sv.add_child(_stage)
	_p = _stage.get_node("Node2D/Player")
	(_stage.get_node("ScrollLevel") as ScrollLevel).set_physics_process(false)
	_p.set_physics_process(false)
	_stage.set_physics_process(false)
	await wait_process_frames(1)


func _descartar_stage() -> void:
	_p.end = true
	_sv.queue_free()
	await wait_process_frames(1)
	Global.iniciado = false


# RandomNumberGenerator com seed tal que as chamadas randi_range(0, 3) seguintes devolvem `valores` em ordem
func _rng_para(valores: Array) -> RandomNumberGenerator:
	for semente in range(1, 200000):
		var sonda := RandomNumberGenerator.new()
		sonda.seed = semente
		var ok: bool = true
		for v: int in valores:
			if sonda.randi_range(0, FundoBiomas.QUANTIDADE - 1) != v:
				ok = false
				break
		if ok:
			var rng := RandomNumberGenerator.new()
			rng.seed = semente
			return rng
	return null


func _opacidades() -> Array[float]:
	var lista: Array[float] = []
	for g in range(FundoBiomas.QUANTIDADE):
		lista.append(_stage.fundo.opacidade(g))
	return lista


func _so_o_bioma(bioma: int) -> Array[float]:
	var lista: Array[float] = [0.0, 0.0, 0.0, 0.0]
	lista[bioma] = 1.0
	return lista


# --- C906 ---


func test_bioma_ativo_e_o_estagio_da_dificuldade_de_0_a_3_na_entrada_e_na_subida() -> void:
	var entradas: Array = [[0.0, 0], [0.4, 1], [0.7, 2], [1.0, 3]]
	for entrada: Array in entradas:
		Global.progresso_inicial = float(entrada[0])
		await _spawn_stage(ClassicoRule.new())
		var esperado: int = int(entrada[1])
		assert_eq(_stage.dificuldade.estagio(), esperado, "C906: pre-condicao, progresso %.2f e o estagio %d" % [entrada[0], esperado])
		assert_eq(_stage.fundo.bioma, esperado, "C906: entrada com progresso_inicial %.2f nasce no bioma %d" % [entrada[0], esperado])
		assert_eq(_opacidades(), _so_o_bioma(esperado), "C906: entrada nasce com opacidade final 1/0, sem crossfade")
		assert_false(_stage.fundo.crossfade_ativo(), "C906: entrada nao inicia crossfade")
		await _descartar_stage()
	await _spawn_stage(ClassicoRule.new())
	for novo in [1, 2, 3]:
		_stage.dificuldade.estagio_mudou.emit(novo)
		_stage.fundo.avancar_crossfade(2.0)
		assert_eq(_stage.fundo.bioma, novo, "C906: estagio_mudou(%d) leva ao bioma %d" % [novo, novo])
		assert_eq(_opacidades(), _so_o_bioma(novo), "C906: apos a troca o bioma %d esta em 1 e os outros em 0" % novo)


# --- C907 ---


func test_crossfade_dura_1_2_s_com_0_5_no_meio_e_1_0_exatos_no_fim() -> void:
	await _spawn_stage(ClassicoRule.new())
	_stage.dificuldade.estagio_mudou.emit(1)
	assert_true(_stage.fundo.crossfade_ativo(), "C907: a troca inicia o crossfade")
	assert_eq(_opacidades(), _so_o_bioma(0), "C907: no instante da troca ainda 1/0 no bioma antigo")
	_stage.fundo.avancar_crossfade(0.6)
	assert_almost_eq(_stage.fundo.opacidade(0), 0.5, EPS, "C907: a 0.6 s o bioma antigo esta em 0.5")
	assert_almost_eq(_stage.fundo.opacidade(1), 0.5, EPS, "C907: a 0.6 s o bioma novo esta em 0.5")
	assert_eq(_stage.fundo.opacidade(2), 0.0, "C907: o bioma 2 segue em 0")
	assert_eq(_stage.fundo.opacidade(3), 0.0, "C907: o bioma 3 segue em 0")
	_stage.fundo.avancar_crossfade(0.6)
	assert_eq(_opacidades(), _so_o_bioma(1), "C907: a 1.2 s os grupos estao em 1/0 exatos")
	assert_false(_stage.fundo.crossfade_ativo(), "C907: o crossfade termina em 1.2 s")
	_stage.fundo.avancar_crossfade(0.5)
	assert_eq(_opacidades(), _so_o_bioma(1), "C907: depois de 1.2 s segue em 1/0 exatos")


# --- C908 ---


func test_offset_igual_antes_e_depois_da_troca_e_compartilhado_pelos_4_grupos_no_crossfade() -> void:
	await _spawn_stage(ClassicoRule.new())
	var fundo: Fundo = _stage.fundo
	fundo.acumulado = 100.0
	fundo.atualizar_posicoes()
	var antes: Array[float] = [fundo.offset_camada(0), fundo.offset_camada(1), fundo.offset_camada(2)]
	assert_almost_eq(antes[2], 30.0, EPS, "C908: pre-condicao, offset de c2 com scroll 100 = 30")
	_stage.dificuldade.estagio_mudou.emit(1)
	var logo_depois: Array[float] = [fundo.offset_camada(0), fundo.offset_camada(1), fundo.offset_camada(2)]
	assert_eq(logo_depois, antes, "C908: o offset das camadas nao pula na troca")
	fundo.avancar_crossfade(0.6)
	for g in range(FundoBiomas.QUANTIDADE):
		for i in range(3):
			assert_eq(fundo.offset_camada(i, g), antes[i], "C908: no crossfade o grupo %d camada %d usa o mesmo offset" % [g, i])
			assert_eq(
				fundo.tiles_da_camada(i, g)[1].position.y,
				fundo.tiles_da_camada(i, 0)[1].position.y,
				"C908: no crossfade o tile do grupo %d camada %d esta na mesma posicao" % [g, i]
			)
	fundo.avancar_crossfade(0.6)
	var depois_do_fim: Array[float] = [fundo.offset_camada(0), fundo.offset_camada(1), fundo.offset_camada(2)]
	assert_eq(depois_do_fim, antes, "C908: o offset tambem fica igual ao fim do crossfade")


# --- C909 ---


func test_nao_troca_de_bioma_apos_a_derrota_mesmo_com_estagio_mudou() -> void:
	await _spawn_stage(ClassicoRule.new())
	_stage._publicar_estado(GameState.STATE_LOST, false)
	_stage.dificuldade.estagio_mudou.emit(1)
	assert_eq(_stage.fundo.bioma, 0, "C909: apos STATE_LOST o bioma nao troca")
	assert_false(_stage.fundo.crossfade_ativo(), "C909: apos STATE_LOST nenhum crossfade comeca")
	assert_eq(_opacidades(), _so_o_bioma(0), "C909: apos STATE_LOST as opacidades seguem em 1/0 no bioma 0")


# --- C910 ---


func test_troca_durante_o_crossfade_termina_no_ultimo_bioma_sem_grupo_preso() -> void:
	await _spawn_stage(ClassicoRule.new())
	_stage.dificuldade.estagio_mudou.emit(1)
	_stage.fundo.avancar_crossfade(0.6)
	_stage.dificuldade.estagio_mudou.emit(2)
	_stage.fundo.avancar_crossfade(0.6)
	assert_almost_eq(_stage.fundo.opacidade(0), 0.25, EPS, "C910: a meio da 2a troca o bioma 0 desce de 0.5 a 0.25")
	assert_almost_eq(_stage.fundo.opacidade(1), 0.25, EPS, "C910: a meio da 2a troca o bioma 1 desce de 0.5 a 0.25")
	assert_almost_eq(_stage.fundo.opacidade(2), 0.5, EPS, "C910: a meio da 2a troca o bioma 2 sobe a 0.5")
	_stage.fundo.avancar_crossfade(0.6)
	assert_eq(_stage.fundo.bioma, 2, "C910: termina no ultimo bioma pedido")
	assert_eq(_opacidades(), _so_o_bioma(2), "C910: termina com 1/0 exatos, nenhum grupo em alfa intermediario")
	assert_false(_stage.fundo.crossfade_ativo(), "C910: o crossfade acabou")


# --- C911 ---


func test_scroll_acumulado_alem_de_2400_nao_cicla_o_bioma() -> void:
	await _spawn_stage(ClassicoRule.new())
	_stage.fundo.acumulado = 5000.0
	_stage.fundo.atualizar_posicoes()
	_stage.fundo.avancar_crossfade(2.0)
	assert_eq(_stage.fundo.bioma, 0, "C911: em e0 o bioma segue e0 com scroll > 2400")
	assert_eq(_opacidades(), _so_o_bioma(0), "C911: em e0 sem troca de opacidade")
	assert_false(_stage.fundo.crossfade_ativo(), "C911: em e0 sem crossfade")
	await _descartar_stage()
	Global.progresso_inicial = 1.0
	await _spawn_stage(ClassicoRule.new())
	_stage.fundo.acumulado = 5000.0
	_stage.fundo.atualizar_posicoes()
	_stage.fundo.avancar_crossfade(2.0)
	assert_eq(_stage.fundo.bioma, 3, "C911: apos e3 o bioma fica em e3")
	assert_eq(_opacidades(), _so_o_bioma(3), "C911: em e3 sem troca de opacidade")
	assert_false(_stage.fundo.crossfade_ativo(), "C911: em e3 sem crossfade")


# --- C933 ---


func test_zen_sorteia_o_bioma_da_sequencia_injetada_sem_crossfade() -> void:
	for esperado in [0, 1, 2, 3]:
		var rng := _rng_para([esperado])
		assert_not_null(rng, "C933: pre-condicao, seed que sorteia %d" % esperado)
		await _spawn_stage(ZenRule.new(), rng)
		assert_eq(_stage.fundo.bioma, esperado, "C933: o Zen mostra o bioma sorteado %d" % esperado)
		assert_eq(_opacidades(), _so_o_bioma(esperado), "C933: o sorteado nasce com opacidade final 1/0 (bioma %d)" % esperado)
		assert_false(_stage.fundo.crossfade_ativo(), "C933: o sorteio nao inicia crossfade (bioma %d)" % esperado)
		await _descartar_stage()


# --- C934 ---


func test_zen_mantem_o_bioma_na_partida_apesar_de_estagio_e_scroll_e_nao_sorteia_de_novo() -> void:
	var rng := _rng_para([2])
	await _spawn_stage(ZenRule.new(), rng)
	var estado_do_rng: int = rng.state
	assert_eq(_stage.fundo.bioma, 2, "C934: pre-condicao, o Zen sorteou o bioma 2")
	_stage.dificuldade.estagio_mudou.emit(1)
	_stage.dificuldade.estagio_mudou.emit(2)
	_stage.fundo.acumulado = 5000.0
	_stage.fundo.atualizar_posicoes()
	assert_false(_stage.fundo.crossfade_ativo(), "C934: estagio_mudou nao inicia crossfade no Zen")
	_stage.fundo.avancar_crossfade(2.0)
	assert_eq(_stage.fundo.bioma, 2, "C934: o bioma do Zen nao muda na partida")
	assert_eq(_opacidades(), _so_o_bioma(2), "C934: as opacidades seguem em 1/0 no bioma sorteado")
	assert_eq(rng.state, estado_do_rng, "C934: o rng nao e consumido de novo")


# --- C935 ---


func test_nova_partida_zen_pode_sortear_outro_e_modo_com_estagio_comeca_em_e0_sem_consumir_o_rng() -> void:
	var rng := _rng_para([1, 3])
	await _spawn_stage(ZenRule.new(), rng)
	assert_eq(_stage.fundo.bioma, 1, "C935: a 1a partida Zen mostra e1")
	await _descartar_stage()
	await _spawn_stage(ZenRule.new(), rng)
	assert_eq(_stage.fundo.bioma, 3, "C935: a 2a partida Zen mostra e3 apos e1 na 1a")
	await _descartar_stage()

	var rng_classico := _rng_para([3])
	var estado_do_rng: int = rng_classico.state
	await _spawn_stage(ClassicoRule.new(), rng_classico)
	assert_eq(_stage.fundo.bioma, 0, "C935: modo com estagio comeca em e0")
	assert_eq(_opacidades(), _so_o_bioma(0), "C935: modo com estagio comeca com 1/0 em e0")
	assert_eq(rng_classico.state, estado_do_rng, "C935: modo com estagio nao consome o rng")
