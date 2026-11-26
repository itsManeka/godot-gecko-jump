extends GutTest

# f557 T8: um SpriteFrames por cor (`ressources/gecko_<cor>.tres`) montado das folhas `assets/gecko-<cor>.png`
# (celula 64x64, uma linha por animacao). Contagem, FPS e loop vem da tabela 3.1 da direcao de arte; a contagem de
# frames vive so em FRAMES (D1: mudar 18 para 13 altera so esta constante e o export das folhas).
const PLAYER := "res://scenes/Player.tscn"
const CELULA := Vector2(64, 64)
const FRAMES := {"idle": 4, "run": 4, "jump": 2, "fall": 2, "lose": 3, "color_change": 3}
const FPS := {"idle": 6.0, "run": 10.0, "jump": 10.0, "fall": 8.0, "lose": 8.0, "color_change": 18.0}
const SEM_LOOP := ["jump", "lose", "color_change"]
const COM_LOOP := ["idle", "run", "fall"]

func _caminho(nome_cor: String) -> String:
	return "res://ressources/gecko_%s.tres" % nome_cor.to_lower()

func _frames_da_cor(nome_cor: String) -> SpriteFrames:
	return load(_caminho(nome_cor)) as SpriteFrames

func _novo_player() -> Node:
	return add_child_autofree(load(PLAYER).instantiate())

# C849: toda cor de Enums.COLOR tem o recurso com as 6 animacoes, a contagem da constante e frames de 64x64
func test_cada_cor_tem_as_6_animacoes_com_a_contagem_e_frames_64x64() -> void:
	for nome_cor: String in Enums.COLOR.keys():
		var sf := _frames_da_cor(nome_cor)
		assert_not_null(sf, "%s: recurso carregado" % nome_cor)
		if sf == null:
			continue
		assert_eq(sf.get_animation_names().size(), FRAMES.size(), "%s: so as 6 animacoes" % nome_cor)
		for anim: String in FRAMES.keys():
			assert_true(sf.has_animation(anim), "%s: tem a animacao %s" % [nome_cor, anim])
			if not sf.has_animation(anim):
				continue
			assert_eq(sf.get_frame_count(anim), FRAMES[anim], "%s/%s: contagem de frames" % [nome_cor, anim])
			for i in range(sf.get_frame_count(anim)):
				var tex := sf.get_frame_texture(anim, i)
				assert_not_null(tex, "%s/%s[%d]: frame nao nulo" % [nome_cor, anim, i])
				if tex != null:
					assert_eq(tex.get_size(), CELULA, "%s/%s[%d]: frame 64x64" % [nome_cor, anim, i])

# C850: o quadro da animacao idle (frame 0) a escala do no ocupa 64x64 no AnimatedSprite2D e no Ghost
func test_escala_do_sprite_e_do_ghost_exibe_64x64() -> void:
	var p := _novo_player()
	var quadro: Vector2 = p.sprite.sprite_frames.get_frame_texture("idle", 0).get_size()
	assert_eq(quadro * p.sprite.scale, CELULA, "AnimatedSprite2D exibe 64x64")
	assert_eq(quadro * p.ghost.scale, CELULA, "Ghost exibe 64x64")
	assert_eq(p.sprite.sprite_frames, _frames_da_cor("AMARELO"), "sprite usa o SpriteFrames da cor inicial")
	assert_eq(p.ghost.sprite_frames, _frames_da_cor("AMARELO"), "ghost usa o SpriteFrames da cor inicial")

# C851: jump, lose e color_change tocam uma vez; idle, run e fall repetem
func test_loop_por_animacao_em_todas_as_cores() -> void:
	for nome_cor: String in Enums.COLOR.keys():
		var sf := _frames_da_cor(nome_cor)
		assert_not_null(sf, "%s: recurso carregado" % nome_cor)
		if sf == null:
			continue
		for anim: String in SEM_LOOP:
			assert_false(sf.get_animation_loop(anim), "%s/%s: sem loop" % [nome_cor, anim])
		for anim: String in COM_LOOP:
			assert_true(sf.get_animation_loop(anim), "%s/%s: com loop" % [nome_cor, anim])

# C852: FPS por animacao = tabela 3.1
func test_fps_por_animacao_segue_a_tabela_3_1() -> void:
	for nome_cor: String in Enums.COLOR.keys():
		var sf := _frames_da_cor(nome_cor)
		assert_not_null(sf, "%s: recurso carregado" % nome_cor)
		if sf == null:
			continue
		for anim: String in FPS.keys():
			assert_eq(sf.get_animation_speed(anim), FPS[anim], "%s/%s: FPS da tabela 3.1" % [nome_cor, anim])

# C853: Enums.COLOR tem exatamente 4 cores e cada uma tem recurso (uma 5a cor sem arte reprova)
func test_enums_color_tem_4_cores_e_cada_uma_tem_recurso() -> void:
	assert_eq(Enums.COLOR.size(), 4, "Enums.COLOR tem 4 cores; cor nova exige arte e atualizar esta contagem")
	for nome_cor: String in Enums.COLOR.keys():
		assert_true(ResourceLoader.exists(_caminho(nome_cor)), "%s: ressources/gecko_%s.tres existe" % [nome_cor, nome_cor.to_lower()])

# C854: colisao do corpo e detector iguais ao HEAD (Player.tscn de antes da f557)
func test_colisao_e_detector_mantem_os_valores_do_head() -> void:
	var p := _novo_player()
	assert_almost_eq(p.collision.shape.size.x, 20.55088, 0.001, "corpo: largura")
	assert_almost_eq(p.collision.shape.size.y, 57.0372, 0.001, "corpo: altura")
	assert_almost_eq(p.collision.position.x, 0.841858, 0.0001, "corpo: pos x")
	assert_almost_eq(p.collision.position.y, -1.122468, 0.0001, "corpo: pos y")
	assert_almost_eq(p.detector.shape.size.x, 19.92024, 0.001, "detector: largura")
	assert_almost_eq(p.detector.shape.size.y, 8.77116, 0.001, "detector: altura")
	assert_almost_eq(p.detector.position.x, 0.52008, 0.0001, "detector: pos x")
	assert_almost_eq(p.detector.position.y, 23.6872, 0.0001, "detector: pos y")

# C855: arquivos de asset da f557 existem e a cena nao referencia mais o Gecko.png antigo
func test_arquivos_de_asset_existem_e_a_cena_nao_usa_o_gecko_antigo() -> void:
	assert_true(FileAccess.file_exists("res://assets/src/_orig/Gecko.png"), "original antigo preservado em _orig")
	assert_true(FileAccess.file_exists("res://assets/src/.gdignore"), "assets/src ignorado pelo Godot")
	for nome_cor: String in Enums.COLOR.keys():
		var png := "res://assets/gecko-%s.png" % nome_cor.to_lower()
		assert_true(FileAccess.file_exists(png), "%s existe" % png)
	var cena := FileAccess.get_file_as_string("res://scenes/Player.tscn")
	assert_false(cena.contains("assets/Gecko.png"), "Player.tscn sem ext_resource do Gecko.png antigo")
