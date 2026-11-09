class_name PlatformTypePicker
extends RefCounted

# Escolhe o tipo concreto de plataforma para o gerador. Sem arvore de cena: testavel direto.
# Tipos aleatorios (RANDOM_ALL, RANDOM_DIRECTION) viram um tipo concreto; tipos concretos passam sem mudanca.

# Opcoes concretas para RANDOM_ALL
const TIPOS_RANDOM_ALL := [
	Enums.PLATFORM_TYPE.STATIC,
	Enums.PLATFORM_TYPE.MOVE_TO_LEFT,
	Enums.PLATFORM_TYPE.MOVE_TO_RIGHT,
]

# Opcoes concretas para RANDOM_DIRECTION
const TIPOS_DIRECAO := [
	Enums.PLATFORM_TYPE.MOVE_TO_LEFT,
	Enums.PLATFORM_TYPE.MOVE_TO_RIGHT,
]

# Devolve o tipo concreto. Sem rng usa randi() global (mesmo comportamento de antes); com rng, determinístico.
static func resolve(type: Enums.PLATFORM_TYPE, rng: RandomNumberGenerator = null) -> Enums.PLATFORM_TYPE:
	if type == Enums.PLATFORM_TYPE.RANDOM_ALL:
		return _sortear(TIPOS_RANDOM_ALL, rng)
	if type == Enums.PLATFORM_TYPE.RANDOM_DIRECTION:
		return _sortear(TIPOS_DIRECAO, rng)
	return type

# Sorteia uma opcao uniformemente
static func _sortear(opcoes: Array, rng: RandomNumberGenerator) -> Enums.PLATFORM_TYPE:
	var indice: int
	if rng == null:
		indice = randi() % opcoes.size()
	else:
		indice = rng.randi() % opcoes.size()
	return opcoes[indice]
