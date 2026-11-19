extends GutTest

# Montador e publicador do estado (ponte `window.__GAME_STATE__`). Logica pura: sem arvore de cena.


func test_build_valores_literais_menu_jogando_derrotado() -> void:
	# (a) default: menu zerado
	var menu: Dictionary = GameState.build(0, 0, "menu", true)
	assert_eq(menu["score"], 0, "menu: score 0")
	assert_eq(menu["best"], 0, "menu: best 0")
	assert_eq(menu["state"], "menu", "menu: state")
	assert_eq((menu["player"] as Dictionary)["alive"], true, "menu: player.alive")
	assert_eq(typeof(menu["score"]), TYPE_INT, "menu: score e int")
	assert_eq(typeof(menu["best"]), TYPE_INT, "menu: best e int")
	assert_eq(typeof((menu["player"] as Dictionary)["alive"]), TYPE_BOOL, "menu: alive e bool")

	# (b) comum: partida em andamento
	var jogando: Dictionary = GameState.build(7, 12, "playing", true)
	assert_eq(jogando["score"], 7, "jogando: score 7")
	assert_eq(jogando["best"], 12, "jogando: best 12")
	assert_eq(jogando["state"], "playing", "jogando: state")
	assert_eq((jogando["player"] as Dictionary)["alive"], true, "jogando: player.alive")

	# (c) degenerado: derrota com alive=false no instante da queda
	var derrotado: Dictionary = GameState.build(3, 12, "lost", false)
	assert_eq(derrotado["score"], 3, "derrotado: score 3")
	assert_eq(derrotado["best"], 12, "derrotado: best 12")
	assert_eq(derrotado["state"], "lost", "derrotado: state")
	assert_eq((derrotado["player"] as Dictionary)["alive"], false, "derrotado: player.alive false")
	assert_eq(typeof((derrotado["player"] as Dictionary)["alive"]), TYPE_BOOL, "derrotado: alive e bool")


func test_build_publica_volumes_de_opcoes() -> void:
	var padrao: Dictionary = GameState.build(0, 0, "menu", true)
	assert_eq((padrao["volume"] as Dictionary)["music"], 100, "padrao: music 100")
	assert_eq((padrao["volume"] as Dictionary)["sfx"], 100, "padrao: sfx 100")
	var mudo: Dictionary = GameState.build(2, 4, "playing", true, 35, 0)
	assert_eq((mudo["volume"] as Dictionary)["music"], 35, "music 35")
	assert_eq((mudo["volume"] as Dictionary)["sfx"], 0, "sfx 0")
	assert_eq(typeof((mudo["volume"] as Dictionary)["sfx"]), TYPE_INT, "sfx e int")


func test_build_publica_tutorial_aberto_e_fechado() -> void:
	assert_eq(GameState.build(0, 0, "menu", true)["tutorial"], "fechado", "padrao: fechado")
	assert_eq(GameState.build(0, 0, "playing", true, 100, 100, true)["tutorial"], "aberto", "aberto")


func test_build_publica_dificuldade_estagio_int_default_0() -> void:
	# (a) default: sem o parametro, estagio 0 e int (nao float)
	var padrao: Dictionary = GameState.build(0, 0, "menu", true)
	var dif_padrao: Dictionary = padrao["dificuldade"] as Dictionary
	assert_eq(dif_padrao["estagio"], 0, "padrao: dificuldade.estagio 0")
	assert_eq(typeof(dif_padrao["estagio"]), TYPE_INT, "padrao: estagio e int")
	# (b) comum: parametro passado publica o mesmo valor
	var em_estagio: Dictionary = GameState.build(7, 12, "playing", true, 100, 100, false, 2)
	assert_eq((em_estagio["dificuldade"] as Dictionary)["estagio"], 2, "estagio 2 publicado")
	assert_eq(typeof((em_estagio["dificuldade"] as Dictionary)["estagio"]), TYPE_INT, "estagio 2 e int")
	# (c) degenerado: round-trip JSON preserva o int (JSON devolve float, int() restaura)
	var texto: String = JSON.stringify(GameState.build(0, 0, "playing", true, 100, 100, false, 3))
	var volta: Dictionary = JSON.parse_string(texto) as Dictionary
	assert_eq(int((volta["dificuldade"] as Dictionary)["estagio"]), 3, "round-trip preserva estagio 3")


func test_build_publica_dificuldade_aviso_bool_default_false() -> void:
	# (a) default: sem o argumento, aviso false (bool) e o estagio segue
	var padrao: Dictionary = GameState.build(0, 0, "menu", true)
	var dif_padrao: Dictionary = padrao["dificuldade"] as Dictionary
	assert_eq(dif_padrao["aviso"], false, "padrao: dificuldade.aviso false")
	assert_eq(typeof(dif_padrao["aviso"]), TYPE_BOOL, "padrao: aviso e bool")
	# (b) comum: aviso true reflete o argumento e o estagio segue
	var avisando: Dictionary = GameState.build(7, 12, "playing", true, 100, 100, false, 2, true)
	var dif_avisando: Dictionary = avisando["dificuldade"] as Dictionary
	assert_eq(dif_avisando["aviso"], true, "aviso true publicado")
	assert_eq(dif_avisando["estagio"], 2, "estagio segue com aviso true")
	# (c) degenerado: aviso false explicito; round-trip JSON preserva o bool
	var apagado: Dictionary = GameState.build(7, 12, "playing", true, 100, 100, false, 2, false)
	assert_eq((apagado["dificuldade"] as Dictionary)["aviso"], false, "aviso false explicito")
	var volta: Dictionary = JSON.parse_string(JSON.stringify(avisando)) as Dictionary
	assert_eq((volta["dificuldade"] as Dictionary)["aviso"], true, "round-trip preserva aviso true")


func test_build_publica_dificuldade_alpha_float_default_zero() -> void:
	# (a) default: sem o argumento, alpha 0.0 (float)
	var padrao: Dictionary = GameState.build(0, 0, "menu", true)
	var dif_padrao: Dictionary = padrao["dificuldade"] as Dictionary
	assert_eq(dif_padrao["alpha"], 0.0, "padrao: dificuldade.alpha 0")
	assert_eq(typeof(dif_padrao["alpha"]), TYPE_FLOAT, "padrao: alpha e float")
	# (b) comum: alpha passado e publicado, o aviso e o estagio seguem
	var pulsando: Dictionary = GameState.build(1, 2, "playing", true, 100, 100, false, 1, true, 0.0, 0.0, 0.75)
	var dif_pulsando: Dictionary = pulsando["dificuldade"] as Dictionary
	assert_eq(dif_pulsando["alpha"], 0.75, "alpha 0.75 publicado")
	assert_eq(dif_pulsando["aviso"], true, "aviso segue")
	assert_eq(dif_pulsando["estagio"], 1, "estagio segue")
	# (c) degenerado: round-trip JSON preserva o valor
	var volta: Dictionary = JSON.parse_string(JSON.stringify(pulsando)) as Dictionary
	assert_eq((volta["dificuldade"] as Dictionary)["alpha"], 0.75, "round-trip preserva alpha")


func test_build_publica_player_xy_inteiros_arredondados() -> void:
	# (a) default: sem posicao, 0/0 inteiros
	var padrao: Dictionary = GameState.build(0, 0, "menu", true)
	assert_eq((padrao["player"] as Dictionary)["x"], 0, "padrao: player.x 0")
	assert_eq((padrao["player"] as Dictionary)["y"], 0, "padrao: player.y 0")
	# (b) comum: positivo arredonda para cima, negativo para o mais proximo
	var pos: Dictionary = (
		GameState.build(1, 2, "playing", true, 100, 100, false, 0, false, 12.6, -12.4)["player"] as Dictionary
	)
	assert_eq(pos["x"], 13, "12.6 -> 13")
	assert_eq(pos["y"], -12, "-12.4 -> -12")
	assert_eq(typeof(pos["x"]), TYPE_INT, "player.x e int")
	assert_eq(typeof(pos["y"]), TYPE_INT, "player.y e int")
	# (c) degenerado: sinais trocados
	var inv: Dictionary = (
		GameState.build(1, 2, "playing", true, 100, 100, false, 0, false, -12.6, 12.4)["player"] as Dictionary
	)
	assert_eq(inv["x"], -13, "-12.6 -> -13")
	assert_eq(inv["y"], 12, "12.4 -> 12")


func test_build_publica_powerup_padrao_e_restante_arredondado_para_cima() -> void:
	# (a) default: sem os parametros, ativo "", restante 0, carga 0 (int)
	var padrao: Dictionary = (GameState.build(0, 0, "menu", true)["powerup"]) as Dictionary
	assert_eq(padrao["ativo"], "", "padrao: powerup.ativo vazio")
	assert_eq(padrao["restante"], 0, "padrao: powerup.restante 0")
	assert_eq(padrao["carga"], 0, "padrao: powerup.carga 0")
	assert_eq(typeof(padrao["restante"]), TYPE_INT, "padrao: restante e int")
	# (b) comum: restante fracionario arredonda para cima
	var ativo: Dictionary = (
		GameState.build(1, 2, "playing", true, 100, 100, false, 0, false, 0.0, 0.0, 0.0, "teste", 1.2, 1)["powerup"]
		as Dictionary
	)
	assert_eq(ativo["ativo"], "teste", "powerup.ativo publicado")
	assert_eq(ativo["restante"], 2, "1.2 s -> 2 (para cima)")
	assert_eq(ativo["carga"], 1, "powerup.carga publicado")
	assert_eq(typeof(ativo["restante"]), TYPE_INT, "restante e int")
	# (c) degenerado: restante exato nao sobe; os demais campos seguem
	var estado: Dictionary = GameState.build(3, 9, "playing", true, 40, 50, false, 2, false, 0.0, 0.0, 0.0, "teste", 1.0)
	assert_eq((estado["powerup"] as Dictionary)["restante"], 1, "1.0 s -> 1")
	assert_eq(estado["score"], 3, "score segue")
	assert_eq((estado["dificuldade"] as Dictionary)["estagio"], 2, "dificuldade segue")


func test_build_alive_false_preserva_posicao_e_demais_campos() -> void:
	var estado: Dictionary = GameState.build(3, 9, "lost", false, 40, 50, false, 2, false, 30.0, 70.0)
	var jogador: Dictionary = estado["player"] as Dictionary
	assert_eq(jogador["alive"], false, "alive false")
	assert_eq(jogador["x"], 30, "x preservado")
	assert_eq(jogador["y"], 70, "y preservado")
	assert_eq(estado["score"], 3, "score igual")
	assert_eq((estado["volume"] as Dictionary)["music"], 40, "volume igual")
	assert_eq((estado["dificuldade"] as Dictionary)["estagio"], 2, "dificuldade igual")


func _nova_stage() -> Node:
	var stage: Node = (load("res://scenes/Stage.tscn") as PackedScene).instantiate()
	add_child_autofree(stage)
	return stage


func test_stage_republica_so_quando_par_arredondado_muda() -> void:
	var stage: Node = _nova_stage()
	stage._on_Play_button_down()
	# y abaixo do limite de topo da camera (f489): acima dele a Stage devolveria o gecko ao limite
	stage.player.global_position = Vector2(50.0, 180.0)
	stage._physics_process(0.016)
	assert_eq((stage.ultimo_estado["player"] as Dictionary)["x"], 50, "publicou x inicial")
	# parado: mesmo par -> nao republica (o dicionario publicado e o mesmo objeto)
	var antes: Dictionary = stage.ultimo_estado
	stage._physics_process(0.016)
	assert_same(stage.ultimo_estado, antes, "parado nao republica")
	# mudanca sub-pixel que nao troca o arredondado: nao republica
	stage.player.global_position = Vector2(50.2, 180.0)
	stage._physics_process(0.016)
	assert_same(stage.ultimo_estado, antes, "mesmo par arredondado nao republica")
	# par muda -> republica
	stage.player.global_position = Vector2(53.0, 181.0)
	stage._physics_process(0.016)
	var jogador: Dictionary = stage.ultimo_estado["player"] as Dictionary
	assert_eq(jogador["x"], 53, "republicou x")
	assert_eq(jogador["y"], 181, "republicou y")


func test_stage_fora_de_partida_nao_publica_posicao() -> void:
	var stage: Node = _nova_stage()
	var menu: Dictionary = stage.ultimo_estado
	stage.player.global_position = Vector2(90.0, 200.0)
	stage._physics_process(0.016)
	assert_same(stage.ultimo_estado, menu, "menu: posicao nova nao republica")


func test_json_stringify_parseia_de_volta_igual() -> void:
	var estado: Dictionary = GameState.build(5, 9, "lost", false)
	var texto: String = JSON.stringify(estado)
	var parseado: Variant = JSON.parse_string(texto)
	assert_true(parseado is Dictionary, "JSON valido e vira dicionario")
	var volta: Dictionary = parseado as Dictionary
	# JSON parseia numeros como float: compara como int para nao acusar 'Float/Int comparison'
	assert_eq(int(volta["score"]), 5, "score volta igual")
	assert_eq(int(volta["best"]), 9, "best volta igual")
	assert_eq(volta["state"], "lost", "state volta igual")
	assert_true(volta["player"] is Dictionary, "player continua aninhado")
	assert_eq((volta["player"] as Dictionary)["alive"], false, "player.alive volta igual")


func test_deve_publicar_so_em_web_debug() -> void:
	assert_true(GameState.deve_publicar(true, true), "web + debug publica")
	assert_false(GameState.deve_publicar(true, false), "web release nao publica")
	assert_false(GameState.deve_publicar(false, true), "desktop debug nao publica")
	assert_false(GameState.deve_publicar(false, false), "desktop release nao publica")


func test_publish_no_headless_e_no_op() -> void:
	# O ambiente do GUT (headless) nao e web: a trava deve barrar, e publish nao chama JavaScriptBridge nem lanca
	assert_false(GameState.deve_publicar(OS.has_feature("web"), OS.is_debug_build()), "headless nao publica")
	GameState.publish(GameState.build(1, 2, "playing", true))
