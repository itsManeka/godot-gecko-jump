extends GutHookScript

# Pre-run do GUT (.gutconfig.json), antes de qualquer teste. Troca o `Global.pontuacao` do autoload por um
# ScoreKeeper sem ligacao ao store de producao: nenhum teste grava o user://best_score.cfg real.

const OPTIONS_TEST_PATH := "user://options_test_suite.cfg"


func run():
	Global.pontuacao = ScoreKeeper.new()
	# Opcoes: o Global le o user://options.cfg real no boot (so leitura); aqui o store vira um de caminho temporario
	# (sem arquivo = volumes 1.0, reaplicados nos buses), entao nenhum teste grava o arquivo real.
	DirAccess.remove_absolute(OPTIONS_TEST_PATH)
	Global.usar_options_store(OptionsStore.new(OPTIONS_TEST_PATH))
	# Janela da suite com area visivel fixa em 180x320 (content_scale_aspect KEEP): cena instanciada na raiz
	# le altura e layout de VisibleArea e nao depende do tamanho da janela headless.
	var raiz := Engine.get_main_loop().root as Window
	raiz.content_scale_size = Vector2i(180, 320)
	raiz.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
