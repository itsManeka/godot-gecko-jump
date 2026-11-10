extends GutTest

# T3 (f414): a nova cor do gecko no pouso sai das plataformas visiveis da linha imediatamente acima.
const PLAYER := "res://scenes/Player.tscn"
const PLATAFORMA := "res://scenes/Platform.tscn"
const SEMENTES := 100
const Y_BAIXO := 200.0
const Y_CIMA := Y_BAIXO - InitialRows.ESPACAMENTO

var _sv: SubViewport
var _p: Node


func before_each() -> void:
	Global.platforms = []
	Global.iniciado = false
	_sv = SubViewport.new()
	_sv.size = Vector2i(180, 320)
	add_child_autofree(_sv)
	_p = load(PLAYER).instantiate()
	_sv.add_child(_p)
	_p.set_physics_process(false)
	_p.set_process(false)


func after_each() -> void:
	Global.platforms = []
	Global.iniciado = false


func _plataforma(y: float, x: float, cor: int) -> Platform:
	var pl: Platform = load(PLATAFORMA).instantiate()
	_sv.add_child(pl)
	pl.position = Vector2(x, y)
	pl.set_color(cor)
	return pl


func _rng(semente: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	return rng


# Pousa em `alvo` com a semente dada e devolve a nova cor do gecko.
func _pousar(alvo: Platform, semente: int) -> int:
	_p.actual_platform = alvo
	_p.rng = _rng(semente)
	_p.change_color_random()
	return _p.color


func test_pouso_sorteia_so_entre_azul_e_verde_visiveis_e_as_duas_aparecem() -> void:
	var base := _plataforma(Y_BAIXO, 90.0, Enums.COLOR.AMARELO)
	_plataforma(Y_CIMA, 40.0, Enums.COLOR.AZUL)
	_plataforma(Y_CIMA, 120.0, Enums.COLOR.VERDE)
	_plataforma(Y_CIMA, 200.0, Enums.COLOR.VERMELHO)
	var vistas := {}
	for semente in range(1, SEMENTES + 1):
		vistas[_pousar(base, semente)] = true
	assert_eq(vistas.size(), 2, "so duas cores aparecem (a VERMELHA fora de [0, largura] nunca)")
	assert_true(vistas.has(Enums.COLOR.AZUL), "AZUL aparece")
	assert_true(vistas.has(Enums.COLOR.VERDE), "VERDE aparece")


func test_pouso_com_linha_de_cima_vazia_usa_fallback_sem_perder_ponto() -> void:
	# Pouso real pela fisica: o gecko cai na plataforma, troca de cor e emite add_point.
	Global.iniciado = true
	var base := _plataforma(Y_BAIXO, 90.0, Enums.COR_INICIAL)
	_p.position = Vector2(90.0, Y_BAIXO - 60.0)
	_p.rng = _rng(3)
	_p.set_physics_process(true)
	watch_signals(_p)
	await wait_physics_frames(90)
	assert_eq(_p.actual_platform, base, "o gecko pousou na plataforma de baixo")
	assert_gt(get_signal_emit_count(_p, "add_point"), 0, "o pouso continua dando ponto com a linha de cima vazia")
	assert_true(Enums.COLOR.values().has(_p.color), "fallback devolve cor valida")


func test_pouso_sem_plataforma_atual_nao_quebra_e_devolve_cor_valida() -> void:
	_plataforma(Y_CIMA, 40.0, Enums.COLOR.AZUL)
	var cor := _pousar(null, 5)
	assert_true(Enums.COLOR.values().has(cor), "actual_platform null -> fallback valido, sem erro")


func test_dois_pousos_em_linhas_diferentes_levam_a_cores_de_destino_distintas() -> void:
	var a := _plataforma(Y_BAIXO, 90.0, Enums.COLOR.AMARELO)
	_plataforma(Y_CIMA, 60.0, Enums.COLOR.AZUL)
	var b := _plataforma(300.0, 90.0, Enums.COLOR.AMARELO)
	_plataforma(250.0, 60.0, Enums.COLOR.VERDE)
	assert_eq(_pousar(a, 1), Enums.COLOR.AZUL, "linha acima de A so tem AZUL")
	assert_eq(_pousar(b, 1), Enums.COLOR.VERDE, "linha acima de B so tem VERDE")


func test_linha_de_cima_so_com_a_cor_atual_mantem_a_cor() -> void:
	var base := _plataforma(Y_BAIXO, 90.0, Enums.COLOR.AMARELO)
	_plataforma(Y_CIMA, 60.0, Enums.COLOR.AZUL)
	_p.color = Enums.COLOR.AZUL
	for semente in range(1, SEMENTES + 1):
		assert_eq(_pousar(base, semente), Enums.COLOR.AZUL, "D4: repetir a cor atual e permitido, sem fallback")
