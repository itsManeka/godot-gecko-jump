# Estado de dificuldade de UMA partida (ver DifficultyCurve). RefCounted, sem autoload e sem estatico:
# nova instancia = zerada. O dono chama tick(delta) a cada _physics_process e set_pontos() a cada ponto.
# Tempo so acumula com Global.is_iniciado() (menu e antes do primeiro toque nao contam).
class_name DifficultyState
extends RefCounted

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
	return _curva.avaliar(_pontos, _segundos)
