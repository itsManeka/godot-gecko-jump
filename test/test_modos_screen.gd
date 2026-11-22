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


func _abrir(lista: Array[GameMode], altura: float = 320.0) -> void:
	_tela.aplicar_layout(Vector2(180.0, altura), Rect2(0.0, 0.0, 180.0, altura))
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


func test_geometria_em_180x320_e_180x400() -> void:
	# 320: (320 - 229) / 2 = 45,5 -> y0 = 46 (grade inteira); 400: 85,5 -> 86
	for caso in [[320.0, 46.0], [400.0, 86.0]]:
		_tela.aplicar_layout(Vector2(180.0, caso[0]), Rect2(0.0, 0.0, 180.0, caso[0]))
		var y0: float = caso[1]
		assert_eq(_tela.rect_titulo(), Rect2(0.0, y0, 180.0, 30.0), "titulo em %s" % caso[0])
		assert_eq(_tela.rect_imagem(), Rect2(58.0, y0 + 42.0, 64.0, 64.0), "imagem 64x64 em %s" % caso[0])
		assert_eq(_tela.rect_seta_esq(), Rect2(4.0, y0 + 62.0, 24.0, 24.0), "seta esq x 4-28 y 62-86 em %s" % caso[0])
		assert_eq(_tela.rect_seta_dir(), Rect2(152.0, y0 + 62.0, 24.0, 24.0), "seta dir x 152-176 em %s" % caso[0])
		assert_eq(_tela.rect_nome(), Rect2(0.0, y0 + 114.0, 180.0, 17.0), "nome y 114-131 em %s" % caso[0])
		assert_eq(_tela.rect_descricao(), Rect2(10.0, y0 + 135.0, 160.0, 34.0), "descricao y 135-169 em %s" % caso[0])
		assert_eq(_tela.rect_ok(), Rect2(34.0, y0 + 197.0, 112.0, 32.0), "OK x 34-146 y 197-229 em %s" % caso[0])


func test_arrasto_limiar_16px_e_faixa() -> void:
	_abrir([_modo_a, _modo_b] as Array[GameMode])
	var faixa := _tela.rect_faixa_arrasto()
	assert_eq(faixa, Rect2(30.0, 46.0 + 42.0, 120.0, 127.0), "faixa x 30-150 y 42-169")
	var inicio := _centro(faixa)
	_arrastar_de(inicio, -15.0)
	assert_eq(_tela.modo_exibido().id, _modo_a.id, "15 px nao troca")
	_arrastar_de(inicio, -16.0)
	assert_eq(_tela.modo_exibido().id, _modo_b.id, "16 px troca")
	_arrastar_de(inicio, 16.0)
	assert_eq(_tela.modo_exibido().id, _modo_a.id, "16 px para o outro lado volta")
	# iniciado fora da faixa (acima, y 41 relativo) nao troca
	var fora := Vector2(inicio.x, faixa.position.y - 1.0)
	_arrastar_de(fora, -40.0)
	assert_eq(_tela.modo_exibido().id, _modo_a.id, "iniciado fora da faixa nao troca")
	# borda interna da faixa troca
	_arrastar_de(Vector2(faixa.position.x, faixa.position.y), -16.0)
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
	_arrastar_de(_centro(_tela.rect_faixa_arrasto()), -40.0)
	assert_eq(_tela.modo_exibido().id, _modo_a.id, "lista de 1 segue no mesmo modo")
	assert_eq(_mudancas.size(), 0, "lista de 1 nao emite modo_mudou")


func test_indicador_n_marcas_so_a_atual_8x4() -> void:
	var sozinho: Array[GameMode] = [_modo_a]
	_abrir(sozinho)
	var marcas := _tela.rect_marcas()
	assert_eq(marcas.size(), 1, "N = 1 gera 1 marca")
	assert_eq(marcas[0].size, Vector2(8.0, 4.0), "a unica marca e a atual 8x4")
	_abrir([_modo_a, _modo_b] as Array[GameMode])
	marcas = _tela.rect_marcas()
	assert_eq(marcas.size(), 2, "N = 2 gera 2 marcas")
	assert_eq(marcas[0].size, Vector2(8.0, 4.0), "a atual (1a) e 8x4")
	assert_eq(marcas[1].size, Vector2(4.0, 4.0), "a outra e 4x4")
	_tocar(_centro(_tela.rect_seta_dir()))
	marcas = _tela.rect_marcas()
	assert_eq(marcas[0].size, Vector2(4.0, 4.0), "depois da troca a 1a e 4x4")
	assert_eq(marcas[1].size, Vector2(8.0, 4.0), "depois da troca a 2a e 8x4")


func test_c714_indicador_com_modos_reais_4_marcas_em_release_e_5_com_teste_atual_8x4_no_zen() -> void:
	for incluir_teste: bool in [false, true]:
		var modos := GameModes.lista(incluir_teste)
		var indice_zen: int = modos.find(GameModes.zen())
		assert_eq(indice_zen, 3, "C714: o Zen e o 4o modo (teste=%s)" % incluir_teste)
		_tela.aplicar_layout(Vector2(180.0, 320.0), Rect2(0.0, 0.0, 180.0, 320.0))
		assert_true(_tela.abrir(GameModes.zen(), modos), "abrir no Zen devolve true")
		var marcas := _tela.rect_marcas()
		assert_eq(marcas.size(), 5 if incluir_teste else 4, "C714: marcas = modos da lista (teste=%s)" % incluir_teste)
		for i in marcas.size():
			var esperado := Vector2(8.0, 4.0) if i == indice_zen else Vector2(4.0, 4.0)
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
