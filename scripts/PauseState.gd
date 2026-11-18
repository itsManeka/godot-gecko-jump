# Logica pura da pausa (sem cena). Fonte de verdade = `paused` da arvore injetada (get_tree() no jogo,
# um double com a propriedade `paused` no teste). Nao le nem escreve Global.iniciado.
# Pausar fora de partida ativa (antes do inicio ou com derrota) e ignorado; pausar/retomar sao idempotentes.
class_name PauseState
extends RefCounted

var _tree: Object
var _partida_ativa: Callable


## `tree`: objeto com a propriedade `paused` (SceneTree). `partida_ativa`: Callable sem argumentos -> bool.
func _init(tree: Object, partida_ativa: Callable) -> void:
	_tree = tree
	_partida_ativa = partida_ativa


## Predicado de partida ativa (§7.2): iniciada e sem derrota.
static func partida_ativa(started: bool, end: bool) -> bool:
	return started and not end


func esta_pausado() -> bool:
	return _tree.paused


## Pausa se a partida esta ativa. Retorna true se o jogo esta pausado ao final.
func pausar() -> bool:
	if not _tree.paused and _partida_ativa.call():
		_tree.paused = true
	return _tree.paused


## Retoma se estiver pausado; sem pausa e no-op.
func retomar() -> void:
	if _tree.paused:
		_tree.paused = false


## Pausado -> retoma; senao tenta pausar (ignorado fora do predicado).
func alternar() -> void:
	if _tree.paused:
		retomar()
	else:
		pausar()
