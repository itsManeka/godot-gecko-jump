# Curva de dificuldade: estagios + interpolacao continua, avaliada por progresso (pontos e tempo).
# progresso = clamp(max(pontos / pontos_plato, segundos / segundos_plato), 0, 1); em 1 a curva fica no teto.
# K = floor(valor interpolado), com minimo 3 (K inteiro e nao decrescente). Estagios devem estar ordenados por
# progresso_inicio, com o primeiro em 0.0. Funcoes puras: nao leem autoload nem arvore de cena.
class_name DifficultyCurve
extends Resource

const K_MINIMO: int = 3

@export var estagios: Array[DifficultyStage] = []
## N_pontos: pontos que levam o progresso a 1 pelo gatilho de pontos.
@export var pontos_plato: float = 120.0
## N_segundos: segundos de partida que levam o progresso a 1 pelo gatilho de tempo.
@export var segundos_plato: float = 180.0


## Progresso 0..1 a partir de pontos (negativos contam como 0) e segundos (negativos contam como 0).
func progresso(pontos: float, segundos: float) -> float:
	var por_pontos := 0.0
	if pontos_plato > 0.0:
		por_pontos = maxf(pontos, 0.0) / pontos_plato
	var por_tempo := 0.0
	if segundos_plato > 0.0:
		por_tempo = maxf(segundos, 0.0) / segundos_plato
	return clampf(maxf(por_pontos, por_tempo), 0.0, 1.0)


## Parametros vigentes para pontos e segundos. Sem estagios, devolve os defaults do estagio 0.
func avaliar(pontos: float, segundos: float) -> DifficultySnapshot:
	if estagios.is_empty():
		return DifficultySnapshot.new()
	var p := progresso(pontos, segundos)
	var indice := 0
	for i in range(estagios.size()):
		if estagios[i].progresso_inicio <= p:
			indice = i
		else:
			break
	var atual: DifficultyStage = estagios[indice]
	if indice + 1 >= estagios.size():
		return _snapshot_de(atual)
	var proximo: DifficultyStage = estagios[indice + 1]
	var faixa := proximo.progresso_inicio - atual.progresso_inicio
	var t := 0.0
	if faixa > 0.0:
		t = clampf((p - atual.progresso_inicio) / faixa, 0.0, 1.0)
	var k_interp := lerpf(float(atual.k), float(proximo.k), t)
	return DifficultySnapshot.new(
		lerpf(atual.scroll, proximo.scroll, t),
		lerpf(atual.speed_moveis, proximo.speed_moveis, t),
		maxi(K_MINIMO, floori(k_interp)),
		lerpf(atual.proporcao_estaticas, proximo.proporcao_estaticas, t),
		atual.mecanicas
	)


func _snapshot_de(estagio: DifficultyStage) -> DifficultySnapshot:
	return DifficultySnapshot.new(
		estagio.scroll,
		estagio.speed_moveis,
		maxi(K_MINIMO, estagio.k),
		estagio.proporcao_estaticas,
		estagio.mecanicas
	)
