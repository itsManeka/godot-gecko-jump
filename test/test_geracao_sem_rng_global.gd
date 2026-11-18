extends GutTest

# Varredura estrutural (le a fonte, nao sobe cena): nenhum sorteio global (randi(), randf(), randf_range(),
# randomize()) em scenes/ e scripts/ fora da lista de excecoes. Sorteio por rng injetado (`rng.randi()`,
# `rng.randf()`, `rng.randf_range()`, `fonte.randomize()` de um RandomNumberGenerator) nao conta: e a seed da
# partida. Comentarios nao contam. A lista e por arquivo, com a quantidade de ocorrencias aceitas e o motivo;
# entrada sem ocorrencia suficiente (ou arquivo sumido) reprova como excecao obsoleta.

const PASTAS: Array[String] = ["res://scenes/", "res://scripts/"]
# Chamada global: randi(, randf(, randf_range(, randomize( sem ponto antes; ou `.randomize(` de um rng.
const PADRAO_SORTEIO_GLOBAL: String = "(?<![\\w.])(randi|randf|randf_range|randomize)\\(|\\.randomize\\("

# caminho -> ocorrencias aceitas e motivo. Partida sem seed = ramos `rng == null`; Global.aplicar_seed fica
# como esta (debug/smoke); Player.rng/pouso fica fora da seed por (d) do ADR 0014 e passa pelo ReachableColors.
const EXCECOES: Dictionary = {
	"res://scenes/RunningPlatforms.gd": {
		"ocorrencias": 5,
		"motivo": "ramos rng == null (partida sem seed): randomize() e randf() globais das fontes sem rng injetado",
	},
	"res://scripts/Enums.gd": {
		"ocorrencias": 1,
		"motivo": "ramo rng == null de Enums.get_random_color (partida sem seed)",
	},
	"res://scripts/Global.gd": {
		"ocorrencias": 1,
		"motivo": "Global.aplicar_seed(null) = sorteio livre (debug/smoke; fora da seed por escopo)",
	},
	"res://scripts/PlatformTypePicker.gd": {
		"ocorrencias": 2,
		"motivo": "ramo rng == null (partida sem seed): randf() e randi() globais do tipo",
	},
	"res://scripts/ReachableColors.gd": {
		"ocorrencias": 1,
		"motivo": "ramo rng == null: randi() global da cor alcancavel (moveis sem rng; pouso do Player fora da seed por (d))",
	},
	"res://scripts/StaticPlatformColors.gd": {
		"ocorrencias": 1,
		"motivo": "ramo rng == null (partida sem seed): randi() global da cor das estaticas",
	},
}


func _arquivos_gd(pasta: String) -> PackedStringArray:
	var achados := PackedStringArray()
	for nome in DirAccess.get_files_at(pasta):
		if nome.ends_with(".gd"):
			achados.append(pasta + nome)
	for sub in DirAccess.get_directories_at(pasta):
		achados.append_array(_arquivos_gd(pasta + sub + "/"))
	return achados


# Numeros das linhas com sorteio global fora de comentario.
func _linhas_com_sorteio(caminho: String) -> PackedStringArray:
	var achados := PackedStringArray()
	var regex := RegEx.new()
	regex.compile(PADRAO_SORTEIO_GLOBAL)
	var numero: int = 0
	for linha in FileAccess.get_file_as_string(caminho).split("\n"):
		numero += 1
		if regex.search(linha.get_slice("#", 0)) != null:
			achados.append(str(numero))
	return achados


# caminho -> numeros das linhas com sorteio global (so arquivos com ocorrencia).
func _mapa_de_sorteios() -> Dictionary:
	var mapa: Dictionary = {}
	for pasta in PASTAS:
		for caminho in _arquivos_gd(pasta):
			var linhas := _linhas_com_sorteio(caminho)
			if not linhas.is_empty():
				mapa[caminho] = linhas
	return mapa


func test_sorteio_global_so_nas_excecoes_listadas() -> void:
	var arquivos_lidos: int = 0
	for pasta in PASTAS:
		arquivos_lidos += _arquivos_gd(pasta).size()
	assert_gt(arquivos_lidos, 0, "a varredura deve enxergar os .gd de scenes/ e scripts/")
	var mapa := _mapa_de_sorteios()
	var fora := PackedStringArray()
	for caminho in mapa:
		var linhas: PackedStringArray = mapa[caminho]
		var aceitas: int = int(EXCECOES.get(caminho, {}).get("ocorrencias", 0))
		if linhas.size() > aceitas:
			fora.append("%s linhas %s (lista aceita %d)" % [caminho, ", ".join(linhas), aceitas])
	assert_true(fora.is_empty(), "sorteio global fora da lista de excecoes: " + "; ".join(fora))


func test_excecao_sem_ocorrencia_reprova() -> void:
	var mapa := _mapa_de_sorteios()
	var obsoletas := PackedStringArray()
	for caminho in EXCECOES:
		var aceitas: int = int(EXCECOES[caminho]["ocorrencias"])
		if not FileAccess.file_exists(caminho):
			obsoletas.append("%s nao existe" % caminho)
			continue
		var reais: int = 0
		if mapa.has(caminho):
			reais = mapa[caminho].size()
		if reais < aceitas:
			obsoletas.append("%s tem %d ocorrencia(s), lista aceita %d" % [caminho, reais, aceitas])
	assert_true(obsoletas.is_empty(), "excecao obsoleta na lista de excecoes: " + "; ".join(obsoletas))
