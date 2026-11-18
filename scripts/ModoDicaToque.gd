class_name ModoDicaToque
extends RefCounted

## Decide se a dica de toque esta forcada (smoke debug) a partir do valor bruto do parametro `?dica=`.
## `decide` e puro: nao le o ambiente nem a arvore de cena; o chamador passa o valor bruto e a flag de build.
## `read_raw` e a unica leitura do ambiente (fina, isolada do decisor): so no web le a query string.
##
## Saida: `bool` (vira `Global.toque_detectado`, o que liga a dica sem dispositivo de toque).
## - build release (`is_debug` falso): sempre `false`, mesmo com "1" (producao ignora `?dica=`).
## - so o texto exato "1" liga; ausente (`null`), nao-String, vazio, "0", "true", " 1", "11", "-1": `false`.

const VALOR_LIGADO: String = "1"


static func decide(raw: Variant, is_debug: bool) -> bool:
	if not is_debug or not (raw is String):
		return false
	var texto: String = raw
	return texto == VALOR_LIGADO


## Le o parametro `dica`. Release: null. Web debug: query string (String, ou null se ausente).
## Nativo debug: argumento de usuario `-- --dica=1` via `DebugArgs.fonte`; sem tocar `JavaScriptBridge`.
static func read_raw() -> Variant:
	if not OS.is_debug_build():
		return null
	if OS.has_feature("web"):
		return JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('dica')", true)
	return DebugArgs.fonte(false, true, OS.get_cmdline_user_args(), "dica")
