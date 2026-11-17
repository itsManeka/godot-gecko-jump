class_name CameraFollow
extends RefCounted

# Regra pura da camera que acompanha o gecko quando ele sobe (issue #46): o limite de topo e uma fracao
# da altura visivel e, por frame, o mundo avanca o quanto o gecko ultrapassou esse limite. Sem arvore de
# cena (padrao de InitialRows.gd): testavel direto; aplicado na cena por ScrollLevel/Stage (T2).

# Fracao da altura visivel que define o limite de topo (0,40 -> y = 128 com altura 320).
# Valor de sensacao: o dono confere no playtest e ajusta a constante.
const FRACAO_LIMITE := 0.40


# y do limite de topo para a altura visivel dada; gecko com y menor que o limite (mais alto) aciona o avanco
static func limite_y(altura_visivel: float) -> float:
	return altura_visivel * FRACAO_LIMITE


# Quanto o mundo avanca neste frame: 0 com o gecko no limite ou abaixo dele, positivo acima
# (inclui gecko acima do topo da tela, y negativo).
static func excesso(gecko_y: float, limite_y: float) -> float:
	return maxf(0.0, limite_y - gecko_y)
