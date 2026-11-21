class_name PuroRule
extends GameModeRule

# Regra do modo Puro: igual ao Classico (cair encerra, pontos diretos, recorde gravado), sem power-ups.
# Sem estado proprio: a mesma instancia serve a todas as partidas.

func ao_cair(_ctx: Dictionary) -> bool:
	return true


func fim_por_regra(_ctx: Dictionary) -> bool:
	return false


func pontuar(pontos_brutos: int) -> int:
	return pontos_brutos


func grava_recorde() -> bool:
	return true


func power_ups_habilitados() -> bool:
	return false
