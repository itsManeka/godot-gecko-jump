extends GutTest

# Visual da Platform: cor por textura (nao modulate), Controls inertes e canais visuais sem dono duplicado.
const PLATAFORMA_CENA := "res://scenes/Platform.tscn"

var _cor_original: Enums.COLOR


func before_each() -> void:
	_cor_original = Global.cor_gecko
	Global.platforms = []
	Global.iniciado = false
	Global.sem_derrota = false


func after_each() -> void:
	Global.cor_gecko = _cor_original
	Global.platforms = []
	Global.iniciado = false
	Global.sem_derrota = false


func _nova(cor: Enums.COLOR, modificadores: Array = []) -> Platform:
	var p: Platform = load(PLATAFORMA_CENA).instantiate()
	p.set_color(cor)
	if not modificadores.is_empty():
		p.definir_modificadores(modificadores, DifficultySnapshot.new())
	add_child_autofree(p)
	return p


# Textura da cor pelo arquivo e Visual.modulate rgb branco (cor deixou de ser modulate)
func _afirmar_cor(cor: Enums.COLOR, arquivo: String) -> void:
	var p := _nova(cor)
	var corpo: NinePatchRect = p.get_node("Visual/Corpo")
	assert_true(corpo.texture.resource_path.ends_with(arquivo), "textura termina em %s (veio %s)" % [arquivo, corpo.texture.resource_path])
	var m: Color = p.get_node("Visual").modulate
	assert_eq(Color(m.r, m.g, m.b), Color.WHITE, "Visual.modulate rgb branco para %s" % arquivo)


# C875 [it]
func test_cor_verde_exibe_a_textura_verde_com_modulate_branco() -> void:
	_afirmar_cor(Enums.COLOR.VERDE, "plataforma-verde.png")


# C876 [it]
func test_cor_amarelo_exibe_a_textura_amarela_com_modulate_branco() -> void:
	_afirmar_cor(Enums.COLOR.AMARELO, "plataforma-amarelo.png")


# C877 [it]
func test_cor_azul_exibe_a_textura_azul_com_modulate_branco() -> void:
	_afirmar_cor(Enums.COLOR.AZUL, "plataforma-azul.png")


# C878 [it]
func test_cor_vermelho_exibe_a_textura_vermelha_e_as_4_texturas_sao_distintas() -> void:
	_afirmar_cor(Enums.COLOR.VERMELHO, "plataforma-vermelho.png")
	var caminhos := {}
	for cor in Enums.COLOR.values():
		caminhos[_nova(cor).get_node("Visual/Corpo").texture.resource_path] = true
	assert_eq(caminhos.size(), 4, "4 resource_path distintos")


func _controles(no: Node, acumulado: Array) -> void:
	if no is Control:
		acumulado.append(no)
	for filho in no.get_children():
		_controles(filho, acumulado)


# C880 [mutacao]: nenhum Control da Platform captura mouse nem foco (jogo de toque: o overlay nao pode roubar o toque)
func test_todo_control_da_platform_ignora_mouse_e_nao_pega_foco() -> void:
	var p := _nova(Enums.COLOR.AMARELO)
	var controles: Array = []
	_controles(p, controles)
	assert_gt(controles.size(), 0, "a Platform tem ao menos um Control (o NinePatchRect)")
	for c in controles:
		assert_eq(c.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s ignora o mouse" % c.name)
		assert_eq(c.focus_mode, Control.FOCUS_NONE, "%s sem foco" % c.name)


func _alfa_permitido(alfa: float, permitidos: Array) -> bool:
	for permitido in permitidos:
		if is_equal_approx(alfa, permitido):
			return true
	return false


# C886 [mutacao]: piscante e cicladora no mesmo frame, cada um no seu canal de alfa
func test_piscante_e_cicladora_no_mesmo_frame_nao_escrevem_no_canal_um_do_outro() -> void:
	Global.iniciado = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var ciclo := PlatformColorCycle.new()
	ciclo.iniciar(Enums.COLOR.AMARELO, 1.0, rng)
	var rng_pisca := RandomNumberGenerator.new()
	rng_pisca.seed = 3
	var blink := PlatformBlink.new()
	blink.iniciar(rng_pisca, 3.0, 1.0, 0.5)
	blink.definir_fase(2.0)
	var p := _nova(Enums.COLOR.AMARELO, [ciclo, blink])
	var permitidos_no: Array = [Platform.PISCA_ALFA_FANTASMA, Platform.PISCA_AVISO_ALFA_BAIXO, 1.0]
	var permitidos_visual: Array = [Platform.AVISO_ALFA_BAIXO, 1.0]
	var viu_pisca_baixo := false
	var viu_fantasma := false
	var viu_aviso_baixo := false
	p._physics_process(0.45)
	for i in 50:
		p._physics_process(0.02)
		var alfa_no: float = p.modulate.a
		var alfa_visual: float = p.visual.modulate.a
		assert_true(_alfa_permitido(alfa_no, permitidos_no), "Platform.modulate.a so PISCA_* (veio %s)" % alfa_no)
		assert_true(_alfa_permitido(alfa_visual, permitidos_visual), "Visual.modulate.a so AVISO_ALFA_BAIXO/1.0 (veio %s)" % alfa_visual)
		viu_pisca_baixo = viu_pisca_baixo or is_equal_approx(alfa_no, Platform.PISCA_AVISO_ALFA_BAIXO)
		viu_fantasma = viu_fantasma or is_equal_approx(alfa_no, Platform.PISCA_ALFA_FANTASMA)
		viu_aviso_baixo = viu_aviso_baixo or is_equal_approx(alfa_visual, Platform.AVISO_ALFA_BAIXO)
	assert_true(viu_pisca_baixo, "o flicker do piscante apareceu no no raiz")
	assert_true(viu_fantasma, "o fantasma do piscante apareceu no no raiz")
	assert_true(viu_aviso_baixo, "o pulso da cicladora apareceu no Visual")
