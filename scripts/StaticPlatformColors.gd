class_name StaticPlatformColors
extends RefCounted

# Cores das 3 plataformas estaticas do gerador inicial. Sem arvore de cena: testavel direto.

const QUANTIDADE := 3

# Devolve 3 cores: a cor inicial numa posicao sorteada e as outras 2 aleatorias (entre as 4 validas).
# Sem rng usa randi() global; com rng (seed fixa nos testes) e deterministico.
# As 2 cores livres podem repetir a cor inicial (intencional: so se garante que ela aparece ao menos 1 vez).
static func sortear(cor_inicial: int, rng: RandomNumberGenerator = null) -> Array:
	var cores: Array = []
	for i in QUANTIDADE:
		cores.append(Enums.get_random_color(rng))
	var posicao: int = (randi() if rng == null else rng.randi()) % QUANTIDADE
	cores[posicao] = cor_inicial
	return cores
