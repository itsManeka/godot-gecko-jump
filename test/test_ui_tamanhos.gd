extends GutTest
## Escala de fontes da UI (multiplos do nativo, 16 e 32): import da fonte, varredura de tamanhos literais e layout.

const FONTE_IMPORT: String = "res://fonts/alterebro-pixel-font.ttf.import"
const STAGE: String = "res://scenes/Stage.tscn"
const LARGURA_TELA: float = 180.0
const ALTURA_TELA: float = 320.0

var _re_tscn: RegEx
var _re_override: RegEx
var _re_const: RegEx


func before_each() -> void:
	Global.tutorial_visto_espelho = true
	Global.platforms = []
	Global.iniciado = false
	_re_tscn = RegEx.create_from_string("theme_override_font_sizes/\\w+\\s*=\\s*(\\d+)")
	_re_override = RegEx.create_from_string("add_theme_font_size_override\\(\\s*\"[^\"]*\"\\s*,\\s*(\\d+)\\s*\\)")
	_re_const = RegEx.create_from_string("const\\s+(?:TAMANHO_\\w+|FONT_SIZE)\\s*:\\s*int\\s*=\\s*(\\d+)")


func after_each() -> void:
	Global.platforms = []
	Global.iniciado = false


func _arquivos(pasta: String, extensao: String) -> Array[String]:
	var achados: Array[String] = []
	for nome in DirAccess.get_files_at(pasta):
		if nome.ends_with(extensao):
			achados.append(pasta.path_join(nome))
	return achados


# Retangulo que o Stage.tscn declara para o Play (offsets do texto da cena; o apply_layout mexe nos da instancia).
func _offsets_do_play() -> Rect2:
	var texto := FileAccess.get_file_as_string(STAGE)
	var inicio := texto.find("[node name=\"Play\"")
	var bloco := texto.substr(inicio, texto.find("[node name=", inicio + 1) - inicio)
	var re := RegEx.create_from_string("offset_(left|top|right|bottom) = ([0-9.]+)")
	var v: Dictionary = {}
	for m in re.search_all(bloco):
		v[m.get_string(1)] = float(m.get_string(2))
	return Rect2(v["left"], v["top"], v["right"] - v["left"], v["bottom"] - v["top"])


# Todo tamanho de fonte literal (cena e script) como "arquivo: valor".
func _tamanhos_literais() -> Dictionary:
	var achados: Dictionary = {}
	var fontes: Array[String] = []
	fontes.append_array(_arquivos("res://scenes", ".tscn"))
	fontes.append_array(_arquivos("res://scenes", ".gd"))
	fontes.append_array(_arquivos("res://scripts", ".gd"))
	for caminho in fontes:
		var texto := FileAccess.get_file_as_string(caminho)
		for re in [_re_tscn, _re_override, _re_const]:
			for m in (re as RegEx).search_all(texto):
				achados["%s#%d" % [caminho, m.get_start()]] = int(m.get_string(1))
	return achados


# C344: varredura estrutural; reverter qualquer cena para 20/26/36 reprova.
func test_c344_todo_font_size_literal_pertence_a_tamanhos_ui() -> void:
	var achados := _tamanhos_literais()
	assert_gte(achados.size(), 7, "a varredura achou os 4 tamanhos do Stage.tscn e as 3 constantes de UiHelpers")
	for chave in achados:
		assert_true(UiHelpers.TAMANHOS_UI.has(achados[chave]), "%s = %d fora de TAMANHOS_UI" % [chave, achados[chave]])


func test_c344_stage_tscn_tem_quatro_tamanhos_da_escala() -> void:
	var texto := FileAccess.get_file_as_string(STAGE)
	var valores: Array[int] = []
	for m in _re_tscn.search_all(texto):
		valores.append(int(m.get_string(1)))
	assert_eq(valores, [32, 32, 16, 16] as Array[int], "Pontos, Play, Last, Best")


# C346: import da fonte com os valores provados (sem hinting nem subpixel, oversampling 1).
func test_c346_import_da_fonte_sem_hinting_nem_subpixel() -> void:
	var cfg := ConfigFile.new()
	assert_eq(cfg.load(FONTE_IMPORT), OK)
	assert_eq(int(cfg.get_value("params", "hinting")), 0)
	assert_eq(int(cfg.get_value("params", "subpixel_positioning")), 0)
	assert_almost_eq(float(cfg.get_value("params", "oversampling")), 1.0, 0.0001)
	assert_eq(int(cfg.get_value("params", "antialiasing")), 0)


# C347: com a fonte em 16 o texto mais longo cabe e nenhum retangulo passa da viewport.
func test_c347_tutorial_e_dica_cabem_na_viewport_180x320() -> void:
	var card: TutorialCard = add_child_autofree(TutorialCard.new())
	card.aplicar_layout(Vector2(LARGURA_TELA, ALTURA_TELA), Rect2(0.0, 0.0, LARGURA_TELA, ALTURA_TELA))
	var textos: Array[String] = ["Pise na cor dele.", "Pouso troca a cor.", "Toque nas metades", "Setas e espaco", "diferente"]
	for t in textos:
		assert_lte(TutorialCard.largura_texto(t), TutorialCard.LARGURA_CONTEUDO, "'%s' cabe em 148 px" % t)
	var tela := Rect2(0.0, 0.0, LARGURA_TELA, ALTURA_TELA)
	assert_true(tela.encloses(card.rect_fundo()), "card dentro de 180x320")
	assert_true(tela.encloses(card.rect_pular()), "botao Pular dentro de 180x320")
	var hint: TouchHint = add_child_autofree(TouchHint.new())
	hint.aplicar_layout(Vector2(LARGURA_TELA, ALTURA_TELA), Rect2(0.0, 0.0, LARGURA_TELA, ALTURA_TELA))
	for lado in [TouchHint.Lado.ESQUERDA, TouchHint.Lado.DIREITA]:
		var r := hint.rect_bloco(lado)
		assert_true(tela.encloses(r), "bloco da dica %d dentro de 180x320" % lado)
		assert_lte(TouchHint.largura_texto(TouchHint.TEXTO_SEGURA), r.size.x, "'segura: anda' cabe no bloco")
		assert_lte(TouchHint.largura_texto(TouchHint.TEXTO_PULA), r.size.x, "'pula' cabe no bloco")


# C348: botoes comportam o rotulo (fonte real) sem corte em 180x320.
func test_c348_play_e_botoes_de_menu_comportam_o_rotulo() -> void:
	var stage: Node = add_child_autofree(load(STAGE).instantiate())
	var scroll: Node = stage.get_node("ScrollLevel")
	stage.remove_child(scroll)
	scroll.free()
	stage.apply_layout(Vector2(LARGURA_TELA, ALTURA_TELA), Rect2(0.0, 0.0, LARGURA_TELA, ALTURA_TELA))
	var play := stage.get_node("CanvasLayer/Play") as Control
	var largura_play := UiHelpers.FONTE.get_string_size("Play", HORIZONTAL_ALIGNMENT_LEFT, -1, UiHelpers.TAMANHO_BOTAO).x
	assert_lte(largura_play, play.get_global_rect().size.x, "'Play' cabe no botao")
	assert_gte(play.get_global_rect().size.y, play.get_minimum_size().y, "altura do Play comporta a fonte de 32 px")
	# O Button cresce sozinho ate o minimo do texto; o que a cena declara (offsets) tem de comportar o rotulo por si
	var declarado := _offsets_do_play()
	assert_gte(declarado.size.x, largura_play, "largura declarada do Play comporta 'Play'")
	assert_gte(declarado.size.y, play.get_minimum_size().y, "altura declarada do Play comporta a fonte")

	var pausa: PauseOverlay = add_child_autofree(PauseOverlay.new())
	pausa.aplicar_layout(Vector2(LARGURA_TELA, ALTURA_TELA), Rect2(0.0, 0.0, LARGURA_TELA, ALTURA_TELA))
	for par in [["> Continuar", pausa.rect_continuar()], ["> Opcoes", pausa.rect_opcoes()]]:
		var l := UiHelpers.FONTE.get_string_size(par[0], HORIZONTAL_ALIGNMENT_LEFT, -1, UiHelpers.TAMANHO_TEXTO).x
		assert_lte(l, (par[1] as Rect2).size.x, "'%s' cabe no botao da pausa" % par[0])

	var botao: OpcoesBotao = add_child_autofree(OpcoesBotao.new())
	botao.aplicar_layout(Vector2(LARGURA_TELA, ALTURA_TELA), Rect2(0.0, 0.0, LARGURA_TELA, ALTURA_TELA))
	var l_opcoes := UiHelpers.FONTE.get_string_size("> Opcoes", HORIZONTAL_ALIGNMENT_LEFT, -1, OpcoesBotao.TAMANHO_TEXTO).x
	assert_lte(l_opcoes, botao.rect_botao().size.x, "'> Opcoes' cabe no botao do menu")

	var opcoes: OptionsScreen = add_child_autofree(OptionsScreen.new())
	opcoes.aplicar_layout(Vector2(LARGURA_TELA, ALTURA_TELA), Rect2(0.0, 0.0, LARGURA_TELA, ALTURA_TELA))
	var l_tutorial := UiHelpers.FONTE.get_string_size("> Ver tutorial", HORIZONTAL_ALIGNMENT_LEFT, -1, OptionsScreen.TAMANHO_TEXTO).x
	assert_lte(l_tutorial, opcoes.rect_ver_tutorial().size.x, "'> Ver tutorial' cabe no botao")


# C349: placar com valores de 4 digitos a 16 px cabe nos 180 px do Last/Best.
func test_c349_ultima_e_melhor_pontuacao_de_4_digitos_cabem_em_180() -> void:
	for texto in ["Ultima pontuacao: 1000", "Melhor pontuacao: 1000", "Melhor pontuacao: 9999"]:
		var l := UiHelpers.FONTE.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, UiHelpers.TAMANHO_TEXTO).x
		assert_lte(l, LARGURA_TELA, "'%s' cabe em 180 px sem quebra" % texto)
