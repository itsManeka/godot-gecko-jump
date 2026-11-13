class_name UiHelpers
extends RefCounted
## Helpers de UI compartilhados pelas telas de toque/menu (sem cena): estilo de caixa, label e a chave do mouse.
## Refactor puro: o desenho e identico ao das copias que existiam em OptionsScreen, OpcoesBotao, PauseOverlay e TouchHint.

# Chave do mouse no dicionario de toques (dedos do toque sao indices pequenos)
const DEDO_MOUSE: int = 1000

const FONTE: Font = preload("res://fonts/alterebro-pixel-font.ttf")
const COR_TEXTO: Color = Color(1.0, 1.0, 1.0, 1.0)
const COR_CONTORNO: Color = Color(0.0, 0.0, 0.0, 1.0)
const RAIO_BOTAO: int = 4


## Caixa com fundo, borda e raio explicitos.
static func estilo(fundo: Color, borda: int, cor_borda: Color, raio: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fundo
	s.set_border_width_all(borda)
	s.border_color = cor_borda
	s.set_corner_radius_all(raio)
	return s


## Caixa de Opcoes: raio 4 so no fundo do botao (com borda); trilha, cursor e moldura ficam retos.
static func estilo_opcoes(fundo: Color, borda: int, cor_borda: Color, cor_botao: Color) -> StyleBoxFlat:
	return estilo(fundo, borda, cor_borda, RAIO_BOTAO if borda > 0 and fundo == cor_botao else 0)


## Label de pixel art (fonte, cor e contorno do jogo), sem interceptar mouse nem foco.
static func novo_label(
	texto: String, tamanho: int, contorno: int, alinhamento: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER
) -> Label:
	var l := Label.new()
	l.text = texto
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.focus_mode = Control.FOCUS_NONE
	l.horizontal_alignment = alinhamento
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", FONTE)
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", COR_TEXTO)
	l.add_theme_color_override("font_outline_color", COR_CONTORNO)
	l.add_theme_constant_override("outline_size", contorno)
	return l
