class_name InitialRows
extends RefCounted

# Regra pura das linhas iniciais do gerador: fonte unica do espacamento vertical (50 px) e do y do topo (-10).
# Sem arvore de cena: testavel direto. Linhas em Y_TOPO + ESPACAMENTO * i enquanto y < altura.

const ESPACAMENTO := 50.0
const Y_TOPO := -10.0


# Devolve os y das linhas que cobrem a altura visivel: a primeira em Y_TOPO, passo ESPACAMENTO, limite estrito y < altura.
# Altura <= Y_TOPO devolve vazio; altura entre Y_TOPO e Y_TOPO + ESPACAMENTO devolve so o topo.
static func initial_row_ys(altura: float) -> Array[float]:
	var ys: Array[float] = []
	var y: float = Y_TOPO
	while y < altura:
		ys.append(y)
		y += ESPACAMENTO
	return ys
