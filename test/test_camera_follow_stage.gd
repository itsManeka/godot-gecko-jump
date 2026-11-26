extends GutTest

# T2 de f489-camera-acompanha-gecko-no-alto-46 (reescrito em f519-gecko-camera-mais-suave): Stage real (SubViewport) com
# o avanco da camera do topo aplicado depois do Player, agora em easing (CameraFollow.parcela por frame). Limite, excesso,
# duracao e piso vem de CameraFollow, nunca copiados da implementacao. O Player tem a fisica desligada nos testes de
# varios frames (sem gravidade/pulo): o y do gecko so muda pelo avanco da camera e pelo que o teste faz.

const STAGE := "res://scenes/Stage.tscn"
const ALTURA := 640
const PASSO := 1.0 / 60.0
const EPS := 0.0001
# excesso(200, 256) (2x do criterio de aceite do 01 em 180x320): gecko 56 px acima do limite com altura 640
const EXCESSO_01 := 56.0
# Excesso de 1 frame de pulo (o pior caso que o pulo mede) e o cenario do repro (y global -70,8, acima do topo)
const EXCESSO_PULO := 8.0
const Y_REPRO := -70.8
# Altura cujo limite (266,4) fica acima do y em float32: unico caso do f531 com residuo positivo
const ALTURA_COM_RESIDUO := 666
var _sv: SubViewport
var _stage: Node
var _scroll: Node
var _p: Node


func before_each() -> void:
	Global.tutorial_visto_espelho = true
	Global.platforms = []
	Global.iniciado = false


func after_each() -> void:
	get_tree().paused = false
	if is_instance_valid(_p):
		_p.end = true
	Global.platforms = []
	Global.iniciado = false


# y do limite de topo para a altura do SubViewport (fracao lida de CameraFollow, nao literal no teste)
func _limite(altura: int = ALTURA) -> float:
	return CameraFollow.limite_y(float(altura))


# Teto de frames para um excesso: duracao + 1 frame por piso de parcela + 1 (mesmo teto do helper de T1)
func _teto(excesso: float) -> int:
	return CameraFollow.DURACAO_FRAMES + int(ceil(excesso / CameraFollow.PASSO_MINIMO_PX)) + 1


# Cota analitica justa do contrato de CameraFollow.parcela (sem laco, sem reproduzir a parcela): fase geometrica ate o
# restante cair a DURACAO_FRAMES * PASSO_MINIMO_PX, depois DURACAO_FRAMES frames de piso e 1 de folga. Protege contra
# regressao de velocidade em excesso grande: um easing so no piso (excesso / PASSO frames) estoura esta cota.
func _teto_justo(excesso: float) -> int:
	var restante_piso: float = CameraFollow.DURACAO_FRAMES * CameraFollow.PASSO_MINIMO_PX
	var geometricos: int = 0
	if excesso > restante_piso:
		var fator: float = 1.0 - 1.0 / float(CameraFollow.DURACAO_FRAMES)
		geometricos = int(ceil(log(excesso / restante_piso) / (-log(fator))))
	return geometricos + CameraFollow.DURACAO_FRAMES + 1


# Stage real em SubViewport 360x640. Com `com_curva` false o scroll da curva fica desligado (valor exato do excesso);
# com `com_curva` true vale o scroll do estagio 0 (40 px/s). Player e Stage seguem com physics ligado: a ordem de
# processamento (Player antes da Stage) e parte do que se verifica.
func _spawn(com_curva: bool = false, altura: int = ALTURA) -> void:
	_sv = SubViewport.new()
	_sv.size = Vector2i(360, altura)
	add_child_autofree(_sv)
	_stage = load(STAGE).instantiate()
	_sv.add_child(_stage)
	_scroll = _stage.get_node("ScrollLevel")
	_p = _stage.get_node("Node2D/Player")
	_scroll.dificuldade = null
	if not com_curva:
		_scroll.set_physics_process(false)
	await wait_process_frames(1)


# Partida em curso com o gecko `excesso` px acima do limite e a fisica do Player desligada
func _iniciar_com_gecko_acima(excesso: float, altura: int = ALTURA) -> void:
	_stage._on_Play_button_down()
	_p.set_physics_process(false)
	_p.global_position.y = _limite(altura) - excesso
	_p.velocity.y = 0.0


# Exatamente 1 physics frame completo (o awaiter do GUT espera n+1, entao nao serve para contar frames). O sinal
# physics_frame sai ANTES de os nos processarem o tick e process_frame depois dele: esperar os dois deixa o estado de
# fim de tick (Player, ScrollLevel e Stage ja processados)
func _frame() -> void:
	await get_tree().physics_frame
	await get_tree().process_frame


# Roda physics frames ate o gecko chegar ao limite (ou passar do teto); devolve quantos frames precisou
func _frames_ate_limite(teto: int, altura: int = ALTURA) -> int:
	var n: int = 0
	while n <= teto and CameraFollow.excesso(_p.global_position.y, _limite(altura)) > EPS:
		await _frame()
		n += 1
	return n


# C432: gecko 28 px acima do limite: plataformas e position_scrolled avancam juntos e o delta total, ao fim do easing,
# e o excesso (o gecko termina no limite)
func test_c432_gecko_acima_do_limite_converge_ao_limite() -> void:
	await _spawn()
	await _iniciar_com_gecko_acima(EXCESSO_01)
	var plataformas_antes: float = _scroll.running_platforms.position.y
	var scrolled_antes: float = _scroll.position_scrolled

	var frames: int = await _frames_ate_limite(_teto(EXCESSO_01))

	var delta_plataformas: float = _scroll.running_platforms.position.y - plataformas_antes
	var delta_scrolled: float = _scroll.position_scrolled - scrolled_antes
	assert_lte(frames, _teto(EXCESSO_01), "C432: converge em numero finito de frames")
	assert_almost_eq(_p.global_position.y, _limite(), EPS, "C432: o gecko termina no limite ao fim do easing")
	assert_almost_eq(delta_plataformas, delta_scrolled, EPS, "C432: plataformas e position_scrolled avancam juntos")
	assert_almost_eq(delta_plataformas, EXCESSO_01, EPS, "C432: o delta total e o excesso do gecko (curva desligada)")


# C433: cenario do repro (y global -35,4, acima do topo). O gecko nunca desce abaixo do y inicial (o primeiro frame
# pode ainda estar acima do topo), termina em y >= 0 e no limite de topo
func test_c433_gecko_acima_do_topo_y_negativo_nao_fica_acima_da_tela() -> void:
	await _spawn()
	await _iniciar_com_gecko_acima(_limite() - Y_REPRO)
	assert_almost_eq(_p.global_position.y, Y_REPRO, EPS, "C433: pre-condicao do repro (y negativo)")
	var teto: int = _teto(_limite() - Y_REPRO)
	var n: int = 0
	var y_anterior: float = _p.global_position.y

	while n <= teto and CameraFollow.excesso(_p.global_position.y, _limite()) > EPS:
		await _frame()
		n += 1
		assert_gte(_p.global_position.y, y_anterior, "C433: o gecko nunca volta para mais alto que o frame anterior")
		y_anterior = _p.global_position.y

	assert_gte(_p.global_position.y, 0.0, "C433: ao fim do easing o gecko nunca esta fora do topo (y >= 0)")
	assert_almost_eq(_p.global_position.y, _limite(), EPS, "C433: o gecko para no limite de topo")


# C434: com a curva de dificuldade (scroll > 0) o avanco e curva + parcela, nunca menor que a curva
func test_c434_avanco_soma_curva_e_excesso_nunca_menor_que_a_curva() -> void:
	await _spawn(true)
	_scroll.dificuldade = _stage.dificuldade
	await _iniciar_com_gecko_acima(EXCESSO_01)
	var curva: float = DifficultySnapshot.de(_stage.dificuldade).get_scroll() * PASSO
	assert_gt(curva, 0.0, "C434: pre-condicao de dificuldade real com scroll positivo")
	var teto: int = _teto(EXCESSO_01)
	var n: int = 0
	var plataformas_antes: float = _scroll.running_platforms.position.y

	while n <= teto and CameraFollow.excesso(_p.global_position.y, _limite()) > EPS:
		await _frame()
		n += 1

	var delta: float = _scroll.running_platforms.position.y - plataformas_antes
	assert_almost_eq(delta, curva * n + EXCESSO_01, 0.2, "C434: o avanco e a soma da curva de cada frame com o excesso")
	assert_gte(delta, curva * n, "C434: o avanco nunca e menor que a curva de dificuldade")
	assert_almost_eq(_p.global_position.y, _limite(), EPS, "C434: o gecko tambem chega ao limite")


# C435: menu (partida nao iniciada) com o gecko acima do limite: gecko e plataformas nao se movem
func test_c435_menu_com_gecko_acima_do_limite_nao_move_nada() -> void:
	await _spawn()
	assert_false(Global.is_iniciado(), "C435: pre-condicao de menu (partida nao iniciada)")
	_p.global_position.y = _limite() - EXCESSO_01
	_p.velocity.y = 0.0
	var gecko_antes: float = _p.global_position.y
	var plataformas_antes: float = _scroll.running_platforms.position.y
	var scrolled_antes: float = _scroll.position_scrolled

	await wait_physics_frames(1)

	assert_almost_eq(_p.global_position.y, gecko_antes, 0.0001, "C435: no menu o gecko nao e deslocado")
	assert_almost_eq(_scroll.running_platforms.position.y, plataformas_antes, 0.0001, "C435: no menu as plataformas nao se movem")
	assert_almost_eq(_scroll.position_scrolled, scrolled_antes, 0.0001, "C435: no menu position_scrolled nao avanca")


# C437: gecko abaixo do limite: o avanco do frame e so a curva (40 px/s no estagio 0), sem excesso
func test_c437_gecko_abaixo_do_limite_avanca_so_a_curva() -> void:
	await _spawn(true)
	_stage._on_Play_button_down()
	_p.global_position.y = _limite() + 60.0
	_p.velocity.y = 0.0
	var plataformas_antes: float = _scroll.running_platforms.position.y

	await wait_physics_frames(1)

	var delta: float = _scroll.running_platforms.position.y - plataformas_antes
	assert_almost_eq(delta, 40.0 * PASSO, 0.1, "C437: abaixo do limite so a curva de 40 px/s move o mundo")


# Gecko `excesso` px acima do limite numa Stage de `altura` px: converge ao limite dessa altura em <= `max_frames`
func _converge_ao_limite(altura: int, excesso: float, max_frames: int, rotulo: String) -> void:
	await _spawn(false, altura)
	await _iniciar_com_gecko_acima(excesso, altura)

	var frames: int = await _frames_ate_limite(max_frames, altura)

	assert_lte(frames, max_frames, "%s: converge em <= %d frames" % [rotulo, max_frames])
	assert_almost_eq(_p.global_position.y, _limite(altura), EPS, "%s: gecko acima do limite converge a ele" % rotulo)


# f531: gecko parado no limite (y = limite arredondado a float32, como o Vector2 guarda) por N frames: o limite e double
# e global_position.y e float32, entao pode sobrar excesso < 1 ulp; position_scrolled nao pode acumular esse residuo
func _parado_no_limite_nao_avanca(altura: int, frames: int) -> void:
	await _spawn(false, altura)
	await _iniciar_com_gecko_acima(0.0, altura)
	var limite: float = _limite(altura)
	var scrolled_antes: float = _scroll.position_scrolled
	var plataformas_antes: float = _scroll.running_platforms.position.y
	var excesso_inicial: float = CameraFollow.excesso(_p.global_position.y, limite)
	gut.p("f531 altura %d: limite=%s y_float32=%s excesso=%s" % [altura, limite, _p.global_position.y, excesso_inicial])
	# Pre-condicao: o excesso e ruido (abaixo do piso); na 333 ele e positivo, entao o teste reproduz o bug sem o fix
	assert_lt(excesso_inicial, CameraFollow.EXCESSO_MINIMO_PX, "f531 altura %d: excesso inicial e ruido de float" % altura)
	if altura == ALTURA_COM_RESIDUO:
		assert_gt(excesso_inicial, 0.0, "f531 altura %d: o residuo existe (limite em double acima do y em float32)" % altura)

	for i in range(frames):
		_scroll.avancar_camera(_p, limite)

	assert_eq(_scroll.position_scrolled, scrolled_antes, "f531 altura %d: position_scrolled nao muda com o gecko parado no limite (%d frames)" % [altura, frames])
	assert_eq(_scroll.running_platforms.position.y, plataformas_antes, "f531 altura %d: as plataformas nao se movem com o gecko parado no limite" % altura)


# f531: so a 666 (limite 266,4) deixa residuo positivo: o float32 arredonda para baixo. 924 (369,6) e 1034 (413,6)
# arredondam para cima (excesso 0); 640 e 800 tem limite exato. Todas entram como guarda.
func test_f531_gecko_parado_no_limite_nao_acumula_residuo_de_float() -> void:
	for altura in [924, 666, 1034, 640, 800]:
		await _parado_no_limite_nao_avanca(altura, 600)
		if is_instance_valid(_sv):
			_sv.queue_free()


# f531: excesso de 0,5x o piso (EXCESSO_MINIMO_PX) e ignorado; 4x o piso ainda avanca a camera
func test_f531_excesso_acima_do_piso_avanca_e_abaixo_do_piso_nao() -> void:
	await _spawn()
	await _iniciar_com_gecko_acima(0.0)
	var scrolled_antes: float = _scroll.position_scrolled

	_p.global_position.y = _limite() - CameraFollow.EXCESSO_MINIMO_PX / 2.0
	_scroll.avancar_camera(_p, _limite())
	assert_eq(_scroll.position_scrolled, scrolled_antes, "f531: excesso abaixo do piso e ignorado")

	_p.global_position.y = _limite() - CameraFollow.EXCESSO_MINIMO_PX * 4.0
	_scroll.avancar_camera(_p, _limite())
	assert_gt(_scroll.position_scrolled, scrolled_antes, "f531: excesso acima do piso continua avancando")


# C438: altura 640, limite 256
func test_c438_altura_640_gecko_acima_do_limite_converge_a_256() -> void:
	await _converge_ao_limite(640, EXCESSO_01, _teto_justo(EXCESSO_01), "C438")
	assert_almost_eq(_p.global_position.y, 256.0, EPS, "C438: limite da altura 640 e 256")


# C439: altura 800, limite 320
func test_c439_altura_800_gecko_acima_do_limite_converge_a_320() -> void:
	await _converge_ao_limite(800, EXCESSO_01, _teto_justo(EXCESSO_01), "C439")
	assert_almost_eq(_p.global_position.y, 320.0, EPS, "C439: limite da altura 800 e 320")


# C440: altura 924, limite 369.6
func test_c440_altura_924_gecko_acima_do_limite_converge_a_369_6() -> void:
	await _converge_ao_limite(924, EXCESSO_01, _teto_justo(EXCESSO_01), "C440")
	assert_almost_eq(_p.global_position.y, 369.6, EPS, "C440: limite da altura 924 e 369.6")


# C441: excesso de 320 px (> ESPACAMENTO): ao fim do easing as linhas novas nascem sem buraco, a ESPACAMENTO uma da outra.
# Player sem fisica: a gravidade de 40 frames tiraria parte do excesso (o teste mede a geracao, nao a queda)
func test_c441_avanco_grande_cria_linhas_sem_buraco() -> void:
	await _spawn()
	_stage._on_Play_button_down()
	_p.set_physics_process(false)
	var antes: Array = _scroll.running_platforms.get_children()
	_p.global_position.y = _limite() - 320.0
	_p.velocity.y = 0.0

	await _frames_ate_limite(_teto(320.0))
	await wait_process_frames(1)

	var ys: Array = []
	for filho in _scroll.running_platforms.get_children():
		if not antes.has(filho):
			ys.append(filho.position.y)
	ys.sort()
	var esperadas: int = int(floor((320.0 + 0.0001) / InitialRows.ESPACAMENTO))
	assert_eq(ys.size(), esperadas, "C441: uma linha nova por ESPACAMENTO de excesso")
	for i in range(1, ys.size()):
		assert_almost_eq(ys[i] - ys[i - 1], InitialRows.ESPACAMENTO, 0.0001, "C441: linhas consecutivas sem buraco")


# C501: gecko em limite - 4 (sem curva): o acumulado de running_platforms.position.y e de position_scrolled ao fim do easing
# e o excesso original, igual nos dois, e o gecko termina no limite
func test_c501_acumulado_do_easing_e_o_excesso_original() -> void:
	await _spawn()
	await _iniciar_com_gecko_acima(EXCESSO_PULO)
	var plataformas_antes: float = _scroll.running_platforms.position.y
	var scrolled_antes: float = _scroll.position_scrolled

	await _frames_ate_limite(CameraFollow.DURACAO_FRAMES)

	var delta_plataformas: float = _scroll.running_platforms.position.y - plataformas_antes
	var delta_scrolled: float = _scroll.position_scrolled - scrolled_antes
	assert_almost_eq(delta_plataformas, EXCESSO_PULO, EPS, "C501: o acumulado das plataformas e o excesso original")
	assert_almost_eq(delta_scrolled, EXCESSO_PULO, EPS, "C501: o acumulado de position_scrolled e o excesso original")
	assert_almost_eq(delta_plataformas, delta_scrolled, EPS, "C501: o delta total e igual nos dois")
	assert_almost_eq(_p.global_position.y, _limite(), EPS, "C501: o gecko termina no limite")


# C502: excesso de 4 px converge em <= DURACAO_FRAMES; o do repro (y = -35,4) em numero finito; nenhum frame deixa o
# excesso crescer em relacao ao anterior
func test_c502_converge_em_duracao_frames_sem_o_excesso_crescer() -> void:
	await _spawn()
	await _iniciar_com_gecko_acima(EXCESSO_PULO)
	var frames_pulo: int = await _frames_ate_limite(CameraFollow.DURACAO_FRAMES)
	assert_lte(frames_pulo, CameraFollow.DURACAO_FRAMES, "C502: excesso de 4 px converge em <= DURACAO_FRAMES frames")
	assert_almost_eq(_p.global_position.y, _limite(), EPS, "C502: o excesso de 4 px zerou")

	_p.global_position.y = Y_REPRO
	var inicial: float = CameraFollow.excesso(_p.global_position.y, _limite())
	var teto: int = _teto(inicial)
	var anterior: float = inicial
	var n: int = 0
	while n <= teto and anterior > EPS:
		await _frame()
		n += 1
		var atual: float = CameraFollow.excesso(_p.global_position.y, _limite())
		assert_lte(atual, anterior + EPS, "C502: o excesso nao cresce entre dois frames consecutivos")
		anterior = atual
	assert_lte(n, teto, "C502: o excesso do repro converge em numero finito de frames")
	assert_almost_eq(_p.global_position.y, _limite(), EPS, "C502: o excesso do repro zerou")


# C503: gecko nunca com global_position.y < 0, frame a frame. Caso realista (afirma y >= 0 em TODO frame): o gecko re-sobe
# 4 px a cada frame por 30 frames. Caso do C433 (y = -35,4; so afirma o que o 01 promete): y >= 0 ao fim e nunca abaixo do
# y inicial (o 1o frame pode ainda estar acima do topo)
func test_c503_gecko_nunca_abaixo_do_topo_no_caso_realista_e_no_do_repro() -> void:
	await _spawn()
	await _iniciar_com_gecko_acima(0.0)
	var subiu: bool = false
	for i in range(30):
		_p.global_position.y -= EXCESSO_PULO
		subiu = subiu or _p.global_position.y < _limite()
		await _frame()
		assert_gte(_p.global_position.y, 0.0, "C503 realista: frame %d com y >= 0" % i)
	assert_true(subiu, "C503 realista: pre-condicao, o gecko ficou acima do limite durante o teste")

	_p.global_position.y = Y_REPRO
	var y_anterior: float = _p.global_position.y
	for i in range(_teto(_limite() - Y_REPRO)):
		await _frame()
		assert_gte(_p.global_position.y, y_anterior, "C503 repro: frame %d nunca abaixo do y inicial/anterior" % i)
		y_anterior = _p.global_position.y
	assert_gte(_p.global_position.y, 0.0, "C503 repro: ao fim do easing y >= 0")


# Segunda Stage (referencia), sem scroll da curva e com o Player sem fisica; devolve [stage, scroll, player]
func _stage_referencia() -> Array:
	var sv := SubViewport.new()
	sv.size = Vector2i(360, ALTURA)
	add_child_autofree(sv)
	var st: Node = load(STAGE).instantiate()
	sv.add_child(st)
	var sc: Node = st.get_node("ScrollLevel")
	var pl: Node = st.get_node("Node2D/Player")
	sc.dificuldade = null
	sc.set_physics_process(false)
	pl.set_physics_process(false)
	return [st, sc, pl]


# y local de todas as linhas do gerador, ordenados
func _ys_das_linhas(scroll: Node) -> Array:
	var ys: Array = []
	for filho in scroll.running_platforms.get_children():
		ys.append(filho.position.y)
	ys.sort()
	return ys


# C504: referencia de hoje (excesso inteiro de uma vez na segunda Stage): _rows_spawned e o y local de cada linha nova sao
# iguais aos do easing, apos varios excessos (mais de 1 ESPACAMENTO inclusive)
func test_c504_linhas_novas_iguais_a_referencia_do_excesso_inteiro() -> void:
	await _spawn()
	var ref: Array = _stage_referencia()
	var ref_stage: Node = ref[0]
	var ref_scroll: Node = ref[1]
	var ref_p: Node = ref[2]
	_stage._on_Play_button_down()
	ref_stage._on_Play_button_down()
	_p.set_physics_process(false)

	for excesso in [EXCESSO_01, 140.0, 320.0, EXCESSO_PULO]:
		_p.global_position.y = _limite() - excesso
		ref_p.global_position.y = _limite() - excesso
		# referencia: o comportamento anterior ao easing, com o excesso inteiro num frame so
		ref_scroll.running_platforms.position.y += excesso
		ref_scroll.position_scrolled += excesso
		ref_p.global_position.y += excesso
		ref_scroll._criar_linhas_pendentes()
		# easing: avancar_camera ate convergir
		var n: int = 0
		while n <= _teto(excesso) and CameraFollow.excesso(_p.global_position.y, _limite()) > EPS:
			_scroll.avancar_camera(_p, _limite())
			n += 1
		assert_lte(n, _teto(excesso), "C504: o easing converge para o excesso %s" % excesso)

	await wait_process_frames(1)

	assert_gt(_scroll._rows_spawned, 0, "C504: pre-condicao, o excesso total gerou linhas")
	assert_eq(_scroll._rows_spawned, ref_scroll._rows_spawned, "C504: _rows_spawned igual ao da referencia")
	assert_almost_eq(_scroll.position_scrolled, ref_scroll.position_scrolled, EPS, "C504: position_scrolled igual ao da referencia")
	assert_eq(_ys_das_linhas(_scroll), _ys_das_linhas(ref_scroll), "C504: y local de cada linha igual ao da referencia")


# C505: tree.paused no meio do easing congela as tres grandezas; ao despausar termina o restante e fecha no limite
func test_c505_pausa_no_meio_do_easing_congela_e_ao_despausar_fecha_no_limite() -> void:
	await _spawn()
	await _iniciar_com_gecko_acima(80.0)
	await _frame()
	var y_pausa: float = _p.global_position.y
	var plataformas_pausa: float = _scroll.running_platforms.position.y
	var scrolled_pausa: float = _scroll.position_scrolled
	assert_gt(CameraFollow.excesso(y_pausa, _limite()), 0.0, "C505: pre-condicao, pausou no meio do easing")

	get_tree().paused = true
	for i in range(5):
		await _frame()

	assert_eq(_p.global_position.y, y_pausa, "C505: o gecko nao se move pausado")
	assert_eq(_scroll.running_platforms.position.y, plataformas_pausa, "C505: as plataformas nao se movem pausadas")
	assert_eq(_scroll.position_scrolled, scrolled_pausa, "C505: position_scrolled nao avanca pausado")

	get_tree().paused = false
	await _frames_ate_limite(_teto(80.0))

	assert_almost_eq(_p.global_position.y, _limite(), EPS, "C505: ao despausar o restante termina no limite")


# C506: partida nao iniciada com o gecko acima do limite: nada se move ao longo de varios frames
func test_c506_partida_nao_iniciada_nao_move_nada_em_varios_frames() -> void:
	await _spawn()
	_p.set_physics_process(false)
	_p.global_position.y = _limite() - EXCESSO_01
	assert_false(Global.is_iniciado(), "C506: pre-condicao de partida nao iniciada")
	var gecko_antes: float = _p.global_position.y
	var plataformas_antes: float = _scroll.running_platforms.position.y
	var scrolled_antes: float = _scroll.position_scrolled

	for i in range(5):
		await _frame()

	assert_eq(_p.global_position.y, gecko_antes, "C506: o gecko nao e deslocado")
	assert_eq(_scroll.running_platforms.position.y, plataformas_antes, "C506: as plataformas nao se movem")
	assert_eq(_scroll.position_scrolled, scrolled_antes, "C506: position_scrolled nao avanca")


# C507: o player.y publicado pela ponte (Stage._posicao_publicada, o mesmo par de _posicao_atual) e o par arredondado de
# global_position em cada frame do easing e termina igual ao limite arredondado
func test_c507_posicao_publicada_acompanha_o_gecko_em_cada_frame_do_easing() -> void:
	await _spawn()
	await _iniciar_com_gecko_acima(EXCESSO_01)
	var teto: int = _teto(EXCESSO_01)
	var n: int = 0
	while n <= teto and CameraFollow.excesso(_p.global_position.y, _limite()) > EPS:
		await _frame()
		n += 1
		var par := Vector2i(roundi(_p.global_position.x), roundi(_p.global_position.y))
		assert_eq(_stage._posicao_publicada, par, "C507: frame %d publica o par arredondado de global_position" % n)
		assert_eq(_stage._posicao_atual(), par, "C507: frame %d _posicao_atual e o mesmo par" % n)

	assert_gt(n, 1, "C507: pre-condicao, o easing durou mais de 1 frame")
	var limite_par := Vector2i(roundi(_p.global_position.x), roundi(_limite()))
	assert_eq(_stage._posicao_publicada, limite_par, "C507: termina publicando o limite arredondado")


# C508: a curva de scroll continua somando por cima: no 1o frame o avanco e a curva + a parcela do excesso
func test_c508_curva_soma_por_cima_da_parcela_no_frame() -> void:
	await _spawn(true)
	_scroll.dificuldade = _stage.dificuldade
	await _iniciar_com_gecko_acima(EXCESSO_01)
	var curva: float = DifficultySnapshot.de(_stage.dificuldade).get_scroll() * PASSO
	assert_gt(curva, 0.0, "C508: pre-condicao de dificuldade real com scroll positivo")
	var parcela: float = CameraFollow.parcela(EXCESSO_01)
	var plataformas_antes: float = _scroll.running_platforms.position.y

	await _frame()

	var delta: float = _scroll.running_platforms.position.y - plataformas_antes
	assert_almost_eq(delta, curva + parcela, 0.1,"C508: o avanco do frame e curva + parcela")
	assert_gte(delta, curva, "C508: o avanco nunca e menor que a curva")


# C509: altura 640 (limite 256), excesso de 8 px converge em <= DURACAO_FRAMES
func test_c509_altura_640_excesso_de_8_px_converge_ao_limite_em_duracao_frames() -> void:
	await _converge_ao_limite(640, EXCESSO_PULO, CameraFollow.DURACAO_FRAMES, "C509")
	assert_almost_eq(_p.global_position.y, CameraFollow.limite_y(640.0), EPS, "C509: limite da altura 640")


# C510: altura 800 (limite 320), idem
func test_c510_altura_800_excesso_de_8_px_converge_ao_limite_em_duracao_frames() -> void:
	await _converge_ao_limite(800, EXCESSO_PULO, CameraFollow.DURACAO_FRAMES, "C510")
	assert_almost_eq(_p.global_position.y, CameraFollow.limite_y(800.0), EPS, "C510: limite da altura 800")


# C511: altura 924 (limite 369,6), idem
func test_c511_altura_924_excesso_de_8_px_converge_ao_limite_em_duracao_frames() -> void:
	await _converge_ao_limite(924, EXCESSO_PULO, CameraFollow.DURACAO_FRAMES, "C511")
	assert_almost_eq(_p.global_position.y, CameraFollow.limite_y(924.0), EPS, "C511: limite da altura 924")
