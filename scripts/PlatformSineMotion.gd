class_name PlatformSineMotion
extends PlatformModifier

# Mecanica "plataformas oscilantes (seno)": soma ao movimento uniforme uma velocidade horizontal senoidal
# `A*w*cos(w*t + fase)`, com `w = 2*pi/periodo`. Media zero: a plataforma segue andando a `speed`; o deslocamento
# extra oscila +-A em torno da trajetoria uniforme. Estado por instancia (fase, relogio): o gerador cria uma por
# plataforma oscilante. Sem cena e sem Global: o relogio so avanca com `plataforma.em_movimento()`.

var _amplitude := 0.0
var _periodo := DifficultyStage.PERIODO_MOVIMENTO_PADRAO
var _fase := 0.0
var _tempo := 0.0


# Linha inicial e estatica (speed 0): inerte de qualquer forma, mas o gerador nao precisa entregar.
func vale_em_linha_inicial() -> bool:
	return true


# Sorteia a fase da plataforma (radianos). Mesmo rng com a mesma semente = mesma fase.
func iniciar(rng: RandomNumberGenerator) -> void:
	_fase = rng.randf() * TAU
	_tempo = 0.0


func get_fase() -> float:
	return _fase


# Velocidade somada (px/s) no instante t: derivada de A*sin(w*t + fase). Amplitude ou periodo <= 0 = sem efeito.
static func desvio(t: float, amplitude: float, periodo: float, fase: float) -> float:
	if amplitude <= 0.0 or periodo <= 0.0:
		return 0.0
	var w := TAU / periodo
	return amplitude * w * cos(w * t + fase)


func ao_criar(plataforma: Platform, snapshot: DifficultySnapshot) -> void:
	_amplitude = 0.0
	if snapshot != null:
		_amplitude = snapshot.get_amplitude_movimento()
		_periodo = snapshot.get_periodo_movimento()
	plataforma.desvio_vx = 0.0


func ao_processar(plataforma: Platform, delta: float) -> void:
	if not plataforma.em_movimento():
		plataforma.desvio_vx = 0.0
		return
	_tempo += delta
	plataforma.desvio_vx = desvio(_tempo, _amplitude, _periodo, _fase)
