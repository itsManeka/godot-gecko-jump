extends Node2D

# Sistema que gerencia o scroll infinito do level e geração de plataformas

# Prefab do gerador de plataformas em movimento
const pre_running_platform = preload("res://scenes/RunningPlatforms.tscn")

# Container que armazena todos os geradores de plataforma
@onready var running_platforms = $RunningPlatforms

# Distância total que o nível scrollou (para posicionar novas plataformas)
var position_scrolled = 0

# Dificuldade da partida (atribuida pela Stage em _ready); null = estagio 0 (cena isolada)
var dificuldade: DifficultyState = null

# Foto vigente da dificuldade; sem estado injetado = estagio 0
func _snapshot() -> DifficultySnapshot:
	if dificuldade == null:
		return DifficultySnapshot.new()
	return dificuldade.snapshot()

# Quantas linhas do fluxo já nasceram (uma a cada InitialRows.ESPACAMENTO px de scroll)
var _rows_spawned: int = 0

# Último y dos nós de linha do .tscn; abaixo dele nascem as linhas iniciais extras.
# Espelha o position.y do último RunningPlatforms em scenes/ScrollLevel.tscn: mover o nó exige mudar aqui
# (test_scroll_level_linhas_iniciais.gd acusa duplicata ou buraco pela contagem 7/9/10).
const ULTIMA_LINHA_TSCN := 190.0
const EPSILON := 0.0001

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
	# EPSILON absorve o erro de ponto flutuante da soma de delta (49.99999 contaria como 1 frame a menos)
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

	running_platforms.call_deferred("add_child", running_platform)

# Remove este nó quando sai completamente da tela
func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
