class_name PartidaCtx
extends RefCounted

# Chaves do snapshot da partida (`ctx`) que a Stage entrega as regras de modo. Definidas aqui uma vez: a Stage
# (`CTX_*`) e as regras citam estas constantes, nunca o literal da chave nos dois lados.

const PONTOS: String = "pontos"
const INICIADO: String = "iniciado"
# Tempo de partida decorrido em segundos (float); a Stage o preenche (relogio da partida)
const TEMPO: String = "tempo"
# f528 T6: dia UTC vigente no momento da chamada (sentinela DiaUtc.DIA_INVALIDO com relogio invalido) e o
# dia que a Stage guardou ao nascer — o do gasto e do resultado (virada no meio da partida nao muda o dia).
# STORE_DIARIO: store do dia da Stage; a regra do Diario consulta a tentativa por ele (o gasto e a gravacao
# sao sempre da Stage, no dia que ela guardou). So o Diario le estas chaves.
const DIA: String = "dia"
const DIA_DA_STAGE: String = "dia_stage"
const STORE_DIARIO: String = "store_diario"
