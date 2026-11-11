class_name VisibleArea
extends RefCounted

# Ponto unico de area visivel, em coordenadas logicas do viewport. Sem arvore de cena: testavel direto.
# Mudanca de tamanho (stretch keep_width: a largura logica fica em 180 e so a altura varia): quem consome liga no sinal size_changed do Viewport.


# Tamanho logico visivel (largura e altura) do viewport.
static func visible_size(viewport: Viewport) -> Vector2:
	return viewport.get_visible_rect().size


# Converte a safe area (pixels de janela) para coordenadas logicas. Funcao pura.
# escala = window_size / viewport_size (por eixo).
static func safe_rect(viewport_size: Vector2, safe_px: Rect2, window_size: Vector2) -> Rect2:
	if window_size.x <= 0.0 or window_size.y <= 0.0:
		return Rect2(Vector2.ZERO, viewport_size)
	var escala := window_size / viewport_size
	return Rect2(safe_px.position / escala, safe_px.size / escala)


# Safe area atual da janela em coordenadas logicas. Desktop/web/headless: viewport inteiro.
static func current_safe_rect(window: Window) -> Rect2:
	var viewport_size := visible_size(window)
	var inteiro := Rect2(Vector2.ZERO, viewport_size)
	if not (OS.has_feature("android") or OS.has_feature("ios")):
		return inteiro
	var janela := Vector2(DisplayServer.window_get_size(window.get_window_id()))
	var safe := Rect2(DisplayServer.get_display_safe_area())
	if janela.x <= 0.0 or janela.y <= 0.0 or safe.size.x <= 0.0 or safe.size.y <= 0.0:
		return inteiro
	return safe_rect(viewport_size, safe, janela)
