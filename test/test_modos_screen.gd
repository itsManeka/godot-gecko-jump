extends GutTest

# Tela Modos (carrossel): geometria do handoff, troca por seta/arrasto, indicador, OK e consumo de toque.

var _tela: ModosScreen
var _modo_a: GameMode
var _modo_b: GameMode
var _fechados: Array = []
var _mudancas: Array = []


func before_each() -> void:
	_modo_a = GameModes.classico()
	_modo_b = GameMode.new(&"b", "B", "Modo B", "Descricao do modo B.", ClassicoRule.new())
	_fechados = []
	_mudancas = []
	_tela = ModosScreen.new()
	add_child_autofree(_tela)
	_tela.fechado.connect(func(m: GameMode) -> void: _fechados.append(m.id))
	_tela.modo_mudou.connect(func(m: GameMode) -> void: _mudancas.append(m.id))


func after_each() -> void:
	Global.set_iniciado(false)


func _abrir(lista: Array[GameMode], altura: float = 640.0) -> void:
	_tela.aplicar_layout(Vector2(360.0, altura), Rect2(0.0, 0.0, 360.0, altura))
	assert_true(_tela.abrir(lista[0], lista), "abrir devolve true com o jogo nao iniciado")


func _toque(dedo: int, pressionado: bool, pos: Vector2) -> bool:
	var ev := InputEventScreenTouch.new()
	ev.index = dedo
	ev.pressed = pressionado
	ev.position = pos
	return _tela.tratar_evento(ev)


func _arrasto(dedo: int, pos: Vector2) -> bool:
	var ev := InputEventScreenDrag.new()
	ev.index = dedo
	ev.position = pos
	return _tela.tratar_evento(ev)


func _tocar(pos: Vector2) -> void:
	_toque(0, true, pos)
	_toque(0, false, pos)


func _arrastar_de(inicio: Vector2, dx: float) -> void:
	_toque(0, true, inicio)
	_arrasto(0, inicio + Vector2(dx, 0.0))
	_toque(0, false, inicio + Vector2(dx, 0.0))


func _centro(r: Rect2) -> Vector2:
	return r.get_center()


func test_geometria_em_360x640_e_360x800() -> void:
	# 640: (640 - 458) / 2 = 91 -> y0 = 91 (grade inteira); 800: 171
	for caso in [[640.0, 91.0], [800.0, 171.0]]:
		_tela.aplicar_layout(Vector2(360.0, caso[0]), Rect2(0.0, 0.0, 360.0, caso[0]))
		var y0: float = caso[1]
		assert_eq(_tela.rect_titulo(), Rect2(0.0, y0, 360.0, 60.0), "titulo em %s" % caso[0])
		assert_eq(_tela.rect_imagem(), Rect2(116.0, y0 + 84.0, 128.0, 128.0), "imagem 128x128 em %s" % caso[0])
		assert_eq(_tela.rect_seta_esq(), Rect2(8.0, y0 + 124.0, 48.0, 48.0), "seta esq x 8-56 y 124-172 em %s" % caso[0])
		assert_eq(_tela.rect_seta_dir(), Rect2(304.0, y0 + 124.0, 48.0, 48.0), "seta dir x 304-352 em %s" % caso[0])
		assert_eq(_tela.rect_nome(), Rect2(0.0, y0 + 228.0, 360.0, 34.0), "nome y 228-262 em %s" % caso[0])
		assert_eq(_tela.rect_descricao(), Rect2(20.0, y0 + 270.0, 320.0, 68.0), "descricao y 270-338 em %s" % caso[0])
		assert_eq(_tela.rect_ok(), Rect2(68.0, y0 + 394.0, 224.0, 64.0), "OK x 68-292 y 394-458 em %s" % caso[0])


# C832: ModosScreen (bloco de 458 px) cabe em 640 e na safe area
func test_c832_bloco_de_458_cabe_em_640_e_na_safe_area() -> void:
	var tela := Rect2(0.0, 0.0, 360.0, 640.0)
	_tela.aplicar_layout(Vector2(360.0, 640.0), Rect2(0.0, 0.0, 360.0, 640.0))
	for r in [_tela.rect_titulo(), _tela.rect_imagem(), _tela.rect_seta_esq(), _tela.rect_seta_dir(), _tela.rect_nome(), _tela.rect_descricao(), _tela.rect_ok()]:
		assert_true(tela.encloses(r), "C832: retangulo %s dentro de 360x640" % str(r))
	var safe := Rect2(0.0, 40.0, 360.0, 588.0)
	_tela.aplicar_layout(Vector2(360.0, 640.0), safe)
	for r in [_tela.rect_titulo(), _tela.rect_imagem(), _tela.rect_seta_esq(), _tela.rect_seta_dir(), _tela.rect_nome(), _tela.rect_descricao(), _tela.rect_ok()]:
		assert_true(safe.encloses(r), "C832: retangulo %s dentro da safe area" % str(r))
	assert_eq(_tela.rect_ok().end.y - _tela.rect_titulo().position.y, 458.0, "C832: bloco de 458 px")


func test_arrasto_limiar_32px_e_faixa() -> void:
	_abrir([_modo_a, _modo_b] as Array[GameMode])
	var faixa := _tela.rect_faixa_arrasto()
	assert_eq(faixa, Rect2(60.0, 91.0 + 84.0, 240.0, 254.0), "faixa x 60-300 y 84-338")
	var inicio := _centro(faixa)
	_arrastar_de(inicio, -31.0)
	assert_eq(_tela.modo_exibido().id, _modo_a.id, "31 px nao troca")
	_arrastar_de(inicio, -32.0)
	assert_eq(_tela.modo_exibido().id, _modo_b.id, "32 px troca")
	_arrastar_de(inicio, 32.0)
	assert_eq(_tela.modo_exibido().id, _modo_a.id, "32 px para o outro lado volta")
	# iniciado fora da faixa (acima, y 83 relativo) nao troca
	var fora := Vector2(inicio.x, faixa.position.y - 1.0)
	_arrastar_de(fora, -80.0)
	assert_eq(_tela.modo_exibido().id, _modo_a.id, "iniciado fora da faixa nao troca")
	# borda interna da faixa troca
	_arrastar_de(Vector2(faixa.position.x, faixa.position.y), -32.0)
	assert_eq(_tela.modo_exibido().id, _modo_b.id, "iniciado no canto da faixa troca")


func test_setas_ciclo_e_lista_de_um() -> void:
	_abrir([_modo_a, _modo_b] as Array[GameMode])
	_tocar(_centro(_tela.rect_seta_dir()))
	assert_eq(_tela.modo_exibido().id, _modo_b.id, "seta direita avanca")
	_tocar(_centro(_tela.rect_seta_dir()))
	assert_eq(_tela.modo_exibido().id, _modo_a.id, "ciclo do ultimo volta ao primeiro")
	_tocar(_centro(_tela.rect_seta_esq()))
	assert_eq(_tela.modo_exibido().id, _modo_b.id, "seta esquerda do primeiro vai ao ultimo")
	assert_eq(_mudancas.size(), 3, "cada troca emite modo_mudou")
	# 3 modos distinguem avancar de voltar (com 2 os dois caminhos dao no mesmo)
	var modo_c := GameMode.new(&"c", "C", "Modo C", "Descricao do modo C.", ClassicoRule.new())
	_abrir([_modo_a, _modo_b, modo_c] as Array[GameMode])
	_tocar(_centro(_tela.rect_seta_dir()))
	assert_eq(_tela.modo_exibido().id, _modo_b.id, "3 modos: direita do 1o vai ao 2o")
	_tocar(_centro(_tela.rect_seta_esq()))
	_tocar(_centro(_tela.rect_seta_esq()))
	assert_eq(_tela.modo_exibido().id, modo_c.id, "3 modos: esquerda do 1o vai ao ultimo")
	# lista de 1: seta cicla para o mesmo e arrasto nao muda nada
	var sozinho: Array[GameMode] = [_modo_a]
	_mudancas.clear()
	_abrir(sozinho)
	_tocar(_centro(_tela.rect_seta_dir()))
	_tocar(_centro(_tela.rect_seta_esq()))
	_arrastar_de(_centro(_tela.rect_faixa_arrasto()), -80.0)
	assert_eq(_tela.modo_exibido().id, _modo_a.id, "lista de 1 segue no mesmo modo")
	assert_eq(_mudancas.size(), 0, "lista de 1 nao emite modo_mudou")


func test_indicador_n_marcas_so_a_atual_16x8() -> void:
	var sozinho: Array[GameMode] = [_modo_a]
	_abrir(sozinho)
	var marcas := _tela.rect_marcas()
	assert_eq(marcas.size(), 1, "N = 1 gera 1 marca")
	assert_eq(marcas[0].size, Vector2(16.0, 8.0), "a unica marca e a atual 16x8")
	_abrir([_modo_a, _modo_b] as Array[GameMode])
	marcas = _tela.rect_marcas()
	assert_eq(marcas.size(), 2, "N = 2 gera 2 marcas")
	assert_eq(marcas[0].size, Vector2(16.0, 8.0), "a atual (1a) e 16x8")
	assert_eq(marcas[1].size, Vector2(8.0, 8.0), "a outra e 8x8")
	_tocar(_centro(_tela.rect_seta_dir()))
	marcas = _tela.rect_marcas()
	assert_eq(marcas[0].size, Vector2(8.0, 8.0), "depois da troca a 1a e 8x8")
	assert_eq(marcas[1].size, Vector2(16.0, 8.0), "depois da troca a 2a e 16x8")


func test_c714_indicador_com_modos_reais_5_marcas_em_release_e_6_com_teste_atual_16x8_no_zen() -> void:
	for incluir_teste: bool in [false, true]:
		var modos := GameModes.lista(incluir_teste)
		var indice_zen: int = modos.find(GameModes.zen())
		assert_eq(indice_zen, 3, "C714: o Zen e o 4o modo (teste=%s)" % incluir_teste)
		_tela.aplicar_layout(Vector2(360.0, 640.0), Rect2(0.0, 0.0, 360.0, 640.0))
		assert_true(_tela.abrir(GameModes.zen(), modos), "abrir no Zen devolve true")
		var marcas := _tela.rect_marcas()
		assert_eq(marcas.size(), 6 if incluir_teste else 5, "C714: marcas = modos da lista (teste=%s)" % incluir_teste)
		for i in marcas.size():
			var esperado := Vector2(16.0, 8.0) if i == indice_zen else Vector2(8.0, 8.0)
			assert_eq(marcas[i].size, esperado, "C714: marca %d (teste=%s)" % [i, incluir_teste])
		_tela.fechar()


func test_ok_fecha_consome_toque_sem_texto_toque_e_recusa_com_jogo_iniciado() -> void:
	_abrir([_modo_a, _modo_b] as Array[GameMode])
	_tocar(_centro(_tela.rect_seta_dir()))
	_tocar(_centro(_tela.rect_ok()))
	assert_eq(_fechados, [_modo_b.id], "OK emite fechado com o modo exibido")
	# toque fora dos controles e consumido e nao fecha nem troca
	_fechados.clear()
	assert_true(_toque(1, true, Vector2(2.0, 2.0)), "toque no fundo e consumido (pressionar)")
	assert_true(_toque(1, false, Vector2(2.0, 2.0)), "toque no fundo e consumido (soltar)")
	assert_eq(_fechados.size(), 0, "toque no fundo nao fecha")
	# texto da tela sem "toque"
	var textos: Array[String] = [ModosScreen.TEXTO_TITULO, ModosScreen.TEXTO_OK]
	for modo in [_modo_a, _modo_b]:
		textos.append(modo.nome)
		textos.append(modo.descricao)
	for texto in textos:
		assert_false(texto.to_lower().contains("toque"), "texto sem 'toque': %s" % texto)
	# fechada nao consome; jogo iniciado recusa abrir
	_tela.fechar()
	assert_false(_toque(2, true, Vector2(2.0, 2.0)), "fechada nao consome")
	Global.set_iniciado(true)
	assert_false(_tela.abrir(_modo_a, [_modo_a, _modo_b] as Array[GameMode]), "abrir com jogo iniciado e recusado")
	assert_false(_tela.esta_aberta(), "recusada continua fechada")


func test_input_nao_quebra_quando_ok_tira_a_tela_da_arvore() -> void:
	# f528: o OK recarrega a Stage e o no sai da arvore durante o _input; get_viewport() nao pode ser chamado depois.
	_abrir([_modo_a, _modo_b] as Array[GameMode])
	var pai := _tela.get_parent()
	_tela.fechado.connect(func(_m: GameMode) -> void: pai.remove_child(_tela))
	var centro := _centro(_tela.rect_ok())
	var ev := InputEventScreenTouch.new()
	ev.index = 3
	ev.position = centro
	ev.pressed = true
	_tela._input(ev)
	ev.pressed = false
	_tela._input(ev)
	var fora_da_arvore := not _tela.is_inside_tree()
	pai.add_child(_tela)
	assert_true(fora_da_arvore, "OK tirou a tela da arvore durante o _input")
	assert_eq(_fechados, [_modo_a.id], "OK emitiu fechado")
