class_name Fundo
extends CanvasLayer

# Fundo de gameplay (f559 T5/T6): CanvasLayer abaixo do jogo (layer < 0) criado pela Stage.
# - Um grupo de sprites por bioma (e0..e3 = FundoBiomas.TEXTURAS), todos vivos e posicionados pelo MESMO offset:
#   - Ceu: 1 textura fixa no topo da tela (fator 0, sem offset, sem repeticao).
#   - Camadas c0/c1/c2 (360xH, H lido da textura): tiles repetidos ceil(H_tela/H_tex)+1 com wrap na altura da propria
#     textura, fatores de FundoParallax.FATORES.
# - O bioma ativo (`bioma`) segue o estagio da dificuldade (troca com crossfade de DURACAO_CROSSFADE, sem pulo de offset,
#   porque o offset e acumulado uma vez so, nunca por grupo). Sem ciclo por distancia; apos o ultimo estagio fica nele.
# - Zen (`sorteia_bioma`): sorteia 1 bioma ao iniciar a partida, sem crossfade, e o mantem (estagio nao troca).
#   O sorteio usa `rng` injetavel; sem ele, um RandomNumberGenerator proprio (ja nasce com seed aleatoria): nunca RNG global.
# O offset acumula o delta de ScrollLevel.position_scrolled (curva + avanco da camera) so com a partida iniciada, a
# arvore nao pausada e o scroll nao forcado a 0 (Zen); delta negativo ou zero nunca anda para tras.

const LAYER_FUNDO: int = -1
const LARGURA_TELA: float = 360.0
# Duracao do crossfade entre biomas (s)
const DURACAO_CROSSFADE: float = 1.2
# Tolerancia ao somar deltas fixos: a soma que chega a duracao (menos EPS) fecha o crossfade em 1/0 exatos
const EPS_CROSSFADE: float = 0.000001

# Bioma ativo (alvo do crossfade); indice em FundoBiomas
var bioma: int = 0
# Zen: sorteia o bioma no inicio da partida e o mantem (sem troca por estagio)
var sorteia_bioma: bool = false
# Fonte do sorteio do Zen (injetavel; null = RandomNumberGenerator proprio criado na 1a vez)
var rng: RandomNumberGenerator = null
# Dificuldade da partida (injetada pela Stage): bioma inicial = estagio vigente (inclui progresso_inicial)
var dificuldade: DifficultyState = null
# Scroll de onde o delta e lido (injetado pela Stage; null = fundo parado)
var scroll_level: ScrollLevel = null
# Scroll acumulado valido (px): so cresce
var acumulado: float = 0.0

# Por bioma: [ceu, c0, c1, c2]; vazio = FundoBiomas.TEXTURAS
var _tabela: Array = []
var _ultimo_scroll: float = 0.0
# Por bioma: o Sprite2D do ceu
var _ceus: Array = []
# Por bioma e por camada (c0, c1, c2): os Sprite2D dos tiles
var _tiles: Array = []
var _altura_tela: float = 0.0
# Opacidade de cada grupo (bioma)
var _alfa: Array[float] = []
var _fade_ativo: bool = false
var _fade_decorrido: float = 0.0
# Opacidades no instante em que o crossfade (ou a troca que o interrompeu) comecou
var _fade_de: Array[float] = []


func _init() -> void:
	layer = LAYER_FUNDO


func _ready() -> void:
	if _tabela.is_empty():
		_tabela = FundoBiomas.TEXTURAS
	if scroll_level != null:
		_ultimo_scroll = scroll_level.position_scrolled
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	reconstruir()
	_iniciar_bioma()


# Substitui a tabela por 1 so bioma [ceu, c0, c1, c2] (teste ou arte nova) e refaz os tiles, mantendo o offset
func definir_texturas(texturas: Array) -> void:
	_tabela = [texturas]
	bioma = 0
	if is_inside_tree():
		reconstruir()


func _process(delta: float) -> void:
	atualizar()
	avancar_crossfade(delta)


# Le o delta do scroll e acumula quando a partida esta ativa; sempre registra o ultimo valor lido (o scroll que
# andou parado/pausado/no Zen e descartado, nao volta como pulo depois)
func atualizar() -> void:
	if scroll_level == null:
		return
	var atual: float = scroll_level.position_scrolled
	var delta: float = atual - _ultimo_scroll
	_ultimo_scroll = atual
	if delta <= 0.0:
		return
	if not Global.is_iniciado() or get_tree().paused or is_zero_approx(scroll_level.fator_forcado):
		return
	acumulado += delta
	atualizar_posicoes()


func _on_viewport_size_changed() -> void:
	reconstruir()


# Liga ou desliga o sorteio do Zen (troca de modo no menu); so age quando o valor muda. Ligar sorteia na hora, desligar
# volta ao bioma do estagio vigente; nos dois casos sem crossfade.
func definir_sorteio(ativo: bool) -> void:
	if ativo == sorteia_bioma:
		return
	sorteia_bioma = ativo
	_iniciar_bioma()


# Subida de estagio em partida: troca o bioma com crossfade. No Zen o bioma e fixo na partida inteira.
func ao_mudar_estagio(novo: int) -> void:
	if sorteia_bioma:
		return
	trocar_bioma(novo)


# Troca o bioma ativo (alvo) com crossfade a partir das opacidades de agora; trocar durante um crossfade recomeca a
# duracao dali, entao nenhum grupo fica preso em alfa intermediario. Indice alem dos biomas vale o ultimo.
func trocar_bioma(novo: int) -> void:
	var alvo: int = _bioma_valido(novo)
	if alvo == bioma:
		return
	bioma = alvo
	_fade_de = _alfa.duplicate()
	_fade_decorrido = 0.0
	_fade_ativo = true


# Avanca o crossfade em `delta` segundos; ao chegar na duracao os grupos ficam em 1/0 exatos
func avancar_crossfade(delta: float) -> void:
	if not _fade_ativo:
		return
	_fade_decorrido += maxf(delta, 0.0)
	if _fade_decorrido >= DURACAO_CROSSFADE - EPS_CROSSFADE:
		_fixar_alfas()
		return
	var t: float = _fade_decorrido / DURACAO_CROSSFADE
	for g in range(_alfa.size()):
		var alvo: float = 1.0 if g == bioma else 0.0
		_alfa[g] = lerpf(_fade_de[g], alvo, t)
	_aplicar_alfas()


func crossfade_ativo() -> bool:
	return _fade_ativo


# Opacidade (0..1) do grupo do bioma (-1 = o ativo)
func opacidade(grupo: int = -1) -> float:
	return _alfa[_grupo_valido(grupo)]


# Offset (px, em [0, H_tex)) da camada 0..2 no grupo (-1 = bioma ativo); o scroll acumulado e o mesmo em todos os grupos
func offset_camada(indice: int, grupo: int = -1) -> float:
	var textura: Texture2D = _tabela[_grupo_valido(grupo)][indice + 1]
	return FundoParallax.offset(acumulado, FundoParallax.FATORES[indice], float(textura.get_height()))


func ceu(grupo: int = -1) -> Sprite2D:
	if _ceus.is_empty():
		return null
	return _ceus[_grupo_valido(grupo)]


func tiles_da_camada(indice: int, grupo: int = -1) -> Array:
	return _tiles[_grupo_valido(grupo)][indice]


# Retangulos (coordenadas da tela) dos tiles da camada, para conferir a cobertura
func retangulos_camada(indice: int, grupo: int = -1) -> Array[Rect2]:
	var retangulos: Array[Rect2] = []
	for tile: Sprite2D in _tiles[_grupo_valido(grupo)][indice]:
		retangulos.append(Rect2(tile.position, tile.texture.get_size()))
	return retangulos


# Refaz ceu e tiles de todos os grupos pela altura visivel atual e pelas texturas; o offset acumulado nao reinicia
func reconstruir() -> void:
	if _tabela.is_empty():
		return
	_altura_tela = VisibleArea.visible_size(get_viewport()).y
	for sprite: Sprite2D in _ceus:
		remove_child(sprite)
		sprite.queue_free()
	_ceus = []
	for camadas: Array in _tiles:
		for lista: Array in camadas:
			for tile: Sprite2D in lista:
				remove_child(tile)
				tile.queue_free()
	_tiles = []
	for texturas: Array in _tabela:
		_ceus.append(_novo_sprite(texturas[FundoBiomas.CEU]))
		var camadas: Array = []
		for indice in range(FundoParallax.FATORES.size()):
			var textura: Texture2D = texturas[indice + 1]
			var lista: Array = []
			for k in range(FundoParallax.quantidade_tiles(_altura_tela, float(textura.get_height()))):
				lista.append(_novo_sprite(textura))
			camadas.append(lista)
		_tiles.append(camadas)
	_normalizar_alfas()
	atualizar_posicoes()
	_aplicar_alfas()


# Posiciona o ceu (fixo no topo) e os tiles de cada camada de cada grupo pelo offset vigente
func atualizar_posicoes() -> void:
	if _ceus.is_empty():
		return
	for g in range(_tabela.size()):
		var ceu_g: Sprite2D = _ceus[g]
		ceu_g.position = Vector2.ZERO
		for indice in range(FundoParallax.FATORES.size()):
			var textura: Texture2D = _tabela[g][indice + 1]
			var altura: float = float(textura.get_height())
			var offset: float = FundoParallax.offset(acumulado, FundoParallax.FATORES[indice], altura)
			var k: int = 0
			for tile: Sprite2D in _tiles[g][indice]:
				tile.position = Vector2(0.0, FundoParallax.y_do_tile(offset, altura, k))
				k += 1


# Bioma do inicio da partida, sem crossfade: o sorteado (Zen) ou o estagio vigente (modos com estagio)
func _iniciar_bioma() -> void:
	var alvo: int = _sortear() if sorteia_bioma else _estagio_inicial()
	bioma = _bioma_valido(alvo)
	_fixar_alfas()


func _estagio_inicial() -> int:
	if dificuldade == null:
		return 0
	return dificuldade.estagio()


# 1 bioma de 0..N-1 pelo rng injetado (ou o proprio, criado na 1a vez)
func _sortear() -> int:
	if rng == null:
		rng = RandomNumberGenerator.new()
	return rng.randi_range(0, _tabela.size() - 1)


func _bioma_valido(indice: int) -> int:
	return clampi(indice, 0, maxi(_tabela.size() - 1, 0))


func _grupo_valido(grupo: int) -> int:
	return bioma if grupo < 0 else _bioma_valido(grupo)


# Opacidades 1/0 exatas (bioma ativo = 1) e fim do crossfade
func _fixar_alfas() -> void:
	_fade_ativo = false
	_fade_decorrido = 0.0
	for g in range(_alfa.size()):
		_alfa[g] = 1.0 if g == bioma else 0.0
	_aplicar_alfas()


# Mantem o vetor de opacidades do tamanho da tabela (tabela nova = recomeca em 1/0 no bioma ativo)
func _normalizar_alfas() -> void:
	bioma = _bioma_valido(bioma)
	if _alfa.size() == _tabela.size():
		return
	_alfa = []
	_fade_de = []
	for g in range(_tabela.size()):
		_alfa.append(1.0 if g == bioma else 0.0)
	_fade_ativo = false
	_fade_decorrido = 0.0


# Passa a opacidade de cada grupo aos sprites dele; opacidade 0 desliga o desenho
func _aplicar_alfas() -> void:
	for g in range(_ceus.size()):
		var alfa: float = _alfa[g]
		var sprites: Array = [_ceus[g]]
		for lista: Array in _tiles[g]:
			sprites.append_array(lista)
		for sprite: Sprite2D in sprites:
			sprite.modulate.a = alfa
			sprite.visible = alfa > 0.0


func _novo_sprite(textura: Texture2D) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = textura
	sprite.centered = false
	add_child(sprite)
	return sprite
