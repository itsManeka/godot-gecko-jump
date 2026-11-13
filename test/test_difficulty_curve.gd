extends GutTest
## Curva de dificuldade de producao (ressources/curva_dificuldade.tres): estagio 0, monotonia, teto, saturacao, max.
## O esperado vem dos estagios do .tres (teto = ultimo estagio), nunca da formula de interpolacao.

const CURVA_PATH := "res://ressources/curva_dificuldade.tres"
const PASSOS: int = 100
const EPS: float = 0.0001

var _curva: DifficultyCurve


func before_each() -> void:
	_curva = load(CURVA_PATH) as DifficultyCurve


func _no_progresso(p: float) -> DifficultySnapshot:
	# Pontos puros: progresso p exige pontos = p * pontos_plato (tempo 0).
	return _curva.avaliar(p * _curva.pontos_plato, 0.0)


func test_curva_de_producao_carrega_com_ao_menos_2_estagios() -> void:
	assert_not_null(_curva, "load() do .tres devolve DifficultyCurve")
	assert_gte(_curva.estagios.size(), 2)


func test_progresso_zero_e_o_comportamento_atual() -> void:
	var s := _curva.avaliar(0, 0)
	assert_almost_eq(s.get_scroll(), 20.0, EPS)
	assert_almost_eq(s.get_speed_moveis(), 60.0, EPS)
	assert_eq(s.get_k(), 3)
	assert_almost_eq(s.get_proporcao_estaticas(), 1.0 / 3.0, EPS)


# O caminho legado do sorteio (golden de rng do smoke) e o snapshot sem estado usam DifficultyStage.*_PADRAO:
# o estagio 0 do .tres tem de bater com eles, senao producao e "estagio 0" divergem em silencio.
func test_estagio_0_do_tres_bate_com_os_defaults_de_difficulty_stage() -> void:
	var e0: DifficultyStage = _curva.estagios[0]
	assert_almost_eq(e0.scroll, DifficultyStage.SCROLL_PADRAO, EPS, "scroll do E0 = SCROLL_PADRAO")
	assert_almost_eq(e0.speed_moveis, DifficultyStage.SPEED_PADRAO, EPS, "speed do E0 = SPEED_PADRAO")
	assert_almost_eq(float(e0.k), float(DifficultyStage.K_PADRAO), EPS, "K do E0 = K_PADRAO")
	assert_almost_eq(
		e0.proporcao_estaticas, DifficultyStage.PROPORCAO_PADRAO, EPS, "proporcao do E0 = PROPORCAO_PADRAO"
	)


func test_varredura_fina_monotonia() -> void:
	var anterior := _no_progresso(0.0)
	for i in range(1, PASSOS + 1):
		var p := float(i) / float(PASSOS)
		var atual := _no_progresso(p)
		assert_gte(atual.get_scroll(), anterior.get_scroll() - EPS, "scroll em p=%s" % p)
		assert_gte(atual.get_speed_moveis(), anterior.get_speed_moveis() - EPS, "speed em p=%s" % p)
		assert_gte(atual.get_k(), anterior.get_k(), "k em p=%s" % p)
		assert_lte(
			atual.get_proporcao_estaticas(),
			anterior.get_proporcao_estaticas() + EPS,
			"proporcao em p=%s" % p
		)
		anterior = atual


func test_varredura_fica_entre_estagio_0_e_teto() -> void:
	var piso := _curva.estagios[0]
	var teto := _curva.estagios.back() as DifficultyStage
	for i in range(0, PASSOS + 1):
		var s := _no_progresso(float(i) / float(PASSOS))
		assert_between(s.get_scroll(), piso.scroll - EPS, teto.scroll + EPS)
		assert_between(s.get_speed_moveis(), piso.speed_moveis - EPS, teto.speed_moveis + EPS)
		assert_between(s.get_k(), piso.k, teto.k)
		assert_between(
			s.get_proporcao_estaticas(),
			teto.proporcao_estaticas - EPS,
			piso.proporcao_estaticas + EPS
		)


func test_saturacao_pontos_e_tempo_extremos() -> void:
	var piso := _curva.estagios[0]
	var teto := _curva.estagios.back() as DifficultyStage
	for par in [[-1.0, 0.0], [-1.0, -5.0], [0.0, -5.0]]:
		var s := _curva.avaliar(par[0], par[1])
		assert_almost_eq(s.get_scroll(), piso.scroll, EPS, "piso %s" % [par])
		assert_almost_eq(s.get_speed_moveis(), piso.speed_moveis, EPS)
		assert_eq(s.get_k(), piso.k)
		assert_almost_eq(s.get_proporcao_estaticas(), piso.proporcao_estaticas, EPS)
		assert_eq(_curva.progresso(par[0], par[1]), 0.0)
	for par in [[1e9, 0.0], [0.0, 1e9], [1e9, 1e9]]:
		var s := _curva.avaliar(par[0], par[1])
		assert_almost_eq(s.get_scroll(), teto.scroll, EPS, "teto %s" % [par])
		assert_almost_eq(s.get_speed_moveis(), teto.speed_moveis, EPS)
		assert_eq(s.get_k(), teto.k)
		assert_almost_eq(s.get_proporcao_estaticas(), teto.proporcao_estaticas, EPS)
		assert_eq(_curva.progresso(par[0], par[1]), 1.0, "progresso saturado %s" % [par])
	var mix := _curva.avaliar(1e9, -5.0)
	assert_almost_eq(mix.get_scroll(), teto.scroll, EPS)
	var mix2 := _curva.avaliar(-1.0, 1e9)
	assert_almost_eq(mix2.get_scroll(), teto.scroll, EPS)


func test_progresso_e_o_maior_dos_dois_gatilhos() -> void:
	var meio_pontos := _curva.pontos_plato / 2.0
	var meio_tempo := _curva.segundos_plato / 2.0
	var so_pontos := _curva.progresso(meio_pontos, 0.0)
	var so_tempo := _curva.progresso(0.0, meio_tempo)
	assert_almost_eq(so_pontos, 0.5, EPS, "so pontos")
	assert_almost_eq(so_tempo, 0.5, EPS, "so tempo")
	# Ambos: o maior vence (pontos 1/4 do plato, tempo 3/4 do plato e o inverso).
	var tempo_maior := _curva.progresso(_curva.pontos_plato * 0.25, _curva.segundos_plato * 0.75)
	var pontos_maior := _curva.progresso(_curva.pontos_plato * 0.75, _curva.segundos_plato * 0.25)
	assert_almost_eq(tempo_maior, 0.75, EPS, "tempo maior")
	assert_almost_eq(pontos_maior, 0.75, EPS, "pontos maior")
	# O snapshot acompanha o maior: so tempo = mesmo que so pontos no mesmo progresso.
	var a := _curva.avaliar(meio_pontos, 0.0)
	var b := _curva.avaliar(0.0, meio_tempo)
	assert_almost_eq(a.get_scroll(), b.get_scroll(), EPS)
	assert_eq(a.get_k(), b.get_k())


func test_plato_devolve_valores_do_teto_e_permanece_constante() -> void:
	var teto := _curva.estagios.back() as DifficultyStage
	for p in [1.0, 1.5, 100.0]:
		var s := _curva.avaliar(p * _curva.pontos_plato, 0.0)
		assert_almost_eq(s.get_scroll(), teto.scroll, EPS, "scroll p=%s" % p)
		assert_almost_eq(s.get_speed_moveis(), teto.speed_moveis, EPS, "speed p=%s" % p)
		assert_eq(s.get_k(), teto.k, "k p=%s" % p)
		assert_almost_eq(
			s.get_proporcao_estaticas(), teto.proporcao_estaticas, EPS, "proporcao p=%s" % p
		)


func test_k_e_inteiro_floor_e_no_minimo_3() -> void:
	for i in range(0, PASSOS + 1):
		var s := _no_progresso(float(i) / float(PASSOS))
		assert_typeof(s.get_k(), TYPE_INT)
		assert_gte(s.get_k(), 3)
	# Interpolado 3.99 -> 3 (floor, nao arredondamento), em curva propria de 2 estagios.
	var a := DifficultyStage.new()
	a.progresso_inicio = 0.0
	a.k = 3
	var b := DifficultyStage.new()
	b.progresso_inicio = 1.0
	b.k = 4
	var curva := DifficultyCurve.new()
	curva.estagios = [a, b]
	curva.pontos_plato = 100.0
	assert_eq(curva.avaliar(99.0, 0.0).get_k(), 3, "3.99 -> 3")
	assert_eq(curva.avaliar(100.0, 0.0).get_k(), 4, "teto 4")
	# Na curva de producao, perto do fim do 1o trecho o K interpolado fica abaixo do proximo inteiro.
	var perto := _no_progresso(_curva.estagios[1].progresso_inicio * 0.97)
	assert_eq(perto.get_k(), _curva.estagios[0].k)


func test_estagios_sem_mecanicas_e_ordenados_a_partir_de_zero() -> void:
	assert_eq(_curva.estagios[0].progresso_inicio, 0.0, "primeiro estagio em 0.0")
	for i in range(_curva.estagios.size()):
		assert_eq(_curva.estagios[i].mecanicas.size(), 0, "mecanicas vazias no estagio %d" % i)
		if i > 0:
			assert_gt(
				_curva.estagios[i].progresso_inicio,
				_curva.estagios[i - 1].progresso_inicio,
				"progresso_inicio estritamente crescente no estagio %d" % i
			)


func test_indice_estagio_da_curva_de_producao_com_fronteira_e_saturacao() -> void:
	# C215: fronteira 0.35 (curva_dificuldade.tres) separa < de <=; fora de [0,1] satura.
	assert_eq(_curva.indice_estagio(0.0), 0, "0.0")
	assert_eq(_curva.indice_estagio(0.34), 0, "0.34")
	assert_eq(_curva.indice_estagio(0.35), 1, "0.35 (fronteira)")
	assert_eq(_curva.indice_estagio(0.7), 2, "0.7")
	assert_eq(_curva.indice_estagio(1.0), 3, "1.0")
	assert_eq(_curva.indice_estagio(-0.5), 0, "-0.5 satura em 0")
	assert_eq(_curva.indice_estagio(1.5), 3, "1.5 satura em 3")


func test_indice_estagio_sem_estagios_e_zero() -> void:
	assert_eq(DifficultyCurve.new().indice_estagio(0.9), 0, "curva vazia")


func _curva_duas_larguras() -> DifficultyCurve:
	var a := DifficultyStage.new()
	a.progresso_inicio = 0.0
	a.largura_plataforma = 56.0
	a.atraso_desmoronar = 1.0
	a.mecanicas = [&"plataformas_menores"]
	var b := DifficultyStage.new()
	b.progresso_inicio = 1.0
	b.largura_plataforma = 50.0
	b.atraso_desmoronar = 0.8
	b.mecanicas = [&"plataformas_que_caem"]
	var curva := DifficultyCurve.new()
	curva.estagios = [a, b]
	curva.pontos_plato = 100.0
	return curva


func test_estagio_sem_campos_novos_devolve_largura_60_e_atraso_1() -> void:
	assert_almost_eq(DifficultyStage.new().largura_plataforma, 60.0, EPS, "default do estagio")
	assert_almost_eq(DifficultyStage.new().atraso_desmoronar, 1.0, EPS, "default do estagio")
	var curva := DifficultyCurve.new()
	curva.estagios = [DifficultyStage.new()]
	var s := curva.avaliar(0.0, 0.0)
	assert_almost_eq(s.get_largura_plataforma(), 60.0, EPS)
	assert_almost_eq(s.get_atraso_desmoronar(), 1.0, EPS)


func test_interpolacao_no_meio_de_estagios_com_largura_e_atraso_e_media() -> void:
	var curva := _curva_duas_larguras()
	var s := curva.avaliar(50.0, 0.0)
	assert_almost_eq(s.get_largura_plataforma(), 53.0, EPS, "largura no meio = media de 56 e 50")
	assert_almost_eq(s.get_atraso_desmoronar(), 0.9, EPS, "atraso no meio = media de 1,0 e 0,8")
	assert_eq(s.get_mecanicas().size(), 1, "mecanicas vem so do estagio atual")
	assert_eq(s.get_mecanicas()[0], &"plataformas_menores")


func test_teto_devolve_largura_e_atraso_do_ultimo_estagio() -> void:
	var curva := _curva_duas_larguras()
	var s := curva.avaliar(1e9, 0.0)
	assert_almost_eq(s.get_largura_plataforma(), 50.0, EPS)
	assert_almost_eq(s.get_atraso_desmoronar(), 0.8, EPS)


func test_curva_sem_estagios_devolve_largura_60_e_atraso_1() -> void:
	var s := DifficultyCurve.new().avaliar(5.0, 5.0)
	assert_almost_eq(s.get_largura_plataforma(), 60.0, EPS)
	assert_almost_eq(s.get_atraso_desmoronar(), 1.0, EPS)


func test_snapshot_sem_argumentos_devolve_largura_60_e_atraso_1() -> void:
	var s := DifficultySnapshot.new()
	assert_almost_eq(s.get_largura_plataforma(), 60.0, EPS)
	assert_almost_eq(s.get_atraso_desmoronar(), 1.0, EPS)
	# Posicional ate o 4o parametro continua valido; os campos novos caem no default.
	var posicional := DifficultySnapshot.new(30.0, 90.0, 4, 0.5)
	assert_almost_eq(posicional.get_scroll(), 30.0, EPS)
	assert_almost_eq(posicional.get_proporcao_estaticas(), 0.5, EPS)
	assert_almost_eq(posicional.get_largura_plataforma(), 60.0, EPS)
	assert_almost_eq(posicional.get_atraso_desmoronar(), 1.0, EPS)


func test_snapshot_aceita_largura_e_atraso_como_ultimos_parametros() -> void:
	var s := DifficultySnapshot.new(20.0, 60.0, 3, 0.3, [&"plataformas_menores"], 44.0, 0.8)
	assert_almost_eq(s.get_largura_plataforma(), 44.0, EPS)
	assert_almost_eq(s.get_atraso_desmoronar(), 0.8, EPS)
	assert_eq(s.get_mecanicas()[0], &"plataformas_menores")
