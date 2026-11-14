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


# Fisica do pulo lida do Player (nenhum literal novo): GRAVITY/JUMP_POWER por tick de fisica.
const PlayerFisica := preload("res://scenes/Player.gd")
# Teto de ticks simulados por tempo_de_pulo (10 s a 60 Hz); com scroll >= 0 o pulo sempre alcanca a linha antes disso.
const TICKS_MAXIMOS := 600
# Passo de amostragem da janela de uma cicladora (s): garante cor constante tambem no meio da janela.
const PASSO_JANELA_S := 0.05


# Segundos entre o pulo e o instante em que a linha de cima (ESPACAMENTO acima da de partida, descendo `scroll` px/s)
# alcanca o gecko. Simula tick a tick a fisica do Player: no tick i o gecko sobe (-JUMP_POWER - GRAVITY*i) / ticks por s.
static func tempo_de_pulo(scroll: float) -> float:
	var taxa: float = float(Engine.physics_ticks_per_second)
	var subida_por_taxa: float = 0.0
	var alvo: float = float(InitialRows.ESPACAMENTO)
	for tick in range(1, TICKS_MAXIMOS + 1):
		var velocidade_y: float = float(PlayerFisica.JUMP_POWER) + float(PlayerFisica.GRAVITY) * tick
		subida_por_taxa -= velocidade_y
		var t: float = float(tick) / taxa
		if subida_por_taxa / taxa + maxf(scroll, 0.0) * t >= alvo:
			return t
	return float(TICKS_MAXIMOS) / taxa


# Converte plataformas vivas em pares {y, x, cor} (posicao global). Ignora null, instancia liberada e `excluir`.
# Plataforma com ciclo de cor ganha tambem "ciclo" (PlatformColorCycle).
static func entradas_de_plataformas(plataformas: Array, excluir: Object = null) -> Array:
	var entradas: Array = []
	for p in plataformas:
		if p == null or not is_instance_valid(p) or p == excluir:
			continue
		var pos: Vector2 = p.global_position
		var entrada := {"y": pos.y, "x": pos.x, "cor": p.color}
		if p.has_method(&"obter_ciclo"):
			var ciclo: PlatformColorCycle = p.obter_ciclo()
			if ciclo != null:
				entrada["ciclo"] = ciclo
		entradas.append(entrada)
	return entradas


# Cores das entradas {y, x, cor[, ciclo]} da linha imediatamente acima de `y_ref` (y ~ y_ref - ESPACAMENTO) com x em [0, largura].
# Pura: sem arvore nem Global. Pode devolver cores repetidas e a cor atual do gecko (D4).
# Entrada com "ciclo": so contribui com a cor que vale em toda a janela [dt_chegada, dt_chegada + espera]; se a cor muda
# dentro dela, nao contribui. Sem ciclo (ou dt/espera padrao) = cor estatica, como antes.
static func coletar_cores_linha_acima(
	entradas: Array, y_ref: float, largura: float, dt_chegada: float = 0.0, espera: float = 0.0
) -> Array:
	var cores: Array = []
	var y_alvo: float = y_ref - InitialRows.ESPACAMENTO
	for e in entradas:
		if absf(float(e["y"]) - y_alvo) > TOLERANCIA_LINHA:
			continue
		var x: float = e["x"]
		if x < 0.0 or x > largura:
			continue
		var ciclo: Variant = e.get("ciclo")
		if ciclo == null:
			cores.append(e["cor"])
			continue
		var cor_janela: int = _cor_que_cobre_a_janela(ciclo, dt_chegada, espera)
		if cor_janela >= 0:
			cores.append(cor_janela)
	return cores


# Nova cor do gecko ao pousar em `atual` (null -> sem candidatas -> fallback de escolher_cor_gecko).
static func cor_no_pouso(
	plataformas: Array,
	atual: Platform,
	largura: float,
	rng: RandomNumberGenerator = null,
	dt_chegada: float = 0.0,
	espera: float = 0.0
) -> int:
	var candidatas: Array = []
	if atual != null and is_instance_valid(atual):
		var entradas: Array = entradas_de_plataformas(plataformas, atual)
		candidatas = coletar_cores_linha_acima(entradas, atual.global_position.y, largura, dt_chegada, espera)
	return escolher_cor_gecko(candidatas, rng)


# Janela K de uma cicladora: garante que a sequencia tenha a cor do gecko por >= 1 periodo (uma entrada = um periodo)
# enquanto a plataforma e alcancavel (ate `alcance_s`; <= 0 = a sequencia toda). Sequencia que ja tem a cor volta igual.
# Senao poe a cor do gecko no indice 1 (ou 0 se o alcance cobre so o periodo atual) e, se o vizinho seguinte ficar igual,
# troca o vizinho por outra cor: cada cor segue != da anterior. Devolve copia; nao altera o argumento.
static func forcar_cor_cicladora(
	sequencia: Array, cor_gecko: int, periodo: float, alcance_s: float = 0.0
) -> Array:
	var saida: Array = sequencia.duplicate()
	if saida.is_empty():
		return saida
	var indice_max: int = saida.size() - 1
	if alcance_s > 0.0 and periodo > 0.0:
		indice_max = clampi(int(ceil(alcance_s / periodo)) - 1, 0, saida.size() - 1)
	for i in range(0, indice_max + 1):
		if saida[i] == cor_gecko:
			return saida
	var alvo: int = mini(1, indice_max)
	saida[alvo] = cor_gecko
	var seguinte: int = alvo + 1
	if seguinte < saida.size() and saida[seguinte] == cor_gecko:
		var depois: int = saida[seguinte + 1] if seguinte + 1 < saida.size() else -1
		for cor in Enums.COLOR.values():
			if cor != cor_gecko and cor != depois:
				saida[seguinte] = cor
				break
	return saida


# Cor constante em [dt_chegada, dt_chegada + espera], ou -1 se muda dentro da janela.
static func _cor_que_cobre_a_janela(ciclo: Variant, dt_chegada: float, espera: float) -> int:
	var inicio: float = maxf(dt_chegada, 0.0)
	var fim: float = inicio + maxf(espera, 0.0)
	var cor: int = ciclo.cor_em(inicio)
	if ciclo.cor_em(fim) != cor:
		return -1
	var t: float = inicio + PASSO_JANELA_S
	while t < fim:
		if ciclo.cor_em(t) != cor:
			return -1
		t += PASSO_JANELA_S
	return cor


static func _tem_cor_na_janela(cor: int, anteriores: Array, tamanho: int) -> bool:
	var inicio: int = maxi(0, anteriores.size() - tamanho)
	for i in range(inicio, anteriores.size()):
		if anteriores[i] == cor:
			return true
	return false
