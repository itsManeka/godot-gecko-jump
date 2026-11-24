class_name PuroRule
extends GameModeRule

# Regra do modo Puro: igual ao Classico (so sobrescreve os power-ups), sem power-ups.
# Sem estado proprio: a mesma instancia serve a todas as partidas.

func power_ups_habilitados() -> bool:
	return false
