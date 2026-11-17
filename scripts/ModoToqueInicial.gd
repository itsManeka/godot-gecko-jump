class_name ModoToqueInicial
extends RefCounted

## Decide o modo de toque forcado pelo parametro `?toque=` dos smokes (so debug): `a`, `b` ou `c`.
## O nome do parametro e contrato para os roteiros de smoke: nao renomear.
## `decide` e puro: nao le o ambiente nem grava nada; o chamador passa o valor bruto e a flag de build.
## `read_raw` e a unica leitura do ambiente (fina, isolada do decisor): so no web debug le a query string.
##
## Saida: `TouchMode.Modo` (0 = A, 1 = B, 2 = C) quando o parametro forca um modo, ou `SEM_FORCA` (-1) quando nao forca.
## - build release (`is_debug` falso): sempre SEM_FORCA, mesmo com "a" (producao ignora `?toque=`).
## - aceita so `a`, `b` ou `c` em minusculo (sem espaco, sem sufixo).
## - ausente (`null`), nao-String, vazio, maiuscula, outra letra, lista ("a|b"): SEM_FORCA.
## O modo forcado nao e gravado no store: quem aplica usa `Global.set_touch_mode(m, false)`.

const SEM_FORCA: int = -1

static func decide(raw: Variant, is_debug: bool) -> int:
	if not is_debug or not (raw is String):
		return SEM_FORCA
	var texto: String = raw
	match texto:
		"a":
			return TouchMode.Modo.A
		"b":
			return TouchMode.Modo.B
		"c":
			return TouchMode.Modo.C
	return SEM_FORCA


## Le o parametro `toque`. Release: null. Web debug: query string (String, ou null se ausente).
## Nativo debug: argumento de usuario `-- --toque=a` via `DebugArgs.fonte`; sem tocar `JavaScriptBridge`.
static func read_raw() -> Variant:
	if not OS.is_debug_build():
		return null
	if OS.has_feature("web"):
		return JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('toque')", true)
	return DebugArgs.fonte(false, true, OS.get_cmdline_user_args(), "toque")
