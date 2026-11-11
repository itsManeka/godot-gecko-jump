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
const RETRATOS: Array[String] = [
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


func test_cada_roteiro_tem_ao_menos_um_passo_expect() -> void:
	for nome in ROTEIROS:
		assert_gt(_expects(nome).size(), 0, "cada roteiro deve ter ao menos um passo expect")


func test_gecko_conserva_a_derrota_proposital() -> void:
	var achou_derrota: bool = false
	for passo in _expects("gecko"):
		if passo["expect"].get("state", null) == "lost":
			achou_derrota = true
	assert_true(achou_derrota, "gecko.smoke.json deve esperar state lost (derrota proposital)")


func test_rajada_pulo2_dos_retratos_nao_exige_movimento_e_confere_score() -> void:
	for nome in RETRATOS:
		var passos := _passos(nome)
		var rajadas: int = 0
		for i in passos.size():
			var passo: Dictionary = passos[i]
			if not str(passo.get("name", "")).ends_with("-pulo2"):
				continue
			rajadas += 1
			assert_eq(passo.get("moving", null), false, "a rajada pulo2 deve declarar moving false")
			var anterior: Dictionary = passos[i - 1]
			assert_true(anterior.has("expect"), "o passo antes da rajada pulo2 deve ser um expect")
			var exigencia: Dictionary = anterior.get("expect", {})
			assert_true(exigencia.has("score"), "o expect da rajada pulo2 deve conferir score")
			assert_false(exigencia.has("player.alive"), "o expect da rajada pulo2 nao deve exigir alive")
			var comparacao: Variant = exigencia.get("score", null)
			assert_true(typeof(comparacao) == TYPE_DICTIONARY and comparacao.has("gte"), "a conferencia de score deve usar gte")
		assert_eq(rajadas, 2, "cada retrato deve ter 2 rajadas pulo2 (partida 1 e 2)")


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
