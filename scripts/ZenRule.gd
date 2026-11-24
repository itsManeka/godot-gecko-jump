class_name ZenRule
extends GameModeRule

# Regra do modo Zen: sem derrota, sem recorde, sem power-ups e com o mundo parado (sem scroll forcado). Ao cair,
# o gecko reaparece na ultima plataforma pisada. Sem estado proprio: a mesma instancia serve a todas as partidas.

func ao_cair(_ctx: Dictionary) -> bool:
	return false


func reposiciona_ao_cair() -> bool:
	return true


func fator_scroll_forcado() -> float:
	return 0.0


func grava_recorde() -> bool:
	return false


func mostra_recorde() -> bool:
	return false


func power_ups_habilitados() -> bool:
	return false


func fim_por_regra(_ctx: Dictionary) -> bool:
	return false


# f527 T6: a pausa do Zen oferece Sair — sai da partida pela pausa, voltando ao menu sem gravar recorde.
func permite_sair_pela_pausa() -> bool:
	return true
