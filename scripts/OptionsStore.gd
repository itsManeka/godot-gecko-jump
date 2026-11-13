class_name OptionsStore
extends RefCounted

# Persistencia das opcoes (ConfigFile). Caminho injetavel; so o default aponta para user://.
# Volumes (music, sfx) sao float linear em [0,1]; ausente, corrompido, tipo errado ou fora da faixa vale 1.0 por canal.
# Gravacao atomica e ler-mesclar-gravar: le o cfg atual, troca so a chave pedida (preserva as outras, inclusive de
# outros chamadores), escreve em <path>.tmp e renomeia para <path> no mesmo frame (sem await; no Web o sync do IDBFS
# depende disso). Se o rename falhar, remove o .tmp. Falhas de leitura ou escrita sao silenciosas.

const DEFAULT_PATH := "user://options.cfg"
const SECTION_AUDIO := "audio"
const KEY_MUSIC := "music"
const KEY_SFX := "sfx"
const DEFAULT_VOLUME := 1.0
const MUTE_DB := -80.0

var path: String

func _init(p := DEFAULT_PATH) -> void:
	path = p

# Converte volume linear [0,1] em dB. 0 vale o piso finito MUTE_DB (nunca -INF); 1 vale 0 dB.
static func volume_linear_to_db(linear: float) -> float:
	if linear <= 0.0:
		return MUTE_DB
	return maxf(linear_to_db(linear), MUTE_DB)

func load_music() -> float:
	return _load_volume(KEY_MUSIC)

func load_sfx() -> float:
	return _load_volume(KEY_SFX)

func save_music(value: float) -> void:
	save_value(SECTION_AUDIO, KEY_MUSIC, value)

func save_sfx(value: float) -> void:
	save_value(SECTION_AUDIO, KEY_SFX, value)

# Le um valor qualquer (para outros chamadores, ex.: flags). Devolve default se ausente ou ilegivel.
func load_value(section: String, key: String, default: Variant) -> Variant:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return default
	return cfg.get_value(section, key, default)

# Grava uma chave preservando as demais (ler-mesclar-gravar atomico). Falha e silenciosa.
func save_value(section: String, key: String, value: Variant) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		cfg = ConfigFile.new()
	cfg.set_value(section, key, value)
	var tmp := path + ".tmp"
	if cfg.save(tmp) != OK:
		return
	if DirAccess.rename_absolute(tmp, path) != OK:
		DirAccess.remove_absolute(tmp)

func _load_volume(key: String) -> float:
	var value: Variant = load_value(SECTION_AUDIO, key, DEFAULT_VOLUME)
	var t := typeof(value)
	if t != TYPE_FLOAT and t != TYPE_INT:
		return DEFAULT_VOLUME
	var f := float(value)
	if is_nan(f) or f < 0.0 or f > 1.0:
		return DEFAULT_VOLUME
	return f
