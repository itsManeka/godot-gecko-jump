class_name GameModes
extends RefCounted

# Registro de modos de jogo: lista ordenada do seletor, resolucao por id e ciclo do carrossel. O Classico
# sempre existe, e o primeiro da lista e o padrao de toda resolucao; Puro, Tempo e Zen vem depois dele em release,
# e o modo de teste so entra com a flag de debug ligada. Cada modo (e a regra dele) e uma instancia unica,
# criada na 1a consulta e reusada: regras sem estado proprio, o relogio da partida vive na Stage.

const ID_CLASSICO: StringName = &"classico"
const ID_PURO: StringName = &"puro"
const ID_TEMPO: StringName = &"tempo"
const ID_ZEN: StringName = &"zen"

static var _classico: GameMode = null
static var _puro: GameMode = null
static var _tempo: GameMode = null
static var _zen: GameMode = null
static var _teste: GameMode = null


# O modo Classico, sempre presente e primeiro.
static func classico() -> GameMode:
	if _classico == null:
		_classico = GameMode.new(
			ID_CLASSICO,
			"Classico",
			"Classico",
			"Pule, suba o maximo que puder e nao caia; o recorde e o seu melhor pouso.",
			ClassicoRule.new()
		)
	return _classico


# Puro: o Classico sem power-ups.
static func puro() -> GameMode:
	if _puro == null:
		_puro = GameMode.new(
			ID_PURO,
			"Puro",
			"Puro",
			"Sem power-ups: so voce, o pulo e a cor; o recorde e o seu melhor pouso.",
			PuroRule.new()
		)
	return _puro


# Contra o tempo: pontue o maximo antes de o relogio zerar.
static func tempo() -> GameMode:
	if _tempo == null:
		_tempo = GameMode.new(
			ID_TEMPO,
			"Tempo",
			"Contra o tempo",
			"Pontue o maximo antes do relogio zerar; o recorde e o seu melhor pouso.",
			TempoRule.new()
		)
	return _tempo


# Zen: sem pressa, sem derrota e sem recorde; o mundo para e a queda devolve o gecko a uma plataforma.
static func zen() -> GameMode:
	if _zen == null:
		_zen = GameMode.new(
			ID_ZEN,
			"Zen",
			"Zen",
			"Sem pressa e sem derrota: o mundo para e, se cair, voce volta.",
			ZenRule.new()
		)
	return _zen


static func _teste_unico() -> GameMode:
	if _teste == null:
		_teste = GameModeTeste.criar()
	return _teste


# Lista ordenada do seletor: Classico, Puro, Tempo, Zen; incluir_teste acrescenta o modo de teste por ultimo
# (debug/GUT, mesma regra do Classico com recorde proprio).
static func lista(incluir_teste := false) -> Array[GameMode]:
	var modos: Array[GameMode] = [classico(), puro(), tempo(), zen()]
	if incluir_teste:
		modos.append(_teste_unico())
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
		if texto == String(ID_PURO):
			return puro()
		if texto == String(ID_TEMPO):
			return tempo()
		if texto == String(ID_ZEN):
			return zen()
		if texto == String(GameModeTeste.ID) and Global.modos_teste_habilitado:
			return _teste_unico()
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
