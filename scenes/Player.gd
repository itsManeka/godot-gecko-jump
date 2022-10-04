extends KinematicBody2D

signal add_point

const SPEED = 80
const GRAVITY = 10
const JUMP_POWER = -250
const FLOOR = Vector2(0, -1)

export(Enums.COLOR) var color

onready var sprite = $Sprite
onready var collision = $CollisionShape2D
onready var detector = $DetectorPlataforma/CollisionShape2D
onready var jumpaudio = $JumpAudio

var velocity = Vector2()
var on_ground = false
var can_change_color = false
var actual_platform : Platform = null
var jumping = true
var end = false

func _ready():
	sprite.modulate = Enums.get_cor(color)

func _physics_process(_delta):
	if end || !Global.is_iniciado():
		return
		
	if is_on_floor() && can_change_color:
		can_change_color = false
		change_color_random()
		emit_signal("add_point")
		
	if Input.is_action_pressed("ui_right"):
		velocity.x = SPEED
		sprite.flip_h = false
		if on_ground:
			sprite.play("run")
	elif Input.is_action_pressed("ui_left"):
		velocity.x = -SPEED
		sprite.flip_h = true
		if on_ground:
			sprite.play("run")
	else:
		velocity.x = 0
		if on_ground:
			sprite.play("idle")
	
	if (position.x > 180 && velocity.x > 0) || \
	   (position.x < 0 && velocity.x < 0):
		velocity.x = 0
		
	if Input.is_action_pressed("jump"):
		if on_ground:
			jumpaudio.play()
			velocity.y = JUMP_POWER
			on_ground = false
		
	velocity.y += GRAVITY
	
	if is_on_floor():
		on_ground = true
		jumping = false
	else:
		on_ground = false
		if velocity.y < 0:
			sprite.play("jump")
			jumping = true
			actual_platform = null
			Global.player_color_changed(color, actual_platform)
		else:
			jumping = false
			sprite.play("fall")
	
	velocity = move_and_slide(velocity, FLOOR)

func _on_DetectorPlataforma_body_entered(_body):
	if _body is Platform:
		actual_platform = _body
		can_change_color = true

func set_color(new_color):
	color = new_color
	sprite.modulate = Enums.get_cor(color)
	Global.player_color_changed(color, actual_platform)
	
func change_color_random():
	set_color(Enums.get_random_color())

func is_jumping() -> bool:
	return jumping

func is_end() -> bool:
	return end

func lose_game():
	end = true
	collision.call_deferred("set_disabled", true)
	detector.call_deferred("set_disabled", true)
	sprite.play("lose")
