class_name ModoMolduraFixa
extends RefCounted

## Decide se a moldura de subida de estagio (LevelUpFrame) fica acesa fixa (smoke debug) a partir do valor bruto do
## parametro `?moldura=`. O nome do parametro e contrato para os roteiros de smoke: nao renomear.
## `decide` e puro: nao le o ambiente nem a arvore de cena; o chamador passa o valor bruto e a flag de build.
## `read_raw` e a unica leitura do ambiente (fina, isolada do decisor): so no web debug le a query string.
##
## Saida: `bool`.
## - build release (`is_debug` falso): sempre false, mesmo com "fixa" (producao ignora `?moldura=`).
## - debug: true so com o texto exato "fixa"; ausente (`null`), nao-String ou outro texto: false.


static func decide(raw: Variant, is_debug: bool) -> bool:
	if not is_debug or not (raw is String):
		return false
	var texto: String = raw
	return texto == "fixa"


## Le o parametro `moldura`. Release: null. Web debug: query string (String, ou null se ausente).
## Nativo debug: argumento de usuario `-- --moldura=fixa` via `DebugArgs.fonte`; sem tocar `JavaScriptBridge`.
static func read_raw() -> Variant:
	if not OS.is_debug_build():
		return null
	if OS.has_feature("web"):
		return JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('moldura')", true)
	return DebugArgs.fonte(false, true, OS.get_cmdline_user_args(), "moldura")
