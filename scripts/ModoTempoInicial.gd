class_name ModoTempoInicial
extends RefCounted

## Decide a duracao do Contra o tempo (smoke debug) a partir do valor bruto do parametro `?tempo=<s>`.
## O nome do parametro e contrato para os roteiros de smoke: nao renomear.
## `decide` e puro: nao le o ambiente; o chamador passa o valor bruto e a flag de build.
## `read_raw` e a unica leitura do ambiente.
##
## Saida: `float` em segundos (> 0), ou 0.0 = sem override (usa o `.tres`).
## - build release (`is_debug` falso): sempre 0.0.
## - ausente (`null`), nao-String, nao numerico, 0, negativo, nao finito: 0.0.


static func decide(raw: Variant, is_debug: bool) -> float:
	if not is_debug or not (raw is String):
		return 0.0
	var texto: String = raw
	if not texto.is_valid_float():
		return 0.0
	var valor: float = texto.to_float()
	if is_nan(valor) or is_inf(valor) or valor <= 0.0:
		return 0.0
	return valor


## Le o parametro `tempo`. Release: null. Web debug: query string (String, ou null se ausente).
## Nativo debug: argumento de usuario `-- --tempo=5` via `DebugArgs.fonte`; sem tocar `JavaScriptBridge`.
static func read_raw() -> Variant:
	if not OS.is_debug_build():
		return null
	if OS.has_feature("web"):
		return JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('tempo')", true)
	return DebugArgs.fonte(false, true, OS.get_cmdline_user_args(), "tempo")
