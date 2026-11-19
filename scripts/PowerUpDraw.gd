class_name PowerUpDraw
extends RefCounted

# Sorteio puro (sem cena) do tipo de power-up de uma plataforma. Devolve o nome do tipo ou &"" (vazio).
# Candidatos = tipos registrados em PowerUps com peso > 0 na curva do estagio.
# Raridade <= 0 ou sem candidato: vazio sem consumir o rng. Raridade >= 1: sempre um tipo (so a escolha
# do tipo consome o rng). Intervalo aberto (0, 1): 1 randf para a chance, depois 1 randf para o tipo.


static func sortear(rng: RandomNumberGenerator, snapshot: DifficultySnapshot) -> StringName:
	var raridade: float = snapshot.get_raridade_power_up()
	if raridade <= 0.0:
		return &""
	var pesos: Dictionary = snapshot.get_pesos_power_ups()
	var nomes: Array[StringName] = []
	var total: float = 0.0
	for nome: StringName in PowerUps.nomes():
		var peso: float = float(pesos.get(nome, 0.0))
		if peso > 0.0:
			nomes.append(nome)
			total += peso
	if nomes.is_empty():
		return &""
	if raridade < 1.0 and rng.randf() >= raridade:
		return &""
	var alvo: float = rng.randf() * total
	var acumulado: float = 0.0
	for nome: StringName in nomes:
		acumulado += float(pesos[nome])
		if alvo < acumulado:
			return nome
	return nomes[nomes.size() - 1]
