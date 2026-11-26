extends GutTest

# Moldura de aviso de subida de estagio (LevelUpFrame): N picos de alpha, fim invisivel, interrupcao, reinicio,
# sem entrada nem texto, safe area injetada e cor branca fora da paleta do jogo.
const VISIVEL := Vector2(360.0, 640.0)
const LIMIAR := 0.5
const TETO_S := 3.0
const PASSO_S := 0.01


func _nova() -> LevelUpFrame:
	var f := LevelUpFrame.new()
	add_child_autofree(f)
	f.aplicar_layout(VISIVEL, Rect2(Vector2.ZERO, VISIVEL))
	return f


# Avanca o Tween do pulso em passos fixos de PASSO_S (sem depender da taxa de frames) ate terminar (ou o teto) e
# devolve o alpha de cada passo. `duracao[0]` recebe o tempo simulado.
func _gravar_ate_terminar(f: LevelUpFrame, duracao: Array = [0.0]) -> Array[float]:
	var amostras: Array[float] = [f.alpha()]
	f._tween.pause()
	var t := 0.0
	while f.pulsando() and t < TETO_S:
		f._tween.custom_step(PASSO_S)
		t += PASSO_S
		amostras.append(f.alpha())
	duracao[0] = t
	return amostras


# Avanca o pulso em curso `segundos` simulados (o Tween segue pausado para o teste conduzir o tempo).
func _avancar(f: LevelUpFrame, segundos: float) -> void:
	f._tween.pause()
	f._tween.custom_step(segundos)


# Amostra o alpha a cada frame durante `segundos`.
func _gravar_por(f: LevelUpFrame, segundos: float) -> Array[float]:
	var amostras: Array[float] = [f.alpha()]
	var t0 := Time.get_ticks_msec()
	while (Time.get_ticks_msec() - t0) < segundos * 1000.0:
		await get_tree().process_frame
		amostras.append(f.alpha())
	return amostras


# Quantas vezes o alpha cruza o limiar subindo (1 = 1 pico).
func _picos(amostras: Array[float]) -> int:
	var n := 0
	var acima := false
	for a in amostras:
		if a > LIMIAR and not acima:
			n += 1
		acima = a > LIMIAR
	return n


func _maximo(amostras: Array[float]) -> float:
	var m := 0.0
	for a in amostras:
		m = maxf(m, a)
	return m


func test_c342_pulsar_1_produz_1_pico_e_termina_invisivel() -> void:
	var f := _nova()
	assert_false(f.visible, "nasce invisivel")
	f.pulsar(1)
	var amostras := await _gravar_ate_terminar(f)
	assert_eq(_picos(amostras), 1, "1 pico de alpha")
	assert_gt(_maximo(amostras), 0.9, "o pico acende quase todo")
	assert_false(f.visible, "termina invisivel")
	assert_eq(f.alpha(), 0.0, "termina com alpha 0")


func test_c343_pulsar_2_produz_2_picos_distintos_e_termina_invisivel() -> void:
	var f := _nova()
	f.pulsar(2)
	var amostras := await _gravar_ate_terminar(f)
	assert_eq(_picos(amostras), 2, "2 picos separados por queda a baixo do limiar")
	assert_false(f.visible, "termina invisivel")
	assert_eq(f.alpha(), 0.0, "termina com alpha 0")


func test_c344_pulsar_3_produz_3_picos_em_ate_1_s_e_termina_invisivel() -> void:
	var f := _nova()
	var duracao: Array = [0.0]
	f.pulsar(3)
	var amostras := await _gravar_ate_terminar(f, duracao)
	var total_s: float = duracao[0]
	assert_eq(_picos(amostras), 3, "3 picos de alpha")
	assert_lte(total_s, 1.2, "duracao total ~1 s no maximo (medido %s s)" % total_s)
	assert_false(f.visible, "termina invisivel")
	assert_eq(f.alpha(), 0.0, "termina com alpha 0")


func test_c345_interromper_apaga_na_hora_e_nenhum_pico_depois() -> void:
	var f := _nova()
	f.pulsar(3)
	_avancar(f, 0.1)
	assert_true(f.pulsando(), "pre-condicao: pulso em curso")
	f.interromper()
	assert_eq(f.alpha(), 0.0, "alpha 0 na hora")
	assert_false(f.visible, "invisivel na hora")
	assert_false(f.pulsando(), "deixa de pulsar")
	if f._tween.is_valid():
		f._tween.play()
	var amostras := await _gravar_por(f, 1.0)
	assert_eq(_picos(amostras), 0, "nenhum pico depois de interromper")
	assert_eq(_maximo(amostras), 0.0, "alpha segue 0")
	assert_false(f.visible, "segue invisivel")


func test_c346_pulsar_3_durante_pulsar_1_reinicia_e_termina_com_3_picos() -> void:
	var f := _nova()
	f.pulsar(1)
	_avancar(f, 0.05)
	assert_true(f.pulsando(), "pre-condicao: o 1o pulso ainda corre")
	f.pulsar(3)
	var amostras := await _gravar_ate_terminar(f)
	assert_eq(_picos(amostras), 3, "3 picos, nao 4: a sequencia anterior foi cancelada")
	assert_false(f.visible, "termina invisivel")
	assert_eq(f.alpha(), 0.0, "termina com alpha 0")


func _todos(no: Node) -> Array:
	var out: Array = []
	for filho in no.get_children():
		out.append(filho)
		out.append_array(_todos(filho))
	return out


func test_c347_nao_filtra_mouse_e_nao_tem_texto() -> void:
	var f := _nova()
	var todos := _todos(f)
	var controles := 0
	for n in todos:
		assert_false(n is Label or n is RichTextLabel, "%s nao e texto" % n.get_class())
		if n is Control:
			controles += 1
			assert_eq((n as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s ignora o mouse" % n.get_class())
			assert_eq((n as Control).focus_mode, Control.FOCUS_NONE, "%s sem foco" % n.get_class())
	assert_gt(controles, 0, "ha ao menos 1 controle de desenho")


func test_c348_moldura_respeita_a_safe_area_injetada() -> void:
	var f := _nova()
	var safe := Rect2(12.0, 48.0, 320.0, 540.0)
	f.aplicar_layout(VISIVEL, safe)
	assert_true(f.rect_moldura() == safe, "a moldura ocupa a safe injetada, nao o visible_size")
	assert_false(f.rect_moldura() == Rect2(Vector2.ZERO, VISIVEL), "nao e o retangulo todo")


func test_c349_cor_e_branca_e_fora_da_paleta_do_jogo() -> void:
	assert_eq(LevelUpFrame.COR, Color.WHITE, "moldura branca")
	for c in Enums.COLOR.values():
		assert_ne(LevelUpFrame.COR, Enums.get_cor(c), "branco nao e a cor %s de Enums" % c)


func test_c350_pulsando_so_durante_o_pulso() -> void:
	var f := _nova()
	assert_false(f.pulsando(), "nasce sem pulsar")
	f.pulsar(1)
	assert_true(f.pulsando(), "verdadeiro durante o pulso")
	await _gravar_ate_terminar(f)
	assert_false(f.pulsando(), "falso apos terminar")
	f.pulsar(2)
	assert_true(f.pulsando(), "verdadeiro no novo pulso")
	f.interromper()
	assert_false(f.pulsando(), "falso apos interromper")


func test_fixa_pulsar_acende_direto_e_fica_acesa_depois_de_1_s() -> void:
	var f := _nova()
	f.fixa = true
	f.pulsar(3)
	assert_eq(f.alpha(), 1.0, "acende direto com alpha 1")
	assert_true(f.visible, "visivel")
	assert_true(f.pulsando(), "pulsando")
	await wait_seconds(1.2)
	assert_eq(f.alpha(), 1.0, "segue acesa depois de mais de 1 s")
	assert_true(f.visible, "segue visivel")
	assert_true(f.pulsando(), "segue pulsando")


func test_fixa_interromper_apaga() -> void:
	var f := _nova()
	f.fixa = true
	f.pulsar(1)
	f.interromper()
	assert_eq(f.alpha(), 0.0, "alpha 0")
	assert_false(f.visible, "invisivel")
	assert_false(f.pulsando(), "nao pulsa")


func test_fixa_pulsar_zero_nao_acende() -> void:
	var f := _nova()
	f.fixa = true
	f.pulsar(0)
	assert_eq(f.alpha(), 0.0, "n=0 nao acende")
	assert_false(f.pulsando(), "n=0 nao pulsa")


# Forma da vinheta (f490 T1, D1 = A): alpha de pico 0,5 na borda da safe area, decaindo ate 0 a 40 px para dentro, 0
# fora da safe area. Valores esperados vem do spec (D2), nao da implementacao.

func test_c442_miolo_da_safe_e_ponto_fora_dela_nao_desenham() -> void:
	var f := _nova()
	var safe := f.rect_moldura()
	assert_eq(f.intensidade_em(safe.get_center()), 0.0, "centro do miolo transparente")
	assert_eq(f.intensidade_em(safe.position + Vector2(120.0, 120.0)), 0.0, "miolo longe das bordas segue 0")
	f.aplicar_layout(VISIVEL, Rect2(12.0, 48.0, 320.0, 540.0))
	var deslocada := f.rect_moldura()
	assert_eq(f.intensidade_em(deslocada.get_center()), 0.0, "centro da safe deslocada transparente")
	assert_eq(f.intensidade_em(Vector2(0.0, deslocada.get_center().y)), 0.0, "ponto fora da safe injetada nao desenha")


func test_c443_borda_externa_esquerda_tem_alpha_de_pico() -> void:
	var f := _nova()
	var safe := f.rect_moldura()
	assert_eq(LevelUpFrame.ALPHA_PICO, 0.5, "pico do spec (D2)")
	assert_eq(f.intensidade_em(Vector2(safe.position.x, safe.get_center().y)), 0.5, "borda externa esquerda = ALPHA_PICO")


func test_c444_intensidade_decresce_para_dentro_e_zera_a_40_px() -> void:
	var f := _nova()
	var safe := f.rect_moldura()
	var y := safe.get_center().y
	var anterior := INF
	assert_eq(LevelUpFrame.PROFUNDIDADE, 40.0, "PROFUNDIDADE = 40 (2x)")
	for d in [0.0, 10.0, 20.0, 30.0]:
		var v := f.intensidade_em(Vector2(safe.position.x + d, y))
		assert_almost_eq(v, 0.5 * (1.0 - d / 40.0), 0.0001, "amostra a %s px segue o gradiente do spec" % d)
		assert_lte(v, anterior, "amostra a %s px nao cresce para dentro" % d)
		anterior = v
	assert_eq(f.intensidade_em(Vector2(safe.position.x + 40.0, y)), 0.0, "zera a 40 px (PROFUNDIDADE)")
	assert_eq(f.intensidade_em(Vector2(safe.position.x + 50.0, y)), 0.0, "segue 0 alem da PROFUNDIDADE")


func test_c445_borda_esquerda_acende_a_2_px_dentro() -> void:
	var f := _nova()
	var safe := f.rect_moldura()
	assert_gt(f.intensidade_em(Vector2(safe.position.x + 2.0, safe.get_center().y)), 0.0, "2 px dentro da borda esquerda")


func test_c446_borda_direita_acende_a_2_px_dentro() -> void:
	var f := _nova()
	var safe := f.rect_moldura()
	assert_gt(f.intensidade_em(Vector2(safe.end.x - 2.0, safe.get_center().y)), 0.0, "2 px dentro da borda direita")


func test_c447_borda_de_cima_acende_a_2_px_dentro() -> void:
	var f := _nova()
	var safe := f.rect_moldura()
	assert_gt(f.intensidade_em(Vector2(safe.get_center().x, safe.position.y + 2.0)), 0.0, "2 px dentro da borda de cima")


func test_c448_borda_de_baixo_acende_a_2_px_dentro() -> void:
	var f := _nova()
	var safe := f.rect_moldura()
	assert_gt(f.intensidade_em(Vector2(safe.get_center().x, safe.end.y - 2.0)), 0.0, "2 px dentro da borda de baixo")


func test_c449_forma_acompanha_a_safe_area_deslocada() -> void:
	var f := _nova()
	f.aplicar_layout(VISIVEL, Rect2(12.0, 48.0, 320.0, 540.0))
	var safe := f.rect_moldura()
	assert_eq(f.intensidade_em(Vector2(safe.position.x, safe.get_center().y)), 0.5, "borda externa da safe deslocada = ALPHA_PICO")
	assert_eq(f.intensidade_em(Vector2(0.0, safe.get_center().y)), 0.0, "x = 0 (borda se a safe fosse a origem) nao acende")


func test_c450_vinheta_nao_cobre_o_miolo() -> void:
	var f := _nova()
	var safe := f.rect_moldura()
	var menor := minf(safe.size.x, safe.size.y)
	assert_lt(LevelUpFrame.ALPHA_PICO, 1.0, "ALPHA_PICO < 1: o aviso nunca fica opaco")
	assert_lte(LevelUpFrame.PROFUNDIDADE, menor * 0.15, "PROFUNDIDADE <= 15 % da menor dimensao da safe")
	assert_eq(f.intensidade_em(Vector2(safe.position.x + menor * 0.15, safe.get_center().y)), 0.0, "a 15 % para dentro ja e miolo")


func test_c451_cantos_nao_vazam_para_fora_nem_passam_do_pico() -> void:
	var f := _nova()
	var safe := f.rect_moldura()
	var inicio := safe.position
	var fim := safe.end
	assert_eq(f.intensidade_em(inicio + Vector2(-1.0, -1.0)), 0.0, "1 px fora do canto superior esquerdo = 0")
	assert_eq(f.intensidade_em(Vector2(fim.x + 1.0, inicio.y - 1.0)), 0.0, "1 px fora do canto superior direito = 0")
	assert_eq(f.intensidade_em(Vector2(inicio.x - 1.0, fim.y + 1.0)), 0.0, "1 px fora do canto inferior esquerdo = 0")
	assert_eq(f.intensidade_em(fim + Vector2(1.0, 1.0)), 0.0, "1 px fora do canto inferior direito = 0")
	var canto := f.intensidade_em(inicio + Vector2(1.0, 1.0))
	assert_gt(canto, 0.0, "o canto interno (onde 2 faixas se sobrepoem) acende")
	assert_lte(canto, LevelUpFrame.ALPHA_PICO, "o canto interno nao passa de ALPHA_PICO")


func test_c452_constantes_da_moldura_antiga_foram_removidas() -> void:
	var f := _nova()
	var constantes: Dictionary = f.get_script().get_script_constant_map()
	for nome in ["ESPESSURA", "ESPESSURA_CONTORNO", "COR_CONTORNO"]:
		assert_false(constantes.has(nome), "%s nao existe mais no no" % nome)
	assert_true(constantes.has("PROFUNDIDADE"), "PROFUNDIDADE e a constante da forma nova")
	assert_true(constantes.has("ALPHA_PICO"), "ALPHA_PICO e a constante da forma nova")
