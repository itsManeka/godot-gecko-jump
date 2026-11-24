extends GameModeRule

# Regra de modo so de teste (nao e um modo do jogo): cada ponto do contrato e um campo, e os defaults sao os
# contrarios do Classico (cai sem encerrar, soma 2x, nao grava recorde, sem power-ups, sem fim por regra).
# Sem class_name de proposito: carregada por preload, nunca entra no registro de producao.

var cair_encerra: bool = false
var fim: bool = false
var fator: int = 2
var grava: bool = false
var power_ups: bool = false


func ao_cair(_ctx: Dictionary) -> bool:
	return cair_encerra


func fim_por_regra(_ctx: Dictionary) -> bool:
	return fim


func pontuar(pontos_brutos: int) -> int:
	return pontos_brutos * fator


func grava_recorde() -> bool:
	return grava


func power_ups_habilitados() -> bool:
	return power_ups
