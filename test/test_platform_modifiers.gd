extends GutTest

const PLATAFORMA_CENA := "res://scenes/Platform.tscn"


class _FakeMenor extends PlatformModifier:
	pass


class _FakeQueCaem extends PlatformModifier:
	pass


func before_each() -> void:
	PlatformModifiers.limpar()


func after_each() -> void:
	PlatformModifiers.restaurar_padrao()


func _snapshot(mecanicas: Array[StringName]) -> DifficultySnapshot:
	return DifficultySnapshot.new(
		DifficultyStage.SCROLL_PADRAO,
		DifficultyStage.SPEED_PADRAO,
		DifficultyStage.K_PADRAO,
		DifficultyStage.PROPORCAO_PADRAO,
		mecanicas
	)


func test_resolver_sem_mecanicas_devolve_lista_vazia() -> void:
	PlatformModifiers.registrar(PlatformModifiers.PLATAFORMAS_MENORES, _FakeMenor)
	var resultado := PlatformModifiers.resolver(_snapshot([]))
	assert_eq(resultado.size(), 0, "mecanicas vazia nao gera modificador")


func test_resolver_nome_desconhecido_sozinho_e_ignorado_sem_erro() -> void:
	var mecanicas: Array[StringName] = [&"inexistente", &"outro_inexistente"]
	var resultado := PlatformModifiers.resolver(_snapshot(mecanicas))
	assert_eq(resultado.size(), 0, "nomes sem registro nao geram modificador")


func test_resolver_nome_desconhecido_no_meio_mantem_os_outros_na_ordem() -> void:
	PlatformModifiers.registrar(PlatformModifiers.PLATAFORMAS_MENORES, _FakeMenor)
	PlatformModifiers.registrar(PlatformModifiers.PLATAFORMAS_QUE_CAEM, _FakeQueCaem)
	var mecanicas: Array[StringName] = [
		PlatformModifiers.PLATAFORMAS_MENORES, &"inexistente", PlatformModifiers.PLATAFORMAS_QUE_CAEM
	]
	var resultado := PlatformModifiers.resolver(_snapshot(mecanicas))
	assert_eq(resultado.size(), 2, "o desconhecido do meio e ignorado, os outros dois ficam")
	assert_true(resultado[0] is _FakeMenor, "primeiro modificador segue a ordem de mecanicas")
	assert_true(resultado[1] is _FakeQueCaem, "segundo modificador segue a ordem de mecanicas")


func test_resolver_segue_ordem_inversa_de_mecanicas() -> void:
	PlatformModifiers.registrar(PlatformModifiers.PLATAFORMAS_MENORES, _FakeMenor)
	PlatformModifiers.registrar(PlatformModifiers.PLATAFORMAS_QUE_CAEM, _FakeQueCaem)
	var mecanicas: Array[StringName] = [
		PlatformModifiers.PLATAFORMAS_QUE_CAEM, PlatformModifiers.PLATAFORMAS_MENORES
	]
	var resultado := PlatformModifiers.resolver(_snapshot(mecanicas))
	assert_true(resultado[0] is _FakeQueCaem, "a ordem vem de mecanicas, nao do registro")
	assert_true(resultado[1] is _FakeMenor, "a ordem vem de mecanicas, nao do registro")


func test_hooks_base_nao_alteram_a_plataforma() -> void:
	var plataforma: Platform = add_child_autofree(load(PLATAFORMA_CENA).instantiate())
	var colisor: CollisionShape2D = plataforma.get_node("CollisionShape2D")
	var forma: RectangleShape2D = colisor.shape
	var largura_antes := forma.size.x
	var desativada_antes := colisor.disabled
	var modificador := PlatformModifier.new()
	var snapshot := _snapshot([])

	modificador.ao_criar(plataforma, snapshot)
	modificador.ao_pousar(plataforma, snapshot)
	modificador.ao_processar(plataforma, 0.016)

	assert_eq(forma.size.x, largura_antes, "hook base nao muda a largura")
	assert_eq(colisor.disabled, desativada_antes, "hook base nao muda shape.disabled")
