class_name SeedPartida
extends RefCounted

# Fonte unica da validacao da seed da partida na borda da Stage (f528 T1). Sem arvore de cena: funcao pura.
# Aceita so TYPE_INT na faixa 0..SeedSource.MAX_SEED (reuso da constante, sem duplicar o limite). Qualquer
# outra coisa (String, mesmo numerica; float, mesmo inteiro como 5.0; bool; Array; Dictionary; nulo; negativo;
# acima do maximo) devolve null = sem seed: a partida sorteia como hoje, nunca int("abc") nem 0 espurio.


# Devolve o proprio int quando valido; null quando invalido.
static func validar(valor: Variant) -> Variant:
	if typeof(valor) != TYPE_INT:
		return null
	if valor < 0 or valor > SeedSource.MAX_SEED:
		return null
	return valor
