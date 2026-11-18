extends GutTest

# ReachableColors.tempo_de_pulo contra a simulacao frame a frame da fisica do Player (GRAVITY/JUMP_POWER lidos do
# Player, nenhum literal de fisica aqui). A simulacao usa a forma fechada da subida (soma de PA), independente do laco do
# preditor: no frame n a velocidade vertical e JUMP_POWER + GRAVITY*n (a gravidade soma antes do move_and_slide) e a
# altura acumulada e a soma dos deslocamentos de cada frame. A linha de cima desce `scroll` px/s.
# Tolerancia declarada: 1 physics frame.

const PlayerFisica := preload("res://scenes/Player.gd")
const CURVA_PATH := "res://ressources/curva_dificuldade.tres"
const FRAMES_MAXIMOS := 1200
const EPS_FLOAT := 0.000001


func _tolerancia() -> float:
	return 1.0 / float(Engine.physics_ticks_per_second) + EPS_FLOAT


# Altura (px acima do ponto do pulo) do gecko no frame n.
func _altura_no_frame(n: int) -> float:
	var taxa: float = float(Engine.physics_ticks_per_second)
	var soma_velocidades: float = float(PlayerFisica.JUMP_POWER) * n + float(PlayerFisica.GRAVITY) * n * (n + 1) / 2.0
	return -soma_velocidades / taxa


# Primeiro frame em que o gecko alcanca a linha de cima (a ESPACAMENTO acima, descendo `scroll` px/s); em segundos.
func _tempo_simulado(scroll: float) -> float:
	var taxa: float = float(Engine.physics_ticks_per_second)
	for n in range(1, FRAMES_MAXIMOS + 1):
		var linha_acima: float = InitialRows.ESPACAMENTO - maxf(scroll, 0.0) * float(n) / taxa
		if _altura_no_frame(n) >= linha_acima:
			return float(n) / taxa
	return -1.0


func _scrolls_da_curva() -> Array:
	var curva := load(CURVA_PATH) as DifficultyCurve
	var inicio: float = curva.avaliar(0.0, 0.0).get_scroll()
	var meio: float = curva.avaliar(curva.estagios[1].progresso_inicio * curva.pontos_plato, 0.0).get_scroll()
	var teto: float = curva.avaliar(curva.pontos_plato, curva.segundos_plato).get_scroll()
	return [["inicio", inicio], ["meio", meio], ["teto", teto]]


func test_c263_tempo_de_pulo_bate_com_a_simulacao_frame_a_frame_em_varios_scrolls() -> void:
	var casos: Array = [["scroll zero", 0.0]]
	casos.append_array(_scrolls_da_curva())
	var falhas: Array = []
	for caso in casos:
		var scroll: float = caso[1]
		var simulado: float = _tempo_simulado(scroll)
		var previsto: float = ReachableColors.tempo_de_pulo(scroll)
		assert_gt(simulado, 0.0, "%s: a simulacao alcanca a linha de cima" % caso[0])
		if absf(previsto - simulado) > _tolerancia():
			falhas.append("%s scroll=%.1f previsto=%.4f simulado=%.4f" % [caso[0], scroll, previsto, simulado])
	assert_eq(falhas, [], "tempo_de_pulo dentro de 1 physics frame da simulacao")


func test_tempo_de_pulo_scroll_maior_alcanca_a_linha_antes() -> void:
	var scrolls: Array = _scrolls_da_curva()
	var anterior: float = ReachableColors.tempo_de_pulo(0.0)
	for caso in scrolls:
		var t: float = ReachableColors.tempo_de_pulo(caso[1])
		assert_lt(t, anterior + EPS_FLOAT, "%s: mais scroll nao demora mais para alcancar a linha" % caso[0])
		assert_gt(t, 0.0, "%s: tempo positivo" % caso[0])
		anterior = t


func test_tempo_de_pulo_scroll_negativo_vale_como_zero() -> void:
	assert_eq(ReachableColors.tempo_de_pulo(-30.0), ReachableColors.tempo_de_pulo(0.0), "scroll negativo = parado")
