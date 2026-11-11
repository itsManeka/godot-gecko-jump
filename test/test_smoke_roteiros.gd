extends GutTest

# Validacao estatica dos roteiros de smoke (test/smoke/*.smoke.json): seed no path, passos `expect` e contrato do
# runner (chaves publicadas pela ponte GameState, operadores eq/ne/gt/gte/lt/lte). Nao sobe export nem navegador.

const PASTA: String = "res://test/smoke/"
const ROTEIROS: Array[String] = [
	"gecko",
	"janela-larga-1280x720",
	"retrato-1080x2400",
	"retrato-1080x2772",
	"retrato-1170x2532",
	"retrato-720x1280",
	"retrato-queda-720x1280",
]
const ROTEIROS_LONGOS: Array[String] = [
	"gecko",
	"retrato-1080x2400",
	"retrato-1080x2772",
	"retrato-1170x2532",
	"retrato-720x1280",
]
const CHAVES_PUBLICADAS: Array[String] = ["score", "best", "state", "player.alive"]
const OPERADORES: Array[String] = ["eq", "ne", "gt", "gte", "lt", "lte"]
const TIMEOUT_MIN_APOS_QUEDA_MS: int = 3000


func _carregar(nome: String) -> Dictionary:
	var arquivo := FileAccess.open(PASTA + nome + ".smoke.json", FileAccess.READ)
	if arquivo == null:
		return {}
	var parsed: Variant = JSON.parse_string(arquivo.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _passos(nome: String) -> Array:
	return _carregar(nome).get("steps", [])


func _expects(nome: String) -> Array:
	var out: Array = []
	for passo in _passos(nome):
		if passo.has("expect"):
			out.append(passo)
	return out


func _checar_roteiro_com_seed(nome: String) -> void:
	var spec := _carregar(nome)
	assert_gt(spec.size(), 0, "o roteiro deve existir e parsear como objeto JSON")
	var caminho: String = str(spec.get("path", ""))
	assert_true(caminho.begins_with("index.html?"), "o path deve ser index.html com query string")
	assert_true("seed=" in caminho, "o path deve carregar seed=")


func test_gecko_parseia_e_tem_seed() -> void:
	_checar_roteiro_com_seed("gecko")


func test_janela_larga_parseia_e_tem_seed() -> void:
	_checar_roteiro_com_seed("janela-larga-1280x720")


func test_retrato_1080x2400_parseia_e_tem_seed() -> void:
	_checar_roteiro_com_seed("retrato-1080x2400")


func test_retrato_1080x2772_parseia_e_tem_seed() -> void:
	_checar_roteiro_com_seed("retrato-1080x2772")


func test_retrato_1170x2532_parseia_e_tem_seed() -> void:
	_checar_roteiro_com_seed("retrato-1170x2532")


func test_retrato_720x1280_parseia_e_tem_seed() -> void:
	_checar_roteiro_com_seed("retrato-720x1280")


func test_retrato_queda_parseia_e_tem_seed() -> void:
	_checar_roteiro_com_seed("retrato-queda-720x1280")


func test_cada_roteiro_tem_expect_e_state_lost_so_na_queda() -> void:
	for nome in ROTEIROS:
		assert_gt(_expects(nome).size(), 0, "cada roteiro deve ter ao menos um passo expect")
		var espera_lost: bool = false
		for passo in _expects(nome):
			var estado: Variant = passo["expect"].get("state", null)
			if typeof(estado) == TYPE_STRING and estado == "lost":
				espera_lost = true
		if nome == "retrato-queda-720x1280":
			assert_true(espera_lost, "o roteiro de queda deve esperar state lost")
		else:
			assert_false(espera_lost, "so o roteiro de queda espera state lost (o gecko pode ja estar no menu)")


func test_roteiros_longos_nao_dependem_do_gecko_sobreviver() -> void:
	for nome in ROTEIROS_LONGOS:
		var passos := _passos(nome)
		var rajadas: int = 0
		for i in passos.size():
			var passo: Dictionary = passos[i]
			if passo.has("expect"):
				assert_false(passo["expect"].has("score"), "nenhum expect dos roteiros longos le score")
				assert_false(passo["expect"].has("player.alive"), "nenhum expect dos roteiros longos le player.alive")
			if str(passo.get("name", "")).ends_with("-pulo2"):
				rajadas += 1
				assert_eq(passo.get("moving", null), false, "a rajada pulo2 deve declarar moving false")
			if passo.get("down", "") == "ArrowLeft":
				var seguinte: Dictionary = passos[i + 1]
				assert_eq(seguinte.get("expect", {}), {"state": {"ne": "playing"}}, "o expect apos a seta deve ser state ne playing")
				assert_gte(int(seguinte.get("timeout_ms", 0)), TIMEOUT_MIN_APOS_QUEDA_MS, "o expect apos a seta deve ter timeout_ms >= 3000")
		assert_eq(rajadas, 2, "cada roteiro longo deve ter 2 rajadas pulo2 (partida 1 e 2)")


func test_expect_apos_queda_ou_animacao_tem_timeout_de_ao_menos_3s() -> void:
	for nome in ROTEIROS:
		for passo in _expects(nome):
			assert_true(passo.has("timeout_ms"), "todo expect deve declarar timeout_ms")
			assert_gte(int(passo.get("timeout_ms", 0)), TIMEOUT_MIN_APOS_QUEDA_MS, "todo expect deve ter timeout_ms >= 3000")


func test_expect_usa_so_chaves_e_operadores_do_contrato() -> void:
	for nome in ROTEIROS:
		for passo in _expects(nome):
			var exigencia: Dictionary = passo["expect"]
			assert_gt(exigencia.size(), 0, "expect nao pode ser vazio")
			for chave in exigencia.keys():
				assert_true(CHAVES_PUBLICADAS.has(str(chave)), "a chave do expect deve ser uma das publicadas pela ponte")
				var valor: Variant = exigencia[chave]
				if typeof(valor) == TYPE_DICTIONARY:
					assert_eq(valor.size(), 1, "o objeto de comparacao deve ter exatamente um operador")
					for operador in valor.keys():
						assert_true(OPERADORES.has(str(operador)), "o operador deve ser eq/ne/gt/gte/lt/lte")
