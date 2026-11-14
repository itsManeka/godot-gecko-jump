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

# Estado de dificuldade da partida (injetado antes do add_child); null = snapshot do estagio 0
var dificuldade: DifficultyState = null

# Ultimas K-1 cores criadas por este gerador (historico da janela, ordem de criacao)
var _cores_criadas: Array = []

# Cor do gecko lida no 1o preenchimento (-1 = ainda nao leu); so leitura, para teste
var primeira_cor_gecko_lida: int = -1

# Snapshot e modificadores de plataforma lidos no nascimento da linha (null = ainda nao lidos)
var _snapshot_nascimento: DifficultySnapshot = null
var _modificadores: Array = []
# A mecanica de ciclo de cor esta ligada neste gerador (nunca na linha garantir_cor_inicial)
var _ciclo_ligado: bool = false
# rng das sequencias das cicladoras: o do gerador (teste) ou um proprio quando rng e null
var _rng_ciclo: RandomNumberGenerator = null
# A mecanica de speed por linha esta ligada neste gerador (nunca na linha garantir_cor_inicial)
var _speed_variada: bool = false

# Inicializa o gerador de plataformas
func _ready():
	# Speed e proporcao lidas do snapshot vigente no nascimento: a linha mantem a speed ate sair
	var snapshot: DifficultySnapshot = _snapshot()
	_ler_mecanicas(snapshot)
	speed = snapshot.get_speed_moveis()

	# Resolve tipos de plataforma aleatórios (sorteio em PlatformTypePicker)
	platform_type = PlatformTypePicker.resolve(platform_type, null, snapshot.get_proporcao_estaticas())

	# Configura comportamento baseado no tipo (Platform.gd: velocity = -speed, entao speed > 0 anda a esquerda)
	match platform_type:
		Enums.PLATFORM_TYPE.STATIC:
			create_static_platforms()
		Enums.PLATFORM_TYPE.MOVE_TO_LEFT:
			# Nasce a direita (x da cena, 210) e anda para a esquerda
			_variar_speed(snapshot)
			preencher_linha()
		Enums.PLATFORM_TYPE.MOVE_TO_RIGHT:
			# Nasce a esquerda (x = -30) e anda para a direita
			check_generate.position.x = -30
			_variar_speed(snapshot)
			speed *= -1
			preencher_linha()

# Speed da linha = speed do estagio x fator sorteado uma vez (rng do gerador; sem rng, um proprio).
# Sem a mecanica e em sem_derrota a speed fica como esta (linha inicial: _ler_mecanicas nem liga a mecanica).
func _variar_speed(snapshot: DifficultySnapshot) -> void:
	if not _speed_variada or Global.sem_derrota:
		return
	var fonte: RandomNumberGenerator = rng
	if fonte == null:
		fonte = RandomNumberGenerator.new()
		fonte.randomize()
	speed *= RowSpeedVariation.fator(fonte, snapshot.get_variacao_speed_linha())

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
		if Global.sem_derrota:
			# Modo sem derrota (smoke debug): cor unica, a plataforma de origem nunca desliga
			platform.set_color(Enums.COR_INICIAL)
		else:
			platform.set_color(cores[i] if not cores.is_empty() else Enums.get_random_color())
		platform.position.x = position_x
		_aplicar_mecanicas(platform)
		platform.set_speed(0)  # Plataformas estáticas não se movem
		add_child(platform)
		position_x += 85

# Linha movel nasce preenchida: plataformas pre-colocadas (posicoes em MovingRowFill) e a do ponto de nascimento
# criada na hora, sem esperar o timer; o ciclo area_exited -> timer segue a partir dela
func preencher_linha():
	var spawn_x: float = check_generate.position.x
	# Plataforma anda em direcao oposta ao sinal de speed (Platform.gd: velocity = -speed)
	for x in MovingRowFill.initial_xs(spawn_x, speed > 0, MovingRowFill.LARGURA_PADRAO, absf(speed)):
		_criar_plataforma(x)
	new_platform()

# Cria uma nova plataforma em movimento
func new_platform():
	_criar_plataforma(check_generate.position.x)

# Foto vigente da dificuldade; sem estado injetado = estagio 0
func _snapshot() -> DifficultySnapshot:
	return DifficultySnapshot.de(dificuldade)

# Cor da proxima plataforma movel: garante a cor do gecko (Global) em toda janela de K (K vigente) criadas por este
# gerador; preencher_linha e new_platform passam por aqui, entao compartilham o historico
func _cor_movel() -> int:
	if Global.sem_derrota:
		return Enums.COR_INICIAL
	var cor_gecko: int = Global.cor_gecko
	if primeira_cor_gecko_lida < 0:
		primeira_cor_gecko_lida = cor_gecko
	# K relido a cada plataforma criada (pode mudar no meio da linha)
	var k: int = _snapshot().get_k()
	var cor: int = ReachableColors.cor_plataforma_movel(cor_gecko, _cores_criadas, rng, k)
	_cores_criadas.append(cor)
	var maximo: int = maxi(k - 1, 0)
	while _cores_criadas.size() > maximo:
		_cores_criadas.pop_front()
	return cor


# Instancia uma plataforma movel em x com cor sorteada
func _criar_plataforma(x: float):
	var platform = pre_platform.instantiate()
	platform.set_color(_cor_movel())
	platform.position.x = x
	platform.set_speed(0 if Global.sem_derrota else speed)
	_aplicar_mecanicas(platform)
	add_child(platform)

# Resolve os modificadores do snapshot do nascimento; linha com garantir_cor_inicial (Q5) nunca desmorona
func _ler_mecanicas(snapshot: DifficultySnapshot) -> void:
	_snapshot_nascimento = snapshot
	_modificadores = []
	_ciclo_ligado = false
	_speed_variada = false
	for modificador in PlatformModifiers.resolver(snapshot):
		if garantir_cor_inicial and not modificador.vale_em_linha_inicial():
			continue
		if modificador is RowSpeedVariation:
			# Mecanica de linha: aplicada na speed no _ready, nunca na lista de plataforma
			_speed_variada = true
			continue
		if modificador is PlatformColorCycle:
			# Estado por plataforma: nunca entra na lista compartilhada da linha; cada cicladora ganha instancia propria
			_ciclo_ligado = true
			continue
		_modificadores.append(modificador)

# Entrega a lista de modificadores a plataforma antes do add_child (gerador fora da arvore le na 1a criacao)
func _aplicar_mecanicas(platform: Platform) -> void:
	if _snapshot_nascimento == null:
		_ler_mecanicas(_snapshot())
	var lista: Array = _modificadores
	if _ciclo_ligado and _sorteia_cicladora():
		lista = _modificadores.duplicate()
		lista.append(_novo_ciclo(platform.color))
	platform.definir_modificadores(lista, _snapshot_nascimento)

# Sorteio da cicladora: proporcao_cicladoras do snapshot do nascimento, pelo rng do gerador (randf global sem rng)
func _sorteia_cicladora() -> bool:
	var proporcao: float = _snapshot_nascimento.get_proporcao_cicladoras()
	if proporcao <= 0.0:
		return false
	var sorteio: float = randf() if rng == null else rng.randf()
	return sorteio < proporcao

# Instancia propria de PlatformColorCycle: sequencia sorteada a partir da cor da plataforma e forcada a ter a cor do gecko
func _novo_ciclo(cor_inicial: int) -> PlatformColorCycle:
	if _rng_ciclo == null:
		_rng_ciclo = rng
		if _rng_ciclo == null:
			_rng_ciclo = RandomNumberGenerator.new()
			_rng_ciclo.randomize()
	var periodo: float = _snapshot_nascimento.get_periodo_ciclo()
	var ciclo := PlatformColorCycle.new()
	ciclo.iniciar(cor_inicial, periodo, _rng_ciclo)
	var alcance_s: float = _alcance_s(periodo)
	ciclo.definir_sequencia(
		ReachableColors.forcar_cor_cicladora(ciclo.get_sequencia(), int(Global.cor_gecko), periodo, alcance_s)
	)
	return ciclo

# Tempo em que a plataforma recem-nascida segue alcancavel: o tempo de pulo ate a linha dela (pelo scroll do snapshot do
# nascimento) mais 1 periodo de espera em cima, com piso de 2 periodos (a cor do indice 0 e a ja pintada na plataforma).
func _alcance_s(periodo: float) -> float:
	var pulo: float = ReachableColors.tempo_de_pulo(_snapshot_nascimento.get_scroll())
	return maxf(pulo, periodo) + periodo

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
