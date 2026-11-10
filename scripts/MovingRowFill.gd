class_name MovingRowFill
extends RefCounted

# Regra pura do preenchimento inicial de uma linha movel: fonte unica do espacamento (ESPACAMENTO), da largura padrao
# (180) e da semi-largura da plataforma (30). Sem arvore de cena: testavel direto.
# ESPACAMENTO = 79 px: area_exited do CheckGenerate (distancia entre centros > 60.2995 px, a 1 px/tick a 60 Hz =
# ~61 ticks) + 0.3 s do timer (18 px). Medido em jogo por test/test_running_platforms_fill.gd (+/- 2 px).

const ESPACAMENTO := 79.0
const LARGURA_PADRAO := 180.0
const SEMI_PLATAFORMA := 30.0


# Devolve os x pre-colocados da linha, do mais proximo do ponto de nascimento ao mais distante. Anda a esquerda
# (toward_left) ou a direita a partir de spawn_x em passos de ESPACAMENTO, excluindo o proprio spawn_x, e so mantem
# x com -SEMI_PLATAFORMA < x < largura + SEMI_PLATAFORMA (limite exclusivo). Largura 0 ou pequena devolve so o que cabe.
static func initial_xs(spawn_x: float, toward_left: bool, largura: float = LARGURA_PADRAO) -> Array[float]:
	var xs: Array[float] = []
	var passo: float = -ESPACAMENTO if toward_left else ESPACAMENTO
	var limite_longe: float = -SEMI_PLATAFORMA if toward_left else largura + SEMI_PLATAFORMA
	var x: float = spawn_x + passo
	while (toward_left and x > limite_longe) or (not toward_left and x < limite_longe):
		if x > -SEMI_PLATAFORMA and x < largura + SEMI_PLATAFORMA:
			xs.append(x)
		x += passo
	return xs
