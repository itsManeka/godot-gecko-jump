class_name GameModeTeste
extends RefCounted

# Modo de teste do seletor: 2a entrada do carrossel em debug (e nos GUT), regra identica a do Classico e
# recorde proprio (id `teste` distinto => arquivo de recorde proprio). Nunca em release: entra na lista
# so quando o decisor de debug liga Global.modos_teste_habilitado.

const ID: StringName = &"teste"


static func criar() -> GameMode:
	return GameMode.new(
		ID,
		"Teste",
		"Modo de teste",
		"Entrada de debug do seletor; mesma regra do Classico com recorde proprio.",
		ClassicoRule.new()
	)
