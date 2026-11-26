extends CharacterBody2D

# Sinal emitido quando o jogador ganha um ponto
signal add_point
# Sinal emitido quando o pouso coleta o power-up da plataforma (tipo vazio nunca viaja)
signal power_up_coletado(tipo)

# Constantes de movimento e física
const SPEED = 160                   # Velocidade horizontal do jogador
const GRAVITY = 20                  # Força da gravidade aplicada por frame
const JUMP_POWER = -500             # Força do pulo (negativa para ir para cima)
const GHOST_HALF_WIDTH = 32.0       # Meia largura visual do gecko (frame 64x64 a escala 1 = 64): o fantasma aparece quando ela cruza a borda
const ESPERA_MAXIMA_S = 0.6         # Quanto o gecko pode esperar apos o pouso na linha de cima e ainda ter a cor valida

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
var _guarda_reaparecimento := false  # f526 T4: o reaparecimento (Segunda chance) nao e pouso (Q2); segura o bloco de pouso mesmo com can_change_color rearmando, ate o proximo pulo
var rng: RandomNumberGenerator = null  # Sorteio da cor no pouso; null usa o global (so teste fixa semente)
var dificuldade: DifficultyState = null  # Injetada pela Stage (scroll vigente para a previsao); null = cena isolada
var power_up_estado: PowerUpState = null  # Injetado pela Stage (fator do scroll efetivo na previsao, f522 T4); null = neutro
# Fator forcado pela regra do modo (f527: Zen = 0.0), o mesmo que a Stage entrega ao ScrollLevel; 1.0 = neutro
var fator_scroll_forcado: float = 1.0

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
	
	# Verifica se deve mudar de cor ao tocar uma nova plataforma. A guarda do reaparecimento (f526 T4) vale mais
	# que can_change_color: o teleporte dispara o body_entered do DetectorPlataforma no frame fisico seguinte e
	# rearma a flag, mas o reaparecimento nao e pouso (Q2) - sem ponto, sem coleta e sem sorteio de cor.
	if is_on_floor() && can_change_color && !_guarda_reaparecimento:
		can_change_color = false
		# Avisa a plataforma do pouso (com a cor do pouso) antes de sortear a nova cor; liberada = sem aviso
		_descartar_plataforma_liberada()
		if actual_platform != null:
			# O pouso devolve o power-up da plataforma (coletado 1x, icone some); vazio = nao havia
			var tipo: StringName = actual_platform.notificar_pouso()
			if tipo != &"":
				power_up_coletado.emit(tipo)
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
			# f526 T4: o pulo derruba a guarda do reaparecimento - o pouso seguinte e pouso de verdade
			_guarda_reaparecimento = false
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
	# Janela de chegada: do pulo (dt_chegada, pelo scroll vigente) ate a espera maxima apos o pouso na linha de cima.
	# Sem dificuldade injetada (Player isolado) = dt 0 e sem espera: cor do instante do pouso, como antes.
	var dt_chegada: float = 0.0
	var espera: float = 0.0
	if dificuldade != null:
		dt_chegada = ReachableColors.tempo_de_pulo(scroll_efetivo())
		espera = ESPERA_MAXIMA_S
	set_color(
		ReachableColors.cor_no_pouso(Global.platforms, actual_platform, PlayArea.LARGURA, rng, dt_chegada, espera)
	)

# f526 T4: reposiciona o gecko sobre a plataforma alvo da Segunda chance - teleporte de resgate, nao pouso (Q2).
# Base do corpo no topo do shape dela (sem interpenetrar; o x e o dela no instante do teleporte - a fisica cuida
# do que vem depois: como em qualquer pouso, a gravidade cola o gecko no topo enquanto a plataforma desce com o
# scroll ou anda em x). Velocity zerada, estado de chao coerente, actual_platform apontando para a alvo e colisao
# reavaliada pela cor vigente (ou cor livre, se o Camaleao esta ativo - este metodo nunca toca Global.cor_livre).
# `cor_a_assumir >= 0` diferente da cor atual = fallback do ADR 0014 (o gecko assume a cor da plataforma);
# -1 ou igual mantem a cor. Sem lose_game e sem animacao de derrota: quem chama e o resgate da Stage (T5).
func reaparecer_sobre(plataforma: Platform, cor_a_assumir: int = -1) -> void:
	velocity = Vector2.ZERO
	on_ground = true
	jumping = false
	can_change_color = false
	_guarda_reaparecimento = true
	actual_platform = plataforma
	if cor_a_assumir >= 0 and int(cor_a_assumir) != int(color):
		# Fallback: assume a cor da alvo (set_color ja reavalia as demais plataformas pelo Global)
		set_color(cor_a_assumir)
	else:
		# Cor mantida: so reavalia a colisao das demais pela cor vigente
		Global.player_color_changed(color, plataforma)
	# O Global nao reavalia a plataforma atual (o pouso normal conta com ela solida desde o ultimo pulo); no
	# fallback a alvo vinha atravessavel (era de outra cor) - sem isto o gecko cairia dentro dela no frame seguinte.
	plataforma.player_color_changed(color)
	global_position = Vector2(plataforma.global_position.x, _y_no_topo(plataforma))


# y global que poe a base do corpo do gecko exatamente no topo do shape da plataforma (tocando, sem interpenetrar).
# O shape do Player tem rotation PI e e um retangulo centrado: o AABB e invariante a rotacao de 180 graus.
func _y_no_topo(plataforma: Platform) -> float:
	var forma_alvo: RectangleShape2D = plataforma.shape.shape as RectangleShape2D
	var topo: float = plataforma.global_position.y + plataforma.shape.position.y - forma_alvo.size.y / 2.0
	var forma_corpo: RectangleShape2D = collision.shape as RectangleShape2D
	var base_corpo: float = collision.position.y + forma_corpo.size.y / 2.0
	return topo - base_corpo

# Scroll vigente da partida (curva do estagio vezes o fator do power-up de desaceleracao, f522 T4):
# a previsao de cor da janela de chegada usa o scroll que de fato move o mundo. Sem dificuldade = 0.
func scroll_efetivo() -> float:
	if dificuldade == null:
		return 0.0
	var fator: float = power_up_estado.fator_scroll() if power_up_estado != null else 1.0
	return DifficultySnapshot.de(dificuldade).get_scroll() * fator * fator_scroll_forcado

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
