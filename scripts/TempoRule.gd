class_name TempoRule
extends GameModeRule

# Regra do modo Contra o tempo: a partida termina quando o tempo de partida do ctx chega ao limite; o resto
# segue o Classico (cair encerra, recorde gravado, power-ups habilitados). Sem estado proprio: o relogio vive
# na Stage e o limite e lido a cada chamada de Global.limite_tempo_s (seam de debug ou `.tres`).

func ao_cair(_ctx: Dictionary) -> bool:
	return true


func fim_por_regra(ctx: Dictionary) -> bool:
	var tempo: Variant = ctx.get(PartidaCtx.TEMPO)
	if not (tempo is float or tempo is int):
		return false
	return float(tempo) >= Global.limite_tempo_s()


func pontuar(pontos_brutos: int) -> int:
	return pontos_brutos


func grava_recorde() -> bool:
	return true


func power_ups_habilitados() -> bool:
	return true
