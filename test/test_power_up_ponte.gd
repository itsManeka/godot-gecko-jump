extends GutTest

# T6 (f521): ponte de estado do power-up e parametro debug `?powerup=` na Stage real (C565, C566).

const STAGE_SCENE := "res://scenes/Stage.tscn"

var _stage: Node = null
var _sem_derrota_original := false
var _iniciado_original := false
var _plataformas_original: Array = []
var _tutorial_espelho_original := false
var _power_up_inicial_original := ""


func before_each() -> void:
	_sem_derrota_original = Global.sem_derrota
	_iniciado_original = Global.iniciado
	_plataformas_original = Global.platforms
	_tutorial_espelho_original = Global.tutorial_visto_espelho
	_power_up_inicial_original = Global.power_up_inicial
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


func _novo_stage() -> Node:
	var stage: Node = add_child_autofree(load(STAGE_SCENE).instantiate())
	await wait_frames(2)
	return stage


func _estado() -> PowerUpState:
	return _stage.get("power_up_estado") as PowerUpState


func _powerup_publicado() -> Dictionary:
	return (_stage.get("ultimo_estado") as Dictionary)["powerup"] as Dictionary


func _fisica(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


# C565: a ponte republica o `powerup` 1x por mudanca de segundo (nao a cada frame) e nunca apos a derrota
func test_ponte_republica_powerup_1x_por_segundo_e_nunca_apos_a_derrota() -> void:
	Global.power_up_inicial = "teste"
	_stage = await _novo_stage()
	_stage.call("_on_Play_button_down")
	# gecko parado: so o campo powerup pode mudar o estado publicado (a posicao nao republica)
	var player: Node = _stage.get_node("Node2D/Player")
	player.set_physics_process(false)
	var inicial: Dictionary = _powerup_publicado()
	assert_eq(inicial["ativo"], "teste", "o power-up de debug entrou ao iniciar a partida")
	assert_eq(inicial["restante"], 2, "duracao cheia publicada")
	var anterior: Dictionary = _stage.get("ultimo_estado")
	var republicacoes: int = 0
	for i in 90:
		await _fisica(1)
		var atual: Dictionary = _stage.get("ultimo_estado")
		if not is_same(atual, anterior):
			republicacoes += 1
			anterior = atual
	assert_eq(republicacoes, 1, "90 ticks (1,5 s): 1 republicacao (a virada de 2 para 1 s), nao uma por frame")
	assert_eq(_powerup_publicado()["restante"], 1, "restante publicado depois da virada do segundo")
	# derrota publicada: o campo muda depois (expira) e a ponte nao republica mais
	_stage.call("_publicar_estado", GameState.STATE_LOST, false)
	var perdido: Dictionary = _stage.get("ultimo_estado")
	var restante_perdido: Variant = (perdido["powerup"] as Dictionary)["restante"]
	await _fisica(90)
	assert_eq(_estado().ativo(), null, "fixture: o temporizado expirou durante a espera")
	assert_same(_stage.get("ultimo_estado"), perdido, "apos a derrota a ponte nao republica")
	assert_eq(_powerup_publicado()["restante"], restante_perdido, "powerup congelado no instante da derrota")


# C566: ?powerup=teste ativa o PowerUpDeTeste ao partida_iniciada; nome nao registrado ou vazio nao ativa
func test_stage_com_powerup_teste_ativa_ao_iniciar_a_partida() -> void:
	Global.power_up_inicial = "teste"
	_stage = await _novo_stage()
	assert_eq(_estado().ativo(), null, "antes do Play nada ativo")
	_stage.call("_on_Play_button_down")
	var ativo := _estado().ativo() as PowerUpDeTeste
	assert_ne(ativo, null, "partida_iniciada ativou o PowerUpDeTeste")
	assert_eq(ativo.ativacoes, 1, "ao_ativar 1x")
	assert_eq(_estado().restante(), PowerUpDeTeste.DURACAO_PADRAO, "duracao cheia")


func test_stage_com_powerup_desconhecido_ou_vazio_nao_ativa() -> void:
	PowerUps.limpar()
	Global.power_up_inicial = "inexistente"
	_stage = await _novo_stage()
	_stage.call("_on_Play_button_down")
	assert_eq(_estado().ativo(), null, "nome nao registrado nao ativa")
	assert_eq(_estado().carga(), 0, "sem carga")
	PowerUps.restaurar_padrao()
	Global.power_up_inicial = ""
	var outra: Node = await _novo_stage()
	outra.call("_on_Play_button_down")
	assert_eq((outra.get("power_up_estado") as PowerUpState).ativo(), null, "vazio nao ativa")
