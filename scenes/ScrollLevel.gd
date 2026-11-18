class_name ScrollLevel
extends Node2D

# Sistema que gerencia o scroll infinito do level e geração de plataformas

# Prefab do gerador de plataformas em movimento
const pre_running_platform = preload("res://scenes/RunningPlatforms.tscn")

# Container que armazena todos os geradores de plataforma
@onready var running_platforms = $RunningPlatforms

# Distância total que o nível scrollou (para posicionar novas plataformas)
var position_scrolled: float = 0.0

# Dificuldade da partida (atribuida pela Stage em _ready); null = estagio 0 (cena isolada)
var dificuldade: DifficultyState = null

# Seed da partida (int ou null): setada pela Stage ANTES de entrar na arvore (D1); null = partida sem
# seed, sorteio global como hoje. Nao toca Global: quem consome sao os rngs por linha, injetados via
# RowSeed pelo indice do y local de cada linha.
var semente: Variant = null

# Foto vigente da dificuldade; sem estado injetado = estagio 0
func _snapshot() -> DifficultySnapshot:
	return DifficultySnapshot.de(dificuldade)

# Quantas linhas do fluxo já nasceram (uma a cada InitialRows.ESPACAMENTO px de scroll)
var _rows_spawned: int = 0

# Último y dos nós de linha do .tscn; abaixo dele nascem as linhas iniciais extras.
# Espelha o position.y do último RunningPlatforms em scenes/ScrollLevel.tscn: mover o nó exige mudar aqui
# (test_scroll_level_linhas_iniciais.gd acusa duplicata ou buraco pela contagem 7/9/10).
const ULTIMA_LINHA_TSCN := 190.0
const EPSILON := 0.0001

# D1 (02-impact): as 5 linhas do .tscn entram na seed. _enter_tree roda antes do _ready de qualquer
# filho — o @onready running_platforms ainda nao existe, mas os nos do .tscn ja estao instanciados —,
# entao a semente setada antes do add_child chega a tempo: injeta os rngs nas linhas do .tscn antes
# do _ready delas.
func _enter_tree() -> void:
	var container: Node = get_node_or_null("RunningPlatforms")
	if container == null:
		return
	for linha in container.get_children():
		_injetar_rng_na_linha(linha)


# Injeta na linha os rngs do seu indice (canais layout e cor_movel da RowSeed) pelo y local, ANTES do
# add_child/_ready dela: a linha le tipo, mecanicas, cores e speed no _ready. Sem semente nao injeta
# nada (partida sem seed: sorteio global como hoje). ScrollLevel nao chama seed() nem randomize().
func _injetar_rng_na_linha(linha) -> void:
	if semente == null:
		return
	var indice: int = RowSeed.indice_do_y(linha.position.y)
	linha.rng = RowSeed.rng_layout(int(semente), indice)
	linha.rng_cor_movel = RowSeed.rng_cor_movel(int(semente), indice)

# Preenche a altura visível com linhas iniciais abaixo das 5 do .tscn.
# Limitação: redimensionar a janela durante a partida não preenche faixa nova (sem religar size_changed).
func _ready():
	var altura: float = VisibleArea.visible_size(get_viewport()).y
	for y in InitialRows.initial_row_ys(altura):
		if y <= ULTIMA_LINHA_TSCN:
			continue
		var linha = pre_running_platform.instantiate()
		linha.name = "Linha_%d" % int(y)
		linha.set_platform_type(Enums.PLATFORM_TYPE.RANDOM_ALL)
		linha.position = Vector2(0, y)
		# Rngs da seed ANTES do add_child: a linha sorteia tipo/mecanicas/cores no _ready
		_injetar_rng_na_linha(linha)
		running_platforms.add_child(linha)

# Processa o scroll contínuo do nível
func _physics_process(delta):
	if !Global.is_iniciado():
		return
	
	# Calcula movimento de scroll baseado no delta time
	var new_position: float = _snapshot().get_scroll() * delta
	running_platforms.position.y += new_position
	position_scrolled += new_position
	# Gatilho aritmético: uma linha a cada ESPACAMENTO px, sem depender de altura nem de colisão
	_criar_linhas_pendentes()

# Avanco da camera do topo (issue #46): o mundo sobe o quanto o gecko passou do limite, e o gecko continua no limite.
# Quem chama e a Stage, com prioridade de physics depois do Player (o y do gecko ja e o do frame, entao ele nao fica
# 1 frame acima do limite). Sem Player (cena isolada) ninguem chama: o scroll da curva segue identico ao de antes.
# O excesso soma em running_platforms.position.y, position_scrolled e no y global do gecko: a posicao relativa entre
# gecko e plataformas se mantem, e as linhas novas saem pelo mesmo gatilho aritmetico do scroll da curva.
func avancar_camera(player: Node2D, limite: float) -> void:
	if player == null or !Global.is_iniciado():
		return
	var excesso: float = CameraFollow.excesso(player.global_position.y, limite)
	if excesso <= 0.0:
		return
	running_platforms.position.y += excesso
	position_scrolled += excesso
	player.global_position.y += excesso
	_criar_linhas_pendentes()

# Cria as linhas que o scroll ja alcancou: uma a cada ESPACAMENTO px de position_scrolled, sem depender de altura nem de
# colisao. EPSILON absorve o erro de ponto flutuante da soma de delta (49.99999 contaria como 1 frame a menos)
func _criar_linhas_pendentes() -> void:
	while position_scrolled + EPSILON >= InitialRows.ESPACAMENTO * (_rows_spawned + 1):
		# Linha k em y local Y_TOPO - ESPACAMENTO*(k+1): com o scroll já em ESPACAMENTO*(k+1), nasce em y global Y_TOPO
		create_new_running_platform(InitialRows.Y_TOPO - InitialRows.ESPACAMENTO * (_rows_spawned + 1))
		_rows_spawned += 1

# Cria um novo gerador de plataformas no y local dado (filho de running_platforms).
# Sem argumento (NAN): nasce em y global Y_TOPO, acima da área visível, descontando o scroll já feito.
# O ramo NAN é usado por test/test_initial_color_stage.gd (chamada sem argumento): não remover.
func create_new_running_platform(y_local: float = NAN):
	var running_platform = pre_running_platform.instantiate()
	running_platform.set_platform_type(Enums.PLATFORM_TYPE.RANDOM_ALL)
	if is_nan(y_local):
		y_local = InitialRows.Y_TOPO - position_scrolled
	running_platform.position = Vector2(0, y_local)
	# Estado injetado ANTES do add_child (adiado): a linha le speed/proporcao/K no _ready
	running_platform.dificuldade = dificuldade
	# Rngs da seed pelo indice do y local ANTES do add_child adiado (o ramo NAN entra aqui com o y ja
	# resolvido); sem semente a injecao e no-op
	_injetar_rng_na_linha(running_platform)

	running_platforms.call_deferred("add_child", running_platform)

# Remove este nó quando sai completamente da tela
func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
