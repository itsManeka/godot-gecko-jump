extends Node2D

# Sistema que gerencia o scroll infinito do level e geração de plataformas

# Prefab do gerador de plataformas em movimento
const pre_running_platform = preload("res://scenes/RuningPlatforms.tscn")

# Container que armazena todos os geradores de plataforma
onready var running_platforms = $RunningPlatforms

# Distância total que o nível scrollou (para posicionar novas plataformas)
var position_scrolled = 0

# Inicialização (vazia por agora)
func _ready():
	pass

# Processa o scroll contínuo do nível
func _physics_process(delta):
	if !Global.is_iniciado():
		return
	
	# Calcula movimento de scroll baseado no delta time
	var new_position = 20 * delta
	running_platforms.position.y += new_position
	position_scrolled += new_position

# Cria um novo gerador de plataformas acima da tela
func create_new_running_platform():
	var running_platform = pre_running_platform.instance()
	running_platform.set_platform_type(Enums.PLATFORM_TYPE.RANDOM_ALL)
	# Posiciona o gerador acima da área visível
	running_platform.global_position = Vector2(0, (-10 - position_scrolled))
	
	running_platforms.call_deferred("add_child", running_platform)

# Callback quando uma área sai da zona de checagem (gera nova plataforma)
func _on_CheckArea_area_exited(_area):
	create_new_running_platform()

# Remove este nó quando sai completamente da tela
func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
