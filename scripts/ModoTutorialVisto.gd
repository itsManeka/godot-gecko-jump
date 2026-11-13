class_name ModoTutorialVisto
extends RefCounted

## Decide se o tutorial da 1a partida esta forcado como visto (smoke debug) a partir do valor bruto do parametro `?tutorial=`.
## `decide` e puro: nao le o ambiente nem a arvore de cena; o chamador passa o valor bruto e a flag de build.
## `read_raw` e a unica leitura do ambiente (fina, isolada do decisor): so no web debug le a query string.
##
## Saida: `bool` (vira `Global.tutorial_visto_espelho`, so em memoria: nunca grava `tutorial/visto` no `.cfg`).
## - build release (`is_debug` falso): sempre `false`, mesmo com "visto" (producao ignora `?tutorial=`).
## - so o texto exato "visto" marca; ausente (`null`), nao-String, vazio, "1", "Visto", " visto": `false`.

const VALOR_MARCADO: String = "visto"


static func decide(raw: Variant, is_debug: bool) -> bool:
	if not is_debug or not (raw is String):
		return false
	var texto: String = raw
	return texto == VALOR_MARCADO


## Le o parametro `tutorial`. Release: null. Web debug: query string (String, ou null se ausente).
## Nativo debug: argumento de usuario `-- --tutorial=visto` via `DebugArgs.fonte`; sem tocar `JavaScriptBridge`.
static func read_raw() -> Variant:
	if not OS.is_debug_build():
		return null
	if OS.has_feature("web"):
		return JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('tutorial')", true)
	return DebugArgs.fonte(false, true, OS.get_cmdline_user_args(), "tutorial")
