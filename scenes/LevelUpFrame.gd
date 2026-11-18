class_name LevelUpFrame
extends CanvasLayer

# Aviso visual de subida de estagio: vinheta branca colada nas bordas da safe area (alpha de pico na borda, decaindo
# para o miolo, que fica transparente) que pulsa N vezes (N = estagio novo). So desenho: nenhum no recebe entrada
# (mouse_filter IGNORE, sem foco) e nao ha texto. Montada por codigo; a Stage a instancia e injeta o layout
# (`aplicar_layout`). O pulso e um Tween do proprio no: pausar a arvore congela o pulso. `pulsar` exige o no dentro da
# arvore (o Tween nasce dele).

const COR: Color = Color(1.0, 1.0, 1.0, 1.0)
# Vinheta (D1 = A): alpha de pico na borda da safe area e profundidade do gradiente para dentro, em px logicos
const ALPHA_PICO: float = 0.5
const PROFUNDIDADE: float = 20.0
# Um pulso dura 0,3 s: acende rapido, apaga em fade, pausa curta entre pulsos (3 pulsos < 1 s)
const SUBIDA_S: float = 0.06
const QUEDA_S: float = 0.19
const INTERVALO_S: float = 0.05
# Multiplicador das duracoes do pulso com `lenta` (so smoke debug); com `lenta` o teto de ~1 s nao se aplica
const LENTA_VEZES: float = 6.0
# Acima do jogo, abaixo do HUD (CanvasLayer da Stage, layer 1)
const CAMADA: int = 0

var _raiz: Control
var _moldura: Rect2 = Rect2()
var _tamanho: Vector2 = Vector2.ZERO
var _tween: Tween = null
var _pulsando: bool = false
# Smoke debug (`?moldura=fixa`): o pulso acende direto e fica aceso ate `interromper` (o print do runner chega tarde)
var fixa: bool = false
# Smoke debug (`?moldura=lenta`): pulso em camera lenta (duracoes multiplicadas por LENTA_VEZES) para o print do
# runner pegar o Tween real no meio do pulso. Nunca liga em release (decisor `ModoMolduraLenta`).
var lenta: bool = false


func _ready() -> void:
	layer = CAMADA
	visible = false
	_raiz = Control.new()
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.focus_mode = Control.FOCUS_NONE
	_raiz.modulate.a = 0.0
	_raiz.draw.connect(_desenhar)
	add_child(_raiz)
	_aplicar()


# Posiciona a moldura pela safe area (coordenadas logicas); chamavel de novo.
func aplicar_layout(visible_size: Vector2, safe: Rect2) -> void:
	_tamanho = visible_size
	_moldura = safe.intersection(Rect2(Vector2.ZERO, visible_size))
	if _raiz != null:
		_aplicar()


# Retangulo externo da moldura (coordenadas logicas).
func rect_moldura() -> Rect2:
	return _moldura


# Alpha do desenho em um ponto logico (sem o modulate do pulso): pico na borda da safe area, decaindo ate 0 a
# PROFUNDIDADE para dentro; 0 fora da safe area e no miolo.
func intensidade_em(ponto: Vector2) -> float:
	var borda := _distancia_da_borda(ponto)
	if borda < 0.0 or borda >= PROFUNDIDADE:
		return 0.0
	return ALPHA_PICO * (1.0 - borda / PROFUNDIDADE)


# Distancia ate a borda mais proxima da safe area (negativa quando o ponto esta fora do retangulo).
func _distancia_da_borda(ponto: Vector2) -> float:
	var dx := minf(ponto.x - _moldura.position.x, _moldura.end.x - ponto.x)
	var dy := minf(ponto.y - _moldura.position.y, _moldura.end.y - ponto.y)
	return minf(dx, dy)


# Alpha atual da moldura (0 = apagada).
func alpha() -> float:
	return _raiz.modulate.a


func pulsando() -> bool:
	return _pulsando


# n pulsos seguidos; chamada durante um pulso reinicia a sequencia.
func pulsar(n: int) -> void:
	if _pulsando:
		interromper()
	if n <= 0:
		return
	_pulsando = true
	visible = true
	if fixa:
		_raiz.modulate.a = 1.0
		return
	var subida := SUBIDA_S
	var queda := QUEDA_S
	var intervalo := INTERVALO_S
	if lenta:
		subida *= LENTA_VEZES
		queda *= LENTA_VEZES
		intervalo *= LENTA_VEZES
	_tween = create_tween()
	for i in n:
		_tween.tween_property(_raiz, "modulate:a", 1.0, subida).from(0.0)
		_tween.tween_property(_raiz, "modulate:a", 0.0, queda)
		if i < n - 1:
			_tween.tween_interval(intervalo)
	_tween.tween_callback(_terminar)


# Apaga na hora, cancelando o que faltava do pulso.
func interromper() -> void:
	if _tween != null:
		_tween.kill()
	_pulsando = false
	_raiz.modulate.a = 0.0
	visible = false


func _terminar() -> void:
	_pulsando = false
	hide()


func _aplicar() -> void:
	_raiz.position = Vector2.ZERO
	_raiz.size = _tamanho
	_raiz.queue_redraw()


func _desenhar() -> void:
	var d := minf(PROFUNDIDADE, minf(_moldura.size.x, _moldura.size.y) * 0.5)
	if d <= 0.0:
		return
	var x0 := _moldura.position.x
	var y0 := _moldura.position.y
	var x1 := _moldura.end.x
	var y1 := _moldura.end.y
	# Faixas das 4 bordas (sem os cantos, para nao sobrepor alpha) e os 4 cantos: quads com gradiente por vertice,
	# sem textura nem shader (vale no export web).
	_quad(Vector2(x0 + d, y0), Vector2(x1 - d, y0), Vector2(x1 - d, y0 + d), Vector2(x0 + d, y0 + d))
	_quad(Vector2(x0 + d, y1 - d), Vector2(x1 - d, y1 - d), Vector2(x1 - d, y1), Vector2(x0 + d, y1))
	_quad(Vector2(x0, y0 + d), Vector2(x0 + d, y0 + d), Vector2(x0 + d, y1 - d), Vector2(x0, y1 - d))
	_quad(Vector2(x1 - d, y0 + d), Vector2(x1, y0 + d), Vector2(x1, y1 - d), Vector2(x1 - d, y1 - d))
	_quad(Vector2(x0, y0), Vector2(x0 + d, y0), Vector2(x0 + d, y0 + d), Vector2(x0, y0 + d))
	_quad(Vector2(x1 - d, y0), Vector2(x1, y0), Vector2(x1, y0 + d), Vector2(x1 - d, y0 + d))
	_quad(Vector2(x0, y1 - d), Vector2(x0 + d, y1 - d), Vector2(x0 + d, y1), Vector2(x0, y1))
	_quad(Vector2(x1 - d, y1 - d), Vector2(x1, y1 - d), Vector2(x1, y1), Vector2(x1 - d, y1))


# Quadrilatero pintado com o alpha de `intensidade_em` em cada vertice (o gradiente da vinheta).
func _quad(p1: Vector2, p2: Vector2, p3: Vector2, p4: Vector2) -> void:
	var pontos := PackedVector2Array([p1, p2, p3, p4])
	var cores := PackedColorArray()
	for p in pontos:
		cores.append(Color(COR.r, COR.g, COR.b, intensidade_em(p)))
	_raiz.draw_polygon(pontos, cores)
