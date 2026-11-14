class_name PlatformPingPongMotion
extends PlatformModifier

# Mecanica "plataformas vai-e-vem": a velocidade somada e uma onda triangular de media zero e pico
# `V = 8*A/periodo` (o deslocamento extra oscila +-A). A plataforma arranca e freia, mas NUNCA inverte o sentido:
# `|desvio|` fica abaixo de `LIMITE_FRACAO_SPEED * |speed|` (Q2: inverter pode gerar 2 saidas no CheckGenerate).
# Estado por instancia (fase, relogio): o gerador cria uma por plataforma oscilante. Sem cena e sem Global.

# Fracao maxima da speed que o desvio pode tomar (d < 1: nunca inverte)
const LIMITE_FRACAO_SPEED := 0.9

var _amplitude := 0.0
var _periodo := DifficultyStage.PERIODO_MOVIMENTO_PADRAO
var _fase := 0.0
var _tempo := 0.0


func vale_em_linha_inicial() -> bool:
	return true


# Sorteia a fase da plataforma (radianos). Mesmo rng com a mesma semente = mesma fase.
func iniciar(rng: RandomNumberGenerator) -> void:
	_fase = rng.randf() * TAU
	_tempo = 0.0


func get_fase() -> float:
	return _fase


# Pico da velocidade somada (px/s) para o deslocamento extra oscilar +-amplitude: V = 8*A/periodo.
static func pico_velocidade(amplitude: float, periodo: float) -> float:
	if amplitude <= 0.0 or periodo <= 0.0:
		return 0.0
	return 8.0 * amplitude / periodo


# Velocidade somada (px/s) no instante t: onda triangular entre -V e +V, media zero.
static func desvio(t: float, amplitude: float, periodo: float, fase: float) -> float:
	if amplitude <= 0.0 or periodo <= 0.0:
		return 0.0
	var angulo := TAU * t / periodo + fase
	return pico_velocidade(amplitude, periodo) * (2.0 / PI) * asin(sin(angulo))


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
	var limite := absf(float(plataforma.speed)) * LIMITE_FRACAO_SPEED
	plataforma.desvio_vx = clampf(desvio(_tempo, _amplitude, _periodo, _fase), -limite, limite)
