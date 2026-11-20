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
# Faixa escura atras do bloco Last/Best (legibilidade sobre as plataformas); cor e alfa = fundo do overlay de pausa
const COR_FAIXA_PLACAR: Color = UiHelpers.COR_FUNDO_OVERLAY
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
# Botao Modo do menu e tela Modos (filhos da Stage, criados em _ready); exclusivos com a tela de Opcoes
var modo_botao: ModoBotao = null
var modos_screen: ModosScreen = null
# `jump` segurado ao fechar a tela Modos (Espaco = ui_accept = jump): nao inicia a partida ate soltar
var _aguardar_soltar_jump: bool = false
# Valor de power_ups_habilitados antes da regra do modo (a troca de modo no menu reavalia a partir dele)
var _power_ups_base: bool = true
# Card do tutorial reaberto por Opcoes > Ver tutorial (modal, 2o card da Stage, ultimo filho: recebe a entrada primeiro).
# `_card_partida_escondido`: o card da 1a partida estava aberto e ficou oculto durante a reabertura.
var tutorial_revisao: TutorialCard = null
var _card_partida_escondido: bool = false
# Safe area (coordenadas logicas) da ultima apply_layout; usada pelo HUD (T4)
var safe_area: Rect2 = Rect2()
# Ultimo estado montado para a ponte do smoke (ver GameState); lido pelos testes sem JavaScriptBridge
var ultimo_estado: Dictionary = {}
# Dificuldade da partida (DifficultyState): nasce em _ready, zera a cada Stage nova (reload da cena). Consumidores leem o snapshot
var dificuldade: DifficultyState = null
# Estado de power-up da partida (PowerUpState): membro da Stage, nunca de Global; nasce zerado em cada
# Stage nova (o reload da cena em _on_animation_end recria tudo) e recebe tick junto da dificuldade
var power_up_estado: PowerUpState = null
# Gancho para os modos (f524): falso = nenhuma plataforma nasce com icone e a coleta e ignorada.
# Padrao true; nenhum modo muda nesta feature (so o gancho).
var power_ups_habilitados: bool = true
# Regra do modo de jogo da partida (hook f523): lida de Global.modo_jogo em _ready quando o chamador nao a setou.
# Seam de teste/modos: setar ANTES do add_child (o _ready le `power_ups_habilitados()` da regra antes da copia ao ScrollLevel).
var regra: GameModeRule = null
# Faixa de HUD da duracao do power-up (filha da Stage, criada em _ready)
var power_up_hud: PowerUpHud = null
# Valor anterior do espelho de cor livre (f522 T3): a borda — ativacao/expiracao do Camaleao — forca a
# reavaliacao da colisao de todas as plataformas no mesmo frame (ver _physics_process).
var _cor_livre_anterior: bool = false
# Seed da partida (int ou null) repassada ao ScrollLevel em _enter_tree (f517 T4): setada pelo chamador antes do add_child
var semente_partida: Variant = null
# Estagio da dificuldade na ultima publicacao da ponte; mudanca por tempo republica 1x (ver _physics_process)
var _estagio_publicado: int = 0
# Moldura de aviso de subida de estagio (filha da Stage, criada em _ready) e o `aviso` da ultima publicacao da ponte
var level_up_frame: LevelUpFrame = null
var _aviso_publicado: bool = false
# Alpha da moldura na ultima publicacao (arredondado a 0,01): durante o pulso republica a cada mudanca (prova do smoke)
var _alpha_publicado: float = 0.0
# Par arredondado de player.x/y na ultima publicacao da ponte
var _posicao_publicada: Vector2i = Vector2i.ZERO
# Campo `powerup` (ativo, restante em segundos inteiros, carga) da ultima publicacao: a mudanca de segundo republica 1x
var _powerup_publicado: Dictionary = {}
# y do limite de topo da camera (fracao da altura visivel em CameraFollow); recalculado a cada apply_layout
var _limite_camera: float = 0.0

# Referencias aos nós da interface e jogo
@onready var animation = $AnimationPlayer
@onready var pointslabel = $CanvasLayer/Pontos
@onready var player = $Node2D/Player
@onready var playbutton = $CanvasLayer/Play
@onready var lastscore = $CanvasLayer/Last
@onready var bestscore = $CanvasLayer/Best
@onready var faixaplacar: ColorRect = $CanvasLayer/FaixaPlacar
@onready var loseaudio = $LoseAudio

# Repassa a seed da partida ao ScrollLevel em _enter_tree (f517 T4, D1): roda antes do _ready de qualquer filho,
# entao as linhas do .tscn ja recebem os rngs no _enter_tree do ScrollLevel. Quem seta semente_partida e o chamador,
# ANTES do add_child; nenhum chamador de producao seta nesta feature. Sem seed a atribuicao leva null (no-op).
func _enter_tree() -> void:
	var scroll_level: ScrollLevel = get_node_or_null("ScrollLevel") as ScrollLevel
	if scroll_level != null:
		scroll_level.semente = semente_partida

# Ao sair da arvore (troca de cena): a flag de cor livre e espelho deste no, nao estado global — a Stage
# seguinte nao herda o efeito de uma partida que ja acabou (mesmo padrao do Player com Global.cor_gecko)
func _exit_tree() -> void:
	Global.cor_livre = false

# Inicializa a tela do jogo
func _ready():
	# Avanco da camera do topo (issue #46) roda depois do Player: mesma prioridade 0 da arvore (Stage vem antes dos
	# filhos), entao a Stage precisa de prioridade 1 de physics para ler o y do gecko ja movido neste frame
	process_physics_priority = 1

	# Atualiza displays de pontuação
	lastscore.text = "Last Score: " + str(Global.get_last_score())
	bestscore.text = "Best Score: " + str(Global.get_best_score())
	
	# Configura estado inicial
	Global.set_iniciado(false)
	if regra == null:
		regra = GameModes.de_id(Global.get_modo_jogo()).regra
	# O gancho so desliga: quem setou `power_ups_habilitados = false` antes do add_child continua valendo
	_power_ups_base = power_ups_habilitados
	power_ups_habilitados = power_ups_habilitados and regra.power_ups_habilitados()
	dificuldade = DifficultyState.new(CURVA_DIFICULDADE)
	# Estado de power-up zerado a cada Stage nova (ativo e carga vazios; nunca em Global)
	power_up_estado = PowerUpState.new()
	# Progresso inicial de debug (?progresso=, 0.0 fora do web debug): a partida ja nasce nesse ponto da curva
	dificuldade.progresso_inicial = Global.progresso_inicial
	# Linhas do .tscn e as de ScrollLevel._ready ja nasceram (estagio 0); as novas recebem o estado
	var scroll_level: ScrollLevel = get_node_or_null("ScrollLevel") as ScrollLevel
	if scroll_level != null:
		scroll_level.dificuldade = dificuldade
		# Estado de power-up injetado no mesmo padrao da dificuldade (f522 T1: ponto de efeito; o consumo
		# do fator de scroll e da feature do Desacelera, T4)
		scroll_level.power_up_estado = power_up_estado
		# Gancho dos modos: copiado UMA vez aqui (_ready); o modo (f524) deve setar `power_ups_habilitados`
		# na Stage antes do add_child, mudar depois do _ready nao chega as linhas
		scroll_level.power_ups_habilitados = power_ups_habilitados
	# O Player le o scroll vigente da mesma dificuldade para prever a cor da janela de chegada
	player.dificuldade = dificuldade
	player.power_up_estado = power_up_estado
	player.visible = false
	player.add_point.connect(_on_player_add_point)
	player.power_up_coletado.connect(_coletar_power_up)
	partida_iniciada.connect(_ativar_power_up_inicial)
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
	# Moldura de subida de estagio (CanvasLayer 0: acima do jogo, abaixo do HUD layer 1 e da pausa layer 10); nasce apagada.
	# Pausavel (herda o modo da Stage): pausar a arvore congela o pulso.
	level_up_frame = LevelUpFrame.new()
	level_up_frame.fixa = Global.moldura_fixa
	level_up_frame.lenta = Global.moldura_lenta
	add_child(level_up_frame)
	dificuldade.estagio_mudou.connect(_on_estagio_mudou)
	# Card do tutorial: depois da dica e antes do botao de pausa (abaixo dele no z-order). Fecha e grava a flag no
	# Pular ou no 1o ponto; derrota antes disso nao grava (o card some com a cena e volta na partida seguinte).
	tutorial_flag = TutorialFlag.new(Global.opcoes)
	tutorial_card = TutorialCard.new()
	touch_hint.tutorial_card = tutorial_card
	tutorial_card.pular.connect(_concluir_tutorial)
	add_child(tutorial_card)
	# Faixa de HUD da duracao do power-up (layer do HUD): so le o estado da partida e o card do tutorial
	power_up_hud = PowerUpHud.new()
	power_up_hud.estado = power_up_estado
	power_up_hud.tutorial_card = tutorial_card
	add_child(power_up_hud)
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
	# Botao Modo e tela Modos: depois do botao Opcoes e antes da tela de Opcoes/revisao; o toque neles e consumido antes
	# do _input da Stage (nao inicia a partida) e o toque no Play, fora dos retangulos, segue para a Stage
	modo_botao = ModoBotao.new()
	modo_botao.acionado.connect(_abrir_modos_do_menu)
	modo_botao.foco_alheio = opcoes_botao.tem_foco
	add_child(modo_botao)
	modo_botao.definir_modo(GameModes.de_id(Global.get_modo_jogo()))
	modos_screen = ModosScreen.new()
	modos_screen.fechado.connect(_fechar_modos)
	add_child(modos_screen)
	# Tela de Opcoes (ALWAYS, camada acima do overlay): Voltar devolve ao overlay (pausa) ou ao menu
	options_screen = OptionsScreen.new()
	options_screen.voltar.connect(_voltar_opcoes)
	options_screen.ver_tutorial.connect(_abrir_tutorial_revisao)
	add_child(options_screen)
	# Reabertura do tutorial (ALWAYS, camada acima de Opcoes): ultimo filho, consome todo toque antes do resto
	tutorial_revisao = TutorialCard.new()
	tutorial_revisao.voltar.connect(_fechar_tutorial_revisao)
	add_child(tutorial_revisao)
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
	_limite_camera = CameraFollow.limite_y(visible_size.y)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(visible_size.x, CHECK_THICKNESS)
	var collision: CollisionShape2D = $CheckPlayer/CollisionShape2D
	collision.shape = shape
	collision.position = Vector2(visible_size.x / 2.0, visible_size.y + CHECK_THICKNESS / 2.0)
	_layout_hud(visible_size, safe)
	if touch_hint != null:
		touch_hint.aplicar_layout(visible_size, safe)
	if level_up_frame != null:
		level_up_frame.aplicar_layout(visible_size, safe)
	if tutorial_card != null:
		tutorial_card.aplicar_layout(visible_size, safe)
	if power_up_hud != null:
		power_up_hud.aplicar_layout(visible_size, safe)
	if pause_botao != null:
		pause_botao.aplicar_layout(visible_size, safe)
	_atualizar_zonas_mortas()
	if pause_overlay != null:
		pause_overlay.aplicar_layout(visible_size, safe)
	if opcoes_botao != null:
		opcoes_botao.aplicar_layout(visible_size, safe)
	if modo_botao != null:
		modo_botao.aplicar_layout(visible_size, safe)
	if modos_screen != null:
		modos_screen.aplicar_layout(visible_size, safe)
	if options_screen != null:
		options_screen.aplicar_layout(visible_size, safe)
	if tutorial_revisao != null:
		tutorial_revisao.aplicar_layout(visible_size, safe)

# Zonas mortas do toque de jogo: o botao de pausa e, com o card do tutorial aberto, o retangulo do Pular (7.3/8.1);
# ja deslocados por s_left/s_top. Refeita ao abrir/fechar o card e no layout.
func _atualizar_zonas_mortas() -> void:
	if touch_controls == null or pause_botao == null:
		return
	var mortas: Array[Rect2] = [pause_botao.rect_botao()]
	if tutorial_card != null and tutorial_card.esta_aberto():
		mortas.append(tutorial_card.rect_pular())
	touch_controls.zonas_mortas = mortas

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
	faixaplacar.color = COR_FAIXA_PLACAR
	_place(faixaplacar, 0.0, top + LAST_TOP, visible_size.x, top + BEST_BOTTOM)

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
	if _aguardar_soltar_jump and not Input.is_action_pressed("jump"):
		_aguardar_soltar_jump = false
	if not started and not _inicio_suspenso() and not _aguardar_soltar_jump:
		if Input.is_action_pressed("jump"):
			_on_Play_button_down()
	_sincronizar_tutorial()

# Acumula o tempo da partida na dificuldade (DifficultyState so conta com Global.is_iniciado())
func _physics_process(delta: float) -> void:
	# Camera do topo antes de tudo: depois do Player (process_physics_priority = 1) e antes de publicar player.y na ponte
	_avancar_camera()
	dificuldade.tick(delta)
	# Estado de power-up no mesmo relogio da dificuldade: fora de partida iniciada nao corre e a pausa
	# congela a arvore inteira (sem codigo de pausa proprio, ADR 0008)
	if Global.is_iniciado():
		power_up_estado.tick(delta)
	# Espelho do efeito vigente para a regra de colisao (a Platform le Global.cor_livre, f522 T3):
	# escrito pela dona do estado a cada frame, nunca pela coleta; pausa congela junto (arvore parada).
	# A escrita vem antes da reavaliacao de borda para a Platform ja ler a flag nova.
	var cor_livre_agora: bool = power_up_estado.cor_livre()
	Global.cor_livre = cor_livre_agora
	# f522 T3: bordas da cor livre (ativacao/expiracao do Camaleao) reavaliam a colisao de todas as
	# plataformas no mesmo frame — o Player so reavalia subindo (velocity.y < 0) e, ao expirar caindo, a
	# regra de cor so voltaria no proximo pulo. A plataforma sob o gecko entra como actual_platform e a
	# Global pula a atual na reavaliacao: o gecko nao cai ao expirar em cima de cor diferente.
	if cor_livre_agora != _cor_livre_anterior:
		_cor_livre_anterior = cor_livre_agora
		Global.player_color_changed(Global.cor_gecko, player.actual_platform)
	# O estagio sobe por tempo sem evento de ponto/Play: republica 1x por mudanca, nunca apos a derrota
	# O mesmo vale para o `aviso` (pulso da moldura comecou ou terminou)
	if ultimo_estado.get("state", "") == GameState.STATE_LOST:
		return
	# Fim de partida pela regra do modo: so com a partida iniciada (no menu nunca dispara)
	if Global.is_iniciado() and not player.is_end() and regra.fim_por_regra(_ctx_partida()):
		_encerrar_partida(player)
		return
	if (
		dificuldade.estagio() != _estagio_publicado
		or _aviso_atual() != _aviso_publicado
		or _alpha_atual() != _alpha_publicado
		or _powerup_atual() != _powerup_publicado
	):
		_republicar_estado()
		return
	# Posicao do jogador (par arredondado) em partida: republica 1x por mudanca; parado ou fora de partida, nunca
	if started and ultimo_estado.get("state", "") == GameState.STATE_PLAYING and _posicao_atual() != _posicao_publicada:
		_republicar_estado()

# Aplica o avanco da camera do topo (issue #46) no ScrollLevel, que sobe o mundo quando o gecko passa do limite.
# A guarda de partida iniciada e a do proprio ScrollLevel (a mesma do scroll da curva); sem ScrollLevel (Stage
# isolada em teste) ou antes do primeiro apply_layout nao ha o que avancar.
func _avancar_camera() -> void:
	if _limite_camera <= 0.0:
		return
	var scroll_level: ScrollLevel = get_node_or_null("ScrollLevel") as ScrollLevel
	if scroll_level == null:
		return
	scroll_level.avancar_camera(player, _limite_camera)

# Par arredondado (pixels logicos) da posicao do jogador, o mesmo publicado em `player.x/y`
func _posicao_atual() -> Vector2i:
	return Vector2i(roundi(player.global_position.x), roundi(player.global_position.y))

# Subida de estagio em partida: a moldura pulsa N vezes (N = estagio novo). Depois da derrota nao pulsa.
func _on_estagio_mudou(novo: int) -> void:
	if ultimo_estado.get("state", "") == GameState.STATE_LOST:
		return
	level_up_frame.pulsar(novo)

func _aviso_atual() -> bool:
	return level_up_frame != null and level_up_frame.pulsando()

# Alpha da moldura (0-1, arredondado a 0,01) enquanto pulsa; 0 com a moldura apagada
func _alpha_atual() -> float:
	if not _aviso_atual():
		return 0.0
	return snappedf(level_up_frame.alpha(), 0.01)

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
	var revisao := tutorial_revisao != null and tutorial_revisao.esta_aberto()
	var modos := modos_screen != null and modos_screen.esta_aberta()
	return revisao or modos or (options_screen != null and options_screen.esta_aberta())

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
	_atualizar_zonas_mortas()

func _tem_touchscreen() -> bool:
	if touchscreen_disponivel.is_valid():
		return bool(touchscreen_disponivel.call())
	return DisplayServer.is_touchscreen_available()

# Pular ou 1o ponto: fecha o card com fade e grava a flag (uma vez: so com o card aberto)
func _concluir_tutorial() -> void:
	if not tutorial_card.esta_aberto():
		return
	tutorial_card.fechar()
	_atualizar_zonas_mortas()
	tutorial_flag.marcar()
	_republicar_estado()

# Card oculto fora de partida ativa (menu, animacao de derrota); nao grava a flag
func _sincronizar_tutorial() -> void:
	if tutorial_card != null and tutorial_card.esta_aberto() and not _partida_ativa():
		tutorial_card.fechar(true)
		_atualizar_zonas_mortas()

# Pausa a arvore (Global.iniciado nao muda), cancela o toque de jogo em curso e abre o overlay
func _pausar() -> bool:
	if pause_state.esta_pausado() or not pause_state.pausar():
		return false
	touch_controls.cancelar_tudo()
	pause_botao.cancelar()
	pause_overlay.abrir()
	_atualizar_card_partida()
	return true

func _retomar() -> void:
	pause_state.retomar()
	pause_overlay.fechar()
	options_screen.fechar()
	_atualizar_card_partida()

# Regra unica do card da 1a partida (handoff 12.5): visivel = aberto, sem pausa e sem a reabertura por cima.
# Aberto/fechado (`esta_aberto()`, fade, flag) nao mudam.
func _atualizar_card_partida() -> void:
	tutorial_card.visible = (
		tutorial_card.esta_aberto() and not pause_state.esta_pausado() and not _card_partida_escondido
	)

# Opcoes pela pausa: o overlay sai de cena (fechar o deixa invisivel e sem entrada) e a arvore segue pausada
func _abrir_opcoes_da_pausa() -> void:
	pause_overlay.fechar()
	options_screen.abrir()

# Opcoes pelo menu (so com o jogo nao iniciado): Play, Last, Best e o botao saem de cena; a arvore nao esta pausada
func _abrir_opcoes_do_menu() -> void:
	if started or options_screen.esta_aberta() or modos_screen.esta_aberta():
		return
	_opcoes_do_menu = true
	_mostrar_menu(false)
	options_screen.abrir()

# Modo pelo menu (so com o jogo nao iniciado): Play, Last, Best e os botoes saem de cena; a arvore nao esta pausada
func _abrir_modos_do_menu() -> void:
	if started or modos_screen.esta_aberta() or options_screen.esta_aberta():
		return
	if not modos_screen.abrir(GameModes.de_id(Global.get_modo_jogo())):
		return
	_mostrar_menu(false)

# OK: aplica o modo exibido, fecha a tela e devolve o menu com Best/Last do modo escolhido (foco no botao Modo)
func _fechar_modos(modo: GameMode) -> void:
	modos_screen.fechar()
	Global.set_modo_jogo(modo.id)
	var atual: GameMode = GameModes.de_id(Global.get_modo_jogo())
	regra = atual.regra
	power_ups_habilitados = _power_ups_base and regra.power_ups_habilitados()
	var scroll_level: ScrollLevel = get_node_or_null("ScrollLevel") as ScrollLevel
	if scroll_level != null:
		scroll_level.power_ups_habilitados = power_ups_habilitados
	lastscore.text = "Last Score: " + str(Global.get_last_score())
	bestscore.text = "Best Score: " + str(Global.get_best_score())
	modo_botao.definir_modo(atual)
	_aguardar_soltar_jump = Input.is_action_pressed("jump")
	if not started:
		_mostrar_menu(true)
		modo_botao.focar(true)
	_republicar_estado()

# Voltar: fecha a tela e devolve o menu (foco no botao Opcoes) ou o overlay de pausa (foco em Opcoes, ainda pausado)
func _voltar_opcoes() -> void:
	options_screen.fechar()
	_republicar_estado()
	if _opcoes_do_menu:
		_opcoes_do_menu = false
		if not started:
			_mostrar_menu(true)
			opcoes_botao.focar(true)
		return
	pause_overlay.abrir(PauseOverlay.Botao.OPCOES)

# Ver tutorial: Opcoes some, o card da 1a partida (se aberto) fica oculto e o card reaberto assume a entrada. A origem
# (pausa x menu) e a flag `tutorial/visto` nao mudam.
func _abrir_tutorial_revisao() -> void:
	options_screen.fechar()
	_card_partida_escondido = tutorial_card.esta_aberto()
	_atualizar_card_partida()
	var toque: bool = Global.toque_detectado or _tem_touchscreen()
	tutorial_revisao.abrir(
		TutorialCard.Variante.TOQUE if toque else TutorialCard.Variante.TECLADO, TutorialCard.Modo.REABERTURA
	)

# Voltar (ou Esc/P) do card reaberto: devolve o card da 1a partida e Opcoes, com foco em Ver tutorial
func _fechar_tutorial_revisao() -> void:
	tutorial_revisao.fechar(true)
	_card_partida_escondido = false
	_atualizar_card_partida()
	options_screen.abrir(OptionsScreen.Item.VER_TUTORIAL)

# Republica o ultimo estado com os volumes e o estagio atuais (ponte do smoke); estado ainda nao publicado nao e inventado
func _republicar_estado() -> void:
	if ultimo_estado.is_empty():
		return
	var player_dict: Dictionary = ultimo_estado.get("player", {}) as Dictionary
	_publicar_estado(str(ultimo_estado.get("state", "")), bool(player_dict.get("alive", true)))

func _mostrar_menu(valor: bool) -> void:
	playbutton.visible = valor
	lastscore.visible = valor
	bestscore.visible = valor
	faixaplacar.visible = valor
	if valor:
		opcoes_botao.mostrar()
		modo_botao.mostrar()
	else:
		opcoes_botao.ocultar()
		modo_botao.ocultar()

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
		# A regra do modo decide se cair encerra (Classico: sim, como sempre)
		if not regra.ao_cair(_ctx_partida()):
			return
		_encerrar_partida(body)

# Encerra a partida (derrota por queda ou fim por regra): grava o recorde so se a regra do modo permite
func _encerrar_partida(body) -> void:
	body.lose_game()
	level_up_frame.interromper()
	_sincronizar_tutorial()
	loseaudio.play()
	if regra.grava_recorde():
		Global.set_score(points)
	_publicar_estado(GameState.STATE_LOST, false)
	animation.play("lose_animation")

# Snapshot da partida entregue a regra do modo
func _ctx_partida() -> Dictionary:
	return {"pontos": points, "iniciado": Global.is_iniciado()}

# Reinicia o jogo após a animação de perda
func _on_animation_end():
	get_tree().change_scene_to_file("res://scenes/Stage.tscn")

# Callback para quando o jogador ganha um ponto
func _on_player_add_point():
	add_point()


# Coleta do pouso do jogador: resolve o tipo no registro e guarda no estado da partida. Com o gancho de
# modos desligado a coleta e ignorada (o estado segue vazio); tipo desconhecido nao ativa nada.
func _coletar_power_up(tipo: StringName) -> void:
	if not power_ups_habilitados or tipo == &"":
		return
	var power_up: PowerUp = PowerUps.resolver(tipo)
	if power_up == null:
		return
	power_up_estado.coletar(power_up)

# Power-up inicial de debug (`?powerup=`, Global.power_up_inicial) ao iniciar a partida. "" = nenhum; o PowerUpDeTeste
# nao esta no registro de producao, entao e resolvido aqui; os demais nomes passam pelo registro (desconhecido = nada).
func _ativar_power_up_inicial() -> void:
	var nome: String = Global.power_up_inicial
	if nome == "":
		return
	var power_up: PowerUp = null
	if StringName(nome) == PowerUpDeTeste.NOME_PADRAO:
		power_up = PowerUpDeTeste.new()
	else:
		power_up = PowerUps.resolver(StringName(nome))
	if power_up == null:
		return
	power_up_estado.coletar(power_up)

# Campo `powerup` da ponte lido do estado da partida: restante arredondado para cima (como GameState.build)
func _powerup_atual() -> Dictionary:
	var ativo: PowerUp = power_up_estado.ativo()
	return {
		"ativo": "" if ativo == null else String(ativo.nome),
		"restante": ceili(power_up_estado.restante()),
		"carga": power_up_estado.carga(),
	}

# Adiciona um ponto à pontuação e atualiza a interface
func add_point():
	# points inicia em -1: o pouso inicial na plataforma de partida leva a 0 e nao conta; o 1o ponto real leva 0 -> 1
	var primeiro_ponto: bool = points == 0
	if points < 0:
		# Ponto de partida: vira 0 sem consultar a regra do modo (a regra de pontuacao nunca ve esse ponto)
		points = 0
	else:
		# Pontos efetivos de 1 ponto bruto pela regra do modo (Classico: 1)
		points += regra.pontuar(1)
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
	_estagio_publicado = dificuldade.estagio()
	_aviso_publicado = _aviso_atual() and state != GameState.STATE_LOST
	_posicao_publicada = _posicao_atual()
	_alpha_publicado = _alpha_atual() if state != GameState.STATE_LOST else 0.0
	_powerup_publicado = _powerup_atual()
	ultimo_estado = GameState.build(
		maxi(points, 0),
		Global.get_best_score(),
		state,
		alive,
		roundi(Global.get_volume_music() * 100.0),
		roundi(Global.get_volume_sfx() * 100.0),
		tutorial_card != null and tutorial_card.esta_aberto(),
		_estagio_publicado,
		_aviso_publicado,
		float(_posicao_publicada.x),
		float(_posicao_publicada.y),
		_alpha_publicado,
		str(_powerup_publicado["ativo"]),
		float(_powerup_publicado["restante"]),
		int(_powerup_publicado["carga"]),
		String(Global.get_modo_jogo()),
	)
	GameState.publish(ultimo_estado)
