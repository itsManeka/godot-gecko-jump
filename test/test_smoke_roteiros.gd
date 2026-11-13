extends GutTest

# Validacao estatica dos roteiros de smoke (test/smoke/*.smoke.json): seed no path, passos `expect` e contrato do
# runner (chaves publicadas pela ponte GameState, operadores eq/ne/gt/gte/lt/lte) e orcamento de tempo das rajadas
# `moving: true` desde o Play (issue #40). Nao sobe export nem navegador.

const PASTA: String = "res://test/smoke/"
const ROTEIROS: Array[String] = [
	"dica-toque",
	"estagio",
	"gecko",
	"janela-larga-1280x720",
	"retrato-1080x2400",
	"retrato-1080x2772",
	"retrato-1170x2532",
	"retrato-720x1280",
	"retrato-pontua-1080x2772",
	"retrato-queda-720x1280",
	"toque",
]
const ROTEIROS_LONGOS: Array[String] = [
	"gecko",
	"retrato-1080x2400",
	"retrato-1080x2772",
	"retrato-1170x2532",
	"retrato-720x1280",
]
const CHAVES_PUBLICADAS: Array[String] = ["score", "best", "state", "player.alive", "dificuldade.estagio"]
const ROTEIROS_SEMDERROTA: Array[String] = [
	"retrato-pontua-1080x2772",
	"estagio",
	"gecko",
	"retrato-1080x2400",
	"retrato-1080x2772",
	"retrato-1170x2532",
	"retrato-720x1280",
]
const OPERADORES: Array[String] = ["eq", "ne", "gt", "gte", "lt", "lte"]
const TIMEOUT_MIN_APOS_QUEDA_MS: int = 3000
# Orcamento do tempo nominal (wait + (shots-1)*every) do Play ate o ultimo print de uma rajada moving true: a recarga
# pos-derrota so ocorre ~2,3 s depois do Play; 1,5 s deixa folga para a sobrecarga do screenshot (issue #40).
const ORCAMENTO_RAJADA_MOVING_MS: int = 1500
const FREEZE_SHOTS_PADRAO: int = 4


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


func test_retrato_pontua_parseia_com_seed_e_semderrota() -> void:
	_checar_roteiro_com_seed("retrato-pontua-1080x2772")
	var caminho: String = str(_carregar("retrato-pontua-1080x2772").get("path", ""))
	assert_true("semderrota=1" in caminho, "o roteiro pontua deve ligar o modo sem derrota (semderrota=1)")


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


func test_roteiros_longos_esperam_state_playing_antes_de_cada_rajada_de_pulo() -> void:
	for nome in ROTEIROS_LONGOS:
		var passos := _passos(nome)
		var protegidos: int = 0
		for i in passos.size():
			if passos[i].get("down", "") != "Space":
				continue
			# o `down Space` abre uma rajada pulo1/pulo2 quando o 1o `shots` depois dele tem esse nome
			var j: int = i + 1
			while j < passos.size() and not passos[j].has("shots"):
				j += 1
			if j >= passos.size():
				continue
			var rajada: String = str(passos[j].get("name", ""))
			if not (rajada.ends_with("-pulo1") or rajada.ends_with("-pulo2")):
				continue
			assert_gt(i, 0, "%s: o down Space de %s nao pode ser o 1o passo" % [nome, rajada])
			var anterior: Dictionary = passos[i - 1]
			assert_eq(anterior.get("expect", {}), {"state": "playing"}, "%s: o down Space de %s deve ser precedido por expect state playing" % [nome, rajada])
			assert_gte(int(anterior.get("timeout_ms", 0)), TIMEOUT_MIN_APOS_QUEDA_MS, "%s: o expect antes de %s deve ter timeout_ms >= 3000" % [nome, rajada])
			protegidos += 1
		assert_eq(protegidos, 4, "%s: 4 rajadas de pulo (2 por partida) devem ter o expect state playing antes" % nome)


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


# Um `down Space` ou um `click` (toque no Play) inicia a partida quando, depois dele, so `wait`/`up` precedem um `expect` com state eq "playing".
func _inicia_partida(passos: Array, i: int) -> bool:
	if passos[i].get("down", "") != "Space" and not passos[i].has("click"):
		return false
	var j: int = i + 1
	while j < passos.size() and (passos[j].has("wait") or passos[j].has("up")):
		j += 1
	if j >= passos.size() or not passos[j].has("expect"):
		return false
	return passos[j]["expect"].get("state", null) == "playing"


func _estouros_de_orcamento(nome: String) -> Array[String]:
	return _estouros_do_spec(nome, _carregar(nome))


func _estouros_do_spec(nome: String, spec: Dictionary) -> Array[String]:
	var freeze: int = FREEZE_SHOTS_PADRAO
	var freeze_spec: Variant = spec.get("freeze_shots", null)
	if (typeof(freeze_spec) == TYPE_FLOAT or typeof(freeze_spec) == TYPE_INT) and freeze_spec == floorf(float(freeze_spec)) and freeze_spec > 1:
		freeze = int(freeze_spec)
	var passos: Array = spec.get("steps", [])
	var acumulado: int = 0
	var estouros: Array[String] = []
	for i in passos.size():
		var passo: Dictionary = passos[i]
		if _inicia_partida(passos, i):
			acumulado = 0
		if passo.has("wait"):
			acumulado += int(passo["wait"])
		if passo.has("shots"):
			var shots: int = int(passo["shots"])
			acumulado += maxi(shots - 1, 0) * int(passo.get("every", 200))
			if passo.get("moving", false) == true and shots >= freeze and acumulado > ORCAMENTO_RAJADA_MOVING_MS:
				estouros.append("%s/%s: %d ms" % [nome, str(passo.get("name", "")), acumulado])
	return estouros


func test_rajada_moving_true_termina_dentro_do_orcamento_desde_o_play() -> void:
	for nome in ROTEIROS:
		var estouros := _estouros_de_orcamento(nome)
		assert_eq(estouros.size(), 0, "rajada moving true fora do orcamento de %d ms desde o Play (roteiro/rajada: %s)" % [ORCAMENTO_RAJADA_MOVING_MS, ", ".join(estouros)])


func test_falha_do_orcamento_cita_roteiro_e_nome_da_rajada() -> void:
	var spec: Dictionary = {
		"steps": [
			{"down": "Space"},
			{"wait": 150},
			{"up": "Space"},
			{"expect": {"state": "playing"}},
			{"shots": 4, "every": 600, "name": "rajada-longa", "moving": true},
		]
	}
	var estouros := _estouros_do_spec("roteiro-x", spec)
	assert_eq(estouros.size(), 1, "a rajada de 1950 ms deve estourar o orcamento")
	assert_true(estouros[0].begins_with("roteiro-x/rajada-longa:"), "a falha deve citar roteiro e nome da rajada")


func _spec_sintetico(rajada: Dictionary, extra: Dictionary = {}) -> Dictionary:
	var spec: Dictionary = extra.duplicate()
	spec["steps"] = [
		{"down": "Space"},
		{"wait": 150},
		{"up": "Space"},
		{"expect": {"state": "playing"}},
		rajada,
	]
	return spec


func test_rajada_moving_com_menos_shots_que_freeze_nao_entra_no_orcamento() -> void:
	var curta := _spec_sintetico({"shots": 3, "every": 800, "name": "curta", "moving": true})
	assert_eq(_estouros_do_spec("s", curta).size(), 0, "rajada moving com 3 prints (< freeze 4) fica fora do orcamento mesmo acima de 1500 ms")
	var no_limite := _spec_sintetico({"shots": 4, "every": 500, "name": "limite", "moving": true})
	assert_eq(_estouros_do_spec("s", no_limite).size(), 1, "rajada moving com 4 prints (== freeze) entra no orcamento e estoura")


func test_freeze_shots_do_spec_com_fallback_4_e_moving_false_ignorada() -> void:
	var com_chave := _spec_sintetico({"shots": 2, "every": 1600, "name": "dois", "moving": true}, {"freeze_shots": 2})
	assert_eq(_estouros_do_spec("s", com_chave).size(), 1, "com freeze_shots 2 a rajada de 2 prints entra no orcamento")
	var sem_3 := _spec_sintetico({"shots": 3, "every": 800, "name": "tres", "moving": true})
	assert_eq(_estouros_do_spec("s", sem_3).size(), 0, "sem a chave o fallback e 4: 3 prints fica fora")
	var sem_4 := _spec_sintetico({"shots": 4, "every": 500, "name": "quatro", "moving": true})
	assert_eq(_estouros_do_spec("s", sem_4).size(), 1, "sem a chave o fallback e 4: 4 prints entra")
	var invalido_3 := _spec_sintetico({"shots": 3, "every": 800, "name": "tres", "moving": true}, {"freeze_shots": 1})
	assert_eq(_estouros_do_spec("s", invalido_3).size(), 0, "freeze_shots 1 nao e valido (so inteiro > 1): fallback 4, 3 prints fica fora")
	var invalido_4 := _spec_sintetico({"shots": 4, "every": 500, "name": "quatro", "moving": true}, {"freeze_shots": 1})
	assert_eq(_estouros_do_spec("s", invalido_4).size(), 1, "freeze_shots 1 nao e valido: fallback 4, 4 prints entra")
	var fracionario := _spec_sintetico({"shots": 3, "every": 800, "name": "tres", "moving": true}, {"freeze_shots": 2.5})
	assert_eq(_estouros_do_spec("s", fracionario).size(), 0, "freeze_shots 2.5 nao e inteiro: fallback 4, 3 prints fica fora")
	var texto := _spec_sintetico({"shots": 3, "every": 800, "name": "tres", "moving": true}, {"freeze_shots": "2"})
	assert_eq(_estouros_do_spec("s", texto).size(), 0, "freeze_shots \"2\" (texto) nao e numero: fallback 4, 3 prints fica fora")
	var parada := _spec_sintetico({"shots": 8, "every": 400, "name": "queda", "moving": false})
	assert_eq(_estouros_do_spec("s", parada).size(), 0, "rajada moving false e ignorada em qualquer tamanho")


func test_orcamento_reinicia_por_partida() -> void:
	var longo: Array[String] = _estouros_de_orcamento("gecko")
	assert_eq(longo.size(), 0, "o roteiro real gecko deve caber no orcamento (partida 2 medida desde o seu Play)")
	var spec := _carregar("gecko")
	var passos: Array = spec["steps"]
	var inicios: int = 0
	for i in passos.size():
		if _inicia_partida(passos, i):
			inicios += 1
	assert_gte(inicios, 2, "o gecko tem ao menos 2 partidas, cada uma com o seu proprio Play")


func _indice_expect(nome: String, chave: String, operador: String) -> int:
	var passos := _passos(nome)
	for i in passos.size():
		if not passos[i].has("expect"):
			continue
		var valor: Variant = passos[i]["expect"].get(chave, null)
		if typeof(valor) == TYPE_DICTIONARY and valor.has(operador):
			return i
	return -1


func test_roteiro_estagio_prova_a_subida_com_seed_progresso_e_termina_vivo() -> void:
	_checar_roteiro_com_seed("estagio")
	var caminho: String = str(_carregar("estagio").get("path", ""))
	assert_true("seed=464" in caminho, "o roteiro estagio usa a seed da propria feature")
	assert_true("semderrota=1" in caminho, "o roteiro estagio liga semderrota")
	assert_true("progresso=" in caminho, "o roteiro estagio passa progresso=")
	assert_true("tutorial=visto" in caminho, "o roteiro estagio pula o tutorial")
	var i_eq0: int = _indice_expect("estagio", "dificuldade.estagio", "eq")
	var i_gte1: int = _indice_expect("estagio", "dificuldade.estagio", "gte")
	assert_gte(i_eq0, 0, "deve haver expect dificuldade.estagio eq 0")
	assert_gt(i_gte1, i_eq0, "expect estagio gte 1 vem depois do eq 0")
	var passos := _passos("estagio")
	assert_eq(passos[i_eq0]["expect"]["dificuldade.estagio"]["eq"], 0.0, "o eq e contra o estagio 0")
	assert_eq(passos[i_gte1]["expect"]["dificuldade.estagio"]["gte"], 1.0, "o gte e contra o estagio 1")
	assert_gte(int(passos[i_gte1].get("timeout_ms", 0)), 8000, "o gte 1 espera ao menos 8 s")
	var ultimo: Dictionary = passos[passos.size() - 1]
	assert_eq(ultimo.get("expect", {}), {"state": "playing"}, "o roteiro estagio termina com expect state playing")


func test_so_retrato_pontua_liga_semderrota_pontua_e_termina_vivo() -> void:
	var nome_pontua: String = "retrato-pontua-1080x2772"
	var passos := _passos(nome_pontua)
	var tem_score_gte_1: bool = false
	for passo in _expects(nome_pontua):
		var exigencia: Dictionary = passo["expect"]
		var score: Variant = exigencia.get("score", null)
		if typeof(score) == TYPE_DICTIONARY and score.has("gte") and float(score["gte"]) == 1.0:
			tem_score_gte_1 = true
	assert_eq(tem_score_gte_1, true, "o roteiro pontua deve ter expect score gte 1")
	var ultimo: Dictionary = passos[passos.size() - 1]
	assert_eq(ultimo.get("expect", {}), {"state": "playing"}, "o roteiro pontua deve terminar com expect state playing (gecko vivo)")
	for nome in ROTEIROS:
		var caminho: String = str(_carregar(nome).get("path", ""))
		assert_eq("semderrota" in caminho, ROTEIROS_SEMDERROTA.has(nome), "semderrota so nos roteiros da lista explicita (pontua, estagio e longos)")
