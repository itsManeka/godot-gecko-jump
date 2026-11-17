extends GutTest

# T3 (f493): TouchControls delega ao esquema do modo (contrato TouchScheme) e traduz a intencao em acoes de input.
# Os esquemas reais A/B/C chegam nas T4-T6; aqui um esquema falso do contrato (injetado por `fabrica_esquema`) prova a
# camada: troca de modo, zona morta, posse de acao, inercia fora de partida, pulso de jump e arrasto desconhecido.
# Valores esperados vem da regra do 01 (pulso de 2 ticks), nunca da saida da implementacao.

const CONTROLS := preload("res://scenes/TouchControls.gd")
const TICK := 1.0 / 60.0
const ESQ := 20.0
const DIR := 160.0
const ACOES := ["ui_left", "ui_right", "jump"]
const MODOS := [TouchMode.Modo.A, TouchMode.Modo.B]
const PULSO_ESPERADO: int = 2

var _c: Node
var _t: int = 0
var _esquemas: Array = []
var _modo_anterior: int = TouchMode.Modo.B


# Esquema falso do contrato: dedo na metade esquerda = esquerda, na direita = direita; todo press pede 1 pulo (evento).
class EsquemaFalso:
	extends TouchScheme
	var lados: Dictionary = {}
	var pulo_pendente: bool = false
	var movimentos: int = 0

	func _ao_pressionar(dedo: int, _t_ms: int, pos: Vector2) -> void:
		lados[dedo] = -1 if pos.x < largura_visivel / 2.0 else 1
		pulo_pendente = true

	func _ao_mover(_dedo: int, _pos: Vector2, _t_ms: int) -> void:
		movimentos += 1

	func _ao_soltar(dedo: int, _t_ms: int) -> void:
		lados.erase(dedo)

	func _ao_cancelar(dedo: int) -> void:
		lados.erase(dedo)

	func _ao_cancelar_tudo() -> void:
		lados.clear()
		pulo_pendente = false

	func _intencao(_t_ms: int) -> Dictionary:
		var r: Dictionary = TouchScheme.intencao_neutra()
		r["esquerda"] = lados.values().has(-1)
		r["direita"] = lados.values().has(1)
		r["pulo"] = pulo_pendente
		pulo_pendente = false
		return r


class JogadorFalso:
	extends Node
	var fim: bool = false

	func is_end() -> bool:
		return fim


func before_each() -> void:
	_modo_anterior = Global.get_touch_mode()
	Global.iniciado = true
	_t = 0
	_esquemas = []


func after_each() -> void:
	for a in ACOES:
		Input.action_release(a)
	Global.iniciado = false
	Global.set_touch_mode(_modo_anterior, false)


func _spawn(modo: int) -> void:
	Global.set_touch_mode(modo, false)
	_c = CONTROLS.new()
	_c.relogio = func() -> int: return _t
	_c.largura_visivel_fixa = 180.0
	_c.fabrica_esquema = func(_m: int) -> TouchScheme:
		var e := EsquemaFalso.new()
		_esquemas.append(e)
		return e
	_c.set_physics_process(false)
	add_child_autofree(_c)
	_c._sincronizar_modo()


func _limpar() -> void:
	if is_instance_valid(_c):
		_c.free()
	for a in ACOES:
		Input.action_release(a)


func _tick() -> void:
	_c._physics_process(TICK)


func _toque(x: float, pressed: bool, idx: int = 0, y: float = 200.0) -> void:
	var e := InputEventScreenTouch.new()
	e.index = idx
	e.position = Vector2(x, y)
	e.pressed = pressed
	_c._input(e)


func _arrasto(x: float, y: float, idx: int) -> void:
	var e := InputEventScreenDrag.new()
	e.index = idx
	e.position = Vector2(x, y)
	_c._input(e)


func _nenhuma_pressionada() -> bool:
	for a in ACOES:
		if Input.is_action_pressed(a):
			return false
	return true


func test_c377_trocar_de_modo_com_dedo_apoiado_solta_as_tres_acoes() -> void:
	for de in MODOS:
		for para in MODOS:
			if de == para:
				continue
			var rotulo := "%s -> %s" % [TouchMode.nome(de), TouchMode.nome(para)]
			_spawn(de)
			_toque(ESQ, true, 0)
			_toque(DIR, true, 1)
			assert_true(Input.is_action_pressed("ui_left"), "%s: pre-condicao ui_left" % rotulo)
			assert_true(Input.is_action_pressed("ui_right"), "%s: pre-condicao ui_right" % rotulo)
			assert_true(Input.is_action_pressed("jump"), "%s: pre-condicao jump" % rotulo)
			Global.set_touch_mode(para, false)
			assert_true(_nenhuma_pressionada(), "%s: a troca solta ui_left, ui_right e jump na hora" % rotulo)
			assert_eq(_esquemas.size(), 2, "%s: o esquema do novo modo foi criado" % rotulo)
			assert_false(_esquemas[1].ativo(), "%s: o novo esquema nasce sem dedo" % rotulo)
			_tick()
			_tick()
			assert_true(_nenhuma_pressionada(), "%s: sem residual nos ticks seguintes" % rotulo)
			_limpar()
			_esquemas = []


func test_c378_dedo_em_zona_morta_nao_gera_acao_em_a_b_e_c() -> void:
	var morta := Rect2(0.0, 0.0, 40.0, 40.0)
	for modo in MODOS:
		var rotulo := "modo %s" % TouchMode.nome(modo)
		_spawn(modo)
		var mortas: Array[Rect2] = [morta]
		_c.zonas_mortas = mortas
		_toque(10.0, true, 0, 10.0)
		_tick()
		assert_true(_nenhuma_pressionada(), "%s: dedo na zona morta nao pressiona nada" % rotulo)
		assert_false(_esquemas[0].ativo(), "%s: o esquema nem registra o dedo" % rotulo)
		_toque(10.0, false, 0, 10.0)
		_toque(DIR, true, 1)
		assert_true(Input.is_action_pressed("ui_right"), "%s: controle: fora da zona o mesmo esquema pressiona" % rotulo)
		_toque(DIR, false, 1)
		# A zona morta vale tambem para o esquema criado depois de uma troca de modo.
		Global.set_touch_mode(TouchMode.Modo.B if modo != TouchMode.Modo.B else TouchMode.Modo.A, false)
		_toque(10.0, true, 2, 10.0)
		assert_true(_nenhuma_pressionada(), "%s: apos trocar de modo a zona morta segue valendo" % rotulo)
		_limpar()
		_esquemas = []


func test_c379_acao_de_teclado_pressionada_antes_nao_e_assumida_nem_solta() -> void:
	for modo in MODOS:
		var rotulo := "modo %s" % TouchMode.nome(modo)
		_spawn(modo)
		Input.action_press("ui_left")
		Input.action_press("jump")
		_toque(ESQ, true, 0)
		for i in 4:
			_tick()
		assert_false(_c._pressionadas.has("ui_left"), "%s: ui_left do teclado nao entra na posse da camada" % rotulo)
		assert_false(_c._pressionadas.has("jump"), "%s: jump do teclado nao entra na posse da camada" % rotulo)
		_toque(ESQ, false, 0)
		for i in 4:
			_tick()
		assert_true(Input.is_action_pressed("ui_left"), "%s: soltar o dedo nao solta ui_left do teclado" % rotulo)
		assert_true(Input.is_action_pressed("jump"), "%s: soltar o dedo nao solta jump do teclado" % rotulo)
		_toque(DIR, true, 1)
		assert_true(Input.is_action_pressed("ui_right"), "%s: controle: acao livre e pressionada pela camada" % rotulo)
		_toque(DIR, false, 1)
		assert_false(Input.is_action_pressed("ui_right"), "%s: controle: e solta ao soltar o dedo" % rotulo)
		_limpar()
		_esquemas = []


func test_c380_fora_de_partida_nenhum_modo_pressiona_e_derrota_e_cancelar_tudo_soltam() -> void:
	var jogador: JogadorFalso = autofree(JogadorFalso.new())
	for modo in MODOS:
		var rotulo := "modo %s" % TouchMode.nome(modo)
		_spawn(modo)
		_c.player = jogador
		jogador.fim = false
		Global.iniciado = false
		_toque(ESQ, true, 0)
		_toque(DIR, true, 1)
		_arrasto(ESQ, 150.0, 0)
		_tick()
		assert_true(_nenhuma_pressionada(), "%s: fora de partida (toque que inicia no menu) nada e pressionado" % rotulo)
		assert_false(_esquemas[0].ativo(), "%s: fora de partida o esquema nao recebe o dedo" % rotulo)
		Global.iniciado = true
		_toque(ESQ, true, 0)
		assert_true(Input.is_action_pressed("ui_left"), "%s: controle: em partida pressiona" % rotulo)
		jogador.fim = true
		_tick()
		assert_true(_nenhuma_pressionada(), "%s: derrota solta tudo" % rotulo)
		assert_false(_esquemas[0].ativo(), "%s: derrota cancela o gesto no esquema" % rotulo)
		jogador.fim = false
		_toque(DIR, true, 3)
		assert_true(Input.is_action_pressed("ui_right"), "%s: pre-condicao do cancelar_tudo" % rotulo)
		_c.cancelar_tudo()
		assert_true(_nenhuma_pressionada(), "%s: cancelar_tudo solta tudo" % rotulo)
		assert_false(_esquemas[0].ativo(), "%s: cancelar_tudo cancela o gesto no esquema" % rotulo)
		_limpar()
		_esquemas = []


func test_c381_jump_e_pulso_de_ticks_minimos_e_nao_repula_ao_segurar() -> void:
	for modo in MODOS:
		var rotulo := "modo %s" % TouchMode.nome(modo)
		_spawn(modo)
		_toque(ESQ, true, 0)
		var amostras: Array = [Input.is_action_pressed("jump")]
		for i in 9:
			_tick()
			amostras.append(Input.is_action_pressed("jump"))
		var pressionadas: int = amostras.count(true)
		assert_eq(pressionadas, PULSO_ESPERADO, "%s: jump fica %d amostras (pulso de 2 ticks): %s" % [rotulo, PULSO_ESPERADO, amostras])
		assert_true(amostras[0] and amostras[1], "%s: o pulso cobre as 2 primeiras amostras" % rotulo)
		assert_true(Input.is_action_pressed("ui_left"), "%s: o lateral segue enquanto o dedo segura" % rotulo)
		_toque(DIR, true, 1)
		assert_true(Input.is_action_pressed("jump"), "%s: novo pedido de pulo gera novo pulso" % rotulo)
		_limpar()
		_esquemas = []


func test_c383_arrasto_de_index_desconhecido_ou_sem_press_previo_e_ignorado() -> void:
	for modo in MODOS:
		var rotulo := "modo %s" % TouchMode.nome(modo)
		_spawn(modo)
		_arrasto(100.0, 100.0, 7)
		assert_eq(_esquemas[0].movimentos, 0, "%s: arrasto sem press previo nao chega ao esquema" % rotulo)
		_toque(ESQ, true, 0)
		_arrasto(100.0, 100.0, 7)
		assert_eq(_esquemas[0].movimentos, 0, "%s: index desconhecido nao chega ao esquema" % rotulo)
		_arrasto(30.0, 150.0, 0)
		assert_eq(_esquemas[0].movimentos, 1, "%s: controle: o index apoiado chega" % rotulo)
		_toque(ESQ, false, 0)
		_arrasto(30.0, 150.0, 0)
		assert_eq(_esquemas[0].movimentos, 1, "%s: arrasto depois de soltar e ignorado" % rotulo)
		_limpar()
		_esquemas = []


func test_fabrica_de_esquemas_so_entrega_o_que_esta_implementado() -> void:
	for modo in MODOS:
		var esquema: TouchScheme = TouchSchemes.criar(modo)
		assert_eq(esquema != null, TouchSchemes.implementado(modo), "modo %s: null = esquema legado" % TouchMode.nome(modo))
	assert_true(TouchSchemeA.new() is TouchScheme, "A cumpre o contrato")
	assert_true(TouchSchemeB.new() is TouchScheme, "B cumpre o contrato")
