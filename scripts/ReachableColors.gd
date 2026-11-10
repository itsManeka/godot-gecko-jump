class_name ReachableColors
extends RefCounted

# Cor alcancavel: (a) nova cor do gecko entre as candidatas da linha de cima; (b) cor de plataforma movel com janela de K.
# Sem arvore de cena: recebe tudo por parametro, testavel direto. Sem rng usa randi() global; com rng e deterministico.

# Janela das plataformas moveis: toda janela de K plataformas consecutivas (ordem de criacao) tem a cor do gecko.
# Constante de dificuldade: K maior = a garantia fica mais rara; K <= 1 = toda movel da cor do gecko.
const K := 3


# (a) Devolve uma das cores candidatas. Lista vazia (sem plataforma visivel acima) -> sorteio livre entre as cores de Enums.
static func escolher_cor_gecko(candidatas: Array, rng: RandomNumberGenerator = null) -> int:
	if candidatas.is_empty():
		return Enums.get_random_color(rng)
	var indice: int = (randi() if rng == null else rng.randi()) % candidatas.size()
	return candidatas[indice]


# (b) Cor de uma plataforma movel. Se nenhuma das K-1 ultimas de `anteriores` tem a cor do gecko, forca a cor do gecko;
# senao sorteia. Historico menor que K-1 (inicio da linha) conta como "nenhuma tem a cor". `k` so muda em teste.
static func cor_plataforma_movel(
	cor_gecko: int, anteriores: Array, rng: RandomNumberGenerator = null, k: int = K
) -> int:
	if k <= 1 or not _tem_cor_na_janela(cor_gecko, anteriores, k - 1):
		return cor_gecko
	return Enums.get_random_color(rng)


static func _tem_cor_na_janela(cor: int, anteriores: Array, tamanho: int) -> bool:
	var inicio: int = maxi(0, anteriores.size() - tamanho)
	for i in range(inicio, anteriores.size()):
		if anteriores[i] == cor:
			return true
	return false
