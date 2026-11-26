class_name PowerUpHud
extends CanvasLayer

# Faixa de HUD da duracao do power-up (handoff de design, secao 3): classe topo, y0 = s_top + 30, mesma medida em
# 360x640 e 360x800. Icone do temporizado ativo, barra que esvazia pela direita, segundos (teto do restante) e o
# slot da carga guardada. Cada elemento some quando o seu estado some; com o card do tutorial aberto a faixa inteira
# fica oculta. Desenho so em branco/preto (cor nunca e a unica pista; nunca a cor de plataforma).

# Offset do topo da safe area e altura da faixa
const OFFSET_Y: float = 60.0
const ALTURA: float = 32.0
# Retangulos de cada elemento (x absoluto; y relativo ao topo da faixa)
const ICONE_X: float = 4.0
const ICONE_TAM: float = 32.0
const BARRA_X: float = 44.0
const BARRA_Y: float = 12.0
const BARRA_W: float = 80.0
const BARRA_H: float = 8.0
const SEGUNDOS_X: float = 132.0
const SEGUNDOS_W: float = 32.0
const CARGA_X: float = 180.0
const RELOGIO_X: float = 276.0
const RELOGIO_W: float = 80.0
const SEGUNDOS_POR_MINUTO: int = 60
const COR_BRANCO: Color = UiHelpers.COR_TEXTO
const COR_PRETO: Color = UiHelpers.COR_CONTORNO

# Estado de power-up da Stage e o card do tutorial da 1a partida (injetados por quem cria o HUD)
var estado: PowerUpState = null
var tutorial_card: TutorialCard = null
# Fonte do relogio injetada pela Stage: Callable que devolve {"ativo": bool, "restante": float} (ativo = o modo tem
# relogio e a partida nao acabou); sem fonte, o relogio nunca aparece
var fonte_relogio: Callable = Callable()

var _relogio: Label = null
var _y0: float = OFFSET_Y
var _largura: float = 360.0
var _icone: _Desenho = null
var _barra: _Desenho = null
var _carga: _Desenho = null
var _segundos: Label = null
# Largura inteira (px, ceil) com que a barra foi montada; -1 = ainda nao montada
var _barra_px: int = -1


# Controle que so executa uma lista de comandos de desenho (retangulos e poligonos)
class _Desenho:
	extends Control

	var comandos: Array = []

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		focus_mode = Control.FOCUS_NONE

	func definir(novos: Array) -> void:
		if novos == comandos:
			return
		comandos = novos
		queue_redraw()

	func _draw() -> void:
		for c in comandos:
			if c["forma"] == &"poly":
				draw_colored_polygon(c["pontos"], c["cor"])
			else:
				draw_rect(c["rect"], c["cor"])


func _init() -> void:
	# Mesmo layer do HUD (Pontos/pausa): acima do jogo, abaixo do overlay de pausa
	layer = 1
	_icone = _Desenho.new()
	_barra = _Desenho.new()
	_carga = _Desenho.new()
	_segundos = UiHelpers.novo_label("", UiHelpers.TAMANHO_TEXTO, 2)
	_relogio = UiHelpers.novo_label("", UiHelpers.TAMANHO_TEXTO, 2)
	_relogio.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for no in [_icone, _barra, _carga, _segundos, _relogio]:
		(no as Control).visible = false
		add_child(no)
	_carga.definir(comandos_do_tipo(&"segunda_chance"))
	aplicar_layout(Vector2(_largura, 640.0), Rect2(0.0, 0.0, _largura, 640.0))


func _process(_delta: float) -> void:
	atualizar()


# Reposiciona a faixa a partir do topo da safe area (largura visivel injetada: testavel sem janela)
func aplicar_layout(visible_size: Vector2, safe: Rect2) -> void:
	_y0 = safe.position.y + OFFSET_Y
	_largura = visible_size.x
	_icone.position = rect_icone().position
	_icone.size = rect_icone().size
	# A moldura de 2 px fica por fora dos 80x8 da barra
	_barra.position = rect_barra().grow(2.0).position
	_barra.size = rect_barra().grow(2.0).size
	_carga.position = rect_carga().position
	_carga.size = rect_carga().size
	_segundos.position = rect_segundos().position
	_segundos.size = rect_segundos().size
	_relogio.position = rect_relogio().position
	_relogio.size = rect_relogio().size


func rect_faixa() -> Rect2:
	return Rect2(0.0, _y0, _largura, ALTURA)


func rect_icone() -> Rect2:
	return Rect2(ICONE_X, _y0, ICONE_TAM, ICONE_TAM)


# Area 40x4 da barra (sem a moldura)
func rect_barra() -> Rect2:
	return Rect2(BARRA_X, _y0 + BARRA_Y, BARRA_W, BARRA_H)


# Parte branca da barra: x esquerdo fixo, largura proporcional ao restante (esvazia pela direita)
func rect_barra_cheia() -> Rect2:
	return Rect2(BARRA_X, _y0 + BARRA_Y, BARRA_W * fracao(), BARRA_H)


func rect_segundos() -> Rect2:
	return Rect2(SEGUNDOS_X, _y0, SEGUNDOS_W, ALTURA)


func rect_carga() -> Rect2:
	return Rect2(CARGA_X, _y0, ICONE_TAM, ICONE_TAM)


# Relogio do Contra o tempo (handoff secao 3: x 138-178, y 30-46)
func rect_relogio() -> Rect2:
	return Rect2(RELOGIO_X, _y0, RELOGIO_W, ALTURA)


# `m:ss` dos segundos restantes, arredondado para cima (0.2 s -> 0:01); negativo conta como 0
static func formatar_relogio(restante_s: float) -> String:
	var total: int = ceili(maxf(0.0, restante_s))
	var minutos: int = floori(float(total) / float(SEGUNDOS_POR_MINUTO))
	return "%d:%02d" % [minutos, total % SEGUNDOS_POR_MINUTO]


func texto_relogio() -> String:
	return _relogio.text


func relogio_visivel() -> bool:
	return _relogio.visible


# Fracao do tempo que resta (0 a 1) do temporizado ativo
func fracao() -> float:
	if estado == null or estado.ativo() == null or estado.ativo().duracao <= 0.0:
		return 0.0
	return clampf(estado.restante() / estado.ativo().duracao, 0.0, 1.0)


func texto_segundos() -> String:
	return _segundos.text


func icone_visivel() -> bool:
	return _icone.visible


func barra_visivel() -> bool:
	return _barra.visible


func segundos_visivel() -> bool:
	return _segundos.visible


func carga_visivel() -> bool:
	return _carga.visible


func comandos_icone() -> Array:
	return _icone.comandos


func comandos_carga() -> Array:
	return _carga.comandos


func comandos_barra() -> Array:
	return _barra.comandos


# Sincroniza visibilidade e desenho com o estado atual (a cada frame; a pausa congela o estado sozinha)
func atualizar() -> void:
	var oculta: bool = tutorial_card != null and tutorial_card.esta_aberto()
	var ativo: PowerUp = null
	if estado != null:
		ativo = estado.ativo()
	var mostra_ativo: bool = ativo != null and not oculta
	var mostra_carga: bool = estado != null and estado.carga() > 0 and not oculta
	_icone.visible = mostra_ativo
	_barra.visible = mostra_ativo
	_segundos.visible = mostra_ativo
	_carga.visible = mostra_carga
	if mostra_ativo:
		_icone.definir(comandos_do_tipo(ativo.nome))
		_atualizar_barra()
		_segundos.text = str(ceili(estado.restante()))
	_atualizar_relogio(oculta)


# Relogio: so no Contra o tempo, com a partida iniciada e antes de `lost`; o card do tutorial so o oculta (o texto
# fica e volta ao fechar o card)
func _atualizar_relogio(oculta: bool) -> void:
	var relogio: Dictionary = fonte_relogio.call() if fonte_relogio.is_valid() else {}
	var ativo: bool = bool(relogio.get("ativo", false)) and Global.is_iniciado()
	if ativo:
		_relogio.text = formatar_relogio(float(relogio.get("restante", 0)))
	_relogio.visible = ativo and not oculta


# Reconstroi os comandos da barra so quando a largura inteira (ceil, 0..80 px) muda: restantes que dao a mesma
# largura reusam o array anterior, sem alocar a cada frame. O cache `_barra_px` assume que a barra depende SO da
# largura: desenho com cor por tipo exige invalidar tambem pelo tipo.
func _atualizar_barra() -> void:
	var px: int = ceili(rect_barra_cheia().size.x)
	if px == _barra_px:
		return
	_barra_px = px
	_barra.definir(_montar_barra(px))


func _montar_barra(px: int) -> Array:
	# Coordenadas locais ao controle da barra (que ja inclui a moldura de 2 px)
	return [
		_rect(Rect2(0.0, 0.0, BARRA_W + 4.0, BARRA_H + 4.0), COR_PRETO),
		_rect(Rect2(2.0, 2.0, float(px), BARRA_H), COR_BRANCO),
	]


# Desenho do icone por tipo: fachada da fonte unica PowerUpDesenho (a mesma do icone da plataforma).
static func comandos_do_tipo(nome: StringName) -> Array:
	return PowerUpDesenho.comandos(nome)


static func _rect(r: Rect2, cor: Color) -> Dictionary:
	return {"forma": &"rect", "rect": r, "cor": cor}
