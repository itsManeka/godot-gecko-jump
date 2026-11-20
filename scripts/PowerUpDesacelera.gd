class_name PowerUpDesacelera
extends PowerUp

# Desacelera (f522 T4, ADR 0014): temporizado — por `duracao_desacelera_s` do Resource de T2 (padrao 5 s do
# ADR) o deslocamento do scroll por frame e o do estagio vezes `fator_desacelera` (padrao 0,5). O efeito
# chega ao mundo pelo hook `fator_scroll()` (T1): o PowerUpState agrega e o ScrollLevel, o Player e a
# RunningPlatforms o multiplicam no scroll da curva. `avancar_camera` e o tempo da dificuldade nao mudam.

# Config injetavel (teste); producao carrega o Resource padrao (PowerUpConfig.CAMINHO_PADRAO).
var _config: PowerUpConfig


func _init(config: PowerUpConfig = null) -> void:
	_config = config if config != null else PowerUpConfig.carregar()
	nome = &"desacelera"
	duracao = _config.duracao_desacelera_vigente()


# Fator do scroll enquanto vigora (lido do Resource a cada consulta; fora de (0,1] cai no padrao do ADR)
func fator_scroll() -> float:
	return _config.fator_desacelera_vigente()
