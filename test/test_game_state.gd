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
