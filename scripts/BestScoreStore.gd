class_name BestScoreStore
extends RefCounted

# Persistencia do recorde em arquivo (ConfigFile). Caminho injetavel; so o default aponta para user://.
# Gravacao atomica: escreve em <path>.tmp e, so se a escrita der OK, renomeia para <path> no mesmo frame
# (no Web o sync do IDBFS depende disso). Se o rename falhar, remove o .tmp (best-effort).
# Falhas de leitura ou escrita sao silenciosas: arquivo ausente ou invalido vale recorde 0.

const DEFAULT_PATH := "user://best_score.cfg"
const SECTION := "score"
const KEY := "best"

var path: String

func _init(p := DEFAULT_PATH) -> void:
	path = p

# Store do recorde do modo. O id passa pelo registro (GameModes.de_id): desconhecido, vazio, nulo ou `teste` sem a
# flag de debug caem no Classico, entao o caminho nunca carrega texto de entrada externa. Classico = `caminho_classico`
# (default DEFAULT_PATH); demais modos = `user://best_score_<id>.cfg` no mesmo diretorio (caminho_classico injetavel para teste).
static func para_modo(id: Variant, caminho_classico: String = DEFAULT_PATH) -> BestScoreStore:
	var modo := GameModes.de_id(id)
	if modo.id == GameModes.ID_CLASSICO:
		return BestScoreStore.new(caminho_classico)
	var diretorio := caminho_classico.get_base_dir()
	if not diretorio.ends_with("/"):
		diretorio += "/"
	return BestScoreStore.new(diretorio + "best_score_%s.cfg" % String(modo.id))

# Le o recorde salvo. Devolve 0 se o arquivo nao existe, nao carrega, nao tem a chave ou o valor nao e int >= 0.
func load_best() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return 0
	var value: Variant = cfg.get_value(SECTION, KEY, 0)
	if typeof(value) != TYPE_INT or (value as int) < 0:
		return 0
	return value as int

# Grava o recorde de forma atomica (tmp + rename, sem await). Falha de escrita ou de rename e ignorada (sem push_error).
func save_best(value: int) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, KEY, value)
	var tmp := path + ".tmp"
	if cfg.save(tmp) != OK:
		return
	if DirAccess.rename_absolute(tmp, path) != OK:
		DirAccess.remove_absolute(tmp)
