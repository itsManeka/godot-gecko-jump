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
