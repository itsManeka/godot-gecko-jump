extends GutTest

# f522 T3: Camaleao — regra, registro e colisao com cor livre. Cenarios do 05-test-plan:
# C600 pouso em cor diferente (valido, soma 1 ponto e troca de cor pelo caminho de pouso existente);
# C601 expiracao com o gecko caindo reavalia no frame da expiracao, sem esperar pulo; C602 desmoronada
# e invisivel por piscar nunca ficam solidas com cor livre (nem reativadas nas bordas); C603 plataforma
# nascida no efeito nasce solida e deixa de ser ao expirar; C604 a actual_platform (sob o gecko) nao e
# reavaliada na ativacao nem na expiracao — o gecko nao cai ao expirar; C605 pausa congela o contador,
# o tempo de jogo (tick) expira e o de relogio nao. Registro de producao (C606) vive em
# test_power_up_state.gd.

const STAGE_SCENE := "res://scenes/Stage.tscn"
const PLATFORM_SCENE := "res://scenes/Platform.tscn"
# Altura do teleporte acima da plataforma de pouso (padrao de test_power_up_stage.gd)
const ALTURA_QUEDA_PX := 30.0

var _stage: Node = null
var _sem_derrota_original := false
var _iniciado_original := false
var _plataformas_original: Array = []
var _tutorial_espelho_original := false
var _power_up_inicial_original := ""
var _cor_original: Enums.COLOR
var _cor_livre_original := false


func before_each() -> void:
	_sem_derrota_original = Global.sem_derrota
	_iniciado_original = Global.iniciado
	_plataformas_original = Global.platforms
	_tutorial_espelho_original = Global.tutorial_visto_espelho
	_power_up_inicial_original = Global.power_up_inicial
	_cor_original = Global.cor_gecko
	_cor_livre_original = Global.cor_livre
	Global.tutorial_visto_espelho = true
	Global.sem_derrota = true
	Global.platforms = []
	Global.iniciado = false


func after_each() -> void:
	get_tree().paused = false
	_stage = null
	Global.sem_derrota = _sem_derrota_original
	Global.iniciado = _iniciado_original
	Global.platforms = _plataformas_original
	Global.tutorial_visto_espelho = _tutorial_espelho_original
	Global.power_up_inicial = _power_up_inicial_original
	Global.cor_gecko = _cor_original
	Global.cor_livre = _cor_livre_original
	PowerUps.restaurar_padrao()


func _novo_stage() -> Node:
	_stage = add_child_autofree(load(STAGE_SCENE).instantiate())
	await wait_frames(2)
	return _stage


func _estado() -> PowerUpState:
	return _stage.get("power_up_estado") as PowerUpState


func _player():
	return _stage.get_node("Node2D/Player")


func _iniciar_partida() -> void:
	_stage.call("_on_Play_button_down")


# Plataforma estatica e plana (sem piscar/ciclo, speed 0) abaixo do ponto de partida do gecko
# (padrao de test_power_up_stage.gd: a linha inicial garante candidata sem mecanicas sob o gecko)
func _plataforma_de_pouso(evitar: Platform = null) -> Platform:
	var y_partida: float = _player().global_position.y
	var escolhida: Platform = null
	for p in Global.platforms:
		if not is_instance_valid(p) or not (p is Platform):
			continue
		var plat := p as Platform
		if plat == evitar:
			continue
		if plat.obter_pisca() != null or plat.obter_ciclo() != null or plat.speed != 0:
			continue
		if plat.global_position.y < y_partida + 5.0:
			continue
		if escolhida == null or plat.global_position.y > escolhida.global_position.y:
			escolhida = plat
	return escolhida


# Uma cor diferente da dada (AZUL ou VERDE, a que nao for igual)
func _outra_cor(de: Enums.COLOR) -> Enums.COLOR:
	return Enums.COLOR.AZUL if de != Enums.COLOR.AZUL else Enums.COLOR.VERDE


# N frames de fisica crus pelo sinal da SceneTree: disparam mesmo com a arvore pausada (o helper
# wait_physics_frames do GUT depende de timer proprio, que congela junto na pausa — padrao do C553).
func _fisica(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


# Camaleao de duracao curta: Resource de teste injetado (T2), expira em `duracao` segundos de jogo
func _camaleao(duracao: float) -> PowerUpCamaleao:
	var config := PowerUpConfig.new()
	config.duracao_camaleao_s = duracao
	return PowerUpCamaleao.new(config)


# Sair da arvore dispara body_exited do CheckPlayer (derrota falsa tocaria audio fora da arvore):
# desconecta antes do autofree da Stage (padrao do C554 em test_power_up_stage.gd).
func _desconectar_derrota_falsa() -> void:
	if _stage == null:
		return
	var area: Area2D = _stage.get_node_or_null("CheckPlayer") as Area2D
	if area == null:
		return
	var chamada := Callable(_stage, "_on_CheckPlayer_body_exited")
	if area.body_exited.is_connected(chamada):
		area.body_exited.disconnect(chamada)


# C600: com Camaleao ativo, pousar em plataforma de cor diferente da do gecko e pouso valido: soma 1
# ponto e dispara a troca de cor do caminho de pouso existente (change_color_random -> set_color ->
# Global.player_color_changed: a plataforma do pouso fica travada, Global.gd:283).
func test_camaleao_ativo_pouso_em_cor_diferente_soma_ponto_e_troca_cor() -> void:
	_stage = await _novo_stage()
	var player = _player()
	var cor_gecko: Enums.COLOR = player.color
	var partida := _plataforma_de_pouso()
	assert_ne(partida, null, "fixture: plataforma de partida abaixo do ponto inicial")
	var alvo := _plataforma_de_pouso(partida)
	assert_ne(alvo, null, "fixture: segunda plataforma de pouso abaixo do ponto inicial")
	alvo.set_color(_outra_cor(cor_gecko))
	_iniciar_partida()
	# camaleao de producao pelo registro (duracao do Resource de T2)
	_stage.call("_coletar_power_up", &"camaleao")
	# gecko imediatamente acima da plataforma de partida, antes do 1o frame de fisica (nada pousou ainda)
	player.global_position = Vector2(partida.global_position.x, partida.global_position.y - ALTURA_QUEDA_PX)
	player.velocity = Vector2.ZERO
	await _fisica(60)
	assert_true(player.is_on_floor(), "fixture: gecko na plataforma de partida")
	assert_eq(_stage.get("points"), 0, "fixture: ponto de partida registrado (0)")
	assert_false(alvo.shape.disabled, "com Camaleao ativo a plataforma de outra cor e solida")
	var pontos_antes: int = _stage.get("points")
	# pouso testado: cor diferente, solida so porque o Camaleao esta ativo
	player.global_position = Vector2(alvo.global_position.x, alvo.global_position.y - ALTURA_QUEDA_PX)
	player.velocity = Vector2.ZERO
	await _fisica(60)
	assert_true(player.is_on_floor(), "pouso valido em cor diferente com Camaleao")
	assert_eq(_stage.get("points"), pontos_antes + 1, "o pouso em cor diferente soma 1 ponto")
	assert_eq(player.actual_platform, alvo, "o gecko pousou na plataforma de cor diferente")
	assert_true(alvo.esta_travada(), "a troca de cor do caminho de pouso rodou (plataforma do pouso travada)")
	_desconectar_derrota_falsa()


# C601: expiracao com o gecko caindo (velocity.y > 0): a plataforma de cor diferente volta a ser
# atravessavel no frame da expiracao, sem esperar pulo — a reavaliacao forcada da borda da Stage
# (o efeito expira dentro do tick da propria Stage, no mesmo frame).
func test_expiracao_com_gecko_caindo_reavalia_sem_esperar_pulo() -> void:
	_stage = await _novo_stage()
	var player = _player()
	var alvo := _plataforma_de_pouso()
	assert_ne(alvo, null, "fixture: plataforma abaixo do ponto inicial")
	alvo.set_color(_outra_cor(player.color))
	_iniciar_partida()
	# gecko caindo e sem reavaliacao propria: a fisica dele desligada, so a borda da Stage mexe na colisao
	player.set_physics_process(false)
	player.velocity.y = 200.0
	_estado().coletar(_camaleao(0.3))
	await _fisica(2)
	assert_false(alvo.shape.disabled, "com Camaleao ativo a plataforma de outra cor e solida")
	await _fisica(45)
	assert_null(_estado().ativo(), "fixture: o Camaleao expirou (0,3 s de jogo)")
	assert_true(alvo.shape.disabled, "expirou com o gecko caindo: atravessavel no frame, sem esperar pulo")
	_desconectar_derrota_falsa()


# C602: plataforma desmoronada ou invisivel por piscar nunca fica solida com Camaleao ativo, nem
# reativada na ativacao/expiracao — a excecao vem antes da cor livre na regra de colisao.
func test_desmoronada_e_invisivel_por_piscar_nunca_ficam_solidas() -> void:
	Global.cor_gecko = Enums.COLOR.AZUL
	var outra: Enums.COLOR = _outra_cor(Global.cor_gecko)
	var desmoronada: Platform = load(PLATFORM_SCENE).instantiate()
	desmoronada.set_color(outra)
	desmoronada.desmoronada = true
	add_child_autofree(desmoronada)
	var invisivel: Platform = load(PLATFORM_SCENE).instantiate()
	invisivel.set_color(outra)
	invisivel.set("_pisca_oculta", true)
	add_child_autofree(invisivel)
	assert_true(desmoronada.shape.disabled, "desmoronada nasce atravessavel (cor diferente)")
	assert_true(invisivel.shape.disabled, "invisivel por piscar nasce atravessavel (cor diferente)")
	# ativacao do Camaleao: a reavaliacao de borda passa por todas; a excecao segue valendo
	Global.cor_livre = true
	desmoronada.player_color_changed(Global.cor_gecko)
	invisivel.player_color_changed(Global.cor_gecko)
	assert_true(desmoronada.shape.disabled, "desmoronada nunca fica solida com cor livre (ativacao)")
	assert_true(invisivel.shape.disabled, "invisivel por piscar nunca fica solida com cor livre (ativacao)")
	# expiracao: idem com a regra de cor de volta
	Global.cor_livre = false
	desmoronada.player_color_changed(Global.cor_gecko)
	invisivel.player_color_changed(Global.cor_gecko)
	assert_true(desmoronada.shape.disabled, "desmoronada nunca reativada na expiracao")
	assert_true(invisivel.shape.disabled, "invisivel por piscar nunca reativada na expiracao")


# C603: plataforma instanciada durante o efeito nasce solida (cor diferente) e deixa de ser ao expirar
# (Platform._ready consulta a flag; o sinal de troca de cor so nao basta). Sem o efeito, cor diferente
# nasce atravessavel: o default da cena e solida, e a regra do nascimento que a desliga.
func test_plataforma_nascida_no_efeito_nasce_solida_e_deixa_de_ser_ao_expirar() -> void:
	Global.cor_gecko = Enums.COLOR.AZUL
	var outra: Enums.COLOR = _outra_cor(Global.cor_gecko)
	Global.cor_livre = true
	var no_efeito: Platform = load(PLATFORM_SCENE).instantiate()
	no_efeito.set_color(outra)
	add_child_autofree(no_efeito)
	assert_false(no_efeito.shape.disabled, "nasce durante o efeito: solida mesmo em cor diferente")
	# expiracao: a reavaliacao de borda devolve a regra de cor
	Global.cor_livre = false
	no_efeito.player_color_changed(Global.cor_gecko)
	assert_true(no_efeito.shape.disabled, "deixa de ser solida ao expirar")
	var sem_efeito: Platform = load(PLATFORM_SCENE).instantiate()
	sem_efeito.set_color(outra)
	add_child_autofree(sem_efeito)
	assert_true(sem_efeito.shape.disabled, "sem o efeito, cor diferente nasce atravessavel")


# C604: a actual_platform (sob o gecko) nao e reavaliada na ativacao nem na expiracao — o gecko nao cai
# ao expirar em cima de cor diferente (a Global pula a atual na reavaliacao, Global.gd:283).
func test_actual_platform_nao_reavaliada_gecko_nao_cai_ao_expirar() -> void:
	_stage = await _novo_stage()
	var player = _player()
	var alvo := _plataforma_de_pouso()
	assert_ne(alvo, null, "fixture: plataforma abaixo do ponto inicial")
	alvo.set_color(_outra_cor(player.color))
	_iniciar_partida()
	# ativacao com o gecko no ar: a borda solidifica a cor diferente e ele pousa nela
	_estado().coletar(_camaleao(2.0))
	player.global_position = Vector2(alvo.global_position.x, alvo.global_position.y - ALTURA_QUEDA_PX)
	player.velocity = Vector2.ZERO
	await _fisica(60)
	assert_true(player.is_on_floor(), "fixture: pouso na cor diferente (solida pelo Camaleao)")
	assert_eq(player.actual_platform, alvo, "fixture: o pouso e a actual_platform")
	# expiracao com o gecko em cima da cor diferente: a borda nao reavalia a atual, o gecko nao cai
	await _fisica(75)
	assert_null(_estado().ativo(), "fixture: o Camaleao expirou (2,0 s de jogo)")
	assert_true(alvo.esta_travada(), "a plataforma do gecko segue travada na expiracao")
	assert_false(alvo.shape.disabled, "a actual_platform nao e reavaliada: segue solida")
	assert_true(player.is_on_floor(), "o gecko nao cai ao expirar")
	_desconectar_derrota_falsa()


# C605: pausa (tree.paused) congela o contador do Camaleao; o tempo de jogo (tick) o expira, nao o
# tempo de relogio. Duracao lida do Resource de producao (nenhum literal de duracao aqui).
func test_pausa_congela_e_o_tempo_de_jogo_expira() -> void:
	Global.power_up_inicial = "camaleao"
	_stage = await _novo_stage()
	_iniciar_partida()
	var ativo: PowerUp = _estado().ativo()
	assert_ne(ativo, null, "camaleao ativo ao iniciar a partida")
	var duracao: float = PowerUpConfig.carregar().duracao_camaleao_vigente()
	assert_eq(ativo.duracao, duracao, "duracao do Camaleao vem do Resource de producao")
	# pausa por mais de uma duracao de relogio: nada expira, o contador nao corre
	get_tree().paused = true
	var antes: float = _estado().restante()
	await _fisica(int(duracao * 60.0) + 30)
	assert_eq(_estado().restante(), antes, "pausado: contador congelado (o relogio nao o expira)")
	assert_ne(_estado().ativo(), null, "tempo de relogio nao expira o Camaleao")
	# de volta ao jogo: a duracao inteira em ticks expira
	get_tree().paused = false
	await _fisica(int(duracao * 60.0) + 30)
	assert_null(_estado().ativo(), "a duracao em tempo de jogo (tick) expira o Camaleao")
	_desconectar_derrota_falsa()
