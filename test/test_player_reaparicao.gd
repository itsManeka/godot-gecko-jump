extends GutTest
## f526 T4 - C649-C654: reposicionamento do gecko sobre a plataforma alvo da Segunda chance
## (Player.reaparecer_sobre) com Player e Platform reais. Q2: o reaparecimento nao e pouso.

var _nos: Array = []
var _pontos := 0
var _coletados: Array = []

func before_each() -> void:
	Global.cor_gecko = Enums.COR_INICIAL
	Global.cor_livre = false
	Global.sem_derrota = false
	Global.set_iniciado(false)
	_pontos = 0
	_coletados = []

func after_each() -> void:
	Input.action_release("jump")
	Global.set_iniciado(false)
	Global.cor_livre = false
	for no in _nos:
		if is_instance_valid(no):
			no.queue_free()
	_nos = []
	# queue_free so processa no fim do frame: a lista do Global nao pode levar os nos condenados ao teste seguinte
	Global.platforms.clear()

func _conectar_sinais(player) -> void:
	player.add_point.connect(_on_add_point)
	player.power_up_coletado.connect(_on_power_up_coletado)

func _on_add_point() -> void:
	_pontos += 1

func _on_power_up_coletado(tipo) -> void:
	_coletados.append(tipo)

func _player_novo(cor: Enums.COLOR):
	var player = load("res://scenes/Player.tscn").instantiate()
	player.color = cor
	player.rng = RandomNumberGenerator.new()
	player.rng.seed = 455
	add_child(player)
	_nos.append(player)
	return player

func _plataforma_da_cor(cor: Enums.COLOR, posicao: Vector2, power_up: StringName = &"") -> Platform:
	var plataforma: Platform = load("res://scenes/Platform.tscn").instantiate()
	plataforma.color = cor
	plataforma.position = posicao
	if power_up != &"":
		plataforma.definir_power_up(power_up)
	add_child(plataforma)
	_nos.append(plataforma)
	return plataforma

func _frames_fisicos(n: int) -> void:
	for i in range(n):
		await get_tree().physics_frame

# Base global do shape de colisao do gecko (retangulo centrado com rotation PI: o AABB e invariante a rotacao).
func _base_do_corpo(player) -> float:
	var forma: RectangleShape2D = player.collision.shape as RectangleShape2D
	return player.global_position.y + player.collision.position.y + forma.size.y / 2.0

# Topo global do shape de colisao da plataforma.
func _topo_do_shape(plataforma: Platform) -> float:
	var forma: RectangleShape2D = plataforma.shape.shape as RectangleShape2D
	return plataforma.global_position.y + plataforma.shape.position.y - forma.size.y / 2.0

func test_c649_apos_reposicionar_estado_do_gecko() -> void:
	var alvo := _plataforma_da_cor(Enums.COR_INICIAL, Vector2(90.0, 150.0))
	var player = _player_novo(Enums.COR_INICIAL)
	Global.set_iniciado(true)
	player.reaparecer_sobre(alvo, int(Enums.COR_INICIAL))
	assert_eq(player.velocity, Vector2.ZERO, "velocity zerada apos o reposicionamento")
	assert_true(absf(_base_do_corpo(player) - _topo_do_shape(alvo)) <= 0.01,
		"y no topo da plataforma (base do shape tocando o shape dela), sem interpenetrar")
	assert_eq(player.actual_platform, alvo, "actual_platform e a plataforma alvo")
	assert_false(player.is_end(), "is_end() falso: reposicionar nao e derrota")
	assert_true(player.on_ground, "estado de chao coerente: on_ground")
	assert_false(player.is_jumping(), "estado de chao coerente: nao pulando")

func test_c650_q2_reaparecimento_nao_e_pouso() -> void:
	var alvo := _plataforma_da_cor(Enums.COR_INICIAL, Vector2(90.0, 150.0), &"camaleao")
	var player = _player_novo(Enums.COR_INICIAL)
	Global.set_iniciado(true)
	_conectar_sinais(player)
	player.reaparecer_sobre(alvo, int(Enums.COR_INICIAL))
	# 6 frames fisicos: o body_entered do DetectorPlataforma rearma can_change_color no frame seguinte ao
	# teleporte; a guarda propria do reaparecimento e o que segura o bloco de pouso.
	await _frames_fisicos(6)
	assert_true(player.can_change_color,
		"o body_entered do DetectorPlataforma rearma can_change_color: so a guarda segura o pouso")
	assert_true(player.is_on_floor(), "o gecko esta no chao da alvo: as condicoes de pouso estao todas presentes")
	assert_eq(_pontos, 0, "sem add_point apos os frames fisicos: o reaparecimento nao e pouso")
	assert_eq(_coletados.size(), 0, "sem coleta do power-up da plataforma alvo")
	assert_eq(alvo.tipo_power_up, &"camaleao", "o power-up da alvo segue la (notificar_pouso nao rodou)")
	assert_eq(int(player.color), int(Enums.COR_INICIAL), "a cor do gecko fica intacta (sem change_color_random)")
	assert_eq(int(Global.cor_gecko), int(Enums.COR_INICIAL), "Global.cor_gecko fica intacta")

func test_c651_guarda_cai_no_proximo_pulo_o_pouso_seguinte_e_normal() -> void:
	var alvo := _plataforma_da_cor(Enums.COR_INICIAL, Vector2(90.0, 150.0), &"camaleao")
	var player = _player_novo(Enums.COR_INICIAL)
	Global.set_iniciado(true)
	_conectar_sinais(player)
	player.reaparecer_sobre(alvo, int(Enums.COR_INICIAL))
	await _frames_fisicos(3)
	assert_eq(_pontos, 0, "antes do pulo nada pontua (guarda ativa)")
	Input.action_press("jump")
	await _frames_fisicos(3)
	assert_true(player.is_jumping(), "o jogador pulou da alvo (velocity.y < 0)")
	Input.action_release("jump")
	await _frames_fisicos(70)
	# A ordem do bloco de pouso e notificar_pouso -> change_color_random -> add_point: com add_point emitido,
	# o sorteio de cor rodou no mesmo bloco (o pouso seguinte sorteia cor normalmente).
	assert_eq(_pontos, 1, "o pouso seguinte pontua normalmente (a guarda caiu no pulo)")
	assert_eq(_coletados.size(), 1, "o pouso seguinte coleta o power-up da plataforma")
	assert_eq(_coletados[0], &"camaleao", "coletou o tipo da alvo")
	assert_eq(alvo.tipo_power_up, &"", "o power-up foi consumido pelo pouso real")

func test_c652_fallback_assume_a_cor_da_plataforma() -> void:
	# O cenario so exige duas cores distintas do registro: a cor inicial do gecko e a primeira diferente dela.
	var cor_do_gecko: int = int(Enums.COR_INICIAL)
	var cor_da_alvo: int = -1
	for valor in Enums.COLOR.values():
		if int(valor) != cor_do_gecko:
			cor_da_alvo = int(valor)
			break
	assert_ne(cor_da_alvo, -1, "o registro precisa de ao menos uma cor distinta da inicial para o fallback")
	var alvo := _plataforma_da_cor(cor_da_alvo as Enums.COLOR, Vector2(90.0, 150.0))
	var outra := _plataforma_da_cor(cor_do_gecko as Enums.COLOR, Vector2(60.0, 60.0))
	var player = _player_novo(Enums.COR_INICIAL)
	Global.set_iniciado(true)
	# Estado pre-reposicionamento realista: o gecko caiu da plataforma da cor dele (outra); a alvo, de outra
	# cor, e atravessavel para a cor vigente.
	Global.player_color_changed(cor_do_gecko, outra)
	assert_true(alvo.shape.disabled, "antes do fallback a alvo (outra cor) e atravessavel")
	player.reaparecer_sobre(alvo, cor_da_alvo)
	assert_eq(int(player.color), cor_da_alvo, "fallback: o gecko assume a cor da plataforma")
	assert_eq(int(Global.cor_gecko), cor_da_alvo, "Global.cor_gecko vira a cor da plataforma")
	assert_false(alvo.shape.disabled, "a plataforma da cor assumida fica solida")
	assert_true(outra.shape.disabled, "plataformas de outras cores ficam atravessaveis")
	player.reaparecer_sobre(alvo, cor_da_alvo)
	assert_eq(int(player.color), cor_da_alvo, "com a cor ja igual, a cor nao muda")
	assert_eq(int(Global.cor_gecko), cor_da_alvo, "Global.cor_gecko segue a cor assumida")
	assert_false(alvo.shape.disabled, "com a cor ja igual a colisao da alvo segue valida")
	assert_true(outra.shape.disabled, "outras cores seguem atravessaveis com a cor ja igual")

func test_c653_camaleao_ativo_cor_livre_nao_e_zerada() -> void:
	var cor_do_gecko: int = int(Enums.COR_INICIAL)
	var cor_outra: int = -1
	for valor in Enums.COLOR.values():
		if int(valor) != cor_do_gecko:
			cor_outra = int(valor)
			break
	assert_ne(cor_outra, -1, "o cenario precisa de uma segunda cor para provar a regra de cor livre")
	var alvo := _plataforma_da_cor(Enums.COR_INICIAL, Vector2(90.0, 150.0))
	var outra := _plataforma_da_cor(cor_outra as Enums.COLOR, Vector2(60.0, 60.0))
	var player = _player_novo(Enums.COR_INICIAL)
	Global.set_iniciado(true)
	# Sem cor livre a plataforma de outra cor e atravessavel; o reposicionamento com o Camaleao ativo
	# reavalia a colisao sob a regra de cor livre (e nunca zera a flag).
	Global.player_color_changed(Enums.COR_INICIAL, alvo)
	assert_true(outra.shape.disabled, "sem cor livre a plataforma de outra cor e atravessavel")
	Global.cor_livre = true
	player.reaparecer_sobre(alvo, int(Enums.COR_INICIAL))
	assert_true(Global.cor_livre, "o reposicionamento nao zera Global.cor_livre (Camaleao segue ativo)")
	assert_false(alvo.shape.disabled, "cor livre: a alvo e solida")
	assert_false(outra.shape.disabled,
		"cor livre: plataforma de outra cor tambem colide (a regra de cor livre segue valendo)")
	await _frames_fisicos(3)
	assert_true(Global.cor_livre, "cor livre segue ativo apos frames fisicos")

func test_c654_plataforma_movel_e_scroll_o_gecko_acompanha() -> void:
	var alvo := _plataforma_da_cor(Enums.COR_INICIAL, Vector2(90.0, 150.0))
	alvo.set_speed(60)
	var player = _player_novo(Enums.COR_INICIAL)
	Global.set_iniciado(true)
	player.reaparecer_sobre(alvo, int(Enums.COR_INICIAL))
	# O scroll do estagio 0 (20 px/s) descendo a alvo frame a frame, com ela movel em x (speed 60):
	# como em qualquer pouso, a gravidade cola o gecko no topo enquanto a plataforma desce e anda.
	var scroll_por_frame := 20.0 / 60.0
	for i in range(8):
		alvo.position.y += scroll_por_frame
		await get_tree().physics_frame
	assert_true(player.is_on_floor(), "o gecko acompanha a plataforma que desce, sem cair no frame seguinte")
	assert_true(absf(_base_do_corpo(player) - _topo_do_shape(alvo)) <= 1.5,
		"a base do corpo segue encostada no topo da plataforma que desce")
