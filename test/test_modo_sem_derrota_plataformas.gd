extends GutTest

# Modo sem derrota (T7): com Global.sem_derrota ligado toda plataforma nasce COR_INICIAL, as moveis com speed 0, e o
# Player mantem COR_INICIAL no pouso. Desligado, tudo segue como antes. Global.sem_derrota volta a false no after_each.

const GERADOR_SCENE := "res://scenes/RunningPlatforms.tscn"
const PLATFORM_SCENE := "res://scenes/Platform.tscn"
const PLAYER_SCENE := "res://scenes/Player.tscn"
const STAGE_SCENE := "res://scenes/Stage.tscn"
const NOVAS_PLATAFORMAS := 10
const ATRASOS := [0, 3, 7, 11, 19]

var _cor_original: Enums.COLOR


func before_each() -> void:
	_cor_original = Global.cor_gecko
	Global.platforms = []
	Global.iniciado = false
	Global.sem_derrota = false


func after_each() -> void:
	Input.action_release("jump")
	randomize()
	Global.sem_derrota = false
	Global.cor_gecko = _cor_original
	Global.platforms = []
	Global.iniciado = false


func _rng(semente: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	return rng


func _gerador(tipo: Enums.PLATFORM_TYPE, garantir: bool = false) -> Node2D:
	var gerador: Node2D = load(GERADOR_SCENE).instantiate()
	gerador.platform_type = tipo
	gerador.garantir_cor_inicial = garantir
	gerador.rng = _rng(7)
	gerador.position = Vector2(0, 100)
	Global.set_iniciado(true)
	add_child_autofree(gerador)
	return gerador


func _plataformas(gerador: Node) -> Array:
	var filhas: Array = []
	for filho in gerador.get_children():
		if filho is Platform:
			filhas.append(filho)
	return filhas


func _outra_cor(excluida: int) -> Enums.COLOR:
	return Enums.COLOR.VERMELHO if excluida != Enums.COLOR.VERMELHO else Enums.COLOR.AZUL


func test_modo_ligado_moveis_nascem_cor_inicial_e_speed_zero_nas_duas_direcoes() -> void:
	Global.sem_derrota = true
	Global.cor_gecko = Enums.COLOR.VERDE
	var total := 0
	for tipo in [Enums.PLATFORM_TYPE.MOVE_TO_LEFT, Enums.PLATFORM_TYPE.MOVE_TO_RIGHT]:
		var gerador := _gerador(tipo)
		for i in NOVAS_PLATAFORMAS:
			gerador.new_platform()
		var filhas := _plataformas(gerador)
		assert_gt(filhas.size(), NOVAS_PLATAFORMAS, "preencher_linha e new_platform criaram plataformas")
		for p in filhas:
			total += 1
			assert_eq(p.color, Enums.COR_INICIAL, "movel nasce com COR_INICIAL no modo sem derrota")
			assert_eq(p.speed, 0, "movel nasce com speed 0 no modo sem derrota")
	assert_gt(total, 0, "alguma plataforma movel foi verificada")


func test_modo_ligado_estaticas_sao_cor_inicial_com_e_sem_garantia() -> void:
	Global.sem_derrota = true
	Global.cor_gecko = Enums.COLOR.VERDE
	for garantir in [true, false]:
		var gerador := _gerador(Enums.PLATFORM_TYPE.STATIC, garantir)
		var filhas := _plataformas(gerador)
		assert_eq(filhas.size(), 3, "gerador estatico cria 3 plataformas")
		for p in filhas:
			assert_eq(p.color, Enums.COR_INICIAL, "estatica nasce com COR_INICIAL no modo sem derrota")


func test_modo_desligado_estaticas_com_garantia_seguem_sorteando() -> void:
	Global.sem_derrota = false
	var diferentes := 0
	for semente in 30:
		seed(semente)
		var gerador := _gerador(Enums.PLATFORM_TYPE.STATIC, true)
		for p in _plataformas(gerador):
			if p.color != Enums.COR_INICIAL:
				diferentes += 1
	assert_gt(diferentes, 0, "com o modo desligado StaticPlatformColors sorteia ao menos 1 cor diferente de COR_INICIAL")


func test_modo_desligado_moveis_mantem_speed_60_e_menos_60() -> void:
	Global.sem_derrota = false
	var esquerda := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT)
	var direita := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_RIGHT)
	assert_gt(_plataformas(esquerda).size(), 0, "MOVE_TO_LEFT criou plataformas")
	assert_gt(_plataformas(direita).size(), 0, "MOVE_TO_RIGHT criou plataformas")
	for p in _plataformas(esquerda):
		assert_eq(p.speed, 60, "MOVE_TO_LEFT com modo desligado: speed 60")
	for p in _plataformas(direita):
		assert_eq(p.speed, -60, "MOVE_TO_RIGHT com modo desligado: speed -60")


func test_modo_desligado_janela_de_k_continua_valendo() -> void:
	Global.sem_derrota = false
	Global.cor_gecko = Enums.COLOR.AZUL
	var gerador := _gerador(Enums.PLATFORM_TYPE.MOVE_TO_LEFT)
	for i in 30:
		gerador.new_platform()
	var cores: Array = []
	for p in _plataformas(gerador):
		cores.append(p.color)
	var sem_a_cor := 0
	for inicio in range(0, cores.size() - ReachableColors.K + 1):
		var tem := false
		for i in range(inicio, inicio + ReachableColors.K):
			if cores[i] == Enums.COLOR.AZUL:
				tem = true
		if not tem:
			sem_a_cor += 1
	assert_gt(cores.size(), 30, "gerador criou plataformas")
	assert_eq(sem_a_cor, 0, "toda janela de K moveis tem a cor do gecko (AZUL) com o modo desligado")
	assert_true(cores.has(Enums.COLOR.AZUL), "a cor do gecko aparece entre as moveis")


# Pouso: atual em y=200, candidatas na linha de cima (y = 200 - ESPACAMENTO) todas de cor `cor_candidata`.
func _player_com_candidatas(cor_candidata: int, com_candidatas: bool) -> Node:
	var player: Node = add_child_autofree(load(PLAYER_SCENE).instantiate())
	var atual: Platform = add_child_autofree(load(PLATFORM_SCENE).instantiate())
	atual.position = Vector2(90, 200)
	if com_candidatas:
		for x in [30, 90, 150]:
			var cima: Platform = add_child_autofree(load(PLATFORM_SCENE).instantiate())
			cima.set_color(cor_candidata)
			cima.position = Vector2(x, 200 - InitialRows.ESPACAMENTO)
	player.actual_platform = atual
	player.rng = _rng(3)
	return player


func test_player_modo_ligado_change_color_random_mantem_cor_inicial() -> void:
	Global.sem_derrota = true
	var outra := _outra_cor(Enums.COR_INICIAL)
	var com_lista := _player_com_candidatas(outra, true)
	com_lista.change_color_random()
	assert_eq(com_lista.color, Enums.COR_INICIAL, "com candidatas de outra cor a cor fica COR_INICIAL")
	Global.platforms = []
	var sem_lista := _player_com_candidatas(outra, false)
	sem_lista.color = outra
	sem_lista.change_color_random()
	assert_eq(sem_lista.color, Enums.COR_INICIAL, "com lista vazia a cor fica COR_INICIAL")


func test_player_modo_desligado_change_color_random_sai_das_candidatas() -> void:
	Global.sem_derrota = false
	var outra := _outra_cor(Enums.COR_INICIAL)
	var player := _player_com_candidatas(outra, true)
	player.change_color_random()
	assert_eq(player.color, outra, "com o modo desligado a cor sai das candidatas (todas da outra cor)")


func _esperar_pouso(player: Node) -> bool:
	for i in 240:
		await wait_physics_frames(1)
		if player.on_ground:
			return true
	return false


func _pular_dois_pulos_com_atraso(atraso: int) -> Dictionary:
	Global.platforms = []
	Global.iniciado = false
	Global.sem_derrota = true
	var stage: Node = add_child_autofree(load(STAGE_SCENE).instantiate())
	await wait_frames(2)
	var player: Node = stage.get_node("Node2D/Player")
	stage._on_Play_button_down()
	var pousou := await _esperar_pouso(player)
	for n in 2:
		if pousou:
			await wait_physics_frames(atraso + 1)
			Input.action_press("jump")
			await wait_physics_frames(1)
			Input.action_release("jump")
			await wait_physics_frames(2)
			pousou = await _esperar_pouso(player)
	await wait_physics_frames(5)
	var resultado := {"score": stage.ultimo_estado["score"], "state": stage.ultimo_estado["state"], "alive": player.is_end() == false}
	remove_child(stage)
	stage.free()
	return resultado


func test_stage_real_modo_ligado_gecko_pontua_e_segue_vivo_em_todos_os_atrasos() -> void:
	for atraso in ATRASOS:
		var r: Dictionary = await _pular_dois_pulos_com_atraso(atraso)
		assert_gte(r["score"], 1, "atraso %d: score >= 1 depois de 2 pulos" % atraso)
		assert_eq(r["state"], "playing", "atraso %d: estado segue playing" % atraso)
		assert_true(r["alive"], "atraso %d: gecko vivo" % atraso)
		Global.platforms = []
		Global.iniciado = false
