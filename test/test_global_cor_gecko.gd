extends GutTest

# Global guarda a cor corrente do gecko e ela volta a Enums.COR_INICIAL a cada partida nova (Stage recarregada).
const STAGE_SCENE := "res://scenes/Stage.tscn"
const PLAYER_PATH := "Node2D/Player"

var _cor_original: Enums.COLOR
var _geradores_vistos: Array = []
var _cores_no_primeiro_gerador: Array = []


func before_each() -> void:
	_cor_original = Global.cor_gecko
	Global.platforms = []
	Global.iniciado = false
	_geradores_vistos = []
	_cores_no_primeiro_gerador = []


func after_each() -> void:
	if get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.disconnect(_on_node_added)
	Global.cor_gecko = _cor_original
	Global.platforms = []
	Global.iniciado = false


func _outra_cor() -> Enums.COLOR:
	return Enums.COLOR.AZUL if Enums.COR_INICIAL != Enums.COLOR.AZUL else Enums.COLOR.VERDE


# Captura a cor guardada no instante em que cada gerador de plataformas entra na arvore (antes do _ready dele).
func _on_node_added(node: Node) -> void:
	if node.has_method("preencher_linha"):
		_geradores_vistos.append(node)
		_cores_no_primeiro_gerador.append(Global.cor_gecko)


func _terminar_partida_em_outra_cor() -> void:
	var stage: Node = load(STAGE_SCENE).instantiate()
	add_child(stage)
	var player = stage.get_node(PLAYER_PATH)
	player.set_color(_outra_cor())
	assert_eq(Global.cor_gecko, _outra_cor(), "a partida terminou numa cor diferente da inicial")
	stage.queue_free()
	await wait_frames(2)


func test_default_do_campo_e_a_cor_inicial() -> void:
	var global_novo = autofree(load("res://scripts/Global.gd").new())
	assert_eq(global_novo.cor_gecko, Enums.COR_INICIAL, "autoload recem-carregado comeca na cor inicial")


func test_player_color_changed_grava_a_ultima_cor() -> void:
	var primeira: Enums.COLOR = _outra_cor()
	var segunda: Enums.COLOR = Enums.COLOR.VERMELHO
	assert_ne(primeira, Enums.COR_INICIAL, "fixture: primeira cor difere da inicial")
	assert_ne(segunda, primeira, "fixture: as duas cores sao distintas")
	Global.player_color_changed(primeira, null)
	assert_eq(Global.cor_gecko, primeira, "campo segue a primeira chamada")
	Global.player_color_changed(segunda, null)
	assert_eq(Global.cor_gecko, segunda, "campo segue a ultima chamada")


func test_stage_recarregada_volta_a_cor_inicial_antes_do_primeiro_frame() -> void:
	await _terminar_partida_em_outra_cor()
	var stage: Node = add_child_autofree(load(STAGE_SCENE).instantiate())
	assert_not_null(stage, "Stage nova instanciada")
	assert_eq(Global.cor_gecko, Enums.COR_INICIAL, "partida nova comeca em COR_INICIAL, sem esperar frame")


func test_geradores_da_stage_nova_leem_a_cor_inicial_no_primeiro_preenchimento() -> void:
	await _terminar_partida_em_outra_cor()
	get_tree().node_added.connect(_on_node_added)
	add_child_autofree(load(STAGE_SCENE).instantiate())
	get_tree().node_added.disconnect(_on_node_added)
	assert_gt(_cores_no_primeiro_gerador.size(), 0, "a Stage nova criou ao menos um gerador no _ready")
	for cor in _cores_no_primeiro_gerador:
		assert_eq(cor, Enums.COR_INICIAL, "gerador ve COR_INICIAL, nao a cor da partida anterior")
