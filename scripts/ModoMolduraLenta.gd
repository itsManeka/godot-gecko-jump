class_name ModoMolduraLenta
extends RefCounted

## Decide se a moldura de subida de estagio (LevelUpFrame) pulsa em camera lenta (smoke debug) a partir do valor
## bruto do parametro `?moldura=`. Decisor distinto do modo fixa (`ModoMolduraFixa`): os modos sao exclusivos
## ("fixa" nao liga `lenta` e "lenta" nao liga `fixa`). O nome do parametro e contrato para os roteiros de smoke:
## nao renomear. `decide` e puro: nao le o ambiente nem a arvore de cena; o chamador passa o valor bruto e a flag
## de build. `read_raw` e a unica leitura do ambiente (fina, isolada do decisor): so no web debug le a query string.
##
## Saida: `bool`.
## - build release (`is_debug` falso): sempre false, mesmo com "lenta" (producao ignora `?moldura=`).
## - debug: true so com o texto exato "lenta"; ausente (`null`), nao-String ou outro texto: false.


static func decide(raw: Variant, is_debug: bool) -> bool:
	if not is_debug or not (raw is String):
		return false
	var texto: String = raw
	return texto == "lenta"


## Le o parametro `moldura` (o mesmo do modo fixa; o texto decide o modo). Release: null. Web debug: query string
## (String, ou null se ausente). Nativo debug: argumento de usuario `-- --moldura=lenta` via `DebugArgs.fonte`;
## sem tocar `JavaScriptBridge`.
static func read_raw() -> Variant:
	if not OS.is_debug_build():
		return null
	if OS.has_feature("web"):
		return JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('moldura')", true)
	return DebugArgs.fonte(false, true, OS.get_cmdline_user_args(), "moldura")
