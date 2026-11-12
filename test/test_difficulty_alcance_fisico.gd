extends GutTest

# Alcancabilidade fisica por estagio e no teto da curva de dificuldade (f458, T13).
# Modelo fisico (nao e prova de pixel): espelha o pulo do Player.gd frame a frame, lendo as constantes do
# proprio script (SPEED, GRAVITY, JUMP_POWER) e a taxa de fisica do projeto; nada e copiado para ca.
#   pulo: velocity.y = JUMP_POWER; a cada frame velocity.y += GRAVITY e a posicao anda velocity.y / taxa.
#   vertical (C155): apice + ganho do scroll durante a subida >= InitialRows.ESPACAMENTO + MARGEM_VERTICAL.
#   horizontal (C156): tempo de voo T = frames ate o gecko descer ao nivel da linha-alvo (que desce com o scroll).
#     (a) tempo em que um ponto fica sem plataforma, (espacamento - largura) / speed, <= T;
#     (b) SPEED * T + largura da plataforma >= espacamento (a lacuna e coberta pelo deslocamento do gecko).
#   O literal "espacamento / speed <= T" reprova ja no estagio 0 (79 / 60 = 1,32 s > T): como o gecko pode esperar
#   na plataforma de partida, o que importa e o tempo sem plataforma sobre o ponto, tratado em (a).
# Estagios lidos do .tres de producao (inicio de cada estagio, instante logo antes do proximo = fim, e o teto).

const CURVA_PATH := "res://ressources/curva_dificuldade.tres"
const PLAYER_SCRIPT := "res://scenes/Player.gd"
const MARGEM_VERTICAL := 5.0
const EPS_PROGRESSO := 0.001


# Formula do 04-plan ("Espacamento"): 60.2995 + 0.3 * speed, arredondada para cima (espacamento(60) == 79).
func _espacamento(speed: float) -> float:
	return MovingRowFill.espacamento(speed)


func _taxa() -> float:
	return float(ProjectSettings.get_setting("physics/common/physics_ticks_per_second"))


func _player_const(nome: String) -> float:
	return float((load(PLAYER_SCRIPT) as GDScript).get_script_constant_map()[nome])


# Snapshots (rotulo, scroll, speed) de inicio e fim de cada estagio e do teto, avaliados pela curva de producao.
func _casos() -> Array:
	var curva := load(CURVA_PATH) as DifficultyCurve
	var casos: Array = []
	for i in range(curva.estagios.size()):
		var p_ini: float = curva.estagios[i].progresso_inicio
		casos.append(["E%d inicio" % i, curva.avaliar(p_ini * curva.pontos_plato, 0.0)])
		if i + 1 < curva.estagios.size():
			var p_fim: float = curva.estagios[i + 1].progresso_inicio - EPS_PROGRESSO
			casos.append(["E%d fim" % i, curva.avaliar(p_fim * curva.pontos_plato, 0.0)])
	casos.append(["teto", curva.avaliar(curva.pontos_plato, curva.segundos_plato)])
	return casos


# Subida: [apice em px, frames ate o apice]. Percorre o pulo do Player enquanto velocity.y < 0.
func _subida() -> Array:
	var vy := _player_const("JUMP_POWER")
	var g := _player_const("GRAVITY")
	var taxa := _taxa()
	var altura := 0.0
	var frames := 0
	while true:
		vy += g
		if vy >= 0.0:
			break
		altura += -vy / taxa
		frames += 1
	return [altura, frames]


# Tempo de voo: frames ate o gecko, na descida, alcancar o nivel da linha-alvo (ESPACAMENTO acima da partida,
# descendo `scroll` px/s). Devolve segundos; -1 se nao chega (pulo curto demais).
func _tempo_de_voo(scroll: float) -> float:
	var vy := _player_const("JUMP_POWER")
	var g := _player_const("GRAVITY")
	var taxa := _taxa()
	var y := 0.0
	var apice_passou := false
	for n in range(1, 2000):
		vy += g
		y += -vy / taxa
		if vy >= 0.0:
			apice_passou = true
		var alvo := InitialRows.ESPACAMENTO - scroll * float(n) / taxa
		if apice_passou and y <= alvo:
			return float(n) / taxa
	return -1.0


func test_vertical_apice_mais_scroll_cobre_espacamento_por_estagio_e_teto() -> void:
	var subida := _subida()
	var apice: float = subida[0]
	var t_subida: float = float(subida[1]) / _taxa()
	var casos := _casos()
	assert_eq(casos.size(), 8, "4 estagios: 3 inicios + 3 fins + inicio do teto + teto")
	for caso in casos:
		var snap: DifficultySnapshot = caso[1]
		var ganho := snap.get_scroll() * t_subida
		assert_gte(
			apice + ganho,
			InitialRows.ESPACAMENTO + MARGEM_VERTICAL,
			"%s: apice %.1f + scroll %.1f x %.3f s = %.1f deve cobrir %.0f + %.0f"
			% [caso[0], apice, snap.get_scroll(), t_subida, apice + ganho, InitialRows.ESPACAMENTO, MARGEM_VERTICAL]
		)


func test_horizontal_lacuna_coberta_no_tempo_de_voo_por_estagio_e_teto() -> void:
	var largura := MovingRowFill.SEMI_PLATAFORMA * 2.0
	var speed_gecko := _player_const("SPEED")
	var casos := _casos()
	assert_eq(casos.size(), 8, "4 estagios: 3 inicios + 3 fins + inicio do teto + teto")
	for caso in casos:
		var snap: DifficultySnapshot = caso[1]
		var speed := snap.get_speed_moveis()
		var esp := _espacamento(speed)
		var t_voo := _tempo_de_voo(snap.get_scroll())
		assert_gt(t_voo, 0.0, "%s: o gecko alcanca a linha-alvo na descida" % caso[0])
		assert_lte(
			(esp - largura) / speed,
			t_voo,
			"%s: tempo sem plataforma sobre um ponto %.3f s <= voo %.3f s" % [caso[0], (esp - largura) / speed, t_voo]
		)
		assert_gte(
			speed_gecko * t_voo + largura,
			esp,
			"%s: SPEED %.0f x %.3f s + largura %.0f cobre espacamento %.0f" % [caso[0], speed_gecko, t_voo, largura, esp]
		)
