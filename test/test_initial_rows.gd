extends GutTest

# Regra pura das linhas iniciais (InitialRows.initial_row_ys). Sem cena: so numeros.


func test_initial_row_ys_valores_exatos_640_800_924() -> void:
	assert_true(
		InitialRows.initial_row_ys(640.0) == [-20.0, 80.0, 180.0, 280.0, 380.0, 480.0, 580.0],
		"altura 640: 7 linhas de -20 a 580 em passo 100"
	)
	assert_true(
		InitialRows.initial_row_ys(800.0)
		== [-20.0, 80.0, 180.0, 280.0, 380.0, 480.0, 580.0, 680.0, 780.0],
		"altura 800: 9 linhas de -20 a 780 em passo 100"
	)
	assert_true(
		InitialRows.initial_row_ys(924.0)
		== [-20.0, 80.0, 180.0, 280.0, 380.0, 480.0, 580.0, 680.0, 780.0, 880.0],
		"altura 924: 10 linhas de -20 a 880 em passo 100"
	)


func test_limite_estrito_e_borda_inferior_sem_faixa_vazia() -> void:
	# y < altura e estrito: 580 exclui o 580; 581 inclui o 580.
	var ys_580 := InitialRows.initial_row_ys(580.0)
	assert_true(ys_580.back() == 480.0, "altura 580 exclui o y=580: ultimo y deve ser 480")
	var ys_581 := InitialRows.initial_row_ys(581.0)
	assert_true(ys_581.back() == 580.0, "altura 581 inclui o y=580: ultimo y deve ser 580")
	# Para alturas variadas: ultimo y em [altura - 100, altura) e passo sempre 100.
	for h in range(400, 1000):
		var altura := float(h)
		var ys := InitialRows.initial_row_ys(altura)
		assert_true(ys.back() >= altura - 100.0, "faixa vazia acima de 100 px em altura %s" % altura)
		assert_true(ys.back() < altura, "ultimo y ultrapassa a altura em %s" % altura)
		for i in range(1, ys.size()):
			assert_eq(ys[i] - ys[i - 1], 100.0, "passo diferente de 100 em altura %s" % altura)


func test_altura_640_prefixo_sao_os_5_y_do_tscn() -> void:
	var texto := FileAccess.get_file_as_string("res://scenes/ScrollLevel.tscn")
	var re := RegEx.new()
	re.compile("position = Vector2\\( 0, (-?[0-9.]+) \\)")
	var ys_tscn: Array[float] = []
	for m in re.search_all(texto):
		ys_tscn.append(m.get_string(1).to_float())
	assert_eq(ys_tscn.size(), 5, "o .tscn deve ter 5 nos de linha com position x=0")
	var ys := InitialRows.initial_row_ys(640.0)
	assert_eq(ys.slice(0, 5), ys_tscn)


func test_altura_sem_linha_devolve_vazio() -> void:
	assert_eq(InitialRows.initial_row_ys(-20.0), [])


func test_altura_no_topo_devolve_so_a_primeira_linha() -> void:
	assert_eq(InitialRows.initial_row_ys(0.0), [-20.0])


# C813: as 5 linhas iniciais (y -20, 80, 180, 280, 380) tem indice RowSeed 0, -1, -2, -3, -4 (valor exato).
func test_indice_do_y_das_5_linhas_iniciais_e_0_menos_1_a_menos_4() -> void:
	var ys := InitialRows.initial_row_ys(640.0).slice(0, 5)
	var indices: Array[int] = []
	for y in ys:
		indices.append(RowSeed.indice_do_y(y))
	assert_eq(indices, [0, -1, -2, -3, -4], "indice_do_y das 5 linhas iniciais")
