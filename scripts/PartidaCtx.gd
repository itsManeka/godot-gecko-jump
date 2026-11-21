class_name PartidaCtx
extends RefCounted

# Chaves do snapshot da partida (`ctx`) que a Stage entrega as regras de modo. Definidas aqui uma vez: a Stage
# (`CTX_*`) e as regras citam estas constantes, nunca o literal da chave nos dois lados.

const PONTOS: String = "pontos"
const INICIADO: String = "iniciado"
# Tempo de partida decorrido em segundos (float); a Stage o preenche (relogio da partida)
const TEMPO: String = "tempo"
