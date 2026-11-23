extends GutTest

# DiaUtc (T3): dia UTC com relogio injetavel. D5: dia = floori(unix / 86400); relogio invalido
# (unix <= 0) devolve a sentinela DIA_INVALIDO (-1). Valores de unix literais por cenario;
# nenhum teste depende do relogio real da maquina.
# preload em vez do nome global: roda igual com ou sem o cache de classes do editor
# (as rodadas dirigidas da task nao passam pelo passo --import do .verify.mjs).

const DiaUtcScript := preload("res://scripts/DiaUtc.gd")

const DIA_BASE := 19675  # floori(1700000000 / 86400)


# Cenario [mutacao] C749: borda do dia UTC com unix literal — 23:59:59Z e 00:00:00Z seguinte (+1);
# dois instantes do mesmo dia devolvem o mesmo dia.
func test_c749_dia_atual_borda_23_59_59_para_00_00_00() -> void:
	assert_eq(DiaUtcScript.new(_relogio(86399)).dia_atual(), 0, "C749: unix 86399 (23:59:59Z do dia 0) -> dia 0")
	assert_eq(DiaUtcScript.new(_relogio(86400)).dia_atual(), 1, "C749: unix 86400 (00:00:00Z seguinte) -> dia +1")
	assert_eq(DiaUtcScript.new(_relogio(1700000000)).dia_atual(), DIA_BASE, "C749: base fixa 1700000000 -> dia 19675")
	assert_eq(DiaUtcScript.new(_relogio(1700000100)).dia_atual(), DIA_BASE, "C749: dois instantes do mesmo dia -> dia igual")
	assert_eq(DiaUtcScript.new(_relogio(1700006399)).dia_atual(), DIA_BASE, "C749: 23:59:59Z do dia base -> dia base")
	assert_eq(DiaUtcScript.new(_relogio(1700006400)).dia_atual(), DIA_BASE + 1, "C749: 00:00:00Z seguinte -> dia base + 1")


# Cenario [mutacao] C750: relogio invalido (unix 0 e negativo) devolve a sentinela -1.
func test_c750_relogio_invalido_devolve_sentinela() -> void:
	assert_eq(DiaUtcScript.new(_relogio(0)).dia_atual(), DiaUtcScript.DIA_INVALIDO, "C750: unix 0 -> sentinela")
	assert_eq(DiaUtcScript.new(_relogio(-5)).dia_atual(), DiaUtcScript.DIA_INVALIDO, "C750: unix negativo -> sentinela")
	assert_eq(DiaUtcScript.DIA_INVALIDO, -1, "C750: a sentinela documentada e -1")


# Sem relogio injetado o default e o do sistema (UTC); so prova que o callable default e valido.
func test_dia_atual_sem_relogio_usa_o_sistema() -> void:
	assert_true(DiaUtcScript.new().dia_atual() > 0, "relogio do sistema devolve dia atual positivo (unix real > 86400)")


func _relogio(unix: int) -> Callable:
	return func() -> int: return unix
