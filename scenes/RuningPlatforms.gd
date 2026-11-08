extends Node2D

# Gerador de grupos de plataformas em movimento

# Prefab da plataforma para instanciar
const pre_platform = preload("res://scenes/Platform.tscn")

# Tipo de plataforma que este gerador cria (definido no editor)
@export var platform_type = Enums.PLATFORM_TYPE.STATIC # (Enums.PLATFORM_TYPE)

# Referencias aos nós filhos
@onready var generate_timer = $Timer
@onready var check_generate = $CheckGenerate

# Velocidade de movimento das plataformas geradas
var speed = 0

# Inicializa o gerador de plataformas
func _ready():
	speed = 60  # Velocidade fixa (antes era aleatória)
	
	# Resolve tipos de plataforma aleatórios
	if platform_type == Enums.PLATFORM_TYPE.RANDOM_ALL:
		var platform_types = [Enums.PLATFORM_TYPE.STATIC, 
							  Enums.PLATFORM_TYPE.MOVE_TO_LEFT, 
							  Enums.PLATFORM_TYPE.MOVE_TO_RIGHT]
		platform_types.shuffle()
		platform_type = platform_types.pop_front()
	
	if platform_type == Enums.PLATFORM_TYPE.RANDOM_DIRECTION:
		var platform_types = [Enums.PLATFORM_TYPE.MOVE_TO_LEFT, 
							  Enums.PLATFORM_TYPE.MOVE_TO_RIGHT]
		platform_types.shuffle()
		platform_type = platform_types.pop_front()
	
	# Configura comportamento baseado no tipo
	match platform_type:
		Enums.PLATFORM_TYPE.STATIC:
			create_static_platforms()
		Enums.PLATFORM_TYPE.MOVE_TO_LEFT:
			check_generate.position.x = -30
			speed *= -1  # Movimento para esquerda
			start_generate_timer()
		Enums.PLATFORM_TYPE.MOVE_TO_RIGHT:
			start_generate_timer()

# Define o tipo de plataforma que será gerada
func set_platform_type(type):
	platform_type = type

# Callback do timer - cria nova plataforma e para o timer
func _on_Timer_timeout():
	new_platform()
	generate_timer.stop()

# Cria um conjunto de 3 plataformas estáticas
func create_static_platforms():
	var position_x = 5
	for i in 3:
		var platform = pre_platform.instantiate()
		platform.set_color(Enums.get_random_color())
		platform.position.x = position_x
		platform.set_velocity(0)  # Plataformas estáticas não se movem
		add_child(platform)
		position_x += 85

# Cria uma nova plataforma em movimento
func new_platform():
	var platform = pre_platform.instantiate()
	platform.set_color(Enums.get_random_color())
	platform.position.x = check_generate.position.x
	platform.set_velocity(speed)
	add_child(platform)

# Inicia o timer para gerar próxima plataforma
func start_generate_timer():
	generate_timer.start(0.3)

# Gera nova plataforma quando a anterior sai da área
func _on_CheckGenerate_area_exited(_area):
	if platform_type != Enums.PLATFORM_TYPE.STATIC:
		start_generate_timer()

# Remove o gerador quando sai da tela
func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
