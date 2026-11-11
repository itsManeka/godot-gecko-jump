class_name SeedSource
extends RefCounted

## Decide a seed do RNG a partir do valor bruto do parametro (ex.: `?seed=N` no web).
## Puro: nao le o ambiente nem a arvore de cena; o chamador passa o valor bruto e a flag de build.
##
## Saida: `int` (seed) ou `null` (= sorteio livre, o chamador deve usar `randomize()`).
## - build release (`is_debug` falso): sempre `null`, mesmo com valor valido (producao ignora `?seed=`).
## - ausente (`null`), nao-String, vazio, com sinal, com espacos, com letra ou acima de MAX_SEED: `null`.
## - so digitos ASCII, ate MAX_DIGITOS caracteres, valor <= MAX_SEED: o inteiro (zero e valido).

const MAX_SEED: int = 2147483647
const MAX_DIGITOS: int = 10
const CODIGO_ZERO: int = 48
const CODIGO_NOVE: int = 57


static func decide(raw: Variant, is_debug: bool) -> Variant:
	if not is_debug or not (raw is String):
		return null
	var texto: String = raw
	if texto.is_empty() or texto.length() > MAX_DIGITOS:
		return null
	for i in texto.length():
		var codigo: int = texto.unicode_at(i)
		if codigo < CODIGO_ZERO or codigo > CODIGO_NOVE:
			return null
	var valor: int = texto.to_int()
	if valor > MAX_SEED:
		return null
	return valor
