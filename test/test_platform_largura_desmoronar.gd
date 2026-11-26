extends GutTest

const PLATAFORMA_CENA := "res://scenes/Platform.tscn"
const LARGURA_PREFAB := 118.948
const LARGURA_AREA := 120.594
const GERADOR_CENA := "res://scenes/RunningPlatforms.tscn"
const LARGURAS_DA_CURVA := [120.0, 112.0, 100.0, 88.0]
# Retangulo visual da plataforma: textura 64x16 a escala 2
const VISUAL_W := 128.0
const VISUAL_H := 32.0


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


# C820 [mutacao]: colisao e largura visual (regiao x escala do sprite) batem com a largura pedida; corpo sem scale
func test_set_largura_da_curva_ajusta_colisao_e_largura_visual_sem_truncar_na_textura() -> void:
	for largura in LARGURAS_DA_CURVA:
		var p := _nova()
		p.set_largura(largura)
		var visual: float = p.sprite.region_rect.size.x * p.sprite.scale.x
		assert_almost_eq(p.shape.shape.size.x, largura, 1.0, "colisao com %s" % largura)
		assert_almost_eq(visual, largura, 1.0, "largura visual (regiao x escala) com %s" % largura)
		assert_eq(p.scale, Vector2.ONE, "corpo sem scale apos set_largura(%s) (ADR 0009)" % largura)


# C821 [mutacao]: o icone fica acima do topo visual (topo = metade da textura x escala do sprite)
func test_icone_de_power_up_fica_acima_do_topo_visual_da_plataforma() -> void:
	var p: Platform = load(PLATAFORMA_CENA).instantiate()
	p.definir_power_up(&"camaleao")
	add_child_autofree(p)
	var topo_visual: float = -p.sprite.texture.get_height() * p.sprite.scale.y / 2.0
	var base_icone: float = p.icone_power_up.position.y + PowerUpIcone.TAMANHO_PX / 2.0
	assert_almost_eq(p.icone_power_up.position.y, topo_visual - 4.0 - PowerUpIcone.TAMANHO_PX / 2.0, 0.001, "icone em topo - 4 - meia altura")
	assert_almost_eq(base_icone, topo_visual - Platform.ICONE_FOLGA, 0.001, "base do icone ICONE_FOLGA acima do topo visual")
	assert_lt(base_icone, -VISUAL_H / 2.0, "icone nao afunda no corpo visual da plataforma")


# C822: AreaCheck + CheckGenerate somam DISTANCIA_SAIDA; o notifier cobre o retangulo visual 128x32 (sem despawn prematuro)
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
