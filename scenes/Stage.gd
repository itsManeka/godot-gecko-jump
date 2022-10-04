extends Node2D

var points = -1
var started = false

onready var animation = $AnimationPlayer
onready var pointslabel = $CanvasLayer/Pontos
onready var player = $Node2D/Player
onready var playbutton = $CanvasLayer/Play
onready var lastscore = $CanvasLayer/Last
onready var bestscore = $CanvasLayer/Best
onready var loseaudio = $LoseAudio

func _ready():
	lastscore.text = "Last Score: " + str(Global.get_last_score())
	bestscore.text = "Best Score: " + str(Global.get_best_score())
	
	Global.set_iniciado(false)
	player.visible = false
	player.connect("add_point", self, "_on_player_add_point")

func _process(delta):
	if not started:
		if Input.is_action_pressed("jump"):
			_on_Play_button_down()

func _on_CheckPlayer_body_exited(body):
	if !body.is_jumping() && !body.is_end():
		body.lose_game()
		loseaudio.play()
		Global.set_score(points)
		animation.play("lose_animation")

func _on_animation_end():
	get_tree().change_scene("res://scenes/Stage.tscn")

func _on_player_add_point():
	add_point()
	
func add_point():
	points += 1
	pointslabel.text = str(points)

func _on_Play_button_down():
	started = true
	playbutton.visible = false
	lastscore.visible = false
	bestscore.visible = false
	player.visible = true
	Global.set_iniciado(true)
