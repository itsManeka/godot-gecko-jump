extends GutTest

# T1 de f489-camera-acompanha-gecko-no-alto-46: funcoes puras do limite da camera (CameraFollow).
# Valores esperados vem do criterio de aceite do 01 (T1), nunca copiados da implementacao.

const CameraFollowScript := preload("res://scripts/CameraFollow.gd")


# C429: limite_y(320) == 128 (fracao 0,40 da altura visivel)
func test_limite_y_altura_320_e_128() -> void:
	assert_almost_eq(CameraFollowScript.limite_y(320.0), 128.0, 0.0001)


# C430: limite_y(400) == 160 (proporcional, altura de test_scroll_level_altura.gd)
func test_limite_y_altura_400_e_160() -> void:
	assert_almost_eq(CameraFollowScript.limite_y(400.0), 160.0, 0.0001)


# C431: limite_y(462) == 184.8 (fracao 0,40, comparado com tolerancia)
func test_limite_y_altura_462_e_184_8() -> void:
	assert_almost_eq(CameraFollowScript.limite_y(462.0), 184.8, 0.0001)


# C427: acima do limite devolve 28; acima do topo com y negativo devolve 163.4
func test_excesso_gecko_acima_do_limite_e_do_topo_y_negativo() -> void:
	assert_eq(CameraFollowScript.excesso(100.0, 128.0), 28.0)
	assert_almost_eq(CameraFollowScript.excesso(-35.4, 128.0), 163.4, 0.0001)


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
	assert_eq(CameraFollowScript.excesso(128.0, 128.0), 0.0)
	assert_eq(CameraFollowScript.excesso(200.0, 128.0), 0.0)
