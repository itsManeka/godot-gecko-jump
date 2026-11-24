class_name ModoDiaInicial
extends RefCounted

## Decide o dia forcado do Desafio diario (smoke debug) a partir do valor bruto do parametro `?dia=<int>`.
## O nome do parametro e contrato para os roteiros de smoke: nao renomear.
## `decide` e puro: nao le o ambiente; o chamador passa o valor bruto e a flag de build.
## `read_raw` e a unica leitura do ambiente.
##
## Saida: `int` = dia UTC forcado (0..SeedSource.MAX_SEED), ou SEM_OVERRIDE = sem override (relogio real).
## - build release (`is_debug` falso): sempre SEM_OVERRIDE.
## - ausente (`null`), nao-String, vazio, nao inteiro (`abc`, `5.5`, `+5`), negativo ou acima de
##   SeedSource.MAX_SEED: SEM_OVERRIDE. Texto com mais de 10 caracteres e rejeitado antes do parse (sem overflow).

const SEM_OVERRIDE := -1
const TAMANHO_MAXIMO := 10


static func decide(raw: Variant, is_debug: bool) -> int:
	if not is_debug or not (raw is String):
		return SEM_OVERRIDE
	var texto: String = raw
	# O primeiro caractere tem de ser digito: sem sinal (`+5`) e sem espaco.
	if texto.is_empty() or texto.length() > TAMANHO_MAXIMO or not texto[0].is_valid_int() or not texto.is_valid_int():
		return SEM_OVERRIDE
	var valor: int = texto.to_int()
	if valor < 0 or valor > SeedSource.MAX_SEED:
		return SEM_OVERRIDE
	return valor


## Le o parametro `dia`. Release: null. Web debug: query string (String, ou null se ausente).
## Nativo debug: argumento de usuario `-- --dia=5` via `DebugArgs.fonte`; sem tocar `JavaScriptBridge`.
static func read_raw() -> Variant:
	if not OS.is_debug_build():
		return null
	if OS.has_feature("web"):
		return JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('dia')", true)
	return DebugArgs.fonte(false, true, OS.get_cmdline_user_args(), "dia")
