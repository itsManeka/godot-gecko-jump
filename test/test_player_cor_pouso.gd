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


func test_pouso_com_viewport_de_240_usa_largura_180_na_cor() -> void:
	# C143: viewport mais largo que 180; a plataforma azul em x=200 (>180) fica fora da janela jogavel e nunca vence.
	_sv.size = Vector2i(240, 320)
	_p.position.x = 200.0
	var base := _plataforma(Y_BAIXO, 90.0, Enums.COLOR.AMARELO)
	_plataforma(Y_CIMA, 40.0, Enums.COLOR.VERDE)
	_plataforma(Y_CIMA, 200.0, Enums.COLOR.AZUL)
	for semente in range(1, SEMENTES + 1):
		assert_eq(_pousar(base, semente), Enums.COLOR.VERDE, "so a VERDE dentro de [0, 180] e candidata")


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


func test_pouso_com_plataforma_atual_liberada_usa_fallback_livre() -> void:
	# Plataforma liberada (screen_exited) antes do pouso seguinte: comporta-se como actual_platform == null.
	_plataforma(Y_CIMA, 40.0, Enums.COLOR.AZUL)
	var vistas := {}
	for semente in range(1, SEMENTES + 1):
		# Atribuir objeto ja liberado a variavel tipada e recusado: o gecko guarda viva e ela e liberada depois.
		var base := _plataforma(Y_BAIXO, 90.0, Enums.COLOR.AMARELO)
		_p.actual_platform = base
		base.free()
		_p.rng = _rng(semente)
		_p.change_color_random()
		assert_null(_p.actual_platform, "a plataforma liberada vira null")
		assert_true(Enums.COLOR.values().has(_p.color), "cor valida")
		vistas[_p.color] = true
	assert_gt(vistas.size(), 1, "fallback livre: mais de uma cor (so a AZUL da linha de cima seria 1)")


func test_set_color_com_plataforma_atual_liberada_avisa_as_plataformas_vivas() -> void:
	var viva := _plataforma(Y_CIMA, 60.0, Enums.COLOR.AZUL)
	var base := _plataforma(Y_BAIXO, 90.0, Enums.COLOR.AMARELO)
	_p.actual_platform = base
	base.free()
	Global.cor_gecko = Enums.COLOR.AZUL
	assert_false(viva.shape.disabled, "a viva comeca com colisao ligada")
	_p.set_color(Enums.COLOR.VERDE)
	assert_eq(Global.cor_gecko, Enums.COLOR.VERDE, "Global.cor_gecko acompanha a cor nova")
	assert_true(viva.shape.disabled, "a viva (AZUL) de outra cor perde a colisao")


func test_pouso_na_fisica_com_plataforma_liberada_conclui_a_troca_de_cor() -> void:
	# Fio real: pousa pela fisica, entra em outra plataforma, ela e liberada e o proximo _physics_process troca a cor.
	Global.iniciado = true
	_plataforma(Y_BAIXO, 90.0, Enums.COR_INICIAL)
	_p.position = Vector2(90.0, Y_BAIXO - 60.0)
	_p.rng = _rng(3)
	_p.set_physics_process(true)
	await wait_physics_frames(90)
	assert_true(_p.is_on_floor(), "o gecko pousou")
	assert_false(_p.can_change_color, "o pouso inicial ja consumiu a troca")
	var outra := _plataforma(20.0, 150.0, Enums.COLOR.AMARELO)
	_p._on_DetectorPlataforma_body_entered(outra)
	assert_true(_p.can_change_color, "o detector liga a troca")
	outra.free()
	var sentinela := Enums.COLOR.AMARELO
	for cor in Enums.COLOR.values():
		if cor != _p.color:
			sentinela = cor
			break
	Global.cor_gecko = sentinela
	watch_signals(_p)
	await wait_physics_frames(2)
	assert_false(_p.can_change_color, "a troca terminou")
	assert_signal_emit_count(_p, "add_point", 1, "o pouso deu o ponto")
	assert_true(Enums.COLOR.values().has(_p.color), "cor valida")
	assert_eq(Global.cor_gecko, _p.color, "Global.cor_gecko acompanha a cor do gecko")


func test_linha_de_cima_so_com_a_cor_atual_mantem_a_cor() -> void:
	var base := _plataforma(Y_BAIXO, 90.0, Enums.COLOR.AMARELO)
	_plataforma(Y_CIMA, 60.0, Enums.COLOR.AZUL)
	_p.color = Enums.COLOR.AZUL
	for semente in range(1, SEMENTES + 1):
		assert_eq(_pousar(base, semente), Enums.COLOR.AZUL, "D4: repetir a cor atual e permitido, sem fallback")
