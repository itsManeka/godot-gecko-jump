class_name ClassicoRule
extends GameModeRule

# Regra do modo Classico: os valores literais do jogo de hoje (cada um e o contrato do modo padrao, nao um
# valor "plausivel"): cair encerra, pontos passam direto, recorde gravado, power-ups habilitados.

func ao_cair(ctx: Dictionary) -> bool:
	return true


func fim_por_regra(ctx: Dictionary) -> bool:
	return false


func pontuar(pontos_brutos: int) -> int:
	return pontos_brutos


func grava_recorde() -> bool:
	return true


func power_ups_habilitados() -> bool:
	return true
