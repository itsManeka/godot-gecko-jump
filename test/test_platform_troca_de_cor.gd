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


func test_trocar_cor_muda_color_modulate_e_colisao_pela_cor_do_gecko() -> void:
	var p := _nova(Enums.COLOR.AMARELO)
	Global.cor_gecko = Enums.COLOR.VERDE
	p.trocar_cor(Enums.COLOR.VERDE)
	assert_eq(p.color, Enums.COLOR.VERDE, "color novo")
	assert_eq(p.sprite.modulate, Enums.get_cor(Enums.COLOR.VERDE), "modulate novo")
	assert_false(p.shape.disabled, "cor igual a do gecko: colisao ligada")
	p.trocar_cor(Enums.COLOR.AZUL)
	assert_eq(p.color, Enums.COLOR.AZUL, "color azul")
	assert_eq(p.sprite.modulate, Enums.get_cor(Enums.COLOR.AZUL), "modulate azul")
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


func test_aviso_alterna_cor_pulsa_alfa_e_volta_ao_normal_apos_a_troca() -> void:
	var ciclo := _ciclo(Enums.COLOR.AMARELO, 1.0)
	var p := _nova(Enums.COLOR.AMARELO, ciclo)
	var atual := Enums.get_cor(Enums.COLOR.AMARELO)
	var proxima := Enums.get_cor(ciclo.proxima_cor())
	p._physics_process(0.3)
	assert_eq(p.sprite.modulate, atual, "fora do aviso: cor atual com brilho normal")
	var viu_atual := false
	var viu_proxima := false
	var alfa_baixo := false
	for i in 20:
		p._physics_process(0.02)
		var m: Color = p.sprite.modulate
		if m.r == atual.r and m.g == atual.g and m.b == atual.b and m.a == 1.0:
			viu_atual = true
		if m.r == proxima.r and m.g == proxima.g and m.b == proxima.b:
			viu_proxima = true
		if m.a < 1.0:
			alfa_baixo = true
	assert_true(ciclo.em_aviso(), "dentro do aviso")
	assert_true(viu_atual, "mostrou a cor atual")
	assert_true(viu_proxima, "mostrou a proxima cor")
	assert_true(alfa_baixo, "alfa pulsou")
	p._physics_process(0.4)
	assert_eq(p.color, ciclo.cor_atual(), "trocou")
	assert_eq(p.sprite.modulate, Enums.get_cor(p.color), "apos a troca: cor nova, brilho normal")


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
	assert_true(p.shape.disabled, "nao solidifica sobre o gecko")
	corpo.global_position = Vector2(100.0, 400.0)
	await wait_physics_frames(3)
	p._physics_process(0.016)
	assert_eq(p.color, Enums.COLOR.VERDE, "gecko saiu: troca aplicada")
	assert_false(p.shape.disabled, "solida depois que o gecko saiu")
