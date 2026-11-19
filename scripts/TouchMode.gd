class_name TouchMode
extends RefCounted

# Modos de toque selecionaveis nas Opcoes (issue #47): A (enum, nome "Flick") arrastar + flick; B (nome "Joy invisivel")
# dois polegares (padrao do dono, playtest). Enum e valor salvo seguem A/B; o nome e so apresentacao.
# Sem cena. Persistido no OptionsStore (secao "controle", chave "toque_modo") como int do enum.
# Ausente, corrompido, tipo errado, fracionario ou fora da faixa vale padrao() (B). O antigo C (valor 2) cai no padrao.

enum Modo { A, B }

const SECTION := "controle"
const KEY := "toque_modo"
# Nomes de apresentacao na ordem do enum (indice 0 = Modo.A, indice 1 = Modo.B). Nunca salvar o nome: o valor salvo e o int.
const NOMES := ["Flick", "Joy invisivel"]
# Default de leitura do store: ConfigFile.get_value com default null acusa ERROR; -1 cai no padrao em de_valor.
const SEM_VALOR := -1


static func padrao() -> Modo:
	return Modo.B


# Valida o valor lido do store. Aceita int na faixa do enum (e float de valor inteiro); o resto cai no padrao.
static func de_valor(valor: Variant) -> Modo:
	var t := typeof(valor)
	if t != TYPE_INT and t != TYPE_FLOAT:
		return padrao()
	var f := float(valor)
	if is_nan(f) or is_inf(f) or f != floorf(f):
		return padrao()
	var i := int(f)
	if i < 0 or i >= NOMES.size():
		return padrao()
	return i as Modo


# Nome de apresentacao do modo ("Flick", "Joy invisivel"). Valor fora da faixa devolve o nome do padrao().
static func nome(modo: int) -> String:
	if modo < 0 or modo >= NOMES.size():
		return NOMES[padrao()]
	return NOMES[modo]


# Texto do seletor e do card/dica: "Toque: " + nome(modo). Fonte unica do prefixo "Toque: ".
static func rotulo(modo: int) -> String:
	return "Toque: " + nome(modo)
