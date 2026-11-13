# Estado de dificuldade de UMA partida (ver DifficultyCurve). RefCounted, sem autoload e sem estatico:
# nova instancia = zerada. O dono chama tick(delta) a cada _physics_process e set_pontos() a cada ponto.
# Tempo so acumula com Global.is_iniciado() (menu e antes do primeiro toque nao contam).
class_name DifficultyState
extends RefCounted

## Progresso inicial de debug (0..1, saturado): entra como offset no canal do tempo
## (segundos efetivos = _segundos + progresso_inicial * segundos_plato); o tempo segue subindo com a partida.
var progresso_inicial: float = 0.0:
	set(valor):
		progresso_inicial = clampf(valor, 0.0, 1.0)

var _curva: DifficultyCurve
var _pontos: float = 0.0
var _segundos: float = 0.0


func _init(curva: DifficultyCurve = null) -> void:
	_curva = curva if curva != null else DifficultyCurve.new()


## Acumula tempo de partida. Delta negativo nao reduz o tempo; fora da partida (Global.is_iniciado() == false) nao conta.
func tick(delta: float) -> void:
	if Global.is_iniciado():
		_segundos += maxf(delta, 0.0)


## Pontos atuais da partida. Negativos (Stage inicia em -1) contam como 0.
func set_pontos(pontos: int) -> void:
	_pontos = maxf(float(pontos), 0.0)


## Foto imutavel dos parametros vigentes para os pontos e o tempo acumulados.
func snapshot() -> DifficultySnapshot:
	return _curva.avaliar(_pontos, _segundos_efetivos())


## Indice do estagio da curva para os pontos e o tempo vigentes (inclui o progresso inicial).
func estagio() -> int:
	return _curva.indice_estagio(_curva.progresso(_pontos, _segundos_efetivos()))


func _segundos_efetivos() -> float:
	return _segundos + progresso_inicial * _curva.segundos_plato
