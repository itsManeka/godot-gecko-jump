extends CharacterBody2D

class_name Platform

# Velocidade de movimento da plataforma (negativa = esquerda)
@export var speed = 0
# Cor da plataforma (definida no editor)
@export var color: Enums.COLOR = Enums.COLOR.AMARELO

# Tremor horizontal do sprite nos ultimos segundos do atraso de desmoronamento
const AVISO_TREMOR_S := 0.3
const TREMOR_AMPLITUDE := 1.0
# Aviso de troca de cor (nos ultimos segundos do ciclo): alterna cor atual/proxima a ~6 Hz e pulsa o alfa
# (pista nao cromatica, legivel a daltonico). Sem icone fixo.
const AVISO_FASES_POR_S := 12.0
const AVISO_ALFA_BAIXO := 0.55
# Camada de fisica do corpo do gecko (Player, camada padrao 1)
const CAMADA_GECKO := 1

# Verdadeiro depois que o desmoronamento termina (colisao desligada de vez)
var desmoronada := false
var _travada := false
var _cor_pendente := -1
var _tempo_aviso := 0.0
var _em_aviso_visual := false
var _desmoronando := false
var _atraso_total := 0.0
var _tempo_restante := 0.0
var _modificadores: Array = []
var _snapshot: DifficultySnapshot = null
# Desvio horizontal (px/s, negativo = esquerda) somado a `speed` pelo modificador de movimento; 0 = sem efeito
var desvio_vx: float = 0.0

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
	if _cor_pendente >= 0 and not desmoronada and not _gecko_prenderia(_cor_pendente):
		_aplicar_cor(_cor_pendente)
	for modificador in _modificadores:
		modificador.ao_processar(self, delta)
	_atualizar_aviso(delta)
	if !Global.is_iniciado():
		return

	velocity = Vector2(-speed + desvio_vx, 0)
	move_and_slide()

# Verdadeiro quando a plataforma realmente anda: tem velocidade base e a partida ja comecou.
# Modificador de movimento so avanca a fase com isto (evita deriva antes da partida e em plataforma parada).
func em_movimento() -> bool:
	return speed != 0 and Global.is_iniciado()

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

# Modificador de ciclo de cor desta plataforma (nulo se nao for cicladora)
func obter_ciclo() -> PlatformColorCycle:
	for modificador in _modificadores:
		if modificador is PlatformColorCycle:
			return modificador
	return null

# O gecko esta nesta plataforma: o ciclo congela (Global registra a cada player_color_changed)
func esta_travada() -> bool:
	return _travada

func definir_travada(valor: bool) -> void:
	_travada = valor

# Troca a cor da plataforma (ciclo). Se o gecko esta com o corpo sobreposto e a troca a tornaria solida,
# a troca espera ele sair (evita prende-lo dentro da colisao).
# Com a troca adiada (_cor_pendente) o ciclo ja avancou o indice: ciclo.cor_atual() difere de `color` ate a troca
# aplicar. Inofensivo para a previsao: o gecko esta sobreposto, entao nao ha pouso nem candidata nessa plataforma.
func trocar_cor(nova: int) -> void:
	if _gecko_prenderia(nova):
		_cor_pendente = nova
		return
	_aplicar_cor(nova)

func _aplicar_cor(nova: int) -> void:
	color = nova as Enums.COLOR
	_cor_pendente = -1
	_tempo_aviso = 0.0
	_em_aviso_visual = false
	sprite.modulate = Enums.get_cor(color)
	player_color_changed(Global.cor_gecko)

# Verdadeiro se a cor `nova` tornaria a plataforma solida para o gecko que ainda sobrepoe o corpo dela
func _gecko_prenderia(nova: int) -> bool:
	if desmoronada or nova != int(Global.cor_gecko) or not shape.disabled:
		return false
	if not is_inside_tree():
		return false
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = shape.shape
	consulta.transform = shape.global_transform
	consulta.collision_mask = CAMADA_GECKO
	consulta.collide_with_bodies = true
	return not get_world_2d().direct_space_state.intersect_shape(consulta, 1).is_empty()

# Aviso visual nos segundos finais do ciclo: cor atual/proxima alternando e alfa pulsando; fora dele, normal
func _atualizar_aviso(delta: float) -> void:
	var ciclo := obter_ciclo()
	var avisar := ciclo != null and ciclo.em_aviso() and not _travada and not desmoronada
	if not avisar:
		if _em_aviso_visual:
			_em_aviso_visual = false
			_tempo_aviso = 0.0
			sprite.modulate = Enums.get_cor(color)
		return
	_em_aviso_visual = true
	_tempo_aviso += delta
	var fase_proxima := int(_tempo_aviso * AVISO_FASES_POR_S) % 2 == 1
	var cor_aviso := Enums.get_cor(ciclo.proxima_cor() if fase_proxima else color)
	cor_aviso.a = AVISO_ALFA_BAIXO if fase_proxima else 1.0
	sprite.modulate = cor_aviso

# Remove a plataforma quando sai da tela
func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
