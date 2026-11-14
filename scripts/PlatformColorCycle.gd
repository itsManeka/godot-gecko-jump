class_name PlatformColorCycle
extends PlatformModifier

# Mecanica "plataformas que mudam de cor": a plataforma percorre uma sequencia de cores, trocando a cada `periodo` s.
# Estado por instancia (sequencia, relogio): o gerador cria uma instancia por plataforma cicladora. Sem cena e sem Global:
# a trava (gecko em cima) e a troca vem da plataforma por `esta_travada()` / `trocar_cor(cor)`.

# Quantas cores a sequencia sorteia (a 1a e a cor inicial). Depois da ultima, o ciclo MANTEM a ultima cor
# (nao reinicia nem estoura indice); o gerador usa janela curta, entao a sequencia nunca se esgota na pratica.
const CORES_NA_SEQUENCIA := 8
# Janela final, em segundos, em que a troca esta iminente (aviso visual da plataforma).
const AVISO_TROCA_S := 0.6
const PERIODO_MINIMO := 0.001

var _sequencia: Array[int] = []
var _indice := 0
var _decorrido := 0.0
var _periodo := 3.0


# Linha inicial e o chao garantido do comeco da partida: nunca muda de cor.
func vale_em_linha_inicial() -> bool:
	return false


# Sorteia a sequencia: cada cor difere da anterior. Mesmo rng com a mesma semente = mesma sequencia.
func iniciar(cor_inicial: int, periodo: float, rng: RandomNumberGenerator) -> void:
	_periodo = maxf(periodo, PERIODO_MINIMO)
	_indice = 0
	_decorrido = 0.0
	_sequencia = [cor_inicial]
	var total := Enums.COLOR.size()
	while _sequencia.size() < CORES_NA_SEQUENCIA:
		var anterior: int = _sequencia[_sequencia.size() - 1]
		_sequencia.append((anterior + 1 + rng.randi() % (total - 1)) % total)


func cor_atual() -> int:
	return _sequencia[_indice]


func get_sequencia() -> Array[int]:
	return _sequencia.duplicate()


# Cor que a plataforma tera na proxima troca (a propria cor atual se a sequencia acabou).
func proxima_cor() -> int:
	return _sequencia[mini(_indice + 1, _sequencia.size() - 1)]


# Cor daqui a `dt` segundos contando a fase atual, sem considerar trava (o preditor trata a trava a parte).
func cor_em(dt: float) -> int:
	var trocas := int(floorf((_decorrido + maxf(dt, 0.0)) / _periodo))
	return _sequencia[mini(_indice + trocas, _sequencia.size() - 1)]


# Troca iminente: faltam AVISO_TROCA_S ou menos (falso quando nao ha mais troca na sequencia).
func em_aviso() -> bool:
	if _indice >= _sequencia.size() - 1:
		return false
	return _periodo - _decorrido <= AVISO_TROCA_S


func ao_processar(plataforma: Platform, delta: float) -> void:
	if _sequencia.is_empty():
		return
	if plataforma.has_method(&"esta_travada") and plataforma.call(&"esta_travada"):
		return
	_decorrido += delta
	while _decorrido >= _periodo:
		_decorrido -= _periodo
		if _indice >= _sequencia.size() - 1:
			_decorrido = 0.0
			return
		_indice += 1
		plataforma.call(&"trocar_cor", _sequencia[_indice])
