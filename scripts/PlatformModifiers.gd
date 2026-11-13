class_name PlatformModifiers
extends RefCounted

# Registro estatico (sem cena) de nome de mecanica -> script de PlatformModifier.
# Fonte unica dos nomes: o `.tres` da curva usa estas constantes como texto.
const PLATAFORMAS_MENORES: StringName = &"plataformas_menores"
const PLATAFORMAS_QUE_CAEM: StringName = &"plataformas_que_caem"

# Nome -> script. Ja nasce com os modificadores reais; registrar/limpar servem a testes com fakes.
static var _registro: Dictionary = _padrao()


static func _padrao() -> Dictionary:
	return {
		PLATAFORMAS_MENORES: PlatformNarrower,
		PLATAFORMAS_QUE_CAEM: PlatformCrumble,
	}


# Restaura o mapeamento real (depois de um limpar() de teste)
static func restaurar_padrao() -> void:
	_registro = _padrao()


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
