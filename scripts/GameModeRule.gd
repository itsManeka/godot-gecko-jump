class_name GameModeRule
extends RefCounted

# Contrato do hook de regra de modo, consultado pela Stage durante a partida. Os defaults seguem o padrao
# identico ao jogo de hoje: um modo so sobrescreve o ponto que muda. `ctx` e o snapshot da partida montado
# pela Stage no momento da chamada (dicionario com o estado que a regra pode consultar).

# Derrota por queda (linha de derrota): true encerra a partida como hoje, false deixa seguir.
func ao_cair(ctx: Dictionary) -> bool:
	return true


# Fim de partida por regra do proprio modo (checado por tick com a partida iniciada): false = nunca.
func fim_por_regra(ctx: Dictionary) -> bool:
	return false


# Pontos efetivos da partida a partir dos brutos: o jogo de hoje nao altera.
func pontuar(pontos_brutos: int) -> int:
	return pontos_brutos


# Se o recorde do modo e gravado ao fim da partida.
func grava_recorde() -> bool:
	return true


# Se as plataformas podem nascer com power-up (gancho copiado ao ScrollLevel uma vez no _ready da Stage).
func power_ups_habilitados() -> bool:
	return true
