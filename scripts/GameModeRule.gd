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


# Multiplicador do scroll forcado da curva (1.0 = scroll normal; 0.0 = mundo parado).
func fator_scroll_forcado() -> float:
	return 1.0


# Ao cair (sem encerrar), reposiciona o gecko na ultima plataforma pisada em vez de deixar cair.
func reposiciona_ao_cair() -> bool:
	return false


# Se o menu mostra o recorde do modo (Best/Last e a faixa de placar).
func mostra_recorde() -> bool:
	return true


# f527 T8: se o modo tem relogio de partida mostrado no HUD (so o Contra o tempo).
func tem_relogio() -> bool:
	return false


# f527 T6: se o overlay de pausa oferece saida da partida (botao Sair: despausa e volta ao menu sem
# gravar nada). false = o overlay segue so com Continuar/Opcoes; o Zen permite.
func permite_sair_pela_pausa() -> bool:
	return false


# f528 T4: se a partida pode ser iniciada com o ctx vigente (default neutro: sempre pode, como hoje).
# O Diario consulta a tentativa do dia (ligado em T6); nenhum modo existente sobrescreve.
func pode_iniciar(ctx: Dictionary) -> bool:
	return true


# f528 T4: se a partida nasce da seed do dia UTC (default neutro: false = sorteio livre de hoje). So o Diario usa.
func usa_seed_do_dia() -> bool:
	return false
