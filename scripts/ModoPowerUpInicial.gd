class_name ModoPowerUpInicial
extends RefCounted

## Decide o power-up ativo desde o inicio da partida (smoke debug) a partir do valor bruto do parametro `?powerup=`.
## O nome do parametro e contrato para os roteiros de smoke: nao renomear.
## `decide` e puro: nao le o ambiente nem a arvore de cena; o chamador passa o valor bruto e a flag de build.
## `read_raw` e a unica leitura do ambiente (fina, isolada do decisor): so no web debug le a query string.
##
## Saida: `String` com o nome do power-up, ou "" (nenhum).
## - build release (`is_debug` falso): sempre "", mesmo com "teste" (producao ignora `?powerup=`).
## - aceita so nome simples em minusculas: letras `a-z`, digitos e `_` (ex. "teste", "camaleao_2").
## - ausente (`null`), nao-String, vazio, maiusculas, espaco, simbolos: "".
## Que o nome exista no registro e decisao da Stage (nome desconhecido nao ativa nada).

const PADRAO_VALIDO: String = "^[a-z][a-z0-9_]*$"

static var _regex: RegEx = null


static func decide(raw: Variant, is_debug: bool) -> String:
	if not is_debug or not (raw is String):
		return ""
	var texto: String = raw
	if _regex == null:
		_regex = RegEx.create_from_string(PADRAO_VALIDO)
	if _regex.search(texto) == null:
		return ""
	return texto


## Le o parametro `powerup`. Release: null. Web debug: query string (String, ou null se ausente).
## Nativo debug: argumento de usuario `-- --powerup=teste` via `DebugArgs.fonte`; sem tocar `JavaScriptBridge`.
static func read_raw() -> Variant:
	if not OS.is_debug_build():
		return null
	if OS.has_feature("web"):
		return JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('powerup')", true)
	return DebugArgs.fonte(false, true, OS.get_cmdline_user_args(), "powerup")
