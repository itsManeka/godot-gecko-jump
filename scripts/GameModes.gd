class_name GameModes
extends RefCounted

# Registro de modos de jogo: lista ordenada do seletor, resolucao por id e ciclo do carrossel. O Classico
# sempre existe, e o primeiro da lista e o padrao de toda resolucao; nenhum outro modo real entra aqui
# (so o de teste, e so com a flag de debug ligada).

const ID_CLASSICO: StringName = &"classico"


# O modo Classico, sempre presente e primeiro.
static func classico() -> GameMode:
	return GameMode.new(
		ID_CLASSICO,
		"Classico",
		"Classico",
		"Pule, suba o maximo que puder e nao caia; o recorde e o seu melhor pouso.",
		ClassicoRule.new()
	)


# Lista ordenada do seletor: Classico primeiro (e unico em release); incluir_teste acrescenta o modo de
# teste (debug/GUT, mesma regra com recorde proprio).
static func lista(incluir_teste := false) -> Array[GameMode]:
	var modos: Array[GameMode] = [classico()]
	if incluir_teste:
		modos.append(GameModeTeste.criar())
	return modos


# Modo padrao de toda resolucao (Classico).
static func padrao() -> GameMode:
	return classico()


# Resolve um id vindo de entrada externa (opcoes salvas, decisor de debug): nulo, tipo invalido, vazio,
# desconhecido ou `teste` sem a flag de debug devolvem o Classico — nunca um modo que o build nao expoe.
static func de_id(id: Variant) -> GameMode:
	if id is String or id is StringName:
		var texto := String(id)
		if texto == String(ID_CLASSICO):
			return classico()
		if texto == String(GameModeTeste.ID) and Global.modos_teste_habilitado:
			return GameModeTeste.criar()
	return classico()


# Ciclo do carrossel: proximo do ultimo volta ao primeiro; anterior do primeiro vai ao ultimo. Modo fora
# da lista cicla a partir do primeiro; lista vazia devolve o padrao.
static func proximo(modo: GameMode, modos: Array[GameMode]) -> GameMode:
	if modos.is_empty():
		return padrao()
	var indice := _indice_de(modo, modos)
	return modos[(indice + 1) % modos.size()]


static func anterior(modo: GameMode, modos: Array[GameMode]) -> GameMode:
	if modos.is_empty():
		return padrao()
	var indice := _indice_de(modo, modos)
	return modos[(indice - 1 + modos.size()) % modos.size()]


static func _indice_de(modo: GameMode, modos: Array[GameMode]) -> int:
	for i in modos.size():
		if modos[i].id == modo.id:
			return i
	return 0
