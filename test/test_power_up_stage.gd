extends GutTest

# T4 (f521): coleta e ciclo de vida do PowerUpState na Stage real. Cenarios C552-C556 do 05-test-plan.
# O pouso e real: o gecko e teleportado acima da plataforma e a fisica da arvore derruba o bloco de
# pouso do Player (detector -> is_on_floor -> notificar_pouso -> sinal -> Stage). C557 (notificar_pouso
# sem power-up) ja vive em test_platform_narrower_crumble.gd, que segue verde.

const STAGE_SCENE := "res://scenes/Stage.tscn"
# Altura do teleporte acima da plataforma de pouso: ~20 frames de queda com a gravidade do Player
const ALTURA_QUEDA_PX := 30.0

var _stage: Node = null
var _sem_derrota_original := false
var _iniciado_original := false
var _plataformas_original: Array = []
var _tutorial_espelho_original := false


# Carga de teste (duracao 0: guardada a parte, maximo 1); o temporizado e o PowerUpDeTeste de producao
class FakeCarga:
	extends PowerUp

	var ativacoes: int = 0
	var encerramentos: int = 0

	func _init() -> void:
		nome = &"carga"
		duracao = 0.0

	func ao_ativar() -> void:
		ativacoes += 1

	func ao_encerrar() -> void:
		encerramentos += 1


func before_each() -> void:
	_sem_derrota_original = Global.sem_derrota
	_iniciado_original = Global.iniciado
	_plataformas_original = Global.platforms
	_tutorial_espelho_original = Global.tutorial_visto_espelho
	Global.tutorial_visto_espelho = true
	Global.platforms = []
	Global.iniciado = false
	# Fakes da task no registro (padrao do 05: fake no before_each, padrao vazio no after_each)
	PowerUps.limpar()
	PowerUps.registrar(PowerUpDeTeste.NOME_PADRAO, PowerUpDeTeste)
	PowerUps.registrar(&"carga", FakeCarga)


func after_each() -> void:
	get_tree().paused = false
	_stage = null
	Global.sem_derrota = _sem_derrota_original
	Global.iniciado = _iniciado_original
	Global.platforms = _plataformas_original
	Global.tutorial_visto_espelho = _tutorial_espelho_original
	PowerUps.restaurar_padrao()


func _novo_stage() -> Node:
	var stage: Node = add_child_autofree(load(STAGE_SCENE).instantiate())
	await wait_frames(2)
	return stage


# Estado de power-up da Stage (PowerUpState e membro dela, nunca de Global)
func _estado() -> PowerUpState:
	return _stage.get("power_up_estado") as PowerUpState


# Partida iniciada pelo caminho oficial do Play: started + Global.set_iniciado(true) + player visivel
func _iniciar_partida() -> void:
	_stage.call("_on_Play_button_down")


# Plataforma estatica e plana (sem piscar/ciclo, speed 0) abaixo do ponto de partida do gecko: a linha
# inicial garante cor_inicial sem piscar/ciclo/queda sob o gecko, entao sempre ha candidata; abaixo do
# ponto de partida a camera do topo nunca avanca durante o pouso
func _plataforma_de_pouso(evitar: Platform = null) -> Platform:
	var player = _stage.get_node("Node2D/Player")
	var y_partida: float = player.global_position.y
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


# Icone nasce na plataforma ja em arvore (o gerador chama definir_power_up antes do add_child e o _ready
# posiciona; aqui o posicionamento e explicito, o resto e o mesmo contrato)
func _dar_power_up(plataforma: Platform, tipo: StringName) -> void:
	plataforma.definir_power_up(tipo)
	plataforma._posicionar_icone()


# Teleporta o gecko acima da plataforma e deixa a fisica real derruba-lo nela (o fluxo do jogo:
# detector dispara -> is_on_floor -> bloco de pouso do Player -> notificar_pouso -> sinal -> Stage)
func _pousar_em(plataforma: Platform) -> void:
	var player = _stage.get_node("Node2D/Player")
	plataforma.set_color(player.color)
	plataforma.player_color_changed(player.color)
	player.global_position = Vector2(
		plataforma.global_position.x, plataforma.global_position.y - ALTURA_QUEDA_PX
	)
	player.velocity = Vector2.ZERO


# Re-pouso na mesma plataforma: o gecko segue em cima dela; o detector autoriza a troca de cor de novo
func _pousar_de_novo(plataforma: Platform) -> void:
	var player = _stage.get_node("Node2D/Player")
	player.actual_platform = plataforma
	player.can_change_color = true


# N frames de fisica crus, pelo sinal da SceneTree: dispara mesmo com a arvore pausada (o helper
# wait_physics_frames do GUT depende de timer proprio, que congela junto na pausa e travaria o
# cenario C553). Mesma semantica do 05: N frames avancam, sem chamar tick na mao.
func _fisica(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


# C552: pousar em plataforma com power-up ativa o fake e remove o icone; pousar de novo na mesma
# NAO ativa de novo (ao_ativar 1x)
func test_pouso_coleta_o_fake_uma_vez_e_remove_o_icone() -> void:
	Global.sem_derrota = true  # cor do pouso fixa: o gecko repousa na plataforma entre os pousos
	_stage = await _novo_stage()
	var plataforma := _plataforma_de_pouso()
	assert_ne(plataforma, null, "fixture: plataforma estatica e plana abaixo do ponto de partida")
	_dar_power_up(plataforma, PowerUpDeTeste.NOME_PADRAO)
	assert_ne(plataforma.icone_power_up, null, "icone nasce com o tipo")
	_iniciar_partida()
	_pousar_em(plataforma)
	await _fisica(60)
	var ativo := _estado().ativo() as PowerUpDeTeste
	assert_ne(ativo, null, "o pouso ativou o fake")
	assert_eq(ativo.ativacoes, 1, "ao_ativar chamado 1x")
	assert_eq(ativo.encerramentos, 0, "fake ativo: sem ao_encerrar")
	assert_eq(plataforma.tipo_power_up, &"", "tipo consumido no pouso (coleta unica)")
	assert_eq(plataforma.icone_power_up, null, "icone removido no pouso")
	var restante_1: float = _estado().restante()
	assert_gt(restante_1, 0.3, "o temporizado corre com a partida")
	assert_lt(restante_1, PowerUpDeTeste.DURACAO_PADRAO, "restante dentro da duracao do fake")
	# pousar de novo na mesma plataforma: o tipo foi consumido, nao ativa de novo
	_pousar_de_novo(plataforma)
	await _fisica(30)
	var ativo_2 := _estado().ativo() as PowerUpDeTeste
	assert_ne(ativo_2, null, "fake segue ativo (nao expirou na janela do teste)")
	assert_eq(ativo_2.ativacoes, 1, "pousar de novo na mesma NAO ativa de novo")
	assert_lt(_estado().restante(), restante_1, "o tempo seguiu correndo (duracao nao reiniciou)")


# C553: com fake ativo, pausar a arvore congela restante(); ao despausar volta a correr sem tick manual
func test_pausa_congela_o_temporizado_e_despausar_retoma() -> void:
	Global.sem_derrota = true
	_stage = await _novo_stage()
	var plataforma := _plataforma_de_pouso()
	_dar_power_up(plataforma, PowerUpDeTeste.NOME_PADRAO)
	_iniciar_partida()
	_pousar_em(plataforma)
	await _fisica(60)
	assert_ne(_estado().ativo(), null, "fixture: fake ativo antes da pausa")
	var antes: float = _estado().restante()
	get_tree().paused = true
	await _fisica(30)
	assert_eq(_estado().restante(), antes, "pausado: restante inalterado")
	get_tree().paused = false
	await _fisica(30)
	assert_lt(_estado().restante(), antes, "despausado: o tempo volta a correr (sem tick na mao)")
	assert_ne(_estado().ativo(), null, "fake segue ativo apos a espera")


# C554: reinicio — a Stage seguinte nasce com PowerUpState vazio (ativo e carga zerados); o estado
# nunca vive em Global (e membro da Stage, recriado a cada cena)
func test_reinicio_stage_seguinte_nasce_com_estado_vazio() -> void:
	Global.sem_derrota = true
	_stage = await _novo_stage()
	var plataforma := _plataforma_de_pouso()
	var outra := _plataforma_de_pouso(plataforma)
	assert_ne(outra, null, "fixture: segunda plataforma de pouso na linha inicial")
	_dar_power_up(plataforma, PowerUpDeTeste.NOME_PADRAO)
	_dar_power_up(outra, &"carga")
	_iniciar_partida()
	_pousar_em(plataforma)
	await _fisica(60)
	assert_ne(_estado().ativo(), null, "temporizado ativo na 1a Stage")
	_pousar_em(outra)
	await _fisica(60)
	assert_eq(_estado().carga(), 1, "carga guardada na 1a Stage")
	var estado_1a: PowerUpState = _estado()
	# Reinicio: Stage._on_animation_end troca de cena; sem current_scene no GUT, libera e instancia nova
	# Sair da arvore dispara body_exited do CheckPlayer (derrota falsa tocaria audio fora da arvore): desconecta
	var area: Area2D = _stage.get_node("CheckPlayer") as Area2D
	area.body_exited.disconnect(Callable(_stage, "_on_CheckPlayer_body_exited"))
	_stage.queue_free()
	await _fisica(3)
	_stage = await _novo_stage()
	var estado_2a: PowerUpState = _estado()
	assert_ne(estado_2a, estado_1a, "a 2a Stage nasce com estado proprio (nunca em Global)")
	assert_eq(estado_2a.ativo(), null, "2a Stage sem temporizado ativo")
	assert_eq(estado_2a.carga(), 0, "2a Stage com carga zerada")
	assert_eq(estado_2a.restante(), 0.0, "2a Stage com restante zerado")


# C555: fora de partida iniciada (Global.is_iniciado() falso) o tempo do temporizado nao corre
func test_fora_de_partida_iniciada_o_tempo_nao_corre() -> void:
	_stage = await _novo_stage()
	assert_false(Global.is_iniciado(), "fixture: partida nao iniciada")
	# a coleta entra pelo handler do pouso (o bloco do Player exige partida iniciada para pousar)
	_stage.call("_coletar_power_up", PowerUpDeTeste.NOME_PADRAO)
	assert_ne(_estado().ativo(), null, "coletado fora de partida (estado em memoria)")
	assert_eq(_estado().restante(), PowerUpDeTeste.DURACAO_PADRAO, "duracao cheia ao coletar")
	await _fisica(60)
	assert_eq(_estado().restante(), PowerUpDeTeste.DURACAO_PADRAO, "sem partida iniciada o tempo nao corre")


# C556: power_ups_habilitados = false: nenhum icone nasce (linha de fluxo real) e a coleta e ignorada
func test_power_ups_desabilitados_sem_icone_e_coleta_ignorada() -> void:
	Global.sem_derrota = false  # o gate testado e o gancho da Stage, nao o do modo sem derrota
	var stage: Node = load(STAGE_SCENE).instantiate()
	stage.set("power_ups_habilitados", false)  # antes do add_child: o _ready repassa a geracao
	_stage = add_child_autofree(stage)
	await wait_frames(2)
	var scroll: ScrollLevel = _stage.get_node("ScrollLevel") as ScrollLevel
	assert_false(scroll.power_ups_habilitados, "o gancho chega ao ScrollLevel no _ready")
	scroll.create_new_running_platform()
	await wait_frames(3)  # add_child adiado + _ready da linha nova
	var linha: Node = scroll.running_platforms.get_children().back()
	var plataformas: int = 0
	for p in linha.get_children():
		if not (p is Platform):
			continue
		plataformas += 1
		var plat := p as Platform
		assert_eq(plat.tipo_power_up, &"", "plataforma de fluxo sem tipo sorteado")
		assert_eq(plat.icone_power_up, null, "nenhum icone nasce com o gancho desligado")
	assert_gt(plataformas, 0, "fixture: a linha nova tem plataformas")
	# coleta ignorada com o gancho desligado: o estado segue vazio
	_stage.call("_coletar_power_up", PowerUpDeTeste.NOME_PADRAO)
	assert_eq(_estado().ativo(), null, "coleta ignorada com o gancho desligado")
	assert_eq(_estado().carga(), 0, "estado segue vazio (sem temporizado e sem carga)")
