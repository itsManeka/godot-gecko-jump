extends GutHookScript

# Pre-run do GUT (.gutconfig.json), antes de qualquer teste. Troca o `Global.pontuacao` do autoload por um
# ScoreKeeper sem ligacao ao store de producao: nenhum teste grava o user://best_score.cfg real.

const OPTIONS_TEST_PATH := "user://options_test_suite.cfg"
const DIARIO_TEST_PATH := "user://desafio_diario_test_suite.cfg"
const DiarioStoreScript := preload("res://scripts/DesafioDiarioStore.gd")


func run():
	# Antes do options store: usar_options_store escolhe o keeper do modo e nao pode religar ao store real.
	Global.isolar_recordes()
	# Opcoes: o Global le o user://options.cfg real no boot (so leitura); aqui o store vira um de caminho temporario
	# (sem arquivo = volumes 1.0, reaplicados nos buses), entao nenhum teste grava o arquivo real.
	DirAccess.remove_absolute(OPTIONS_TEST_PATH)
	Global.usar_options_store(OptionsStore.new(OPTIONS_TEST_PATH))
	# Diario (T3): mesmo padrao do options — o caminho padrao do store do dia vira um de teste; nenhum
	# teste grava o user://desafio_diario.cfg real (vale tambem quando T6 ligar a Stage sem caminho injetado).
	DirAccess.remove_absolute(DIARIO_TEST_PATH)
	DiarioStoreScript.isolar_caminho_padrao(DIARIO_TEST_PATH)
	# Janela da suite com area visivel fixa em 360x640 (content_scale_aspect KEEP): cena instanciada na raiz
	# le altura e layout de VisibleArea e nao depende do tamanho da janela headless.
	var raiz := Engine.get_main_loop().root as Window
	raiz.content_scale_size = Vector2i(360, 640)
	raiz.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
