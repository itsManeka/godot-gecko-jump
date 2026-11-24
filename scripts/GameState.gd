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

# Chaves (caminho com ponto) que a ponte publica e que um `expect` de roteiro de smoke pode ler: fonte unica do
# validador dos roteiros (test_smoke_roteiros.gd); `build` tem de publicar cada uma delas (C804)
const CHAVES_PUBLICADAS: Array[String] = [
	"score",
	"best",
	"state",
	"player.alive",
	"player.x",
	"player.y",
	"player.on_floor",
	"dificuldade.estagio",
	"powerup.ativo",
	"powerup.restante",
	"powerup.carga",
	"modo",
	"relogio.restante",
	"alvo.alinhado",
	"alvo.dx",
]

# Monta o estado publicado: `score` e `best` (int), `state` ("menu"|"playing"|"lost"), `player.alive` (bool) e
# `volume.music`/`volume.sfx` (int 0-100, o mesmo valor mostrado nos sliders de Opcoes) e
# `tutorial` ("aberto"|"fechado": card do tutorial) e `dificuldade.estagio` (int, indice do estagio na curva; 0 = inicial) e
# `dificuldade.aviso` (bool, true enquanto a moldura de subida de estagio pulsa) e
# `dificuldade.alpha` (float 0-1, alpha atual da moldura de aviso, 0 = apagada; prova do pulso real no smoke) e
# `player.x`/`player.y` (int, pixels logicos arredondados de `player_x`/`player_y`) e
# `powerup.ativo` (nome do temporizado ativo ou ""), `powerup.restante` (int, segundos restantes arredondados para
# cima; 0 sem ativo) e `powerup.carga` (int, 0 ou 1) e
# `modo` (string, id do modo de jogo atual; padrao "classico") e `relogio.restante` (int, segundos restantes do
# Contra o tempo arredondados para cima; 0 fora do modo `tempo`; padrao 0) e
# `alvo.alinhado` (bool, true se o gecko pode tocar reto agora: ha plataforma da sua cor na linha de cima alinhada em x)
# e `alvo.dx` (int, px com sinal ate a plataforma elegivel da linha de cima na chegada; 0 sem alvo) e
# `player.on_floor` (bool, estado de contato com o chao no momento da publicacao);
# ultimo parametro, padrao `false` para compatibilidade.
static func build(
	score: int,
	best: int,
	state: String,
	alive: bool,
	music: int = 100,
	sfx: int = 100,
	tutorial_aberto: bool = false,
	estagio: int = 0,
	aviso: bool = false,
	player_x: float = 0.0,
	player_y: float = 0.0,
	alpha: float = 0.0,
	powerup_ativo: String = "",
	powerup_restante: float = 0.0,
	powerup_carga: int = 0,
	modo: String = "classico",
	relogio_restante: int = 0,
	alvo_alinhado: bool = false,
	alvo_dx: int = 0,
	player_on_floor: bool = false
) -> Dictionary:
	return {
		"score": score,
		"best": best,
		"state": state,
		"player": {"alive": alive, "x": roundi(player_x), "y": roundi(player_y), "on_floor": player_on_floor},
		"volume": {"music": music, "sfx": sfx},
		"tutorial": STATE_TUTORIAL_ABERTO if tutorial_aberto else STATE_TUTORIAL_FECHADO,
		"dificuldade": {"estagio": estagio, "aviso": aviso, "alpha": alpha},
		"powerup": {"ativo": powerup_ativo, "restante": ceili(powerup_restante), "carga": powerup_carga},
		"modo": modo,
		"relogio": {"restante": relogio_restante},
		"alvo": {"alinhado": alvo_alinhado, "dx": alvo_dx},
	}

# Validador de chave de `expect` do roteiro de smoke: true se a ponte publica essa chave
static func chave_publicada(chave: String) -> bool:
	return CHAVES_PUBLICADAS.has(chave)

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
