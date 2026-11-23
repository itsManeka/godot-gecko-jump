class_name DiarioRule
extends GameModeRule

# Regra do Desafio diario (f528 T4, ADR 0014): uma tentativa por dia UTC com a fase sorteada pela data
# (usa_seed_do_dia true; a seed entra na Stage em T5) e nenhum icone de power-up nasce, com qualquer raridade.
# O resultado do dia nunca vai ao best_score_* do modo — grava_recorde false: o recorde proprio vive no
# DesafioDiarioStore, gravado ao fim da partida (T6). `pode_iniciar` (tentativa unica) e ligado por T6; a
# pausa segue so Continuar/Opcoes (default) e a queda encerra como no Classico (default). Sem estado proprio:
# a mesma instancia serve a todas as partidas.

func power_ups_habilitados() -> bool:
	return false


func grava_recorde() -> bool:
	return false


func usa_seed_do_dia() -> bool:
	return true
