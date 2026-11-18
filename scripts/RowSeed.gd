class_name RowSeed
extends RefCounted

# Derivador dos RandomNumberGenerator por linha para a partida com seed. Sem arvore de cena:
# funcoes puras, testavel direto. A seed de cada rng vem do hash de [semente, indice, canal]
# (mistura, nunca soma: seeds consecutivas, como a data UTC do desafio diario, nao podem gerar
# linhas deslocadas umas das outras). Dois canais independentes por linha:
# - layout: tipo, mecanicas, cores das estaticas, speed, ciclo, oscilacao e piscar;
# - cor_movel: so a cor das moveis (consumo condicionado a janela do gecko, decisao (d) do ADR 0014).

const CANAL_LAYOUT: StringName = &"layout"
const CANAL_COR_MOVEL: StringName = &"cor_movel"


# Indice da linha a partir do y local: fonte unica e a geometria de InitialRows (Y_TOPO e
# ESPACAMENTO), nunca a ordem de criacao (as linhas iniciais nascem antes da Stage._ready e o
# numero de extras muda com a altura visivel). -10 -> 0, -60 -> 1, 40 -> -1, 190 -> -4;
# indice negativo e valido.
static func indice_do_y(y_local: float) -> int:
	return roundi((InitialRows.Y_TOPO - y_local) / InitialRows.ESPACAMENTO)


# Seed efetiva do canal: hash de [semente, indice, canal]. A soma (semente + indice) faria
# (s, i + 1) colidir com (s + 1, i) e deslocar as linhas entre seeds consecutivas.
static func _seed_do_canal(semente: int, indice: int, canal: StringName) -> int:
	return hash([semente, indice, canal])


# RNG do canal layout da linha: tipo, mecanicas, cores das estaticas, speed, ciclo, oscilacao
# e piscar.
static func rng_layout(semente: int, indice: int) -> RandomNumberGenerator:
	return _novo_rng(semente, indice, CANAL_LAYOUT)


# RNG do canal cor_movel da linha: so a cor das moveis. Fluxo separado do canal layout para
# que o consumo condicionado a janela do gecko nao desloque os sorteios das mecanicas.
static func rng_cor_movel(semente: int, indice: int) -> RandomNumberGenerator:
	return _novo_rng(semente, indice, CANAL_COR_MOVEL)


static func _novo_rng(semente: int, indice: int, canal: StringName) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed_do_canal(semente, indice, canal)
	return rng
