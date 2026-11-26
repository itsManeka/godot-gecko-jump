extends GutTest

# T4 (f495): modelo da sensibilidade do modo A. Constantes e funcao pura do TouchTuning (uma definicao do padrao e da
# faixa; o grep de definicao unica do criterio confere). Valores esperados vem da decisao do G1 (base de hoje 6 px de
# zona morta / 24 px de flick; faixa 0,5x a 2x; sensibilidade maior = limiares menores), nunca da saida da
# implementacao.

const PADRAO: float = 1.0
const MAXIMA: float = 2.0
const MINIMA: float = 0.5


func test_c463_valor_ausente_no_store_cai_no_padrao_1x() -> void:
	assert_eq(TouchTuning.sensibilidade_de_valor(null), PADRAO, "sem valor (leitura de chave ausente) = 1,0x")
	assert_eq(
		TouchTuning.sensibilidade_de_valor(TouchTuning.SENSIBILIDADE_SEM_VALOR),
		PADRAO,
		"sentinela SEM_VALOR (-1, fora da faixa) = 1,0x"
	)


func test_c464_tipo_errado_cai_no_padrao() -> void:
	assert_eq(TouchTuning.sensibilidade_de_valor("alta"), PADRAO, "String = padrao")
	assert_eq(TouchTuning.sensibilidade_de_valor("1.5"), PADRAO, "String numerica (1.5) tambem = padrao, sem coagir")
	assert_eq(TouchTuning.sensibilidade_de_valor(true), PADRAO, "bool = padrao")
	assert_eq(TouchTuning.sensibilidade_de_valor(Vector2(1.0, 1.0)), PADRAO, "Vector2 = padrao")


func test_c465_nan_cai_no_padrao() -> void:
	assert_eq(TouchTuning.sensibilidade_de_valor(NAN), PADRAO, "NaN = padrao")


func test_c466_fora_da_faixa_cai_no_padrao_e_extremos_sao_validos() -> void:
	assert_eq(TouchTuning.sensibilidade_de_valor(0.4), PADRAO, "abaixo de 0,5 = padrao")
	assert_eq(TouchTuning.sensibilidade_de_valor(2.5), PADRAO, "acima de 2 = padrao")
	assert_eq(
		TouchTuning.sensibilidade_de_valor(TouchTuning.SENSIBILIDADE_MIN),
		TouchTuning.SENSIBILIDADE_MIN,
		"0,5 (minimo da faixa) e valor valido"
	)
	assert_eq(
		TouchTuning.sensibilidade_de_valor(TouchTuning.SENSIBILIDADE_MAX),
		TouchTuning.SENSIBILIDADE_MAX,
		"2,0 (maximo da faixa) e valor valido"
	)
	assert_eq(TouchTuning.sensibilidade_de_valor(1.0), 1.0, "1,0 e valor valido")


func test_c467_padrao_reproduz_12px_de_zona_morta_e_48px_de_flick_e_extremos_mapeiam() -> void:
	# G1 em 360x640 (2x): 1,0x = 12 px / 48 px; sensibilidade maior = limiares menores. Maxima 2,0x ->
	# 6 px / 24 px; minima 0,5x -> 24 px / 96 px. Literais derivados do plano, nao da implementacao.
	assert_eq(TouchTuning.zona_morta_a(PADRAO), 12.0, "padrao: zona morta de 12 px (2x)")
	assert_eq(TouchTuning.flick_dy_min_a(PADRAO), 48.0, "padrao: flick dy minimo de 48 px (2x)")
	assert_eq(TouchTuning.zona_morta_a(MAXIMA), 6.0, "sensibilidade maxima: zona morta de 6 px")
	assert_eq(TouchTuning.flick_dy_min_a(MAXIMA), 24.0, "sensibilidade maxima: flick dy minimo de 24 px")
	assert_eq(TouchTuning.zona_morta_a(MINIMA), 24.0, "sensibilidade minima: zona morta de 24 px")
	assert_eq(TouchTuning.flick_dy_min_a(MINIMA), 96.0, "sensibilidade minima: flick dy minimo de 96 px")
	assert_eq(TouchTuning.REARME_VELOCIDADE_PX_MS, 0.10, "rearme: velocidade 0.10 px/ms (2x)")
	assert_eq(TouchTuning.REARME_RECUO_PX, 24.0, "rearme: recuo de 24 px (2x)")
