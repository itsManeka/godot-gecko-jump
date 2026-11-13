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
# Curva de producao (estagios da dificuldade); o estado de cada partida e criado em _ready a partir dela
const CURVA_DIFICULDADE: DifficultyCurve = preload("res://ressources/curva_dificuldade.tres")
# Disparado a cada inicio efetivo da partida (a guarda de started impede repeticao)
signal partida_iniciada
# Camada de toque (filha da Stage, criada em _ready)
var touch_controls: TouchControls = null
# Dica visual das zonas de toque (filha da Stage, criada em _ready)
var touch_hint: TouchHint = null
# Botao de pausa por toque e overlay de pausa (filhos da Stage, criados em _ready)
var pause_botao: PauseBotao = null
var pause_overlay: PauseOverlay = null
var pause_state: PauseState = null
# Tela de Opcoes (filha da Stage, criada em _ready)
var options_screen: OptionsScreen = null
# Safe area (coordenadas logicas) da ultima apply_layout; usada pelo HUD (T4)
var safe_area: Rect2 = Rect2()
# Ultimo estado montado para a ponte do smoke (ver GameState); lido pelos testes sem JavaScriptBridge
var ultimo_estado: Dictionary = {}
# Dificuldade da partida (DifficultyState): nasce em _ready, zera a cada Stage nova (reload da cena). Consumidores leem o snapshot
var dificuldade: DifficultyState = null

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
	dificuldade = DifficultyState.new(CURVA_DIFICULDADE)
	# Linhas do .tscn e as de ScrollLevel._ready ja nasceram (estagio 0); as novas recebem o estado
	var scroll_level: Node = get_node_or_null("ScrollLevel")
	if scroll_level != null:
		scroll_level.dificuldade = dificuldade
	player.visible = false
	player.add_point.connect(_on_player_add_point)
	_publicar_estado(GameState.STATE_MENU, true)

	# Camada de toque de um polegar (criada por codigo; inerte fora de partida em curso)
	touch_controls = TouchControls.new()
	touch_controls.player = player
	add_child(touch_controls)
	# Dica das zonas de toque (so desenho, abaixo do HUD); criada depois da camada de toque: recebe o toque antes
	# dela e da Stage, entao o toque que inicia a partida nao conta como toque de jogo
	touch_hint = TouchHint.new()
	touch_hint.player = player
	add_child(touch_hint)
	# Botao e overlay de pausa: filhos depois de touch_controls/touch_hint (o _input chega a eles antes). So o overlay
	# e ALWAYS (retoma com a arvore pausada); a Stage segue pausavel.
	pause_botao = PauseBotao.new()
	pause_botao.player = player
	pause_botao.pausar_pedido.connect(_pausar)
	add_child(pause_botao)
	pause_overlay = PauseOverlay.new()
	pause_overlay.retomar.connect(_retomar)
	pause_overlay.opcoes.connect(_abrir_opcoes_da_pausa)
	add_child(pause_overlay)
	# Tela de Opcoes (ALWAYS, camada acima do overlay): origem pausa; Voltar devolve ao overlay com foco em Opcoes
	options_screen = OptionsScreen.new()
	options_screen.voltar.connect(_voltar_opcoes_da_pausa)
	add_child(options_screen)
	pause_state = PauseState.new(get_tree(), _partida_ativa)

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
	if touch_hint != null:
		touch_hint.aplicar_layout(visible_size, safe)
	if pause_botao != null:
		pause_botao.aplicar_layout(visible_size, safe)
		# Zona morta do toque de jogo: o retangulo do botao (ja deslocado por s_left/s_top)
		if touch_controls != null:
			var mortas: Array[Rect2] = [pause_botao.rect_botao()]
			touch_controls.classificador.zonas_mortas = mortas
	if pause_overlay != null:
		pause_overlay.aplicar_layout(visible_size, safe)
	if options_screen != null:
		options_screen.aplicar_layout(visible_size, safe)

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
	# Pausa terminada por outro caminho: a tela de Opcoes nao fica aberta sobre a partida rodando
	if options_screen != null and options_screen.esta_aberta() and not get_tree().paused:
		options_screen.fechar()
	if not started:
		if Input.is_action_pressed("jump"):
			_on_Play_button_down()

# Acumula o tempo da partida na dificuldade (DifficultyState so conta com Global.is_iniciado())
func _physics_process(delta: float) -> void:
	dificuldade.tick(delta)

# Toque de jogo no menu inicia a partida. A TouchControls (filha) recebe o evento antes e ainda esta inerte,
# entao o toque que inicia nao vira tap de jogo; depois da derrota started segue true e a guarda de
# _on_Play_button_down faz o toque nao ter efeito.
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		_on_Play_button_down()

# Acao `pause` com a arvore rodando: pausa (ignorada fora de partida ativa). Com o overlay aberto, quem escuta
# e o proprio overlay (ALWAYS), que consome o evento antes daqui.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not (event is InputEventKey and (event as InputEventKey).echo):
		# Consome so quando a pausa de fato acontece: no menu e na derrota a acao segue para quem a escuta
		if _pausar():
			get_viewport().set_input_as_handled()

func _partida_ativa() -> bool:
	return PauseState.partida_ativa(started, player.is_end())

# Pausa a arvore (Global.iniciado nao muda), cancela o toque de jogo em curso e abre o overlay
func _pausar() -> bool:
	if pause_state.esta_pausado() or not pause_state.pausar():
		return false
	touch_controls.cancelar_tudo()
	pause_botao.cancelar()
	pause_overlay.abrir()
	return true

func _retomar() -> void:
	pause_state.retomar()
	pause_overlay.fechar()
	options_screen.fechar()

# Opcoes pela pausa: o overlay sai de cena (fechar o deixa invisivel e sem entrada) e a arvore segue pausada
func _abrir_opcoes_da_pausa() -> void:
	pause_overlay.fechar()
	options_screen.abrir()

# Voltar: fecha a tela e devolve o overlay com foco em Opcoes (ainda pausado)
func _voltar_opcoes_da_pausa() -> void:
	options_screen.fechar()
	pause_overlay.abrir(PauseOverlay.Botao.OPCOES)

# Perda de foco da janela ou da aba pausa a partida (idempotente; fora de partida ativa _pausar ignora). Nao retoma
# ao recuperar o foco: a retomada e do jogador, por Continuar.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_pausar()
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		# Android/web em segundo plano: mesmo efeito da perda de foco (idempotente, so partida ativa)
		_pausar()

# Detecta quando o jogador sai da área de jogo (perde)
func _on_CheckPlayer_body_exited(body):
	if !body.is_jumping() && !body.is_end():
		body.lose_game()
		loseaudio.play()
		Global.set_score(points)
		_publicar_estado(GameState.STATE_LOST, false)
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
	dificuldade.set_pontos(points)
	pointslabel.text = str(points)
	# Ponto tardio depois da derrota nao republica: o estado publicado segue `lost`, com o score do instante da queda.
	if ultimo_estado.get("state", "") == GameState.STATE_LOST:
		return
	_publicar_estado(GameState.STATE_PLAYING, true)

# Inicia o jogo escondendo menus e mostrando o jogador
func _on_Play_button_down():
	# Idempotente: toque + button_down emulado, toque durante a derrota ou jump preso nao reiniciam nada
	if started:
		return
	started = true
	partida_iniciada.emit()
	playbutton.visible = false
	lastscore.visible = false
	bestscore.visible = false
	player.visible = true
	Global.set_iniciado(true)
	_publicar_estado(GameState.STATE_PLAYING, true)

# Monta e publica o estado na ponte do smoke (no-op fora de web debug); score nunca negativo (points inicia em -1)
func _publicar_estado(state: String, alive: bool) -> void:
	ultimo_estado = GameState.build(maxi(points, 0), Global.get_best_score(), state, alive)
	GameState.publish(ultimo_estado)
