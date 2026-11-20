class_name GameModesDebug
extends RefCounted

## Decide se o seletor de modos inclui o modo de teste (smoke e GUT) a partir do valor bruto do parametro `?modos=`.
## O nome do parametro e contrato para os roteiros de smoke: nao renomear.
## `decide` e puro: nao le o ambiente nem a arvore de cena; o chamador passa o valor bruto e a flag de build.
## `read_raw` e a unica leitura do ambiente (fina, isolada do decisor): so no web debug le a query string.
##
## Saida: `bool`. true so em build debug com o valor exato do id do modo de teste (`GameModeTeste.ID`).
## - build release (`is_debug` falso): sempre false, mesmo com o id (producao nunca expoe o modo de teste).
## - ausente (`null`), nao-String, vazio, maiusculas, espaco, qualquer outro valor: false.

static func decide(raw: Variant, is_debug: bool) -> bool:
	if not is_debug or not (raw is String):
		return false
	var texto: String = raw
	return texto == String(GameModeTeste.ID)


## Le o parametro `modos`. Release: null. Web debug: query string (String, ou null se ausente).
## Nativo debug: argumento de usuario `-- --modos=teste` via `DebugArgs.fonte`; sem tocar `JavaScriptBridge`.
static func read_raw() -> Variant:
	if not OS.is_debug_build():
		return null
	if OS.has_feature("web"):
		return JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('modos')", true)
	return DebugArgs.fonte(false, true, OS.get_cmdline_user_args(), "modos")
