extends GutTest

# f530 T2: alvos do pouso reto da linha de cima (ReachableColors.alvos_da_linha_acima + alinhamento_do_alvo),
# funcoes puras como as demais do ReachableColors (entradas em dicionario, sem arvore). Cenarios C794-C801 do
# 05-test-plan. Larguras lidas das constantes (PlayArea.LARGURA, MovingRowFill.SEMI_PLATAFORMA) e a meia-largura
# do corpo do shape do Player por regua propria (a cena instanciada so para ler o shape, no padrao de
# test_segunda_chance_justica.gd) — nunca do codigo sob teste, para a prova de mutacao do limiar (C796) nao
# herdar o valor dele. Janela de chegada = a de Player.change_color_random (tempo_de_pulo(scroll) +
# ESPERA_MAXIMA_S), salvo onde o cenario pede janela propria (C798).

const PlayerFisica := preload("res://scenes/Player.gd")
const PLAYER_SCENE := "res://scenes/Player.tscn"
const PLATAFORMA_CENA := "res://scenes/Platform.tscn"
const LARGURA := PlayArea.LARGURA
const SEMI_APOIO := MovingRowFill.SEMI_PLATAFORMA
const Y_REF := 200.0
const Y_LINHA: float = Y_REF - InitialRows.ESPACAMENTO
const SEED := 20261115
const PERIODO := 3.0
const AZUL := Enums.COLOR.AZUL
const VERDE := Enums.COLOR.VERDE
const AMARELO := Enums.COLOR.AMARELO

var _meia_corpo := 0.0
var _plataformas_original: Array = []
var _iniciado_original := false


func before_all() -> void:
	_meia_corpo = _medir_meia_corpo()


func before_each() -> void:
	_plataformas_original = Global.platforms
	_iniciado_original = Global.iniciado
	Global.platforms = []
	Global.iniciado = false


func after_each() -> void:
	Global.platforms = _plataformas_original
	Global.iniciado = _iniciado_original


# Regua independente da producao: meia-largura do corpo lida do shape de colisao da cena do Player.
func _medir_meia_corpo() -> float:
	var player: Node = load(PLAYER_SCENE).instantiate()
	var forma: RectangleShape2D = (player.get_node("CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D
	var meia: float = forma.size.x / 2.0
	player.free()
	return meia


# --- builders de entradas (o modelo de entradas_de_plataformas, sem arvore) --------------------------------------


func _entrada(x: float, cor: int, vx: float = 0.0) -> Dictionary:
	return {"y": Y_LINHA, "x": x, "cor": cor, "vx": vx}


# Entrada montada a mao sem a chave "vx" (contrato: ausente vale 0, C797).
func _entrada_sem_vx(x: float, cor: int) -> Dictionary:
	return {"y": Y_LINHA, "x": x, "cor": cor}


func _entrada_com_ciclo(x: float, cor: int, ciclo: PlatformColorCycle) -> Dictionary:
	var e := _entrada(x, cor)
	e["ciclo"] = ciclo
	return e


func _entrada_com_pisca(x: float, cor: int, pisca: PlatformBlink) -> Dictionary:
	var e := _entrada(x, cor)
	e["pisca"] = pisca
	return e


func _ciclo() -> PlatformColorCycle:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var ciclo := PlatformColorCycle.new()
	ciclo.iniciar(AZUL, PERIODO, rng)
	return ciclo


# Piscante com ciclo visivel/invisivel injetados e fase fixada (padrao de test_cor_alcancavel_pisca_janela.gd).
func _pisca(visivel: float, invisivel: float, fase: float) -> PlatformBlink:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var blink := PlatformBlink.new()
	blink.iniciar(rng, visivel, invisivel, 0.0, 1.0)
	blink.definir_fase(fase)
	return blink


# Chamadas do cenario: alvos da linha de cima e a reducao a {alinhado, dx}.
func _alvos(entradas: Array, cor: int, dt: float, espera: float) -> Array:
	return ReachableColors.alvos_da_linha_acima(entradas, Y_REF, cor, LARGURA, dt, espera)


func _alinhado(entradas: Array, cor: int, x_gecko: float, dt: float, espera: float) -> Dictionary:
	return ReachableColors.alinhamento_do_alvo(_alvos(entradas, cor, dt, espera), x_gecko)


# Plataforma real (C801): a mesma regua de test_reachable_colors.gd para as chaves de entradas_de_plataformas.
func _plataforma(cor: int, x: float, speed: int) -> Platform:
	var p: Platform = add_child_autofree(load(PLATAFORMA_CENA).instantiate())
	p.global_position = Vector2(x, Y_LINHA)
	p.set_color(cor)
	p.set_speed(speed)
	return p


# --- C794: wrap horizontal do dx --------------------------------------------------------------------------------


func test_c794_wrap_gecko_perto_de_uma_borda_alvo_na_outra_devolve_o_caminho_curto() -> void:
	var dt: float = ReachableColors.tempo_de_pulo(0.0)
	var espera: float = PlayerFisica.ESPERA_MAXIMA_S
	# Aritmetica do wrap do requirements: 10 - 170 = -160 pela borda; pelo caminho curto e -160 + LARGURA = +20
	var a_direita: Dictionary = _alinhado([_entrada(10.0, AZUL)], AZUL, 170.0, dt, espera)
	assert_eq(int(a_direita["dx"]), 20, "gecko em 170, alvo em 10: dx=+20 pelo wrap, nao -160")
	assert_true(bool(a_direita["alinhado"]), "|+20| dentro do limiar: alinhado")
	var a_esquerda: Dictionary = _alinhado([_entrada(170.0, AZUL)], AZUL, 10.0, dt, espera)
	assert_eq(int(a_esquerda["dx"]), -20, "espelhado: gecko em 10, alvo em 170 -> dx=-20 (160 - LARGURA)")
	assert_true(bool(a_esquerda["alinhado"]), "|-20| dentro do limiar: alinhado")


# --- C795: da cor mas desalinhada -------------------------------------------------------------------------------


func test_c795_da_cor_mas_desalinhada_alinhado_false_e_dx_com_o_sinal_do_lado_do_alvo() -> void:
	var limiar: float = float(SEMI_APOIO) + _meia_corpo
	var dt: float = ReachableColors.tempo_de_pulo(0.0)
	var espera: float = PlayerFisica.ESPERA_MAXIMA_S
	# Gecko no centro, longe das bordas (sem wrap no caminho): alvo alem do limiar para cada lado
	var a_direita: Dictionary = _alinhado([_entrada(90.0 + limiar + 10.0, AZUL)], AZUL, 90.0, dt, espera)
	assert_false(bool(a_direita["alinhado"]), "|dx| acima de SEMI_PLATAFORMA + meia-largura do corpo: nao alinhado")
	assert_gt(int(a_direita["dx"]), 0, "alvo a direita: dx com sinal positivo")
	assert_gt(int(a_direita["dx"]), int(roundi(limiar)), "modulo acima do limiar (distancia real, sem clamp)")
	var a_esquerda: Dictionary = _alinhado([_entrada(90.0 - limiar - 10.0, AZUL)], AZUL, 90.0, dt, espera)
	assert_false(bool(a_esquerda["alinhado"]), "desalinhado para o outro lado tambem")
	assert_lt(int(a_esquerda["dx"]), 0, "alvo a esquerda: dx com sinal negativo")
	assert_gt(-int(a_esquerda["dx"]), int(roundi(limiar)), "modulo acima do limiar para o lado negativo")


# --- C796: limite do alinhamento --------------------------------------------------------------------------------


func test_c796_limite_logo_abaixo_alinha_na_borda_exata_nao_e_acima_tambem_nao() -> void:
	assert_gt(_meia_corpo, 0.0, "fixture: o shape do Player tem meia-largura positiva")
	var limiar: float = float(SEMI_APOIO) + _meia_corpo
	var dt: float = ReachableColors.tempo_de_pulo(0.0)
	var espera: float = PlayerFisica.ESPERA_MAXIMA_S
	# Gecko em x=0: o dx e exatamente o x do alvo (sem aritmetica no caminho, a borda exata e confiavel)
	var na_faixa_da_meia: Dictionary = _alinhado(
		[_entrada(float(SEMI_APOIO) + _meia_corpo * 0.5, AZUL)], AZUL, 0.0, dt, espera
	)
	assert_true(
		bool(na_faixa_da_meia["alinhado"]),
		"SEMI_PLATAFORMA < |dx| < limiar: alinhado (a meia-largura do corpo conta; omitti-la reprova aqui)"
	)
	var logo_abaixo: Dictionary = _alinhado([_entrada(limiar - 1.0, AZUL)], AZUL, 0.0, dt, espera)
	assert_true(bool(logo_abaixo["alinhado"]), "|dx| logo abaixo do limiar: alinhado")
	var na_borda: Dictionary = _alinhado([_entrada(limiar, AZUL)], AZUL, 0.0, dt, espera)
	assert_false(bool(na_borda["alinhado"]), "|dx| exatamente no limiar: NAO alinhado (limiar estrito, < e nao <=)")
	var logo_acima: Dictionary = _alinhado([_entrada(limiar + 1.0, AZUL)], AZUL, 0.0, dt, espera)
	assert_false(bool(logo_acima["alinhado"]), "|dx| logo acima do limiar: nao alinhado")


# --- C797: plataforma movel: x previsto na chegada --------------------------------------------------------------


func test_c797_plataforma_movel_preve_o_x_da_chegada_e_sem_vx_usa_zero() -> void:
	var dt: float = ReachableColors.tempo_de_pulo(0.0)
	var espera: float = PlayerFisica.ESPERA_MAXIMA_S
	assert_gt(dt, 0.0, "fixture: dt de chegada positivo")
	var limiar: float = float(SEMI_APOIO) + _meia_corpo
	# Deslocamento total no tempo de voo: 10 px (cruza o limiar em qualquer direcao); gecko em 0 (dx exato)
	var vx: float = 10.0 / dt
	var previstos: Array = _alvos([_entrada(100.0, AZUL, vx)], AZUL, dt, espera)
	assert_eq(previstos.size(), 1, "a movel elegivel vira alvo")
	assert_almost_eq(float(previstos[0]["x"]), 100.0 + vx * dt, 0.0001, "x previsto = x + vx * dt_chegada")
	# O x ATUAL alinharia, mas o previsto fica alem do limiar
	var sai_da_faixa: Dictionary = _alinhado([_entrada(limiar - 5.0, AZUL, vx)], AZUL, 0.0, dt, espera)
	assert_false(bool(sai_da_faixa["alinhado"]), "x atual alinharia; o previsto (x + vx * dt) nao: desalinhado")
	assert_eq(int(sai_da_faixa["dx"]), int(roundi(limiar - 5.0 + vx * dt)), "dx pelo x previsto, do lado do movimento")
	# O inverso: x atual desalinhado, o previsto entra na faixa
	var entra_na_faixa: Dictionary = _alinhado([_entrada(limiar + 5.0, AZUL, -vx)], AZUL, 0.0, dt, espera)
	assert_true(bool(entra_na_faixa["alinhado"]), "x atual fora da faixa; o previsto entra: alinhado")
	assert_eq(int(entra_na_faixa["dx"]), int(roundi(limiar + 5.0 - vx * dt)), "dx pelo x previsto (aproximando)")
	# Sem a chave "vx" na entrada: velocidade 0, o x da entrada e o previsto
	var sem_vx: Dictionary = _alinhado([_entrada_sem_vx(limiar - 5.0, AZUL)], AZUL, 0.0, dt, espera)
	assert_true(bool(sem_vx["alinhado"]), "sem chave vx: usa 0, o x atual (alinhado) vale")
	assert_eq(int(sem_vx["dx"]), int(roundi(limiar - 5.0)), "sem vx o dx e o do x informado")


# --- C798: cicladora que muda na janela e piscante invisivel: mesmas exclusoes do coletor -----------------------


func test_c798_cicladora_que_muda_na_janela_e_piscante_invisivel_ficam_de_fora() -> void:
	# Janela deslocada para cruzar a troca do periodo de 3 s (a mesma forma de test_reachable_colors_tempo.gd)
	var dt: float = PERIODO - 0.3
	var espera: float = 0.6
	var ciclo := _ciclo()
	assert_ne(ciclo.cor_em(dt), ciclo.cor_em(dt + espera), "fixture: a cicladora troca de cor dentro da janela")
	var invisivel_na_janela := _pisca(1.0, 1.0, 0.5)
	assert_false(
		invisivel_na_janela.visivel_na_janela(dt, dt + espera), "fixture: a piscante fica invisivel dentro da janela"
	)
	var excluidas: Array = _alvos(
		[_entrada_com_ciclo(90.0, AZUL, ciclo), _entrada_com_pisca(60.0, AZUL, invisivel_na_janela)],
		AZUL,
		dt,
		espera
	)
	assert_eq(
		excluidas.size(), 0, "cicladora que muda na janela e piscante invisivel nao viram alvo (mesmo filtro do coletor)"
	)
	var sem_alvo: Dictionary = ReachableColors.alinhamento_do_alvo(excluidas, 90.0)
	assert_false(bool(sem_alvo["alinhado"]), "sem alvo elegivel: alinhado false")
	assert_eq(int(sem_alvo["dx"]), 0, "sem alvo elegivel: dx 0")
	# Controles: a mesma cicladora com a janela coberta pela cor conta; piscante visivel na janela inteira conta
	var antes_da_troca: Array = _alvos([_entrada_com_ciclo(90.0, AZUL, ciclo)], AZUL, 0.0, 0.6)
	assert_eq(antes_da_troca.size(), 1, "a mesma cicladora com a cor cobrindo a janela vira alvo")
	var visivel_na_janela := _pisca(4.0, 1.0, 0.0)
	assert_true(
		visivel_na_janela.visivel_na_janela(dt, dt + espera), "fixture: a piscante de controle cobre a janela inteira"
	)
	assert_eq(
		_alvos([_entrada_com_pisca(60.0, AZUL, visivel_na_janela)], AZUL, dt, espera).size(),
		1,
		"piscante visivel em toda a janela vira alvo"
	)


# --- C799: ausencia: so outra cor ou lista vazia ----------------------------------------------------------------


func test_c799_plataformas_so_de_outra_cor_ou_lista_vazia_devolvem_false_e_dx_zero() -> void:
	var dt: float = ReachableColors.tempo_de_pulo(0.0)
	var espera: float = PlayerFisica.ESPERA_MAXIMA_S
	# So de outra cor, alinhadissimas: nada elegivel
	var so_outra: Array = [_entrada(90.0, VERDE), _entrada(60.0, AMARELO)]
	assert_eq(_alvos(so_outra, AZUL, dt, espera).size(), 0, "nenhuma entrada de outra cor vira alvo")
	var sem_da_cor: Dictionary = _alinhado(so_outra, AZUL, 90.0, dt, espera)
	assert_false(bool(sem_da_cor["alinhado"]), "so de outra cor: alinhado false")
	assert_eq(int(sem_da_cor["dx"]), 0, "sem alvo da cor: dx 0")
	# Lista vazia: o mesmo contrato de ausencia
	var vazio: Dictionary = _alinhado([], AZUL, 90.0, dt, espera)
	assert_false(bool(vazio["alinhado"]), "lista vazia: alinhado false")
	assert_eq(int(vazio["dx"]), 0, "lista vazia: dx 0")


# --- C800: duas elegiveis: o dx e o da mais proxima -------------------------------------------------------------


func test_c800_duas_elegiveis_alinhado_true_e_dx_da_elegivel_mais_proxima() -> void:
	var dt: float = ReachableColors.tempo_de_pulo(0.0)
	var espera: float = PlayerFisica.ESPERA_MAXIMA_S
	var limiar: float = float(SEMI_APOIO) + _meia_corpo
	assert_gt(80.0, limiar, "fixture: |dx|=80 (alvo em 170) fica fora da faixa de alinhamento")
	# A desalinhada vem PRIMEIRA na lista: o dx reportado e o da mais proxima (a alinhada), nao o da 1a da ordem
	var res: Dictionary = _alinhado([_entrada(170.0, AZUL), _entrada(98.0, AZUL)], AZUL, 90.0, dt, espera)
	assert_true(bool(res["alinhado"]), "havendo uma alinhada entre as elegiveis: alinhado true")
	assert_eq(int(res["dx"]), 8, "o dx e o da elegivel mais proxima (a alinhada), nao o da 1a da lista")
	var espelhado: Dictionary = _alinhado([_entrada(170.0, AZUL), _entrada(82.0, AZUL)], AZUL, 90.0, dt, espera)
	assert_true(bool(espelhado["alinhado"]), "alinhada a esquerda tambem alinha")
	assert_eq(int(espelhado["dx"]), -8, "sinal do lado da mais proxima")


# --- C801: entradas_de_plataformas so ganha a chave vx ----------------------------------------------------------


# Filtro de linha e de x herdado do coletor (C798 cita "mesmo filtro de y, x"): mesma cor em outra linha ou
# fora do x nao vira alvo; as bordas x=0 e x=largura entram, como em test_reachable_colors.gd.
func test_alvos_filtram_linha_e_x_como_o_coletor() -> void:
	var dt: float = ReachableColors.tempo_de_pulo(0.0)
	var espera: float = PlayerFisica.ESPERA_MAXIMA_S
	var na_linha_de_pouso: Dictionary = _entrada(90.0, AZUL)
	na_linha_de_pouso["y"] = Y_REF
	var fora_do_x: Dictionary = _entrada(90.0, AZUL)
	fora_do_x["x"] = float(LARGURA) + 1.0
	var alvos: Array = _alvos(
		[na_linha_de_pouso, fora_do_x, _entrada(0.0, AZUL), _entrada(float(LARGURA), AZUL)], AZUL, dt, espera
	)
	assert_eq(alvos.size(), 2, "outra linha e x fora da faixa ficam de fora; x=0 e x=largura entram")
	assert_almost_eq(float(alvos[0]["x"]), 0.0, 0.0001, "o 1o alvo e o da borda esquerda")
	assert_almost_eq(float(alvos[1]["x"]), float(LARGURA), 0.0001, "o 2o alvo e o da borda direita")


func test_c801_entradas_de_plataformas_so_ganham_a_chave_vx_valores_anteriores_iguais() -> void:
	var parada: Platform = _plataforma(AZUL, 40.0, 0)
	var movel: Platform = _plataforma(VERDE, 60.0, 30)
	movel.desvio_vx = -5.0
	var pra_direita: Platform = _plataforma(AMARELO, 80.0, -30)
	var entradas: Array = ReachableColors.entradas_de_plataformas([parada, movel, pra_direita])
	assert_eq(entradas.size(), 3, "as tres plataformas vivas viram entrada")
	# Chave nova: vx = -speed + desvio_vx (a velocidade horizontal de Platform._physics_process)
	assert_eq(float(entradas[0]["vx"]), 0.0, "speed 0 (sem desvio): vx 0")
	assert_eq(float(entradas[1]["vx"]), -35.0, "speed 30 com desvio -5: vx = -speed + desvio_vx = -35")
	assert_eq(float(entradas[2]["vx"]), 30.0, "speed -30: vx = +30 (para a direita)")
	# Nenhuma chave alem de vx entrou: o conjunto e o anterior + vx
	var chaves: Array = entradas[0].keys()
	chaves.sort()
	assert_eq(
		chaves,
		["cor", "desmoronada", "desmoronando", "movel", "pisca_oculta", "plataforma", "vx", "x", "y"],
		"o conjunto de chaves e o anterior + vx, nada mais"
	)
	# Chaves anteriores com os mesmos valores
	assert_eq(int(entradas[0]["cor"]), AZUL, "cor segue a da plataforma")
	assert_eq(float(entradas[0]["x"]), 40.0, "x global segue o da plataforma")
	assert_eq(float(entradas[0]["y"]), Y_LINHA, "y global segue o da plataforma")
	assert_false(bool(entradas[0]["desmoronada"]), "desmoronada segue false")
	assert_false(bool(entradas[0]["desmoronando"]), "desmoronando segue false")
	assert_false(bool(entradas[0]["pisca_oculta"]), "pisca_oculta segue false")
	assert_false(bool(entradas[0]["movel"]), "speed 0 segue estatica")
	assert_true(bool(entradas[1]["movel"]), "speed 30 segue movel")
	assert_true(bool(entradas[2]["movel"]), "speed negativo segue movel")
	assert_true(is_same(entradas[0]["plataforma"], parada), "a entrada guarda a propria plataforma de origem")
