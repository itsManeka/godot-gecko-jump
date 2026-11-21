extends GutTest

# f526 T3: escolha pura da plataforma de reaparicao da Segunda chance (SegundaChanceAlvo). Casos de escolha sem
# arvore — builders de entrada {y, x, cor, desmoronando, desmoronada, pisca_oculta[, movel]} em lista pura
# (C636-C647); C648 confere com Platform real as chaves que ReachableColors.entradas_de_plataformas passou a
# acrescentar. Regra (Q4 do G1): candidata visivel (y em [0, altura], x em [0, largura]), solida (nem desmoronada,
# nem desmoronando, nem oculta por piscar) e com tempo ate sair da tela >= janela minima (tempo de pulo pelo scroll
# + espera maxima do Player; scroll 0 = infinito); entre as da cor do gecko a de menor distancia euclidiana com dx
# ciente do wrap; sem nenhuma da cor, a mais proxima de qualquer cor como fallback (cor a assumir); empate exato
# por (distancia, y, x, cor); sem candidata = "nenhuma". Os argumentos nunca sao alterados.
# Correcao 1 (PASSO 6.5, achado C1 do game-review): o desempate por estatica vive DENTRO da faixa — havendo ao
# menos uma estatica ("movel" falso/ausente; chave ausente = estatica), so as estaticas sao consideradas; so faixa
# sem nenhuma estatica considera as moveis. Movel da cor do gecko nunca perde para estatica de outra cor.

const PlayerFisica := preload("res://scenes/Player.gd")
const PLATAFORMA_CENA := "res://scenes/Platform.tscn"
# Ciclo de piscar de producao do E3 (visivel 3,0 / invisivel 1,2 / aviso 0,6), como em test_cor_alcancavel_pisca.gd
const VISIVEL := 3.0
const INVISIVEL := 1.2
const AVISO := 0.6
const LARGURA := 180.0
const ALTURA := 320.0
# Ponto da queda: logo abaixo da borda visivel (a faixa de derrota fica abaixo de y = altura)
const GECKO := Vector2(90.0, 340.0)
const SCROLL := 20.0
const AZUL := Enums.COLOR.AZUL
const VERDE := Enums.COLOR.VERDE
const AMARELO := Enums.COLOR.AMARELO
const VERMELHO := Enums.COLOR.VERMELHO

var _cor_original: Enums.COLOR


func before_each() -> void:
	_cor_original = Global.cor_gecko
	Global.platforms = []
	Global.iniciado = false
	Global.sem_derrota = false


func after_each() -> void:
	Global.cor_gecko = _cor_original
	Global.platforms = []
	Global.iniciado = false
	Global.sem_derrota = false


func _rng(semente: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	return rng


func _entrada(
	y: float,
	x: float,
	cor: int,
	desmoronando: bool = false,
	desmoronada: bool = false,
	pisca_oculta: bool = false,
	movel: bool = false
) -> Dictionary:
	var entrada := {
		"y": y,
		"x": x,
		"cor": cor,
		"desmoronando": desmoronando,
		"desmoronada": desmoronada,
		"pisca_oculta": pisca_oculta,
	}
	# Chave "movel" so existe quando true: entradas montadas a mao sem a chave valem estatica (correcao 1).
	if movel:
		entrada["movel"] = true
	return entrada


# Teto de cada entrada: plataforma da mesma cor na linha de cima (predicado de saida, Q6 c), marcada desmoronada
# para nunca ser candidata. Acrescentada ao FIM da lista: os indices das entradas do teste nao mudam.
func _com_teto(entradas: Array) -> Array:
	var lista: Array = entradas.duplicate()
	for e in entradas:
		lista.append(_entrada(float(e["y"]) - InitialRows.ESPACAMENTO, 90.0, int(e["cor"]), false, true))
	return lista


func _escolher_cru(entradas: Array, cor_gecko: int = AZUL, scroll: float = 0.0, gecko: Vector2 = GECKO) -> Dictionary:
	return SegundaChanceAlvo.escolher(entradas, gecko, cor_gecko, LARGURA, ALTURA, scroll)


func _escolher(entradas: Array, cor_gecko: int = AZUL, scroll: float = 0.0, gecko: Vector2 = GECKO) -> Dictionary:
	return _escolher_cru(_com_teto(entradas), cor_gecko, scroll, gecko)


# Piscante com fase fixada, no padrao de test_cor_alcancavel_pisca.gd (fase 3,5 = invisivel no ciclo do E3).
func _blink(fase: float) -> PlatformBlink:
	var blink := PlatformBlink.new()
	blink.iniciar(_rng(3), VISIVEL, INVISIVEL, AVISO)
	blink.definir_fase(fase)
	return blink


# Plataforma real fora do fluxo da partida (sem fisica rodando): so o estado de nascimento interessa ao C648.
func _plataforma(cor: int, modificadores: Array) -> Platform:
	var p: Platform = load(PLATAFORMA_CENA).instantiate()
	p.set_color(cor)
	p.definir_modificadores(modificadores, DifficultySnapshot.new())
	p.position = Vector2(90.0, 150.0)
	add_child_autofree(p)
	return p


# --- C636: menor distancia euclidiana entre as da cor; outra cor mais proxima ignorada --------------------


func test_c636_entre_varias_da_cor_escolhe_a_de_menor_distancia_euclidiana_e_ignora_outra_cor_mais_proxima() -> void:
	var entradas: Array = [
		_entrada(100.0, 60.0, AZUL),
		_entrada(200.0, 120.0, AZUL),
		_entrada(310.0, 90.0, VERDE),
		_entrada(50.0, 10.0, VERDE),
	]
	var res: Dictionary = _escolher(entradas)
	assert_eq(int(res["indice"]), 1, "a AZUL de (120, 200) tem a menor distancia euclidiana ao ponto da queda")
	assert_eq(float(res["entrada"]["y"]), 200.0, "a escolhida e a entrada de y=200")
	assert_eq(float(res["entrada"]["x"]), 120.0, "a escolhida e a entrada de x=120")
	assert_eq(int(res["cor"]), AZUL, "a cor da escolhida e a cor do gecko")
	assert_false(bool(res["fallback"]), "havendo plataforma da cor na tela nao ha fallback")
	assert_lt(
		_distancia_do_gecko(entradas[2]),
		_distancia_do_gecko(res["entrada"]),
		"a VERDE de (90, 310) e mais proxima que a escolhida e foi ignorada por ser de outra cor"
	)


func _distancia_do_gecko(e: Dictionary) -> float:
	var dx: float = absf(float(e["x"]) - GECKO.x)
	var dy: float = float(e["y"]) - GECKO.y
	return sqrt(dx * dx + dy * dy)


# --- C637: fallback sem nenhuma da cor ---------------------------------------------------------------------


func test_c637_fallback_sem_nenhuma_da_cor_devolve_a_mais_proxima_de_qualquer_cor_com_a_cor_a_assumir() -> void:
	var entradas: Array = [
		_entrada(310.0, 90.0, VERDE),
		_entrada(100.0, 170.0, AMARELO),
	]
	var res: Dictionary = _escolher(entradas)
	assert_eq(int(res["indice"]), 0, "sem AZUL na tela, a mais proxima e a VERDE de (90, 310)")
	assert_eq(int(res["cor"]), VERDE, "a cor a assumir e a cor da plataforma escolhida")
	assert_true(bool(res["fallback"]), "fallback informado: a escolhida nao tem a cor do gecko")


# --- C638-C640: fora da tela --------------------------------------------------------------------------------


func test_c638_ignora_candidata_acima_da_tela_y_negativo() -> void:
	var so_fora: Dictionary = _escolher([_entrada(-1.0, 90.0, AZUL)])
	assert_eq(int(so_fora["indice"]), -1, "unica candidata acima da tela (y < 0): nenhuma")
	assert_null(so_fora["entrada"], "sem entrada escolhida")
	var mista: Array = [_entrada(-1.0, 90.0, AZUL), _entrada(0.0, 90.0, AZUL)]
	var res: Dictionary = _escolher(mista)
	assert_eq(int(res["indice"]), 1, "y < 0 fica de fora; y = 0 (topo da tela) e candidata")


func test_c639_ignora_candidata_abaixo_da_altura_visivel() -> void:
	var so_fora: Dictionary = _escolher([_entrada(ALTURA + 0.5, 90.0, AZUL)])
	assert_eq(int(so_fora["indice"]), -1, "unica candidata abaixo da altura visivel: nenhuma")
	var mista: Array = [_entrada(ALTURA + 0.5, 90.0, AZUL), _entrada(ALTURA, 90.0, AZUL)]
	var res: Dictionary = _escolher(mista)
	assert_eq(int(res["indice"]), 1, "y > altura fica de fora (a invalida e a mais proxima); y = altura e candidata")


func test_c640_ignora_candidata_fora_do_x_0_largura() -> void:
	var so_fora: Dictionary = _escolher([_entrada(200.0, -1.0, AZUL), _entrada(200.0, LARGURA + 1.0, AZUL)])
	assert_eq(int(so_fora["indice"]), -1, "so candidatas fora do x [0, largura]: nenhuma")
	var bordas: Array = [_entrada(200.0, 0.0, AZUL), _entrada(200.0, LARGURA, AZUL), _entrada(200.0, -1.0, AZUL)]
	var res: Dictionary = _escolher(bordas)
	assert_eq(
		int(res["indice"]),
		0,
		"x = 0 e x = largura entram e a fora do x fica de fora; no empate (mesma distancia e y) vence o menor x"
	)


# --- C641-C643: estados que fazem a plataforma nao servir de apoio ------------------------------------------


func test_c641_ignora_plataforma_desmoronada() -> void:
	var so_caida: Dictionary = _escolher([_entrada(310.0, 90.0, AZUL, false, true)])
	assert_eq(int(so_caida["indice"]), -1, "unica candidata desmoronada: nenhuma")
	var mista: Array = [_entrada(310.0, 90.0, AZUL, false, true), _entrada(200.0, 90.0, AZUL)]
	var res: Dictionary = _escolher(mista)
	assert_eq(int(res["indice"]), 1, "desmoronada fica de fora mesmo sendo a mais proxima")


func test_c642_ignora_plataforma_desmoronando() -> void:
	var so_caindo: Dictionary = _escolher([_entrada(310.0, 90.0, AZUL, true)])
	assert_eq(int(so_caindo["indice"]), -1, "unica candidata desmoronando: nenhuma")
	var mista: Array = [_entrada(310.0, 90.0, AZUL, true), _entrada(200.0, 90.0, AZUL)]
	var res: Dictionary = _escolher(mista)
	assert_eq(int(res["indice"]), 1, "desmoronando fica de fora mesmo sendo a mais proxima")


func test_c643_ignora_plataforma_com_piscar_oculto() -> void:
	var so_oculta: Dictionary = _escolher([_entrada(310.0, 90.0, AZUL, false, false, true)])
	assert_eq(int(so_oculta["indice"]), -1, "unica candidata invisivel por piscar: nenhuma")
	var mista: Array = [_entrada(310.0, 90.0, AZUL, false, false, true), _entrada(200.0, 90.0, AZUL)]
	var res: Dictionary = _escolher(mista)
	assert_eq(int(res["indice"]), 1, "piscar oculto fica de fora mesmo sendo a mais proxima")


# --- C644: filtro de tempo ate sair da tela -------------------------------------------------------------------


func test_c644_descarta_a_mais_proxima_com_tempo_ate_sair_abaixo_da_janela_minima_em_favor_da_mais_distante() -> void:
	var janela: float = ReachableColors.tempo_de_pulo(SCROLL) + PlayerFisica.ESPERA_MAXIMA_S
	# A mais proxima sai da tela em (janela - 0,1) s, abaixo da janela minima; a mais distante sobrevive a ela.
	var perto: Dictionary = _entrada(ALTURA - (janela - 0.1) * SCROLL, 90.0, AZUL)
	var longe: Dictionary = _entrada(ALTURA - (janela + 0.1) * SCROLL, 90.0, AZUL)
	var res: Dictionary = _escolher([perto, longe], AZUL, SCROLL)
	assert_eq(int(res["indice"]), 1, "a mais proxima sai antes da janela minima: a mais distante vence")
	assert_eq(res["entrada"], longe, "a escolhida e a que ainda fica na tela tempo suficiente")
	# Scroll 0 = tempo infinito: sem descarte (e sem divisao por zero), a mais proxima vence de volta.
	var sem_scroll: Dictionary = _escolher([perto, longe], AZUL, 0.0)
	assert_eq(int(sem_scroll["indice"]), 0, "scroll 0 nao descarta ninguem: a mais proxima vence")


# --- C645: distancia horizontal com wrap ----------------------------------------------------------------------


func test_c645_distancia_horizontal_com_wrap_gecko_perto_de_0_e_plataforma_perto_da_largura_vence() -> void:
	var entradas: Array = [
		_entrada(200.0, 50.0, AZUL),
		_entrada(200.0, LARGURA - 1.0, AZUL),
	]
	var res: Dictionary = _escolher(entradas, AZUL, 0.0, Vector2(1.0, 300.0))
	assert_eq(
		int(res["indice"]),
		1,
		"gecko em x~0 contra x~180: dx com wrap (LARGURA - |dx|) = 2 vence o dx cru de 49 da outra candidata"
	)


# --- C646: empate exato de distancia ----------------------------------------------------------------------------


func test_c646_empate_exato_de_distancia_menor_y_vence_depois_menor_x_e_o_resultado_repete_com_a_lista_embaralhada() -> void:
	# Empate exato (distancias 100,0 = pitagorica 0/100 contra 60/80) em relacao ao gecko (90, 300).
	var a: Dictionary = _entrada(200.0, 90.0, AZUL)
	var b: Dictionary = _entrada(220.0, 30.0, AZUL)
	var res_y: Dictionary = _escolher([b, a], AZUL, 0.0, Vector2(90.0, 300.0))
	assert_eq(int(res_y["indice"]), 1, "empate exato de distancia: menor y (200) vence o y maior (220)")
	# Empate com o mesmo y (distancias iguais, y 200): menor x vence.
	var c: Dictionary = _entrada(200.0, 60.0, AZUL)
	var d: Dictionary = _entrada(200.0, 120.0, AZUL)
	var res_x: Dictionary = _escolher([d, c], AZUL, 0.0, Vector2(90.0, 300.0))
	assert_eq(int(res_x["indice"]), 1, "empate com o mesmo y: menor x (60) vence")
	# A escolha nao depende da ordem da lista: embaralhada, o resultado e identico.
	var lista: Array = [a, b, c, d]
	var primeira: Dictionary = _escolher(lista, AZUL, 0.0, Vector2(90.0, 300.0))
	seed(20261120)
	lista.shuffle()
	var segunda: Dictionary = _escolher(lista, AZUL, 0.0, Vector2(90.0, 300.0))
	seed(20261121)
	lista.shuffle()
	var terceira: Dictionary = _escolher(lista, AZUL, 0.0, Vector2(90.0, 300.0))
	assert_eq(segunda["entrada"], primeira["entrada"], "lista embaralhada devolve a mesma entrada")
	assert_eq(terceira["entrada"], primeira["entrada"], "embaralhada de novo, a mesma entrada")
	assert_eq(float(primeira["entrada"]["y"]), 200.0, "o vencedor e o do empate de menor distancia (y=200)")


# --- C647: nenhuma sem erro e argumentos intactos ----------------------------------------------------------------


func test_c647_lista_vazia_ou_so_com_invalidas_devolve_nenhuma_sem_erro_e_sem_alterar_os_argumentos() -> void:
	var vazio: Dictionary = _escolher([])
	assert_eq(int(vazio["indice"]), -1, "lista vazia: nenhuma")
	assert_null(vazio["entrada"], "sem entrada escolhida")
	assert_eq(int(vazio["cor"]), -1, "sem cor a assumir")
	var invalidas: Array = _com_teto(
		[
			_entrada(-1.0, 90.0, AZUL),
			_entrada(ALTURA + 1.0, 90.0, AZUL),
			_entrada(200.0, -1.0, AZUL),
			_entrada(200.0, LARGURA + 1.0, AZUL),
			_entrada(310.0, 90.0, AZUL, true),
			_entrada(310.0, 90.0, AZUL, false, true),
			_entrada(310.0, 90.0, AZUL, false, false, true),
		]
	)
	var antes: Array = invalidas.duplicate(true)
	var so_invalidas: Dictionary = _escolher_cru(invalidas, AZUL, SCROLL)
	assert_eq(int(so_invalidas["indice"]), -1, "so candidatas invalidas: nenhuma, sem erro")
	assert_eq(invalidas, antes, "a lista de entradas nao foi alterada")
	var mista: Array = _com_teto([_entrada(200.0, 90.0, VERDE), _entrada(310.0, 90.0, AZUL, true)])
	var antes_mista: Array = mista.duplicate(true)
	var res: Dictionary = _escolher_cru(mista)
	assert_eq(int(res["indice"]), 0, "a candidata valida entra no lugar da invalida")
	assert_eq(mista, antes_mista, "escolher nao altera a lista nem os dicionarios dela")


# --- Saida do reaparecimento (Q6 c): a candidata precisa da cor dela na linha de cima ---------------------------


func test_candidata_sem_a_cor_na_linha_de_cima_e_descartada_em_favor_de_outra_com_saida() -> void:
	var esp: float = InitialRows.ESPACAMENTO
	# A mais proxima (y=250) so tem VERDE acima; a mais distante (y=100) tem AZUL acima: so ela tem saida
	var entradas: Array = [
		_entrada(250.0, 90.0, AZUL),
		_entrada(250.0 - esp, 90.0, VERDE),
		_entrada(100.0, 90.0, AZUL),
		_entrada(100.0 - esp, 90.0, AZUL),
	]
	var res: Dictionary = _escolher_cru(entradas)
	assert_eq(int(res["indice"]), 2, "sem a cor na linha de cima a mais proxima fica de fora: a de y=100 tem saida")
	# Fallback: a candidata de outra cor tambem precisa da propria cor acima
	var fallback: Array = [
		_entrada(250.0, 90.0, VERDE),
		_entrada(250.0 - esp, 90.0, AMARELO),
		_entrada(100.0, 90.0, AMARELO),
		_entrada(100.0 - esp, 90.0, AMARELO),
	]
	var res_fallback: Dictionary = _escolher_cru(fallback)
	assert_true(bool(res_fallback["fallback"]), "sem AZUL na tela vale o fallback")
	assert_eq(int(res_fallback["indice"]), 2, "no fallback a candidata sem a propria cor acima tambem fica de fora")
	# Nenhuma com saida: nenhuma (derrota padrao em quem chama)
	var sem_saida: Dictionary = _escolher_cru([_entrada(250.0, 90.0, AZUL), _entrada(250.0 - esp, 90.0, VERDE)])
	assert_eq(int(sem_saida["indice"]), -1, "so candidata sem a cor na linha de cima: nenhuma")


# --- C648: chaves de estado em entradas_de_plataformas -------------------------------------------------------------


func test_c648_entradas_de_plataformas_acrescentam_desmoronando_e_pisca_oculta_conforme_o_estado_real() -> void:
	var normal: Platform = _plataforma(AZUL, [])
	var desmoronando: Platform = _plataforma(VERDE, [])
	desmoronando.iniciar_desmoronamento(1.0)
	var desmoronada: Platform = _plataforma(AMARELO, [])
	desmoronada.desmoronada = true
	var piscando: Platform = _plataforma(VERMELHO, [_blink(3.5)])
	var entradas: Array = ReachableColors.entradas_de_plataformas([normal, desmoronando, desmoronada, piscando])
	assert_eq(entradas.size(), 4, "as quatro plataformas vivas viram entrada")
	assert_false(bool(entradas[0]["desmoronando"]), "plataforma normal nao esta desmoronando")
	assert_false(bool(entradas[0]["desmoronada"]), "plataforma normal nao esta desmoronada")
	assert_false(bool(entradas[0]["pisca_oculta"]), "plataforma normal nao esta oculta por piscar")
	assert_true(bool(entradas[1]["desmoronando"]), "iniciar_desmoronamento reflete em \"desmoronando\"")
	assert_false(bool(entradas[1]["desmoronada"]), "desmoronando ainda nao e desmoronada")
	assert_true(bool(entradas[2]["desmoronada"]), "o estado publico desmoronada segue na entrada")
	assert_true(bool(entradas[3]["pisca_oculta"]), "piscante nascida na fase invisivel reflete em \"pisca_oculta\"")
	assert_true(is_same(entradas[0]["plataforma"], normal), "a entrada guarda a propria plataforma de origem")

# --- Correcao 1 (PASSO 6.5, achado C1 do game-review): dentro da faixa, estatica antes de movel -------------------
# Plataforma movel (Platform.speed != 0) sai de baixo do gecko — ele nao e carregado — e o reaparecimento
# derrubaria de novo, gastando a carga sem salvar. O desempate novo vive DENTRO da faixa (a da cor do gecko e,
# so no fallback, a de qualquer cor): havendo ao menos uma estatica ("movel" falso/ausente), so as estaticas sao
# consideradas; so faixa sem nenhuma estatica considera as moveis. Movel da cor do gecko nunca perde para
# estatica de outra cor: a faixa da cor vem antes, o desempate nunca troca de faixa.


func test_movel_da_cor_mais_proxima_perde_para_estatica_da_cor_mais_distante() -> void:
	# Prova de mutacao (verify-wave --mutate revertendo o desempate de faixa em escolher para a _mais_proxima
	# antiga): este it falha em "[0] expected to equal [1]:  havendo estatica da cor na faixa, a movel mais
	# proxima fica fora da escolha: vence a estatica" (at line 372) — a escolhida volta a ser a movel mais
	# proxima (y=310), que sai de baixo do gecko (ele nao e carregado), derruba de novo e gasta a carga sem
	# salvar (o achado C1 do game-review que motivou a correcao).
	var movel: Dictionary = _entrada(310.0, 90.0, AZUL, false, false, false, true)
	var estatica: Dictionary = _entrada(100.0, 90.0, AZUL)
	var res: Dictionary = _escolher([movel, estatica])
	var escolhida: Dictionary = res["entrada"]
	assert_eq(
		int(res["indice"]),
		1,
		"havendo estatica da cor na faixa, a movel mais proxima fica fora da escolha: vence a estatica"
	)
	assert_eq(
		float(escolhida["y"]), 100.0, "a escolhida e a estatica mais distante (y=100), nao a movel (y=310)"
	)
	assert_false(bool(escolhida.get("movel", false)), "a escolhida e estatica")
	assert_lt(
		_distancia_do_gecko(movel),
		_distancia_do_gecko(escolhida),
		"a movel era a mais proxima do ponto da queda: perder para a estatica e o desempate novo"
	)
	assert_false(bool(res["fallback"]), "escolha dentro da faixa da cor: sem fallback")


func test_faixa_da_cor_so_com_moveis_escolhe_a_movel_mais_proxima_sem_devolver_nenhuma() -> void:
	var entradas: Array = [
		_entrada(200.0, 120.0, AZUL, false, false, false, true),
		_entrada(100.0, 60.0, AZUL, false, false, false, true),
		_entrada(310.0, 90.0, VERDE),
	]
	var res: Dictionary = _escolher(entradas)
	var escolhida: Dictionary = res["entrada"]
	assert_eq(
		int(res["indice"]),
		0,
		"faixa da cor so com moveis: a movel mais proxima e escolhida, nao \"nenhuma\""
	)
	assert_ne(int(res["indice"]), -1, "so moveis na faixa nao devolve \"nenhuma\"")
	assert_true(bool(escolhida.get("movel", false)), "a escolhida e movel: nao havia estatica na faixa")
	assert_false(bool(res["fallback"]), "a escolhida tem a cor do gecko: sem fallback")
	assert_lt(
		_distancia_do_gecko(entradas[0]),
		_distancia_do_gecko(entradas[1]),
		"entre as moveis da faixa, vence a mais proxima do ponto da queda"
	)


func test_movel_da_cor_do_gecko_nao_perde_para_estatica_de_outra_cor_faixa_da_cor_vence() -> void:
	var entradas: Array = [
		_entrada(310.0, 90.0, AZUL, false, false, false, true),
		_entrada(100.0, 90.0, VERDE),
	]
	var res: Dictionary = _escolher(entradas)
	var escolhida: Dictionary = res["entrada"]
	assert_eq(
		int(res["indice"]),
		0,
		"movel da cor do gecko vence estatica de outra cor: a faixa da cor vem antes do desempate"
	)
	assert_true(bool(escolhida.get("movel", false)), "a escolhida e a movel da cor do gecko")
	assert_eq(int(res["cor"]), AZUL, "a cor devolvida e a cor do gecko")
	assert_false(bool(res["fallback"]), "sem fallback: havia candidata da cor, so que movel")


func test_fallback_estatica_de_outra_cor_vence_movel_mais_proxima_de_outra_cor() -> void:
	var entradas: Array = [
		_entrada(310.0, 90.0, VERDE, false, false, false, true),
		_entrada(100.0, 90.0, AMARELO),
	]
	var res: Dictionary = _escolher(entradas)
	var escolhida: Dictionary = res["entrada"]
	assert_true(bool(res["fallback"]), "sem nenhuma da cor do gecko: fallback de qualquer cor")
	assert_eq(
		int(res["indice"]),
		1,
		"no fallback havendo estatica, a movel mais proxima fica fora da escolha: vence a estatica"
	)
	assert_eq(int(res["cor"]), AMARELO, "cor a assumir = cor da estatica escolhida")
	assert_lt(
		_distancia_do_gecko(entradas[0]),
		_distancia_do_gecko(escolhida),
		"a movel era a mais proxima: no fallback a estatica vence o desempate"
	)
