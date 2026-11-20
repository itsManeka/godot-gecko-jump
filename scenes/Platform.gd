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
# Plataforma que pisca: invisivel = fantasma (alfa baixo, sem colisao); aviso = flicker de alfa (10 ciclos/s = 20 fases/s,
# ver PISCA_AVISO_FASES_POR_S) mantendo a cor.
# O alfa vive no proprio no (nao em sprite.modulate, canal de cor/aviso da cicladora).
const PISCA_ALFA_FANTASMA := 0.2
const PISCA_AVISO_ALFA_BAIXO := 0.35
const PISCA_AVISO_FASES_POR_S := 20.0

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
# Invisivel por piscar: a colisao fica desligada. _pisca_pendente = reaparecer adiado porque o gecko (mesma cor)
# ainda sobrepoe o corpo; a colisao liga no frame em que ele sai.
var _pisca_oculta := false
var _pisca_pendente := false
var _tempo_aviso_pisca := 0.0
# Tipo de power-up desta plataforma (&"" = nenhum) e o icone filho; o icone nunca entra em Global.platforms
var tipo_power_up: StringName = &""
var icone_power_up: Node2D = null
# Distancia (px) entre a base do icone e o topo da plataforma
const ICONE_FOLGA := 2.0
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
	_atualizar_pisca(0.0, true)
	_posicionar_icone()
	_regra_de_cor_no_nascimento()

# Sai de Global.platforms sempre que sai da arvore (queue_free do gerador, troca de cena, saida de tela)
func _exit_tree():
	Global.remove_platform(self)

# Guarda a lista de modificadores e o snapshot; o gerador chama antes do add_child
func definir_modificadores(lista: Array, snapshot: DifficultySnapshot) -> void:
	_modificadores = lista
	_snapshot = snapshot

# Power-up sorteado pelo gerador (vazio = nenhum). Com tipo, a plataforma ganha um icone filho (Node2D sem colisao);
# o gerador chama antes do add_child e o icone se posiciona no _ready (o sprite so existe ali).
func definir_power_up(tipo: StringName) -> void:
	tipo_power_up = tipo
	if tipo == &"":
		return
	var icone := PowerUpIcone.new()
	icone.tipo = tipo
	icone_power_up = icone
	add_child(icone)

# Icone centrado no x da plataforma, com a base ICONE_FOLGA px acima do topo do sprite
func _posicionar_icone() -> void:
	if icone_power_up == null:
		return
	var topo: float = sprite.position.y + sprite.offset.y - sprite.texture.get_height() / 2.0
	icone_power_up.position = Vector2(0.0, topo - ICONE_FOLGA - PowerUpIcone.TAMANHO_PX / 2.0)


# f522 T3: a plataforma nasce com a regra de colisao vigente — o sinal de troca de cor so chega na proxima
# reavaliacao do Player, e o default da cena e solida; sem isto, cor diferente nasceria solida ate a 1a
# reavaliacao do jogo (e nunca nasceria solida com cor livre no meio do efeito, C603).
func _regra_de_cor_no_nascimento() -> void:
	player_color_changed(Global.cor_gecko)

# Pouso confirmado do jogador: despacha o hook aos modificadores e devolve o power-up da plataforma
# (consumido aqui: o tipo zera e o icone sai da arvore; &"" = nao tinha ou ja foi coletado)
func notificar_pouso() -> StringName:
	var tipo: StringName = _consumir_power_up()
	for modificador in _modificadores:
		modificador.ao_pousar(self, _snapshot)
	return tipo


# Coleta unica: devolve o tipo desta plataforma e limpa o seu power-up (o icone sai junto)
func _consumir_power_up() -> StringName:
	var tipo: StringName = tipo_power_up
	tipo_power_up = &""
	if icone_power_up != null:
		icone_power_up.queue_free()
		icone_power_up = null
	return tipo

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
		# O relogio do piscar so corre com a partida em andamento (o menu/derrota nao o avanca) e fora do modo sem derrota
		if modificador is PlatformBlink and not _pisca_corre():
			continue
		modificador.ao_processar(self, delta)
	_atualizar_aviso(delta)
	_atualizar_pisca(delta)
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

# Ativa/desativa a colisão baseado na cor do jogador. Cor livre (Camaleao, f522 T3): qualquer cor colide.
# Desmoronada e invisivel por piscar nunca reativam — a excecao vale tambem com cor livre.
func player_color_changed(player_color):
	if desmoronada or _pisca_oculta or _pisca_pendente:
		shape.disabled = true  # Desmoronada e invisivel por piscar nunca reativam
	elif Global.cor_livre or player_color == color:
		shape.disabled = false  # Mesma cor ou cor livre (Camaleao): jogador pode colidir
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
	return _gecko_sobrepoe_corpo()

# Verdadeiro se o corpo do gecko sobrepoe a forma de colisao desta plataforma agora
func _gecko_sobrepoe_corpo() -> bool:
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

# Modificador de piscar desta plataforma (nulo se nao for piscante)
func obter_pisca() -> PlatformBlink:
	for modificador in _modificadores:
		if modificador is PlatformBlink:
			return modificador
	return null

# O relogio do piscar corre so com a partida iniciada e fora do modo sem derrota (inerte)
func _pisca_corre() -> bool:
	return Global.is_iniciado() and not Global.sem_derrota

# Aplica visibilidade/colisao/aviso do piscar. `inicial` aplica o estado de nascimento mesmo antes da partida.
func _atualizar_pisca(delta: float, inicial: bool = false) -> void:
	var pisca := obter_pisca()
	if pisca == null:
		return
	if _pisca_pendente:
		_resolver_pisca_pendente()
	var inerte := Global.sem_derrota or not pisca.esta_ativo()
	if not inerte and not inicial and not Global.is_iniciado():
		return
	# Travada (gecko em cima) nunca some; o relogio do modificador ja esta congelado
	var visivel := inerte or _travada or pisca.esta_visivel()
	_definir_pisca_oculta(not visivel)
	_atualizar_alfa_pisca(pisca, delta, inerte)

func _definir_pisca_oculta(oculta: bool) -> void:
	if oculta == _pisca_oculta:
		return
	_pisca_oculta = oculta
	if oculta:
		_pisca_pendente = false
		shape.disabled = true
		return
	# Reaparecer: com o gecko (mesma cor) sobrepondo o corpo, a colisao espera ele sair
	if int(Global.cor_gecko) == int(color) and not desmoronada and _gecko_sobrepoe_corpo():
		_pisca_pendente = true
		shape.disabled = true
		return
	player_color_changed(Global.cor_gecko)

func _resolver_pisca_pendente() -> void:
	if int(Global.cor_gecko) == int(color) and _gecko_sobrepoe_corpo():
		return
	_pisca_pendente = false
	player_color_changed(Global.cor_gecko)

func _atualizar_alfa_pisca(pisca: PlatformBlink, delta: float, inerte: bool) -> void:
	var alfa := 1.0
	if _pisca_oculta:
		alfa = PISCA_ALFA_FANTASMA
		_tempo_aviso_pisca = 0.0
	elif pisca.em_aviso() and not _travada and not desmoronada and not inerte:
		_tempo_aviso_pisca += delta
		if int(_tempo_aviso_pisca * PISCA_AVISO_FASES_POR_S) % 2 == 1:
			alfa = PISCA_AVISO_ALFA_BAIXO
	else:
		_tempo_aviso_pisca = 0.0
	modulate.a = alfa

# Remove a plataforma quando sai da tela
func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
