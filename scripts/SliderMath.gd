class_name SliderMath
extends RefCounted

# Matematica pura do slider de volume da tela de Opcoes (handoff 10.2 e 10.3), sem cena.
# Valor inteiro de 0 a 100; a trilha vai de x = 16 a x = 164 (148 de largura).

const X_MIN: float = 16.0
const LARGURA_TRILHA: float = 148.0
const VALOR_MAX: int = 100
const PASSO: int = 5


# Posicao horizontal do dedo -> valor 0-100 (x limitado a [16, 164]).
static func valor_de_x(x: float) -> int:
	return roundi(clampf((x - X_MIN) / LARGURA_TRILHA, 0.0, 1.0) * VALOR_MAX)


# Centro do cursor para um valor 0-100.
static func x_do_valor(valor: int) -> float:
	return X_MIN + LARGURA_TRILHA * float(clampi(valor, 0, VALOR_MAX)) / VALOR_MAX


# Passo de teclado: direcao -1 ou +1, de 5 em 5, limitado a 0 e 100.
static func passo(valor: int, direcao: int) -> int:
	return clampi(valor + direcao * PASSO, 0, VALOR_MAX)


# Texto do valor: "mudo" em 0 e "N%" nos demais.
static func rotulo(valor: int) -> String:
	if valor <= 0:
		return "mudo"
	return "%d%%" % valor
