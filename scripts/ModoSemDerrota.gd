class_name ModoSemDerrota
extends RefCounted

## Decide se o modo sem derrota (smoke debug) esta ligado a partir do valor bruto do parametro `?semderrota=`.
## `decide` e puro: nao le o ambiente nem a arvore de cena; o chamador passa o valor bruto e a flag de build.
## `read_raw` e a unica leitura do ambiente (fina, isolada do decisor): so no web le a query string.
##
## Saida: `bool`.
## - build release (`is_debug` falso): sempre `false`, mesmo com "1" (producao ignora `?semderrota=`).
## - so o texto exato "1" liga; ausente (`null`), nao-String, vazio, "0", "true", " 1", "11", "-1": `false`.

const VALOR_LIGADO: String = "1"


static func decide(raw: Variant, is_debug: bool) -> bool:
	if not is_debug or not (raw is String):
		return false
	var texto: String = raw
	return texto == VALOR_LIGADO


## Le o parametro `semderrota` da query string. No web devolve o String (ou null se ausente);
## fora do web devolve null sem tocar `JavaScriptBridge`.
static func read_raw() -> Variant:
	if not OS.has_feature("web") or not OS.is_debug_build():
		return null
	return JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('semderrota')", true)
