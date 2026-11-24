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
# (f530 T2) Cache da meia-largura do corpo do gecko (shape de colisao do Player, lida uma vez): negativa ate a
# primeira leitura de _meia_largura_corpo().
static var _cache_meia_corpo: float = -1.0


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
# Plataforma com ciclo de cor ganha tambem "ciclo" (PlatformColorCycle); com piscar, "pisca" (PlatformBlink).
# Estado solido/visivel/movel para o alvo da Segunda chance (f526 T3 e correcao 1 do PASSO 6.5): toda entrada
# ganha "desmoronada", "desmoronando", "pisca_oculta" e "movel" (falso em objeto sem o membro/metodo, ex. fake de
# teste; movel = Platform.speed != 0 — sai de baixo do gecko, que nao e carregado) e a "plataforma" de origem (o
# chamador resolve o no escolhido sem casar posicao). So chaves acrescentadas: nenhum filtro muda aqui.
# f530 T2: toda entrada ganha tambem "vx" (velocidade horizontal vigente, -speed + desvio_vx de
# Platform._physics_process; 0 em objeto sem "speed") para o chamador prever o x na chegada do pulo.
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
		if p.has_method(&"obter_pisca"):
			var pisca: PlatformBlink = p.obter_pisca()
			if pisca != null:
				entrada["pisca"] = pisca
		entrada["desmoronada"] = p.get("desmoronada") == true
		entrada["desmoronando"] = p.esta_desmoronando() if p.has_method(&"esta_desmoronando") else false
		entrada["pisca_oculta"] = p.esta_pisca_oculta() if p.has_method(&"esta_pisca_oculta") else false
		entrada["movel"] = p.get("speed") != null and float(p.get("speed")) != 0.0
		# f530 T2: velocidade horizontal vigente (a de Platform._physics_process: -speed + desvio_vx) para o
		# chamador prever o x na chegada; 0 em objeto sem "speed"/"desvio_vx" (ex. fake de teste).
		var vx: float = 0.0
		if p.get("speed") != null:
			vx = -float(p.get("speed"))
			if p.get("desvio_vx") != null:
				vx += float(p.get("desvio_vx"))
		entrada["vx"] = vx
		entrada["plataforma"] = p
		entradas.append(entrada)
	return entradas


# Cores das entradas {y, x, cor[, ciclo]} da linha imediatamente acima de `y_ref` (y ~ y_ref - ESPACAMENTO) com x em [0, largura].
# Pura: sem arvore nem Global. Pode devolver cores repetidas e a cor atual do gecko (D4).
# Entrada com "ciclo": so contribui com a cor que vale em toda a janela [dt_chegada, dt_chegada + espera]; se a cor muda
# dentro dela, nao contribui. Entrada com "pisca": so contribui se a plataforma esta visivel em toda a mesma janela
# (invisivel = sem colisao, nao serve de apoio). Com ciclo e pisca juntos vale a conjuncao. Sem ciclo/pisca (ou dt/espera
# padrao) = cor estatica, como antes. O filtro de janela vive em _cor_na_janela, compartilhado com alvos_da_linha_acima
# (f530 T2): o alvo do pouso reto herda a mesma elegibilidade, somando a cor do gecko.
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
		var cor: int = _cor_na_janela(e, dt_chegada, espera)
		if cor < 0:
			continue
		cores.append(cor)
	return cores


# (f530 T2) Alvos do pouso reto: as entradas da linha imediatamente acima de `y_ref` que servem de apoio ao
# gecko de cor `cor` na janela de chegada [dt_chegada, dt_chegada + espera] — o MESMO filtro de y, x, ciclo e
# pisca de coletar_cores_linha_acima (a elegibilidade vive em _cor_na_janela, compartilhada) somado a cor igual
# a do gecko — com o x previsto na chegada: x + "vx" * dt_chegada (chave que entradas_de_plataformas acrescenta;
# entrada sem ela vale 0). Devolve {x, cor} por alvo, na ordem das entradas. Pura: sem arvore nem Global; as
# entradas excluem a plataforma atual (quem chama monta como em cor_no_pouso).
static func alvos_da_linha_acima(
	entradas: Array, y_ref: float, cor: int, largura: float, dt_chegada: float = 0.0, espera: float = 0.0
) -> Array:
	var alvos: Array = []
	var y_alvo: float = y_ref - InitialRows.ESPACAMENTO
	for e in entradas:
		if absf(float(e["y"]) - y_alvo) > TOLERANCIA_LINHA:
			continue
		var x: float = e["x"]
		if x < 0.0 or x > largura:
			continue
		var cor_entrada: int = _cor_na_janela(e, dt_chegada, espera)
		if cor_entrada < 0 or cor_entrada != cor:
			continue
		alvos.append({"x": x + float(e.get("vx", 0.0)) * dt_chegada, "cor": cor_entrada})
	return alvos


# (f530 T2) Reducao dos alvos a {alinhado: bool, dx: int} para o gecko em `x_gecko`: o dx (px, com sinal) e o da
# elegivel mais proxima pelo caminho curto no mundo que wrapa em PlayArea.LARGURA (a aritmetica do wrap_x do
# Player, Player.gd:139: gecko em 170 contra alvo em 10 e +20, nao -160; empate exato fica com a 1a da ordem);
# alinhado quando |dx| fica abaixo da soma da meia-largura do apoio (MovingRowFill.SEMI_PLATAFORMA) com a
# meia-largura do corpo do gecko (lida do shape do Player). Sem alvo: {alinhado: false, dx: 0}.
static func alinhamento_do_alvo(alvos: Array, x_gecko: float) -> Dictionary:
	var dx: float = 0.0
	var menor_abs: float = INF
	for a in alvos:
		var dx_a: float = _dx_com_wrap(x_gecko, float(a["x"]))
		var dx_abs: float = absf(dx_a)
		if dx_abs < menor_abs:
			menor_abs = dx_abs
			dx = dx_a
	return {"alinhado": menor_abs < _limiar_de_alinhamento(), "dx": roundi(dx)}


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


# Cor que a entrada tem na janela de chegada [dt_chegada, dt_chegada + espera]: -1 se a cicladora troca de cor
# dentro dela ou a piscante fica invisivel em parte. Compartilhada por coletar_cores_linha_acima e
# alvos_da_linha_acima (f530 T2): o alvo herda o mesmo filtro sem duplicar a regra.
static func _cor_na_janela(e: Dictionary, dt_chegada: float, espera: float) -> int:
	var cor: int = e["cor"]
	var ciclo: Variant = e.get("ciclo")
	if ciclo != null:
		cor = _cor_que_cobre_a_janela(ciclo, dt_chegada, espera)
		if cor < 0:
			return -1
	var pisca: PlatformBlink = e.get("pisca")
	if pisca != null and not pisca.visivel_na_janela(dt_chegada, dt_chegada + espera):
		return -1
	return cor


# Dx com sinal do alvo ao gecko pelo caminho curto no mundo que wrapa em PlayArea.LARGURA (o mesmo valor do
# wrap_x do Player, Player.gd:139: quem cruza a borda reaparece do lado oposto). |dx| ate meia largura volta
# inalterado, sem aritmetica: a borda exata do limiar de alinhamento nao depende de erro de float.
static func _dx_com_wrap(x_gecko: float, x_alvo: float) -> float:
	var largura: float = float(PlayArea.LARGURA)
	var dx: float = x_alvo - x_gecko
	if dx > largura * 0.5:
		return dx - largura
	if dx < -largura * 0.5:
		return dx + largura
	return dx


# Limiar de alinhamento do pouso reto: meia-largura do apoio + meia-largura do corpo do gecko (sem literal novo).
static func _limiar_de_alinhamento() -> float:
	return float(MovingRowFill.SEMI_PLATAFORMA) + _meia_largura_corpo()


# Meia-largura do corpo do gecko, lida do shape de colisao da cena do Player (instancia fora da arvore, so para
# ler o shape; cacheada na 1a chamada). O shape e um retangulo centrado com rotacao PI: a largura e invariante.
static func _meia_largura_corpo() -> float:
	if _cache_meia_corpo < 0.0:
		var cena: PackedScene = load("res://scenes/Player.tscn")
		var player: Node = cena.instantiate()
		var forma: RectangleShape2D = (
			player.get_node("CollisionShape2D") as CollisionShape2D
		).shape as RectangleShape2D
		_cache_meia_corpo = forma.size.x / 2.0
		player.free()
	return _cache_meia_corpo


static func _tem_cor_na_janela(cor: int, anteriores: Array, tamanho: int) -> bool:
	var inicio: int = maxi(0, anteriores.size() - tamanho)
	for i in range(inicio, anteriores.size()):
		if anteriores[i] == cor:
			return true
	return false
