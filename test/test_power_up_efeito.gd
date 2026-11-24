extends GutTest

# T1 (f522): ponto de efeito do power-up. Hooks de efeito em PowerUp (ignora_cor/fator_scroll), agregados
# em PowerUpState (cor_livre/fator_scroll) e espelhados ao mundo pela Stage (Global.cor_livre, zerada ao
# sair da arvore). Cenarios C592-C596 do 05-test-plan; fakes da f521 seguem neutros sem edicao (C595).

const STAGE_SCENE := "res://scenes/Stage.tscn"

var _stage: Node = null
var _sem_derrota_original := false
var _iniciado_original := false
var _plataformas_original: Array = []
var _tutorial_espelho_original := false
var _cor_livre_original := false


# Temporizado que so acende cor livre (fator neutro): o A da substituicao (C593)
class FakeCorLivre:
	extends PowerUp

	func _init() -> void:
		nome = &"cor_livre"
		duracao = 5.0

	func ignora_cor() -> bool:
		return true


# Temporizado que so reduz o scroll a 0.5 (cor neutra): o B da substituicao (C593)
class FakeFator:
	extends PowerUp

	func _init() -> void:
		nome = &"fator"
		duracao = 3.0

	func fator_scroll() -> float:
		return 0.5


# Temporizado com os dois efeitos (cor livre + fator 0.5): expiracao devolve os dois ao neutro no mesmo
# tick (C592) e a carga coletada por cima nao pode alterar nenhum (C594)
class FakeCompleto:
	extends PowerUp

	func _init() -> void:
		nome = &"completo"
		duracao = 4.0

	func ignora_cor() -> bool:
		return true

	func fator_scroll() -> float:
		return 0.5


# Carga unica (duracao 0) sem override de efeito: guardada a parte do temporizado (C594) e prova do
# neutro herdado por quem nao sobrescreve os hooks (C595)
class FakeCarga:
	extends PowerUp

	func _init() -> void:
		nome = &"carga"
		duracao = 0.0


func before_each() -> void:
	_sem_derrota_original = Global.sem_derrota
	_iniciado_original = Global.iniciado
	_plataformas_original = Global.platforms
	_tutorial_espelho_original = Global.tutorial_visto_espelho
	_cor_livre_original = Global.cor_livre
	Global.tutorial_visto_espelho = true
	Global.platforms = []
	Global.iniciado = false
	Global.cor_livre = false
	# Fakes da task no registro (padrao do test_power_up_stage.gd: fake no before_each, padrao no after_each)
	PowerUps.limpar()
	PowerUps.registrar(&"cor_livre", FakeCorLivre)
	PowerUps.registrar(&"fator", FakeFator)
	PowerUps.registrar(&"carga", FakeCarga)


func after_each() -> void:
	get_tree().paused = false
	_stage = null
	Global.sem_derrota = _sem_derrota_original
	Global.iniciado = _iniciado_original
	Global.platforms = _plataformas_original
	Global.tutorial_visto_espelho = _tutorial_espelho_original
	Global.cor_livre = _cor_livre_original
	PowerUps.restaurar_padrao()


func _novo_stage() -> Node:
	var stage: Node = add_child_autofree(load(STAGE_SCENE).instantiate())
	await wait_frames(2)
	return stage


func _estado() -> PowerUpState:
	return _stage.get("power_up_estado") as PowerUpState


# N frames de fisica crus, pelo sinal da SceneTree (mesma semantica do test_power_up_stage.gd)
func _fisica(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


# C592: sem power-up ativo o agregado e neutro (cor_livre falso, fator 1.0); com temporizado que
# sobrescreve, os valores valem ate expirar e voltam ao neutro NO TICK da expiracao (mesmo tick, nao
# um frame depois)
func test_sem_ativo_agregado_neutro_e_expira_no_tick_exato() -> void:
	var estado := PowerUpState.new()
	assert_false(estado.cor_livre(), "sem ativo: sem cor livre")
	assert_eq(estado.fator_scroll(), 1.0, "sem ativo: fator neutro 1.0")
	estado.coletar(FakeCompleto.new())
	assert_true(estado.cor_livre(), "com temporizado ativo: cor livre vale")
	assert_eq(estado.fator_scroll(), 0.5, "com temporizado ativo: fator vale")
	estado.tick(3.9)
	assert_true(estado.cor_livre(), "antes de expirar: cor livre segue valendo")
	estado.tick(0.2)
	assert_false(estado.cor_livre(), "no tick que expira: cor ja voltou ao neutro (nao um frame depois)")
	assert_eq(estado.fator_scroll(), 1.0, "no tick que expira: fator ja voltou ao neutro")


# C593: substituir temporizado A (cor livre) por B (fator 0.5): so o efeito de B vale, o de A nao vaza
func test_substituir_cor_livre_por_fator_so_o_efeito_de_b_vale() -> void:
	var estado := PowerUpState.new()
	estado.coletar(FakeCorLivre.new())
	assert_true(estado.cor_livre(), "fixture: A (cor livre) ativo")
	estado.coletar(FakeFator.new())
	assert_false(estado.cor_livre(), "substituido: cor livre de A nao vaza")
	assert_eq(estado.fator_scroll(), 0.5, "substituido: fator de B e o vigente")


# C594: coletar carga com temporizado ativo nao altera cor_livre()/fator_scroll(); partida nova (estado
# recriado) zera os dois
func test_carga_com_temporizado_nao_altera_agregado_e_partida_nova_zera() -> void:
	var estado := PowerUpState.new()
	estado.coletar(FakeCompleto.new())
	estado.tick(1.0)
	estado.coletar(FakeCarga.new())
	assert_eq(estado.carga(), 1, "fixture: a carga foi guardada com temporizado ativo")
	assert_true(estado.cor_livre(), "carga guardada nao desliga a cor livre do temporizado")
	assert_eq(estado.fator_scroll(), 0.5, "carga guardada nao altera o fator do temporizado")
	# Partida nova: o estado e recriado zerado (PowerUpState e membro da Stage, nunca de Global)
	var nova := PowerUpState.new()
	assert_false(nova.cor_livre(), "partida nova: cor livre zerada")
	assert_eq(nova.fator_scroll(), 1.0, "partida nova: fator neutro")


# C595: PowerUpDeTeste e fakes sem override seguem neutros sem edicao (os 6 testes da f521 rodam verdes)
func test_power_up_de_teste_e_fakes_seguem_neutros_sem_edicao() -> void:
	var padrao := PowerUpDeTeste.new()
	assert_false(padrao.ignora_cor(), "PowerUpDeTeste sem override: ignora_cor neutro")
	assert_eq(padrao.fator_scroll(), 1.0, "PowerUpDeTeste sem override: fator neutro")
	var neutro := FakeCarga.new()
	assert_false(neutro.ignora_cor(), "fake sem override: ignora_cor neutro")
	assert_eq(neutro.fator_scroll(), 1.0, "fake sem override: fator neutro")


# C596: a Stage espelha o efeito em Global.cor_livre e zera a flag ao sair da arvore: a Stage seguinte
# nao herda cor livre (o estado vive na Stage; em Global so a flag de leitura)
func test_flag_cor_livre_e_zerada_ao_sair_da_stage() -> void:
	Global.sem_derrota = true
	_stage = await _novo_stage()
	_stage.call("_coletar_power_up", &"cor_livre")
	await _fisica(2)
	assert_true(Global.cor_livre, "fixture: coleta propagada a flag pela Stage")
	var area: Area2D = _stage.get_node("CheckPlayer") as Area2D
	area.body_exited.disconnect(Callable(_stage, "_on_CheckPlayer_body_exited"))
	_stage.queue_free()
	await _fisica(3)
	assert_false(Global.cor_livre, "sair da Stage zera a flag no _exit_tree")
	_stage = await _novo_stage()
	assert_false(Global.cor_livre, "nova Stage nao herda cor livre")
	assert_false(_estado().cor_livre(), "estado da nova Stage nasce neutro")
