extends GutTest

# Cor de fundo das barras laterais em janela larga (direcao de arte 4.2 item 4): default_clear_color = painel_escuro
# #1f2738 como Color(0.1216, 0.1529, 0.2196, 1.0). Valor esperado escrito a mao, nao lido do project.godot.
const CHAVE := "rendering/environment/defaults/default_clear_color"
const ESPERADA := Color(0.1216, 0.1529, 0.2196, 1.0)


func test_default_clear_color_e_painel_escuro_das_barras_laterais() -> void:
	var cor: Variant = ProjectSettings.get_setting(CHAVE)
	assert_true(cor is Color, "a chave existe e e Color")
	assert_eq(cor, ESPERADA, "default_clear_color = Color(0.1216, 0.1529, 0.2196, 1.0)")
