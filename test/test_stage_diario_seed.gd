extends GutTest

# f528 T5 (C767-C774): seed do dia na Stage e recarga na troca de modo. A Stage Diario nasce com a seed do dia
# UTC: o relogio e injetado ANTES do add_child pelo ponto de injecao do DiaUtc (Global.aplicar_dia_inicial ->
# Global.relogio_do_dia, o mesmo caminho `?dia=` dos smokes de T7). O resumo comparavel de cada linha (posicao,
# tipo, mecanica, cor das estaticas) segue o padrao do test_scroll_level_seed.gd; a cor das moveis fica fora
# (segue o gecko, decisao (d) do ADR 0014 — C769). A recarga ao cruzar a fronteira do Diario e espiada pela seam
# `recarregar_cena` (o GUT nao pode trocar a cena do proprio runner); a Stage que o reload real instanciaria e
# simulada instanciando outra com o modo persistido, o que `_on_animation_end` faria de verdade.

const STAGE_SCENE := "res://scenes/Stage.tscn"
# Plano de testes [T3/T5]: base 1700000000 = dia UTC 19675 (o par esta travado em test_dia_utc.gd); dia + 1 = 19676
const DIA_BASE := 19675
# Seed fixa do chamador (precedencia sobre o dia, C771); nunca coincide com um dia do relogio injetado
const SEMENTE_DO_CHAMADOR := 4242
# Camera do topo dirigida: o gecko e reposicionado acima do limite antes de cada _physics_process manual (a
# parcela do CameraFollow converge ao limite, entao o reset por passo mantem o avanco identico entre geracoes)
const Y_GEOCO_ACIMA := -2000.0
const PASSOS_CAMERA := 40
# Viewport logico fixo do layout (180x320 do Stage.tscn): determina o limite de topo da camera
const VISIVEL := Vector2(180.0, 320.0)
const SAFE := Rect2(0.0, 0.0, 180.0, 320.0)

var _resumos: Dictionary = {}
var _modo_original: StringName
var _cor_original: Enums.COLOR
var _sem_derrota_original: bool
var _toque_detectado_original: bool
var _espelho_original: bool
var _dia_inicial_original: int


func before_each() -> void:
	_modo_original = Global.get_modo_jogo()
	_cor_original = Global.cor_gecko
	_sem_derrota_original = Global.sem_derrota
	_toque_detectado_original = Global.toque_detectado
	_espelho_original = Global.tutorial_visto_espelho
	_dia_inicial_original = Global.dia_inicial
	# Sem derrota e sem toque: o gecko dirigido nao encerra a partida nem abre card na geracao
	Global.sem_derrota = false
	Global.tutorial_visto_espelho = true
	Global.toque_detectado = false
	Global.platforms = []
	Global.iniciado = false
	_resumos = {}


func after_each() -> void:
	# iniciado = false antes de restaurar o modo (a troca e bloqueada com a partida iniciada) e de novo no fim
	# (a geracao deixa iniciado true pelo Play); o modo volta persistido, desfazendo o que o _fechar_modos gravou
	Global.iniciado = false
	Global.set_modo_jogo(_modo_original)
	Global.dia_inicial = _dia_inicial_original
	Global.cor_gecko = _cor_original
	Global.sem_derrota = _sem_derrota_original
	Global.toque_detectado = _toque_detectado_original
	Global.tutorial_visto_espelho = _espelho_original
	Global.platforms = []
	Global.iniciado = false


# Captura o resumo de cada linha no nascimento, conectando ANTES do add_child da Stage: o child_entered_tree
# do container dispara tambem para as 5 linhas do .tscn quando a Stage entra na arvore (padrao do
# test_scroll_level_seed.gd) e de novo para cada linha nova (extras de _ready e as do avanco da camera);
# o ready de cada linha roda depois do proprio enter_tree, entao a conexao chega a tempo. O indice e o do
# y local, nunca a ordem de criacao.
func _escutar_linhas(stage: Node) -> void:
	stage.get_node("ScrollLevel/RunningPlatforms").child_entered_tree.connect(_ao_entrar_linha)


func _ao_entrar_linha(linha: Node) -> void:
	linha.ready.connect(_capturar.bind(linha))


func _capturar(linha: Node) -> void:
	var indice: int = RowSeed.indice_do_y(linha.position.y)
	_resumos[indice] = _resumir(linha)


# Resumo comparavel da linha: cor das moveis fica fora (segue o gecko, decisao (d) do ADR 0014).
func _resumir(linha: Node) -> Dictionary:
	var estatica: bool = linha.platform_type == Enums.PLATFORM_TYPE.STATIC
	var plataformas: Array = []
	for filho in linha.get_children():
		if filho is Platform:
			plataformas.append(_resumir_plataforma(filho, estatica))
	return {
		"tipo": linha.platform_type,
		"speed": linha.speed,
		"plataformas": plataformas,
	}


func _resumir_plataforma(plataforma: Platform, linha_estatica: bool) -> Dictionary:
	var mecanicas: Array = []
	for modificador in plataforma._modificadores:
		if modificador is PlatformColorCycle:
			mecanicas.append("ciclo")
		elif modificador is PlatformSineMotion:
			mecanicas.append("seno")
		elif modificador is PlatformPingPongMotion:
			mecanicas.append("vai_e_vem")
		elif modificador is PlatformBlink:
			mecanicas.append("pisca")
	var resumo := {
		"x": plataforma.position.x,
		"mecanicas": mecanicas,
	}
	if linha_estatica:
		resumo["cor"] = plataforma.color
	return resumo


# Indices de `base` que faltam em `outra` ou cujo resumo difere (lista vazia = geracoes iguais nos indices de base)
func _indices_divergentes(base: Dictionary, outra: Dictionary) -> Array:
	var divergentes: Array = []
	for indice in base:
		if not outra.has(indice) or base[indice] != outra[indice]:
			divergentes.append(indice)
	divergentes.sort()
	return divergentes


# Cor de gecko valida e diferente da vigente (so a cor das moveis segue o gecko; o resumo nao a compara)
func _cor_diferente_do_gecko() -> Enums.COLOR:
	var fonte := RandomNumberGenerator.new()
	fonte.seed = 31337
	var cor := Enums.get_random_color(fonte) as Enums.COLOR
	while cor == _cor_original:
		cor = Enums.get_random_color(fonte) as Enums.COLOR
	return cor


# Uma geracao no modo Diario com o dia injetado: modo e relogio aplicados ANTES do add_child (o _enter_tree le
# os dois), Stage na raiz, partida iniciada pelo Play (caminho real) e fisica dirigida a mao (a automatica e
# desligada): a camera do topo avanca PASSOS_CAMERA passos com o gecko acima do limite, criando mais linhas pelo
# gerador. Devolve {indice do y: resumo} do nascimento de cada linha (iniciais + do avanco).
func _gerar(dia: int, cor: Enums.COLOR) -> Dictionary:
	Global.iniciado = false
	Global.set_modo_jogo(GameModes.ID_DIARIO, false)
	Global.aplicar_dia_inicial(str(dia), true)
	assert_eq(
		DiaUtc.new(Global.relogio_do_dia()).dia_atual(),
		dia,
		"fixture: o relogio injetado deveria devolver o dia %s (C767/C768 dependem de dias de fato distintos)" % dia
	)
	Global.cor_gecko = cor
	Global.platforms = []
	# f528 T6: o Play do Diario gasta a tentativa do dia (uma por dia UTC); cada geracao comeca com o store
	# limpo para o fixture (duas geracoes no MESMO dia, C767/C769) nao esbarrar no bloqueio de "ja jogado
	# hoje" — o caminho e o isolado pelo gut_pre_run, nenhum teste grava o user:// real.
	DirAccess.remove_absolute("user://desafio_diario_test_suite.cfg")
	_resumos = {}
	var stage: Node = load(STAGE_SCENE).instantiate()
	_escutar_linhas(stage)
	add_child(stage)
	stage.apply_layout(VISIVEL, SAFE)
	stage.set_physics_process(false)
	(stage.get_node("ScrollLevel") as ScrollLevel).set_physics_process(false)
	stage._on_Play_button_down()
	var antes: int = _resumos.size()
	for i in PASSOS_CAMERA:
		# Gecko sempre acima do limite no instante do calculo: a parcela do passo e identica entre geracoes
		stage.player.global_position = Vector2(90.0, Y_GEOCO_ACIMA)
		stage._physics_process(0.016)
		await wait_process_frames(1)
	assert_gt(
		_resumos.size(),
		antes,
		"o avanco da camera deveria fazer o gerador criar mais linhas (capturou %s alem das %s iniciais)"
		% [_resumos.size() - antes, antes]
	)
	var resumos := _resumos.duplicate()
	remove_child(stage)
	stage.free()
	return resumos


# C767: relogio injetado no mesmo dia -> duas Stages Diario geram a mesma lista (posicao, tipo, mecanica, cor
# das estaticas) das primeiras linhas, inclusive apos o avanco da camera criar mais linhas; cor das moveis fora.
func test_C767_mesmo_dia_duas_stages_diario_mesma_lista() -> void:
	var ger_a := await _gerar(DIA_BASE, Enums.COR_INICIAL)
	var ger_b := await _gerar(DIA_BASE, Enums.COR_INICIAL)
	assert_gt(
		ger_a.size(), 5, "a geracao deveria capturar as 5 linhas do .tscn e as do avanco (capturou %s)" % ger_a.size()
	)
	assert_eq(ger_b.size(), ger_a.size(), "mesmo dia e mesmo layout: mesmos indices de linha nas duas Stages")
	var divergentes := _indices_divergentes(ger_a, ger_b)
	assert_eq(
		divergentes.size(),
		0,
		"mesmo dia deveria reproduzir a lista das linhas; primeiro indice divergente: %s"
		% [divergentes.front() if not divergentes.is_empty() else "nenhum"]
	)


# C768: dia + 1 -> diverge em pelo menos uma linha; a fixture confere o dia injetado e o teste confere a
# divergencia de fato (as N linhas comparadas sao as mesmas do C767).
func test_C768_dia_seguinte_diverge_em_pelo_menos_uma_linha() -> void:
	var ger_a := await _gerar(DIA_BASE, Enums.COR_INICIAL)
	var ger_b := await _gerar(DIA_BASE + 1, Enums.COR_INICIAL)
	assert_gt(ger_a.size(), 0, "a geracao deveria capturar linhas para comparar (capturou %s)" % ger_a.size())
	var divergentes := _indices_divergentes(ger_a, ger_b)
	assert_gt(
		divergentes.size(),
		0,
		"dias distintos (%s e %s) deveriam divergir em pelo menos uma linha (divergiram em %s de %s)"
		% [DIA_BASE, DIA_BASE + 1, divergentes.size(), ger_a.size()]
	)


# C769: cor das moveis fora da seed — duas Stages do mesmo dia com cor inicial do gecko diferente geram as
# mesmas plataformas normais (o resumo nao compara a cor das moveis, que segue o gecko).
func test_C769_cor_do_gecko_diferente_mesmas_plataformas_normais() -> void:
	var cor_outra := _cor_diferente_do_gecko()
	assert_ne(cor_outra, Enums.COR_INICIAL, "fixture: a cor da 2a geracao deveria diferir da 1a")
	var ger_a := await _gerar(DIA_BASE, Enums.COR_INICIAL)
	var ger_b := await _gerar(DIA_BASE, cor_outra)
	var divergentes := _indices_divergentes(ger_a, ger_b)
	assert_eq(
		divergentes.size(),
		0,
		"cor do gecko nao entra na seed: as plataformas normais deveriam ser as mesmas; primeiro divergente: %s"
		% [divergentes.front() if not divergentes.is_empty() else "nenhum"]
	)


# C770: modos sem seed do dia (Classico, Puro, Tempo, Zen) continuam sem seed na Stage (sorteio livre como hoje)
func test_C770_modos_sem_seed_do_dia_nascem_sem_semente() -> void:
	for id in [GameModes.ID_CLASSICO, GameModes.ID_PURO, GameModes.ID_TEMPO, GameModes.ID_ZEN]:
		Global.set_modo_jogo(id, false)
		var stage: Node = load(STAGE_SCENE).instantiate()
		add_child(stage)
		assert_null(
			stage.get_node("ScrollLevel").semente,
			"Stage do modo %s deveria nascer sem seed (sorteio livre como hoje)" % String(id)
		)
		remove_child(stage)
		stage.free()


# C771: semente_partida setada ANTES do add_child vence a seed do dia (precedencia do chamador sobre o dia)
func test_C771_semente_partida_setada_antes_do_add_child_vence_o_dia() -> void:
	Global.iniciado = false
	Global.set_modo_jogo(GameModes.ID_DIARIO, false)
	Global.aplicar_dia_inicial(str(DIA_BASE), true)
	var stage: Node = load(STAGE_SCENE).instantiate()
	stage.semente_partida = SEMENTE_DO_CHAMADOR
	add_child(stage)
	var semente = stage.get_node("ScrollLevel").semente
	assert_eq(semente, SEMENTE_DO_CHAMADOR, "a seed setada pelo chamador deveria vencer a do dia")
	assert_ne(semente, DIA_BASE, "a seed do dia (%s) nao deveria ter sido usada quando o chamador setou a dele" % DIA_BASE)
	remove_child(stage)
	stage.free()


# C772: troca Classico -> Diario no menu recarrega (a nova Stage nasce com a seed do dia); Diario -> Classico
# recarrega de novo e a nova nasce sem seed. A seam `recarregar_cena` registra o pedido; a Stage do reload real
# e simulada instanciando outra com o modo persistido.
func test_C772_troca_classico_diario_no_menu_recarrega_nova_stage_com_e_sem_seed() -> void:
	Global.aplicar_dia_inicial(str(DIA_BASE), true)
	Global.set_modo_jogo(GameModes.ID_CLASSICO, false)
	var stage: Node = load(STAGE_SCENE).instantiate()
	var pedidos: Array = []
	stage.recarregar_cena = func() -> void: pedidos.append("recarga")
	add_child(stage)
	# Classico -> Diario
	stage._abrir_modos_do_menu()
	stage._fechar_modos(GameModes.diario())
	assert_eq(pedidos.size(), 1, "Classico -> Diario cruza a fronteira do Diario: deveria pedir recarga da Stage")
	assert_eq(Global.get_modo_jogo(), GameModes.ID_DIARIO, "o modo persistido apos o OK e o Diario")
	var nova: Node = load(STAGE_SCENE).instantiate()
	add_child(nova)
	assert_eq(
		nova.get_node("ScrollLevel").semente,
		DIA_BASE,
		"a Stage recarregada apos Classico -> Diario nasce com a seed do dia"
	)
	assert_eq(nova._dia_da_stage, DIA_BASE, "a Stage recarregada guarda o dia usado")
	remove_child(nova)
	nova.free()
	# Diario -> Classico
	stage._abrir_modos_do_menu()
	stage._fechar_modos(GameModes.classico())
	assert_eq(pedidos.size(), 2, "Diario -> Classico cruza a fronteira: deveria pedir recarga de novo")
	assert_eq(Global.get_modo_jogo(), GameModes.ID_CLASSICO, "o modo persistido apos o OK e o Classico")
	var outra: Node = load(STAGE_SCENE).instantiate()
	add_child(outra)
	assert_null(outra.get_node("ScrollLevel").semente, "a Stage recarregada apos Diario -> Classico nasce sem seed")
	remove_child(outra)
	outra.free()
	remove_child(stage)
	stage.free()


# C773: Puro -> Zen nao cruza a fronteira do Diario — sem recarga (mesma instancia de Stage na arvore); a
# troca sem recarga ainda aplica a regra do novo modo in place, e reconfirmar o Diario tampouco recarrega.
func test_C773_troca_puro_zen_sem_recarga_mesma_instancia() -> void:
	Global.set_modo_jogo(GameModes.ID_PURO, false)
	var stage: Node = load(STAGE_SCENE).instantiate()
	var pedidos: Array = []
	stage.recarregar_cena = func() -> void: pedidos.append("recarga")
	add_child(stage)
	var id_antes: int = stage.get_instance_id()
	stage._abrir_modos_do_menu()
	stage._fechar_modos(GameModes.zen())
	assert_eq(pedidos.size(), 0, "Puro -> Zen nao cruza a fronteira do Diario: nenhuma recarga")
	assert_eq(stage.get_instance_id(), id_antes, "a mesma instancia de Stage segue na arvore (sem reinstanciar)")
	assert_true(stage.regra is ZenRule, "a troca sem recarga ainda aplica a regra do novo modo in place")
	# Reconfirmar o Diario nao cruza a fronteira (entrar/sair x escolher de novo): a 2a Stage nasce
	# no Diario para o `regra` vigente ja ser o Diario antes do OK
	Global.aplicar_dia_inicial(str(DIA_BASE), true)
	Global.iniciado = false
	Global.set_modo_jogo(GameModes.ID_DIARIO, false)
	var stage_diario: Node = load(STAGE_SCENE).instantiate()
	var pedidos_diario: Array = []
	stage_diario.recarregar_cena = func() -> void: pedidos_diario.append("recarga")
	add_child(stage_diario)
	stage_diario._abrir_modos_do_menu()
	stage_diario._fechar_modos(GameModes.diario())
	assert_eq(pedidos_diario.size(), 0, "Diario -> Diario nao cruza a fronteira: nenhuma recarga")
	remove_child(stage_diario)
	stage_diario.free()
	remove_child(stage)
	stage.free()


# C774: relogio invalido (sentinela) na Stage Diario: sem seed — a sentinela DIA_INVALIDO nunca vira seed
# (`?dia=0` de debug devolve relogio unix 0, e DiaUtc devolve a sentinela -1).
func test_C774_relogio_invalido_stage_diario_sem_seed() -> void:
	Global.iniciado = false
	Global.set_modo_jogo(GameModes.ID_DIARIO, false)
	Global.aplicar_dia_inicial("0", true)
	assert_eq(
		DiaUtc.new(Global.relogio_do_dia()).dia_atual(),
		DiaUtc.DIA_INVALIDO,
		"fixture: o relogio injetado devolve o dia invalido (unix 0)"
	)
	var stage: Node = load(STAGE_SCENE).instantiate()
	add_child(stage)
	assert_null(stage.get_node("ScrollLevel").semente, "relogio invalido: a Stage Diario nasce SEM seed")
	assert_eq(stage._dia_da_stage, DiaUtc.DIA_INVALIDO, "o dia usado guarda a sentinela (nunca vira seed)")
	remove_child(stage)
	stage.free()
