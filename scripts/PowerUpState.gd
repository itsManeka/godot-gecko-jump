class_name PowerUpState
extends RefCounted

# Estado de power-up da partida, so em memoria (sem cena, sem I/O). Dois slots independentes:
# 1 temporizado (duracao > 0) e 1 carga guardada a parte (duracao == 0, maximo 1).
# A pausa congela o contador sozinha: quem chama tick() e um no pausavel (ADR 0008).
var _ativo: PowerUp = null
var _restante: float = 0.0
var _carga: PowerUp = null


func coletar(power_up: PowerUp) -> void:
	if power_up.duracao > 0.0:
		_coletar_temporizado(power_up)
	else:
		_coletar_carga(power_up)


func _coletar_temporizado(power_up: PowerUp) -> void:
	if _ativo != null and _ativo.nome == power_up.nome:
		# Mesmo power-up: so reinicia o tempo (sem encerrar nem reativar)
		_restante = power_up.duracao
		return
	if _ativo != null:
		_ativo.ao_encerrar()
	_ativo = power_up
	_restante = power_up.duracao
	_ativo.ao_ativar()


func _coletar_carga(power_up: PowerUp) -> void:
	if _carga != null:
		return
	_carga = power_up
	_carga.ao_ativar()


func tick(delta: float) -> void:
	if _ativo == null:
		return
	_restante -= delta
	if _restante <= 0.0:
		var expirado: PowerUp = _ativo
		_ativo = null
		_restante = 0.0
		expirado.ao_encerrar()


# Gasta a carga guardada; false quando nao ha nenhuma
func consumir_carga() -> bool:
	if _carga == null:
		return false
	var gasta: PowerUp = _carga
	_carga = null
	gasta.ao_encerrar()
	return true


# Temporizado ativo, ou null
func ativo() -> PowerUp:
	return _ativo


# Segundos que faltam do temporizado ativo (0 sem ativo)
func restante() -> float:
	return _restante


# Cargas guardadas (0 ou 1)
func carga() -> int:
	return 0 if _carga == null else 1
