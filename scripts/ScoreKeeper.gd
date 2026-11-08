class_name ScoreKeeper
extends RefCounted

# Pontuacao da ultima partida e recorde da sessao. Logica pura: sem arvore de cena e sem persistencia.

# Ultima pontuacao registrada
var last: int = 0
# Melhor pontuacao registrada
var best: int = 0

# Registra a pontuacao e sobe o recorde so se a nova pontuacao for maior que ele
func set_score(score: int) -> void:
	last = score
	if last > best:
		best = last
