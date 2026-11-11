extends Node2D

# Gerador de grupos de plataformas em movimento

# Prefab da plataforma para instanciar
const pre_platform = preload("res://scenes/Platform.tscn")

# Tipo de plataforma que este gerador cria (definido no editor)
@export var platform_type: Enums.PLATFORM_TYPE = Enums.PLATFORM_TYPE.STATIC

# Só o gerador inicial liga: garante 1 estática com a cor inicial do jogador (Enums.COR_INICIAL)
@export var garantir_cor_inicial: bool = false

# Referencias aos nós filhos
@onready var generate_timer = $Timer
@onready var check_generate = $CheckGenerate

# Velocidade de movimento das plataformas geradas
var speed = 0

# Sorteio das moveis: null = randi() global; teste injeta um rng de seed fixa
var rng: RandomNumberGenerator = null

# Ultimas K-1 cores criadas por este gerador (historico da janela, ordem de criacao)
var _cores_criadas: Array = []

# Cor do gecko lida no 1o preenchimento (-1 = ainda nao leu); so leitura, para teste
var primeira_cor_gecko_lida: int = -1

# Inicializa o gerador de plataformas
func _ready():
	speed = 60  # Velocidade fixa (antes era aleatória)

	# Resolve tipos de plataforma aleatórios (sorteio em PlatformTypePicker)
	platform_type = PlatformTypePicker.resolve(platform_type)

	# Configura comportamento baseado no tipo (Platform.gd: velocity = -speed, entao speed > 0 anda a esquerda)
	match platform_type:
		Enums.PLATFORM_TYPE.STATIC:
			create_static_platforms()
		Enums.PLATFORM_TYPE.MOVE_TO_LEFT:
			# Nasce a direita (x da cena, 210) e anda para a esquerda
			preencher_linha()
		Enums.PLATFORM_TYPE.MOVE_TO_RIGHT:
			# Nasce a esquerda (x = -30) e anda para a direita
			check_generate.position.x = -30
			speed *= -1
			preencher_linha()

# Define o tipo de plataforma que será gerada
func set_platform_type(type):
	platform_type = type

# Callback do timer - cria nova plataforma e para o timer
func _on_Timer_timeout():
	new_platform()
	generate_timer.stop()

# Cria um conjunto de 3 plataformas estáticas
func create_static_platforms():
	var position_x = 5
	var cores: Array = []
	if garantir_cor_inicial:
		cores = StaticPlatformColors.sortear(Enums.COR_INICIAL)
	for i in 3:
		var platform = pre_platform.instantiate()
		platform.set_color(cores[i] if not cores.is_empty() else Enums.get_random_color())
		platform.position.x = position_x
		platform.set_speed(0)  # Plataformas estáticas não se movem
		add_child(platform)
		position_x += 85

# Linha movel nasce preenchida: plataformas pre-colocadas (posicoes em MovingRowFill) e a do ponto de nascimento
# criada na hora, sem esperar o timer; o ciclo area_exited -> timer segue a partir dela
func preencher_linha():
	var spawn_x: float = check_generate.position.x
	# Plataforma anda em direcao oposta ao sinal de speed (Platform.gd: velocity = -speed)
	for x in MovingRowFill.initial_xs(spawn_x, speed > 0):
		_criar_plataforma(x)
	new_platform()

# Cria uma nova plataforma em movimento
func new_platform():
	_criar_plataforma(check_generate.position.x)

# Cor da proxima plataforma movel: garante a cor do gecko (Global) em toda janela de ReachableColors.K criadas por este
# gerador; preencher_linha e new_platform passam por aqui, entao compartilham o historico
func _cor_movel() -> int:
	var cor_gecko: int = Global.cor_gecko
	if primeira_cor_gecko_lida < 0:
		primeira_cor_gecko_lida = cor_gecko
	var cor: int = ReachableColors.cor_plataforma_movel(cor_gecko, _cores_criadas, rng)
	_cores_criadas.append(cor)
	var maximo: int = maxi(ReachableColors.K - 1, 0)
	while _cores_criadas.size() > maximo:
		_cores_criadas.pop_front()
	return cor


# Instancia uma plataforma movel em x com cor sorteada
func _criar_plataforma(x: float):
	var platform = pre_platform.instantiate()
	platform.set_color(_cor_movel())
	platform.position.x = x
	platform.set_speed(speed)
	add_child(platform)

# Inicia o timer para gerar próxima plataforma
func start_generate_timer():
	generate_timer.start(0.3)

# Gera nova plataforma quando a anterior sai da área
func _on_CheckGenerate_area_exited(_area):
	if platform_type != Enums.PLATFORM_TYPE.STATIC:
		start_generate_timer()

# Remove o gerador quando sai da tela
func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
