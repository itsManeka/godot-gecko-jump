extends CharacterBody2D

class_name Platform

# Velocidade de movimento da plataforma (negativa = esquerda)
@export var speed = 0
# Cor da plataforma (definida no editor)
@export var color: Enums.COLOR = Enums.COLOR.AMARELO

# Tremor horizontal do Visual nos ultimos segundos do atraso de desmoronamento
const AVISO_TREMOR_S := 0.3
const TREMOR_AMPLITUDE := 2.0
# Aviso de troca de cor (nos ultimos segundos do ciclo): alterna cor atual/proxima a ~6 Hz e pulsa o alfa
# (pista nao cromatica, legivel a daltonico). Sem icone fixo.
const AVISO_FASES_POR_S := 12.0
const AVISO_ALFA_BAIXO := 0.55
# Camada de fisica do corpo do gecko (Player, camada padrao 1)
const CAMADA_GECKO := 1
# Plataforma que pisca: invisivel = fantasma (alfa baixo, sem colisao); aviso = flicker de alfa (10 ciclos/s = 20 fases/s,
# ver PISCA_AVISO_FASES_POR_S) mantendo a cor.
# O alfa vive no proprio no (nao em Visual.modulate, canal do aviso da cicladora).
const PISCA_ALFA_FANTASMA := 0.2
const PISCA_AVISO_ALFA_BAIXO := 0.35
const PISCA_AVISO_FASES_POR_S := 20.0

# Rachadura: estagio 1 ao iniciar (atraso > AVISO_TREMOR_S), 2 em _tempo_restante <= AVISO_TREMOR_S, 3 em <= 0.1
const RACHADURA_ESTAGIO_3_S := 0.1
# Rng do burst de pedacos (nulo = RandomNumberGenerator novo no colapso; o teste injeta a semente)
var rng_pedacos: RandomNumberGenerator = null
var _estagio_rachadura := 0
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
const ICONE_FOLGA := 4.0
# Desvio horizontal (px/s, negativo = esquerda) somado a `speed` pelo modificador de movimento; 0 = sem efeito
var desvio_vx: float = 0.0

# Referencias aos nós filhos. Canais visuais, um dono cada: textura de `corpo` = cor (_aplicar_cor/aviso),
# Visual.modulate.a = pulso do aviso da cicladora, Platform.modulate.a = piscante, Visual.position.x = tremor.
@onready var visual: Node2D = $Visual
@onready var corpo: NinePatchRect = $Visual/Corpo
@onready var overlay: NinePatchRect = $Visual/OverlayRachadura
@onready var shape = $CollisionShape2D

# Inicializa a plataforma
func _ready():
	# Movimento livre (MOTION_MODE_FLOATING), sem logica de chao: a plataforma so desliza no eixo X
	motion_mode = MOTION_MODE_FLOATING
	Global.add_platform(self)
	_aplicar_textura(color)
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
# o gerador chama antes do add_child e o icone se posiciona no _ready (o Visual so existe ali).
func definir_power_up(tipo: StringName) -> void:
	tipo_power_up = tipo
	if tipo == &"":
		return
	var icone := PowerUpIcone.new()
	icone.tipo = tipo
	icone_power_up = icone
	add_child(icone)

# Topo real do NinePatchRect no espaco da Platform (inclui o offset vertical que alinha a superficie da peca ao topo da
# colisao: hoje -16). O Visual nao tem scale.
func topo_visual() -> float:
	return visual.position.y + corpo.position.y

# Icone centrado no x da plataforma, com a base ICONE_FOLGA px acima do topo do visual
func _posicionar_icone() -> void:
	if icone_power_up == null:
		return
	icone_power_up.position = Vector2(0.0, topo_visual() - ICONE_FOLGA - PowerUpIcone.TAMANHO_PX / 2.0)


# f522 T3 (C603): so com o efeito de cor livre ativo a regra vigente e aplicada no nascimento (piscar oculto
# segue atravessavel). Sem efeito nada muda: vale o default da cena (solida) ate a 1a reavaliacao do Player,
# como antes do power-up.
func _regra_de_cor_no_nascimento() -> void:
	if Global.cor_livre:
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
	# O NinePatchRect (pontas 20/20, miolo TILE) cobre a largura pedida em px logicos, sem scale; fica centrado em x
	corpo.size.x = largura
	corpo.position.x = -largura / 2.0
	# O overlay de rachadura acompanha a largura do corpo
	overlay.size.x = largura
	overlay.position.x = -largura / 2.0

# Inicia a contagem do desmoronamento (uma vez); ao fim a colisao some de vez e a plataforma sai da arvore
func iniciar_desmoronamento(atraso: float) -> void:
	if _desmoronando or desmoronada:
		return
	_desmoronando = true
	_atraso_total = atraso
	_tempo_restante = atraso
	if atraso > AVISO_TREMOR_S:
		_definir_estagio_rachadura(1)

func _avancar_desmoronamento(delta: float) -> void:
	if desmoronada:
		return
	_tempo_restante -= delta
	if _tempo_restante <= 0.0:
		_desmoronando = false
		desmoronada = true
		shape.disabled = true
		visual.position.x = 0.0
		_emitir_pedacos()
		queue_free()
		return
	if _tempo_restante <= RACHADURA_ESTAGIO_3_S:
		_definir_estagio_rachadura(3)
	elif _tempo_restante <= AVISO_TREMOR_S:
		_definir_estagio_rachadura(2)
	if _tempo_restante <= minf(AVISO_TREMOR_S, _atraso_total):
		visual.position.x = TREMOR_AMPLITUDE if int(_tempo_restante * 40.0) % 2 == 0 else -TREMOR_AMPLITUDE

# Estagio da rachadura no overlay (0 = invisivel); o overlay e o unico dono desse canal visual
func _definir_estagio_rachadura(estagio: int) -> void:
	_estagio_rachadura = estagio
	overlay.texture = PlatformVisuais.rachadura(estagio)
	overlay.visible = estagio > 0

# Burst one-shot de pedacos no pai (sobrevive a liberacao da plataforma); sem pai = sem burst
func _emitir_pedacos() -> void:
	var pai := get_parent()
	if pai == null:
		return
	if rng_pedacos == null:
		rng_pedacos = RandomNumberGenerator.new()
	PlatformPedacos.emitir(pai, global_position, corpo.size.x, color, rng_pedacos)

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

# Em curso de desmoronamento (o atraso conta e a plataforma ainda colide, mas esta prestes a sumir). Leitor
# publico para ReachableColors.entradas_de_plataformas (f526 T3): o alvo da Segunda chance exclui quem esta assim.
func esta_desmoronando() -> bool:
	return _desmoronando

# Invisivel por piscar (fantasma sem colisao). Leitor publico para ReachableColors.entradas_de_plataformas (f526 T3).
func esta_pisca_oculta() -> bool:
	return _pisca_oculta

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
	_aplicar_textura(color)
	visual.modulate = Color.WHITE
	player_color_changed(Global.cor_gecko)

# A cor da plataforma e a textura do corpo (peca propria por cor), nunca o modulate
func _aplicar_textura(cor: int) -> void:
	corpo.texture = PlatformVisuais.textura(cor)

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
			_aplicar_textura(color)
			visual.modulate = Color.WHITE
		return
	_em_aviso_visual = true
	_tempo_aviso += delta
	var fase_proxima := int(_tempo_aviso * AVISO_FASES_POR_S) % 2 == 1
	_aplicar_textura(ciclo.proxima_cor() if fase_proxima else color)
	visual.modulate = Color(1.0, 1.0, 1.0, AVISO_ALFA_BAIXO if fase_proxima else 1.0)

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
