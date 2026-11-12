# Estagio da curva de dificuldade (ver DifficultyCurve). Valores do estagio 0 = comportamento de antes da curva.
# Os defaults abaixo sao os unicos literais de dificuldade fora do .tres de producao.
class_name DifficultyStage
extends Resource

const SCROLL_PADRAO: float = 20.0
const SPEED_PADRAO: float = 60.0
const K_PADRAO: int = 3
const PROPORCAO_PADRAO: float = 1.0 / 3.0

## Progresso (0..1) a partir do qual este estagio vale; interpola ate o proximo estagio.
@export_range(0.0, 1.0) var progresso_inicio: float = 0.0
## Scroll vertical do cenario, em px/s.
@export var scroll: float = SCROLL_PADRAO
## Speed horizontal das plataformas moveis, em px/s.
@export var speed_moveis: float = SPEED_PADRAO
## K: quantas cores distintas o gecko precisa ver como alcancaveis na janela (inteiro, minimo 3 na avaliacao).
@export_range(1, 20) var k: int = K_PADRAO
## Fracao das plataformas sorteadas como estaticas (o resto e movel, dividido igualmente entre esquerda e direita).
@export_range(0.0, 1.0) var proporcao_estaticas: float = PROPORCAO_PADRAO
## Mecanicas ligadas ao estagio (f10..f14). Vazio nesta feature.
@export var mecanicas: Array[StringName] = []
