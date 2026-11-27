extends GutTest

const PLATAFORMA_CENA := "res://scenes/Platform.tscn"
const LARGURA_PREFAB := 118.948
const LARGURA_AREA := 120.594
const GERADOR_CENA := "res://scenes/RunningPlatforms.tscn"
# Retangulo visual nominal da plataforma: peca 96x40 (NinePatchRect, prefab com 120 de largura), sem scale
const VISUAL_W := 120.0
const VISUAL_H := 40.0
# Pontas 20/20 e altura da peca; a superficie (linha y=6 da peca) fica a 4 px abaixo do centro nominal: corpo.position.y = -20 + 4
const MARGEM := 20
const CORPO_Y := -16.0


class _FakeEstreita extends PlatformModifier:
	func ao_criar(plataforma: Platform, _snapshot: DifficultySnapshot) -> void:
		plataforma.set_largura(44.0)


func _nova() -> Platform:
	return add_child_autofree(load(PLATAFORMA_CENA).instantiate())


func test_instancias_tem_largura_propria_e_o_prefab_nao_muda() -> void:
	var a := _nova()
	var b := _nova()
	a.set_largura(44.0)
	b.set_largura(60.0)
	assert_eq(a.shape.shape.size.x, 44.0, "instancia A com 44")
	assert_eq(b.shape.shape.size.x, 60.0, "instancia B com 60")
	var c := _nova()
	assert_almost_eq(c.shape.shape.size.x, LARGURA_PREFAB, 0.001, "prefab recem-instanciado segue 118,948")


func test_set_largura_mantem_centro_area_e_sem_scale() -> void:
	var p := _nova()
	p.position = Vector2(30.0, 40.0)
	var centro_antes: Vector2 = p.shape.position
	var pos_antes := p.position
	var area_antes: Vector2 = p.get_node("AreaCheck/CollisionPolygon2D").shape.size
	p.set_largura(44.0)
	assert_eq(p.shape.position, centro_antes, "centro da colisao nao muda")
	assert_eq(p.position, pos_antes, "position da plataforma nao muda")
	assert_eq(p.scale, Vector2.ONE, "sem scale no corpo")
	var area: RectangleShape2D = p.get_node("AreaCheck/CollisionPolygon2D").shape
	assert_almost_eq(area.size.x, LARGURA_AREA, 0.001, "AreaCheck segue 120,594")
	assert_eq(area.size, area_antes, "AreaCheck inalterada")
	assert_eq(p.shape.shape.size.x, 44.0, "colisao com 44")


# Colisao, AreaCheck e NinePatchRect (largura, altura, margens, TILE, sem scale) para uma largura pedida
func _afirmar_largura(largura: float) -> void:
	var p := _nova()
	p.set_largura(largura)
	assert_eq(p.shape.shape.size.x, largura, "colisao com %s" % largura)
	var area: RectangleShape2D = p.get_node("AreaCheck/CollisionPolygon2D").shape
	assert_almost_eq(area.size.x, LARGURA_AREA, 0.001, "AreaCheck segue 120,594 com %s" % largura)
	var corpo: NinePatchRect = p.get_node("Visual/Corpo")
	assert_eq(corpo.size, Vector2(largura, 40.0), "NinePatchRect %sx40" % largura)
	assert_eq(corpo.position.x, -largura / 2.0, "NinePatchRect centrado em x com %s" % largura)
	assert_eq(corpo.patch_margin_left, MARGEM, "margem esquerda 20 com %s" % largura)
	assert_eq(corpo.patch_margin_right, MARGEM, "margem direita 20 com %s" % largura)
	assert_eq(corpo.axis_stretch_horizontal, NinePatchRect.AXIS_STRETCH_MODE_TILE, "miolo TILE com %s" % largura)
	assert_eq(p.scale, Vector2.ONE, "corpo sem scale apos set_largura(%s) (ADR 0009)" % largura)
	assert_eq(p.get_node("Visual").scale, Vector2.ONE, "Visual sem scale com %s" % largura)


# C869 [mutacao]
func test_set_largura_120_ajusta_colisao_e_ninepatch_sem_scale() -> void:
	_afirmar_largura(120.0)


# C870 [mutacao]
func test_set_largura_112_ajusta_colisao_e_ninepatch_sem_scale() -> void:
	_afirmar_largura(112.0)


# C871 [mutacao]
func test_set_largura_100_ajusta_colisao_e_ninepatch_sem_scale() -> void:
	_afirmar_largura(100.0)


# C872 [mutacao]: unica largura em que o miolo (48) e menor que o tile (56)
func test_set_largura_88_ajusta_colisao_e_ninepatch_sem_scale() -> void:
	_afirmar_largura(88.0)


# C873 [mutacao]: piso usado por testes existentes; o shape e duplicado por instancia
func test_set_largura_44_piso_e_instancias_nao_compartilham_o_shape() -> void:
	var a := _nova()
	var b := _nova()
	a.set_largura(44.0)
	b.set_largura(60.0)
	assert_eq(a.get_node("Visual/Corpo").size.x, 44.0, "NinePatchRect da A com 44")
	assert_eq(a.shape.shape.size.x, 44.0, "colisao da A com 44")
	assert_eq(b.get_node("Visual/Corpo").size.x, 60.0, "NinePatchRect da B com 60")
	assert_eq(b.shape.shape.size.x, 60.0, "colisao da B com 60")
	assert_ne(a.shape.shape, b.shape.shape, "RectangleShape2D duplicado por instancia")


# C874 [mutacao]: prefab sem set_largura tem visual 120x40, centrado, com a superficie alinhada ao topo da colisao
func test_prefab_sem_set_largura_tem_visual_120x40_centrado() -> void:
	var p := _nova()
	var corpo: NinePatchRect = p.get_node("Visual/Corpo")
	assert_eq(corpo.size, Vector2(120.0, 40.0), "visual do prefab 120x40")
	assert_eq(corpo.position, Vector2(-60.0, CORPO_Y), "centrado em x; y = -altura/2 + 4 (superficie da peca no topo da colisao)")
	assert_eq(p.get_node("Visual").position, Vector2.ZERO, "Visual na origem")


# C881 [mutacao]: topo_visual() deriva da altura da textura; o icone fica ICONE_FOLGA acima dele, em x == 0
func test_icone_de_power_up_fica_acima_do_topo_visual_da_plataforma() -> void:
	var p: Platform = load(PLATAFORMA_CENA).instantiate()
	p.definir_power_up(&"camaleao")
	add_child_autofree(p)
	assert_eq(p.topo_visual(), CORPO_Y, "topo do visual = topo do NinePatchRect na cena (-16, conta de mesa)")
	var base_icone: float = p.icone_power_up.position.y + PowerUpIcone.TAMANHO_PX / 2.0
	assert_eq(p.icone_power_up.position.x, 0.0, "icone centrado em x")
	assert_almost_eq(base_icone, CORPO_Y - 4.0, 0.001, "base do icone ICONE_FOLGA acima do topo (-16 - 4)")
	assert_lt(base_icone, CORPO_Y, "icone nao afunda no corpo visual da plataforma")
	p.corpo.position.y = -30.0
	assert_eq(p.topo_visual(), -30.0, "topo acompanha a posicao do NinePatchRect (-30)")


# C822 / C882 [mutacao]: AreaCheck + CheckGenerate somam DISTANCIA_SAIDA; o notifier cobre o retangulo visual 120x40 (sem despawn prematuro)
func test_area_check_e_check_generate_somam_a_distancia_de_saida_e_notifier_cobre_o_visual() -> void:
	var gerador: Node = autofree(load(GERADOR_CENA).instantiate())
	var check_generate: RectangleShape2D = gerador.get_node("CheckGenerate").get_child(0).shape
	var p := _nova()
	var area: RectangleShape2D = p.get_node("AreaCheck/CollisionPolygon2D").shape
	assert_almost_eq(
		(check_generate.size.x + area.size.x) / 2.0, MovingRowFill.DISTANCIA_SAIDA, 0.01, "meias larguras somam DISTANCIA_SAIDA"
	)
	var notifier: VisibleOnScreenNotifier2D = p.get_node("VisibleOnScreenNotifier2D")
	var ret: Rect2 = Rect2(notifier.position + notifier.rect.position * notifier.scale, notifier.rect.size * notifier.scale)
	assert_lte(ret.position.x, -VISUAL_W / 2.0 + 1.0, "notifier cobre a borda esquerda visual")
	assert_gte(ret.end.x, VISUAL_W / 2.0 - 1.0, "notifier cobre a borda direita visual")
	assert_lte(ret.position.y, -VISUAL_H / 2.0 + 1.0, "notifier cobre o topo visual")
	assert_gte(ret.end.y, VISUAL_H / 2.0 - 1.0, "notifier cobre a base visual")
	# O NinePatchRect real (deslocado 4 px para a superficie bater com a colisao) tambem fica dentro do notifier
	var corpo: NinePatchRect = p.get_node("Visual/Corpo")
	assert_lte(ret.position.y, corpo.position.y, "notifier cobre o topo do NinePatchRect")
	assert_gte(ret.end.y, corpo.position.y + corpo.size.y, "notifier cobre a base do NinePatchRect")
	assert_lte(ret.position.x, corpo.position.x, "notifier cobre a esquerda do NinePatchRect")
	assert_gte(ret.end.x, corpo.position.x + corpo.size.x, "notifier cobre a direita do NinePatchRect")
	assert_almost_eq(area.size.x, LARGURA_AREA, 0.001, "AreaCheck intacta")
	assert_almost_eq(p.shape.shape.size.x, LARGURA_PREFAB, 0.001, "shape intacto")


func test_desmoronada_nao_reativa_colisao_com_a_cor_dela() -> void:
	var p := _nova()
	p.set_color(Enums.COLOR.VERDE)
	p.iniciar_desmoronamento(0.5)
	p._physics_process(0.2)
	assert_false(p.desmoronada, "ainda nao desmoronou antes do atraso")
	p._physics_process(0.4)
	assert_true(p.desmoronada, "desmoronou apos o atraso")
	Global.player_color_changed(Enums.COLOR.VERDE, null)
	assert_true(p.shape.disabled, "continua sem colisao com a cor dela")


func test_ao_criar_e_despachado_no_ready_com_lista_entregue_antes_do_add_child() -> void:
	var p: Platform = load(PLATAFORMA_CENA).instantiate()
	var lista: Array = [_FakeEstreita.new()]
	p.definir_modificadores(lista, DifficultySnapshot.new())
	add_child_autofree(p)
	assert_eq(p.shape.shape.size.x, 44.0, "modificador aplicou a largura no _ready")


func test_plataforma_desmoronada_sai_de_global_platforms() -> void:
	var p := _nova()
	assert_true(Global.platforms.has(p), "registrada no _ready")
	p.iniciar_desmoronamento(0.1)
	p._physics_process(0.2)
	await wait_process_frames(2)
	assert_false(Global.platforms.has(p), "removida de Global.platforms apos desmoronar")
