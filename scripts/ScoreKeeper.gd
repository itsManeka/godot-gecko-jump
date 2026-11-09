class_name ScoreKeeper
extends RefCounted

# Pontuacao da ultima partida e recorde. Logica pura: sem arvore de cena e sem I/O. A gravacao do recorde
# fica fora desta classe: quem persiste escuta `best_changed` e o recorde inicial entra por `load_best`.

signal best_changed(best: int)

# Ultima pontuacao registrada
var last: int = 0
# Melhor pontuacao registrada
var best: int = 0

# Semeia o recorde inicial (ex. valor salvo em disco) sem emitir `best_changed`
func load_best(value: int) -> void:
	best = value

# Registra a pontuacao e sobe o recorde so se a nova pontuacao for maior que ele; so emite `best_changed` nesse caso
func set_score(score: int) -> void:
	last = score
	if last > best:
		best = last
		best_changed.emit(best)
