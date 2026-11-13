extends Node

# Script global que gerencia o estado do jogo

# Lista de todas as plataformas ativas no jogo
var platforms = []
# Estado se o jogo foi iniciado
var iniciado : bool = false
# Pontuação da partida e recorde (regra em ScoreKeeper).
# Publico de proposito (seam de teste): test/test_score_keeper.gd sobrescreve `Global.pontuacao` por atribuicao
# em before_each/after_each. Trocar por reset explicito exige atualizar esse teste.
var pontuacao: ScoreKeeper = ScoreKeeper.new()
# Persistencia do recorde em user://, ligada ao `pontuacao` so no _ready (os keepers de teste nascem sem ligacao).
# Mantido em membro para o store nao ser liberado ao fim do _ready.
var _best_store: BestScoreStore
# Cor corrente do gecko (lida pelos geradores de plataforma). Volta a Enums.COR_INICIAL a cada partida nova:
# o Player a reseta ao sair da arvore (Player._exit_tree), antes de a Stage seguinte gerar as plataformas.
var cor_gecko: Enums.COLOR = Enums.COR_INICIAL

# Aplica a seed do RNG: null = sorteio livre (producao), inteiro = sequencia fixa (smoke debug).
func aplicar_seed(valor: Variant) -> void:
	if valor == null:
		randomize()
	else:
		seed(int(valor))

# Dica de toque (TouchHint): so em memoria (volta a cada recarga da pagina). A Stage e recriada a cada partida,
# entao o estado "ja detectei toque" e "ja mostrei a dica" vive aqui.
var toque_detectado: bool = false
var dica_toque_mostrada: bool = false

# Dica de toque forcada (so smoke debug via `?dica=1`): liga toque_detectado sem dispositivo de toque. Nunca liga em release.
func aplicar_modo_dica(raw: Variant, is_debug: bool) -> void:
	toque_detectado = ModoDicaToque.decide(raw, is_debug)

# Modo sem derrota (so smoke debug via `?semderrota=1`): o gecko nao perde. Nunca liga em release.
var sem_derrota: bool = false

# Aplica o modo sem derrota a partir do valor bruto do parametro e da flag de build.
func aplicar_modo_sem_derrota(raw: Variant, is_debug: bool) -> void:
	sem_derrota = ModoSemDerrota.decide(raw, is_debug)

# Inicializa o gerador de números aleatórios e liga o recorde salvo ao ScoreKeeper
func _ready():
	aplicar_seed(SeedSource.decide(SeedSource.read_raw(), OS.is_debug_build()))
	aplicar_modo_sem_derrota(ModoSemDerrota.read_raw(), OS.is_debug_build())
	aplicar_modo_dica(ModoDicaToque.read_raw(), OS.is_debug_build())
	_best_store = BestScoreStore.new()
	pontuacao.load_best(_best_store.load_best())
	pontuacao.best_changed.connect(_best_store.save_best)
	usar_options_store(OptionsStore.new())

# Opcoes de audio: store publico de proposito (seam de teste; test/gut_pre_run.gd o troca por um de caminho temporario).
var opcoes: OptionsStore
var _volume_music: float = OptionsStore.DEFAULT_VOLUME
var _volume_sfx: float = OptionsStore.DEFAULT_VOLUME

# Define o store das opcoes, le os volumes salvos e aplica nos buses.
func usar_options_store(store: OptionsStore) -> void:
	opcoes = store
	_volume_music = store.load_music()
	_volume_sfx = store.load_sfx()
	_aplicar_bus("Music", _volume_music)
	_aplicar_bus("SFX", _volume_sfx)

# Aplica no bus sempre; grava no store so com `persistir` (arrasto de slider aplica sem gravar e grava ao soltar).
func set_volume_music(v: float, persistir: bool = true) -> void:
	_volume_music = clampf(v, 0.0, 1.0)
	_aplicar_bus("Music", _volume_music)
	if persistir:
		opcoes.save_music(_volume_music)

func set_volume_sfx(v: float, persistir: bool = true) -> void:
	_volume_sfx = clampf(v, 0.0, 1.0)
	_aplicar_bus("SFX", _volume_sfx)
	if persistir:
		opcoes.save_sfx(_volume_sfx)

# Grava no store os dois volumes atuais.
func salvar_volumes() -> void:
	opcoes.save_music(_volume_music)
	opcoes.save_sfx(_volume_sfx)

func get_volume_music() -> float:
	return _volume_music

func get_volume_sfx() -> float:
	return _volume_sfx

# Aplica o volume linear no bus: dB pela conversao do store e mudo em 0.
func _aplicar_bus(bus: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, OptionsStore.volume_linear_to_db(linear))
	AudioServer.set_bus_mute(idx, linear <= 0.0)

# Adiciona uma nova plataforma à lista de plataformas ativas
func add_platform(platform: Platform):
	platforms.append(platform)

# Notifica todas as plataformas sobre a mudança de cor do jogador
# Ativa/desativa colisão baseado na cor
func player_color_changed(player_color, actual_platform: Platform):
	cor_gecko = player_color
	for platform in platforms:
		if is_instance_valid(platform) and platform != actual_platform:
			var p := platform as Platform
			if p:
				p.player_color_changed(player_color)

# Atualiza a plataforma atual quando o jogador muda de cor
func att_actual_platform(player_color, actual_platform):
	var platform_index = platforms.find(actual_platform, 0)
	if platform_index != -1 and is_instance_valid(platforms[platform_index]):
		platforms[platform_index].player_color_changed(player_color)

# Remove uma plataforma da lista (quando sai de tela)
func remove_platform(platform):
	var platform_index = platforms.find(platform, 0)
	if platform_index != -1:
		platforms.remove_at(platform_index)

# Define se o jogo foi iniciado
func set_iniciado(b: bool):
	iniciado = b

# Retorna se o jogo foi iniciado
func is_iniciado() -> bool:
	return iniciado

# Define a pontuação atual e atualiza o recorde se necessário
func set_score(score):
	pontuacao.set_score(score)

# Retorna a última pontuação obtida
func get_last_score() -> int:
	return pontuacao.last

# Retorna a melhor pontuação alcançada
func get_best_score() -> int:
	return pontuacao.best
