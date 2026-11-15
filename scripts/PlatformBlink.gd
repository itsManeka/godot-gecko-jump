class_name PlatformBlink
extends PlatformModifier

# Mecanica "plataformas que piscam": a plataforma alterna entre visivel/solida e invisivel/sem colisao.
# Ciclo = `duracao_visivel` (os ultimos `aviso` s sao o aviso, ainda solida) + `duracao_invisivel`.
# Estado por instancia (fase, relogio); sem cena e sem Global: a trava (gecko em cima) vem da plataforma por
# `esta_travada()` e o relogio so avanca pelo `delta` recebido (pausa/menu/derrota ficam por conta de quem chama).
# Fronteiras: em t = duracao_visivel ja e invisivel; em t = ciclo volta a ser visivel.

# Teto de duracao: duracoes enormes saturam aqui (evita inf/NaN no fmod).
const DURACAO_MAXIMA := 1.0e9

var _visivel := 0.0
var _invisivel := 0.0
var _aviso := 0.0
var _ativo := false
var _relogio := 0.0


# Sorteia a fase no ciclo com o rng recebido (mesma semente = mesma fase). Duracao <= 0 ou proporcao <= 0 = inerte
# (sempre visivel).
func iniciar(
	rng: RandomNumberGenerator, duracao_visivel: float, duracao_invisivel: float, aviso: float, proporcao: float = 1.0
) -> void:
	_visivel = clampf(duracao_visivel, 0.0, DURACAO_MAXIMA)
	_invisivel = clampf(duracao_invisivel, 0.0, DURACAO_MAXIMA)
	_aviso = clampf(aviso, 0.0, _visivel)
	_ativo = _visivel > 0.0 and _invisivel > 0.0 and proporcao > 0.0
	_relogio = rng.randf() * _ciclo() if _ativo else 0.0


# Fixa a fase (segundos dentro do ciclo); usado por teste e pelo gerador quando precisa de fase conhecida.
func definir_fase(segundos: float) -> void:
	_relogio = _normalizar(segundos)


func get_fase() -> float:
	return _relogio


func get_ciclo() -> float:
	return _ciclo()


# Linha inicial e o chao garantido do comeco da partida: nunca some.
func vale_em_linha_inicial() -> bool:
	return false


func esta_visivel() -> bool:
	return visivel_em(0.0)


# Visibilidade daqui a `dt` s contando a fase atual, sem considerar trava (o preditor trata a trava a parte).
# O aviso conta como visivel.
func visivel_em(dt: float) -> bool:
	if not _ativo:
		return true
	return _normalizar(_relogio + maxf(dt, 0.0)) < _visivel


# Nos ultimos `aviso` s do visivel (falso se invisivel ou sem aviso).
func em_aviso() -> bool:
	if not _ativo or _aviso <= 0.0:
		return false
	var t := _normalizar(_relogio)
	return t < _visivel and t >= _visivel - _aviso


# Verdadeiro so se a plataforma esta visivel em TODA a janela [inicio, fim] (a partir de agora, em s).
func visivel_na_janela(inicio: float, fim: float) -> bool:
	if not _ativo:
		return true
	var ini := maxf(inicio, 0.0)
	if not visivel_em(ini):
		return false
	var restante := _visivel - _normalizar(_relogio + ini)
	return maxf(fim, ini) - ini < restante


func ao_processar(plataforma: Platform, delta: float) -> void:
	if not _ativo or delta <= 0.0:
		return
	if plataforma.has_method(&"esta_travada") and plataforma.call(&"esta_travada"):
		return
	_relogio = _normalizar(_relogio + delta)


func _ciclo() -> float:
	return _visivel + _invisivel


func _normalizar(t: float) -> float:
	var ciclo := _ciclo()
	if ciclo <= 0.0:
		return 0.0
	return fposmod(t, ciclo)
