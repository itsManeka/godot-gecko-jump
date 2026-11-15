class_name LevelUpFrame
extends CanvasLayer

# Aviso visual de subida de estagio: moldura branca na borda da safe area que pulsa N vezes (N = estagio novo).
# So desenho: nenhum no recebe entrada (mouse_filter IGNORE, sem foco) e nao ha texto. Montada por codigo; a Stage a
# instancia e injeta o layout (`aplicar_layout`). O pulso e um Tween do proprio no: pausar a arvore congela o pulso.
# `pulsar` exige o no dentro da arvore (o Tween nasce dele).

const COR: Color = Color(1.0, 1.0, 1.0, 1.0)
const COR_CONTORNO: Color = Color(0.0, 0.0, 0.0, 0.6)
# Espessura da moldura e do contorno escuro interno, em px logicos
const ESPESSURA: float = 4.0
const ESPESSURA_CONTORNO: float = 1.0
# Um pulso dura 0,3 s: acende rapido, apaga em fade, pausa curta entre pulsos (3 pulsos < 1 s)
const SUBIDA_S: float = 0.06
const QUEDA_S: float = 0.19
const INTERVALO_S: float = 0.05
# Acima do jogo, abaixo do HUD (CanvasLayer da Stage, layer 1)
const CAMADA: int = 0

var _raiz: Control
var _moldura: Rect2 = Rect2()
var _tamanho: Vector2 = Vector2.ZERO
var _tween: Tween = null
var _pulsando: bool = false


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
	_tween = create_tween()
	for i in n:
		_tween.tween_property(_raiz, "modulate:a", 1.0, SUBIDA_S).from(0.0)
		_tween.tween_property(_raiz, "modulate:a", 0.0, QUEDA_S)
		if i < n - 1:
			_tween.tween_interval(INTERVALO_S)
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
	_borda(_moldura, ESPESSURA, COR)
	_borda(_moldura.grow(-ESPESSURA), ESPESSURA_CONTORNO, COR_CONTORNO)


# Quatro faixas de largura `esp` por dentro do retangulo `r`.
func _borda(r: Rect2, esp: float, cor: Color) -> void:
	_raiz.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, esp), cor)
	_raiz.draw_rect(Rect2(r.position.x, r.end.y - esp, r.size.x, esp), cor)
	_raiz.draw_rect(Rect2(r.position.x, r.position.y + esp, esp, r.size.y - 2.0 * esp), cor)
	_raiz.draw_rect(Rect2(r.end.x - esp, r.position.y + esp, esp, r.size.y - 2.0 * esp), cor)
