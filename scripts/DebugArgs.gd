class_name DebugArgs
extends RefCounted

## Le os argumentos de usuario do Godot nativo (`godot ... -- --nome=valor`) para os parametros de debug.
## `find` e `fonte` sao puros: recebem a lista e o nome, nao leem o ambiente.
## `fonte` decide a origem: so em build debug fora do web le os args; release e web devolvem null sem ler.
## Os `read_raw` dos 5 decisores passam `OS.get_cmdline_user_args()` a `fonte`.
##
## Saida: `String` com o valor de `--nome=valor` (`--nome` sem valor vira `""`, paridade com `?nome` do web),
## ou `null` se ausente. Casa o nome exato (`--seed` nao casa `--seedx` nem `--seed2=1`); o valor e tudo
## depois do primeiro `=` (`--a=b=c` -> `b=c`); repeticao: vale o primeiro; argumento sem `--` e ignorado.


## Valor de `--nome=valor` ou `""` para `--nome`; `null` se nao houver o argumento.
static func find(args: PackedStringArray, nome: String) -> Variant:
	var prefixo: String = "--" + nome + "="
	var nu: String = "--" + nome
	for arg in args:
		if arg.begins_with(prefixo):
			return arg.substr(prefixo.length())
		if arg == nu:
			return ""
	return null


## Decisor da origem: web ou release nao leem args de usuario (null); nativo debug le via `find`.
static func fonte(is_web: bool, is_debug: bool, args: PackedStringArray, nome: String) -> Variant:
	if is_web or not is_debug:
		return null
	return find(args, nome)
