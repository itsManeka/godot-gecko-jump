extends GutTest

# Ciclo de vida de Global.platforms (f402 T2, issue #3): C26-C29.

const PLATAFORMA_CENA := preload("res://scenes/Platform.tscn")
const GERADOR_CENA := preload("res://scenes/RunningPlatforms.tscn")
const STAGE_CENA := preload("res://scenes/Stage.tscn")


func before_each() -> void:
	Global.platforms.clear()
	Global.set_iniciado(false)


func after_each() -> void:
	Global.platforms.clear()
	Global.set_iniciado(false)


# Conta entradas de Global.platforms que ja foram liberadas (referencia morta na lista).
func _invalidas() -> int:
	var n := 0
	for p in Global.platforms:
		if not is_instance_valid(p):
			n += 1
	return n


# Conta entradas vivas de Global.platforms com o instance id dado.
func _vivas_com_id(id: int) -> int:
	var n := 0
	for p in Global.platforms:
		if is_instance_valid(p) and p.get_instance_id() == id:
			n += 1
	return n


# C26: queue_free do gerador (pai RunningPlatforms), sem screen_exited, tira a plataforma de Global.platforms.
func test_queue_free_do_gerador_tira_plataforma_da_lista() -> void:
	var gerador = GERADOR_CENA.instantiate()
	add_child(gerador)
	var plataforma: Platform = PLATAFORMA_CENA.instantiate()
	gerador.add_child(plataforma)
	var id := plataforma.get_instance_id()
	assert_eq(_vivas_com_id(id), 1, "plataforma entra em Global.platforms no _ready")

	gerador.queue_free()
	await wait_frames(3)

	assert_eq(_invalidas(), 0, "nenhuma referencia liberada sobra em Global.platforms apos o queue_free do gerador")
	assert_eq(_vivas_com_id(id), 0, "a plataforma liberada pelo gerador sai de Global.platforms")


# C27: sinais de cor com uma entrada liberada ainda na lista nao dao SCRIPT ERROR (guarda is_instance_valid).
func test_sinais_de_cor_ignoram_entrada_liberada() -> void:
	var viva: Platform = add_child_autofree(PLATAFORMA_CENA.instantiate())
	var liberada: Platform = PLATAFORMA_CENA.instantiate()
	add_child(liberada)
	liberada.free()
	# Forca a entrada liberada de volta na lista, na frente (o caso que o cast quebrava).
	Global.platforms.insert(0, liberada)
	var outra_cor: int = Enums.COLOR.AMARELO + 1

	Global.player_color_changed(outra_cor, null)
	assert_true(viva.shape.disabled, "player_color_changed atualiza a plataforma viva apesar da entrada liberada")

	viva.shape.disabled = false
	Global.att_actual_platform(outra_cor, liberada)
	assert_false(viva.shape.disabled, "att_actual_platform com atual liberada nao mexe na plataforma viva")


# C28: saida por screen_exited e depois liberada: removida uma vez, sem duplicata nem erro (idempotencia).
func test_screen_exited_seguido_de_queue_free_remove_uma_vez() -> void:
	var saiu: Platform = PLATAFORMA_CENA.instantiate()
	add_child(saiu)
	add_child_autofree(PLATAFORMA_CENA.instantiate())
	var id := saiu.get_instance_id()
	var antes := Global.platforms.size()

	saiu._on_VisibilityNotifier2D_screen_exited()
	await wait_frames(3)

	assert_eq(_vivas_com_id(id), 0, "a plataforma que saiu da tela nao fica em Global.platforms")
	assert_eq(_invalidas(), 0, "nenhuma referencia liberada sobra apos screen_exited + queue_free")
	assert_eq(Global.platforms.size(), antes - 1, "a plataforma e removida exatamente uma vez")


# C29: liberar a Stage inteira (como change_scene_to_file) deixa Global.platforms sem plataforma da cena antiga.
func test_liberar_stage_tira_plataformas_da_cena() -> void:
	var stage = STAGE_CENA.instantiate()
	add_child(stage)
	await wait_frames(3)
	var ids: Array[int] = []
	for no in stage.find_children("*", "", true, false):
		if no is Platform:
			ids.append(no.get_instance_id())
	assert_gt(ids.size(), 0, "a Stage monta plataformas no _ready")

	stage.free()
	await wait_frames(3)

	assert_eq(_invalidas(), 0, "nenhuma referencia liberada da Stage antiga sobra em Global.platforms")
	for id in ids:
		assert_eq(_vivas_com_id(id), 0, "plataforma da Stage antiga sai de Global.platforms")
