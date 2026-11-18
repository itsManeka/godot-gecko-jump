extends GutTest

# T6 (f465): o pouso confirmado do gecko avisa a plataforma (hooks ao_pousar), antes da troca de cor.
const PLAYER := "res://scenes/Player.tscn"
const PLATAFORMA := "res://scenes/Platform.tscn"
const Y_BAIXO := 200.0
const Y_CIMA := Y_BAIXO - InitialRows.ESPACAMENTO
const ATRASO_LONGO := 100.0


# Modificador espiao: conta os pousos e guarda a cor da plataforma e do gecko no instante do aviso.
class Espiao:
	extends PlatformModifier
	var pousos := 0
	var cor_plataforma := -1
	var cor_gecko := -1
	var gecko: Node = null

	func ao_pousar(plataforma: Platform, _snapshot: DifficultySnapshot) -> void:
		pousos += 1
		cor_plataforma = plataforma.color
		if gecko != null:
			cor_gecko = gecko.color


var _sv: SubViewport
var _p: Node


func before_each() -> void:
	PlatformModifiers.restaurar_padrao()
	Global.platforms = []
	Global.iniciado = false
	Global.cor_gecko = Enums.COR_INICIAL
	_sv = SubViewport.new()
	_sv.size = Vector2i(180, 320)
	add_child_autofree(_sv)
	_p = load(PLAYER).instantiate()
	_sv.add_child(_p)
	_p.set_physics_process(false)
	_p.set_process(false)


func after_each() -> void:
	PlatformModifiers.restaurar_padrao()
	Global.platforms = []
	Global.iniciado = false
	Global.cor_gecko = Enums.COR_INICIAL


func _plataforma(y: float, x: float, cor: int, modificadores: Array = []) -> Platform:
	var pl: Platform = load(PLATAFORMA).instantiate()
	pl.set_color(cor)
	var snapshot := DifficultySnapshot.new(
		DifficultyStage.SCROLL_PADRAO,
		DifficultyStage.SPEED_PADRAO,
		DifficultyStage.K_PADRAO,
		DifficultyStage.PROPORCAO_PADRAO,
		[],
		DifficultyStage.LARGURA_PLATAFORMA_PADRAO,
		ATRASO_LONGO
	)
	pl.definir_modificadores(modificadores, snapshot)
	_sv.add_child(pl)
	pl.position = Vector2(x, y)
	return pl


func _espiao() -> Espiao:
	var e := Espiao.new()
	e.gecko = _p
	return e


func _soltar_sobre(base: Platform) -> void:
	Global.iniciado = true
	_p.position = Vector2(base.position.x, base.position.y - 60.0)
	_p.rng = RandomNumberGenerator.new()
	_p.rng.seed = 3
	_p.set_physics_process(true)


func test_pouso_confirmado_inicia_a_contagem_exatamente_uma_vez() -> void:
	var espiao := _espiao()
	var base := _plataforma(Y_BAIXO, 90.0, Enums.COR_INICIAL, [PlatformCrumble.new(), espiao])
	_soltar_sobre(base)
	await wait_physics_frames(90)
	assert_true(_p.is_on_floor(), "o gecko pousou")
	assert_eq(espiao.pousos, 1, "um unico aviso de pouso, mesmo com o gecko parado na plataforma")
	assert_true(base._desmoronando, "o PlatformCrumble iniciou a contagem")


func test_atravessar_subindo_sem_pouso_nao_inicia_a_contagem() -> void:
	var espiao := _espiao()
	var base := _plataforma(Y_BAIXO, 90.0, Enums.COR_INICIAL, [PlatformCrumble.new(), espiao])
	_p._on_DetectorPlataforma_body_entered(base)
	await wait_physics_frames(3)
	assert_true(_p.can_change_color, "o detector so arma a troca de cor")
	assert_eq(espiao.pousos, 0, "body_entered sem pouso nao avisa a plataforma")
	assert_false(base._desmoronando, "a contagem nao comecou")


func test_plataforma_liberada_no_frame_do_pouso_segue_com_ponto_e_cor() -> void:
	var base := _plataforma(Y_BAIXO, 90.0, Enums.COR_INICIAL)
	_soltar_sobre(base)
	await wait_physics_frames(90)
	assert_true(_p.is_on_floor(), "o gecko pousou")
	var espiao := _espiao()
	var outra := _plataforma(20.0, 150.0, Enums.COLOR.AMARELO, [espiao])
	_p._on_DetectorPlataforma_body_entered(outra)
	assert_true(_p.can_change_color, "o detector arma a troca")
	outra.free()
	watch_signals(_p)
	await wait_physics_frames(2)
	assert_eq(espiao.pousos, 0, "o aviso de pouso da plataforma liberada foi descartado")
	assert_false(_p.can_change_color, "a troca terminou sem erro")
	assert_signal_emit_count(_p, "add_point", 1, "o pouso deu o ponto")
	assert_true(Enums.COLOR.values().has(_p.color), "cor valida")
	assert_eq(Global.cor_gecko, _p.color, "Global.cor_gecko acompanha a cor do gecko")


func test_hook_de_pouso_roda_antes_da_troca_de_cor() -> void:
	var espiao := _espiao()
	var base := _plataforma(Y_BAIXO, 90.0, Enums.COR_INICIAL, [espiao])
	# Linha de cima com so uma cor diferente da do pouso: a nova cor do gecko e determinista.
	var nova := Enums.COLOR.AZUL if Enums.COR_INICIAL != Enums.COLOR.AZUL else Enums.COLOR.VERDE
	_plataforma(Y_CIMA, 90.0, nova)
	Global.player_color_changed(Enums.COR_INICIAL, null)
	_soltar_sobre(base)
	await wait_physics_frames(90)
	assert_eq(espiao.pousos, 1, "o pouso foi avisado")
	assert_eq(espiao.cor_plataforma, Enums.COR_INICIAL, "a plataforma recebe o pouso com a cor do pouso")
	assert_eq(espiao.cor_gecko, Enums.COR_INICIAL, "o gecko ainda tem a cor do pouso no aviso")
	assert_eq(_p.color, nova, "depois do aviso o gecko trocou de cor")
