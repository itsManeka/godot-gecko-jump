class_name DiaUtc
extends RefCounted

# Dia UTC do Desafio diario, com relogio injetavel (codigo sem cena, T3). D5: dia = floori(unix / 86400)
# — inteiro unico, sem calendario; serve de seed da partida do dia e de chave do save. Relogio invalido
# (unix <= 0) devolve a sentinela DIA_INVALIDO (-1), documentada e nunca usada como seed (a borda da
# Stage trata; C774). O callable default le o relogio do sistema em UTC.

const SEGUNDOS_POR_DIA := 86400
const DIA_INVALIDO := -1

var _relogio: Callable


func _init(relogio: Callable = Callable()) -> void:
	_relogio = relogio if relogio.is_valid() else _unix_do_sistema


func dia_atual() -> int:
	var unix: float = float(_relogio.call())
	if unix <= 0.0:
		return DIA_INVALIDO
	return floori(unix / SEGUNDOS_POR_DIA)


func _unix_do_sistema() -> float:
	# Unix epoch e UTC por definicao (segundos desde 1970-01-01T00:00:00Z): o dia derivado dele e o
	# dia UTC do ADR 0014 (D6), sem fuso local.
	return Time.get_unix_time_from_system()
