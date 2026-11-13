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
# Card do tutorial da 1a partida (filho da Stage, criado em _ready) e a flag "ja visto" (store: Global.opcoes)
var tutorial_card: TutorialCard = null
var tutorial_flag: TutorialFlag = null
# Callable() -> bool que substitui DisplayServer.is_touchscreen_available() na escolha da variante do card (teste)
var touchscreen_disponivel: Callable = Callable()
var pause_overlay: PauseOverlay = null
var pause_state: PauseState = null
# Tela de Opcoes (filha da Stage, criada em _ready)
var options_screen: OptionsScreen = null
# Botao Opcoes do menu (filho da Stage, criado em _ready) e origem da tela aberta (menu x pausa)
var opcoes_botao: OpcoesBotao = null
var _opcoes_do_menu: bool = false
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
	# Card do tutorial: depois da dica e antes do botao de pausa (abaixo dele no z-order). Fecha e grava a flag no
	# Pular ou no 1o ponto; derrota antes disso nao grava (o card some com a cena e volta na partida seguinte).
	tutorial_flag = TutorialFlag.new(Global.opcoes)
	tutorial_card = TutorialCard.new()
	tutorial_card.pular.connect(_concluir_tutorial)
	add_child(tutorial_card)
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
	# Botao Opcoes do menu: filho da Stage, entao o toque nele e consumido antes do _input da Stage (nao inicia a partida)
	opcoes_botao = OpcoesBotao.new()
	opcoes_botao.acionado.connect(_abrir_opcoes_do_menu)
	add_child(opcoes_botao)
	# Tela de Opcoes (ALWAYS, camada acima do overlay): Voltar devolve ao overlay (pausa) ou ao menu
	options_screen = OptionsScreen.new()
	options_screen.voltar.connect(_voltar_opcoes)
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
	if tutorial_card != null:
		tutorial_card.aplicar_layout(visible_size, safe)
	if pause_botao != null:
		pause_botao.aplicar_layout(visible_size, safe)
		# Zona morta do toque de jogo: o retangulo do botao (ja deslocado por s_left/s_top)
		if touch_controls != null:
			var mortas: Array[Rect2] = [pause_botao.rect_botao()]
			touch_controls.classificador.zonas_mortas = mortas
	if pause_overlay != null:
		pause_overlay.aplicar_layout(visible_size, safe)
	if opcoes_botao != null:
		opcoes_botao.aplicar_layout(visible_size, safe)
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
	# (a origem menu roda sem pausa: ela e fechada so pelo Voltar)
	if options_screen != null and options_screen.esta_aberta() and not _opcoes_do_menu and not get_tree().paused:
		options_screen.fechar()
	if not started and not _inicio_suspenso():
		if Input.is_action_pressed("jump"):
			_on_Play_button_down()
	_sincronizar_tutorial()

# Acumula o tempo da partida na dificuldade (DifficultyState so conta com Global.is_iniciado())
func _physics_process(delta: float) -> void:
	dificuldade.tick(delta)

# Toque de jogo no menu inicia a partida. A TouchControls (filha) recebe o evento antes e ainda esta inerte,
# entao o toque que inicia nao vira tap de jogo; depois da derrota started segue true e a guarda de
# _on_Play_button_down faz o toque nao ter efeito.
func _input(event: InputEvent) -> void:
	if _inicio_suspenso():
		return
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		_on_Play_button_down()

# A partida nao inicia enquanto a tela de Opcoes esta aberta (tecla `jump` e toque ficam suspensos)
func _inicio_suspenso() -> bool:
	return options_screen != null and options_screen.esta_aberta()

# Acao `pause` com a arvore rodando: pausa (ignorada fora de partida ativa). Com o overlay aberto, quem escuta
# e o proprio overlay (ALWAYS), que consome o evento antes daqui.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not (event is InputEventKey and (event as InputEventKey).echo):
		# Consome so quando a pausa de fato acontece: no menu e na derrota a acao segue para quem a escuta
		if _pausar():
			get_viewport().set_input_as_handled()

func _partida_ativa() -> bool:
	return PauseState.partida_ativa(started, player.is_end())

# Abre o card se a flag "visto" esta ausente (so no inicio da partida); a partida nao espera por ele
func _abrir_tutorial() -> void:
	if tutorial_flag.visto():
		return
	var toque: bool = Global.toque_detectado or _tem_touchscreen()
	tutorial_card.abrir(TutorialCard.Variante.TOQUE if toque else TutorialCard.Variante.TECLADO)

func _tem_touchscreen() -> bool:
	if touchscreen_disponivel.is_valid():
		return bool(touchscreen_disponivel.call())
	return DisplayServer.is_touchscreen_available()

# Pular ou 1o ponto: fecha o card com fade e grava a flag (uma vez: so com o card aberto)
func _concluir_tutorial() -> void:
	if not tutorial_card.esta_aberto():
		return
	tutorial_card.fechar()
	tutorial_flag.marcar()
	_republicar_volumes()

# Card oculto fora de partida ativa (menu, animacao de derrota); nao grava a flag
func _sincronizar_tutorial() -> void:
	if tutorial_card != null and tutorial_card.esta_aberto() and not _partida_ativa():
		tutorial_card.fechar(true)

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

# Opcoes pelo menu (so com o jogo nao iniciado): Play, Last, Best e o botao saem de cena; a arvore nao esta pausada
func _abrir_opcoes_do_menu() -> void:
	if started or options_screen.esta_aberta():
		return
	_opcoes_do_menu = true
	_mostrar_menu(false)
	options_screen.abrir()

# Voltar: fecha a tela e devolve o menu (foco no botao Opcoes) ou o overlay de pausa (foco em Opcoes, ainda pausado)
func _voltar_opcoes() -> void:
	options_screen.fechar()
	_republicar_volumes()
	if _opcoes_do_menu:
		_opcoes_do_menu = false
		if not started:
			_mostrar_menu(true)
			opcoes_botao.focar(true)
		return
	pause_overlay.abrir(PauseOverlay.Botao.OPCOES)

# Republica o ultimo estado com os volumes atuais (ponte do smoke); estado ainda nao publicado nao e inventado
func _republicar_volumes() -> void:
	if ultimo_estado.is_empty():
		return
	var player_dict: Dictionary = ultimo_estado.get("player", {}) as Dictionary
	_publicar_estado(str(ultimo_estado.get("state", "")), bool(player_dict.get("alive", true)))

func _mostrar_menu(valor: bool) -> void:
	playbutton.visible = valor
	lastscore.visible = valor
	bestscore.visible = valor
	if valor:
		opcoes_botao.mostrar()
	else:
		opcoes_botao.ocultar()

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
		_sincronizar_tutorial()
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
	var primeiro_ponto: bool = points < 0
	points += 1
	if primeiro_ponto and ultimo_estado.get("state", "") != GameState.STATE_LOST:
		_concluir_tutorial()
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
	_mostrar_menu(false)
	player.visible = true
	Global.set_iniciado(true)
	_abrir_tutorial()
	_publicar_estado(GameState.STATE_PLAYING, true)

# Monta e publica o estado na ponte do smoke (no-op fora de web debug); score nunca negativo (points inicia em -1)
func _publicar_estado(state: String, alive: bool) -> void:
	ultimo_estado = GameState.build(
		maxi(points, 0),
		Global.get_best_score(),
		state,
		alive,
		roundi(Global.get_volume_music() * 100.0),
		roundi(Global.get_volume_sfx() * 100.0),
		tutorial_card != null and tutorial_card.esta_aberto(),
	)
	GameState.publish(ultimo_estado)
