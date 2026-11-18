extends GutTest

# Ponto de extensao de velocidade em Platform (f467 T2): C267-C269.

const PLATAFORMA_CENA := preload("res://scenes/Platform.tscn")
const PLAYER_CENA := preload("res://scenes/Player.tscn")
const X_INICIAL := 160.0
const Y_LINHA := 300.0
# C269: parte perto da borda direita para a plataforma andar um periodo inteiro sem o gecko cruzar x < 0 (wrap do Player)
const X_INICIAL_C269 := 170.0
# Janela de medicao em physics frames (x2 de 60 Hz = 2 s): erro de um frame fica abaixo de 0,5 px/s
const FRAMES_MEDICAO := 120
# C269: deriva maxima aceita do x relativo gecko-plataforma (px) com desvio oscilando em media zero
const TOLERANCIA_DERIVA_PX := 2.0
# C269: amplitude de pico da velocidade do desvio (px/s) e periodo (s) de uma oscilacao de teste
const DESVIO_PICO := 20.0
const PERIODO_S := 2.5


func before_each() -> void:
	Global.platforms.clear()
	Global.set_iniciado(false)


func after_each() -> void:
	Global.platforms.clear()
	Global.set_iniciado(false)
	Global.sem_derrota = false


# Plataforma na cena de teste, sem modificadores, com speed e desvio dados.
func _plataforma(speed: float, desvio: float) -> Platform:
	var plataforma: Platform = add_child_autofree(PLATAFORMA_CENA.instantiate())
	plataforma.position = Vector2(X_INICIAL, Y_LINHA)
	plataforma.speed = speed
	plataforma.desvio_vx = desvio
	return plataforma


# C267: desvio_vx 10 somado a speed 60 anda 50 px/s para a esquerda (dx / tempo medido em physics frames).
func test_desvio_vx_10_anda_50_px_por_segundo_para_a_esquerda() -> void:
	Global.set_iniciado(true)
	var plataforma := _plataforma(60.0, 10.0)
	var x0 := plataforma.position.x
	var f0 := Engine.get_physics_frames()
	await wait_physics_frames(FRAMES_MEDICAO)
	var segundos := (Engine.get_physics_frames() - f0) / float(Engine.physics_ticks_per_second)
	var velocidade := (x0 - plataforma.position.x) / segundos
	assert_almost_eq(velocidade, 50.0, 1.0, "speed 60 + desvio_vx 10 anda 50 px/s para a esquerda")


# C267 (controle): desvio_vx 0 e a velocidade de hoje, 60 px/s exatos.
func test_desvio_vx_0_anda_60_px_por_segundo_como_hoje() -> void:
	Global.set_iniciado(true)
	var plataforma := _plataforma(60.0, 0.0)
	var x0 := plataforma.position.x
	var f0 := Engine.get_physics_frames()
	await wait_physics_frames(FRAMES_MEDICAO)
	var segundos := (Engine.get_physics_frames() - f0) / float(Engine.physics_ticks_per_second)
	var velocidade := (x0 - plataforma.position.x) / segundos
	assert_almost_eq(velocidade, 60.0, 1.0, "sem desvio a plataforma anda a speed exata")


# C268: speed 0 com desvio diferente de 0 nao anda antes de Global.is_iniciado().
func test_speed_zero_com_desvio_nao_anda_antes_da_partida() -> void:
	var plataforma := _plataforma(0.0, 10.0)
	var x0 := plataforma.position.x
	await wait_physics_frames(30)
	assert_eq(plataforma.position.x, x0, "plataforma parada com desvio_vx nao anda antes da partida")
	assert_false(plataforma.em_movimento(), "fora da partida, nao esta em movimento")


# C268: em_movimento() so e verdadeiro com speed != 0 e partida iniciada (as 4 combinacoes).
func test_em_movimento_so_com_speed_diferente_de_zero_e_partida() -> void:
	var parada := _plataforma(0.0, 0.0)
	var andando := _plataforma(60.0, 0.0)
	Global.set_iniciado(false)
	assert_false(parada.em_movimento(), "speed 0 sem partida: parada")
	assert_false(andando.em_movimento(), "speed 60 sem partida: parada")
	Global.set_iniciado(true)
	assert_false(parada.em_movimento(), "speed 0 com partida: parada")
	assert_true(andando.em_movimento(), "speed 60 com partida: em movimento")


# Montagem do C269: gecko cai sobre plataforma parada da cor dele, espera pousar (is_on_floor), depois a
# plataforma anda a speed 60 com desvio_vx = pico * cos(w t) (media zero). Mede a deriva do x relativo.
func _deriva_gecko_na_plataforma(pico: float) -> Dictionary:
	# Sem sorteio de cor no pouso: o gecko fica da cor da plataforma (COR_INICIAL), entao a colisao permanece ativa.
	Global.sem_derrota = true
	Global.set_iniciado(true)
	var plataforma: Platform = PLATAFORMA_CENA.instantiate()
	plataforma.color = Enums.COR_INICIAL
	plataforma.position = Vector2(X_INICIAL_C269, Y_LINHA)
	add_child_autofree(plataforma)
	# Player nao tem class_name: o gecko fica sem tipo estatico (o script e acessado por propriedade)
	var gecko = add_child_autofree(PLAYER_CENA.instantiate())
	gecko.color = Enums.COR_INICIAL
	gecko.position = Vector2(X_INICIAL_C269, Y_LINHA - 60.0)
	for i in range(120):
		if gecko.is_on_floor():
			break
		await wait_physics_frames(1)
	var pousou: bool = gecko.is_on_floor()
	var x_plataforma_inicial: float = plataforma.position.x

	plataforma.speed = 60.0
	var omega := TAU / PERIODO_S
	var f0 := Engine.get_physics_frames()
	var deriva_inicial: float = gecko.position.x - plataforma.position.x
	var deriva_maxima := 0.0
	var vel_plataforma_vista_pelo_gecko := 0.0
	var vel_real_plataforma := 0.0
	# Um periodo inteiro da oscilacao. Cada wait_physics_frames(1) do GUT 9 espera 2 ticks (n+1 sinais), entao o
	# laco tem metade dos ticks do periodo: a plataforma anda ~150 px (speed 60) e o gecko nao chega ao wrap da borda
	for i in range(int(PERIODO_S * Engine.physics_ticks_per_second / 2.0)):
		var t := (Engine.get_physics_frames() - f0) / float(Engine.physics_ticks_per_second)
		plataforma.desvio_vx = pico * cos(omega * t)
		await wait_physics_frames(1)
		var deriva := absf((gecko.position.x - plataforma.position.x) - deriva_inicial)
		deriva_maxima = maxf(deriva_maxima, deriva)
		if i == 5:
			vel_plataforma_vista_pelo_gecko = gecko.get_platform_velocity().x
			vel_real_plataforma = plataforma.get_real_velocity().x
	return {
		"pousou": pousou,
		"pousado_no_fim": gecko.is_on_floor(),
		"deriva_maxima": deriva_maxima,
		"deslocamento_plataforma": x_plataforma_inicial - plataforma.position.x,
		"dy_gecko_menos_plataforma": gecko.position.y - plataforma.position.y,
		"vel_plataforma_vista_pelo_gecko": vel_plataforma_vista_pelo_gecko,
		"vel_real_plataforma": vel_real_plataforma,
	}


# C269: gecko pousado em plataforma com desvio oscilando em media zero nao escorrega (deriva do x relativo).
func test_gecko_pousado_nao_deriva_com_desvio_oscilando() -> void:
	var r: Dictionary = await _deriva_gecko_na_plataforma(DESVIO_PICO)
	assert_true(r["pousou"], "gecko pousa na plataforma parada antes da oscilacao")
	var medida := "deriva %.2f px (tolerancia %.1f); deslocamento plataforma %.2f px; dy gecko-plataforma %.2f; pousado no fim %s" % [
		r["deriva_maxima"], TOLERANCIA_DERIVA_PX, r["deslocamento_plataforma"], r["dy_gecko_menos_plataforma"], str(r["pousado_no_fim"])
	]
	assert_lt(r["deriva_maxima"], TOLERANCIA_DERIVA_PX, medida)


# Controle do C269: mesma montagem com desvio_vx = 0. Se este tambem deriva, a montagem esta errada.
func test_controle_sem_desvio_gecko_pousado_nao_deriva() -> void:
	var r: Dictionary = await _deriva_gecko_na_plataforma(0.0)
	assert_true(r["pousou"], "gecko pousa na plataforma parada (controle)")
	var medida := "deriva %.2f px (tolerancia %.1f); deslocamento plataforma %.2f px; dy gecko-plataforma %.2f; pousado no fim %s; vel plataforma vista pelo gecko %.1f; vel real plataforma %.1f" % [
		r["deriva_maxima"], TOLERANCIA_DERIVA_PX, r["deslocamento_plataforma"], r["dy_gecko_menos_plataforma"], str(r["pousado_no_fim"]), r["vel_plataforma_vista_pelo_gecko"], r["vel_real_plataforma"]
	]
	assert_lt(r["deriva_maxima"], TOLERANCIA_DERIVA_PX, medida)
