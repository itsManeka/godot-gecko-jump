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


# f528 T6: uma tentativa por dia UTC (ADR 0014). O ctx da Stage traz o dia vigente (DIA), o dia que ela
# guardou ao nascer (DIA_DA_STAGE) e o store do dia (STORE_DIARIO): false quando o dia ja foi jogado, o
# relogio e invalido (sentinela) ou a virada encontrou a Stage aberta no dia antigo — a Stage recarrega
# com a seed do dia novo antes de gastar (C783). ctx sem as chaves do dia (montado fora da Stage):
# falha segura, false.
func pode_iniciar(ctx: Dictionary) -> bool:
	var dia: int = int(ctx.get(PartidaCtx.DIA, DiaUtc.DIA_INVALIDO))
	if dia == DiaUtc.DIA_INVALIDO:
		return false
	if int(ctx.get(PartidaCtx.DIA_DA_STAGE, DiaUtc.DIA_INVALIDO)) != dia:
		return false
	var store: DesafioDiarioStore = ctx.get(PartidaCtx.STORE_DIARIO) as DesafioDiarioStore
	if store == null:
		return false
	return store.tentativa_disponivel(dia)
