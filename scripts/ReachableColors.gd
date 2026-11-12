class_name ReachableColors
extends RefCounted

# Cor alcancavel: (a) nova cor do gecko entre as candidatas da linha de cima; (b) cor de plataforma movel com janela de K.
# Sem arvore de cena: recebe tudo por parametro, testavel direto. Sem rng usa randi() global; com rng e deterministico.

# Janela das plataformas moveis: toda janela de K plataformas consecutivas (ordem de criacao) tem a cor do gecko.
# K vem do estagio da curva (DifficultyStage.k): K maior = a garantia fica mais rara; K <= 1 = toda movel da cor do gecko.
# Sem k explicito vale DifficultyStage.K_PADRAO.


# (a) Devolve uma das cores candidatas. Lista vazia (sem plataforma visivel acima) -> sorteio livre entre as cores de Enums.
static func escolher_cor_gecko(candidatas: Array, rng: RandomNumberGenerator = null) -> int:
	if candidatas.is_empty():
		return Enums.get_random_color(rng)
	var indice: int = (randi() if rng == null else rng.randi()) % candidatas.size()
	return candidatas[indice]


# (b) Cor de uma plataforma movel. Se nenhuma das K-1 ultimas de `anteriores` tem a cor do gecko, forca a cor do gecko;
# senao sorteia. Historico menor que K-1 (inicio da linha) conta como "nenhuma tem a cor".
static func cor_plataforma_movel(
	cor_gecko: int, anteriores: Array, rng: RandomNumberGenerator = null, k: int = DifficultyStage.K_PADRAO
) -> int:
	if k <= 1 or not _tem_cor_na_janela(cor_gecko, anteriores, k - 1):
		return cor_gecko
	return Enums.get_random_color(rng)


# (c) Coleta das cores candidatas do pouso: plataformas da linha imediatamente acima da linha de pouso.
# Tolerancia em px no y da linha de cima (as linhas ficam a InitialRows.ESPACAMENTO; a plataforma desliza so em x).
const TOLERANCIA_LINHA := 10.0


# Converte plataformas vivas em pares {y, x, cor} (posicao global). Ignora null, instancia liberada e `excluir`.
static func entradas_de_plataformas(plataformas: Array, excluir: Object = null) -> Array:
	var entradas: Array = []
	for p in plataformas:
		if p == null or not is_instance_valid(p) or p == excluir:
			continue
		var pos: Vector2 = p.global_position
		entradas.append({"y": pos.y, "x": pos.x, "cor": p.color})
	return entradas


# Cores das entradas {y, x, cor} da linha imediatamente acima de `y_ref` (y ~ y_ref - ESPACAMENTO) com x em [0, largura].
# Pura: sem arvore nem Global. Pode devolver cores repetidas e a cor atual do gecko (D4).
static func coletar_cores_linha_acima(entradas: Array, y_ref: float, largura: float) -> Array:
	var cores: Array = []
	var y_alvo: float = y_ref - InitialRows.ESPACAMENTO
	for e in entradas:
		if absf(float(e["y"]) - y_alvo) > TOLERANCIA_LINHA:
			continue
		var x: float = e["x"]
		if x < 0.0 or x > largura:
			continue
		cores.append(e["cor"])
	return cores


# Nova cor do gecko ao pousar em `atual` (null -> sem candidatas -> fallback de escolher_cor_gecko).
static func cor_no_pouso(
	plataformas: Array, atual: Platform, largura: float, rng: RandomNumberGenerator = null
) -> int:
	var candidatas: Array = []
	if atual != null and is_instance_valid(atual):
		var entradas: Array = entradas_de_plataformas(plataformas, atual)
		candidatas = coletar_cores_linha_acima(entradas, atual.global_position.y, largura)
	return escolher_cor_gecko(candidatas, rng)


static func _tem_cor_na_janela(cor: int, anteriores: Array, tamanho: int) -> bool:
	var inicio: int = maxi(0, anteriores.size() - tamanho)
	for i in range(inicio, anteriores.size()):
		if anteriores[i] == cor:
			return true
	return false
