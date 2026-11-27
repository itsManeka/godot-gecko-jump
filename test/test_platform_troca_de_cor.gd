extends GutTest

const PLATAFORMA_CENA := "res://scenes/Platform.tscn"

var _cor_original: Enums.COLOR


func before_each() -> void:
	_cor_original = Global.cor_gecko
	Global.platforms = []
	Global.iniciado = false


func after_each() -> void:
	Global.cor_gecko = _cor_original
	Global.platforms = []
	Global.iniciado = false


func _nova(cor: Enums.COLOR = Enums.COLOR.AMARELO, ciclo: PlatformColorCycle = null) -> Platform:
	var p: Platform = load(PLATAFORMA_CENA).instantiate()
	p.set_color(cor)
	if ciclo != null:
		p.definir_modificadores([ciclo], DifficultySnapshot.new())
	add_child_autofree(p)
	return p


func _ciclo(cor_inicial: Enums.COLOR, periodo: float) -> PlatformColorCycle:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var ciclo := PlatformColorCycle.new()
	ciclo.iniciar(cor_inicial, periodo, rng)
	return ciclo


# C879 [mutacao]: a troca muda color e textura no mesmo frame
func test_trocar_cor_muda_color_textura_e_colisao_pela_cor_do_gecko() -> void:
	var p := _nova(Enums.COLOR.AMARELO)
	Global.cor_gecko = Enums.COLOR.VERDE
	p.trocar_cor(Enums.COLOR.VERDE)
	assert_eq(p.color, Enums.COLOR.VERDE, "color novo")
	assert_true(p.corpo.texture.resource_path.ends_with("plataforma-verde.png"), "textura nova (verde)")
	assert_eq(p.visual.modulate, Color.WHITE, "Visual.modulate branco apos a troca")
	assert_false(p.shape.disabled, "cor igual a do gecko: colisao ligada")
	p.trocar_cor(Enums.COLOR.AZUL)
	assert_eq(p.color, Enums.COLOR.AZUL, "color azul")
	assert_true(p.corpo.texture.resource_path.ends_with("plataforma-azul.png"), "textura azul")
	assert_true(p.shape.disabled, "cor diferente da do gecko: colisao desligada")


func test_desmoronada_continua_desabilitada_apos_trocar_cor_para_a_do_gecko() -> void:
	var p := _nova(Enums.COLOR.AMARELO)
	p.desmoronada = true
	Global.cor_gecko = Enums.COLOR.VERDE
	p.trocar_cor(Enums.COLOR.VERDE)
	assert_true(p.shape.disabled, "desmoronada nunca reativa")


func test_gecko_na_plataforma_trava_o_ciclo_e_sem_plataforma_retoma() -> void:
	var ciclo := _ciclo(Enums.COLOR.AMARELO, 1.0)
	var p := _nova(Enums.COLOR.AMARELO, ciclo)
	Global.player_color_changed(Enums.COLOR.VERDE, p)
	assert_true(p.esta_travada(), "gecko em cima: travada")
	p._physics_process(1.5)
	assert_eq(p.color, Enums.COLOR.AMARELO, "travada nao troca")
	Global.player_color_changed(Enums.COLOR.VERDE, null)
	assert_false(p.esta_travada(), "gecko saiu: destravada")
	p._physics_process(1.1)
	assert_eq(p.color, ciclo.cor_atual(), "retomou e trocou")
	assert_ne(p.color, Enums.COLOR.AMARELO, "cor mudou")


func test_trava_limpa_quando_o_gecko_troca_para_outra_plataforma() -> void:
	var a := _nova(Enums.COLOR.AMARELO)
	var b := _nova(Enums.COLOR.AMARELO)
	Global.player_color_changed(Enums.COLOR.VERDE, a)
	assert_true(a.esta_travada(), "a travada")
	assert_false(b.esta_travada(), "b livre")
	Global.player_color_changed(Enums.COLOR.VERDE, b)
	assert_false(a.esta_travada(), "a destravada ao gecko ir para b")
	assert_true(b.esta_travada(), "b travada")


# C883 [mutacao] + C884 [mutacao]: no aviso a textura alterna color/proxima_cor e Visual.modulate.a alterna 1.0/0.55;
# fora do aviso e apos a troca: textura da cor nova e Visual.modulate == Color.WHITE
func test_aviso_alterna_textura_pulsa_alfa_e_volta_ao_normal_apos_a_troca() -> void:
	var ciclo := _ciclo(Enums.COLOR.AMARELO, 1.0)
	var p := _nova(Enums.COLOR.AMARELO, ciclo)
	var tex_atual := PlatformVisuais.textura(Enums.COLOR.AMARELO)
	var tex_proxima := PlatformVisuais.textura(ciclo.proxima_cor())
	assert_ne(tex_atual, tex_proxima, "cor atual e proxima tem texturas distintas")
	p._physics_process(0.3)
	assert_eq(p.corpo.texture, tex_atual, "fora do aviso: textura atual")
	assert_eq(p.visual.modulate, Color.WHITE, "fora do aviso: Visual.modulate branco (alfa 1.0)")
	var viu_atual := false
	var viu_proxima := false
	var alfa_baixo := false
	var alfa_cheio := false
	for i in 20:
		p._physics_process(0.02)
		var alfa: float = p.visual.modulate.a
		if p.corpo.texture == tex_atual:
			viu_atual = true
			assert_almost_eq(alfa, 1.0, 0.0001, "textura atual com alfa 1.0")
		if p.corpo.texture == tex_proxima:
			viu_proxima = true
			assert_almost_eq(alfa, Platform.AVISO_ALFA_BAIXO, 0.0001, "textura proxima com alfa baixo")
		if is_equal_approx(alfa, Platform.AVISO_ALFA_BAIXO):
			alfa_baixo = true
		if is_equal_approx(alfa, 1.0):
			alfa_cheio = true
		assert_eq(p.modulate.a, 1.0, "Platform.modulate.a fica 1.0 no aviso da cicladora")
	assert_true(ciclo.em_aviso(), "dentro do aviso")
	assert_true(viu_atual, "mostrou a textura atual")
	assert_true(viu_proxima, "mostrou a textura da proxima cor")
	assert_true(alfa_baixo, "alfa baixo (0.55) apareceu")
	assert_true(alfa_cheio, "alfa 1.0 apareceu")
	p._physics_process(0.4)
	assert_eq(p.color, ciclo.cor_atual(), "trocou")
	assert_eq(p.corpo.texture, PlatformVisuais.textura(p.color), "apos a troca: textura da cor nova")
	assert_eq(p.visual.modulate, Color.WHITE, "apos a troca: Visual.modulate branco (alfa 1.0)")


# C884 [mutacao]: fora do aviso e logo apos a troca, a textura e a da cor nova e Visual.modulate e Color.WHITE (alfa 1.0)
func test_fora_do_aviso_e_apos_a_troca_a_textura_e_a_nova_e_visual_modulate_e_branco() -> void:
	var p := _nova(Enums.COLOR.AMARELO, _ciclo(Enums.COLOR.AMARELO, 2.0))
	p._physics_process(0.3)
	assert_eq(p.visual.modulate, Color.WHITE, "fora do aviso: Visual.modulate branco com alfa 1.0")
	p = _plataforma_mostrando_a_proxima_cor()
	assert_almost_eq(p.visual.modulate.a, Platform.AVISO_ALFA_BAIXO, 0.0001, "precondicao: aviso com alfa baixo na tela")
	p._physics_process(0.5)
	var nova: int = p.obter_ciclo().cor_atual()
	assert_eq(p.color, nova, "trocou")
	assert_eq(p.corpo.texture, PlatformVisuais.textura(nova), "textura da cor nova logo apos a troca")
	assert_eq(p.visual.modulate, Color.WHITE, "logo apos a troca: Visual.modulate branco com alfa 1.0")


# C885 [mutacao]: travada ou desmoronada em aviso nao alterna textura nem pulsa alfa
func test_travada_ou_desmoronada_em_aviso_nao_alterna_textura_nem_alfa() -> void:
	var tex_atual := PlatformVisuais.textura(Enums.COLOR.AMARELO)
	var p := _plataforma_mostrando_a_proxima_cor()
	assert_ne(p.corpo.texture, tex_atual, "precondicao: o aviso mostra a textura da proxima cor")
	p.definir_travada(true)
	for i in 20:
		p._physics_process(0.02)
		assert_eq(p.corpo.texture, tex_atual, "travada: textura nao alterna")
		assert_eq(p.visual.modulate, Color.WHITE, "travada: Visual.modulate branco")
	var q := _plataforma_mostrando_a_proxima_cor()
	assert_ne(q.corpo.texture, tex_atual, "precondicao: o aviso mostra a textura da proxima cor")
	q.desmoronada = true
	for i in 10:
		q._physics_process(0.02)
		assert_eq(q.corpo.texture, tex_atual, "desmoronada: textura nao alterna")
		assert_eq(q.visual.modulate, Color.WHITE, "desmoronada: Visual.modulate branco")


# Cicladora de periodo 2 s em aviso (a partir de 1,4 s), avancada ate a fase que mostra a textura da proxima cor
func _plataforma_mostrando_a_proxima_cor() -> Platform:
	var ciclo := _ciclo(Enums.COLOR.AMARELO, 2.0)
	var p := _nova(Enums.COLOR.AMARELO, ciclo)
	var tex_atual := PlatformVisuais.textura(Enums.COLOR.AMARELO)
	p._physics_process(1.5)
	for i in 12:
		if p.corpo.texture != tex_atual:
			break
		p._physics_process(0.02)
	return p


func test_plataforma_sem_ciclo_nao_tem_ciclo_nem_filho_novo() -> void:
	var p := _nova(Enums.COLOR.AMARELO)
	var referencia: Node = load(PLATAFORMA_CENA).instantiate()
	autofree(referencia)
	assert_null(p.obter_ciclo(), "sem ciclo")
	assert_eq(p.get_child_count(), referencia.get_child_count(), "nenhum filho visual novo")


func test_troca_adiada_enquanto_o_corpo_do_gecko_sobrepoe() -> void:
	var p := _nova(Enums.COLOR.AMARELO)
	p.global_position = Vector2(100.0, 100.0)
	Global.cor_gecko = Enums.COLOR.VERDE
	p.player_color_changed(Enums.COLOR.VERDE)
	var corpo := CharacterBody2D.new()
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = Vector2(10.0, 10.0)
	forma.shape = ret
	corpo.add_child(forma)
	add_child_autofree(corpo)
	corpo.global_position = Vector2(100.0, 100.0)
	await wait_physics_frames(3)
	p.trocar_cor(Enums.COLOR.VERDE)
	assert_eq(p.color, Enums.COLOR.AMARELO, "troca adiada com o gecko sobreposto")
	assert_true(p.corpo.texture.resource_path.ends_with("plataforma-amarelo.png"), "textura segue a antiga com a troca adiada")
	assert_true(p.shape.disabled, "nao solidifica sobre o gecko")
	corpo.global_position = Vector2(100.0, 400.0)
	await wait_physics_frames(3)
	p._physics_process(0.016)
	assert_eq(p.color, Enums.COLOR.VERDE, "gecko saiu: troca aplicada")
	assert_true(p.corpo.texture.resource_path.ends_with("plataforma-verde.png"), "textura nova so depois da troca aplicar")
	assert_false(p.shape.disabled, "solida depois que o gecko saiu")
