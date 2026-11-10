extends Node2D

# Sistema que gerencia o scroll infinito do level e geração de plataformas

# Prefab do gerador de plataformas em movimento
const pre_running_platform = preload("res://scenes/RunningPlatforms.tscn")

# Container que armazena todos os geradores de plataforma
@onready var running_platforms = $RunningPlatforms

# Distância total que o nível scrollou (para posicionar novas plataformas)
var position_scrolled = 0

# Quantas linhas do fluxo já nasceram (uma a cada InitialRows.ESPACAMENTO px de scroll)
var _rows_spawned: int = 0

# Último y dos nós de linha do .tscn; abaixo dele nascem as linhas iniciais extras
const ULTIMA_LINHA_TSCN := 190.0

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
	var new_position = 20 * delta
	running_platforms.position.y += new_position
	position_scrolled += new_position
	# Gatilho aritmético: uma linha a cada ESPACAMENTO px, sem depender de altura nem de colisão
	while position_scrolled >= InitialRows.ESPACAMENTO * (_rows_spawned + 1):
		create_new_running_platform(InitialRows.Y_TOPO - InitialRows.ESPACAMENTO * _rows_spawned)
		_rows_spawned += 1

# Cria um novo gerador de plataformas no y global dado (padrão: topo, acima da área visível)
func create_new_running_platform(y_global: float = InitialRows.Y_TOPO):
	var running_platform = pre_running_platform.instantiate()
	running_platform.set_platform_type(Enums.PLATFORM_TYPE.RANDOM_ALL)
	# running_platforms já desceu position_scrolled; compensa para o y global sair em y_global
	running_platform.global_position = Vector2(0, y_global - position_scrolled)

	running_platforms.call_deferred("add_child", running_platform)

# Remove este nó quando sai completamente da tela
func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
