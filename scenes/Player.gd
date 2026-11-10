extends CharacterBody2D

# Sinal emitido quando o jogador ganha um ponto
signal add_point

# Constantes de movimento e física
const SPEED = 80                    # Velocidade horizontal do jogador
const GRAVITY = 10                  # Força da gravidade aplicada por frame
const JUMP_POWER = -250             # Força do pulo (negativa para ir para cima)
const SCREEN_WIDTH = 180            # Largura da tela em px: ponto unico do wrap (a F3 troca pela largura visivel)

# Cor atual do jogador (definida no editor)
@export var color: Enums.COLOR = Enums.COR_INICIAL

# Referencias aos nós filhos
@onready var sprite = $AnimatedSprite2D
@onready var collision = $CollisionShape2D
@onready var detector = $DetectorPlataforma/CollisionShape2D
@onready var jumpaudio = $JumpAudio

# Variáveis de estado do jogador
var on_ground = false              # Se o jogador está no chão
var can_change_color = false       # Se pode mudar de cor na próxima plataforma
var actual_platform : Platform = null  # Plataforma atual em que o jogador está
var jumping = true                 # Se o jogador está pulando
var end = false                    # Se o jogo terminou para este jogador

# Inicializa o jogador definindo sua cor inicial
func _ready():
	# Chao para cima e sem snap ao chao (floor_snap_length = 0): o movimento vertical nao e corrigido ao pousar
	up_direction = Vector2.UP
	motion_mode = MOTION_MODE_GROUNDED
	floor_snap_length = 0.0
	sprite.modulate = Enums.get_cor(color)

# Processa a física e input do jogador a cada frame
func _physics_process(_delta):
	# Para o movimento se o jogo acabou ou não iniciou
	if end || !Global.is_iniciado():
		return
	
	# Verifica se deve mudar de cor ao tocar uma nova plataforma
	if is_on_floor() && can_change_color:
		can_change_color = false
		change_color_random()
		emit_signal("add_point")
	
	# Processa movimento horizontal
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
	
	# Processa o pulo
	if Input.is_action_pressed("jump"):
		if on_ground:
			jumpaudio.play()
			velocity.y = JUMP_POWER
			on_ground = false
	
	# Aplica gravidade
	velocity.y += GRAVITY
	
	# Gerencia estado de chão e animações
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
	
	# Aplica o movimento
	move_and_slide()

	# Wrap horizontal: o centro que cruza uma borda reaparece do lado oposto (velocity intacta)
	position.x = wrap_x(position.x, SCREEN_WIDTH)

# Detecta quando o jogador entra em contato com uma plataforma
func _on_DetectorPlataforma_body_entered(_body):
	if _body is Platform:
		actual_platform = _body
		can_change_color = true

# Define uma nova cor para o jogador e atualiza a visualização
func set_color(new_color):
	color = new_color
	sprite.modulate = Enums.get_cor(color)
	Global.player_color_changed(color, actual_platform)

# Muda a cor do jogador para uma cor aleatória
func change_color_random():
	set_color(Enums.get_random_color())

# Retorna se o jogador está atualmente pulando
func is_jumping() -> bool:
	return jumping

# Retorna se o jogo terminou para este jogador
func is_end() -> bool:
	return end

# Termina o jogo para o jogador (quando perde)
func lose_game():
	end = true
	collision.call_deferred("set_disabled", true)
	detector.call_deferred("set_disabled", true)
	sprite.play("lose")

# Wrap horizontal puro: x > width volta por width; x < 0 entra por width; x em [0, width] nao muda
static func wrap_x(x: float, width: float) -> float:
	if x > width:
		return x - width
	if x < 0.0:
		return x + width
	return x
