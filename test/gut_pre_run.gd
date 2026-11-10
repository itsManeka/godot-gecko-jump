extends GutHookScript

# Pre-run do GUT (.gutconfig.json), antes de qualquer teste. Troca o `Global.pontuacao` do autoload por um
# ScoreKeeper sem ligacao ao store de producao: nenhum teste grava o user://best_score.cfg real.


func run():
	Global.pontuacao = ScoreKeeper.new()
	# Janela da suite com area visivel fixa em 180x320 (aspect KEEP): testes que instanciam o Player na raiz
	# leem a largura de VisibleArea e nao dependem do tamanho da janela headless.
	var raiz := Engine.get_main_loop().root as Window
	raiz.content_scale_size = Vector2i(180, 320)
	raiz.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
