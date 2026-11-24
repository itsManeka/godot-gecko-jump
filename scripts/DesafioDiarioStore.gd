class_name DesafioDiarioStore
extends RefCounted

# Estado do Desafio diario em user:// (caminho injetavel, T3). Um registro: {dia, tentativa_gasta,
# resultado}. Gravacao atomica tmp+rename como o BestScoreStore; falhas de leitura e de escrita sao
# silenciosas: arquivo ausente/corrompido/valor invalido vale "nao jogado hoje, resultado 0", nunca
# crash. A virada do dia zera sem apagar nada: dia salvo != dia consultado => tentativa disponivel e
# resultado 0. O arquivo e separado dos best_score_*.cfg — gravar aqui nunca toca os outros modos.

const CAMINHO_PADRAO := "user://desafio_diario.cfg"
const SECTION := "desafio"
const KEY_DIA := "dia"
const KEY_TENTATIVA := "tentativa_gasta"
const KEY_RESULTADO := "resultado"
const DIA_SEM_REGISTRO := -1

# Suite do GUT (gut_pre_run.gd): redireciona o caminho padrao para um arquivo de teste, como o
# options store — nenhum teste grava o user://desafio_diario.cfg real.
static var _caminho_isolado: String = ""

var caminho: String
var _estado: Dictionary


static func caminho_padrao() -> String:
	return _caminho_isolado if _caminho_isolado != "" else CAMINHO_PADRAO


static func isolar_caminho_padrao(caminho: String) -> void:
	_caminho_isolado = caminho


func _init(caminho_injetado: String = "") -> void:
	# caminho_padrao() sem prefixo da classe: o nome global pode ainda nao estar no cache de classes
	# em rodadas sem o passo --import do editor.
	caminho = caminho_injetado if caminho_injetado != "" else caminho_padrao()
	_estado = _ler_estado()


func tentativa_disponivel(dia: int) -> bool:
	return _estado[KEY_DIA] != dia or not _estado[KEY_TENTATIVA]


func gastar_tentativa(dia: int) -> void:
	if _estado[KEY_DIA] != dia:
		_estado = _sem_registro(dia)
	_estado[KEY_TENTATIVA] = true
	_gravar()


func gravar_resultado(dia: int, pontos: int) -> void:
	if _estado[KEY_DIA] != dia:
		_estado = _jogado(dia)
	_estado[KEY_RESULTADO] = maxi(0, pontos)
	_gravar()


func resultado_do(dia: int) -> int:
	return _estado[KEY_RESULTADO] if _estado[KEY_DIA] == dia else 0


func _sem_registro(dia: int = DIA_SEM_REGISTRO) -> Dictionary:
	return {KEY_DIA: dia, KEY_TENTATIVA: false, KEY_RESULTADO: 0}


func _jogado(dia: int) -> Dictionary:
	return {KEY_DIA: dia, KEY_TENTATIVA: true, KEY_RESULTADO: 0}


# Le o registro do disco. Ausente, corrompido ou com valor invalido (dia nao int ou negativo,
# tentativa nao bool, resultado nao int ou negativo) vale registro vazio — sem push_error/push_warning.
func _ler_estado() -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(caminho) != OK:
		return _sem_registro()
	# Defaults tipados (nunca NIL: default NIL faz o motor logar uma condicao a cada get_value):
	# dia -1 nunca e dia valido, 0 (int) nunca e bool valido, resultado -1 nunca e resultado valido —
	# chave ausente devolve o sentinela e o registro inteiro cai no estado vazio.
	var dia: Variant = cfg.get_value(SECTION, KEY_DIA, -1)
	var gasta: Variant = cfg.get_value(SECTION, KEY_TENTATIVA, 0)
	var resultado: Variant = cfg.get_value(SECTION, KEY_RESULTADO, -1)
	if typeof(dia) != TYPE_INT or dia < 0:
		return _sem_registro()
	if typeof(gasta) != TYPE_BOOL:
		return _sem_registro()
	if typeof(resultado) != TYPE_INT or resultado < 0:
		return _sem_registro()
	return {KEY_DIA: dia, KEY_TENTATIVA: gasta, KEY_RESULTADO: resultado}


# Grava de forma atomica (tmp + rename, sem await). Falha de escrita ou de rename e ignorada: o
# estado em memoria segue valido na instancia que gravou (a nova instancia le o que houver no disco).
func _gravar() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, KEY_DIA, int(_estado[KEY_DIA]))
	cfg.set_value(SECTION, KEY_TENTATIVA, bool(_estado[KEY_TENTATIVA]))
	cfg.set_value(SECTION, KEY_RESULTADO, int(_estado[KEY_RESULTADO]))
	var tmp := caminho + ".tmp"
	if cfg.save(tmp) != OK:
		return
	if DirAccess.rename_absolute(tmp, caminho) != OK:
		DirAccess.remove_absolute(tmp)
