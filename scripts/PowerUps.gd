class_name PowerUps
extends RefCounted

# Registro estatico (sem cena) de nome de power-up -> script de PowerUp.
# O padrao de producao e vazio: os power-ups reais se registram nas features que os criam.
# PowerUpDeTeste nunca entra aqui (so o parametro so-debug o ativa).

# Nome -> script. registrar/limpar servem a testes com fakes.
static var _registro: Dictionary = _padrao()


static func _padrao() -> Dictionary:
	return {}


# Restaura o mapeamento de producao (depois de um limpar()/registrar() de teste)
static func restaurar_padrao() -> void:
	_registro = _padrao()


static func registrar(nome: StringName, power_up: Script) -> void:
	_registro[nome] = power_up


static func limpar() -> void:
	_registro.clear()


# Nomes registrados, na ordem de registro
static func nomes() -> Array[StringName]:
	var resultado: Array[StringName] = []
	for nome: StringName in _registro.keys():
		resultado.append(nome)
	return resultado


# Instancia nova do power-up pelo nome. Nome desconhecido: null com aviso (nunca erro nem crash).
static func resolver(nome: StringName) -> PowerUp:
	if not _registro.has(nome):
		push_warning("power-up desconhecido: %s" % nome)
		return null
	var instancia: Object = _registro[nome].new()
	if instancia is PowerUp:
		return instancia
	return null
