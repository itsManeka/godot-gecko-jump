extends GutTest

# Registro de modos (GameModes): Classico sempre presente, primeiro e padrao; resolucao por id
# (C567/C568) e ciclo do carrossel (C569). A flag de debug e ligada/restaurada em before_each/after_each.

var _flag_antes: bool = false


func before_each() -> void:
	_flag_antes = Global.modos_teste_habilitado
	Global.modos_teste_habilitado = false


func after_each() -> void:
	Global.modos_teste_habilitado = _flag_antes


# Registro: Classico sempre presente, primeiro da lista e padrao de resolucao.
func test_registro_tem_classico_primeiro_e_padrao() -> void:
	var modos := GameModes.lista()
	assert_eq(modos.size(), 1, "lista sem o modo de teste tem so o Classico")
	assert_eq(modos[0].id, &"classico", "Classico e o primeiro da lista")
	assert_eq(GameModes.padrao().id, &"classico", "padrao() devolve o Classico")
	var com_teste := GameModes.lista(true)
	assert_eq(com_teste.size(), 2, "lista com incluir_teste acrescenta o modo de teste")
	assert_eq(com_teste[0].id, &"classico", "com o modo de teste, Classico segue primeiro")


func test_c567_de_id_nulo_devolve_classico_sem_erro_de_tipo() -> void:
	var modo: GameMode = GameModes.de_id(null)
	assert_eq(modo.id, &"classico", "C567: de_id(null) devolve o Classico sem erro de tipo")


func test_de_id_vazio_ou_desconhecido_devolve_classico() -> void:
	assert_eq(GameModes.de_id("").id, &"classico", "id vazio devolve o Classico")
	assert_eq(GameModes.de_id("xyz").id, &"classico", "id desconhecido devolve o Classico")
	assert_eq(GameModes.de_id(7).id, &"classico", "id de tipo invalido (int) devolve o Classico")
	assert_eq(GameModes.de_id(true).id, &"classico", "id de tipo invalido (bool) devolve o Classico")
	assert_eq(GameModes.de_id(&"classico").id, &"classico", "id StringName classico devolve o Classico")


func test_c568_de_id_teste_respeita_a_flag_de_debug() -> void:
	assert_eq(GameModes.de_id("teste").id, &"classico", "C568: sem a flag, de_id teste devolve o Classico")
	Global.modos_teste_habilitado = true
	assert_eq(GameModes.de_id("teste").id, &"teste", "C568: com a flag, de_id teste devolve o modo de teste")


func test_c569_ciclo_voltam_nas_listas_de_2_e_de_1() -> void:
	var dois := GameModes.lista(true)
	assert_eq(
		GameModes.proximo(dois[1], dois).id, &"classico", "C569: proximo do ultimo (lista de 2) volta ao primeiro"
	)
	assert_eq(GameModes.anterior(dois[0], dois).id, &"teste", "C569: anterior do primeiro (lista de 2) vai ao ultimo")
	var um := GameModes.lista()
	assert_eq(GameModes.proximo(um[0], um).id, &"classico", "C569: lista de 1 cicla proximo para si mesmo, sem erro")
	assert_eq(GameModes.anterior(um[0], um).id, &"classico", "C569: lista de 1 cicla anterior para si mesmo, sem erro")
