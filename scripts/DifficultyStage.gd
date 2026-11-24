# Estagio da curva de dificuldade (ver DifficultyCurve). Valores do estagio 0 = comportamento de antes da curva.
# Os defaults abaixo sao os unicos literais de dificuldade fora do .tres de producao.
class_name DifficultyStage
extends Resource

const SCROLL_PADRAO: float = 20.0
const SPEED_PADRAO: float = 60.0
const K_PADRAO: int = 3
const PROPORCAO_PADRAO: float = 1.0 / 3.0
const LARGURA_PLATAFORMA_PADRAO: float = 60.0
const ATRASO_DESMORONAR_PADRAO: float = 1.0
const PROPORCAO_CICLADORAS_PADRAO: float = 0.0
const PERIODO_CICLO_PADRAO: float = 3.0
const AMPLITUDE_MOVIMENTO_PADRAO: float = 0.0
const PERIODO_MOVIMENTO_PADRAO: float = 2.5
const PROPORCAO_OSCILANTES_PADRAO: float = 0.0
const PROPORCAO_VAI_E_VEM_PADRAO: float = 0.0
const VARIACAO_SPEED_LINHA_PADRAO: float = 0.0
const PROPORCAO_PISCANTES_PADRAO: float = 0.0
const DURACAO_VISIVEL_PADRAO: float = 3.0
const DURACAO_INVISIVEL_PADRAO: float = 1.2
const AVISO_PISCA_PADRAO: float = 0.6
const PROPORCAO_QUE_CAEM_PADRAO: float = 1.0
const RARIDADE_POWER_UP_PADRAO: float = 0.0

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
## Largura da plataforma em px (interpola ate o proximo estagio). Padrao = largura do prefab de antes da curva.
@export var largura_plataforma: float = LARGURA_PLATAFORMA_PADRAO
## Segundos entre o pouso e o desmoronamento da plataforma (so vale com a mecanica plataformas_que_caem).
@export var atraso_desmoronar: float = ATRASO_DESMORONAR_PADRAO
## Fracao das plataformas que caem, sorteada por plataforma (0..1; so vale com a mecanica plataformas_que_caem).
## Padrao 1.0 = todas caem, igual ao comportamento antes deste campo.
@export_range(0.0, 1.0) var proporcao_que_caem: float = PROPORCAO_QUE_CAEM_PADRAO
## Fracao das plataformas moveis que trocam de cor sozinhas (so vale com a mecanica plataformas_que_mudam_de_cor).
@export_range(0.0, 1.0) var proporcao_cicladoras: float = PROPORCAO_CICLADORAS_PADRAO
## Segundos por cor de uma plataforma que muda de cor (so vale com a mecanica plataformas_que_mudam_de_cor).
@export var periodo_ciclo: float = PERIODO_CICLO_PADRAO
## Mecanicas ligadas ao estagio (nomes conhecidos por PlatformModifiers). Nao interpolam: vem do estagio atual.
@export var mecanicas: Array[StringName] = []
## Amplitude do deslocamento horizontal oscilante, em px (so vale com a mecanica de movimento).
@export var amplitude_movimento: float = AMPLITUDE_MOVIMENTO_PADRAO
## Periodo da oscilacao, em segundos (so vale com a mecanica de movimento).
@export var periodo_movimento: float = PERIODO_MOVIMENTO_PADRAO
## Fracao das plataformas moveis que oscilam (0..1; so vale com a mecanica de movimento).
@export_range(0.0, 1.0) var proporcao_oscilantes: float = PROPORCAO_OSCILANTES_PADRAO
## Fracao das oscilantes que sao vai-e-vem; o resto e seno (0..1).
@export_range(0.0, 1.0) var proporcao_vai_e_vem: float = PROPORCAO_VAI_E_VEM_PADRAO
## Variacao sorteada da speed por linha movel, fracao da speed (0..1; so vale com a mecanica de speed por linha).
@export_range(0.0, 1.0) var variacao_speed_linha: float = VARIACAO_SPEED_LINHA_PADRAO
## Fracao das plataformas (nao cicladoras) que piscam (0..1; so vale com a mecanica plataformas_que_piscam).
@export_range(0.0, 1.0) var proporcao_piscantes: float = PROPORCAO_PISCANTES_PADRAO
## Segundos que a plataforma piscante fica visivel e solida, contando o aviso (so vale com a mecanica que pisca).
@export var duracao_visivel: float = DURACAO_VISIVEL_PADRAO
## Segundos que a plataforma piscante fica invisivel e sem colisao (so vale com a mecanica que pisca).
@export var duracao_invisivel: float = DURACAO_INVISIVEL_PADRAO
## Segundos finais da janela visivel em que a plataforma avisa que vai sumir (so vale com a mecanica que pisca).
@export var aviso_pisca: float = AVISO_PISCA_PADRAO
## Chance (0..1) de uma plataforma criada neste estagio ganhar um power-up (interpola ate o proximo estagio).
@export_range(0.0, 1.0) var raridade_power_up: float = RARIDADE_POWER_UP_PADRAO
## Peso relativo de cada tipo de power-up (nome -> peso). Nao interpola: vem do estagio atual. Vazio = nenhum candidato.
@export var pesos_power_ups: Dictionary = {}
