extends CharacterBody2D

# Sinal emitido quando o jogador ganha um ponto
signal add_point

# Constantes de movimento e física
const SPEED = 80                    # Velocidade horizontal do jogador
const GRAVITY = 10                  # Força da gravidade aplicada por frame
const JUMP_POWER = -250             # Força do pulo (negativa para ir para cima)
const GHOST_HALF_WIDTH = 16.0       # Meia largura visual do gecko (frame 32x32): o fantasma aparece quando ela cruza a borda

# Cor atual do jogador (definida no editor)
@export var color: Enums.COLOR = Enums.COR_INICIAL

# Referencias aos nós filhos
@onready var sprite = $AnimatedSprite2D
@onready var collision = $CollisionShape2D
@onready var detector = $DetectorPlataforma/CollisionShape2D
@onready var jumpaudio = $JumpAudio
@onready var ghost = $Ghost

# Variáveis de estado do jogador
var on_ground = false              # Se o jogador está no chão
var can_change_color = false       # Se pode mudar de cor na próxima plataforma
var actual_platform : Platform = null  # Plataforma atual em que o jogador está
var jumping = true                 # Se o jogador está pulando
var end = false                    # Se o jogo terminou para este jogador
var rng: RandomNumberGenerator = null  # Sorteio da cor no pouso; null usa o global (so teste fixa semente)

# Inicializa o jogador definindo sua cor inicial
func _ready():
	# Chao para cima e sem snap ao chao (floor_snap_length = 0): o movimento vertical nao e corrigido ao pousar
	up_direction = Vector2.UP
	motion_mode = MOTION_MODE_GROUNDED
	floor_snap_length = 0.0
	sprite.modulate = Enums.get_cor(color)

# Partida acabou (Stage liberada): a cor guardada em Global volta ao inicio antes da Stage seguinte gerar plataformas.
# O _ready do Player chegaria tarde: ScrollLevel/RunningPlatforms (antes dele na Stage) ja geram no proprio _ready.
func _exit_tree() -> void:
	Global.cor_gecko = Enums.COR_INICIAL

# Atualiza o fantasma a cada frame (tambem apos game over, quando a animacao "lose" troca sem physics)
func _process(_delta):
	_sync_ghost()

# Copia animacao, frame, flip e cor do sprite real; o fantasma so aparece do outro lado da borda (sem colisao)
func _sync_ghost() -> void:
	if ghost.animation != sprite.animation:
		ghost.animation = sprite.animation
	ghost.frame = sprite.frame
	ghost.flip_h = sprite.flip_h
	ghost.modulate = sprite.modulate
	if position.x < GHOST_HALF_WIDTH:
		ghost.position = Vector2(PlayArea.LARGURA, 0.0)
		ghost.visible = true
	elif position.x > PlayArea.LARGURA - GHOST_HALF_WIDTH:
		ghost.position = Vector2(-PlayArea.LARGURA, 0.0)
		ghost.visible = true
	else:
		ghost.visible = false

# Processa a física e input do jogador a cada frame
func _physics_process(_delta):
	# Para o movimento se o jogo acabou ou não iniciou
	if end || !Global.is_iniciado():
		return
	
	# Verifica se deve mudar de cor ao tocar uma nova plataforma
	if is_on_floor() && can_change_color:
		can_change_color = false
		# Avisa a plataforma do pouso (com a cor do pouso) antes de sortear a nova cor; liberada = sem aviso
		_descartar_plataforma_liberada()
		if actual_platform != null:
			actual_platform.notificar_pouso()
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
	position.x = wrap_x(position.x, PlayArea.LARGURA)

# Detecta quando o jogador entra em contato com uma plataforma
func _on_DetectorPlataforma_body_entered(_body):
	if _body is Platform:
		actual_platform = _body
		can_change_color = true

# Define uma nova cor para o jogador e atualiza a visualização
func set_color(new_color):
	color = new_color
	sprite.modulate = Enums.get_cor(color)
	_descartar_plataforma_liberada()
	Global.player_color_changed(color, actual_platform)

# Plataforma liberada (saiu da tela) vira null: parametro tipado recusa objeto liberado antes de qualquer checagem
func _descartar_plataforma_liberada() -> void:
	if not is_instance_valid(actual_platform):
		actual_platform = null

# Muda a cor do jogador para uma cor aleatória
func change_color_random():
	_descartar_plataforma_liberada()
	if Global.sem_derrota:
		# Modo sem derrota (smoke debug): sem sorteio, a cor fica COR_INICIAL
		set_color(Enums.COR_INICIAL)
		return
	set_color(ReachableColors.cor_no_pouso(Global.platforms, actual_platform, PlayArea.LARGURA, rng))

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
