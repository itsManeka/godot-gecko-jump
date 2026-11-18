extends GutTest

const PLATAFORMA_CENA := "res://scenes/Platform.tscn"
const LARGURA_PREFAB := 59.474

var _sem_derrota_original := false


func before_each() -> void:
	_sem_derrota_original = Global.sem_derrota
	Global.sem_derrota = false
	PlatformModifiers.restaurar_padrao()


func after_each() -> void:
	Global.sem_derrota = _sem_derrota_original
	PlatformModifiers.restaurar_padrao()


func _snapshot(mecanicas: Array[StringName], largura: float = 44.0, atraso: float = 0.8) -> DifficultySnapshot:
	return DifficultySnapshot.new(
		DifficultyStage.SCROLL_PADRAO,
		DifficultyStage.SPEED_PADRAO,
		DifficultyStage.K_PADRAO,
		DifficultyStage.PROPORCAO_PADRAO,
		mecanicas,
		largura,
		atraso
	)


func _nova() -> Platform:
	return add_child_autofree(load(PLATAFORMA_CENA).instantiate())


func _nova_com(snapshot: DifficultySnapshot) -> Platform:
	var p: Platform = load(PLATAFORMA_CENA).instantiate()
	var lista: Array = PlatformModifiers.resolver(snapshot)
	p.definir_modificadores(lista, snapshot)
	return add_child_autofree(p)


func _passos(p: Platform, n: int, delta: float) -> void:
	for i in n:
		p._physics_process(delta)


func test_registro_real_mapeia_os_nomes_para_as_classes() -> void:
	var lista := PlatformModifiers.resolver(
		_snapshot([PlatformModifiers.PLATAFORMAS_MENORES, PlatformModifiers.PLATAFORMAS_QUE_CAEM])
	)
	assert_eq(lista.size(), 2, "dois modificadores resolvidos")
	assert_true(lista[0] is PlatformNarrower, "menores -> PlatformNarrower")
	assert_true(lista[1] is PlatformCrumble, "que caem -> PlatformCrumble")


func test_plataformas_menores_aplicam_largura_do_snapshot() -> void:
	var p := _nova_com(_snapshot([PlatformModifiers.PLATAFORMAS_MENORES], 44.0))
	assert_eq(p.shape.shape.size.x, 44.0, "largura do snapshot")


func test_sem_plataformas_menores_a_largura_nao_muda() -> void:
	var p := _nova_com(_snapshot([], 44.0))
	assert_almost_eq(p.shape.shape.size.x, LARGURA_PREFAB, 0.001, "sem a mecanica segue a largura do prefab")


func test_ao_pousar_desmorona_so_apos_o_atraso() -> void:
	var snap := _snapshot([PlatformModifiers.PLATAFORMAS_QUE_CAEM], 60.0, 0.8)
	var p := _nova_com(snap)
	p.notificar_pouso()
	_passos(p, 7, 0.1)
	assert_false(p.desmoronada, "aos 0,7 s ainda nao desmoronou")
	assert_false(p.shape.disabled, "aos 0,7 s a colisao segue ativa")
	p._physics_process(0.15)
	assert_true(p.desmoronada, "apos 0,8 s desmoronou")
	assert_true(p.shape.disabled, "apos 0,8 s sem colisao")


func test_segundo_pouso_nao_reinicia_nem_estende_o_prazo() -> void:
	var snap := _snapshot([PlatformModifiers.PLATAFORMAS_QUE_CAEM], 60.0, 0.8)
	var p := _nova_com(snap)
	p.notificar_pouso()
	_passos(p, 4, 0.1)
	p.notificar_pouso()
	_passos(p, 3, 0.1)
	assert_false(p.desmoronada, "aos 0,7 s ainda nao desmoronou")
	p._physics_process(0.15)
	assert_true(p.desmoronada, "some aos 0,8 s do primeiro pouso")


func test_sem_derrota_crumble_nao_age_e_narrower_aplica() -> void:
	Global.sem_derrota = true
	var snap := _snapshot([PlatformModifiers.PLATAFORMAS_MENORES, PlatformModifiers.PLATAFORMAS_QUE_CAEM], 44.0, 0.8)
	var p := _nova_com(snap)
	p.notificar_pouso()
	_passos(p, 20, 0.1)
	assert_false(p.desmoronada, "nao desmoronou depois de 2 s")
	assert_false(p.shape.disabled, "colisao segue ativa depois de 2 s")
	assert_eq(p.shape.shape.size.x, 44.0, "largura menor aplicada mesmo com sem_derrota")


func test_sem_a_lista_de_menores_a_plataforma_fica_com_a_largura_do_prefab_mesmo_com_snapshot_44() -> void:
	var p := _nova_com(_snapshot([PlatformModifiers.PLATAFORMAS_QUE_CAEM], 44.0))
	assert_almost_eq(p.shape.shape.size.x, LARGURA_PREFAB, 0.001, "sem plataformas_menores nao estreita")
	assert_ne(p.shape.shape.size.x, 44.0, "nao ficou com 44")
