class_name ModoProgressoInicial
extends RefCounted

## Decide o progresso inicial da dificuldade (smoke debug) a partir do valor bruto do parametro `?progresso=`.
## O nome do parametro e contrato para os roteiros de smoke: nao renomear.
## `decide` e puro: nao le o ambiente nem a arvore de cena; o chamador passa o valor bruto e a flag de build.
## `read_raw` e a unica leitura do ambiente (fina, isolada do decisor): so no web debug le a query string.
##
## Saida: `float` em [0, 1].
## - build release (`is_debug` falso): sempre 0.0, mesmo com "0.5" (producao ignora `?progresso=`).
## - aceita so decimal simples de "0" a "1" (ex. "0.34", "0.7", "1", "1.0").
## - ausente (`null`), nao-String, vazio, negativo, acima de 1, letras, espaco, notacao cientifica: 0.0.

const PADRAO_VALIDO: String = "^(0(\\.[0-9]+)?|1(\\.0+)?)$"

static var _regex: RegEx = null


static func decide(raw: Variant, is_debug: bool) -> float:
	if not is_debug or not (raw is String):
		return 0.0
	var texto: String = raw
	if _regex == null:
		_regex = RegEx.create_from_string(PADRAO_VALIDO)
	if _regex.search(texto) == null:
		return 0.0
	return texto.to_float()


## Le o parametro `progresso`. Release: null. Web debug: query string (String, ou null se ausente).
## Nativo debug: argumento de usuario `-- --progresso=0.34` via `DebugArgs.fonte`; sem tocar `JavaScriptBridge`.
static func read_raw() -> Variant:
	if not OS.is_debug_build():
		return null
	if OS.has_feature("web"):
		return JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('progresso')", true)
	return DebugArgs.fonte(false, true, OS.get_cmdline_user_args(), "progresso")
