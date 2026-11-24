class_name CameraFollow
extends RefCounted

# Regra pura da camera que acompanha o gecko quando ele sobe (issue #46): o limite de topo e uma fracao
# da altura visivel. O mundo avanca o quanto o gecko ultrapassou esse limite, suavizado: por frame aplica-se
# uma parcela do que resta (easing, issue #49), ate o gecko convergir ao limite. Sem arvore de
# cena (padrao de InitialRows.gd): testavel direto; aplicado na cena por ScrollLevel/Stage.

# Fracao da altura visivel que define o limite de topo (0,40 -> y = 128 com altura 320).
# Valor de sensacao: o dono confere no playtest e ajusta a constante.
const FRACAO_LIMITE := 0.40

# Frames em que o excesso e distribuido (easing do avanco da camera, issue #49): cada frame aplica
# 1/DURACAO_FRAMES do que resta. Valor de sensacao: o dono confere no playtest e ajusta a constante.
const DURACAO_FRAMES := 4

# Piso da parcela por frame, em px logicos: so garante que a sequencia termina (sem cauda infinita).
const PASSO_MINIMO_PX := 1.0

# Excesso abaixo disso e ruido de ponto flutuante, nao subida do gecko: o limite e double e global_position.y e float32,
# entao o gecko parado no limite pode ficar ate meio ulp (float32 em y ~100-200: ate ~8e-6 px) acima do limite e a camera
# acumularia esse residuo em position_scrolled a cada frame. Bem abaixo de 1 px, invisivel na tela de 180x320.
const EXCESSO_MINIMO_PX := 0.001


# y do limite de topo para a altura visivel dada; gecko com y menor que o limite (mais alto) aciona o avanco
static func limite_y(altura_visivel: float) -> float:
	return altura_visivel * FRACAO_LIMITE


# Quanto o mundo avanca neste frame: 0 com o gecko no limite ou abaixo dele, positivo acima
# (inclui gecko acima do topo da tela, y negativo).
static func excesso(gecko_y: float, limite_y: float) -> float:
	return maxf(0.0, limite_y - gecko_y)


# Parcela do excesso restante a aplicar neste frame: nunca maior que o restante, 0 sem excesso; a fracao
# 1/DURACAO_FRAMES tem piso PASSO_MINIMO_PX e a ultima parcela fecha o resto exato.
static func parcela(excesso_restante: float) -> float:
	if excesso_restante <= 0.0:
		return 0.0
	return minf(excesso_restante, maxf(excesso_restante / float(DURACAO_FRAMES), PASSO_MINIMO_PX))
