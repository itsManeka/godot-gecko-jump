extends GutTest

# Regra pura das linhas iniciais (InitialRows.initial_row_ys). Sem cena: so numeros.


func test_initial_row_ys_valores_exatos_320_400_462() -> void:
	assert_true(
		InitialRows.initial_row_ys(320.0) == [-10.0, 40.0, 90.0, 140.0, 190.0, 240.0, 290.0],
		"altura 320: 7 linhas de -10 a 290 em passo 50"
	)
	assert_true(
		InitialRows.initial_row_ys(400.0)
		== [-10.0, 40.0, 90.0, 140.0, 190.0, 240.0, 290.0, 340.0, 390.0],
		"altura 400: 9 linhas de -10 a 390 em passo 50"
	)
	assert_true(
		InitialRows.initial_row_ys(462.0)
		== [-10.0, 40.0, 90.0, 140.0, 190.0, 240.0, 290.0, 340.0, 390.0, 440.0],
		"altura 462: 10 linhas de -10 a 440 em passo 50"
	)


func test_limite_estrito_e_borda_inferior_sem_faixa_vazia() -> void:
	# y < altura e estrito: 290 exclui o 290; 291 inclui o 290.
	var ys_290 := InitialRows.initial_row_ys(290.0)
	assert_true(ys_290.back() == 240.0, "altura 290 exclui o y=290: ultimo y deve ser 240")
	var ys_291 := InitialRows.initial_row_ys(291.0)
	assert_true(ys_291.back() == 290.0, "altura 291 inclui o y=290: ultimo y deve ser 290")
	# Para alturas variadas: ultimo y em [altura - 50, altura) e passo sempre 50.
	for h in range(200, 500):
		var altura := float(h)
		var ys := InitialRows.initial_row_ys(altura)
		assert_true(ys.back() >= altura - 50.0, "faixa vazia acima de 50 px em altura %s" % altura)
		assert_true(ys.back() < altura, "ultimo y ultrapassa a altura em %s" % altura)
		for i in range(1, ys.size()):
			assert_eq(ys[i] - ys[i - 1], 50.0, "passo diferente de 50 em altura %s" % altura)


func test_altura_320_prefixo_sao_os_5_y_do_tscn() -> void:
	var texto := FileAccess.get_file_as_string("res://scenes/ScrollLevel.tscn")
	var re := RegEx.new()
	re.compile("position = Vector2\\( 0, (-?[0-9.]+) \\)")
	var ys_tscn: Array[float] = []
	for m in re.search_all(texto):
		ys_tscn.append(m.get_string(1).to_float())
	assert_eq(ys_tscn.size(), 5, "o .tscn deve ter 5 nos de linha com position x=0")
	var ys := InitialRows.initial_row_ys(320.0)
	assert_eq(ys.slice(0, 5), ys_tscn)


func test_altura_sem_linha_devolve_vazio() -> void:
	assert_eq(InitialRows.initial_row_ys(-20.0), [])


func test_altura_no_topo_devolve_so_a_primeira_linha() -> void:
	assert_eq(InitialRows.initial_row_ys(0.0), [-10.0])
