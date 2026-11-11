extends Node2D

# Script principal que gerencia o fluxo do jogo

# Pontuação atual (inicia em -1 para começar em 0 no primeiro ponto)
var points = -1
# Estado se o jogo foi iniciado
var started = false
# Espessura da faixa de derrota (abaixo da borda inferior visivel)
const CHECK_THICKNESS: float = 20.0
# Medidas do HUD (as de 180x320 do Stage.tscn); y do menu relativo ao topo da safe area
const HUD_RIGHT_MARGIN: float = 2.0
const POINTS_WIDTH: float = 137.0
const POINTS_HEIGHT: float = 30.0
const PLAY_WIDTH: float = 56.0
const PLAY_TOP: float = 147.0
const PLAY_BOTTOM: float = 173.0
const LAST_TOP: float = 230.0
const LAST_BOTTOM: float = 247.0
const BEST_TOP: float = 248.0
const BEST_BOTTOM: float = 265.0
# Safe area (coordenadas logicas) da ultima apply_layout; usada pelo HUD (T4)
var safe_area: Rect2 = Rect2()

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

	# Layout a partir da area visivel real; refaz quando o viewport muda de tamanho
	# (stretch keep_width: so a altura varia, a largura fica em 180)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()

# Reaplica o layout com o tamanho/safe area atuais do viewport
func _on_viewport_size_changed() -> void:
	apply_layout(VisibleArea.visible_size(get_viewport()), VisibleArea.current_safe_rect(get_window()))

# Posiciona a faixa de derrota logo abaixo da borda inferior visivel (topo em y = altura, espessura 20)
# e com a largura visivel. Tamanho injetado: testavel sem janela. Chamavel de novo (resize em runtime).
# Sobrescreve a shape e a posicao literais da CollisionShape2D do Stage.tscn (a cena guarda so o valor de 180x320).
func apply_layout(visible_size: Vector2, safe: Rect2) -> void:
	safe_area = safe
	var shape := RectangleShape2D.new()
	shape.size = Vector2(visible_size.x, CHECK_THICKNESS)
	var collision: CollisionShape2D = $CheckPlayer/CollisionShape2D
	collision.shape = shape
	collision.position = Vector2(visible_size.x / 2.0, visible_size.y + CHECK_THICKNESS / 2.0)
	_layout_hud(visible_size, safe)

# HUD no topo da safe area: Pontos junto a borda direita visivel, menu com o y de 180x320 deslocado por safe.position.y
# e centrado na largura visivel. Posicao calculada do tamanho injetado (o pai Control so reflete o viewport real).
func _layout_hud(visible_size: Vector2, safe: Rect2) -> void:
	var top := safe.position.y
	var right := minf(visible_size.x, safe.end.x) - HUD_RIGHT_MARGIN
	_place(pointslabel, right - POINTS_WIDTH, top, right, top + POINTS_HEIGHT)
	var play_left := (visible_size.x - PLAY_WIDTH) / 2.0
	_place(playbutton, play_left, top + PLAY_TOP, play_left + PLAY_WIDTH, top + PLAY_BOTTOM)
	_place(lastscore, 0.0, top + LAST_TOP, visible_size.x, top + LAST_BOTTOM)
	_place(bestscore, 0.0, top + BEST_TOP, visible_size.x, top + BEST_BOTTOM)

func _place(control: Control, left: float, top: float, right: float, bottom: float) -> void:
	control.offset_left = left
	control.offset_top = top
	control.offset_right = right
	control.offset_bottom = bottom

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
