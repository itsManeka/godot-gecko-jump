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
#
# proporcao_estaticas (so RANDOM_ALL): fracao sorteada como STATIC; o resto divide igualmente entre esquerda e direita.
# No valor do estagio 0 usa o caminho legado (randi() % 3), preservando a sequencia seedada de antes da curva.
static func resolve(
	type: Enums.PLATFORM_TYPE,
	rng: RandomNumberGenerator = null,
	proporcao_estaticas: float = DifficultyStage.PROPORCAO_PADRAO
) -> Enums.PLATFORM_TYPE:
	if type == Enums.PLATFORM_TYPE.RANDOM_ALL:
		if is_equal_approx(proporcao_estaticas, DifficultyStage.PROPORCAO_PADRAO):
			return _sortear(TIPOS_RANDOM_ALL, rng)
		var r: float = randf() if rng == null else rng.randf()
		if r < proporcao_estaticas:
			return Enums.PLATFORM_TYPE.STATIC
		return _sortear(TIPOS_DIRECAO, rng)
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
