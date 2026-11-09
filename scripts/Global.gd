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

# Inicializa o gerador de números aleatórios
func _ready():
	randomize()

# Adiciona uma nova plataforma à lista de plataformas ativas
func add_platform(platform: Platform):
	platforms.append(platform)

# Notifica todas as plataformas sobre a mudança de cor do jogador
# Ativa/desativa colisão baseado na cor
func player_color_changed(player_color, actual_platform: Platform):
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
