extends GutTest

# f524 T4: relogio do Contra o tempo na linha de duracao do HUD (handoff de design, secao 3: x 138-178, y 30-46).
# Formato e retangulo sao testados no HUD solto; visibilidade e texto, na Stage real (o HUD le o estado publicado dela).
const STAGE_SCENE := "res://scenes/Stage.tscn"
const VISIVEL := Vector2(180.0, 320.0)
const SAFE := Rect2(0.0, 0.0, 180.0, 320.0)

var _stage: Node = null
var _modo_original: StringName = GameModes.ID_CLASSICO
var _iniciado_original: bool = false
var _tutorial_original: bool = false


func before_each() -> void:
	_modo_original = Global.get_modo_jogo()
	_iniciado_original = Global.iniciado
	_tutorial_original = Global.tutorial_visto_espelho
	Global.tutorial_visto_espelho = true
	Global.iniciado = false
	Global.set_modo_jogo(GameModes.ID_TEMPO, false)


func after_each() -> void:
	Global.iniciado = _iniciado_original
	Global.tutorial_visto_espelho = _tutorial_original
	Global.set_modo_jogo(_modo_original, false)
	_stage = null


func _novo_stage() -> Node:
	_stage = load(STAGE_SCENE).instantiate()
	var scroll: Node = _stage.get_node("ScrollLevel")
	_stage.remove_child(scroll)
	scroll.free()
	add_child_autofree(_stage)
	await wait_frames(2)
	_stage.apply_layout(VISIVEL, SAFE)
	_stage.set_physics_process(false)
	_stage.get_node("Node2D/Player").set_physics_process(false)
	return _stage


func _publicar(estado: String, restante: int) -> void:
	_stage.ultimo_estado = {"state": estado, "relogio": {"restante": restante}}


func _hud() -> PowerUpHud:
	return _stage.power_up_hud


func test_c697_formata_m_ss_arredondando_para_cima() -> void:
	assert_eq(PowerUpHud.formatar_relogio(60.0), "1:00", "C697: 60.0 -> 1:00")
	assert_eq(PowerUpHud.formatar_relogio(59.0), "0:59", "C697: 59.0 -> 0:59")
	assert_eq(PowerUpHud.formatar_relogio(0.2), "0:01", "C697: 0.2 s -> 0:01")
	assert_eq(PowerUpHud.formatar_relogio(0.0), "0:00", "C697: 0 -> 0:00")
	assert_eq(PowerUpHud.formatar_relogio(9.0), "0:09", "C697: 9 s -> 0:09 (zero a esquerda)")
	assert_eq(PowerUpHud.formatar_relogio(59.01), "1:00", "C697: 59.01 s -> 1:00")


func test_c698_visivel_so_no_tempo_com_partida_iniciada_e_antes_de_lost() -> void:
	await _novo_stage()
	_publicar("playing", 42)
	_hud().atualizar()
	assert_false(_hud().relogio_visivel(), "C698: antes de iniciar o relogio fica oculto")
	Global.iniciado = true
	_hud().atualizar()
	assert_true(_hud().relogio_visivel(), "C698: Tempo + iniciada: visivel")
	assert_eq(_hud().texto_relogio(), "0:42", "C698: texto m:ss do restante publicado")
	_publicar("lost", 0)
	_hud().atualizar()
	assert_false(_hud().relogio_visivel(), "C698: apos lost o relogio some")
	_publicar("playing", 42)
	# O modo so troca com o jogo nao iniciado (como no seletor)
	Global.iniciado = false
	Global.set_modo_jogo(GameModes.ID_CLASSICO, false)
	Global.iniciado = true
	assert_eq(Global.get_modo_jogo(), GameModes.ID_CLASSICO, "fixture: modo Classico ativo")
	_hud().atualizar()
	assert_false(_hud().relogio_visivel(), "C698: Classico nao mostra o relogio")
	Global.iniciado = false
	Global.set_modo_jogo(GameModes.ID_PURO, false)
	Global.iniciado = true
	assert_eq(Global.get_modo_jogo(), GameModes.ID_PURO, "fixture: modo Puro ativo")
	_hud().atualizar()
	assert_false(_hud().relogio_visivel(), "C698: Puro nao mostra o relogio")


func test_c738_zen_nunca_mostra_relogio_e_hud_recebe_o_relogio_da_stage() -> void:
	await _novo_stage()
	Global.iniciado = true
	_publicar("playing", 42)
	_hud().atualizar()
	assert_true(_hud().relogio_visivel(), "C738: Tempo mostra o relogio injetado pela Stage")
	assert_eq(_hud().texto_relogio(), "0:42", "C738: Tempo mostra o restante da Stage")
	Global.iniciado = false
	Global.set_modo_jogo(GameModes.ID_ZEN, false)
	Global.iniciado = true
	assert_eq(Global.get_modo_jogo(), GameModes.ID_ZEN, "fixture: modo Zen ativo")
	_publicar("playing", 42)
	_hud().atualizar()
	assert_false(_hud().relogio_visivel(), "C738: Zen nunca mostra o relogio")


func test_c738_hud_sem_fonte_de_relogio_nunca_mostra() -> void:
	var hud: PowerUpHud = PowerUpHud.new()
	add_child_autofree(hud)
	Global.iniciado = true
	hud.atualizar()
	assert_false(hud.relogio_visivel(), "C738: sem fonte injetada o relogio fica oculto")
	hud.fonte_relogio = func() -> Dictionary: return {"ativo": true, "restante": 9.0}
	hud.atualizar()
	assert_true(hud.relogio_visivel(), "C738: com fonte ativa o HUD mostra o que recebeu")
	assert_eq(hud.texto_relogio(), "0:09", "C738: texto vem do restante injetado")


func test_c739_hud_nao_referencia_modo_tempo_nem_fonte_estado() -> void:
	var texto: String = FileAccess.get_file_as_string("res://scenes/PowerUpHud.gd")
	assert_ne(texto, "", "fixture: PowerUpHud.gd lido")
	assert_eq(texto.find("ID_TEMPO"), -1, "C739: o HUD nao referencia GameModes.ID_TEMPO")
	assert_eq(texto.find("fonte_estado"), -1, "C739: o HUD nao referencia fonte_estado")


func test_c698_card_do_tutorial_oculta_o_relogio_e_fechar_mostra_sem_zerar_o_texto() -> void:
	await _novo_stage()
	Global.iniciado = true
	_publicar("playing", 42)
	_hud().atualizar()
	assert_true(_hud().relogio_visivel(), "fixture: relogio visivel antes do card")
	var card: TutorialCard = _stage.get("tutorial_card") as TutorialCard
	card.abrir(TutorialCard.Variante.TECLADO)
	assert_true(card.esta_aberto(), "fixture: card aberto")
	_hud().atualizar()
	assert_false(_hud().relogio_visivel(), "C698: card aberto oculta o relogio")
	card.fechar(true)
	assert_false(card.esta_aberto(), "fixture: card fechado")
	_hud().atualizar()
	assert_true(_hud().relogio_visivel(), "C698: fechar o card mostra o relogio de novo")
	assert_eq(_hud().texto_relogio(), "0:42", "C698: o texto nao foi zerado")


func test_c699_rect_relogio_nas_medidas_do_handoff_nas_duas_alturas() -> void:
	var hud: PowerUpHud = PowerUpHud.new()
	add_child_autofree(hud)
	for altura in [320.0, 400.0]:
		hud.aplicar_layout(Vector2(180.0, altura), Rect2(0.0, 0.0, 180.0, altura))
		var r: Rect2 = hud.rect_relogio()
		assert_eq(r.position, Vector2(138.0, 30.0), "C699: origem x 138, y 30 em 180x%d" % int(altura))
		assert_eq(r.end, Vector2(178.0, 46.0), "C699: fim x 178, y 46 em 180x%d" % int(altura))
		assert_false(r.intersects(hud.rect_segundos()), "C699: relogio nao cobre os segundos (x 66-82)")
		assert_false(r.intersects(hud.rect_carga()), "C699: relogio nao cobre a carga (x 90-106)")
