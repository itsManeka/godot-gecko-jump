extends Node2D

const pre_running_platform = preload("res://scenes/RuningPlatforms.tscn")

onready var running_platforms = $RunningPlatforms

var position_scrolled = 0

func _ready():
	pass

func _physics_process(delta):
	if !Global.is_iniciado():
		return
		
	var new_position = 20 * delta
	running_platforms.position.y += new_position
	position_scrolled += new_position

func create_new_running_platform():
	var running_platform = pre_running_platform.instance()
	running_platform.set_platform_type(Enums.PLATFORM_TYPE.RANDOM_ALL)
	running_platform.global_position = Vector2(0, (-10 - position_scrolled))
	
	running_platforms.call_deferred("add_child", running_platform)

func _on_CheckArea_area_exited(_area):
	create_new_running_platform()

func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
