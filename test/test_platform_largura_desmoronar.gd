extends GutTest

const PLATAFORMA_CENA := "res://scenes/Platform.tscn"
const LARGURA_PREFAB := 59.474
const LARGURA_AREA := 60.297


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
	assert_almost_eq(c.shape.shape.size.x, LARGURA_PREFAB, 0.001, "prefab recem-instanciado segue 59,474")


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
	assert_almost_eq(area.size.x, LARGURA_AREA, 0.001, "AreaCheck segue 60,297")
	assert_eq(area.size, area_antes, "AreaCheck inalterada")
	assert_eq(p.shape.shape.size.x, 44.0, "colisao com 44")


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
