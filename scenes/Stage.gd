extends Node2D

# Script principal que gerencia o fluxo do jogo

# Pontuação atual (inicia em -1 para começar em 0 no primeiro ponto)
var points = -1
# Estado se o jogo foi iniciado
var started = false

# Referencias aos nós da interface e jogo
@onready var animation = $AnimationPlayer
@onready var pointslabel = $CanvasLayer/Pontos
@onready var player = $Node2D/Player
@onready var playbutton = $CanvasLayer/Play
@onready var lastscore = $CanvasLayer/Last
@onready var bestscore = $CanvasLayer/Best
@onready var loseaudio = $LoseAudio

# Inicializa a tela do jogo
func _ready():
	# Atualiza displays de pontuação
	lastscore.text = "Last Score: " + str(Global.get_last_score())
	bestscore.text = "Best Score: " + str(Global.get_best_score())
	
	# Configura estado inicial
	Global.set_iniciado(false)
	player.visible = false
	player.add_point.connect(_on_player_add_point)

# Processa input para iniciar o jogo
func _process(delta):
	if not started:
		if Input.is_action_pressed("jump"):
			_on_Play_button_down()

# Detecta quando o jogador sai da área de jogo (perde)
func _on_CheckPlayer_body_exited(body):
	if !body.is_jumping() && !body.is_end():
		body.lose_game()
		loseaudio.play()
		Global.set_score(points)
		animation.play("lose_animation")

# Reinicia o jogo após a animação de perda
func _on_animation_end():
	get_tree().change_scene_to_file("res://scenes/Stage.tscn")

# Callback para quando o jogador ganha um ponto
func _on_player_add_point():
	add_point()

# Adiciona um ponto à pontuação e atualiza a interface
func add_point():
	points += 1
	pointslabel.text = str(points)

# Inicia o jogo escondendo menus e mostrando o jogador
func _on_Play_button_down():
	started = true
	playbutton.visible = false
	lastscore.visible = false
	bestscore.visible = false
	player.visible = true
	Global.set_iniciado(true)
