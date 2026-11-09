extends GutHookScript

# Pre-run do GUT (.gutconfig.json), antes de qualquer teste. Troca o `Global.pontuacao` do autoload por um
# ScoreKeeper sem ligacao ao store de producao: nenhum teste grava o user://best_score.cfg real.


func run():
	Global.pontuacao = ScoreKeeper.new()
