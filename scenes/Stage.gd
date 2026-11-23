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
# f528 T6 (D3): Play desabilitado com o texto do dia ("Ja jogado hoje", sem contagem regressiva), no estilo
# existente de Play desabilitado. O texto do dia usa a fonte 16 (TAMANHO_TEXTO de UiHelpers) e o botao alarga
# para caber (o rotulo "Play" em 32 nao cabe nos 56 px do Play normal).
const TEXTO_DIA_JA_JOGADO: String = "Ja jogado hoje"
const TAMANHO_TEXTO_DIA: int = 16
const PLAY_WIDTH_DIA: float = 132.0
const COR_TEXTO_DIA: Color = Color(0.93, 0.96, 0.9)
# Chaves do ctx do dia (f528 T6), citadas pela Stage e pela regra do Diario so via PartidaCtx
const CTX_DIA: String = PartidaCtx.DIA
const CTX_DIA_DA_STAGE: String = PartidaCtx.DIA_DA_STAGE
const CTX_STORE_DIARIO: String = PartidaCtx.STORE_DIARIO
# Faixa escura atras do bloco Last/Best (legibilidade sobre as plataformas); cor e alfa = fundo do overlay de pausa
const COR_FAIXA_PLACAR: Color = UiHelpers.COR_FUNDO_OVERLAY
# Curva de producao (estagios da dificuldade); o estado de cada partida e criado em _ready a partir dela
const CURVA_DIFICULDADE: DifficultyCurve = preload("res://ressources/curva_dificuldade.tres")
# Chaves do ctx da partida entregue as regras de modo (definidas em PartidaCtx; a Stage e as regras citam so a constante)
const CTX_PONTOS: String = PartidaCtx.PONTOS
const CTX_INICIADO: String = PartidaCtx.INICIADO
const CTX_TEMPO: String = PartidaCtx.TEMPO
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
# f527 T6: recarga da cena pedida por Sair na pausa; f528 T5 tambem pela troca de modo que cruza a fronteira do
# Diario no menu (a fase de fundo muda de origem: dia x sorteio). Callable injetavel em teste: o GUT nao pode
# trocar a cena do proprio runner, entao registra o pedido; invalido (producao) recarrega.
var recarregar_cena: Callable = Callable()
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
# Tamanho visivel da ultima apply_layout (f526 T5): area de candidatura do reaparecimento da Segunda chance
var _tamanho_visivel: Vector2 = Vector2(180.0, 320.0)
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
# Ultima plataforma pisada (a do ultimo ponto); pode ser liberada (checar is_instance_valid antes de ler). f527 T4
var _ultima_plataforma: Node2D = null
# Faixa de HUD da duracao do power-up (filha da Stage, criada em _ready)
var power_up_hud: PowerUpHud = null
# Valor anterior do espelho de cor livre (f522 T3): a borda — ativacao/expiracao do Camaleao — forca a
# reavaliacao da colisao de todas as plataformas no mesmo frame (ver _physics_process).
var _cor_livre_anterior: bool = false
# Seed da partida (int ou null) repassada ao ScrollLevel em _enter_tree (f517 T4): setada pelo chamador antes do add_child
var semente_partida: Variant = null
# Dia UTC usado como seed desta Stage (f528 T5, D2a): guardado em _enter_tree quando a regra do modo persistido
# pede a seed do dia (Diario); DIA_INVALIDO (-1) = relogio invalido ou modo sem seed do dia — a sentinela nunca
# vira seed (o validador devolve null). O bloqueio/gasto da tentativa e o reload da virada (T6) leem daqui.
var _dia_da_stage: int = DiaUtc.DIA_INVALIDO
# f528 T6: store do Desafio diario desta Stage (so no Diario): a tentativa e o resultado do dia passam por
# ele — nunca pelo best_score_* do modo. Nasce no _ready (uma leitura por Stage; o reload da cena re-le o
# disco, entao o estado de outra Stage/sessao chega) e entra no ctx para a regra consultar a tentativa.
var _store_diario: DesafioDiarioStore = null
# f528 T6 (D3): rotulo original do Play e o estado do dia avaliado na UI (decide largura/texto no layout)
var _texto_play_original: String = ""
var _ui_dia_bloqueada: bool = false
# Tamanho de fonte do Play antes da UI do dia (override da cena ou do layout), para o estado habilitado restaurar
var _play_capturado: bool = false
var _play_tinha_tamanho_proprio: bool = false
var _tamanho_play_original: int = 0
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
# Relogio restante (inteiro, segundos para cima) da ultima publicacao (f524 T5): a mudanca de segundo republica 1x
var _relogio_publicado: int = 0
# y do limite de topo da camera (fracao da altura visivel em CameraFollow); recalculado a cada apply_layout
var _limite_camera: float = 0.0
# Relogio da partida em segundos (f524 T3): membro da Stage (nunca da regra, que e instancia reusada); nasce em 0 a cada
# Stage nova. So corre com a partida iniciada, no delta da fisica (pausa congela a arvore; power-up nao o escala).
var tempo_partida: float = 0.0

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
# ANTES do add_child (nenhum chamador de producao seta); a seed passa por SeedPartida.validar (f528 T1): valor
# invalido vira null (sem seed), nunca chega ao ScrollLevel como String/float/negativo. f528 T5 (D2a): sem
# semente_partida, o modo persistido em Global decide — usa_seed_do_dia() (Diario) atribui o dia UTC vigente como
# seed e guarda o dia usado em _dia_da_stage; quem setou antes do add_child (teste, debug) vence o dia; modo sem
# seed do dia segue sorteado como hoje. O Diario nunca toca Global.aplicar_seed.
func _enter_tree() -> void:
	var scroll_level: ScrollLevel = get_node_or_null("ScrollLevel") as ScrollLevel
	if scroll_level == null:
		return
	if semente_partida != null:
		scroll_level.semente = SeedPartida.validar(semente_partida)
		return
	if not GameModes.de_id(Global.get_modo_jogo()).regra.usa_seed_do_dia():
		scroll_level.semente = null
		return
	var dia: int = _dia_utc_atual()
	_dia_da_stage = dia
	scroll_level.semente = SeedPartida.validar(dia)


# Dia UTC vigente pelo relogio do dia (f528 T5): Global.relogio_do_dia e o ponto de injecao do DiaUtc — os smokes
# debug (`?dia=`) e os testes injetam ANTES do add_child; sem injecao vale o relogio do sistema. Lido a cada
# chamada (nao cacheia), como limite_tempo_s. Relogio invalido devolve a sentinela, que nunca vira seed.
func _dia_utc_atual() -> int:
	return DiaUtc.new(Global.relogio_do_dia()).dia_atual()

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
	# f528 T6: store do dia quando o modo pede (Diario) e o rotulo original do Play para a UI do dia restaurar
	_store_do_dia()
	_texto_play_original = playbutton.text
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
	_aplicar_fator_scroll_forcado()
	_aplicar_visibilidade_recorde(true)
	player.power_up_estado = power_up_estado
	player.visible = false
	player.add_point.connect(_on_player_add_point)
	player.power_up_coletado.connect(_coletar_power_up)
	partida_iniciada.connect(_ativar_power_up_inicial)
	_publicar_estado(GameState.STATE_MENU, true)
	# f526 T5: o sinal da linha de derrota dispara durante o flush de queries da fisica; o resgate da
	# Segunda chance reavalia colisao de plataformas (T4) e isso so e licito fora do flush. Conectado
	# diferido o handler roda no fim do mesmo frame (o padrao do call_deferred do lose_game); derrota e
	# resgate seguem atomicos no handler e nada muda para quem chama o metodo direto.
	var check: Area2D = $CheckPlayer as Area2D
	var ao_sair_da_faixa := Callable(self, "_on_CheckPlayer_body_exited")
	if check.body_exited.is_connected(ao_sair_da_faixa):
		check.body_exited.disconnect(ao_sair_da_faixa)
	check.body_exited.connect(ao_sair_da_faixa, CONNECT_DEFERRED)

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
	power_up_hud.fonte_relogio = _relogio_para_hud
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
	pause_overlay.sair.connect(_sair_da_pausa)
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
	# f528 T6: UI do dia do menu avaliada ao nascer (o _on_viewport_size_changed acima ja deixou o layout pronto)
	_aplicar_ui_dia()

# Reaplica o layout com o tamanho/safe area atuais do viewport
func _on_viewport_size_changed() -> void:
	apply_layout(VisibleArea.visible_size(get_viewport()), VisibleArea.current_safe_rect(get_window()))

# Posiciona a faixa de derrota logo abaixo da borda inferior visivel (topo em y = altura, espessura 20)
# e com a largura visivel. Tamanho injetado: testavel sem janela. Chamavel de novo (resize em runtime).
# Sobrescreve a shape e a posicao literais da CollisionShape2D do Stage.tscn (a cena guarda so o valor de 180x320).
func apply_layout(visible_size: Vector2, safe: Rect2) -> void:
	safe_area = safe
	_tamanho_visivel = visible_size
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
	# f528 T6: o Play alarga no estado do dia (o texto "Ja jogado hoje" nao cabe nos 56 px do rotulo)
	var play_width := PLAY_WIDTH_DIA if _ui_dia_bloqueada else PLAY_WIDTH
	var play_left := (visible_size.x - play_width) / 2.0
	_place(playbutton, play_left, top + PLAY_TOP, play_left + play_width, top + PLAY_BOTTOM)
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
	# Entre o _ready e o 1o frame de fisica a flag guarda o valor anterior: a unica protecao contra uma Stage nova
	# herdar cor livre e o zerar em _exit_tree (teste C596).
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
	# Relogio da partida: antes da regra, para o tick que chega ao limite encerrar no mesmo tick (parado apos `lost`: o return acima)
	tempo_partida += delta if Global.is_iniciado() else 0.0
	# Fim de partida pela regra do modo: so com a partida iniciada (no menu nunca dispara)
	if Global.is_iniciado() and not player.is_end() and regra.fim_por_regra(_ctx_partida()):
		_encerrar_partida(player)
		return
	if (
		dificuldade.estagio() != _estagio_publicado
		or _aviso_atual() != _aviso_publicado
		or _alpha_atual() != _alpha_publicado
		or _powerup_atual() != _powerup_publicado
		or _relogio_atual() != _relogio_publicado
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

# Pausa a arvore (Global.iniciado nao muda), cancela o toque de jogo em curso e abre o overlay — com o botao
# Sair quando a regra do modo permite (predicado unico `permite_sair_pela_pausa()`, o mesmo da acao)
func _pausar() -> bool:
	if pause_state.esta_pausado() or not pause_state.pausar():
		return false
	touch_controls.cancelar_tudo()
	pause_botao.cancelar()
	pause_overlay.definir_permite_sair(regra.permite_sair_pela_pausa())
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


# f527 T6 (D5): Sair da pausa — so a regra do modo permite (o mesmo predicado `permite_sair_pela_pausa()` que
# decide a visibilidade do botao). Despausa a arvore e recarrega a Stage: a nova nasce no menu (`started ==
# false`), sem `Global.set_score` (recorde do modo intacto) e sem som/animacao de derrota (a derrota nunca roda).
# `recarregar_cena` (via `_recarregar_stage`): Callable injetavel em teste (o GUT nao pode trocar a cena do
# proprio runner); sem injecao vale o reload real do fim da animacao de perda (`_on_animation_end`).
func _sair_da_pausa() -> void:
	if not regra.permite_sair_pela_pausa():
		return
	pause_state.retomar()
	pause_overlay.fechar()
	options_screen.fechar()
	_recarregar_stage()


# f528 T5: recarga da Stage (a mesma do fim da animacao de derrota). A seam `recarregar_cena` registra o pedido
# em teste (o GUT nao pode trocar a cena do proprio runner); sem injecao vale o reload real do `_on_animation_end`,
# que recria a cena e roda o _enter_tree desta Stage de novo (modo persistido + seed do dia, se for o caso).
func _recarregar_stage() -> void:
	if recarregar_cena.is_valid():
		recarregar_cena.call()
		return
	_on_animation_end()

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

# OK: aplica o modo exibido, fecha a tela e devolve o menu com Best/Last do modo escolhido (foco no botao Modo).
# f528 T5 (D2a): troca que cruza a fronteira do Diario (entrar ou sair) recarrega a Stage no menu — a fase de
# fundo nasce da seed do dia (ou sorteada) sem reload no Play; trocas entre modos sem seed do dia (inclusive
# reconfirmar o Diario) seguem sem recarga, atualizando tudo in place como antes.
func _fechar_modos(modo: GameMode) -> void:
	modos_screen.fechar()
	Global.set_modo_jogo(modo.id)
	var atual: GameMode = GameModes.de_id(Global.get_modo_jogo())
	# Fronteira antes de trocar a regra: `regra` ainda e a do modo anterior ao OK
	var recarregar := atual.regra.usa_seed_do_dia() != regra.usa_seed_do_dia()
	regra = atual.regra
	power_ups_habilitados = _power_ups_base and regra.power_ups_habilitados()
	var scroll_level: ScrollLevel = get_node_or_null("ScrollLevel") as ScrollLevel
	if scroll_level != null:
		scroll_level.power_ups_habilitados = power_ups_habilitados
	_aplicar_fator_scroll_forcado()
	_aplicar_visibilidade_recorde(not started)
	# f528 T6: placar e Play reavaliados com o modo vigente (C787: o Best do Diario le o resultado do dia)
	_aplicar_ui_dia()
	modo_botao.definir_modo(atual)
	_aguardar_soltar_jump = Input.is_action_pressed("jump")
	if not started:
		_mostrar_menu(true)
		modo_botao.focar(true)
	_republicar_estado()
	if recarregar:
		_recarregar_stage()

# Entrega o fator de scroll da regra do modo (f527) ao ScrollLevel e ao Player (a previsao de cor do pouso usa o
# scroll que de fato move o mundo). Reaplicado na troca de modo do menu, sem reload.
func _aplicar_fator_scroll_forcado() -> void:
	var fator: float = regra.fator_scroll_forcado()
	var scroll_level: ScrollLevel = get_node_or_null("ScrollLevel") as ScrollLevel
	if scroll_level != null:
		scroll_level.fator_forcado = fator
	player.fator_scroll_forcado = fator

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

# f527 T5 (D1): Last, Best e a faixa so aparecem com o menu visivel E a regra do modo mostrando recorde (Zen: nunca)
func _aplicar_visibilidade_recorde(menu_visivel: bool) -> void:
	var visivel: bool = menu_visivel and regra.mostra_recorde()
	lastscore.visible = visivel
	bestscore.visible = visivel
	faixaplacar.visible = visivel

func _mostrar_menu(valor: bool) -> void:
	playbutton.visible = valor
	_aplicar_visibilidade_recorde(valor)
	if valor:
		# f528 T6: menu de volta a aparecer (Opcoes/Modos fecharam): UI do dia reavaliada (C787/C779)
		_aplicar_ui_dia()
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
	# Corpo ja fora da arvore (a liberacao da Stage dispara o sinal no teardown): nada a decidir
	if not body.is_inside_tree():
		return
	if !body.is_jumping() && !body.is_end():
		# f527 T4: a regra do modo pode trocar a queda por reposicionamento (Zen); sem derrota e sem gastar carga
		if regra.reposiciona_ao_cair():
			_reposicionar_na_ultima_plataforma(body)
			return
		# A regra do modo decide se cair encerra (Classico: sim, como sempre); falso = carga intacta (Q5)
		if not regra.ao_cair(_ctx_partida()):
			return
		# f526 T5: com carga guardada o reaparecimento substitui a derrota; sem carga ou sem
		# candidata visivel (Q3) vale a derrota padrao
		if _tentar_reaparecimento(body):
			return
		_encerrar_partida(body)

# f527 T4 (Zen): devolve o gecko a ultima plataforma pisada, com a cor dela (D4); pontos intactos (D2). Sem pisada
# ainda ou com a ultima ja liberada (D3), cai na escolha da Segunda chance (SegundaChanceAlvo) com a cor da escolhida.
# Sem candidata, vale a plataforma solida mais proxima; sem plataforma alguma nao ha o que fazer (o gecko segue caindo).
func _reposicionar_na_ultima_plataforma(body) -> void:
	var alvo: Platform = null
	var cor: int = -1
	if is_instance_valid(_ultima_plataforma):
		alvo = _ultima_plataforma as Platform
		cor = int(alvo.color)
	else:
		_ultima_plataforma = null
		var entradas: Array = ReachableColors.entradas_de_plataformas(Global.platforms)
		var escolha: Dictionary = SegundaChanceAlvo.escolher(
			entradas,
			body.global_position,
			int(Global.cor_gecko),
			_tamanho_visivel.x,
			_tamanho_visivel.y,
			player.scroll_efetivo()
		)
		if int(escolha["indice"]) >= 0:
			alvo = escolha["entrada"]["plataforma"]
			cor = int(escolha["cor"])
		else:
			# Sem candidata da Segunda chance: no Zen a partida nao encerra e, sem novo body_exited, ficaria presa
			# com o gecko caindo. Vale a plataforma solida mais proxima da queda, de qualquer cor (cor dela assumida)
			var indice: int = _mais_proxima_solida(entradas, body.global_position)
			if indice < 0:
				return
			alvo = entradas[indice]["plataforma"]
			cor = int(entradas[indice]["cor"])
	body.reaparecer_sobre(alvo, cor)
	_publicar_estado(GameState.STATE_PLAYING, true)


# f527 correcao 2: indice da entrada solida (nem desmoronada, nem desmoronando, nem invisivel por piscar) acima da
# linha de derrota mais proxima de `ponto` (dx ciente do wrap horizontal); -1 sem nenhuma
func _mais_proxima_solida(entradas: Array, ponto: Vector2) -> int:
	var melhor: int = -1
	var melhor_distancia: float = INF
	for i in range(entradas.size()):
		var e: Dictionary = entradas[i]
		if float(e["y"]) > _tamanho_visivel.y:
			continue
		if not SegundaChanceAlvo.e_solida(e):
			continue
		var dx_abs: float = absf(float(e["x"]) - ponto.x)
		var dx: float = minf(dx_abs, _tamanho_visivel.x - dx_abs)
		var distancia: float = Vector2(dx, float(e["y"]) - ponto.y).length()
		if distancia < melhor_distancia:
			melhor_distancia = distancia
			melhor = i
	return melhor

# f526 T5: gasta a carga da Segunda chance na linha de derrota. O alvo vem do predicado puro de T3 (a
# Stage nunca recalcula a escolha) e o reposicionamento e o teleporte de resgate de T4; a carga so sai
# no caminho que de fato reaparece. Sem carga, sem candidata visivel (Q3: derrota padrao com a carga
# guardada) ou regra do modo que nao encerra: false. Sem som, sem animacao e sem encerrar: a partida
# segue em curso e a ponte ve carga 0 no mesmo frame do consumo.
func _tentar_reaparecimento(body) -> bool:
	if power_up_estado.carga() <= 0:
		return false
	var escolha: Dictionary = SegundaChanceAlvo.escolher(
		ReachableColors.entradas_de_plataformas(Global.platforms),
		body.global_position,
		int(Global.cor_gecko),
		_tamanho_visivel.x,
		_tamanho_visivel.y,
		player.scroll_efetivo()
	)
	if int(escolha["indice"]) < 0:
		# Q3: sem candidata visivel a carga fica guardada e vale a derrota padrao
		return false
	body.reaparecer_sobre(escolha["entrada"]["plataforma"], int(escolha["cor"]))
	power_up_estado.consumir_carga()
	_publicar_estado(GameState.STATE_PLAYING, true) # f526 T5: carga 0 na ponte no mesmo frame do consumo
	return true

# Encerra a partida (derrota por queda ou fim por regra): grava o recorde so se a regra do modo permite
func _encerrar_partida(body) -> void:
	body.lose_game()
	level_up_frame.interromper()
	_sincronizar_tutorial()
	loseaudio.play()
	if regra.grava_recorde():
		Global.set_score(points)
	# f528 T6 (D7): o resultado do dia vive no DesafioDiarioStore, sempre no DIA DA STAGE — o do inicio:
	# virada no meio da partida nao muda o dia de gravacao (C784) — e nunca no best_score_* do modo (C781).
	# Stage Diario sem dia (seed setada pelo chamador em teste) nao grava nada no store.
	var store_dia: DesafioDiarioStore = _store_do_dia()
	if store_dia != null and _dia_da_stage != DiaUtc.DIA_INVALIDO:
		store_dia.gravar_resultado(_dia_da_stage, points)
	_publicar_estado(GameState.STATE_LOST, false)
	animation.play("lose_animation")

# Snapshot da partida entregue a regra do modo. f528 T6: no Diario acrescenta o dia vigente, o dia guardado
# pela Stage e o store do dia (a regra consulta a tentativa; gasto e gravacao sao sempre da Stage, no dia
# guardado) — o _ctx_partida roda por frame de fisica, entao as chaves extras so entram no modo que as usa.
func _ctx_partida() -> Dictionary:
	var ctx := {CTX_PONTOS: points, CTX_INICIADO: Global.is_iniciado(), CTX_TEMPO: tempo_partida}
	if regra != null and regra.usa_seed_do_dia():
		ctx[CTX_DIA] = _dia_utc_atual()
		ctx[CTX_DIA_DA_STAGE] = _dia_da_stage
		ctx[CTX_STORE_DIARIO] = _store_do_dia()
	return ctx


# f528 T6: store do dia desta Stage, so enquanto o modo vigente usa a seed do dia (Diario): criado sob demanda
# (uma leitura por Stage) e null nos demais modos — a UI e o gasto nunca olham o store num modo sem dia, mesmo
# depois de uma troca Diario -> Classico na mesma Stage (a recarga da fronteira vem em seguida).
func _store_do_dia() -> DesafioDiarioStore:
	if regra == null or not regra.usa_seed_do_dia():
		return null
	if _store_diario == null:
		_store_diario = DesafioDiarioStore.new()
	return _store_diario

# Reinicia o jogo após a animação de perda
func _on_animation_end():
	get_tree().change_scene_to_file("res://scenes/Stage.tscn")

# Callback para quando o jogador ganha um ponto
func _on_player_add_point():
	# f527 T4: a plataforma do pouso (a pontuada) e o alvo do reposicionamento do Zen; sem tipo: pode ser liberada depois
	_ultima_plataforma = player.actual_platform
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

# Relogio restante do Contra o tempo (f524 T5): max(0, limite - tempo) para cima, inteiro. Fora do modo `tempo` e 0
# (o campo nunca muda nos outros modos). Le o limite a cada chamada (Global.limite_tempo_s: seam ou .tres).
func _relogio_atual() -> int:
	if Global.get_modo_jogo() != GameModes.ID_TEMPO:
		return 0
	return ceili(maxf(0.0, Global.limite_tempo_s() - tempo_partida))

# f527 T8: relogio entregue ao HUD. Ativo = a regra do modo atual tem relogio e a partida nao esta em `lost`;
# o restante e o ultimo publicado (o HUD nao conhece modo nem estado publicado).
func _relogio_para_hud() -> Dictionary:
	var tem: bool = regra.tem_relogio()
	var perdida: bool = ultimo_estado.get("state", "") == GameState.STATE_LOST
	var publicado: Dictionary = ultimo_estado.get("relogio", {})
	return {"ativo": tem and not perdida, "restante": float(publicado.get("restante", 0))}


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
	# f528 T6: o mesmo predicado do estado do botao decide as tres entradas de inicio (Play, acao `jump` do
	# _process, toque do _input). Bloqueado, nada comeca — sem started, sem tutorial, sem som, sem
	# partida_iniciada; liberado, a tentativa do dia e gasta ANTES do started (conta mesmo que o app feche
	# logo depois, D7), sempre no dia que a Stage guardou ao nascer.
	if not _pode_iniciar():
		_bloquear_inicio()
		return
	var store_dia: DesafioDiarioStore = _store_do_dia()
	if store_dia != null:
		store_dia.gastar_tentativa(_dia_da_stage)
	started = true
	partida_iniciada.emit()
	_mostrar_menu(false)
	player.visible = true
	Global.set_iniciado(true)
	_abrir_tutorial()
	_publicar_estado(GameState.STATE_PLAYING, true)


# f528 T6: predicado UNICO do inicio, citado nos dois lados — a acao que inicia (as tres entradas) e o
# estado do Play no menu (C779, sem divergencia entre o que o botao promete e o que a acao faz). A regra
# do modo decide com o ctx vigente; o Diario nega o dia ja jogado, o relogio invalido e a Stage aberta na
# virada (o bloqueio dessa recarga com a seed do dia novo, C783); os demais seguem o default neutro (true,
# inicio como hoje, C786).
func _pode_iniciar() -> bool:
	return regra.pode_iniciar(_ctx_partida())


# f528 T6: o predicado negou o inicio. So o Diario chega aqui; o caso acionavel e a virada com a Stage
# aberta (dia da Stage != dia vigente, dia novo valido com tentativa disponivel): recarrega a Stage no
# menu — a nova nasce com a seed do dia novo e o Play seguinte gasta a tentativa de d+1 (a do dia antigo
# segue intacta, C783). Dia ja jogado ou relogio invalido (sentinela): nada comeca (C776/C785).
func _bloquear_inicio() -> void:
	var store_dia: DesafioDiarioStore = _store_do_dia()
	if store_dia == null:
		return
	var dia: int = _dia_utc_atual()
	if dia == DiaUtc.DIA_INVALIDO or dia == _dia_da_stage:
		return
	if not store_dia.tentativa_disponivel(dia):
		return
	_recarregar_stage()


# f528 T6 (D3/D4): UI do dia no menu — reavaliada ao nascer a Stage (menu aberto), na troca de modo
# (_fechar_modos) e quando o menu volta a aparecer (_mostrar_menu(true)). O estado do Play e o MESMO
# predicado do inicio (`_pode_iniciar`): bloqueado, o botao mostra o texto do dia no estilo do Play
# desabilitado (D3, "Ja jogado hoje", sem contagem regressiva); o placar do Diario le o resultado do dia
# vigente (D4: o recorde proprio do dia — o Best do menu; o Last e a partida do dia, a mesma coisa num
# modo de uma tentativa), nunca o best_score_* do modo. Nao reavalia por frame: a virada com a Stage
# aberta e resolvida pela recarga do primeiro inicio bloqueado (C783), nao por polling do relogio.
func _aplicar_ui_dia() -> void:
	var bloqueado: bool = not _pode_iniciar()
	if not _play_capturado:
		# 1a avaliacao (fim do _ready, o estilo da cena ja aplicado e o estado do dia ainda nao): guarda o tamanho do Play
		_play_capturado = true
		_play_tinha_tamanho_proprio = playbutton.has_theme_font_size_override("font_size")
		_tamanho_play_original = playbutton.get_theme_font_size("font_size")
	_ui_dia_bloqueada = bloqueado
	playbutton.disabled = bloqueado
	if bloqueado:
		playbutton.text = TEXTO_DIA_JA_JOGADO
		playbutton.add_theme_font_size_override("font_size", TAMANHO_TEXTO_DIA)
		# Texto claro so neste estado: a cor padrao do Play desabilitado fica escura sobre o verde (ilegivel)
		playbutton.add_theme_color_override("font_disabled_color", COR_TEXTO_DIA)
	else:
		playbutton.text = _texto_play_original
		if playbutton.has_theme_color_override("font_disabled_color"):
			playbutton.remove_theme_color_override("font_disabled_color")
		# Devolve o tamanho que a cena dava ao Play (o override do .tscn, ex. TAMANHO_BOTAO), nunca o do tema
		if _play_tinha_tamanho_proprio:
			playbutton.add_theme_font_size_override("font_size", _tamanho_play_original)
		elif playbutton.has_theme_font_size_override("font_size"):
			playbutton.remove_theme_font_size_override("font_size")
	var store_dia: DesafioDiarioStore = _store_do_dia()
	if store_dia != null:
		var resultado: int = store_dia.resultado_do(_dia_utc_atual())
		bestscore.text = "Best Score: " + str(resultado)
		lastscore.text = "Last Score: " + str(resultado)
	else:
		bestscore.text = "Best Score: " + str(Global.get_best_score())
		lastscore.text = "Last Score: " + str(Global.get_last_score())
	_layout_hud(_tamanho_visivel, safe_area)

# Monta e publica o estado na ponte do smoke (no-op fora de web debug); score nunca negativo (points inicia em -1)
func _publicar_estado(state: String, alive: bool) -> void:
	_estagio_publicado = dificuldade.estagio()
	_aviso_publicado = _aviso_atual() and state != GameState.STATE_LOST
	_posicao_publicada = _posicao_atual()
	_alpha_publicado = _alpha_atual() if state != GameState.STATE_LOST else 0.0
	_powerup_publicado = _powerup_atual()
	_relogio_publicado = _relogio_atual()
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
		_relogio_publicado,
	)
	GameState.publish(ultimo_estado)
