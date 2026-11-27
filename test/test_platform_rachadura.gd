extends GutTest

# Rachadura em 3 estagios (overlay) e pedacos no colapso do desmoronamento da Platform.
const PLATAFORMA_CENA := "res://scenes/Platform.tscn"

var _cor_original: Enums.COLOR


func before_each() -> void:
	_cor_original = Global.cor_gecko
	Global.platforms = []
	Global.iniciado = false
	Global.sem_derrota = false


func after_each() -> void:
	for pedaco in _pedacos():
		pedaco.free()
	Global.cor_gecko = _cor_original
	Global.platforms = []
	Global.iniciado = false
	Global.sem_derrota = false


func _nova(cor: Enums.COLOR = Enums.COLOR.AMARELO, modificadores: Array = []) -> Platform:
	var p: Platform = load(PLATAFORMA_CENA).instantiate()
	p.set_color(cor)
	p.position = Vector2(100.0, 50.0)
	if not modificadores.is_empty():
		p.definir_modificadores(modificadores, DifficultySnapshot.new())
	add_child_autofree(p)
	return p


# Pedacos do burst que estao no pai (este teste), contados por tipo e nao por get_child_count
func _pedacos() -> Array:
	var achados: Array = []
	for filho in get_children():
		if filho is PlatformPedacos and not filho.is_queued_for_deletion():
			achados.append(filho)
	return achados


func _afirmar_estagio(p: Platform, estagio: int) -> void:
	assert_true(p.overlay.visible, "overlay visivel no estagio %d" % estagio)
	assert_not_null(p.overlay.texture, "overlay com textura no estagio %d" % estagio)
	if p.overlay.texture != null:
		assert_true(p.overlay.texture.resource_path.ends_with("plataforma-rachadura-%d.png" % estagio), "textura do estagio %d (veio %s)" % [estagio, p.overlay.texture.resource_path])


func _tem_colisao(no: Node) -> bool:
	if no is CollisionObject2D or no is CollisionShape2D or no is CollisionPolygon2D:
		return true
	for filho in no.get_children():
		if _tem_colisao(filho):
			return true
	return false


# C888 [it]
func test_estagio_0_antes_de_iniciar_o_overlay_e_invisivel_filho_de_visual_com_margens_20() -> void:
	var p := _nova()
	var overlay: NinePatchRect = p.get_node("Visual/OverlayRachadura")
	assert_eq(overlay.get_parent(), p.get_node("Visual"), "OverlayRachadura e filho de Visual")
	assert_true(not overlay.visible or overlay.texture == null, "estagio 0: overlay invisivel ou sem textura")
	assert_eq(overlay.patch_margin_left, 20, "margem esquerda 20")
	assert_eq(overlay.patch_margin_right, 20, "margem direita 20")


# C889 [it]
func test_iniciar_desmoronamento_com_atraso_maior_que_03_mostra_o_estagio_1_no_mesmo_frame() -> void:
	var p := _nova()
	p.iniciar_desmoronamento(1.0)
	_afirmar_estagio(p, 1)


# C890 [it]
func test_tempo_restante_ate_03_mostra_o_estagio_2_e_acima_de_03_segue_no_estagio_1() -> void:
	var p := _nova()
	p.iniciar_desmoronamento(0.5)
	p._physics_process(0.19)  # 0.31: logo acima do limite
	_afirmar_estagio(p, 1)
	var q := _nova()
	q.iniciar_desmoronamento(0.5)
	q._physics_process(0.2)  # 0.3 exato: limite
	_afirmar_estagio(q, 2)


# C891 [it]
func test_tempo_restante_ate_01_mostra_o_estagio_3_ainda_na_arvore_e_sem_desmoronar() -> void:
	var p := _nova()
	p.iniciar_desmoronamento(0.5)
	p._physics_process(0.2)
	p._physics_process(0.2)  # 0.1 aprox: ainda estagio 2 ou 3
	p._physics_process(0.02)  # ~0.08
	_afirmar_estagio(p, 3)
	assert_false(p.desmoronada, "estagio 3 ainda nao e o colapso")
	assert_true(p.is_inside_tree(), "plataforma ainda na arvore no estagio 3")


# C892
func test_atraso_ate_03_nunca_mostra_o_estagio_1_e_vai_de_2_para_3() -> void:
	var p := _nova()
	p.iniciar_desmoronamento(0.2)
	assert_true(not p.overlay.visible or p.overlay.texture == null, "sem estagio 1 logo apos iniciar")
	p._physics_process(0.05)  # 0.15
	_afirmar_estagio(p, 2)
	p._physics_process(0.1)  # 0.05
	_afirmar_estagio(p, 3)


# C893
func test_colapso_desabilita_a_colisao_emite_de_6_a_8_pedacos_e_a_plataforma_sai_da_arvore() -> void:
	var p := _nova()
	p.iniciar_desmoronamento(0.05)
	p._physics_process(0.06)
	assert_true(p.desmoronada, "desmoronada")
	assert_true(p.shape.disabled, "colisao desligada")
	var total := _pedacos().size()
	assert_between(total, 6, 8, "o pai recebe de 6 a 8 pedacos (veio %d)" % total)
	await get_tree().process_frame
	assert_false(is_instance_valid(p) and p.is_inside_tree(), "a plataforma saiu da arvore")


# C894
func test_pedacos_sem_colisao_caem_pela_gravidade_e_somem_em_035_s() -> void:
	var p := _nova()
	p.iniciar_desmoronamento(0.05)
	p._physics_process(0.06)
	var pedacos := _pedacos()
	assert_between(pedacos.size(), 6, 8, "burst emitido")
	var y_inicial: Array = []
	for pedaco in pedacos:
		assert_false(_tem_colisao(pedaco), "pedaco sem CollisionObject2D/CollisionShape2D")
		pedaco.set_process(false)
		y_inicial.append(pedaco.position.y)
	for i in 4:
		for pedaco in pedacos:
			pedaco.avancar(0.05)
	for i in pedacos.size():
		var dy: float = pedacos[i].position.y - y_inicial[i]
		assert_almost_eq(dy, 0.5 * 440.0 * 0.2 * 0.2, 0.05, "deslocamento vertical em t = 0.2 s")
	for pedaco in pedacos:
		pedaco.avancar(0.14)  # t = 0.34
	assert_eq(_pedacos().size(), pedacos.size(), "ainda presentes em 0.34 s")
	for pedaco in pedacos:
		pedaco.avancar(0.02)  # t = 0.36
	assert_eq(_pedacos().size(), 0, "somem sozinhos em 0.35 s (o pai volta a 0 pedacos)")


# C895
func test_chamar_de_novo_apos_desmoronada_nao_emite_outro_burst() -> void:
	var p := _nova()
	p.iniciar_desmoronamento(0.05)
	p._physics_process(0.06)
	var total := _pedacos().size()
	assert_between(total, 6, 8, "burst inicial")
	p.iniciar_desmoronamento(1.0)
	p._avancar_desmoronamento(0.5)
	assert_eq(_pedacos().size(), total, "sem novo burst (contagem no pai igual)")
	assert_between(_pedacos().size(), 6, 8, "contagem segue entre 6 e 8")


# C896
func test_plataforma_sem_pai_ao_colapsar_nao_da_erro_nem_emite_burst() -> void:
	var p := _nova()
	remove_child(p)
	p.iniciar_desmoronamento(0.05)
	p._physics_process(0.06)
	assert_true(p.desmoronada, "colapsou sem pai")
	assert_eq(_pedacos().size(), 0, "sem pai nao ha burst")
	p.queue_free()


# C897
func test_mesma_semente_gera_os_mesmos_pedacos_e_sementes_diferentes_divergem() -> void:
	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 5
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 5
	var rng_c := RandomNumberGenerator.new()
	rng_c.seed = 6
	var a := PlatformPedacos.gerar(rng_a, 120.0, Enums.COLOR.VERDE)
	var b := PlatformPedacos.gerar(rng_b, 120.0, Enums.COLOR.VERDE)
	var c := PlatformPedacos.gerar(rng_c, 120.0, Enums.COLOR.VERDE)
	assert_true(a == b, "mesma semente: mesmas posicoes e formas")
	assert_true(a != c, "sementes diferentes divergem")
	var p1 := _nova()
	p1.rng_pedacos = RandomNumberGenerator.new()
	p1.rng_pedacos.seed = 9
	p1.iniciar_desmoronamento(0.05)
	p1._physics_process(0.06)
	var posicoes_1: Array = []
	for pedaco in _pedacos():
		posicoes_1.append(pedaco.position)
		pedaco.free()
	var p2 := _nova()
	p2.rng_pedacos = RandomNumberGenerator.new()
	p2.rng_pedacos.seed = 9
	p2.iniciar_desmoronamento(0.05)
	p2._physics_process(0.06)
	var posicoes_2: Array = []
	for pedaco in _pedacos():
		posicoes_2.append(pedaco.position)
	assert_gt(posicoes_1.size(), 0, "o primeiro burst existiu")
	assert_true(posicoes_1 == posicoes_2, "mesma semente injetada na plataforma: mesmas posicoes")


# C898
func test_piscante_desmoronando_e_cicladora_no_mesmo_no_cada_canal_no_seu_dono() -> void:
	Global.iniciado = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var ciclo := PlatformColorCycle.new()
	ciclo.iniciar(Enums.COLOR.AMARELO, 1.0, rng)
	var rng_pisca := RandomNumberGenerator.new()
	rng_pisca.seed = 3
	var blink := PlatformBlink.new()
	blink.iniciar(rng_pisca, 3.0, 1.0, 0.5)
	blink.definir_fase(2.0)
	var p := _nova(Enums.COLOR.AMARELO, [ciclo, blink])
	p.iniciar_desmoronamento(1.7)
	var permitidos_no: Array = [Platform.PISCA_ALFA_FANTASMA, Platform.PISCA_AVISO_ALFA_BAIXO, 1.0]
	var permitidos_visual: Array = [Platform.AVISO_ALFA_BAIXO, 1.0]
	var viu_pisca := false
	var viu_aviso := false
	var viu_tremor := false
	var estagios := {}
	p._physics_process(0.45)
	for i in 60:
		p._physics_process(0.02)
		var restante: float = p._tempo_restante
		var esperado := 1
		if restante <= 0.1:
			esperado = 3
		elif restante <= 0.3:
			esperado = 2
		estagios[esperado] = true
		assert_true(p.overlay.texture != null and p.overlay.texture.resource_path.ends_with("plataforma-rachadura-%d.png" % esperado), "overlay no estagio %d" % esperado)
		var alfa_no: float = p.modulate.a
		var alfa_visual: float = p.visual.modulate.a
		var x: float = p.visual.position.x
		var alfa_ok_no := false
		for permitido in permitidos_no:
			alfa_ok_no = alfa_ok_no or is_equal_approx(alfa_no, permitido)
		var alfa_ok_visual := false
		for permitido in permitidos_visual:
			alfa_ok_visual = alfa_ok_visual or is_equal_approx(alfa_visual, permitido)
		assert_true(alfa_ok_no, "Platform.modulate.a so PISCA_* (veio %s)" % alfa_no)
		assert_true(alfa_ok_visual, "Visual.modulate.a so AVISO_ALFA_BAIXO/1.0 (veio %s)" % alfa_visual)
		if restante <= Platform.AVISO_TREMOR_S:
			assert_eq(absf(x), Platform.TREMOR_AMPLITUDE, "tremor em Visual.position.x na janela de tremor")
			viu_tremor = true
		else:
			assert_eq(x, 0.0, "sem tremor fora da janela")
		viu_pisca = viu_pisca or not is_equal_approx(alfa_no, 1.0)
		viu_aviso = viu_aviso or is_equal_approx(alfa_visual, Platform.AVISO_ALFA_BAIXO)
	assert_true(viu_pisca, "o piscante apareceu em Platform.modulate.a")
	assert_true(viu_aviso, "o pulso da cicladora apareceu em Visual.modulate.a")
	assert_true(viu_tremor, "o tremor apareceu em Visual.position.x")
	assert_eq(estagios.size(), 3, "os 3 estagios de rachadura passaram pelo overlay")


# C899
func test_visual_volta_a_x_zero_ao_fim_e_o_overlay_acompanha_a_largura() -> void:
	var p := _nova()
	p.set_largura(88.0)
	assert_eq(p.overlay.size, p.corpo.size, "overlay herda o tamanho do corpo apos set_largura(88)")
	assert_eq(p.overlay.position.x, p.corpo.position.x, "overlay alinhado ao corpo")
	p.iniciar_desmoronamento(0.2)
	p._physics_process(0.1)
	assert_eq(absf(p.visual.position.x), Platform.TREMOR_AMPLITUDE, "tremendo antes do colapso")
	p._physics_process(0.2)
	assert_true(p.desmoronada, "colapsou")
	assert_eq(p.visual.position.x, 0.0, "Visual.position.x == 0 ao fim")
