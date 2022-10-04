extends KinematicBody2D

class_name Platform

export var speed = 0
export(Enums.COLOR) var color

onready var sprite = $Sprite
onready var shape = $CollisionShape2D

func _ready():
	Global.add_platform(self)
	sprite.modulate = Enums.get_cor(color)
	
func _physics_process(_delta):
	if !Global.is_iniciado():
		return
		
	move_and_slide(Vector2(-speed, 0))
	
func set_speed(new_speed):
	speed = new_speed

func set_color(new_color):
	color = new_color

func get_color():
	return color

func player_color_changed(player_color):
	if player_color == color:
		shape.disabled = false
	else:
		shape.disabled = true

func _on_VisibilityNotifier2D_screen_exited():
	Global.remove_platform(self)
	queue_free()
