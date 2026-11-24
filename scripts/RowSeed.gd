class_name RowSeed
extends RefCounted

# Derivador dos RandomNumberGenerator por linha para a partida com seed. Sem arvore de cena:
# funcoes puras, testavel direto. A seed de cada rng vem da mistura int64 de [semente, indice,
# canal] (f528 T2, D9(a)): aritmetica do proprio engine, sem hash() — que nao tem valor
# garantido entre plataformas; a sequencia literal e travada valor a valor em test_row_seed.gd.
# Mistura, nunca soma: seeds consecutivas, como a data UTC do desafio diario, nao podem gerar
# linhas deslocadas umas das outras. Dois canais independentes por linha:
# - layout: tipo, mecanicas, cores das estaticas, speed, ciclo, oscilacao e piscar;
# - cor_movel: so a cor das moveis (consumo condicionado a janela do gecko, decisao (d) do ADR 0014).

# Canais como constantes inteiras (eram StringName enquanto a seed vinha do hash()); a distancia
# entre elas (2^24 linhas de scroll) so colide com indice fora do dominio real do jogo.
const CANAL_LAYOUT: int = 0x1000000
const CANAL_COR_MOVEL: int = 0x2000000

# Campo do indice (32 bits) e multiplicadores impares de 32 bits da avalanche (padrao fmix).
const _MASCARA_32: int = 0xFFFFFFFF
const _MULTIPLICADOR_A: int = 0x9E3779B1
const _MULTIPLICADOR_B: int = 0x85EBCA77


# Indice da linha a partir do y local: fonte unica e a geometria de InitialRows (Y_TOPO e
# ESPACAMENTO), nunca a ordem de criacao (as linhas iniciais nascem antes da Stage._ready e o
# numero de extras muda com a altura visivel). -10 -> 0, -60 -> 1, 40 -> -1, 190 -> -4;
# indice negativo e valido.
static func indice_do_y(y_local: float) -> int:
	return roundi((InitialRows.Y_TOPO - y_local) / InitialRows.ESPACAMENTO)


# Seed efetiva do canal: semente (bits altos, faixa 0..SeedSource.MAX_SEED da borda da Stage) e
# indice (bits 0..31, negativo valido) em campos de bits distintos — a soma (semente + indice)
# faria (s, i + 1) colidir com (s + 1, i) e deslocar as linhas entre seeds consecutivas — e o
# canal somado depois do empacotamento, distante 2^24 do canal vizinho.
static func _seed_do_canal(semente: int, indice: int, canal: int) -> int:
	var empacotado: int = (semente << 32) | (indice & _MASCARA_32)
	return _misturar64(empacotado + canal)


# Avalanche int64 (xor com shift e multiplicacao por impar, no padrao do fmix do murmurhash)
# com o wrap do int do proprio engine: mesma aritmetica em qualquer plataforma, sem hash(). O
# passo (m >> 33) desce os bits da semente para a metade baixa do valor.
static func _misturar64(valor: int) -> int:
	var m: int = valor
	m = (m ^ (m >> 33)) * _MULTIPLICADOR_A
	m = (m ^ (m >> 29)) * _MULTIPLICADOR_B
	return m ^ (m >> 32)


# RNG do canal layout da linha: tipo, mecanicas, cores das estaticas, speed, ciclo, oscilacao
# e piscar.
static func rng_layout(semente: int, indice: int) -> RandomNumberGenerator:
	return _novo_rng(semente, indice, CANAL_LAYOUT)


# RNG do canal cor_movel da linha: so a cor das moveis. Fluxo separado do canal layout para
# que o consumo condicionado a janela do gecko nao desloque os sorteios das mecanicas.
static func rng_cor_movel(semente: int, indice: int) -> RandomNumberGenerator:
	return _novo_rng(semente, indice, CANAL_COR_MOVEL)


static func _novo_rng(semente: int, indice: int, canal: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed_do_canal(semente, indice, canal)
	return rng
