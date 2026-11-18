class_name MovingRowFill
extends RefCounted

# Regra pura do preenchimento inicial de uma linha movel: fonte unica do espacamento (espacamento(speed)), da largura
# padrao (180) e da semi-largura da plataforma (30). Sem arvore de cena: testavel direto.
# espacamento(speed): area_exited do CheckGenerate dispara no 1o tick com distancia entre centros > 60.2995 px
# (independe da speed; a speed/60 px por tick) + 0.3 s do timer (18 ticks), tudo andando a speed px/s:
# (ceil(60.2995 / (speed / 60)) + 18) * speed / 60 ~ 60.2995 + 0.3 * speed + ate 1 tick. Em speed 60: 61 + 18 = 79 px
# (valor medido). Medido em jogo por test/test_running_platforms_fill.gd (+/- 2 px) em 60, 86 e 100 (o timer tem
# jitter de ~1 tick contra a fisica, ate 1,7 px a speed 100).

const DISTANCIA_SAIDA := 60.2995
const TEMPO_TIMER := 0.3
const TAXA_FISICA := 60.0
const SPEED_PADRAO: float = DifficultyStage.SPEED_PADRAO # speed do estagio 0 (ressources/curva_dificuldade.tres)
const LARGURA_PADRAO := PlayArea.LARGURA
const SEMI_PLATAFORMA := 30.0


# Distancia entre plataformas consecutivas de uma linha movel que anda a `speed` px/s.
static func espacamento(speed: float) -> float:
	var px_por_tick: float = absf(speed) / TAXA_FISICA
	if px_por_tick <= 0.0:
		return INF
	var ticks_saida: float = ceilf(DISTANCIA_SAIDA / px_por_tick)
	return (ticks_saida + TEMPO_TIMER * TAXA_FISICA) * px_por_tick


# Devolve os x pre-colocados da linha, do mais proximo do ponto de nascimento ao mais distante. Anda a esquerda
# (toward_left) ou a direita a partir de spawn_x em passos de espacamento(speed), excluindo o proprio spawn_x, e so
# mantem x com -SEMI_PLATAFORMA < x < largura + SEMI_PLATAFORMA (limite exclusivo). Largura 0 ou pequena devolve so o
# que cabe. Sem `speed` = estagio 0.
static func initial_xs(spawn_x: float, toward_left: bool, largura: float = LARGURA_PADRAO, speed: float = SPEED_PADRAO) -> Array[float]:
	var xs: Array[float] = []
	var esp: float = espacamento(speed)
	var passo: float = -esp if toward_left else esp
	var limite_longe: float = -SEMI_PLATAFORMA if toward_left else largura + SEMI_PLATAFORMA
	var x: float = spawn_x + passo
	while (toward_left and x > limite_longe) or (not toward_left and x < limite_longe):
		if x > -SEMI_PLATAFORMA and x < largura + SEMI_PLATAFORMA:
			xs.append(x)
		x += passo
	return xs
