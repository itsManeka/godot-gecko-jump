extends GutTest

# f526 T6: justica do reaparecimento da Segunda chance. Cenarios C666-C672 do 05-test-plan.
# "Estado sem saida" (Q6) vira predicado testavel; depois de reaparecer: (a) o gecko nao esta dentro de shape solido
# nem fora da PlayArea, (b) esta sobre plataforma solida da cor vigente que nao desmorona nem pisca oculta, (c) ha
# plataforma da cor vigente na linha de cima enquanto a de baixo ainda vive (janela de ReachableColors) e (d) nenhum
# body_exited extra dispara depois, sem nova queda.
# Simulacao no padrao de test_cor_alcancavel_simulacao.gd (o harness e reutilizado, nao reescrito): 200 linhas, seed
# fixa, estagios 0 a 3 da curva de producao. Cada pouso do harness vira uma queda forcada em varios x (inclusive nas
# bordas) e y; as plataformas das linhas visiveis ganham estados hostis (desmoronando, piscar oculto) sorteados com
# seed fixa. (a)-(c) sao medidos sobre as entradas (modelo de ReachableColors.entradas_de_plataformas) com a geometria
# real do Player e da Platform; (d) e o caso hostil rodam na Stage real.

const Simulacao := preload("res://test/test_cor_alcancavel_simulacao.gd")
const PlayerFisica := preload("res://scenes/Player.gd")
const STAGE_SCENE := "res://scenes/Stage.tscn"
const PLAYER_SCENE := "res://scenes/Player.tscn"
const PLATFORM_SCENE := "res://scenes/Platform.tscn"
const CURVA_PATH := "res://ressources/curva_dificuldade.tres"
const SEED := 20261110
const LARGURA := 180.0
const ALTURA := 320.0
const EPS := 0.01
# Quedas forcadas: x inclui as duas bordas e o wrap; y fica alem da linha de derrota
const XS_QUEDA := [0.0, 3.0, 90.0, 177.0, 180.0]
const YS_QUEDA := [330.0, 345.0, 400.0]
const QUEDAS_POR_POUSO := 3
const PROB_DESMORONANDO := 0.12
const PROB_OCULTA := 0.12
const VISIVEL := Vector2(180.0, 320.0)
const SAFE := Rect2(0.0, 0.0, 180.0, 320.0)
const X_QUEDA := 20.0
const Y_QUEDA := 360.0

var _mundos: Array = []
var _cache: Dictionary = {}
var _regua_player: Node = null
var _regua_plat: Node = null
var _dy_topo := 0.0
var _corpo_half := Vector2.ZERO
var _corpo_off := Vector2.ZERO
var _plat_half := Vector2.ZERO
var _plat_off := Vector2.ZERO

var _stage: Node = null
var _p: Node = null
var _saidas := 0
var _plats: Array = []
var _plataformas_original: Array = []
var _iniciado_original := false
var _tutorial_espelho_original := false
var _sem_derrota_original := false
var _cor_original: Enums.COLOR
var _cor_livre_original := false
var _keeper_original: ScoreKeeper


func before_all() -> void:
	var harness = Simulacao.new()
	var curva := load(CURVA_PATH) as DifficultyCurve
	for i in range(curva.estagios.size()):
		var snap: DifficultySnapshot = curva.avaliar(curva.estagios[i].progresso_inicio * curva.pontos_plato, 0.0)
		_mundos.append({"scroll": snap.get_scroll(), "sim": harness._simular(SEED, snap)})
	harness.free()


func before_each() -> void:
	_plataformas_original = Global.platforms
	_iniciado_original = Global.iniciado
	_tutorial_espelho_original = Global.tutorial_visto_espelho
	_sem_derrota_original = Global.sem_derrota
	_cor_original = Global.cor_gecko
	_cor_livre_original = Global.cor_livre
	Global.tutorial_visto_espelho = true
	Global.platforms = []
	Global.iniciado = false
	Global.cor_livre = false
	_keeper_original = Global.pontuacao
	Global.pontuacao = ScoreKeeper.new()
	PowerUps.restaurar_padrao()
	_saidas = 0


func after_each() -> void:
	if is_instance_valid(_p):
		_p.end = true
	get_tree().paused = false
	Global.platforms = _plataformas_original
	Global.iniciado = _iniciado_original
	Global.tutorial_visto_espelho = _tutorial_espelho_original
	Global.sem_derrota = _sem_derrota_original
	Global.cor_gecko = _cor_original
	Global.cor_livre = _cor_livre_original
	Global.pontuacao = _keeper_original
	PowerUps.restaurar_padrao()
	_stage = null
	_p = null
	_plats = []


# ---------------------------------------------------------------- geometria e predicado (puros)


# Player e Platform reais so como regua: o y do gecko sobre o topo e os tamanhos dos shapes vem deles
func _preparar_regua() -> void:
	_regua_player = load(PLAYER_SCENE).instantiate()
	add_child(_regua_player)
	_regua_plat = load(PLATFORM_SCENE).instantiate()
	add_child(_regua_plat)
	_regua_plat.global_position = Vector2.ZERO
	_dy_topo = _regua_player._y_no_topo(_regua_plat)
	var forma_corpo: RectangleShape2D = _regua_player.collision.shape as RectangleShape2D
	_corpo_half = forma_corpo.size / 2.0
	_corpo_off = _regua_player.collision.position
	var forma_plat: RectangleShape2D = _regua_plat.shape.shape as RectangleShape2D
	_plat_half = forma_plat.size / 2.0
	_plat_off = _regua_plat.shape.position
	# Medidas lidas: a regua sai da arvore (um Player vivo cairia pela faixa de derrota dos testes de Stage)
	for no in [_regua_player, _regua_plat]:
		remove_child(no)
		no.free()
	_regua_player = null
	_regua_plat = null


func _entrada(y: float, x: float, cor: int, desmoronando := false, oculta := false) -> Dictionary:
	return {
		"y": y,
		"x": x,
		"cor": cor,
		"desmoronada": false,
		"desmoronando": desmoronando,
		"pisca_oculta": oculta,
	}


func _interpenetra(gx: float, gy: float, e: Dictionary) -> bool:
	for wrap in [0.0, LARGURA, -LARGURA]:
		var ox: float = (
			_corpo_half.x + _plat_half.x - absf((gx + _corpo_off.x) - (float(e["x"]) + wrap + _plat_off.x))
		)
		var oy: float = (
			_corpo_half.y + _plat_half.y - absf((gy + _corpo_off.y) - (float(e["y"]) + _plat_off.y))
		)
		if ox > EPS and oy > EPS:
			return true
	return false


func _solida_para(e: Dictionary, cor: int, livre: bool) -> bool:
	if bool(e["desmoronada"]) or bool(e["pisca_oculta"]):
		return false
	return livre or int(e["cor"]) == cor


# Violacoes do predicado "com saida" para a escolha de T3: chaves "a", "b" e "c" com a descricao de cada falha
func _violacoes(entradas: Array, escolha: Dictionary, scroll: float, livre: bool) -> Dictionary:
	var v: Dictionary = {"a": [], "b": [], "c": []}
	var alvo: Dictionary = escolha["entrada"]
	var cor: int = int(escolha["cor"])
	var gx: float = float(alvo["x"])
	var gy: float = float(alvo["y"]) + _dy_topo
	# (a) dentro da PlayArea e sem interpenetrar nenhum shape solido
	if gx < 0.0 or gx > LARGURA or float(alvo["y"]) < 0.0 or float(alvo["y"]) > ALTURA:
		v["a"].append("fora da PlayArea x=%.1f y=%.1f" % [gx, float(alvo["y"])])
	for e in entradas:
		if _solida_para(e, cor, livre) and _interpenetra(gx, gy, e):
			v["a"].append("dentro de shape solido x=%.1f y=%.1f" % [float(e["x"]), float(e["y"])])
	# (b) sobre plataforma solida da cor vigente que nao esta prestes a sumir
	if not (livre or int(alvo["cor"]) == cor):
		v["b"].append("alvo de outra cor")
	if bool(alvo["desmoronada"]) or bool(alvo["desmoronando"]) or bool(alvo["pisca_oculta"]):
		v["b"].append("alvo prestes a sumir (desmoronando/oculta)")
	# (c) a de baixo ainda vive o tempo do pulo + espera e ha da cor vigente na linha de cima
	if scroll > 0.0:
		var vida: float = (ALTURA - float(alvo["y"])) / scroll
		var preciso: float = ReachableColors.tempo_de_pulo(scroll) + PlayerFisica.ESPERA_MAXIMA_S
		if vida < preciso:
			v["c"].append("vive %.2fs < %.2fs" % [vida, preciso])
	# Linha de cima pela janela de ReachableColors (do pulo ate a espera maxima apos o pouso); cor livre serve qualquer cor
	var cores_acima: Array = ReachableColors.coletar_cores_linha_acima(
		entradas, float(alvo["y"]), LARGURA, ReachableColors.tempo_de_pulo(scroll), PlayerFisica.ESPERA_MAXIMA_S
	)
	var acima: bool = not cores_acima.is_empty() if livre else cores_acima.has(cor)
	if not acima:
		v["c"].append("sem plataforma da cor %d na linha de cima de y=%.1f" % [cor, float(alvo["y"])])
	return v


func _primeira(lista: Array) -> String:
	return str(lista.front()) if not lista.is_empty() else "-"


# Entradas visiveis em torno do pouso g (y do gecko na tela = y_tela), com estados hostis sorteados por seed fixa
func _entradas_do_pouso(estagio: int, linhas: Array, g: int, y_tela: float) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED + estagio * 1000 + g
	var entradas: Array = []
	var margem: float = 3.0 * InitialRows.ESPACAMENTO
	for i in range(maxi(0, g - 8), mini(linhas.size(), g + 12)):
		var y: float = y_tela - InitialRows.ESPACAMENTO * float(i - g)
		if y < -margem or y > ALTURA + margem:
			continue
		for p in linhas[i]["plataformas"]:
			var sorte: float = rng.randf()
			entradas.append(
				_entrada(
					y,
					float(p["x"]),
					int(p["cor"]),
					sorte < PROB_DESMORONANDO,
					sorte >= PROB_DESMORONANDO and sorte < PROB_DESMORONANDO + PROB_OCULTA
				)
			)
	return entradas


# Roda todas as quedas forcadas de um mundo (estagio); `sem_a_cor_do_gecko` tira a cor vigente da tela (fallback)
func _rodar(mundo: Dictionary, estagio: int, livre: bool, sem_a_cor_do_gecko := false) -> Dictionary:
	var r: Dictionary = {"resgates": 0, "derrotas": 0, "fallbacks": 0, "a": [], "b": [], "c": [], "x_fora": 0}
	var sim: Dictionary = mundo["sim"]
	var scroll: float = mundo["scroll"]
	for e in sim["eventos"]:
		var g: int = e["g"]
		var cor_gecko: int = e["depois"]
		var y_tela: float = 150.0 + float((g * 13) % 120)
		var entradas: Array = _entradas_do_pouso(estagio, sim["linhas"], g, y_tela)
		if sem_a_cor_do_gecko:
			entradas = entradas.filter(func(x: Dictionary) -> bool: return int(x["cor"]) != cor_gecko)
		for k in range(QUEDAS_POR_POUSO):
			var ponto := Vector2(XS_QUEDA[(g + k * 2) % XS_QUEDA.size()], YS_QUEDA[(g + k) % YS_QUEDA.size()])
			var escolha: Dictionary = SegundaChanceAlvo.escolher(entradas, ponto, cor_gecko, LARGURA, ALTURA, scroll)
			if int(escolha["indice"]) < 0:
				r["derrotas"] += 1
				continue
			r["resgates"] += 1
			if bool(escolha["fallback"]):
				r["fallbacks"] += 1
			var v: Dictionary = _violacoes(entradas, escolha, scroll, livre)
			for chave in ["a", "b", "c"]:
				for item in v[chave]:
					r[chave].append("est%d g=%d ponto=%s: %s" % [estagio, g, ponto, item])
	return r


func _todos_os_estagios(livre: bool, sem_a_cor_do_gecko := false) -> Dictionary:
	var chave := "%s|%s" % [livre, sem_a_cor_do_gecko]
	if not _cache.has(chave):
		_cache[chave] = _calcular_todos(livre, sem_a_cor_do_gecko)
	return _cache[chave]


func _calcular_todos(livre: bool, sem_a_cor_do_gecko: bool) -> Dictionary:
	var total: Dictionary = {"resgates": 0, "derrotas": 0, "fallbacks": 0, "a": [], "b": [], "c": []}
	for i in range(_mundos.size()):
		var r: Dictionary = _rodar(_mundos[i], i, livre, sem_a_cor_do_gecko)
		for chave in ["resgates", "derrotas", "fallbacks"]:
			total[chave] += r[chave]
		for chave in ["a", "b", "c"]:
			total[chave].append_array(r[chave])
	return total


# Cena cravada: gecko em (90, 330) com a cor AZUL; cada teste acrescenta as plataformas hostis
func _entrada_valida(y: float, x: float = 90.0) -> Array:
	return [_entrada(y, x, Enums.COLOR.AZUL), _entrada(y - InitialRows.ESPACAMENTO, x, Enums.COLOR.AZUL)]


# Teto de uma entrada AZUL em y: plataforma AZUL na linha de cima, marcada desmoronada (nunca candidata)
func _teto(y: float) -> Dictionary:
	var e: Dictionary = _entrada(y - InitialRows.ESPACAMENTO, 90.0, Enums.COLOR.AZUL)
	e["desmoronada"] = true
	return e


func _escolher_azul(entradas: Array, ponto: Vector2, scroll: float) -> Dictionary:
	return SegundaChanceAlvo.escolher(entradas, ponto, int(Enums.COLOR.AZUL), LARGURA, ALTURA, scroll)


# ---------------------------------------------------------------- C666 a C668 e C671


func test_C666_predicado_a_nao_interpenetra_e_fica_na_play_area() -> void:
	_preparar_regua()
	assert_eq(_mundos.size(), 4, "fixture: os 4 estagios da curva de producao")
	var r: Dictionary = _todos_os_estagios(false)
	assert_gt(r["resgates"], 400, "fixture: a simulacao reaparece em centenas de quedas (200 linhas x 4 estagios)")
	assert_eq(r["a"].size(), 0, "C666: (a) violada: %s" % _primeira(r["a"]))
	# Borda x: candidata fora de [0, largura] mais proxima do gecko nao serve de alvo (wrap) - a visivel e escolhida
	# (a mais proxima por wrap esta em x=200, fora da PlayArea; a linha de cima dela e a mesma da visivel)
	var entradas: Array = _entrada_valida(200.0, 100.0)
	entradas.append(_entrada(200.0, 200.0, Enums.COLOR.AZUL))
	var escolha: Dictionary = _escolher_azul(entradas, Vector2(178.0, 330.0), 0.0)
	assert_true(int(escolha["indice"]) >= 0, "fixture: ha candidata na borda")
	var v: Dictionary = _violacoes(entradas, escolha, 0.0, false)
	assert_eq(v["a"].size(), 0, "C666: borda x - alvo fora da PlayArea: %s" % _primeira(v["a"]))
	# O predicado reprova alvo fora da PlayArea e gecko dentro de plataforma solida (nao e vacuo)
	var fora: Dictionary = {"indice": 2, "entrada": entradas[2], "cor": int(Enums.COLOR.AZUL), "fallback": false}
	assert_gt(_violacoes(entradas, fora, 0.0, false)["a"].size(), 0, "C666: o predicado reprova alvo fora da area")
	var sobreposta: Array = _entrada_valida(200.0, 100.0)
	sobreposta.append(_entrada(190.0, 100.0, Enums.COLOR.AZUL))
	var dentro: Dictionary = {"indice": 0, "entrada": sobreposta[0], "cor": int(Enums.COLOR.AZUL), "fallback": false}
	assert_gt(_violacoes(sobreposta, dentro, 0.0, false)["a"].size(), 0, "C666: o predicado reprova shape solido")


func test_C667_predicado_b_alvo_solido_da_cor_e_sem_estado_hostil() -> void:
	_preparar_regua()
	var r: Dictionary = _todos_os_estagios(false)
	assert_gt(r["resgates"], 400, "fixture: a simulacao reaparece em centenas de quedas")
	assert_eq(r["b"].size(), 0, "C667: (b) violada: %s" % _primeira(r["b"]))
	# Moveis/desmoronando/piscar entre candidatas: a mais proxima e hostil, a valida mais distante e a escolhida
	var entradas: Array = _entrada_valida(120.0)
	entradas.append(_entrada(250.0, 90.0, Enums.COLOR.AZUL, true, false))
	entradas.append(_entrada(280.0, 90.0, Enums.COLOR.AZUL, false, true))
	# Os hostis tem a cor na linha de cima: so o estado hostil os deixa de fora (os tetos nunca sao candidatos)
	entradas.append(_teto(250.0))
	entradas.append(_teto(280.0))
	var escolha: Dictionary = _escolher_azul(entradas, Vector2(90.0, 330.0), 0.0)
	assert_true(int(escolha["indice"]) >= 0, "fixture: ha candidata valida")
	assert_eq(float(escolha["entrada"]["y"]), 120.0, "C667: ignora a desmoronando e a oculta, mais proximas")
	assert_eq(_violacoes(entradas, escolha, 0.0, false)["b"].size(), 0, "C667: (b) vale no cenario hostil")
	# O predicado reprova cada estado hostil escolhido de proposito
	for hostil in [entradas[2], entradas[3]]:
		var ruim: Dictionary = {"indice": 2, "entrada": hostil, "cor": int(Enums.COLOR.AZUL), "fallback": false}
		assert_gt(_violacoes(entradas, ruim, 0.0, false)["b"].size(), 0, "C667: o predicado reprova o estado hostil")


func test_C668_predicado_c_vive_o_tempo_do_pulo_e_ha_cor_acima() -> void:
	_preparar_regua()
	var r: Dictionary = _todos_os_estagios(false)
	assert_gt(r["resgates"], 400, "fixture: a simulacao reaparece em centenas de quedas")
	assert_eq(r["c"].size(), 0, "C668: (c) violada: %s" % _primeira(r["c"]))
	# Scroll alto: a mais baixa (quase saindo da tela) e a mais proxima, mas a outra e a escolhida
	var scroll := 100.0
	var entradas: Array = _entrada_valida(100.0)
	entradas.append(_entrada(318.0, 90.0, Enums.COLOR.AZUL))
	entradas.append(_entrada(318.0 - InitialRows.ESPACAMENTO, 90.0, Enums.COLOR.AZUL))
	var escolha: Dictionary = _escolher_azul(entradas, Vector2(90.0, 330.0), scroll)
	assert_true(int(escolha["indice"]) >= 0, "fixture: ha candidata")
	assert_eq(float(escolha["entrada"]["y"]), 100.0, "C668: descarta a que sai da tela antes do pulo")
	assert_eq(_violacoes(entradas, escolha, scroll, false)["c"].size(), 0, "C668: (c) vale no cenario de scroll alto")
	# Linha estatica sem a cor vigente acima da mais proxima, e a mais distante tem a cor acima: o alvo deve ter saida
	var estatica: Array = _entrada_valida(100.0)
	estatica.append(_entrada(250.0, 90.0, Enums.COLOR.AZUL))
	estatica.append(_entrada(250.0 - InitialRows.ESPACAMENTO, 90.0, Enums.COLOR.VERDE))
	var escolha_estatica: Dictionary = _escolher_azul(estatica, Vector2(90.0, 330.0), 0.0)
	assert_true(int(escolha_estatica["indice"]) >= 0, "fixture: ha candidata na linha estatica")
	var v_estatica: Dictionary = _violacoes(estatica, escolha_estatica, 0.0, false)
	assert_eq(v_estatica["c"].size(), 0, "C668: estatica - alvo sem a cor vigente na linha de cima: %s" % _primeira(v_estatica["c"]))
	# Sem plataforma da cor na linha de cima o predicado (c) reprova
	var sem_acima: Array = [_entrada(100.0, 90.0, Enums.COLOR.AZUL)]
	var sozinha: Dictionary = {"indice": 0, "entrada": sem_acima[0], "cor": int(Enums.COLOR.AZUL), "fallback": false}
	assert_gt(_violacoes(sem_acima, sozinha, scroll, false)["c"].size(), 0, "C668: o predicado reprova sem cor acima")


func test_C671_contraprova_o_predicado_reprova_alvo_ruim_de_proposito() -> void:
	_preparar_regua()
	var scroll := 100.0
	# Mundo: desmoronando e a mais proxima, a mais baixa sai da tela, a valida e a mais distante
	var entradas: Array = _entrada_valida(100.0)
	entradas.append(_entrada(250.0, 90.0, Enums.COLOR.AZUL, true, false))
	entradas.append(_entrada(318.0, 90.0, Enums.COLOR.AZUL))
	entradas.append(_teto(250.0))
	entradas.append(_teto(318.0))
	var ponto := Vector2(90.0, 330.0)
	# O alvo ruim escolhido de proposito e reprovado pelo predicado
	var desmoronando: Dictionary = {"indice": 2, "entrada": entradas[2], "cor": int(Enums.COLOR.AZUL), "fallback": false}
	assert_gt(_violacoes(entradas, desmoronando, scroll, false)["b"].size(), 0, "C671: reprova plataforma desmoronando")
	var saindo: Dictionary = {"indice": 3, "entrada": entradas[3], "cor": int(Enums.COLOR.AZUL), "fallback": false}
	assert_gt(_violacoes(entradas, saindo, scroll, false)["c"].size(), 0, "C671: reprova a mais baixa saindo da tela")
	# A escolha de producao nao e nenhuma das duas e passa no predicado inteiro
	var escolha: Dictionary = _escolher_azul(entradas, ponto, scroll)
	assert_eq(float(escolha["entrada"]["y"]), 100.0, "C671: producao nao escolhe o alvo ruim")
	var v: Dictionary = _violacoes(entradas, escolha, scroll, false)
	assert_eq(v["a"].size() + v["b"].size() + v["c"].size(), 0, "C671: a escolha de producao tem saida")


# ---------------------------------------------------------------- Stage real: C669, C670, C672


func _novo_stage() -> Node:
	_stage = load(STAGE_SCENE).instantiate()
	var scroll: Node = _stage.get_node("ScrollLevel")
	_stage.remove_child(scroll)
	scroll.free()
	add_child_autofree(_stage)
	await wait_frames(2)
	_stage.apply_layout(VISIVEL, SAFE)
	Global.platforms = []
	_p = _stage.get_node("Node2D/Player")
	_p.set_physics_process(false)
	_p.jumping = false
	return _stage


func _plataforma(cor: Enums.COLOR, x: float, y: float, com_teto := true) -> Platform:
	var plat: Platform = _plataforma_solta(cor, x, y)
	if com_teto:
		# Teto: a cor na linha de cima (predicado de saida); desmoronada para nunca ser candidata nem colidir
		var teto: Platform = _plataforma_solta(cor, x, y - InitialRows.ESPACAMENTO)
		teto.desmoronada = true
	return plat


func _plataforma_solta(cor: Enums.COLOR, x: float, y: float) -> Platform:
	var plat: Platform = load(PLATFORM_SCENE).instantiate()
	plat.set_color(cor)
	add_child_autofree(plat)
	plat.global_position = Vector2(x, y)
	_plats.append(plat)
	return plat


# Derruba a Stage e as plataformas do cenario antes de montar outra no mesmo teste (padrao do C661 da T5): sem
# isso o gecko e as plataformas antigas seguem vivos e contaminam o contador de saidas e o actual_platform
func _derrubar_stage() -> void:
	_p.end = true
	var area: Area2D = _stage.get_node("CheckPlayer") as Area2D
	var chamada := Callable(_stage, "_on_CheckPlayer_body_exited")
	if area.body_exited.is_connected(chamada):
		area.body_exited.disconnect(chamada)
	if area.body_exited.is_connected(_on_saida):
		area.body_exited.disconnect(_on_saida)
	_stage.queue_free()
	for plat in _plats:
		if is_instance_valid(plat):
			plat.queue_free()
	_plats = []
	await _fisica(3)
	Global.platforms = []
	Global.cor_livre = false
	_saidas = 0


func _outra_cor(de: Enums.COLOR) -> Enums.COLOR:
	return Enums.COLOR.AZUL if de != Enums.COLOR.AZUL else Enums.COLOR.VERDE


func _fisica(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _estado() -> PowerUpState:
	return _stage.get("power_up_estado") as PowerUpState


func _on_saida(_corpo: Node) -> void:
	_saidas += 1


# Partida com 1 carga guardada e o gecko forcado alem da linha de derrota
func _iniciar_com_carga() -> void:
	_stage.call("_on_Play_button_down")
	_stage.call("_coletar_power_up", &"segunda_chance")
	assert_eq(_estado().carga(), 1, "fixture: carga guardada")


func _cair_e_resgatar() -> void:
	_p.global_position = Vector2(X_QUEDA, Y_QUEDA)
	_stage._on_CheckPlayer_body_exited(_p)


# Frames seguintes ao reaparecimento com a fisica ligada: nenhuma saida extra da faixa de derrota
func _conferir_sem_saida_extra(alvo: Platform, rotulo: String) -> void:
	(_stage.get_node("CheckPlayer") as Area2D).body_exited.connect(_on_saida)
	_p.set_physics_process(true)
	await _fisica(120)
	assert_eq(_saidas, 0, "%s: nenhum body_exited extra nos frames seguintes" % rotulo)
	assert_eq(_stage.ultimo_estado["state"], GameState.STATE_PLAYING, "%s: a partida segue playing" % rotulo)
	assert_eq(_estado().carga(), 0, "%s: sem consumo em dobro" % rotulo)
	assert_eq(_p.actual_platform, alvo, "%s: o gecko segue na plataforma de resgate" % rotulo)


func test_C669_predicado_d_sem_body_exited_extra_apos_reaparecer() -> void:
	# Caso comum: plataforma da cor do gecko
	_stage = await _novo_stage()
	_iniciar_com_carga()
	var alvo := _plataforma(Global.cor_gecko, 90.0, 60.0)
	_cair_e_resgatar()
	assert_eq(_stage.ultimo_estado["state"], GameState.STATE_PLAYING, "fixture: o resgate aconteceu")
	await _conferir_sem_saida_extra(alvo, "C669 comum")
	await _derrubar_stage()
	# Fallback: so ha plataforma de outra cor, o gecko assume a cor dela e nao pode atravessa-la
	_stage = await _novo_stage()
	_iniciar_com_carga()
	var de_outra := _plataforma(_outra_cor(Global.cor_gecko), 90.0, 60.0)
	_cair_e_resgatar()
	assert_eq(_stage.ultimo_estado["state"], GameState.STATE_PLAYING, "fixture: o resgate de fallback aconteceu")
	await _conferir_sem_saida_extra(de_outra, "C669 fallback")


func test_C670_caso_hostil_cai_na_derrota_padrao() -> void:
	_stage = await _novo_stage()
	_iniciar_com_carga()
	var cor: Enums.COLOR = Global.cor_gecko
	var desmoronando := _plataforma(cor, 90.0, 60.0)
	desmoronando.iniciar_desmoronamento(600.0)
	var oculta := _plataforma(cor, 60.0, 100.0)
	oculta.set("_pisca_oculta", true)
	oculta.shape.disabled = true
	_plataforma(cor, 90.0, 400.0)
	_plataforma(cor, 90.0, -60.0)
	assert_eq(_estado().carga(), 1, "fixture: so ha plataformas invalidas na tela")
	_cair_e_resgatar()
	assert_eq(_stage.ultimo_estado["state"], GameState.STATE_LOST, "C670: sem alvo valido vale a derrota padrao")
	assert_true(_p.is_end(), "C670: o gecko encerrou em vez de reaparecer")
	assert_eq(_estado().carga(), 1, "C670: a carga nao foi gasta num reaparecimento sem saida")
	assert_eq(_p.global_position, Vector2(X_QUEDA, Y_QUEDA), "C670: o gecko nao foi reposicionado")


func _fallback_em_stage(com_camaleao: bool, rotulo: String) -> void:
	_stage = await _novo_stage()
	_iniciar_com_carga()
	if com_camaleao:
		_stage.call("_coletar_power_up", &"camaleao")
		await _fisica(3)
		assert_true(Global.cor_livre, "fixture: Camaleao ativo (cor livre)")
		assert_eq(_estado().carga(), 1, "fixture: a carga segue guardada com o Camaleao ativo")
	var cor_antes: Enums.COLOR = Global.cor_gecko
	var de_outra := _plataforma(_outra_cor(cor_antes), 110.0, 90.0)
	_cair_e_resgatar()
	assert_eq(_p.actual_platform, de_outra, "%s: reaparece na unica plataforma da tela" % rotulo)
	assert_eq(_p.color, de_outra.color, "%s: o gecko assumiu a cor da plataforma (fallback)" % rotulo)
	assert_ne(_p.color, cor_antes, "%s: a cor mudou (nenhuma da cor do gecko visivel)" % rotulo)
	assert_eq(Global.cor_livre, com_camaleao, "%s: o reposicionamento nao mexe na cor livre" % rotulo)
	await _conferir_sem_saida_extra(de_outra, rotulo)


func test_C672_fallback_de_cor_com_e_sem_camaleao() -> void:
	_preparar_regua()
	# Simulacao: sem a cor do gecko na tela o alvo e de outra cor, com a cor a assumir; (a), (b) e (c) valem pela cor assumida
	for livre in [false, true]:
		var r: Dictionary = _todos_os_estagios(livre, true)
		assert_gt(r["fallbacks"], 300, "C672: fixture: a simulacao exercita o fallback (livre=%s)" % livre)
		assert_eq(r["resgates"], r["fallbacks"], "C672: sem a cor do gecko todo reaparecimento e fallback")
		var violacoes: Array = r["a"] + r["b"] + r["c"]
		assert_eq(violacoes.size(), 0, "C672: (a)/(b)/(c) no fallback (livre=%s): %s" % [livre, _primeira(violacoes)])
	# Stage real: sem e com Camaleao ativo
	await _fallback_em_stage(false, "C672 sem Camaleao")
	await _derrubar_stage()
	await _fallback_em_stage(true, "C672 com Camaleao")
