class_name TouchSchemes
extends RefCounted

# Fabrica dos esquemas de toque por modo (TouchMode). Ponto unico de ligacao: T4-T6 nao editam este arquivo, so o
# proprio esquema (e a constante IMPLEMENTADO dele).


static func implementado(modo: int) -> bool:
	match modo:
		TouchMode.Modo.A:
			return TouchSchemeA.IMPLEMENTADO
		TouchMode.Modo.B:
			return TouchSchemeB.IMPLEMENTADO
		TouchMode.Modo.C:
			return TouchSchemeC.IMPLEMENTADO
	return false


# Esquema do modo, ou null se o modo nao esta implementado (a camada fica inerte).
static func criar(modo: int) -> TouchScheme:
	if not implementado(modo):
		return null
	match modo:
		TouchMode.Modo.A:
			return TouchSchemeA.new()
		TouchMode.Modo.B:
			return TouchSchemeB.new()
		TouchMode.Modo.C:
			return TouchSchemeC.new()
	return null
