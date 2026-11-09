class_name BestScoreStore
extends RefCounted

# Persistencia do recorde em arquivo (ConfigFile). Caminho injetavel; so o default aponta para user://.
# Falhas de leitura ou escrita sao silenciosas: arquivo ausente ou invalido vale recorde 0.

const DEFAULT_PATH := "user://best_score.cfg"
const SECTION := "score"
const KEY := "best"

var path: String

func _init(p := DEFAULT_PATH) -> void:
	path = p

# Le o recorde salvo. Devolve 0 se o arquivo nao existe, nao carrega, nao tem a chave ou o valor nao e int >= 0.
func load_best() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return 0
	var value: Variant = cfg.get_value(SECTION, KEY, 0)
	if typeof(value) != TYPE_INT or (value as int) < 0:
		return 0
	return value as int

# Grava o recorde. Falha de escrita e ignorada (sem push_error).
func save_best(value: int) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, KEY, value)
	cfg.save(path)
