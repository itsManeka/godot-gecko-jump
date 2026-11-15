extends GutTest

# T5 (f468): o preditor de pouso so conta uma plataforma que pisca se ela esta visivel em toda a janela de chegada
# [dt_chegada, dt_chegada + ESPERA_MAXIMA_S]. Puro: entradas em dicionario com "pisca" (PlatformBlink real, fase fixada),
# sem cena. O wiring de entradas_de_plataformas usa Platform falsa que devolve o pisca.

const PlayerFisica := preload("res://scenes/Player.gd")
const LARGURA := 180.0
const Y_REF := 1000.0
const DT_CHEGADA := 0.2
const SEED := 20261115


class PlataformaComPisca:
	extends Platform
	var pisca_fake: PlatformBlink = null

	func obter_pisca() -> PlatformBlink:
		return pisca_fake


# Piscante com ciclo visivel/invisivel injetados e fase fixada (sem relogio real).
func _pisca(visivel: float, invisivel: float, fase: float) -> PlatformBlink:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var blink := PlatformBlink.new()
	blink.iniciar(rng, visivel, invisivel, 0.0, 1.0)
	blink.definir_fase(fase)
	return blink


func _entrada(x: float, cor: int, pisca: PlatformBlink = null) -> Dictionary:
	var e := {"y": Y_REF - InitialRows.ESPACAMENTO, "x": x, "cor": cor}
	if pisca != null:
		e["pisca"] = pisca
	return e


func _entrada_com_ciclo(x: float, ciclo: PlatformColorCycle, pisca: PlatformBlink) -> Dictionary:
	var e := {"y": Y_REF - InitialRows.ESPACAMENTO, "x": x, "cor": ciclo.cor_em(0.0), "ciclo": ciclo, "pisca": pisca}
	return e


func _cores(entradas: Array) -> Array:
	return ReachableColors.coletar_cores_linha_acima(
		entradas, Y_REF, LARGURA, DT_CHEGADA, PlayerFisica.ESPERA_MAXIMA_S
	)


func test_c321_candidata_que_some_dentro_da_janela_nao_conta() -> void:
	# Fase 0,5 s no ciclo de 1 s visivel + 1 s invisivel: some em 0,5 s, dentro de [0,2; 0,8].
	var entradas: Array = [_entrada(90.0, Enums.COLOR.AMARELO, _pisca(1.0, 1.0, 0.5))]
	assert_eq(_cores(entradas), [], "a plataforma que some dentro da janela de chegada nao e candidata")


func test_c321_candidata_que_cabe_inteira_na_janela_conta() -> void:
	# Fase 0: visivel de 0 a 1 s, cobre [0,2; 0,8] inteira.
	var cor: int = Enums.COLOR.AMARELO
	var entradas: Array = [_entrada(90.0, cor, _pisca(1.0, 1.0, 0.0))]
	assert_eq(_cores(entradas), [cor], "a plataforma visivel na janela inteira e candidata")


func test_c322_entradas_sem_pisca_devolvem_o_resultado_de_antes() -> void:
	var cores_enum: Array = Enums.COLOR.values()
	var cor_a: int = cores_enum[0]
	var cor_b: int = cores_enum[1]
	var sem_pisca: Array = [
		_entrada(30.0, cor_a),
		_entrada(90.0, cor_b),
		_entrada(500.0, cores_enum[2]),
	]
	assert_eq(_cores(sem_pisca), [cor_a, cor_b], "sem pisca vale a cor estatica; x fora da largura continua fora")
	# Piscante inerte (proporcao 0 = sempre visivel) nao muda o resultado.
	var inerte := PlatformBlink.new()
	inerte.iniciar(RandomNumberGenerator.new(), 0.0, 0.0, 0.0, 0.0)
	var com_inerte: Array = [_entrada(30.0, cor_a, inerte), _entrada(90.0, cor_b, inerte)]
	assert_eq(_cores(com_inerte), [cor_a, cor_b], "piscante inerte devolve o mesmo resultado de antes")
	assert_eq(_cores([]), [], "sem entradas, lista vazia")


func test_c323_todas_piscantes_invisiveis_na_janela_devolvem_lista_vazia() -> void:
	# Fase 1,5 s: invisivel de 1 a 2 s; a janela [0,2; 0,8] inteira cai no invisivel. Nenhuma candidata, sem erro.
	var cores_enum: Array = Enums.COLOR.values()
	var entradas: Array = [
		_entrada(30.0, cores_enum[0], _pisca(1.0, 1.0, 1.5)),
		_entrada(90.0, cores_enum[1], _pisca(1.0, 1.0, 1.5)),
	]
	assert_eq(_cores(entradas), [], "todas piscantes invisiveis na janela devolvem lista vazia")


func test_c324_ciclo_e_pisca_juntos_valem_a_conjuncao() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	# Ciclo longo: cor constante na janela inteira (precondicao conferida antes da asserção).
	var ciclo_fixo := PlatformColorCycle.new()
	ciclo_fixo.iniciar(Enums.COLOR.AMARELO, 100.0, rng)
	var cor_fixa: int = ciclo_fixo.cor_em(DT_CHEGADA)
	assert_eq(
		ciclo_fixo.cor_em(DT_CHEGADA + PlayerFisica.ESPERA_MAXIMA_S),
		cor_fixa,
		"precondicao: o ciclo longo tem a mesma cor na janela"
	)
	# Ciclo curto: troca de cor dentro da janela (precondicao conferida antes da asserção).
	var ciclo_troca := PlatformColorCycle.new()
	ciclo_troca.iniciar(Enums.COLOR.AMARELO, 0.3, rng)
	assert_ne(
		ciclo_troca.cor_em(DT_CHEGADA),
		ciclo_troca.cor_em(DT_CHEGADA + PlayerFisica.ESPERA_MAXIMA_S),
		"precondicao: o ciclo curto troca de cor dentro da janela"
	)

	var visivel := _pisca(1.0, 1.0, 0.0)
	var some := _pisca(1.0, 1.0, 0.5)
	assert_eq(_cores([_entrada_com_ciclo(90.0, ciclo_fixo, visivel)]), [cor_fixa], "cor cobre a janela e visivel: conta")
	assert_eq(_cores([_entrada_com_ciclo(90.0, ciclo_fixo, some)]), [], "cor cobre mas some na janela: nao conta")
	assert_eq(_cores([_entrada_com_ciclo(90.0, ciclo_troca, visivel)]), [], "visivel mas a cor troca na janela: nao conta")


func test_entradas_de_plataformas_anexa_pisca_so_quando_a_plataforma_tem() -> void:
	var com_pisca := PlataformaComPisca.new()
	autofree(com_pisca)
	var pisca := _pisca(1.0, 1.0, 0.0)
	com_pisca.pisca_fake = pisca
	var sem_pisca := Platform.new()
	autofree(sem_pisca)
	var entradas: Array = ReachableColors.entradas_de_plataformas([com_pisca, sem_pisca])
	assert_eq(entradas.size(), 2, "as duas plataformas viram entrada")
	assert_true(entradas[0].has("pisca"), "plataforma com pisca anexa a instancia em \"pisca\"")
	assert_true(is_same(entradas[0]["pisca"], pisca), "a entrada guarda a mesma instancia do pisca")
	assert_false(entradas[1].has("pisca"), "plataforma sem pisca nao ganha a chave \"pisca\"")
