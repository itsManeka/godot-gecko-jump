class_name TouchTuning
extends RefCounted

# Valores numericos dos esquemas de toque (hipotese do Q5 da f493, provisorios ate o playtest do dono).
# Cada valor tem UMA definicao aqui; trocar e editar uma linha. Os esquemas A/B e os testes leem so por este simbolo.

# Deslocamento horizontal (px logicos) a partir do ponto de contato abaixo do qual o dedo esta "parado".
const ZONA_MORTA_PX: float = 6.0
# Flick para cima: deslocamento vertical minimo (px logicos) dentro da janela abaixo.
const FLICK_DY_MIN_PX: float = 24.0
const FLICK_JANELA_MS: int = 150
# Rearme do flick no modo A: depois de um flick o proximo so vale quando o dedo parou (velocidade vertical media abaixo
# de REARME_VELOCIDADE_PX_MS, medida em pelo menos REARME_PARADO_MS) ou recuou REARME_RECUO_PX para baixo do ponto mais
# alto atingido. Arrasto vertical continuo gera UM pulso.
const REARME_VELOCIDADE_PX_MS: float = 0.05
const REARME_PARADO_MS: int = 48
const REARME_RECUO_PX: float = 12.0

# Sensibilidade do modo A (decisao do G1 da f495): UM controle que escala juntos a zona morta do A e o dy minimo do
# flick; a janela de 150 ms nao e exposta e a zona morta do B NAO e escalada (a sensibilidade e "do modo A"). O valor e
# a sensibilidade: quanto maior, menores os limiares (px = constante / valor). Padrao 1,0 reproduz os 6 px / 24 px de
# hoje; faixa 0,5x a 2x (provisoria, o dono julga no aparelho). UMA definicao do padrao e da faixa; os esquemas, o
# Global e os testes leem so por este simbolo.
const SENSIBILIDADE_PADRAO: float = 1.0
const SENSIBILIDADE_MIN: float = 0.5
const SENSIBILIDADE_MAX: float = 2.0
# Chave no OptionsStore (mesma secao do modo de toque; API generica save_value/load_value, validada aqui).
const SENSIBILIDADE_SECTION: String = TouchMode.SECTION
const SENSIBILIDADE_KEY: String = "toque_sensibilidade"
# Default da leitura do store (ConfigFile.get_value com default null acusa ERROR; -1 cai no padrao abaixo).
const SENSIBILIDADE_SEM_VALOR: float = -1.0


# Valida o valor bruto lido do store (ou recebido do controle): tipo errado, NaN ou fora da faixa [MIN, MAX] vale o
# padrao.
static func sensibilidade_de_valor(valor: Variant) -> float:
	var t := typeof(valor)
	if t != TYPE_INT and t != TYPE_FLOAT:
		return SENSIBILIDADE_PADRAO
	var f := float(valor)
	if is_nan(f) or f < SENSIBILIDADE_MIN or f > SENSIBILIDADE_MAX:
		return SENSIBILIDADE_PADRAO
	return f


# Zona morta do A em px para uma sensibilidade (a do B continua ZONA_MORTA_PX, nao escalada). O piso protege a divisao
# de valores invalidos; quem passa a sensibilidade valida pelo Global/esquema nunca o atinge.
static func zona_morta_a(sensibilidade: float) -> float:
	return ZONA_MORTA_PX / maxf(sensibilidade, SENSIBILIDADE_MIN)


# Dy minimo do flick do A em px para uma sensibilidade.
static func flick_dy_min_a(sensibilidade: float) -> float:
	return FLICK_DY_MIN_PX / maxf(sensibilidade, SENSIBILIDADE_MIN)
