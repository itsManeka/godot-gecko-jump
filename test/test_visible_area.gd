extends GutTest

# VisibleArea: ponto unico de area visivel (tamanho logico do viewport e safe area em coordenadas logicas).


func _viewport(tamanho: Vector2i) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = tamanho
	add_child_autofree(vp)
	return vp


func test_safe_area_igual_a_janela_inteira_devolve_o_viewport_inteiro() -> void:
	var viewport := Vector2(180, 320)
	var janela := Vector2(720, 1280)
	var rect: Rect2 = VisibleArea.safe_rect(viewport, Rect2(Vector2.ZERO, janela), janela)
	assert_eq(rect.position.x, 0.0, "sem recorte, position.x do rect e 0")
	assert_eq(rect.position.y, 0.0, "sem recorte, position.y do rect e 0")
	assert_eq(rect.size.x, 180.0, "sem recorte, size.x do rect e a largura do viewport")
	assert_eq(rect.size.y, 320.0, "sem recorte, size.y do rect e a altura do viewport")


func test_recorte_superior_de_100px_com_escala_4_vira_25_logicos() -> void:
	var rect: Rect2 = VisibleArea.safe_rect(Vector2(180, 320), Rect2(0, 100, 720, 1180), Vector2(720, 1280))
	assert_eq(rect.position.y, 25.0, "100 px / escala 4 = 25")
	assert_eq(rect.size.y, 295.0, "1180 px / escala 4 = 295")
	assert_eq(rect.size.x, 180.0, "largura intacta")


func test_escala_vem_de_janela_sobre_viewport_e_nao_de_constante() -> void:
	var rect: Rect2 = VisibleArea.safe_rect(Vector2(195, 422), Rect2(0, 120, 1170, 2412), Vector2(1170, 2532))
	assert_eq(rect.position.y, 20.0, "120 px / escala 6 = 20")
	assert_eq(rect.size.y, 402.0, "2412 px / escala 6 = 402")


func test_visible_size_devolve_o_tamanho_logico_do_viewport() -> void:
	assert_eq(VisibleArea.visible_size(_viewport(Vector2i(180, 320))), Vector2(180, 320), "180x320")
	assert_eq(VisibleArea.visible_size(_viewport(Vector2i(180, 400))), Vector2(180, 400), "180x400")


func test_current_safe_rect_sem_recorte_devolve_o_viewport_inteiro() -> void:
	var janela: Window = get_tree().root
	var esperado := Rect2(Vector2.ZERO, janela.get_visible_rect().size)
	var rect: Rect2 = VisibleArea.current_safe_rect(janela)
	assert_eq(rect, esperado, "headless/desktop: viewport inteiro")
