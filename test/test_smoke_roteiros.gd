extends GutTest

# Validacao estatica dos roteiros de smoke (test/smoke/*.smoke.json): seed no path, passos `expect` e contrato do
# runner (chaves publicadas pela ponte GameState, operadores eq/ne/gt/gte/lt/lte) e orcamento de tempo das rajadas
# `moving: true` desde o Play (issue #40). Nao sobe export nem navegador.

const PASTA: String = "res://test/smoke/"
const ROTEIROS: Array[String] = [
	"camaleao",
	"camera-cruza-limite",
	"desacelera",
	"dica-toque",
	"estagio",
	"estagio-alto",
	"gecko",
	"janela-larga-1280x720",
	"power-up",
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
const CHAVES_PUBLICADAS: Array[String] = ["score", "best", "state", "player.alive", "player.x", "player.y", "dificuldade.estagio", "powerup.ativo", "powerup.restante", "powerup.carga", "modo", "relogio.restante", "alvo.alinhado", "alvo.dx"]
# Roteiros dos modos de jogo (seletor, Puro, Contra o tempo, Diario): fora de ROTEIROS porque o do Tempo espera `lost`
# pelo relogio e o do Diario espera `lost` pela queda do dia.
const ROTEIROS_MODOS: Array[String] = ["modos", "modo-puro", "modo-tempo", "modo-zen", "modo-diario"]
const ROTEIROS_SEMDERROTA: Array[String] = [
	"camaleao",
	"desacelera",
	"retrato-pontua-1080x2772",
	"estagio",
	"estagio-alto",
	"gecko",
	"power-up",
	"retrato-1080x2400",
	"retrato-1080x2772",
	"retrato-1170x2532",
	"retrato-720x1280",
]
const OPERADORES: Array[String] = ["eq", "ne", "gt", "gte", "lt", "lte"]
# Power-ups reais do registro de producao (ADR 0014); o roteiro de cada um passa `?powerup=<nome>` (so-debug).
const POWERUPS_REAIS: Array[String] = ["camaleao", "desacelera"]
# Duracao temporizada de Camaleao e Desacelera (ADR 0014: 5 s de tempo de jogo).
const DURACAO_POWERUP_MS: int = 5000
const TIMEOUT_MIN_APOS_QUEDA_MS: int = 3000
# Orcamento do tempo nominal (wait + (shots-1)*every) do Play ate o ultimo print de uma rajada moving true: a recarga
# pos-derrota so ocorre ~2,3 s depois do Play; 1,5 s deixa folga para a sobrecarga do screenshot (issue #40).
const ORCAMENTO_RAJADA_MOVING_MS: int = 1500
const FREEZE_SHOTS_PADRAO: int = 4
# Periodo de uma cor da cicladora (PlatformColorCycle, 3 s): o roteiro estagio-alto espera mais que isso entre os prints.
const TROCA_COR_MS: int = 3000


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


# State do 1o `expect` depois do passo `i` (pulando so `wait`/`up`); null quando nao ha expect direto — serve para
# conferir que uma acao bloqueada (clique no Play desabilitado, `jump` no menu com o dia gasto) mantem o estado.
func _estado_do_proximo_expect(passos: Array, i: int) -> Variant:
	var j: int = i + 1
	while j < passos.size() and (passos[j].has("wait") or passos[j].has("up")):
		j += 1
	if j >= passos.size() or not passos[j].has("expect"):
		return null
	return passos[j]["expect"].get("state", null)


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


func test_semderrota_so_na_lista_explicita_e_pontua_termina_vivo() -> void:
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


func test_estagio_alto_prova_estagio_3_com_progresso_1_e_semderrota() -> void:
	var nome: String = "estagio-alto"
	_checar_roteiro_com_seed(nome)
	var caminho: String = str(_carregar(nome).get("path", ""))
	assert_true("progresso=1.0" in caminho, "o roteiro estagio-alto passa progresso=1.0 (estagio mais alto)")
	assert_true("semderrota=1" in caminho, "o roteiro estagio-alto liga semderrota")
	assert_true(ROTEIROS.has(nome), "o roteiro estagio-alto deve estar em ROTEIROS")
	assert_true(ROTEIROS_SEMDERROTA.has(nome), "o roteiro estagio-alto deve estar em ROTEIROS_SEMDERROTA")
	var i_gte3: int = _indice_expect(nome, "dificuldade.estagio", "gte")
	assert_gte(i_gte3, 0, "deve haver expect dificuldade.estagio gte")
	var passos := _passos(nome)
	assert_eq(passos[i_gte3]["expect"]["dificuldade.estagio"]["gte"], 3.0, "o gte e contra o estagio 3")
	assert_gte(int(passos[i_gte3].get("timeout_ms", 0)), TIMEOUT_MIN_APOS_QUEDA_MS, "o expect do estagio 3 deve ter timeout_ms >= 3000")
	var i_antes: int = _indice_shots(nome, "antes-troca")
	var i_depois: int = _indice_shots(nome, "depois-troca")
	assert_gte(i_antes, 0, "o roteiro estagio-alto tira o print antes-troca")
	assert_gt(i_depois, i_antes, "o print depois-troca vem depois do antes-troca")
	# O formato do smoke nao tem OU: a partida pode acabar por queda nos 3,3 s, entao nenhum expect de state depois do antes-troca
	if i_antes >= 0:
		for i in range(i_antes + 1, passos.size()):
			var exigencia: Dictionary = passos[i].get("expect", {})
			assert_false(exigencia.has("state"), "passo %d: sem expect state depois do antes-troca (aceita playing ou queda)" % i)
	var espera_ms: int = 0
	for i in range(maxi(i_antes + 1, 0), maxi(i_depois, 0)):
		if passos[i].has("wait"):
			espera_ms += int(passos[i]["wait"])
	assert_gt(espera_ms, TROCA_COR_MS, "entre antes-troca e depois-troca ha mais de 3 s (um periodo de cor da cicladora)")


func test_power_up_parseia_usa_powerup_teste_e_so_chaves_publicadas() -> void:
	var nome: String = "power-up"
	_checar_roteiro_com_seed(nome)
	var caminho: String = str(_carregar(nome).get("path", ""))
	assert_true("powerup=teste" in caminho, "o roteiro power-up passa powerup=teste")
	assert_true("semderrota=1" in caminho, "o roteiro power-up liga semderrota")
	assert_true("tutorial=visto" in caminho, "o roteiro power-up pula o tutorial")
	assert_true(CHAVES_PUBLICADAS.has("powerup.ativo"), "powerup.ativo e chave publicada")
	assert_true(CHAVES_PUBLICADAS.has("powerup.restante"), "powerup.restante e chave publicada")
	assert_true(CHAVES_PUBLICADAS.has("powerup.carga"), "powerup.carga e chave publicada")
	var chaves_powerup: int = 0
	for passo in _expects(nome):
		for chave in passo["expect"].keys():
			assert_true(CHAVES_PUBLICADAS.has(str(chave)), "chave do expect publicada pela ponte: %s" % str(chave))
			if str(chave).begins_with("powerup."):
				chaves_powerup += 1
	assert_gt(chaves_powerup, 0, "o roteiro power-up confere a ponte do powerup")


func _indice_shots(nome: String, rotulo: String) -> int:
	var passos := _passos(nome)
	for i in passos.size():
		if str(passos[i].get("name", "")) == rotulo:
			return i
	return -1


# Valor de `powerup=` do path (ate o proximo `&`); vazio quando o path nao traz o parametro.
func _nome_powerup(caminho: String) -> String:
	var idx: int = caminho.find("powerup=")
	if idx < 0:
		return ""
	var resto: String = caminho.substr(idx + "powerup=".length())
	var fim: int = resto.find("&")
	if fim < 0:
		return resto
	return resto.substr(0, fim)


# Valor inteiro de `<chave>=` do path (ate o proximo `&`); -1 quando ausente, vazia ou nao inteira.
func _valor_query_int(caminho: String, chave: String) -> int:
	var busca: String = chave + "="
	var idx: int = caminho.find(busca)
	if idx < 0:
		return -1
	var resto: String = caminho.substr(idx + busca.length())
	var fim: int = resto.find("&")
	if fim >= 0:
		resto = resto.substr(0, fim)
	if not resto.is_valid_int():
		return -1
	return resto.to_int()


func test_camaleao_e_desacelera_parseiam_com_seed_e_powerup_real() -> void:
	for nome in ["camaleao", "desacelera"]:
		_checar_roteiro_com_seed(nome)
		var caminho: String = str(_carregar(nome).get("path", ""))
		assert_true(POWERUPS_REAIS.has(_nome_powerup(caminho)), "?powerup= deve ser um power-up real (camaleao ou desacelera)")
		assert_eq(_nome_powerup(caminho), nome, "?powerup= deve ser o proprio nome do roteiro")


func test_roteiro_powerup_real_ativa_com_o_nome_e_expira_dentro_da_duracao() -> void:
	for nome in ["camaleao", "desacelera"]:
		var passos := _passos(nome)
		var i_ativo: int = -1
		var i_expira: int = -1
		for i in passos.size():
			if not passos[i].has("expect"):
				continue
			var exigencia: Dictionary = passos[i]["expect"]
			if i_ativo < 0 and exigencia.get("powerup.ativo", null) == nome:
				i_ativo = i
			elif i_ativo >= 0 and i_expira < 0 and exigencia.get("powerup.ativo", null) == "":
				i_expira = i
		assert_gte(i_ativo, 0, "%s: deve haver expect powerup.ativo igual ao nome do power-up" % nome)
		assert_gt(i_expira, i_ativo, "%s: deve haver expect powerup.ativo vazio depois da ativacao" % nome)
		if i_ativo >= 0:
			var restante: Variant = passos[i_ativo]["expect"].get("powerup.restante", null)
			assert_true(typeof(restante) == TYPE_DICTIONARY and restante.has("gt"), "%s: a ativacao confere powerup.restante gt 0" % nome)
		if i_expira >= 0:
			assert_gte(int(passos[i_expira].get("timeout_ms", 0)), DURACAO_POWERUP_MS, "%s: a expiracao deve ter timeout_ms >= a duracao de 5 s" % nome)


func _valores_expect(nome: String, chave: String) -> Array:
	var out: Array = []
	for passo in _expects(nome):
		if passo["expect"].has(chave):
			out.append(passo["expect"][chave])
	return out


func test_roteiros_dos_modos_parseiam_com_seed_tutorial_e_so_chaves_publicadas() -> void:
	for nome in ROTEIROS_MODOS:
		_checar_roteiro_com_seed(nome)
		var caminho: String = str(_carregar(nome).get("path", ""))
		assert_true("tutorial=visto" in caminho, "%s: o roteiro pula o tutorial" % nome)
		assert_gt(_expects(nome).size(), 0, "%s: deve ter ao menos um passo expect" % nome)
		for passo in _expects(nome):
			assert_gte(int(passo.get("timeout_ms", 0)), TIMEOUT_MIN_APOS_QUEDA_MS, "%s: todo expect deve ter timeout_ms >= 3000" % nome)
			for chave in passo["expect"].keys():
				assert_true(CHAVES_PUBLICADAS.has(str(chave)), "%s: chave do expect publicada pela ponte: %s" % [nome, str(chave)])
				var valor: Variant = passo["expect"][chave]
				if typeof(valor) == TYPE_DICTIONARY:
					assert_eq(valor.size(), 1, "%s: o objeto de comparacao tem um operador" % nome)
					for operador in valor.keys():
						assert_true(OPERADORES.has(str(operador)), "%s: operador eq/ne/gt/gte/lt/lte" % nome)


func test_modos_smoke_cicla_classico_puro_tempo_zen_teste_e_volta() -> void:
	var caminho: String = str(_carregar("modos").get("path", ""))
	assert_true("modos=teste" in caminho, "o roteiro dos modos liga a lista com teste")
	var ids: Array = []
	for passo in _expects("modos"):
		var exigencia: Dictionary = passo["expect"]
		if exigencia.get("state", "") == "menu" and exigencia.has("modo") and (ids.is_empty() or ids[ids.size() - 1] != exigencia["modo"]):
			ids.append(exigencia["modo"])
	var esperados: Array = []
	for modo in GameModes.lista(true):
		esperados.append(String(modo.id))
	esperados.append(esperados[0])
	assert_eq(ids, esperados, "C716: o roteiro percorre a lista de debug (classico -> puro -> tempo -> zen -> diario -> teste) e volta ao primeiro")
	assert_eq(ids, ["classico", "puro", "tempo", "zen", "diario", "teste", "classico"], "C716: ordem literal do roteiro de modos")
	# o registro cicla igual nas duas direcoes (seta direita e esquerda) com a lista de debug
	var lista: Array[GameMode] = GameModes.lista(true)
	var modo: GameMode = lista[0]
	var vistos: Array = []
	for i in lista.size() + 1:
		vistos.append(String(modo.id))
		modo = GameModes.proximo(modo, lista)
	assert_eq(vistos, ["classico", "puro", "tempo", "zen", "diario", "teste", "classico"], "seta direita: classico -> puro -> tempo -> zen -> diario -> teste -> classico")
	var voltando: Array = []
	modo = lista[0]
	for i in lista.size() + 1:
		voltando.append(String(modo.id))
		modo = GameModes.anterior(modo, lista)
	assert_eq(voltando, ["classico", "teste", "diario", "zen", "tempo", "puro", "classico"], "seta esquerda: classico -> teste -> diario -> zen -> tempo -> puro -> classico")


func test_roteiro_puro_joga_com_modo_puro_e_powerup_vazio() -> void:
	var nome: String = "modo-puro"
	var caminho: String = str(_carregar(nome).get("path", ""))
	assert_true("progresso=" in caminho, "o roteiro puro adianta o progresso (raridade de power-up alta)")
	assert_true("semderrota=1" in caminho, "o roteiro puro liga semderrota")
	assert_true(_valores_expect(nome, "modo").has("puro"), "o roteiro confere modo puro")
	var vazios: int = 0
	for valor in _valores_expect(nome, "powerup.ativo"):
		assert_eq(valor, "", "no Puro powerup.ativo so e esperado vazio")
		vazios += 1
	assert_gt(vazios, 0, "o roteiro puro confere powerup.ativo vazio")


func test_roteiro_zen_joga_sem_derrota_cai_e_sai_pela_pausa_ao_menu() -> void:
	var nome: String = "modo-zen"
	assert_true(ROTEIROS_MODOS.has(nome), "C740: o roteiro zen esta em ROTEIROS_MODOS")
	var caminho: String = str(_carregar(nome).get("path", ""))
	assert_true("progresso=" in caminho, "o roteiro zen adianta o progresso")
	assert_true(_valores_expect(nome, "modo").has("zen"), "o roteiro confere modo zen")
	var vazios: int = 0
	for valor in _valores_expect(nome, "powerup.ativo"):
		assert_eq(valor, "", "no Zen powerup.ativo so e esperado vazio")
		vazios += 1
	assert_gt(vazios, 0, "o roteiro zen confere powerup.ativo vazio")
	var passos := _passos(nome)
	var i_queda: int = -1
	for i in passos.size():
		if passos[i].get("down", "") == "ArrowLeft" or passos[i].get("down", "") == "ArrowRight":
			i_queda = i
			break
	assert_gte(i_queda, 0, "a queda proposital usa down de seta (sem gesto)")
	assert_true(passos[i_queda + 2].has("up"), "a seta e solta depois do wait")
	var i_pos_queda: int = -1
	for i in range(i_queda + 3, passos.size()):
		if passos[i].has("expect"):
			i_pos_queda = i
			break
	assert_gte(i_pos_queda, 0, "ha expect depois da queda")
	assert_eq(passos[i_pos_queda]["expect"].get("state", null), "playing", "depois da queda o Zen segue playing")
	var i_escape: int = -1
	for i in range(i_pos_queda, passos.size()):
		if passos[i].get("down", "") == "Escape":
			i_escape = i
			break
	assert_gte(i_escape, 0, "a pausa abre pela tecla da acao pause")
	var ultimo: Dictionary = passos[passos.size() - 1]
	var ultimo_expect: Dictionary = {}
	for i in range(passos.size() - 1, i_escape, -1):
		if passos[i].has("expect"):
			ultimo_expect = passos[i]["expect"]
			break
	assert_eq(ultimo_expect.get("state", null), "menu", "depois de Sair a ponte volta a state menu")
	assert_eq(ultimo_expect.get("modo", null), "zen", "e o modo segue zen")
	assert_true(ultimo.has("shots"), "o roteiro termina com o print do menu")


func test_roteiro_tempo_usa_tempo_curto_e_termina_em_lost_com_gecko_vivo() -> void:
	var nome: String = "modo-tempo"
	var caminho: String = str(_carregar(nome).get("path", ""))
	var idx: int = caminho.find("tempo=")
	assert_gte(idx, 0, "o roteiro tempo passa ?tempo=<s>")
	var resto: String = caminho.substr(idx + "tempo=".length())
	var fim: int = resto.find("&")
	var segundos: String = resto if fim < 0 else resto.substr(0, fim)
	assert_true(segundos.is_valid_float() and segundos.to_float() > 0.0 and segundos.to_float() <= 10.0, "o ?tempo= e um relogio curto (1 a 10 s)")
	assert_true("semderrota=1" in caminho, "sem derrota por queda: so o relogio encerra a partida")
	assert_true(_valores_expect(nome, "modo").has("tempo"), "o roteiro confere modo tempo")
	var i_playing: int = -1
	var i_lost: int = -1
	var passos := _passos(nome)
	for i in passos.size():
		if not passos[i].has("expect"):
			continue
		var exigencia: Dictionary = passos[i]["expect"]
		if i_playing < 0 and exigencia.get("state", "") == "playing" and exigencia.has("relogio.restante"):
			i_playing = i
		elif i_playing >= 0 and i_lost < 0 and exigencia.get("state", "") == "lost":
			i_lost = i
	assert_gte(i_playing, 0, "deve haver expect playing com relogio.restante")
	assert_gt(i_lost, i_playing, "o expect lost vem depois do playing")
	if i_lost >= 0:
		assert_false(passos[i_lost]["expect"].has("player.alive"), "a ponte publica alive=false em todo lost: o roteiro nao le player.alive no lost")
		assert_true(_valores_expect(nome, "relogio.restante").size() >= 2, "o fim por relogio e provado por relogio.restante (gt 0 no playing, eq 0 depois)")
		assert_gte(int(passos[i_lost].get("timeout_ms", 0)), int(segundos.to_float() * 1000.0), "o timeout do lost cobre o relogio curto")


func test_roteiro_diario_valida_passos_e_seletor_com_6_entradas() -> void:
	var nome: String = "modo-diario"
	assert_true(ROTEIROS_MODOS.has(nome), "C793: o roteiro do Diario esta registrado em ROTEIROS_MODOS")
	var spec := _carregar(nome)
	assert_gt(spec.size(), 0, "o roteiro do Diario existe e parseia como objeto JSON")
	var caminho: String = str(spec.get("path", ""))
	assert_true("modos=teste" in caminho, "o roteiro do Diario liga a lista de debug (modos=teste)")
	assert_true("progresso=1.0" in caminho, "o roteiro joga com progresso 1.0 (raridade maxima) para provar que nenhum power-up nasce")
	var dia: int = _valor_query_int(caminho, "dia")
	assert_true(dia >= 0 and dia <= SeedSource.MAX_SEED, "o ?dia= e um inteiro na faixa 0..MAX_SEED (ModoDiaInicial)")
	# C793: o seletor de debug tem 6 entradas e o Diario e o 5o (depois do Zen, antes do teste): as setas do roteiro
	# batem com a posicao no registro — e o ciclo do modos.smoke.json percorre essas mesmas 6 entradas.
	var lista_debug: Array[GameMode] = GameModes.lista(true)
	assert_eq(lista_debug.size(), 6, "C793: a lista de debug tem 6 entradas (classico, puro, tempo, zen, diario, teste)")
	var indice_diario: int = -1
	for i in lista_debug.size():
		if String(lista_debug[i].id) == "diario":
			indice_diario = i
	assert_eq(indice_diario, 4, "o Diario e o 5o modo da lista de debug")
	var passos := _passos(nome)
	var setas: int = 0
	var fechou_seletor: bool = false
	for passo in passos:
		if fechou_seletor:
			break
		if not passo.has("click"):
			continue
		if passo["click"] == [328.0, 240.0]:
			setas += 1
		elif passo["click"] == [180.0, 518.0]:
			fechou_seletor = true
	assert_true(fechou_seletor, "a selecao fecha com o OK do seletor")
	assert_eq(setas, indice_diario, "as setas ate o Diario batem com a sua posicao no seletor (4 a partir do classico)")
	# modos.smoke.json percorre as 6 entradas: 6 confirmacoes (OK) e a ponte passa por cada id da lista de debug
	var oks: int = 0
	for passo in _passos("modos"):
		if passo.has("click") and passo["click"] == [180.0, 518.0]:
			oks += 1
	assert_eq(oks, 6, "C793: modos.smoke.json confirma o seletor 6 vezes (uma por entrada da lista de debug)")
	var ids_modos: Array = _valores_expect("modos", "modo")
	for modo_debug in lista_debug:
		assert_true(ids_modos.has(String(modo_debug.id)), "C793: modos.smoke.json confere o modo %s pela ponte" % modo_debug.id)
	# a partida do dia: ponte modo diario, powerup.ativo vazio, playing -> lost -> menu com o dia gasto
	assert_true(_valores_expect(nome, "modo").has("diario"), "o roteiro confere o modo diario pela ponte")
	var vazios: int = 0
	for valor in _valores_expect(nome, "powerup.ativo"):
		assert_eq(valor, "", "no Diario powerup.ativo so e esperado vazio (nenhum icone nasce)")
		vazios += 1
	assert_gt(vazios, 0, "o roteiro confere powerup.ativo vazio com progresso 1.0")
	var i_playing: int = -1
	var i_lost: int = -1
	var i_menu_depois: int = -1
	for i in passos.size():
		if not passos[i].has("expect"):
			continue
		var exigencia: Dictionary = passos[i]["expect"]
		if i_playing < 0 and exigencia.get("state", null) == "playing":
			i_playing = i
		elif i_playing >= 0 and i_lost < 0 and exigencia.get("state", null) == "lost":
			i_lost = i
		elif i_lost >= 0 and i_menu_depois < 0 and exigencia.get("state", null) == "menu":
			i_menu_depois = i
	assert_gte(i_playing, 0, "o roteiro prova o Play (state playing)")
	assert_gt(i_lost, i_playing, "a queda encerra a partida (lost depois do playing)")
	assert_gt(i_menu_depois, i_lost, "a derrota volta ao menu com o dia jogado")
	var inicio_menu: int = maxi(i_menu_depois, 0)
	# menu bloqueado: clicar no Play desabilitado mantem state menu
	var cliques_no_play: int = 0
	for i in range(inicio_menu, passos.size()):
		if not (passos[i].has("click") and passos[i]["click"] == [180.0, 324.0]):
			continue
		cliques_no_play += 1
		assert_eq(_estado_do_proximo_expect(passos, i), "menu", "clicar no Play desabilitado mantem state menu")
	assert_gte(cliques_no_play, 1, "o roteiro clica no botao Play desabilitado (centro logico (90,162) da Stage)")
	# o jump no menu bloqueado: um antes do reload e outro depois, ambos mantem state menu
	var i_primeiro_jump: int = -1
	var i_ultimo_jump: int = -1
	var i_reload: int = -1
	for i in range(inicio_menu, passos.size()):
		if passos[i].has("reload") and passos[i]["reload"] == true:
			i_reload = i
		if not (passos[i].has("down") and passos[i]["down"] == "Space"):
			continue
		if i_primeiro_jump < 0:
			i_primeiro_jump = i
		i_ultimo_jump = i
		assert_eq(_estado_do_proximo_expect(passos, i), "menu", "o jump no menu com o dia jogado mantem state menu")
	assert_lt(i_primeiro_jump, i_ultimo_jump, "o roteiro da jump no menu bloqueado ao menos 2 vezes")
	assert_gte(i_reload, i_primeiro_jump, "o reload vem depois do 1o jump bloqueado")
	assert_lt(i_reload, i_ultimo_jump, "o ultimo jump bloqueado acontece depois do reload (dia jogado lido do disco)")
	# passos validos (contrato do game-smoke): cada passo declara exatamente uma acao do runner
	var acoes: Array[String] = ["down", "up", "press", "click", "tap", "hold", "drag", "touches", "wait", "shots", "expect", "reload", "blur", "hidden"]
	for i in passos.size():
		var declaradas: int = 0
		for acao in acoes:
			if passos[i].has(acao):
				declaradas += 1
		assert_eq(declaradas, 1, "o passo %d declara exatamente uma acao do runner" % i)


func test_nome_de_powerup_invalido_reprova() -> void:
	assert_false(POWERUPS_REAIS.has(_nome_powerup("index.html?seed=1&semderrota=1&powerup=fantasma")), "powerup fora da lista de power-ups reais reprova")
	assert_eq(_nome_powerup("index.html?seed=1&semderrota=1"), "", "path sem powerup= nao traz nome")
	assert_true(POWERUPS_REAIS.has(_nome_powerup("index.html?seed=1&powerup=camaleao&semderrota=1")), "powerup= no meio da query e lido ate o &")


func test_C804_chaves_publicadas_incluem_alvo_e_chave_inexistente_reprova() -> void:
	assert_true(CHAVES_PUBLICADAS.has("alvo.alinhado"), "C804: alvo.alinhado esta em CHAVES_PUBLICADAS")
	assert_true(CHAVES_PUBLICADAS.has("alvo.dx"), "C804: alvo.dx esta em CHAVES_PUBLICADAS")
	# a ponte de verdade publica cada chave alvo.* declarada (o teste cai se o montador deixar uma de fora)
	var publicado: Dictionary = GameState.build(0, 0, "menu", true)["alvo"] as Dictionary
	for chave in ["alinhado", "dx"]:
		assert_true(publicado.has(chave), "C804: GameState.build publica alvo.%s" % chave)
	# roteiro fake: expect com as chaves novas passa; chave que a ponte nao publica reprova
	var fake_ok: Dictionary = {"expect": {"alvo.alinhado": true, "alvo.dx": {"lt": 20}}}
	for chave in fake_ok["expect"].keys():
		assert_true(CHAVES_PUBLICADAS.has(str(chave)), "C804: chave do expect fake publicada: %s" % str(chave))
	var fake_ruim: Dictionary = {"expect": {"alvo.cor": true}}
	var reprovou: bool = false
	for chave in fake_ruim["expect"].keys():
		if not CHAVES_PUBLICADAS.has(str(chave)):
			reprovou = true
	assert_true(reprovou, "C804: chave inexistente (alvo.cor) reprova no teste estatico")


# f530 T5: corte de player.y em repouso apos cruzar o limite (medido na T1: antes 169-180, depois 145-152).
const CORTE_Y_CRUZOU: float = 160.0


func test_C810_camera_cruza_limite_esta_registrado_com_seed_e_regra_real() -> void:
	var nome: String = "camera-cruza-limite"
	assert_true(ROTEIROS.has(nome), "C810: o roteiro camera-cruza-limite esta em ROTEIROS")
	_checar_roteiro_com_seed(nome)
	var caminho: String = str(_carregar(nome).get("path", ""))
	assert_true("seed=472" in caminho, "C810: seed fixa na URL")
	assert_true("tutorial=visto" in caminho, "C810: pula o tutorial")
	assert_true("toque=b" in caminho, "C810: modo de toque B")
	assert_false("semderrota" in caminho, "C810: joga a regra real, sem semderrota (D2)")
	assert_false("powerup" in caminho, "C810: sem power-up (D4)")
	assert_false(ROTEIROS_SEMDERROTA.has(nome), "C810: nao esta na lista de roteiros sem derrota")


func test_C811_camera_cruza_limite_prova_alinhado_corte_e_termina_vivo() -> void:
	var nome: String = "camera-cruza-limite"
	var passos := _passos(nome)
	assert_gt(passos.size(), 0, "C811: o roteiro tem passos")
	for passo in _expects(nome):
		for chave in passo["expect"].keys():
			assert_true(CHAVES_PUBLICADAS.has(str(chave)), "C811: chave publicada pela ponte: %s" % str(chave))
			var valor: Variant = passo["expect"][chave]
			if typeof(valor) == TYPE_DICTIONARY:
				assert_eq(valor.size(), 1, "C811: um operador por comparacao")
				for operador in valor.keys():
					assert_true(OPERADORES.has(str(operador)), "C811: operador valido")
	var alinhados: int = 0
	for valor in _valores_expect(nome, "alvo.alinhado"):
		assert_eq(valor, true, "C811: alvo.alinhado so e esperado true")
		alinhados += 1
	assert_gte(alinhados, 4, "C811: varios pousos alinhados antes de cruzar o limite")
	var i_corte: int = _indice_expect(nome, "player.y", "lt")
	assert_gte(i_corte, 0, "C811: ha expect player.y lt <corte>")
	assert_eq(passos[i_corte]["expect"]["player.y"]["lt"], CORTE_Y_CRUZOU, "C811: o corte e o medido na T1 (repouso apos cruzar < 160)")
	var ultimo_expect: Dictionary = {}
	for i in range(passos.size() - 1, -1, -1):
		if passos[i].has("expect"):
			ultimo_expect = passos[i]["expect"]
			break
	assert_eq(ultimo_expect.get("player.y", null), {"gte": 0.0}, "C811: ao fim player.y gte 0")
	assert_eq(ultimo_expect.get("state", null), "playing", "C811: ao fim state playing")
	assert_eq(ultimo_expect.get("player.alive", null), true, "C811: ao fim player.alive true")


func test_C812_camera_cruza_limite_usa_retrato_720x1280_e_tem_shots_do_cruzamento() -> void:
	var nome: String = "camera-cruza-limite"
	var spec := _carregar(nome)
	assert_eq(spec.get("viewport", null), [720.0, 1280.0], "C812: viewport 720x1280 (altura logica 320, limite 128)")
	var i_corte: int = _indice_expect(nome, "player.y", "lt")
	var i_shots: int = _indice_shots(nome, "cruzou-limite")
	assert_gt(i_shots, i_corte, "C812: o print do cruzamento vem depois do expect do corte")
	assert_gt(_indice_shots(nome, "camera-cruza-fim"), i_shots, "C812: o print final vem depois do do cruzamento")
