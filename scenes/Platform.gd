extends CharacterBody2D

class_name Platform

# Velocidade de movimento da plataforma (negativa = esquerda)
@export var speed = 0
# Cor da plataforma (definida no editor)
@export var color: Enums.COLOR = Enums.COLOR.AMARELO

# Tremor horizontal do sprite nos ultimos segundos do atraso de desmoronamento
const AVISO_TREMOR_S := 0.3
const TREMOR_AMPLITUDE := 1.0

# Verdadeiro depois que o desmoronamento termina (colisao desligada de vez)
var desmoronada := false
var _desmoronando := false
var _atraso_total := 0.0
var _tempo_restante := 0.0
var _modificadores: Array = []
var _snapshot: DifficultySnapshot = null

# Referencias aos nós filhos
@onready var sprite = $Sprite2D
@onready var shape = $CollisionShape2D

# Inicializa a plataforma
func _ready():
	# Movimento livre (MOTION_MODE_FLOATING), sem logica de chao: a plataforma so desliza no eixo X
	motion_mode = MOTION_MODE_FLOATING
	Global.add_platform(self)
	sprite.modulate = Enums.get_cor(color)
	# Os nos filhos so existem aqui: o ao_criar dos modificadores (ex.: set_largura) roda neste ponto
	for modificador in _modificadores:
		modificador.ao_criar(self, _snapshot)

# Sai de Global.platforms sempre que sai da arvore (queue_free do gerador, troca de cena, saida de tela)
func _exit_tree():
	Global.remove_platform(self)

# Guarda a lista de modificadores e o snapshot; o gerador chama antes do add_child
func definir_modificadores(lista: Array, snapshot: DifficultySnapshot) -> void:
	_modificadores = lista
	_snapshot = snapshot

# Pouso confirmado do jogador: despacha o hook aos modificadores
func notificar_pouso() -> void:
	for modificador in _modificadores:
		modificador.ao_pousar(self, _snapshot)

# Largura da colisao e do visual; o shape e duplicado por instancia (o sub_resource da cena e compartilhado).
# Sem scale no corpo; AreaCheck e o notifier ficam como estao.
func set_largura(largura: float) -> void:
	var forma: RectangleShape2D = (shape.shape as RectangleShape2D).duplicate()
	forma.size.x = largura
	shape.shape = forma
	var tex_w: float = sprite.texture.get_width()
	var tex_h: float = sprite.texture.get_height()
	var visivel: float = minf(largura, tex_w)
	sprite.region_enabled = true
	sprite.region_rect = Rect2((tex_w - visivel) / 2.0, 0.0, visivel, tex_h)

# Inicia a contagem do desmoronamento (uma vez); ao fim a colisao some de vez e a plataforma sai da arvore
func iniciar_desmoronamento(atraso: float) -> void:
	if _desmoronando or desmoronada:
		return
	_desmoronando = true
	_atraso_total = atraso
	_tempo_restante = atraso

func _avancar_desmoronamento(delta: float) -> void:
	_tempo_restante -= delta
	if _tempo_restante <= 0.0:
		_desmoronando = false
		desmoronada = true
		shape.disabled = true
		sprite.position.x = 0.0
		queue_free()
		return
	if _tempo_restante <= minf(AVISO_TREMOR_S, _atraso_total):
		sprite.position.x = TREMOR_AMPLITUDE if int(_tempo_restante * 40.0) % 2 == 0 else -TREMOR_AMPLITUDE

# Processa o movimento da plataforma
func _physics_process(delta):
	if _desmoronando:
		_avancar_desmoronamento(delta)
	for modificador in _modificadores:
		modificador.ao_processar(self, delta)
	if !Global.is_iniciado():
		return

	velocity = Vector2(-speed, 0)
	move_and_slide()

# Define a velocidade de movimento da plataforma
func set_speed(new_speed):
	speed = new_speed

# Define a cor da plataforma
func set_color(new_color):
	color = new_color

# Retorna a cor atual da plataforma
func get_color():
	return color

# Ativa/desativa a colisão baseado na cor do jogador
func player_color_changed(player_color):
	if desmoronada:
		shape.disabled = true  # Desmoronada nunca reativa
	elif player_color == color:
		shape.disabled = false  # Jogador pode colidir (mesma cor)
	else:
		shape.disabled = true   # Jogador passa através (cor diferente)

# Remove a plataforma quando sai da tela
func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
