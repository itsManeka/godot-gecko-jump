class_name TouchTuning
extends RefCounted

# Valores numericos dos esquemas de toque (hipotese do Q5 da f493, provisorios ate o playtest do dono).
# Cada valor tem UMA definicao aqui; trocar e editar uma linha. Os esquemas A/B e os testes leem so por este simbolo.

# Deslocamento horizontal (px logicos) a partir do ponto de contato abaixo do qual o dedo esta "parado".
const ZONA_MORTA_PX: float = 6.0
# Flick para cima: deslocamento vertical minimo (px logicos) dentro da janela abaixo.
const FLICK_DY_MIN_PX: float = 24.0
const FLICK_JANELA_MS: int = 150
