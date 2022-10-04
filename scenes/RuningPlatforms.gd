extends Node2D

const pre_platform = preload("res://scenes/Platform.tscn")

export(Enums.PLATFORM_TYPE) var platform_type = Enums.PLATFORM_TYPE.STATIC

onready var generate_timer = $Timer
onready var check_generate = $CheckGenerate

var speed = 0

func _ready():
	speed = 60#randi()%60+1
	
	if platform_type == Enums.PLATFORM_TYPE.RANDOM_ALL:
		var platform_types = [Enums.PLATFORM_TYPE.STATIC, \
							  Enums.PLATFORM_TYPE.MOVE_TO_LEFT, \
							  Enums.PLATFORM_TYPE.MOVE_TO_RIGHT]
		platform_types.shuffle()
		platform_type = platform_types.pop_front()
	
	if platform_type == Enums.PLATFORM_TYPE.RANDON_DIRECTION:
		var platform_types = [Enums.PLATFORM_TYPE.MOVE_TO_LEFT, \
							  Enums.PLATFORM_TYPE.MOVE_TO_RIGHT]
		platform_types.shuffle()
		platform_type = platform_types.pop_front()
	
	match platform_type:
		Enums.PLATFORM_TYPE.STATIC:
			create_static_platforms()
		Enums.PLATFORM_TYPE.MOVE_TO_LEFT:
			check_generate.position.x = -30
			speed *= -1
			start_generate_timer()
		Enums.PLATFORM_TYPE.MOVE_TO_RIGHT:
			start_generate_timer()

func set_platform_type(type):
	platform_type = type

func _on_Timer_timeout():
	new_platform()
	generate_timer.stop()

func create_static_platforms():
	var position_x = 5
	for i in 3:
		var platform = pre_platform.instance()
		platform.set_color(Enums.get_random_color())
		platform.position.x = position_x
		
		platform.set_speed(0)
		
		add_child(platform)
		
		position_x += 85

func new_platform():
	var platform = pre_platform.instance()
	platform.set_color(Enums.get_random_color())
	platform.position.x = check_generate.position.x
	
	platform.set_speed(speed)
	
	add_child(platform)

func start_generate_timer():
	generate_timer.start(0.3)

func _on_CheckGenerate_area_exited(_area):
	if platform_type != Enums.PLATFORM_TYPE.STATIC:
		start_generate_timer()

func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
