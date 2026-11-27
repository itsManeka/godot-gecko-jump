class_name NevoaRegra
extends RefCounted

# Regra pura da nevoa reativa na base (f559 T8, direcao-de-arte.md 4.3): altura (px) e opacidade (0..1) da nevoa e o
# fator de velocidade do deslize, sem cena. Tres regimes:
# - menu (partida nao iniciada): discreta, 28 px / 0.35;
# - zona segura (y <= H - 176): 32 px / 0.45;
# - aproximacao (H - 176 .. H - 32): p = clamp((y - (H - 176)) / 144, 0, 1) sobe linear de 32 a 64 px e de 0.45 a 0.85.
# A zona segura e a aproximacao com p = 0, entao uma formula so cobre as duas.

const ALTURA_MENU: float = 28.0
const OPACIDADE_MENU: float = 0.35
const ALTURA_SEGURA: float = 32.0
const OPACIDADE_SEGURA: float = 0.45
const ALTURA_MAXIMA: float = 64.0
const OPACIDADE_MAXIMA: float = 0.85
# Distancia da borda inferior onde a aproximacao comeca e largura da faixa de aproximacao (px)
const INICIO_APROXIMACAO: float = 176.0
const FAIXA_APROXIMACAO: float = 144.0
# "Ondulacao +40%" da direcao de arte = deslize 1.4x, so com p acima deste limite
const LIMITE_PERIGO_RAPIDO: float = 0.5
const FATOR_RAPIDO: float = 1.4


# Fator de perigo 0..1 pelo y do gecko e a altura visivel da tela; y fora da faixa clampa
static func perigo(y: float, altura_tela: float) -> float:
	return clampf((y - (altura_tela - INICIO_APROXIMACAO)) / FAIXA_APROXIMACAO, 0.0, 1.0)


static func altura(em_partida: bool, y: float, altura_tela: float) -> float:
	if not em_partida:
		return ALTURA_MENU
	return lerpf(ALTURA_SEGURA, ALTURA_MAXIMA, perigo(y, altura_tela))


static func opacidade(em_partida: bool, y: float, altura_tela: float) -> float:
	if not em_partida:
		return OPACIDADE_MENU
	return lerpf(OPACIDADE_SEGURA, OPACIDADE_MAXIMA, perigo(y, altura_tela))


# Multiplicador da velocidade de deslize: 1.4 so com p > 0.5 (estritamente)
static func fator_velocidade(p: float) -> float:
	return FATOR_RAPIDO if p > LIMITE_PERIGO_RAPIDO else 1.0
