extends GutTest

# Platform com o modificador PlatformBlink: visibilidade, colisao, reaparecer, trava, pausa, aviso.
# Fases exatas em binario (ciclo 4 s: visivel [0,3), aviso [2.5,3), invisivel [3,4)).
const PLATAFORMA_CENA := "res://scenes/Platform.tscn"
const VISIVEL := 3.0
const INVISIVEL := 1.0
const AVISO := 0.5

var _cor_original: Enums.COLOR


func before_each() -> void:
	_cor_original = Global.cor_gecko
	Global.platforms = []
	Global.iniciado = true
	Global.sem_derrota = false


func after_each() -> void:
	get_tree().paused = false
	Global.cor_gecko = _cor_original
	Global.platforms = []
	Global.iniciado = false
	Global.sem_derrota = false


func _blink(fase: float) -> PlatformBlink:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var blink := PlatformBlink.new()
	blink.iniciar(rng, VISIVEL, INVISIVEL, AVISO)
	blink.definir_fase(fase)
	return blink


func _nova(fase: float, modificadores: Array = [], cor: Enums.COLOR = Enums.COLOR.AMARELO) -> Platform:
	var p: Platform = load(PLATAFORMA_CENA).instantiate()
	p.set_color(cor)
	var lista: Array = modificadores.duplicate()
	lista.append(_blink(fase))
	p.definir_modificadores(lista, DifficultySnapshot.new())
	add_child_autofree(p)
	return p


func _corpo_gecko(pos: Vector2) -> CharacterBody2D:
	var corpo := CharacterBody2D.new()
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = Vector2(10.0, 10.0)
	forma.shape = ret
	corpo.add_child(forma)
	add_child_autofree(corpo)
	corpo.global_position = pos
	return corpo


func test_invisivel_por_piscar_mantem_colisao_desligada_apos_player_color_changed() -> void:
	var p := _nova(3.5)
	Global.cor_gecko = p.color
	p.player_color_changed(p.color)
	assert_true(p.shape.disabled, "invisivel: sem colisao mesmo com a cor do gecko")
	assert_almost_eq(p.modulate.a, Platform.PISCA_ALFA_FANTASMA, 0.001, "fantasma")


func test_visivel_segue_a_regra_de_cor_de_antes() -> void:
	var p := _nova(1.0)
	Global.cor_gecko = p.color
	p.player_color_changed(p.color)
	assert_false(p.shape.disabled, "visivel e mesma cor: solida")
	p.player_color_changed(Enums.COLOR.AZUL)
	assert_true(p.shape.disabled, "visivel e cor diferente: sem colisao")


func test_invisivel_por_piscar_mantem_colisao_desligada_apos_aplicar_cor() -> void:
	var p := _nova(3.5)
	Global.cor_gecko = Enums.COLOR.VERDE
	p.trocar_cor(Enums.COLOR.VERDE)
	assert_eq(p.color, Enums.COLOR.VERDE, "cor trocada")
	assert_true(p.shape.disabled, "invisivel: a troca de cor nao liga a colisao")


func test_reaparecer_com_gecko_sobreposto_adia_e_aplica_quando_ele_sai() -> void:
	var p := _nova(3.3)
	p.global_position = Vector2(100.0, 100.0)
	Global.cor_gecko = p.color
	var corpo := _corpo_gecko(Vector2(100.0, 100.0))
	await wait_physics_frames(3)
	p._physics_process(0.7)
	assert_true(p.obter_pisca().esta_visivel(), "voltou ao ciclo visivel")
	assert_true(p.shape.disabled, "gecko sobrepondo: colisao adiada")
	assert_eq(p.modulate.a, 1.0, "visual ja reaparece")
	corpo.global_position = Vector2(100.0, 400.0)
	await wait_physics_frames(3)
	p._physics_process(0.016)
	assert_false(p.shape.disabled, "gecko saiu: solida")


func test_reaparecer_sem_sobreposicao_liga_a_colisao_no_mesmo_frame() -> void:
	var p := _nova(3.5)
	p.global_position = Vector2(100.0, 100.0)
	Global.cor_gecko = p.color
	p.player_color_changed(p.color)
	assert_true(p.shape.disabled, "invisivel")
	p._physics_process(0.6)
	assert_false(p.shape.disabled, "reapareceu sem gecko: solida no mesmo frame")


func test_travada_nunca_some_nem_avisa_e_ao_destravar_o_relogio_retoma() -> void:
	var p := _nova(2.6)
	Global.cor_gecko = p.color
	p.definir_travada(true)
	for i in 10:
		p._physics_process(0.06)
		assert_eq(p.modulate.a, 1.0, "travada: sem aviso nem fantasma")
		assert_eq(p.obter_pisca().get_fase(), 2.6, "relogio congelado")
	p.definir_travada(false)
	p._physics_process(0.5)
	assert_almost_eq(p.obter_pisca().get_fase(), 3.1, 0.0001, "retomou do ponto em que parou")
	assert_almost_eq(p.modulate.a, Platform.PISCA_ALFA_FANTASMA, 0.001, "destravada e invisivel")


func test_travada_em_fase_invisivel_permanece_visivel() -> void:
	var p := _nova(3.5)
	assert_almost_eq(p.modulate.a, Platform.PISCA_ALFA_FANTASMA, 0.001, "nasce fantasma")
	p.definir_travada(true)
	p._physics_process(0.1)
	assert_eq(p.modulate.a, 1.0, "travada vira visivel")


func test_com_a_arvore_pausada_a_fase_nao_avanca_e_retoma_do_mesmo_ponto() -> void:
	var p := _nova(1.0)
	get_tree().paused = true
	await wait_physics_frames(6)
	assert_eq(p.obter_pisca().get_fase(), 1.0, "pausada: fase parada")
	get_tree().paused = false
	await wait_physics_frames(6)
	assert_gt(p.obter_pisca().get_fase(), 1.0, "retomou a partir do mesmo ponto")
	assert_lt(p.obter_pisca().get_fase(), 1.5, "sem salto")


func test_partida_nao_iniciada_nao_avanca_relogio_nem_muda_visibilidade() -> void:
	Global.iniciado = false
	var p := _nova(2.0)
	for i in 10:
		p._physics_process(1.0)
	assert_eq(p.obter_pisca().get_fase(), 2.0, "relogio parado")
	assert_eq(p.modulate.a, 1.0, "visibilidade intacta")
	var q := _nova(3.5)
	for i in 10:
		q._physics_process(1.0)
	assert_eq(q.obter_pisca().get_fase(), 3.5, "relogio parado (invisivel)")
	assert_almost_eq(q.modulate.a, Platform.PISCA_ALFA_FANTASMA, 0.001, "continua fantasma")
	assert_true(q.shape.disabled, "sem colisao")


func _neutralizar(p: Platform) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	p.obter_pisca().iniciar(rng, 0.0, 0.0, 0.0, 0.0)


func test_neutralizada_apos_o_ready_fica_visivel_e_solida_sem_esperar_a_partida() -> void:
	Global.iniciado = false
	var p := _nova(3.5)
	Global.cor_gecko = p.color
	assert_true(p.shape.disabled, "nasce fantasma")
	_neutralizar(p)
	p._physics_process(0.016)
	assert_false(p.shape.disabled, "inerte: solida antes da partida")
	assert_eq(p.modulate.a, 1.0, "inerte: visivel antes da partida")


func test_neutralizada_apos_o_ready_com_partida_iniciada_fica_visivel_e_solida() -> void:
	Global.iniciado = false
	var p := _nova(3.5)
	Global.cor_gecko = p.color
	_neutralizar(p)
	Global.iniciado = true
	p._physics_process(0.016)
	assert_false(p.shape.disabled, "inerte: solida com a partida iniciada")
	assert_eq(p.modulate.a, 1.0, "inerte: visivel com a partida iniciada")


func test_sem_derrota_deixa_a_mecanica_inerte() -> void:
	Global.sem_derrota = true
	var p := _nova(3.5)
	p._physics_process(0.1)
	assert_eq(p.obter_pisca().get_fase(), 3.5, "relogio parado")
	assert_eq(p.modulate.a, 1.0, "sempre visivel")
	Global.cor_gecko = p.color
	p.player_color_changed(p.color)
	assert_false(p.shape.disabled, "solida")


func test_desmoronada_nunca_volta_a_ter_colisao_nem_exibe_aviso() -> void:
	var p := _nova(2.6)
	p.desmoronada = true
	Global.cor_gecko = p.color
	p._physics_process(0.06)
	assert_eq(p.modulate.a, 1.0, "sem aviso")
	p._physics_process(0.9)
	assert_true(p.shape.disabled, "invisivel: sem colisao")
	p._physics_process(0.6)
	assert_true(p.obter_pisca().esta_visivel(), "ciclo voltou a visivel")
	assert_true(p.shape.disabled, "desmoronada nao reativa")


# C887 [mutacao]: tremor so em Visual.position.x, dentro da janela AVISO_TREMOR_S; zera ao fim
func test_que_caem_piscante_mantem_tremor_colisao_e_cor_da_textura() -> void:
	var p := _nova(0.0, [PlatformCrumble.new()])
	Global.cor_gecko = p.color
	p.player_color_changed(p.color)
	var corpo_pos: Vector2 = p.corpo.position
	var pos_antes := p.position
	p.iniciar_desmoronamento(1.0)
	p._physics_process(0.5)
	assert_eq(p.visual.position.x, 0.0, "antes da janela de tremor: sem tremor")
	p._physics_process(0.3)
	assert_ne(p.visual.position.x, 0.0, "tremor do desmoronar segue")
	assert_lte(absf(p.visual.position.x), Platform.TREMOR_AMPLITUDE, "tremor dentro da amplitude")
	assert_eq(p.position, pos_antes, "Platform nao treme")
	assert_eq(p.corpo.position, corpo_pos, "NinePatchRect nao muda de posicao")
	assert_false(p.shape.disabled, "visivel: colisao de antes")
	p._physics_process(0.3)
	assert_true(p.desmoronada, "atraso esgotado")
	assert_eq(p.visual.position.x, 0.0, "tremor zerado ao fim")
	var q := _nova(2.5)
	q._physics_process(0.06)
	assert_almost_eq(q.modulate.a, Platform.PISCA_AVISO_ALFA_BAIXO, 0.001, "aviso do piscar no alfa do no")
	assert_eq(q.visual.modulate, Color.WHITE, "Visual.modulate fica branco")
	assert_eq(q.corpo.texture, PlatformVisuais.textura(q.color), "textura fica com a cor")


func test_obter_pisca_devolve_a_instancia_anexada_e_null_sem_ela() -> void:
	var p := _nova(0.0)
	assert_true(p.obter_pisca() is PlatformBlink, "instancia anexada")
	var sem: Platform = load(PLATAFORMA_CENA).instantiate()
	add_child_autofree(sem)
	assert_null(sem.obter_pisca(), "sem modificador: null")
