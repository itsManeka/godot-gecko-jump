class_name PlatformModifiers
extends RefCounted

# Registro estatico (sem cena) de nome de mecanica -> script de PlatformModifier.
# Fonte unica dos nomes: o `.tres` da curva usa estas constantes como texto.
const PLATAFORMAS_MENORES: StringName = &"plataformas_menores"
const PLATAFORMAS_QUE_CAEM: StringName = &"plataformas_que_caem"

# Nome -> script. Vazio ate as classes dos modificadores existirem; cada uma entra aqui ao ser criada.
static var _registro: Dictionary = {}


static func registrar(nome: StringName, modificador: Script) -> void:
	_registro[nome] = modificador


static func limpar() -> void:
	_registro.clear()


# Devolve um modificador por nome conhecido de snapshot.get_mecanicas(), na mesma ordem.
# Nome desconhecido e ignorado com aviso (nunca erro nem crash).
static func resolver(snapshot: DifficultySnapshot) -> Array[PlatformModifier]:
	var modificadores: Array[PlatformModifier] = []
	for nome: StringName in snapshot.get_mecanicas():
		if not _registro.has(nome):
			push_warning("mecanica de plataforma desconhecida: %s" % nome)
			continue
		var instancia: Object = _registro[nome].new()
		if instancia is PlatformModifier:
			modificadores.append(instancia)
	return modificadores
