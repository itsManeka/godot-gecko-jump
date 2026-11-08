extends CharacterBody2D

class_name Platform

# Velocidade de movimento da plataforma (negativa = esquerda)
@export var speed = 0
# Cor da plataforma (definida no editor)
@export var color # (Enums.COLOR)

# Referencias aos nós filhos
@onready var sprite = $Sprite2D
@onready var shape = $CollisionShape2D

# Inicializa a plataforma
func _ready():
	Global.add_platform(self)
	sprite.modulate = Enums.get_cor(color)

# Processa o movimento da plataforma
func _physics_process(_delta):
	if !Global.is_iniciado():
		return
	
	set_velocity(Vector2(-speed, 0))
	move_and_slide()

# Define a velocidade de movimento da plataforma
func set_velocity(new_speed):
	speed = new_speed

# Define a cor da plataforma
func set_color(new_color):
	color = new_color

# Retorna a cor atual da plataforma
func get_color():
	return color

# Ativa/desativa a colisão baseado na cor do jogador
func player_color_changed(player_color):
	if player_color == color:
		shape.disabled = false  # Jogador pode colidir (mesma cor)
	else:
		shape.disabled = true   # Jogador passa através (cor diferente)

# Remove a plataforma quando sai da tela
func _on_VisibilityNotifier2D_screen_exited():
	Global.remove_platform(self)
	queue_free()
