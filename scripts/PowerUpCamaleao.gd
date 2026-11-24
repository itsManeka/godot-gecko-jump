class_name PowerUpCamaleao
extends PowerUp

# Camaleao (f522 T3, ADR 0014): temporizado — por `duracao_camaleao_s` do Resource de T2 (padrao 5 s do
# ADR) o gecko pisa em plataforma de qualquer cor. O efeito chega ao mundo pelo hook `ignora_cor()` (T1):
# o PowerUpState agrega, a Stage espelha em Global.cor_livre e a regra de colisao da Platform le a flag;
# as bordas do efeito (ativacao/expiracao) forcam a reavaliacao da colisao na propria Stage. Pausa congela
# o contador junto com a arvore (quem chama tick e a Stage, ADR 0008).

# Config injetavel (teste); producao carrega o Resource padrao (PowerUpConfig.CAMINHO_PADRAO).
var _config: PowerUpConfig


func _init(config: PowerUpConfig = null) -> void:
	_config = config if config != null else PowerUpConfig.carregar()
	nome = &"camaleao"
	duracao = _config.duracao_camaleao_vigente()


# Verdadeiro = o gecko pisa em plataforma de qualquer cor enquanto vigora (Platform le Global.cor_livre).
func ignora_cor() -> bool:
	return true
