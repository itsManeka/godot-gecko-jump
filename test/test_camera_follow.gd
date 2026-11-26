extends GutTest

# T1 de f489-camera-acompanha-gecko-no-alto-46: funcoes puras do limite da camera (CameraFollow).
# Valores esperados vem do criterio de aceite do 01 (T1), nunca copiados da implementacao.

const CameraFollowScript := preload("res://scripts/CameraFollow.gd")


# C429: limite_y(640) == 256 (fracao 0,40 da altura visivel 360x640)
func test_limite_y_altura_640_e_256() -> void:
	assert_almost_eq(CameraFollowScript.limite_y(640.0), 256.0, 0.0001)


# C430: limite_y(800) == 320 (proporcional, altura de test_scroll_level_altura.gd)
func test_limite_y_altura_800_e_320() -> void:
	assert_almost_eq(CameraFollowScript.limite_y(800.0), 320.0, 0.0001)


# C431: limite_y(924) == 369.6 (fracao 0,40, comparado com tolerancia)
func test_limite_y_altura_924_e_369_6() -> void:
	assert_almost_eq(CameraFollowScript.limite_y(924.0), 369.6, 0.0001)


# C427: acima do limite devolve 56; acima do topo com y negativo devolve 326.8
func test_excesso_gecko_acima_do_limite_e_do_topo_y_negativo() -> void:
	assert_eq(CameraFollowScript.excesso(200.0, 256.0), 56.0)
	assert_almost_eq(CameraFollowScript.excesso(-70.8, 256.0), 326.8, 0.0001)


# C814: passo minimo dobrado (2.0 px) e paridade de ticks com a base 180x320 (passo 1.0 px):
# o numero de frames ate o snap do easing em 2x o excesso e igual ao de 1x com o passo original.
func test_passo_minimo_dobrado_e_paridade_de_ticks_com_180x320() -> void:
	assert_eq(CameraFollowScript.PASSO_MINIMO_PX, 2.0, "PASSO_MINIMO_PX dobra para 2.0 (base 360x640)")
	for excesso in [0.5, 4.0, 37.5, 80.0]:
		assert_eq(
			_frames_com_passo(excesso * 2.0, CameraFollowScript.PASSO_MINIMO_PX),
			_frames_com_passo(excesso, 1.0),
			"frames ate o snap do excesso %s em 2x == 1x (passo 1.0)" % excesso
		)


# Frames ate zerar o excesso com DURACAO_FRAMES e um piso de passo dado (mesma formula de parcela()).
func _frames_com_passo(excesso: float, passo: float) -> int:
	var restante: float = excesso
	var frames: int = 0
	while restante > 0.0 and frames < 1000:
		var p: float = minf(restante, maxf(restante / float(CameraFollowScript.DURACAO_FRAMES), passo))
		restante -= p
		frames += 1
	return frames


# Aplica parcela(restante) e desce o restante ate zerar (ou ate o teto de iteracoes).
# Devolve {"parcelas": Array, "restante": float, "frames": int}.
func _iterar(excesso: float, restante_inicial: float = -1.0) -> Dictionary:
	var restante: float = excesso if restante_inicial < 0.0 else restante_inicial
	var teto: int = CameraFollowScript.DURACAO_FRAMES + int(ceil(restante / CameraFollowScript.PASSO_MINIMO_PX)) + 1
	var parcelas: Array = []
	while restante > 0.0 and parcelas.size() < teto:
		var p: float = CameraFollowScript.parcela(restante)
		parcelas.append(p)
		restante -= p
	return {"parcelas": parcelas, "restante": restante, "frames": parcelas.size(), "teto": teto}


# C495: soma das parcelas iteradas ate zerar == excesso original (esperado = a entrada, nao a saida)
func test_soma_das_parcelas_igual_ao_excesso_original() -> void:
	for excesso in [0.3, 4.0, 37.5, 160.0]:
		var r := _iterar(excesso)
		var soma := 0.0
		for p in r["parcelas"]:
			soma += p
		assert_almost_eq(soma, excesso, 0.0001, "soma das parcelas para excesso %s" % excesso)


# C496: nenhuma parcela excede o restante naquele passo; excesso menor que o piso vira parcela == excesso
func test_parcela_nunca_excede_o_restante() -> void:
	assert_eq(CameraFollowScript.parcela(0.3), 0.3, "0.3 < PASSO_MINIMO_PX: parcela == 0.3, nao o piso")
	for excesso in [0.3, 4.0, 37.5, 160.0]:
		var restante: float = excesso
		var r := _iterar(excesso)
		for p in r["parcelas"]:
			assert_true(p <= restante, "parcela %s <= restante %s" % [p, restante])
			restante -= p


# C497: excesso 0 e negativo devolvem exatamente 0.0
func test_parcela_sem_excesso_ou_negativo_e_zero() -> void:
	assert_eq(CameraFollowScript.parcela(0.0), 0.0)
	assert_eq(CameraFollowScript.parcela(-5.0), 0.0)


# C498: excesso novo no meio da sequencia (maior e menor) converge a 0 em numero finito de frames
func test_excesso_novo_no_meio_converge_em_numero_finito() -> void:
	# O excesso e recalculado a cada frame: o "novo" excesso substitui o restante.
	# maior: 4 aplicado por 1 frame, depois o excesso passa a 40
	var maior := _iterar(0.0, 40.0)
	assert_eq(maior["restante"], 0.0, "4 -> 40 zera")
	assert_true(maior["frames"] < maior["teto"], "4 -> 40 termina antes do teto")
	# menor: 40 aplicado por 1 frame, depois o excesso passa a 1
	var menor := _iterar(0.0, 1.0)
	assert_eq(menor["restante"], 0.0, "40 -> 1 zera")
	assert_true(menor["frames"] < menor["teto"], "40 -> 1 termina antes do teto")


# C499: 4 px zera em <= DURACAO_FRAMES frames e a ultima parcela fecha o resto exato
func test_excesso_de_4_px_zera_em_duracao_frames_com_resto_exato() -> void:
	var r := _iterar(4.0)
	assert_true(r["frames"] <= CameraFollowScript.DURACAO_FRAMES, "frames %s" % r["frames"])
	assert_eq(r["restante"], 0.0, "restante final exato, nao 1e-7")


# C500: curva nao inverte e parcela nunca trava em 0 enquanto resta excesso
func test_parcela_monotona_e_positiva_enquanto_resta_excesso() -> void:
	assert_true(CameraFollowScript.parcela(160.0) >= CameraFollowScript.parcela(4.0))
	for excesso in [0.3, 4.0, 37.5, 160.0]:
		for p in _iterar(excesso)["parcelas"]:
			assert_true(p > 0.0, "parcela > 0 para excesso %s" % excesso)


# C428: no limite e abaixo do limite nunca e negativo
func test_excesso_no_limite_e_abaixo_nunca_negativo() -> void:
	assert_eq(CameraFollowScript.excesso(256.0, 256.0), 0.0)
	assert_eq(CameraFollowScript.excesso(400.0, 256.0), 0.0)
