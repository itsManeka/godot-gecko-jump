class_name TouchClassifier
extends RefCounted

# Lado do toque (sem cena, sem Input): metade da largura visivel; x == metade pertence a DIREITA (handoff 8.1).
# Usado pelo esquema B. O esquema antigo tap x segurar (limiar, multitoque) foi removido.

enum Lado { NENHUM, ESQUERDA, DIREITA }


static func lado_de(x: float, largura: float) -> Lado:
	return Lado.ESQUERDA if x < largura / 2.0 else Lado.DIREITA
