class_name GameState
extends RefCounted

# Ponte de estado para o smoke (`window.__GAME_STATE__`). Montador puro: recebe valores simples e devolve o dicionario,
# sem ler a arvore de cena. `publish` e o unico ponto com `JavaScriptBridge` do jogo e so age em web de debug; em
# headless, desktop e release e no-op. Contrato em `.claude/dev-stacks/godot.md` (workspace).

const STATE_MENU := "menu"
const STATE_PLAYING := "playing"
const STATE_LOST := "lost"
# Campo `tutorial` da ponte: card do tutorial aberto ou fechado
const STATE_TUTORIAL_ABERTO := "aberto"
const STATE_TUTORIAL_FECHADO := "fechado"

# Monta o estado publicado: `score` e `best` (int), `state` ("menu"|"playing"|"lost"), `player.alive` (bool) e
# `volume.music`/`volume.sfx` (int 0-100, o mesmo valor mostrado nos sliders de Opcoes) e
# `tutorial` ("aberto"|"fechado": card do tutorial)
static func build(
	score: int, best: int, state: String, alive: bool, music: int = 100, sfx: int = 100, tutorial_aberto: bool = false
) -> Dictionary:
	return {
		"score": score,
		"best": best,
		"state": state,
		"player": {"alive": alive},
		"volume": {"music": music, "sfx": sfx},
		"tutorial": STATE_TUTORIAL_ABERTO if tutorial_aberto else STATE_TUTORIAL_FECHADO,
	}

# Decisor puro da trava de publicacao: so web de debug publica (release ignora; headless/desktop nao tem web)
static func deve_publicar(is_web: bool, is_debug: bool) -> bool:
	return is_web and is_debug

# Publica o estado em `window.__GAME_STATE__` so em web de debug; em qualquer outro ambiente nao faz nada
static func publish(estado: Dictionary) -> void:
	if not deve_publicar(OS.has_feature("web"), OS.is_debug_build()):
		return
	# O estado so leva valor interno (int, bool e as 3 strings constantes de estado). Campo de texto livre
	# (ex.: nome de jogador) exige rever a montagem deste eval.
	JavaScriptBridge.eval("window.__GAME_STATE__ = %s" % JSON.stringify(estado), true)
